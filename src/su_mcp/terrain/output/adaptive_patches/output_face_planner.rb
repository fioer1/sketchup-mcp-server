# frozen_string_literal: true

module SU_MCP
  module Terrain
    module AdaptivePatches
      # Converts adaptive cells into face plans and patch registry records.
      class OutputFacePlanner
        def initialize(vertex_projector:)
          @vertex_projector = vertex_projector
        end

        def batch(state:, output_plan:, patches:)
          patch_records = []
          batch_id = replacement_batch_id(output_plan)
          policy_fingerprint = output_plan.adaptive_patch_policy.output_policy_fingerprint
          vertex_cache = {}
          face_plans = patches.flat_map do |patch|
            faces = planned_patch_faces(
              state,
              output_plan,
              patch,
              batch_id,
              policy_fingerprint,
              vertex_cache
            )
            unless faces.empty?
              patch_records << registry_patch_record(
                output_plan,
                patch: patch,
                batch_id: batch_id,
                face_count: faces.length
              )
            end
            faces
          end
          { faces: face_plans, patches: patch_records }
        end

        def replacement_batch_id(output_plan)
          "adaptive-batch-#{output_plan.state_digest}"
        end

        private

        attr_reader :vertex_projector

        def planned_patch_faces(state, output_plan, patch, batch_id, policy_fingerprint, cache)
          cells = cells_for_patch(output_plan.adaptive_cells, patch)
          return [] if cells.empty?

          planned_faces(
            state,
            cells,
            patch_id: patch.fetch(:patchId),
            batch_id: batch_id,
            state_digest: output_plan.state_digest,
            policy_fingerprint: policy_fingerprint,
            vertex_cache: cache
          )
        end

        def planned_faces(
          state,
          cells,
          patch_id:,
          batch_id:,
          state_digest:,
          policy_fingerprint:,
          vertex_cache:
        )
          face_index = 0
          cells.flat_map do |cell|
            cell.fetch(:emission_triangles).map do |triangle|
              plan = face_plan(
                state,
                triangle,
                ownership: face_ownership(
                  patch_id,
                  face_index,
                  batch_id,
                  state_digest,
                  policy_fingerprint
                ),
                vertex_cache: vertex_cache
              )
              face_index += 1
              plan
            end
          end
        end

        def face_plan(state, triangle, ownership:, vertex_cache:)
          {
            points: triangle.map do |vertex|
              vertex_cache[vertex] ||= vertex_projector.adaptive_vertex_for_planned_point(
                state,
                vertex
              )
            end,
            ownership: ownership
          }
        end

        def face_ownership(patch_id, face_index, batch_id, state_digest, policy_fingerprint)
          {
            kind: :adaptive_patch,
            patch_id: patch_id,
            patch_face_index: face_index,
            replacement_batch_id: batch_id,
            state_digest: state_digest,
            policy_fingerprint: policy_fingerprint
          }
        end

        def cells_for_patch(cells, patch)
          bounds = patch.fetch(:cell_bounds)
          cells.select do |cell|
            cell.fetch(:min_column) >= bounds.fetch(:min_column) &&
              cell.fetch(:min_row) >= bounds.fetch(:min_row) &&
              cell.fetch(:max_column) <= bounds.fetch(:max_column) + 1 &&
              cell.fetch(:max_row) <= bounds.fetch(:max_row) + 1
          end
        end

        def registry_patch_record(output_plan, patch:, batch_id:, face_count:)
          {
            patchId: patch.fetch(:patchId),
            bounds: patch.fetch(:bounds),
            outputBounds: patch.fetch(:bounds),
            replacementBatchId: batch_id,
            faceCount: face_count,
            seamRecords: seam_records_for(output_plan, patch.fetch(:patchId)),
            status: 'valid'
          }
        end

        def seam_records_for(output_plan, patch_id)
          return [] unless output_plan.respond_to?(:adaptive_seam_records)

          output_plan.adaptive_seam_records.select do |record|
            record.fetch(:patchId) == patch_id
          end
        end
      end
    end
  end
end
