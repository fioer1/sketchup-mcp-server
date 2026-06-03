# frozen_string_literal: true

require 'set'

require_relative 'output_attributes'

module SU_MCP
  module Terrain
    module AdaptivePatches
      # Resolves the managed adaptive patch mesh and verifies patch-face ownership.
      class OutputOwnershipResolver
        def initialize(derived_output_store:, patch_registry_store:)
          @derived_output_store = derived_output_store
          @patch_registry_store = patch_registry_store
        end

        def patch_mesh(entities)
          entities.to_a.find do |entity|
            derived_output_store.derived_output?(entity) &&
              output_attribute(entity, OUTPUT_KIND_KEY) == ADAPTIVE_PATCH_MESH_OUTPUT_KIND &&
              entity.respond_to?(:entities)
          end
        end

        def owned_faces(owner:, entities:, patch_ids:, output_plan:)
          faces = patch_faces(entities, patch_ids)
          return derived_output_store.fallback_ownership(:missing_ownership) if faces.empty?

          registry = patch_registry_store.read(owner)
          return { outcome: :refused, reason: :registry_invalid } unless
            registry.fetch(:status) == 'valid'

          patch_face_counts = registry.fetch(:patches, []).to_h do |patch|
            [patch.fetch(:patchId), patch.fetch(:faceCount)]
          end
          return invalid_ownership unless complete_patch_faces?(
            patch_ids,
            patch_face_counts,
            faces.group_by { |face| output_attribute(face, ADAPTIVE_PATCH_ID_KEY) },
            output_plan
          )

          { outcome: :owned, faces: faces }
        end

        def entity_faces(entities)
          return entities.faces if entities.respond_to?(:faces)

          entities.grep(Sketchup::Face)
        end

        private

        attr_reader :derived_output_store, :patch_registry_store

        def patch_faces(entities, patch_ids)
          wanted = patch_ids.to_set
          entity_faces(entities).select do |face|
            output_attribute(face, OUTPUT_KIND_KEY) == ADAPTIVE_PATCH_FACE_OUTPUT_KIND &&
              wanted.include?(output_attribute(face, ADAPTIVE_PATCH_ID_KEY))
          end
        end

        def complete_patch_faces?(patch_ids, expected_counts, faces_by_patch, output_plan)
          patch_ids.all? do |patch_id|
            ownership_complete?(
              faces_by_patch.fetch(patch_id, []),
              expected_face_count: expected_counts.fetch(patch_id, nil),
              output_plan: output_plan
            )
          end
        end

        def ownership_complete?(faces, expected_face_count:, output_plan:)
          return false unless expected_face_count.is_a?(Integer) && expected_face_count.positive?
          return false unless faces.length == expected_face_count

          indexes = []
          faces.each do |face|
            return false unless owned_face_complete?(face, output_plan)

            indexes << output_attribute(face, ADAPTIVE_PATCH_FACE_INDEX_KEY)
          end
          indexes.sort == (0...expected_face_count).to_a
        end

        def owned_face_complete?(face, output_plan)
          output_attribute(face, DERIVED_OUTPUT_KEY) == true &&
            output_attribute(face, OUTPUT_KIND_KEY) == ADAPTIVE_PATCH_FACE_OUTPUT_KIND &&
            !output_attribute(face, ADAPTIVE_PATCH_ID_KEY).nil? &&
            output_attribute(face, ADAPTIVE_PATCH_FACE_INDEX_KEY).is_a?(Integer) &&
            !output_attribute(face, REPLACEMENT_BATCH_ID_KEY).nil? &&
            output_attribute(face, TERRAIN_STATE_DIGEST_KEY).is_a?(String) &&
            output_attribute(face, ADAPTIVE_POLICY_FINGERPRINT_KEY) ==
              output_plan.adaptive_patch_policy.output_policy_fingerprint
        end

        def output_attribute(entity, key)
          derived_output_store.output_attribute(entity, key)
        end

        def invalid_ownership
          { outcome: :refused, reason: :ownership_integrity_mismatch }
        end
      end
    end
  end
end
