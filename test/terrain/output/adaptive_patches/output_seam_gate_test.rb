# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../src/su_mcp/terrain/output/adaptive_patches/output_seam_gate'

module SU_MCP
  module Terrain
    module AdaptivePatches
      class OutputSeamGateTest < Minitest::Test
        def test_validate_before_mutation_refuses_missing_sealed_plan
          result = gate.validate_before_mutation(
            owner: Object.new,
            output_plan: output_plan(sealed_adaptive_seam_plan: nil),
            replacement_patch_ids: ['patch-a']
          )

          assert_equal(:failed, result.fetch(:status))
          assert_equal(:missing_seam_plan, result.fetch(:reason))
        end

        def test_summary_includes_retained_validation_result
          summary = gate.summary(
            output_plan(
              adaptive_seam_records: [seam_record],
              adaptive_seam_validations: [{ status: :passed, maxZGap: 0.25 }],
              sealed_adaptive_seam_plan: Struct.new(:replacement_patch_ids).new(['patch-a'])
            ),
            retained_result: { status: :failed, reason: :retained_seam_missing }
          )

          assert_equal('failed', summary.fetch(:status))
          assert_equal(1, summary.fetch(:seamRecordCount))
          assert_equal(1, summary.fetch(:replacementPatchCount))
          assert_equal('retained_seam_missing', summary.fetch(:retained).fetch(:reason))
        end

        private

        def gate
          OutputSeamGate.new(patch_registry_store: Object.new)
        end

        def output_plan(
          adaptive_seam_records: [],
          adaptive_seam_validations: [],
          sealed_adaptive_seam_plan: nil
        )
          Struct.new(
            :adaptive_seam_records,
            :adaptive_seam_validations,
            :sealed_adaptive_seam_plan
          ).new(
            adaptive_seam_records,
            adaptive_seam_validations,
            sealed_adaptive_seam_plan
          )
        end

        def seam_record
          {
            patchId: 'patch-a',
            replacementSide: true,
            boundaryKind: 'neighbor',
            neighborPatchId: 'patch-b'
          }
        end
      end
    end
  end
end
