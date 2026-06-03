# frozen_string_literal: true

require_relative '../patch_lifecycle/patch_registry_store'
require_relative '../patch_lifecycle/patch_timing'
require_relative '../patch_lifecycle/patch_window_resolver'
require_relative '../terrain_output_plan'
require_relative 'output_attributes'
require_relative 'output_face_planner'
require_relative 'output_ownership_resolver'
require_relative 'output_registry_writer'
require_relative 'output_result'
require_relative 'output_seam_gate'

module SU_MCP
  module Terrain
    module AdaptivePatches
      # Owns adaptive patch mesh generation and dirty-window replacement.
      class OutputGenerator
        def initialize(
          derived_output_store:,
          mesh_emitter:,
          vertex_projector:,
          patch_registry_store: nil
        )
          @derived_output_store = derived_output_store
          @mesh_emitter = mesh_emitter
          @patch_registry_store = patch_registry_store ||
                                  PatchLifecycle::PatchRegistryStore.new(
                                    registry_key: ADAPTIVE_PATCH_REGISTRY_KEY
                                  )
          @face_planner = OutputFacePlanner.new(vertex_projector: vertex_projector)
          @ownership_resolver = OutputOwnershipResolver.new(
            derived_output_store: derived_output_store,
            patch_registry_store: @patch_registry_store
          )
          @seam_gate = OutputSeamGate.new(patch_registry_store: @patch_registry_store)
          @registry_writer = OutputRegistryWriter.new(
            patch_registry_store: @patch_registry_store,
            seam_gate: @seam_gate
          )
        end

        def generate(owner:, state:, output_plan:)
          timing = PatchLifecycle::PatchTiming.new
          output_plan = full_generation_plan(timing, state, output_plan)
          planned = planned_patch_batch(
            timing,
            state: state,
            output_plan: output_plan,
            patches: all_patch_domains(timing, output_plan, state)
          )
          replace_all_output(owner, output_plan, planned, timing)
          output_result(
            result: generated_result(output_plan),
            timing: timing.to_h,
            seam_validation_summary: seam_gate.summary(output_plan)
          )
        end

        def regenerate(owner:, state:, output_plan:)
          return generate(owner: owner, state: state, output_plan: output_plan) unless
            output_plan.intent == :dirty_window

          timing = PatchLifecycle::PatchTiming.new
          resolution = dirty_lifecycle_resolution(timing, output_plan, state)
          mesh = ownership_resolver.patch_mesh(owner.entities)
          return generate(owner: owner, state: state, output_plan: output_plan) unless mesh

          refusal = pre_mutation_refusal(mesh)
          return output_result(result: refusal) if refusal

          ownership = replacement_ownership(timing, owner, mesh, resolution, output_plan)
          stop_result = ownership_stop_result(owner, state, output_plan, ownership)
          return stop_result if stop_result

          seam_gate_result = retained_seam_gate(owner, output_plan, resolution)
          return seam_gate_result.fetch(:result) unless seam_gate_result.fetch(:passed)

          planned = planned_patch_batch(
            timing,
            state: state,
            output_plan: output_plan,
            patches: resolution.fetch(:replacementPatches)
          )
          replace_dirty_output(mesh, owner, output_plan, planned, ownership, timing)
          output_result(
            result: generated_result(output_plan),
            timing: timing.to_h,
            seam_validation_summary: seam_gate_result.fetch(:summary)
          )
        end

        private

        attr_reader :derived_output_store, :mesh_emitter, :face_planner,
                    :ownership_resolver, :seam_gate, :registry_writer

        def output_result(result:, timing: nil, seam_validation_summary: nil)
          OutputResult.new(
            result: result,
            timing: timing,
            seam_validation_summary: seam_validation_summary
          )
        end

        def generated_result(output_plan)
          {
            outcome: 'generated',
            summary: output_plan.to_summary
          }
        end

        def full_generation_plan(timing, state, output_plan)
          timing.measure(:adaptivePlanning) do
            full_rebuild_plan(state, output_plan)
          end
        end

        def full_rebuild_plan(state, output_plan)
          return output_plan unless output_plan.intent == :dirty_window

          TerrainOutputPlan.full_grid(
            state: state,
            terrain_state_summary: {
              digest: output_plan.state_digest,
              revision: output_plan.state_revision
            },
            adaptive_patch_policy: output_plan.adaptive_patch_policy
          )
        end

        def all_patch_domains(timing, output_plan, state)
          timing.measure(:dirtyWindowMapping) do
            output_plan.adaptive_patch_policy.patch_domains(state.dimensions)
          end
        end

        def planned_patch_batch(timing, state:, output_plan:, patches:)
          timing.measure(:adaptivePlanning) do
            face_planner.batch(state: state, output_plan: output_plan, patches: patches)
          end
        end

        def replace_all_output(owner, output_plan, planned, timing)
          timing.measure(:mutation) do
            derived_output_store.erase_entities(
              owner.entities,
              derived_output_store.derived_output_entities(owner.entities)
            )
            mesh = owner.entities.add_group
            mark_patch_mesh(mesh, output_plan, face_count: 0)
            emit_planned_faces(mesh.entities, planned.fetch(:faces))
            registry_writer.write(
              owner: owner,
              output_plan: output_plan,
              patches: planned.fetch(:patches)
            )
            mark_patch_mesh(
              mesh,
              output_plan,
              face_count: ownership_resolver.entity_faces(mesh.entities).length
            )
          end
        end

        def dirty_lifecycle_resolution(timing, output_plan, state)
          timing.measure(:dirtyWindowMapping) do
            lifecycle_resolution_for(output_plan, state)
          end
        end

        def lifecycle_resolution_for(output_plan, state)
          if output_plan.respond_to?(:adaptive_lifecycle_resolution) &&
             output_plan.adaptive_lifecycle_resolution
            return output_plan.adaptive_lifecycle_resolution
          end

          PatchLifecycle::PatchWindowResolver.new(
            policy: output_plan.adaptive_patch_policy,
            dimensions: state.dimensions
          ).resolve(cell_window: output_plan.cell_window)
        end

        def pre_mutation_refusal(mesh)
          unsupported = derived_output_store.unsupported_child_types(mesh.entities)
          unsupported.empty? ? nil : unsupported_children_refusal(unsupported)
        end

        def replacement_ownership(timing, owner, mesh, resolution, output_plan)
          timing.measure(:ownershipLookup) do
            ownership_resolver.owned_faces(
              owner: owner,
              entities: mesh.entities,
              patch_ids: resolution.fetch(:replacementPatchIds),
              output_plan: output_plan
            )
          end
        end

        def ownership_stop_result(owner, state, output_plan, ownership)
          return output_result(result: ownership_refusal) if ownership.fetch(:outcome) == :refused
          return generate(owner: owner, state: state, output_plan: output_plan) if
            ownership.fetch(:outcome) == :fallback

          nil
        end

        def retained_seam_gate(owner, output_plan, resolution)
          retained = seam_gate.validate_before_mutation(
            owner: owner,
            output_plan: output_plan,
            replacement_patch_ids: resolution.fetch(:replacementPatchIds)
          )
          summary = seam_gate.summary(output_plan, retained_result: retained)
          return { passed: true, summary: summary } if retained.fetch(:status) == :passed

          {
            passed: false,
            result: output_result(result: ownership_refusal, seam_validation_summary: summary)
          }
        end

        def replace_dirty_output(mesh, owner, output_plan, planned, ownership, timing)
          timing.measure(:mutation) do
            derived_output_store.erase_partial_output(mesh.entities, ownership.fetch(:faces))
            emit_planned_faces(mesh.entities, planned.fetch(:faces))
            derived_output_store.cleanup_orphan_derived_edges(mesh.entities)
            mark_patch_mesh(
              mesh,
              output_plan,
              face_count: ownership_resolver.entity_faces(mesh.entities).length
            )
            registry_writer.write(
              owner: owner,
              output_plan: output_plan,
              patches: planned.fetch(:patches)
            )
          end
        end

        def mark_patch_mesh(mesh, output_plan, face_count:)
          derived_output_store.mark_adaptive_patch_mesh(
            mesh,
            batch_id: face_planner.replacement_batch_id(output_plan),
            output_plan: output_plan,
            face_count: face_count
          )
        end

        def emit_planned_faces(entities, faces)
          emitted_faces = []
          unless entities.respond_to?(:build)
            emit_faces_to(entities, faces, emitted_faces)
            return emitted_faces
          end

          entities.build do |builder|
            emit_faces_to(builder, faces, emitted_faces)
          end
        end

        def emit_faces_to(target, faces, emitted_faces)
          faces.each do |face|
            emitted_faces << mesh_emitter.add_derived_face(
              target,
              *face.fetch(:points),
              ownership: face.fetch(:ownership),
              mark_edges: false
            )
          end
          derived_output_store.mark_unique_derived_edges(emitted_faces)
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

        def ownership_refusal
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
    end
  end
end
