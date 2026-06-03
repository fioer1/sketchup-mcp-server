# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../src/su_mcp/terrain/output/adaptive_patches/output_registry_writer'
require_relative '../../../../src/su_mcp/terrain/output/adaptive_patches/adaptive_patch_policy'

module SU_MCP
  module Terrain
    module AdaptivePatches
      class OutputRegistryWriterTest < Minitest::Test
        def test_write_replaces_requested_patches_and_refreshes_retained_seams
          store = RecordingRegistryStore.new(
            patches: [
              { patchId: 'patch-a', faceCount: 2 },
              { patchId: 'patch-b', faceCount: 3 }
            ]
          )
          writer = OutputRegistryWriter.new(
            patch_registry_store: store,
            seam_gate: SeamRecords.new(records: [seam_record('patch-b')])
          )

          writer.write(
            owner: Object.new,
            output_plan: output_plan,
            patches: [{ patchId: 'patch-a', faceCount: 4 }]
          )

          patches = store.written.fetch(:patches)
          assert_equal(%w[patch-b patch-a], patches.map { |patch| patch.fetch(:patchId) })
          assert_equal('valid', patches.first.fetch(:seamStatus))
          assert_equal([seam_record('patch-b')], patches.first.fetch(:seamRecords))
        end

        private

        def output_plan
          Struct.new(
            :adaptive_patch_policy,
            :state_digest,
            :state_revision
          ).new(
            AdaptivePatchPolicy.new(patch_cell_size: 1),
            'digest-v2',
            2
          )
        end

        def seam_record(patch_id)
          { patchId: patch_id, side: 'west' }
        end

        class SeamRecords
          def initialize(records:)
            @records = records
          end

          def records_for(_output_plan)
            @records
          end
        end

        class RecordingRegistryStore
          attr_reader :written

          def initialize(patches:)
            @patches = patches
          end

          def read(_owner)
            { status: 'valid', patches: @patches }
          end

          def write!(owner:, registry:)
            @owner = owner
            @written = registry
          end
        end
      end
    end
  end
end
