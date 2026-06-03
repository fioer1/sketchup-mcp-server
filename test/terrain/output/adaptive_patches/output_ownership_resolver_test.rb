# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../support/semantic_test_support'
require_relative '../../../../src/su_mcp/terrain/output/adaptive_patches/output_ownership_resolver'
require_relative '../../../../src/su_mcp/terrain/output/adaptive_patches/adaptive_patch_policy'
require_relative '../../../../src/su_mcp/terrain/output/derived_output_entity_store'

module SU_MCP
  module Terrain
    module AdaptivePatches
      class OutputOwnershipResolverTest < Minitest::Test
        include SemanticTestSupport

        def test_entity_faces_uses_sketchup_entity_enumeration_when_faces_reader_is_missing
          model = build_semantic_model
          owner = model.active_entities.add_group
          face = owner.entities.add_face([0, 0, 0], [1, 0, 0], [0, 1, 0])

          assert_equal([face], resolver.entity_faces(EntityList.new([face])))
        end

        def test_patch_mesh_finds_marked_adaptive_patch_group
          model = build_semantic_model
          owner = model.active_entities.add_group
          mesh = owner.entities.add_group
          store.mark_adaptive_patch_mesh(
            mesh,
            batch_id: 'adaptive-batch-digest-v2',
            output_plan: output_plan,
            face_count: 0
          )

          assert_equal(mesh, resolver.patch_mesh(owner.entities))
        end

        private

        def resolver
          OutputOwnershipResolver.new(
            derived_output_store: store,
            patch_registry_store: Object.new
          )
        end

        def store
          @store ||= DerivedOutputEntityStore.new
        end

        def output_plan
          Struct.new(
            :state_digest,
            :state_revision,
            :adaptive_patch_policy
          ).new(
            'digest-v2',
            2,
            AdaptivePatchPolicy.new(patch_cell_size: 1)
          )
        end

        class EntityList
          include Enumerable

          def initialize(entities)
            @entities = entities
          end

          def each(&block)
            @entities.each(&block)
          end
        end
      end
    end
  end
end
