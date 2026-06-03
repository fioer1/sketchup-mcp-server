# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../src/su_mcp/terrain/output/adaptive_patches/output_face_planner'
require_relative '../../../../src/su_mcp/terrain/output/adaptive_patches/adaptive_patch_policy'

module SU_MCP
  module Terrain
    module AdaptivePatches
      class OutputFacePlannerTest < Minitest::Test
        def test_batch_reuses_projected_vertices_across_patch_triangles
          projector = CountingVertexProjector.new
          planner = OutputFacePlanner.new(vertex_projector: projector)

          planned = planner.batch(
            state: Object.new,
            output_plan: output_plan,
            patches: [patch]
          )

          assert_equal(2, planned.fetch(:faces).length)
          assert_equal(4, projector.adaptive_vertex_call_count)
          assert_equal(1, planned.fetch(:patches).length)
          assert_equal(2, planned.fetch(:patches).first.fetch(:faceCount))
        end

        private

        def output_plan
          Struct.new(
            :adaptive_cells,
            :state_digest,
            :adaptive_patch_policy,
            :adaptive_seam_records
          ).new(
            adaptive_cells,
            'digest-v2',
            AdaptivePatchPolicy.new(patch_cell_size: 1),
            []
          )
        end

        def adaptive_cells
          [
            {
              min_column: 0,
              min_row: 0,
              max_column: 1,
              max_row: 1,
              emission_triangles: [
                [[0, 0], [1, 0], [1, 1]],
                [[0, 0], [1, 1], [0, 1]]
              ]
            }
          ]
        end

        def patch
          {
            patchId: 'adaptive-patch-v1-c0-r0',
            bounds: {},
            cell_bounds: { min_column: 0, min_row: 0, max_column: 0, max_row: 0 }
          }
        end

        class CountingVertexProjector
          attr_reader :adaptive_vertex_call_count

          def initialize
            @adaptive_vertex_call_count = 0
          end

          def adaptive_vertex_for_planned_point(_state, point)
            @adaptive_vertex_call_count += 1
            [point[0].to_f, point[1].to_f, 1.0]
          end
        end
      end
    end
  end
end
