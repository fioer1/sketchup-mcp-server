# frozen_string_literal: true

require 'time'

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/probes/' \
                 'feature_aware_adaptive_baseline_result_document'

class FeatureAwareAdaptiveBaselineResultDocumentTest < Minitest::Test
  def test_serializes_planar_interior_metrics_for_hosted_result_rows
    document = SU_MCP::Terrain::FeatureAwareAdaptiveBaselineResultDocument.new(
      replay: replay,
      evidence: {
        rows: [
          {
            rowId: 'planar-pad-intersect',
            sourceElementId: 'terrain-main',
            commandKind: 'edit',
            timingBuckets: { total: 0.1 },
            accepted: true,
            faceCount: 90,
            vertexCount: 45,
            planarInteriorMetrics: {
              faceCount: 12,
              vertexCount: 8,
              qualityStatus: 'captured'
            }
          }
        ]
      },
      replay_path: __FILE__,
      clock: Struct.new(:now).new(Time.utc(2026, 5, 18)),
      model: Object.new,
      include_timing: false
    ).to_h

    row = document.fetch(:rows).first

    assert_includes(row.keys, :planarInteriorMetrics)
    assert_equal(
      { faceCount: 12, vertexCount: 8, qualityStatus: 'captured' },
      row.fetch(:planarInteriorMetrics)
    )
  end

  def test_serializes_internal_seam_evidence_for_hosted_result_rows
    document = SU_MCP::Terrain::FeatureAwareAdaptiveBaselineResultDocument.new(
      replay: replay,
      evidence: {
        rows: [
          {
            rowId: 'retained-seam-edit',
            sourceElementId: 'terrain-main',
            commandKind: 'edit',
            timingBuckets: { total: 0.1 },
            accepted: true,
            faceCount: 90,
            vertexCount: 45,
            seamValidationSummary: {
              status: 'passed',
              comparisonMode: 'planned_vs_registry',
              mismatchCategory: nil,
              maxZGap: 0.0,
              promotionCount: 1,
              fallbackReason: nil,
              noDeleteOutcome: 'old_output_preserved_on_failure'
            }
          }
        ]
      },
      replay_path: __FILE__,
      clock: Struct.new(:now).new(Time.utc(2026, 5, 18)),
      model: Object.new,
      include_timing: false
    ).to_h

    row = document.fetch(:rows).first

    assert_equal(
      {
        status: 'passed',
        comparisonMode: 'planned_vs_registry',
        maxZGap: 0.0,
        promotionCount: 1,
        noDeleteOutcome: 'old_output_preserved_on_failure'
      },
      row.fetch(:seamValidationSummary)
    )
  end

  def test_serializes_component_summary_without_raw_patch_identifiers
    document = SU_MCP::Terrain::FeatureAwareAdaptiveBaselineResultDocument.new(
      replay: replay,
      evidence: {
        rows: [
          {
            rowId: 'cross-patch-feature',
            sourceElementId: 'terrain-main',
            commandKind: 'edit',
            timingBuckets: { total: 0.1, componentPlanning: 0.004 },
            accepted: true,
            faceCount: 90,
            vertexCount: 45,
            componentPlanSummary: {
              componentCount: 1,
              maxComponentSize: 4,
              promotedCount: 2,
              roleCounts: {
                affected: 1,
                replacement: 4,
                conformance: 3,
                retained_boundary: 1,
                safety_margin: 0
              },
              graphReasons: %w[dirty_window feature_boundary_crossing],
              rawPatchIds: %w[adaptive-patch-v1-c0-r0]
            },
            componentBudget: {
              status: 'within_budget',
              maxReplacementPatchCount: 25,
              maxPromotionRadius: 2
            },
            expectedPromotion: true,
            expectedOverBudget: false,
            expectedFallback: false
          }
        ]
      },
      replay_path: __FILE__,
      clock: Struct.new(:now).new(Time.utc(2026, 5, 18)),
      model: Object.new,
      include_timing: false
    ).to_h

    row = document.fetch(:rows).first
    serialized = JSON.generate(row)

    assert_equal(
      {
        componentCount: 1,
        maxComponentSize: 4,
        promotedCount: 2,
        roleCounts: {
          affected: 1,
          replacement: 4,
          conformance: 3,
          retained_boundary: 1,
          safety_margin: 0
        },
        graphReasons: %w[dirty_window feature_boundary_crossing]
      },
      row.fetch(:componentPlanSummary)
    )
    assert_equal('within_budget', row.fetch(:componentBudget).fetch(:status))
    assert_equal(true, row.fetch(:expectedPromotion))
    assert_equal(false, row.fetch(:expectedOverBudget))
    assert_equal(false, row.fetch(:expectedFallback))
    refute_includes(serialized, 'adaptive-patch-v1')
    refute_includes(serialized, 'rawPatchIds')
  end

  private

  def replay
    Struct.new(:corpus_id, :terrain, :document).new(
      'feature-aware-adaptive-baseline',
      {
        'sourceElementId' => 'terrain-main',
        'dimensions' => { 'columns' => 2, 'rows' => 2 }
      },
      {}
    )
  end
end
