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
