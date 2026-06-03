# frozen_string_literal: true

require 'json'

require_relative '../../../test_helper'
require_relative '../../../support/semantic_test_support'
require_relative '../../../../src/su_mcp/terrain/output/adaptive_patches/output_generator'
require_relative '../../../../src/su_mcp/terrain/output/adaptive_patches/adaptive_patch_policy'
require_relative '../../../../src/su_mcp/terrain/output/derived_output_entity_store'
require_relative '../../../../src/su_mcp/terrain/output/regular_grid_mesh_emitter'
require_relative '../../../../src/su_mcp/terrain/output/terrain_output_plan'
require_relative '../../../../src/su_mcp/terrain/output/terrain_vertex_projector'
require_relative '../../../../src/su_mcp/terrain/state/tiled_heightmap_state'

module SU_MCP
  module Terrain
    module AdaptivePatches
      class OutputGeneratorTest < Minitest::Test
        include SemanticTestSupport

        OverBudgetFixture = Struct.new(
          :owner,
          :state,
          :mesh,
          :old_faces,
          :dirty,
          :generator,
          :store,
          keyword_init: true
        )

        def test_generate_returns_result_timing_and_seam_summary
          model = build_semantic_model
          owner = model.active_entities.add_group
          state = build_state(columns: 3, rows: 3)
          plan = TerrainOutputPlan.full_grid(
            state: state,
            terrain_state_summary: { digest: 'digest-1', revision: 1 },
            adaptive_patch_policy: patch_policy
          )

          output = generator.generate(owner: owner, state: state, output_plan: plan)

          assert_instance_of(OutputResult, output)
          assert_equal('generated', output.result.fetch(:outcome))
          assert(output.timing.fetch(:buckets).key?(:mutation))
          assert_equal('passed', output.seam_validation_summary.fetch(:status))
          assert_equal(1, owner.entities.groups.length)
        end

        def test_dirty_regeneration_keeps_over_budget_component_on_partial_path
          fixture = over_budget_fixture

          assert_equal(
            'over_budget',
            fixture.dirty.adaptive_lifecycle_resolution.dig(:componentBudget, :status)
          )
          output = fixture.generator.regenerate(
            owner: fixture.owner,
            state: fixture.state,
            output_plan: fixture.dirty
          )

          assert_equal('generated', output.result.fetch(:outcome))
          assert_partial_over_budget_replacement(fixture)
        end

        private

        def over_budget_fixture
          model = build_semantic_model
          owner = model.active_entities.add_group
          state = build_state(columns: 17, rows: 17)
          policy = AdaptivePatchPolicy.new(patch_cell_size: 4)
          store = RecordingDerivedOutputEntityStore.new
          adaptive_generator = seeded_generator(owner, state, policy, store)
          mesh = owner.entities.groups.first
          OverBudgetFixture.new(
            owner: owner,
            state: state,
            mesh: mesh,
            old_faces: mesh.entities.faces.dup,
            dirty: over_budget_dirty_plan(state, policy),
            generator: adaptive_generator,
            store: store
          )
        end

        def seeded_generator(owner, state, policy, store)
          adaptive_generator = generator(store: store)
          adaptive_generator.generate(
            owner: owner,
            state: state,
            output_plan: adaptive_full_plan(state, 'digest-1', policy)
          )
          store.reset_recorded_calls!
          adaptive_generator
        end

        def over_budget_dirty_plan(state, policy)
          adaptive_dirty_plan_with_sources(
            state,
            'digest-2',
            policy,
            dirty_window(5, 5, 5, 5),
            {
              feature_windows: [dirty_window(0, 0, 15, 15)],
              budget: { maxReplacementPatchCount: 2, maxPromotionRadius: 1 }
            }
          )
        end

        def assert_partial_over_budget_replacement(fixture)
          assert_equal([fixture.mesh], fixture.owner.entities.groups)
          assert_equal(1, fixture.store.partial_erase_calls.length)
          fixture.old_faces.each do |face|
            next unless terrain_attribute(face, 'adaptivePatchId') == 'patch-v1-r1-c1'

            refute_includes(fixture.mesh.entities.faces, face)
          end
          assert_equal(16, adaptive_registry(fixture.owner).fetch(:patches).length)
        end

        def generator(store: DerivedOutputEntityStore.new, vertex_projector: nil)
          projector = vertex_projector || TerrainVertexProjector.new(
            length_converter: ScalingLengthConverter.new(multiplier: 1.0)
          )
          OutputGenerator.new(
            derived_output_store: store,
            mesh_emitter: RegularGridMeshEmitter.new(
              derived_output_store: store,
              vertex_projector: projector
            ),
            vertex_projector: projector
          )
        end

        def adaptive_full_plan(state, digest, policy)
          TerrainOutputPlan.full_grid(
            state: state,
            terrain_state_summary: { digest: digest, revision: state.revision },
            adaptive_patch_policy: policy
          )
        end

        def adaptive_dirty_plan_with_sources(state, digest, policy, window, sources)
          TerrainOutputPlan.dirty_window(
            state: state,
            terrain_state_summary: { digest: digest, revision: state.revision },
            window: window,
            adaptive_patch_policy: policy,
            component_sources: sources
          )
        end

        def dirty_window(min_column, min_row, max_column, max_row)
          SampleWindow.new(
            min_column: min_column,
            min_row: min_row,
            max_column: max_column,
            max_row: max_row
          )
        end

        def terrain_attribute(entity, key)
          entity.get_attribute(DerivedOutputAttributes::DICTIONARY, key)
        end

        def adaptive_registry(owner)
          JSON.parse(
            owner.get_attribute('su_mcp_terrain', 'adaptivePatchRegistry'),
            symbolize_names: true
          )
        end

        def patch_policy
          AdaptivePatchPolicy.new(patch_cell_size: 2)
        end

        def build_state(columns:, rows:, revision: 1, elevations: nil)
          TiledHeightmapState.new(
            basis: {
              'xAxis' => [1.0, 0.0, 0.0],
              'yAxis' => [0.0, 1.0, 0.0],
              'zAxis' => [0.0, 0.0, 1.0],
              'vertical' => 'z_up'
            },
            origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
            spacing: { 'x' => 1.0, 'y' => 1.0 },
            dimensions: { 'columns' => columns, 'rows' => rows },
            elevations: elevations || Array.new(columns * rows, 1.0),
            revision: revision,
            state_id: 'adaptive-output-state'
          )
        end

        class ScalingLengthConverter
          def initialize(multiplier:)
            @multiplier = multiplier
          end

          def public_meters_to_internal(value)
            value.to_f * @multiplier
          end
        end

        class RecordingDerivedOutputEntityStore < DerivedOutputEntityStore
          attr_reader :partial_erase_calls

          def initialize
            super
            @partial_erase_calls = []
          end

          def reset_recorded_calls!
            @partial_erase_calls.clear
          end

          def erase_partial_output(entities, faces)
            @partial_erase_calls << faces
            super
          end
        end
      end
    end
  end
end
