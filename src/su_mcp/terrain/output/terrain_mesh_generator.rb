# frozen_string_literal: true

require 'set'

require_relative '../../semantic/length_converter'
require_relative '../regions/composed_height_oracle'
require_relative 'patch_lifecycle/patch_registry_store'
require_relative 'patch_lifecycle/patch_window_resolver'
require_relative 'patch_lifecycle/patch_timing'
require_relative 'cdt/patches/cdt_lifecycle_ownership'
require_relative 'cdt/patches/cdt_patch_batch_plan'
require_relative 'cdt/terrain_cdt_backend'
require_relative 'adaptive_patches/output_generator'
require_relative 'derived_output_attributes'
require_relative 'derived_output_entity_store'
require_relative 'regular_grid_mesh_emitter'
require_relative 'terrain_vertex_projector'
require_relative 'terrain_output_plan'

module SU_MCP
  module Terrain
    # Regenerates disposable SketchUp mesh output from authoritative terrain state.
    # rubocop:disable Metrics/AbcSize, Metrics/ClassLength
    class TerrainMeshGenerator
      DERIVED_OUTPUT_DICTIONARY = DerivedOutputAttributes::DICTIONARY
      DERIVED_OUTPUT_KEY = DerivedOutputAttributes::DERIVED_OUTPUT_KEY
      OUTPUT_SCHEMA_VERSION = DerivedOutputAttributes::OUTPUT_SCHEMA_VERSION
      OUTPUT_SCHEMA_VERSION_KEY = DerivedOutputAttributes::OUTPUT_SCHEMA_VERSION_KEY
      GRID_CELL_COLUMN_KEY = DerivedOutputAttributes::GRID_CELL_COLUMN_KEY
      GRID_CELL_ROW_KEY = DerivedOutputAttributes::GRID_CELL_ROW_KEY
      GRID_TRIANGLE_INDEX_KEY = DerivedOutputAttributes::GRID_TRIANGLE_INDEX_KEY
      OUTPUT_KIND_KEY = DerivedOutputAttributes::OUTPUT_KIND_KEY
      ADAPTIVE_PATCH_MESH_OUTPUT_KIND = DerivedOutputAttributes::ADAPTIVE_PATCH_MESH_OUTPUT_KIND
      ADAPTIVE_PATCH_FACE_OUTPUT_KIND = DerivedOutputAttributes::ADAPTIVE_PATCH_FACE_OUTPUT_KIND
      ADAPTIVE_PATCH_REGISTRY_KEY = DerivedOutputAttributes::ADAPTIVE_PATCH_REGISTRY_KEY
      ADAPTIVE_PATCH_ID_KEY = DerivedOutputAttributes::ADAPTIVE_PATCH_ID_KEY
      ADAPTIVE_PATCH_FACE_INDEX_KEY = DerivedOutputAttributes::ADAPTIVE_PATCH_FACE_INDEX_KEY
      ADAPTIVE_POLICY_FINGERPRINT_KEY =
        DerivedOutputAttributes::ADAPTIVE_POLICY_FINGERPRINT_KEY
      REPLACEMENT_BATCH_ID_KEY = DerivedOutputAttributes::REPLACEMENT_BATCH_ID_KEY
      TERRAIN_STATE_DIGEST_KEY = DerivedOutputAttributes::TERRAIN_STATE_DIGEST_KEY
      TERRAIN_STATE_REVISION_KEY = DerivedOutputAttributes::TERRAIN_STATE_REVISION_KEY
      FACE_COUNT_KEY = DerivedOutputAttributes::FACE_COUNT_KEY
      CDT_PATCH_OUTPUT_KIND = DerivedOutputAttributes::CDT_PATCH_OUTPUT_KIND
      CDT_OWNERSHIP_SCHEMA_VERSION_KEY =
        DerivedOutputAttributes::CDT_OWNERSHIP_SCHEMA_VERSION_KEY
      CDT_PATCH_ID_KEY = DerivedOutputAttributes::CDT_PATCH_ID_KEY
      CDT_REPLACEMENT_BATCH_ID_KEY = DerivedOutputAttributes::CDT_REPLACEMENT_BATCH_ID_KEY
      CDT_PATCH_FACE_INDEX_KEY = DerivedOutputAttributes::CDT_PATCH_FACE_INDEX_KEY
      CDT_BORDER_SIDE_KEY = DerivedOutputAttributes::CDT_BORDER_SIDE_KEY
      CDT_BORDER_SPAN_ID_KEY = DerivedOutputAttributes::CDT_BORDER_SPAN_ID_KEY
      CDT_BORDER_SIDE_DEFINITIONS = [
        ['west', 0, :min],
        ['east', 0, :max],
        ['south', 1, :min],
        ['north', 1, :max]
      ].freeze
      DEFAULT_CDT_BACKEND = Object.new.freeze
      DEFAULT_CDT_ENABLED = false

      attr_reader :last_cdt_patch_timing, :last_cdt_failure_reason,
                  :last_adaptive_patch_timing, :last_adaptive_seam_validation_summary

      def initialize(
        length_converter: Semantic::LengthConverter.new,
        cdt_backend: DEFAULT_CDT_BACKEND,
        cdt_patch_replacement_provider: nil,
        seam_validator: nil,
        fallback_on_cdt_failure: true
      )
        @length_converter = length_converter
        @cdt_backend = if default_cdt_backend?(cdt_backend)
                         default_cdt_backend
                       else
                         cdt_backend
                       end
        @cdt_patch_replacement_provider = cdt_patch_replacement_provider
        @seam_validator = seam_validator
        @fallback_on_cdt_failure = fallback_on_cdt_failure
      end

      def generate(owner:, state:, terrain_state_summary:, output_plan: nil, feature_context: nil,
                   height_oracle: nil)
        @height_oracle = height_oracle || ComposedHeightOracle.build(state: state)
        @height_oracle_state = state
        @vertex_projector = nil
        @regular_grid_mesh_emitter = nil
        @adaptive_patch_output_generator = nil
        @last_cdt_failure_reason = nil
        @last_adaptive_patch_timing = nil
        @last_adaptive_seam_validation_summary = nil
        return no_data_refusal if adaptive_state?(state) && state.elevations.any?(&:nil?)

        # Create/adopt generation emits the complete derived grid; edit regeneration may be partial.
        plan = output_plan || TerrainOutputPlan.full_grid(
          state: state,
          terrain_state_summary: terrain_state_summary,
          height_oracle: @height_oracle
        )
        cdt_attempted = cdt_generation_attemptable?(plan, feature_context)
        cdt_result = generate_cdt(
          owner: owner,
          state: state,
          terrain_state_summary: terrain_state_summary,
          plan: plan,
          feature_context: feature_context
        )
        strict_cdt_result = cdt_result_or_strict_refusal(cdt_result, cdt_attempted)
        return strict_cdt_result if strict_cdt_result

        if plan.execution_strategy == :adaptive_tin
          return generate_adaptive(owner: owner, state: state, output_plan: plan)
        end

        rows = state.dimensions.fetch('rows')
        columns = state.dimensions.fetch('columns')
        vertices = vertex_projector.vertices_for(state, columns, rows)
        regular_grid_mesh_emitter.emit_faces_via_builder(
          owner.entities,
          vertices,
          columns,
          rows,
          ownership_context
        )

        generated_result(plan)
      end

      # Validation-only path for live SketchUp comparisons.
      # Do not wire this into production regeneration.
      def generate_bulk_candidate(owner:, state:, terrain_state_summary:)
        rows = state.dimensions.fetch('rows')
        columns = state.dimensions.fetch('columns')
        vertices = vertex_projector.vertices_for(state, columns, rows)
        output_plan = TerrainOutputPlan.full_grid(
          state: state,
          terrain_state_summary: terrain_state_summary
        )

        regular_grid_mesh_emitter.emit_faces_via_builder(
          owner.entities,
          vertices,
          columns,
          rows,
          ownership_context
        )
        generated_result(output_plan).merge(validationOnly: true)
      end

      def cdt_enabled?
        !cdt_backend.nil? || !cdt_patch_replacement_provider.nil?
      end

      def regenerate(owner:, state:, terrain_state_summary:, output_plan: nil,
                     feature_context: nil, height_oracle: nil)
        @height_oracle = height_oracle || ComposedHeightOracle.build(state: state)
        @height_oracle_state = state
        @vertex_projector = nil
        @regular_grid_mesh_emitter = nil
        @adaptive_patch_output_generator = nil
        @last_cdt_failure_reason = nil
        @last_adaptive_patch_timing = nil
        @last_adaptive_seam_validation_summary = nil
        unsupported = derived_output_store.unsupported_child_types(owner.entities)
        return unsupported_children_refusal(unsupported) unless unsupported.empty?
        return no_data_refusal if adaptive_state?(state) && state.elevations.any?(&:nil?)

        plan = output_plan || TerrainOutputPlan.full_grid(
          state: state,
          terrain_state_summary: terrain_state_summary,
          height_oracle: @height_oracle
        )
        cdt_attempted = cdt_regeneration_attemptable?(plan, feature_context)
        cdt_result = regenerate_cdt(
          owner: owner,
          state: state,
          terrain_state_summary: terrain_state_summary,
          plan: plan,
          feature_context: feature_context
        )
        strict_cdt_result = cdt_result_or_strict_refusal(cdt_result, cdt_attempted)
        return strict_cdt_result if strict_cdt_result

        if plan.execution_strategy == :adaptive_tin
          return regenerate_adaptive(owner: owner, state: state, output_plan: plan)
        end

        partial_result = regenerate_partial(
          owner: owner,
          state: state,
          output_plan: plan
        )
        return partial_result if partial_result

        derived_output_store.erase_entities(
          owner.entities,
          derived_output_store.derived_output_entities(owner.entities)
        )
        generate(
          owner: owner,
          state: state,
          terrain_state_summary: terrain_state_summary,
          output_plan: plan
        )
      end

      private

      attr_reader :length_converter, :cdt_backend, :cdt_patch_replacement_provider,
                  :seam_validator, :height_oracle

      def derived_output_store
        @derived_output_store ||= DerivedOutputEntityStore.new
      end

      def vertex_projector
        @vertex_projector ||= TerrainVertexProjector.new(
          length_converter: length_converter,
          height_oracle: height_oracle,
          height_oracle_state: @height_oracle_state
        )
      end

      def regular_grid_mesh_emitter
        @regular_grid_mesh_emitter ||= RegularGridMeshEmitter.new(
          derived_output_store: derived_output_store,
          vertex_projector: vertex_projector
        )
      end

      def adaptive_patch_output_generator
        @adaptive_patch_output_generator ||= AdaptivePatches::OutputGenerator.new(
          derived_output_store: derived_output_store,
          mesh_emitter: regular_grid_mesh_emitter,
          vertex_projector: vertex_projector,
          patch_registry_store: patch_registry_store
        )
      end

      def apply_adaptive_patch_output(output)
        @last_adaptive_patch_timing = output.timing
        @last_adaptive_seam_validation_summary = output.seam_validation_summary
        output.result
      end

      def fallback_on_cdt_failure?
        @fallback_on_cdt_failure == true
      end

      def default_cdt_backend?(candidate)
        candidate.equal?(DEFAULT_CDT_BACKEND)
      end

      def default_cdt_backend
        return nil unless DEFAULT_CDT_ENABLED

        TerrainCdtBackend.new
      end

      def generate_cdt(owner:, state:, terrain_state_summary:, plan:, feature_context:)
        return nil unless cdt_generation_attemptable?(plan, feature_context)

        if cdt_patch_bootstrap_eligible?(plan, feature_context)
          return generate_cdt_patch_bootstrap(
            owner: owner,
            state: state,
            terrain_state_summary: terrain_state_summary,
            plan: plan,
            feature_context: feature_context
          )
        end

        timing = cdt_bootstrap_timing(plan)
        result = timed_cdt_solve(timing) do
          cdt_backend.build(
            state: feature_context[:terrainState] || feature_context['terrainState'] || state,
            feature_geometry: feature_context[:featureGeometry] ||
              feature_context['featureGeometry'],
            primitive_request: feature_context[:primitiveRequest] ||
              feature_context['primitiveRequest'] ||
              {},
            state_digest: terrain_state_summary.fetch(:digest, nil)
          )
        end
      rescue StandardError
        record_cdt_fallback(timing, :backend_exception)
        @last_cdt_patch_timing = finalize_cdt_timing(timing)
        nil
      else
        unless result.fetch(:status) == 'accepted'
          record_cdt_fallback(timing, cdt_failure_reason_for(result))
          @last_cdt_patch_timing = finalize_cdt_timing(timing)
          return nil
        end

        emit_generated_cdt_mesh(
          owner: owner,
          state: state,
          terrain_state_summary: terrain_state_summary,
          output_plan: plan,
          mesh: result.fetch(:mesh),
          timing: timing
        )
        cdt_generated_result(result, terrain_state_summary)
      end

      def emit_generated_cdt_mesh(owner:, state:, terrain_state_summary:, output_plan:, mesh:,
                                  timing: nil, replace_existing: false)
        unless output_plan.adaptive_patch_policy
          if replace_existing
            derived_output_store.erase_entities(
              owner.entities,
              derived_output_store.derived_output_entities(owner.entities)
            )
          end
          return emit_cdt_mesh_via_builder(owner.entities, mesh)
        end

        timing ||= PatchLifecycle::PatchTiming.new
        patches = timing.measure(:cdt_input_build) do
          output_plan.adaptive_patch_policy.patch_domains(state.dimensions)
        end
        emitted_faces = nil
        timing.measure(:mutation) do
          if replace_existing
            derived_output_store.erase_entities(
              owner.entities,
              derived_output_store.derived_output_entities(owner.entities)
            )
          end
          emitted_faces = emit_cdt_mesh_via_builder(
            owner.entities,
            mesh,
            ownership: cdt_bootstrap_ownership_context(
              state: state,
              terrain_state_summary: terrain_state_summary,
              output_plan: output_plan,
              patches: patches
            )
          )
        end
        timing.measure(:registry_write) do
          write_cdt_patch_registry_records(
            owner: owner,
            patches: patches,
            replacement_batch_id: cdt_bootstrap_batch_id(terrain_state_summary),
            policy_fingerprint: output_plan.adaptive_patch_policy.output_policy_fingerprint,
            state_digest: terrain_state_summary.fetch(:digest, nil),
            state_revision: terrain_state_summary.fetch(:revision, nil),
            faces: emitted_faces
          )
        end
        @last_cdt_patch_timing = finalize_cdt_timing(timing)
      end

      def generated_result(output_plan)
        {
          outcome: 'generated',
          summary: output_plan.to_summary
        }
      end

      def adaptive_state?(state)
        state.respond_to?(:tiles) &&
          state.respond_to?(:tile_size) &&
          state.respond_to?(:payload_kind)
      end

      def regenerate_cdt(owner:, state:, terrain_state_summary:, plan:, feature_context:)
        patch_attempt = cdt_patch_regeneration_attempt(
          owner: owner,
          state: state,
          terrain_state_summary: terrain_state_summary,
          plan: plan,
          feature_context: feature_context
        )
        return nil if patch_attempt == :fallback
        return patch_attempt if patch_attempt

        if cdt_patch_bootstrap_eligible?(plan, feature_context)
          return generate_cdt_patch_bootstrap(
            owner: owner,
            state: state,
            terrain_state_summary: terrain_state_summary,
            plan: plan,
            feature_context: feature_context,
            replace_existing: true
          )
        end

        timing = cdt_bootstrap_timing(plan)
        result = build_global_cdt_result(
          state: state,
          terrain_state_summary: terrain_state_summary,
          plan: plan,
          feature_context: feature_context,
          timing: timing
        )
        unless result&.fetch(:status) == 'accepted'
          record_cdt_fallback(timing, cdt_failure_reason_for(result))
          @last_cdt_patch_timing = finalize_cdt_timing(timing)
          return nil
        end

        emit_generated_cdt_mesh(
          owner: owner,
          state: state,
          terrain_state_summary: terrain_state_summary,
          output_plan: plan,
          mesh: result.fetch(:mesh),
          timing: timing,
          replace_existing: true
        )
        cdt_generated_result(result, terrain_state_summary)
      end

      def cdt_generation_attemptable?(plan, feature_context)
        cdt_backend && cdt_regeneration_eligible?(plan, feature_context)
      end

      def cdt_regeneration_attemptable?(plan, feature_context)
        cdt_patch_replacement_eligible?(plan, feature_context) ||
          global_cdt_regeneration_eligible?(plan, feature_context)
      end

      def cdt_result_or_strict_refusal(cdt_result, cdt_attempted)
        return cdt_result if cdt_result
        return nil if fallback_on_cdt_failure?
        return nil unless cdt_attempted || cdt_enabled?

        cdt_output_not_accepted_refusal
      end

      def build_global_cdt_result(state:, terrain_state_summary:, plan:, feature_context:,
                                  timing: nil)
        return nil unless global_cdt_regeneration_eligible?(plan, feature_context)

        timed_cdt_solve(timing) do
          cdt_backend.build(
            state: feature_context[:terrainState] || feature_context['terrainState'] || state,
            feature_geometry: feature_context[:featureGeometry] ||
              feature_context['featureGeometry'],
            primitive_request: feature_context[:primitiveRequest] ||
              feature_context['primitiveRequest'] ||
              {},
            state_digest: terrain_state_summary.fetch(:digest, nil)
          )
        end
      rescue StandardError
        record_cdt_fallback(timing, :backend_exception)
        nil
      end

      def cdt_patch_regeneration_attempt(owner:, state:, terrain_state_summary:, plan:,
                                         feature_context:)
        return nil unless cdt_patch_replacement_eligible?(plan, feature_context)

        regenerate_cdt_patch(
          owner: owner,
          state: state,
          terrain_state_summary: terrain_state_summary,
          plan: plan,
          feature_context: feature_context
        )
      end

      def global_cdt_regeneration_eligible?(plan, feature_context)
        cdt_backend && cdt_regeneration_eligible?(plan, feature_context)
      end

      def cdt_regeneration_eligible?(plan, feature_context)
        return false unless feature_context
        return false if cdt_participation_skipped?(feature_context)
        return false if plan.intent == :dirty_window && !cdt_feature_geometry?(feature_context)

        true
      end

      def cdt_patch_replacement_eligible?(plan, feature_context)
        # MTA-34 retained infrastructure: this must stay dormant until MTA-35
        # supplies stable CDT-owned patch output and injects a real provider.
        return false unless cdt_patch_replacement_provider
        return false unless plan.intent == :dirty_window
        return false unless plan.adaptive_patch_policy

        cdt_regeneration_eligible?(plan, feature_context)
      end

      def cdt_patch_bootstrap_eligible?(plan, feature_context)
        return false unless cdt_patch_replacement_provider
        return false unless plan.intent == :full_grid
        return false unless plan.adaptive_patch_policy

        cdt_regeneration_eligible?(plan, feature_context)
      end

      def generate_cdt_patch_bootstrap(owner:, state:, terrain_state_summary:, plan:,
                                       feature_context:, replace_existing: false)
        return nil unless cdt_patch_bootstrap_eligible?(plan, feature_context)

        timing = cdt_bootstrap_timing(plan)
        batch_plan = timing.measure(:cdt_input_build) do
          cdt_bootstrap_batch_plan(
            state: state,
            terrain_state_summary: terrain_state_summary,
            plan: plan,
            feature_context: feature_context
          )
        end
        replacement = build_cdt_patch_replacement(
          batch_plan: batch_plan,
          state: state,
          feature_context: feature_context,
          timing: timing
        )
        merge_cdt_timing!(timing, replacement.timing) if replacement.respond_to?(:timing)
        fallback = cdt_replacement_fallback_result(replacement, timing)
        return nil if fallback

        timing.measure(:mutation) do
          if replace_existing
            derived_output_store.erase_entities(
              owner.entities,
              derived_output_store.derived_output_entities(owner.entities)
            )
          end
          emitted_faces = emit_cdt_mesh_via_builder(
            owner.entities,
            replacement.mesh,
            ownership: cdt_patch_ownership_context(replacement, state: state)
          )
          timing.measure(:registry_write) do
            write_cdt_patch_registry(owner: owner, replacement: replacement, faces: emitted_faces)
          end
        end
        @last_cdt_patch_timing = finalize_cdt_timing(timing)
        cdt_generated_result({ mesh: replacement.mesh }, terrain_state_summary)
      rescue StandardError
        record_cdt_fallback(timing, :pre_mutation_exception)
        @last_cdt_patch_timing = finalize_cdt_timing(timing)
        nil
      end

      def regenerate_cdt_patch(owner:, state:, terrain_state_summary:, plan:, feature_context:)
        mutation_started = false
        timing = PatchLifecycle::PatchTiming.new
        merge_cdt_timing!(timing, feature_context)
        batch_plan = timing.measure(:cdt_input_build) do
          cdt_patch_batch_plan(
            owner: owner,
            state: state,
            terrain_state_summary: terrain_state_summary,
            plan: plan,
            feature_context: feature_context,
            timing: timing
          )
        end
        replacement = build_cdt_patch_replacement(
          batch_plan: batch_plan,
          state: state,
          feature_context: feature_context,
          timing: timing
        )
        merge_cdt_timing!(timing, replacement.timing) if replacement.respond_to?(:timing)
        fallback = cdt_replacement_fallback_result(replacement, timing)
        return fallback if fallback

        ownership = timing.measure(:ownership_lookup) do
          owned_cdt_patch_faces(
            owner: owner,
            entities: owner.entities,
            patch_ids: replacement.replacement_patch_ids
          )
        end
        if ownership.fetch(:outcome) == :refused
          @last_cdt_patch_timing = finalize_cdt_timing(timing)
          return cdt_ownership_refusal
        end
        fallback = cdt_ownership_fallback_result(ownership, timing)
        return fallback if fallback

        seam = timing.measure(:seam_validation) do
          cdt_patch_seam_validator.validate(
            replacement_spans: replacement.border_spans,
            preserved_neighbor_spans: batch_plan.retained_boundary_spans
          )
        end
        fallback = cdt_seam_fallback_result(seam, timing)
        return fallback if fallback

        mutation_started = true
        mutate_cdt_patch_replacement(owner, replacement, state, ownership, timing)
        @last_cdt_patch_timing = finalize_cdt_timing(timing)
        cdt_generated_result({ mesh: replacement.mesh }, terrain_state_summary)
      rescue StandardError
        raise if mutation_started

        cdt_patch_fallback(timing, :pre_mutation_exception)
      end

      def replacement_accepted?(replacement)
        replacement.respond_to?(:accepted?) && replacement.accepted?
      end

      def mutate_cdt_patch_replacement(owner, replacement, state, ownership, timing)
        timing.measure(:mutation) do
          erase_partial_output(owner.entities, ownership.fetch(:faces))
          emitted_faces = emit_cdt_mesh_via_builder(
            owner.entities,
            replacement.mesh,
            ownership: cdt_patch_ownership_context(replacement, state: state)
          )
          timing.measure(:registry_write) do
            write_cdt_patch_registry(owner: owner, replacement: replacement, faces: emitted_faces)
          end
          derived_output_store.cleanup_orphan_derived_edges(owner.entities)
        end
      end

      def cdt_replacement_fallback_result(replacement, timing)
        return nil if replacement_accepted?(replacement)

        cdt_patch_fallback(timing, cdt_failure_reason_for(replacement))
      end

      def cdt_ownership_fallback_result(ownership, timing)
        return nil if ownership.fetch(:outcome) == :owned

        cdt_patch_fallback(timing, ownership.fetch(:reason, :ownership_missing))
      end

      def cdt_seam_fallback_result(seam, timing)
        return nil if seam.fetch(:status) == 'passed'

        cdt_patch_fallback(timing, seam.fetch(:reason, :seam_validation_failed))
      end

      def cdt_patch_seam_validator
        return seam_validator if seam_validator

        require_relative 'cdt/patches/patch_cdt_seam_validator'
        @seam_validator = PatchCdtSeamValidator.new
      end

      def build_cdt_patch_replacement(batch_plan:, state:, feature_context:, timing:)
        timing.measure(:solve) do
          cdt_patch_replacement_provider.build(
            batch_plan: batch_plan,
            state: state,
            feature_geometry: feature_context[:featureGeometry] ||
              feature_context['featureGeometry'],
            feature_context: feature_context
          )
        end
      end

      def cdt_patch_batch_plan(owner:, state:, terrain_state_summary:, plan:, feature_context:,
                               timing: nil)
        # Resolve the lifecycle dirty window into stable PatchLifecycle CDT domains.
        resolver = PatchLifecycle::PatchWindowResolver.new(
          policy: plan.adaptive_patch_policy,
          dimensions: state.dimensions
        )
        resolution = resolver.resolve(cell_window: plan.cell_window)
        retained_boundary_spans = timed_retained_boundary_snapshot(
          timing,
          owner.entities,
          resolution.fetch(:replacementPatchIds),
          state: state,
          patch_domains: plan.adaptive_patch_policy.patch_domains(state.dimensions)
        )
        CdtPatchBatchPlan.from_lifecycle_resolution(
          lifecycle_resolution: resolution,
          terrain_state_summary: terrain_state_summary,
          feature_plan: cdt_patch_feature_plan(feature_context),
          retained_boundary_spans: retained_boundary_spans
        )
      end

      def cdt_bootstrap_batch_plan(state:, terrain_state_summary:, plan:, feature_context:)
        patches = plan.adaptive_patch_policy.patch_domains(state.dimensions)
        patch_ids = patches.map { |patch| patch.fetch(:patchId) }
        CdtPatchBatchPlan.from_lifecycle_resolution(
          lifecycle_resolution: {
            affectedPatchIds: patch_ids,
            replacementPatchIds: patch_ids,
            affectedPatches: patches,
            replacementPatches: patches
          },
          terrain_state_summary: terrain_state_summary,
          feature_plan: cdt_patch_feature_plan(feature_context),
          retained_boundary_spans: []
        )
      end

      def cdt_patch_feature_plan(feature_context)
        feature_context.fetch(:patchFeaturePlan) do
          feature_context.fetch('patchFeaturePlan', feature_context)
        end
      end

      def merge_cdt_timing!(timing, source)
        timing_data = nil
        if source.respond_to?(:fetch)
          timing_data = source.fetch(:cdtTiming) do
            source.fetch('cdtTiming', nil)
          end
        end
        timing_data ||= source if source.is_a?(Hash) && (
          source.key?(:buckets) || source.key?('buckets')
        )
        timing.merge!(timing_data) if timing_data
      end

      def cdt_bootstrap_timing(plan)
        return nil unless plan.adaptive_patch_policy

        PatchLifecycle::PatchTiming.new
      end

      def timed_cdt_solve(timing, &block)
        return block.call unless timing

        timing.measure(:solve, &block)
      end

      def timed_retained_boundary_snapshot(timing, entities, replacement_patch_ids, state: nil,
                                           patch_domains: [])
        unless timing
          return preserved_cdt_neighbor_spans(
            entities,
            replacement_patch_ids,
            state: state,
            patch_domains: patch_domains
          )
        end

        timing.measure(:retained_boundary_snapshot) do
          preserved_cdt_neighbor_spans(
            entities,
            replacement_patch_ids,
            state: state,
            patch_domains: patch_domains
          )
        end
      end

      def record_cdt_fallback(timing, reason = :not_accepted)
        @last_cdt_failure_reason = reason.to_s
        timing&.record(:fallback_route, 0.0)
      end

      def cdt_patch_fallback(timing, reason = :not_accepted)
        record_cdt_fallback(timing, reason)
        @last_cdt_patch_timing = finalize_cdt_timing(timing)
        :fallback
      end

      def cdt_failure_reason_for(result)
        return :not_accepted unless result

        return normalized_cdt_failure_reason(result.stop_reason) if result.respond_to?(:stop_reason)

        if result.respond_to?(:fetch)
          reason = result.fetch(:fallbackReason) do
            result.fetch('fallbackReason') do
              result.fetch(:stopReason) do
                result.fetch('stopReason', :not_accepted)
              end
            end
          end
          return normalized_cdt_failure_reason(reason)
        end
        :not_accepted
      end

      def normalized_cdt_failure_reason(reason)
        value = reason.to_s
        return :not_accepted if value.empty?

        value
      end

      def finalize_cdt_timing(timing)
        return nil unless timing

        timing.measure(:audit) { nil }
        timing.to_h
      end

      def cdt_participation_skipped?(feature_context)
        participation = feature_context[:cdtParticipation] || feature_context['cdtParticipation']
        return false unless participation.is_a?(Hash)

        (participation[:status] || participation['status']) == 'skip'
      end

      def cdt_feature_geometry?(feature_context)
        feature_geometry = feature_context[:featureGeometry] || feature_context['featureGeometry']
        feature_geometry.respond_to?(:feature_geometry_digest) &&
          feature_geometry.respond_to?(:protected_regions) &&
          feature_geometry.respond_to?(:reference_segments)
      end

      def cdt_generated_result(result, terrain_state_summary)
        mesh = result.fetch(:mesh)
        {
          outcome: 'generated',
          summary: {
            derivedMesh: {
              meshType: 'adaptive_tin',
              vertexCount: mesh.fetch(:vertices).length,
              faceCount: mesh.fetch(:triangles).length,
              derivedFromStateDigest: terrain_state_summary.fetch(:digest, nil)
            }
          }
        }
      end

      def emit_cdt_mesh_via_builder(entities, mesh, ownership: nil)
        unless entities.respond_to?(:build)
          return emit_cdt_mesh(entities, mesh,
                               ownership: ownership)
        end

        emitted_faces = []
        entities.build do |builder|
          emitted_faces = emit_cdt_mesh(builder, mesh, ownership: ownership)
        end
        emitted_faces
      end

      def emit_cdt_mesh(face_target, mesh, ownership:)
        raw_vertices = mesh.fetch(:vertices).map do |vertex|
          vertex.map(&:to_f)
        end
        vertices = raw_vertices.map do |vertex|
          vertex.map { |coordinate| vertex_projector.internal_length(coordinate) }
        end
        mesh.fetch(:triangles).each_with_index.map do |triangle, index|
          regular_grid_mesh_emitter.add_derived_face(
            face_target,
            *triangle.map { |index| vertices.fetch(index) },
            ownership: cdt_face_ownership(ownership, index, raw_vertices, triangle)
          )
        end
      end

      def generate_adaptive(owner:, state:, output_plan:)
        if output_plan.adaptive_patch_policy
          return apply_adaptive_patch_output(
            adaptive_patch_output_generator.generate(
              owner: owner,
              state: state,
              output_plan: output_plan
            )
          )
        end

        regular_grid_mesh_emitter.emit_adaptive_faces_via_builder(
          owner.entities,
          state,
          output_plan.adaptive_cells
        )
        generated_result(output_plan)
      end

      def regenerate_adaptive(owner:, state:, output_plan:)
        return no_data_refusal if state.elevations.any?(&:nil?)

        if output_plan.adaptive_patch_policy
          return apply_adaptive_patch_output(
            adaptive_patch_output_generator.regenerate(
              owner: owner,
              state: state,
              output_plan: output_plan
            )
          )
        end

        derived_output_store.erase_entities(
          owner.entities,
          derived_output_store.derived_output_entities(owner.entities)
        )
        generate_adaptive(owner: owner, state: state, output_plan: output_plan)
      end

      def patch_registry_store
        PatchLifecycle::PatchRegistryStore.new(registry_key: ADAPTIVE_PATCH_REGISTRY_KEY)
      end

      def write_cdt_patch_registry(owner:, replacement:, faces:)
        write_cdt_patch_registry_records(
          owner: owner,
          patches: replacement.replacement_patches,
          replacement_batch_id: replacement.replacement_batch_id,
          policy_fingerprint: replacement.policy_fingerprint,
          state_digest: replacement.state_digest,
          state_revision: nil,
          faces: faces
        )
      end

      def write_cdt_patch_registry_records(
        owner:,
        patches:,
        replacement_batch_id:,
        policy_fingerprint:,
        state_digest:,
        state_revision:,
        faces:
      )
        patch_ids = patches.to_set { |patch| patch.fetch(:patchId) }
        new_face_counts = Array(faces).group_by do |face|
          output_attribute(face, CDT_PATCH_ID_KEY)
        end.transform_values(&:length)
        patch_records = patches.map do |patch|
          CdtLifecycleOwnership.registry_patch_record(
            patch: patch,
            replacement_batch_id: replacement_batch_id,
            face_count: new_face_counts.fetch(patch.fetch(:patchId), 0)
          )
        end

        store = patch_registry_store
        existing = store.read(owner)
        retained = existing.fetch(:patches, []).reject do |patch|
          patch_ids.include?(patch.fetch(:patchId))
        end
        store.write!(
          owner: owner,
          registry: {
            outputPolicyFingerprint: policy_fingerprint,
            stateDigest: state_digest,
            stateRevision: state_revision,
            ownerTransformSignature: nil,
            patches: retained + patch_records
          }
        )
      end

      def ownership_context
        {}
      end

      def regenerate_partial(owner:, state:, output_plan:)
        return nil unless output_plan.intent == :dirty_window
        return nil if output_plan.cell_window.empty? || output_plan.cell_window.whole_grid?

        ownership = derived_output_store.owned_faces_for_cell_window(
          owner.entities,
          output_plan.cell_window
        )
        return nil unless ownership.fetch(:outcome) == :owned

        rows = state.dimensions.fetch('rows')
        columns = state.dimensions.fetch('columns')
        vertices = vertex_projector.vertices_for(state, columns, rows)
        erase_partial_output(owner.entities, ownership.fetch(:faces))
        regular_grid_mesh_emitter.emit_cell_window_via_builder(
          owner.entities,
          vertices,
          columns,
          output_plan.cell_window,
          ownership_context
        )
        derived_output_store.cleanup_orphan_derived_edges(owner.entities)
        generated_result(output_plan)
      end

      def no_data_refusal
        {
          outcome: 'refused',
          refusal: {
            code: 'adaptive_output_generation_failed',
            message: 'Adaptive terrain output cannot be generated from no-data samples.',
            details: { category: 'no_data_samples' }
          }
        }
      end

      def cdt_output_not_accepted_refusal
        {
          outcome: 'refused',
          refusal: {
            code: 'terrain_output_generation_failed',
            message: 'Terrain output could not be generated by the selected output mode.',
            details: {
              category: 'selected_output_mode',
              action: 'use a supported output mode or repair the selected output implementation'
            }
          }
        }
      end

      def owned_cdt_patch_faces(owner:, entities:, patch_ids:)
        wanted = patch_ids.to_set
        faces = derived_output_store.derived_output_entities(entities).select do |entity|
          derived_face_entity?(entity) &&
            output_attribute(entity, OUTPUT_KIND_KEY) == CDT_PATCH_OUTPUT_KIND &&
            wanted.include?(output_attribute(entity, CDT_PATCH_ID_KEY))
        end
        return derived_output_store.fallback_ownership(:missing_ownership) if faces.empty?

        registry = patch_registry_store.read(owner)
        return { outcome: :refused, reason: :registry_invalid } unless
          registry.fetch(:status) == 'valid'

        patch_face_counts = registry.fetch(:patches, []).to_h do |patch|
          [patch.fetch(:patchId), patch.fetch(:faceCount)]
        end
        faces_by_patch = faces.group_by { |face| output_attribute(face, CDT_PATCH_ID_KEY) }
        patch_ids.each do |patch_id|
          patch_faces = faces_by_patch.fetch(patch_id, [])
          expected = patch_face_counts.fetch(patch_id, nil)
          return { outcome: :refused, reason: :ownership_integrity_mismatch } unless
            cdt_patch_ownership_complete?(patch_faces, expected_face_count: expected)
        end
        { outcome: :owned, faces: faces }
      end

      def cdt_patch_ownership_complete?(faces, expected_face_count:)
        return false unless expected_face_count.is_a?(Integer) && expected_face_count.positive?
        return false unless faces.length == expected_face_count

        by_index = {}
        faces.each do |face|
          return false unless cdt_owned_face_complete?(face)

          index = output_attribute(face, CDT_PATCH_FACE_INDEX_KEY)
          return false if by_index.key?(index)

          by_index[index] = face
        end
        by_index.keys.sort == (0...expected_face_count).to_a
      end

      def cdt_owned_face_complete?(face)
        [
          CDT_OWNERSHIP_SCHEMA_VERSION_KEY,
          CDT_PATCH_ID_KEY,
          CDT_REPLACEMENT_BATCH_ID_KEY,
          CDT_PATCH_FACE_INDEX_KEY
        ].all? { |key| !output_attribute(face, key).nil? }
      end

      def preserved_cdt_neighbor_spans(entities, replacement_patch_ids, state: nil,
                                       patch_domains: [])
        replacement = replacement_patch_ids.to_set
        patch_domains_by_id = patch_domains_by_id(patch_domains)
        span_groups = {}
        derived_output_store.derived_output_entities(entities).each do |entity|
          add_retained_boundary_entity!(
            span_groups: span_groups,
            entity: entity,
            replacement: replacement,
            state: state,
            patch_domains_by_id: patch_domains_by_id
          )
        end
        span_groups.values.filter_map { |group| retained_boundary_span(group) }
      end

      def add_retained_boundary_entity!(span_groups:, entity:, replacement:, state:,
                                        patch_domains_by_id:)
        return unless derived_face_entity?(entity)
        return unless output_attribute(entity, OUTPUT_KIND_KEY) == CDT_PATCH_OUTPUT_KIND

        patch_id = output_attribute(entity, CDT_PATCH_ID_KEY)
        return if replacement.include?(patch_id)

        side = output_attribute(entity, CDT_BORDER_SIDE_KEY)
        return unless retained_boundary_entity_side?(patch_id, side, replacement)

        group = span_groups[[patch_id, side]] ||= retained_boundary_group(
          patch_id,
          side,
          state: state,
          patch_domain: patch_domains_by_id[patch_id]
        )
        group.fetch(:vertices).concat(border_points_for_side(entity_points(entity), side))
        group[:fresh] &&= cdt_owned_face_complete?(entity)
      end

      def retained_boundary_entity_side?(patch_id, side, replacement)
        side && cdt_adjacent_to_replacement?(patch_id, side, replacement)
      end

      def border_points_for_side(points, side)
        axis = %w[east west].include?(side) ? 0 : 1
        value = if %w[east north].include?(side)
                  points.map { |point| point[axis] }.max
                else
                  points.map { |point| point[axis] }.min
                end
        points.select { |point| (point[axis].to_f - value.to_f).abs <= 1e-6 }
              .sort_by { |point| axis.zero? ? point[1] : point[0] }
      end

      def retained_boundary_group(patch_id, side, state: nil, patch_domain: nil)
        {
          side: side,
          spanId: "#{side}-0",
          patchId: patch_id,
          fresh: true,
          protectedBoundaryCrossing: false,
          vertices: retained_boundary_expected_endpoints(
            state: state,
            patch_domain: patch_domain,
            side: side
          )
        }
      end

      def retained_boundary_span(group)
        vertices = ordered_unique_border_vertices(group.fetch(:vertices), group.fetch(:side))
        return nil if vertices.length < 2

        group.merge(vertices: vertices)
      end

      def ordered_unique_border_vertices(vertices, side)
        unique = {}
        vertices.each do |vertex|
          unique[[vertex[0].to_f, vertex[1].to_f]] ||= vertex
        end
        axis = %w[east west].include?(side) ? 1 : 0
        unique.values.sort_by { |vertex| [vertex[axis].to_f, vertex[axis.zero? ? 1 : 0].to_f] }
      end

      def retained_boundary_expected_endpoints(state:, patch_domain:, side:)
        return [] unless state && patch_domain

        endpoints = retained_boundary_endpoint_indices(patch_domain, side)
        endpoints.map { |column, row| state_vertex_at(state, column, row) }
      rescue KeyError, TypeError
        []
      end

      def retained_boundary_endpoint_indices(patch_domain, side)
        sample_bounds = value_from_hash(patch_domain, :sampleBounds)
        bounds = value_from_hash(patch_domain, :bounds)
        case side.to_s
        when 'west'
          vertical_side_endpoint_indices(sample_bounds, value_from_hash(sample_bounds, :minColumn))
        when 'east'
          vertical_side_endpoint_indices(sample_bounds, value_from_hash(bounds, :maxColumn) + 1)
        when 'south'
          horizontal_side_endpoint_indices(sample_bounds, value_from_hash(sample_bounds, :minRow))
        when 'north'
          horizontal_side_endpoint_indices(sample_bounds, value_from_hash(bounds, :maxRow) + 1)
        else
          []
        end
      end

      def vertical_side_endpoint_indices(sample_bounds, column)
        [
          [column, value_from_hash(sample_bounds, :minRow)],
          [column, value_from_hash(sample_bounds, :maxRow)]
        ]
      end

      def horizontal_side_endpoint_indices(sample_bounds, row)
        [
          [value_from_hash(sample_bounds, :minColumn), row],
          [value_from_hash(sample_bounds, :maxColumn), row]
        ]
      end

      def state_vertex_at(state, column, row)
        vertex_projector.state_vertex_at(state, column, row)
      end

      def height_at_grid(state, column, row)
        vertex_projector.height_at_grid(state, column, row)
      end

      def height_oracle_for(state)
        return height_oracle if height_oracle && state.equal?(@height_oracle_state)

        ComposedHeightOracle.build(state: state)
      end

      def value_from_hash(hash, key)
        hash.fetch(key) { hash.fetch(key.to_s) }
      end

      def patch_domains_by_id(patch_domains)
        patch_domains.to_h do |patch|
          [value_from_hash(patch, :patchId), patch]
        end
      end

      def entity_points(entity)
        return entity.points if entity.respond_to?(:points)
        return entity.vertices.map { |vertex| point_to_a(vertex.position) } if
          entity.respond_to?(:vertices)

        []
      end

      def point_to_a(point)
        [
          length_converter.internal_to_public_meters(point.x),
          length_converter.internal_to_public_meters(point.y),
          length_converter.internal_to_public_meters(point.z)
        ]
      end

      def legacy_owned_face?(face)
        derived_output_store.legacy_owned_face?(face)
      end

      def cell_in_window?(cell_window, column, row)
        derived_output_store.cell_in_window?(cell_window, column, row)
      end

      def output_attribute(entity, key)
        derived_output_store.output_attribute(entity, key)
      end

      def cdt_patch_ownership_context(replacement, state:)
        cdt_patch_ownership_context_for(
          patches: replacement.replacement_patches,
          replacement_batch_id: replacement.replacement_batch_id,
          state_digest: replacement.state_digest,
          policy_fingerprint: replacement.policy_fingerprint,
          state: state
        )
      end

      def cdt_bootstrap_ownership_context(state:, terrain_state_summary:, output_plan:, patches:)
        cdt_patch_ownership_context_for(
          patches: patches,
          replacement_batch_id: cdt_bootstrap_batch_id(terrain_state_summary),
          state_digest: terrain_state_summary.fetch(:digest, nil),
          policy_fingerprint: output_plan.adaptive_patch_policy.output_policy_fingerprint,
          state: state
        )
      end

      def cdt_bootstrap_batch_id(terrain_state_summary)
        "cdt-bootstrap-#{terrain_state_summary.fetch(:digest, nil)}"
      end

      def cdt_patch_ownership_context_for(
        patches:,
        replacement_batch_id:,
        state_digest:,
        policy_fingerprint:,
        state:
      )
        {
          kind: :cdt_patch,
          patches: cdt_patch_output_bounds(patches, state),
          replacement_batch_id: replacement_batch_id,
          state_digest: state_digest,
          policy_fingerprint: policy_fingerprint,
          face_indexes_by_patch: Hash.new(0)
        }
      end

      def cdt_face_ownership(ownership, index, vertices, triangle)
        return nil unless ownership

        if ownership[:kind] == :cdt_patch
          return cdt_patch_face_ownership(ownership, index, vertices, triangle)
        end

        side = cdt_border_side_for(vertices, triangle)
        ownership.merge(
          patch_face_index: index,
          side: side,
          span_id: side ? "#{side}-0" : nil
        )
      end

      def cdt_patch_face_ownership(ownership, index, vertices, triangle)
        patch = cdt_patch_for_triangle(ownership.fetch(:patches), vertices, triangle)
        patch_id = patch.fetch(:patchId)
        patch_face_index = cdt_patch_face_index(ownership, patch_id, index)
        side = cdt_patch_border_side_for(patch, vertices, triangle)
        CdtLifecycleOwnership.face_ownership(
          patch_id: patch_id,
          patch_face_index: patch_face_index,
          replacement_batch_id: ownership.fetch(:replacement_batch_id),
          state_digest: ownership.fetch(:state_digest),
          policy_fingerprint: ownership.fetch(:policy_fingerprint)
        ).merge(
          side: side,
          span_id: side ? "#{side}-0" : nil
        )
      end

      def cdt_patch_face_index(ownership, patch_id, fallback_index)
        indexes = ownership[:face_indexes_by_patch]
        return fallback_index unless indexes

        index = indexes[patch_id]
        indexes[patch_id] = index + 1
        index
      end

      def cdt_patch_for_triangle(patches, vertices, triangle)
        centroid = triangle_centroid(vertices, triangle)
        patches.find do |patch|
          bounds = patch.fetch(:output_bounds)
          centroid.fetch(:x).between?(bounds.fetch(:min_x), bounds.fetch(:max_x)) &&
            centroid.fetch(:y).between?(bounds.fetch(:min_y), bounds.fetch(:max_y))
        end || patches.fetch(0)
      end

      def triangle_centroid(vertices, triangle)
        points = triangle.map { |vertex_index| vertices.fetch(vertex_index) }
        {
          x: points.sum { |point| point.fetch(0) } / points.length.to_f,
          y: points.sum { |point| point.fetch(1) } / points.length.to_f
        }
      end

      def cdt_patch_output_bounds(patches, state)
        patches.map do |patch|
          bounds = patch.fetch(:bounds)
          patch.merge(
            output_bounds: {
              min_x: patch_bound(state, bounds, :minColumn, 'x'),
              min_y: patch_bound(state, bounds, :minRow, 'y'),
              max_x: state.origin.fetch('x') +
                ((bounds.fetch(:maxColumn) + 1) * state.spacing.fetch('x')),
              max_y: state.origin.fetch('y') +
                ((bounds.fetch(:maxRow) + 1) * state.spacing.fetch('y'))
            }
          )
        end
      end

      def patch_bound(state, bounds, key, axis)
        state.origin.fetch(axis) + (bounds.fetch(key) * state.spacing.fetch(axis))
      end

      def cdt_adjacent_to_replacement?(patch_id, side, replacement_patch_ids)
        coords = cdt_patch_coords(patch_id)
        return false unless coords

        adjacent = case side
                   when 'west'
                     coords.merge(column: coords.fetch(:column) - 1)
                   when 'east'
                     coords.merge(column: coords.fetch(:column) + 1)
                   when 'south'
                     coords.merge(row: coords.fetch(:row) - 1)
                   when 'north'
                     coords.merge(row: coords.fetch(:row) + 1)
                   end
        return false unless adjacent
        return false if adjacent.fetch(:column).negative? || adjacent.fetch(:row).negative?

        replacement_patch_ids.include?(
          cdt_patch_id_for_coords(patch_id, adjacent.fetch(:column), adjacent.fetch(:row))
        )
      end

      def cdt_patch_coords(patch_id)
        match = patch_id.to_s.match(/\A(?<prefix>.+)-c(?<column>\d+)-r(?<row>\d+)\z/)
        return nil unless match

        {
          prefix: match[:prefix],
          column: match[:column].to_i,
          row: match[:row].to_i
        }
      end

      def cdt_patch_id_for_coords(reference_patch_id, column, row)
        coords = cdt_patch_coords(reference_patch_id)
        return nil unless coords

        "#{coords.fetch(:prefix)}-c#{column}-r#{row}"
      end

      def cdt_patch_border_side_for(patch, vertices, triangle)
        points = triangle.map { |vertex_index| vertices.fetch(vertex_index) }
        bounds = patch.fetch(:output_bounds)
        definition = CDT_BORDER_SIDE_DEFINITIONS.find do |_side, axis, limit|
          key = axis.zero? ? :x : :y
          bound_key = :"#{limit}_#{key}"
          values = points.map { |point| point[axis].to_f }
          values.count { |value| (value - bounds.fetch(bound_key)).abs <= 1e-6 } >= 2
        end
        definition&.first
      end

      def cdt_border_side_for(vertices, triangle)
        points = triangle.map { |vertex_index| vertices.fetch(vertex_index) }
        bounds = mesh_bounds(vertices)
        definition = CDT_BORDER_SIDE_DEFINITIONS.find do |_side, axis, limit|
          values = points.map { |point| point[axis] }
          values.count { |value| value == bounds.fetch(axis).fetch(limit) } >= 2
        end
        definition&.first
      end

      def mesh_bounds(vertices)
        {
          0 => { min: vertices.map { |point| point[0] }.min,
                 max: vertices.map { |point| point[0] }.max },
          1 => { min: vertices.map { |point| point[1] }.min,
                 max: vertices.map { |point| point[1] }.max }
        }
      end

      def erase_partial_output(entities, faces)
        derived_output_store.erase_partial_output(entities, faces)
      end

      def derived_face_entity?(entity)
        derived_output_store.derived_face_entity?(entity)
      end

      def derived_output?(entity)
        derived_output_store.derived_output?(entity)
      end

      def unsupported_children_refusal(types)
        {
          outcome: 'refused',
          refusal: {
            code: 'terrain_output_contains_unsupported_entities',
            message: 'Terrain owner contains unsupported child entities.',
            details: {
              unsupportedChildTypes: types.uniq,
              action: 'remove unsupported children or recreate the managed terrain output'
            }
          }
        }
      end

      def cdt_ownership_refusal
        {
          outcome: 'refused',
          refusal: {
            code: 'terrain_output_ownership_invalid',
            message: 'Terrain output ownership metadata is invalid.',
            details: {
              category: 'derived_output_ownership',
              action: 'recreate the managed terrain output'
            }
          }
        }
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/ClassLength
  end
end
