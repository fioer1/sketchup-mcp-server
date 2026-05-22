# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/probes/' \
                 'feature_aware_adaptive_baseline_result_classifier'

class FeatureAwareAdaptiveBaselineResultClassifierTest < Minitest::Test
  def test_classifies_feature_policy_rows_as_policy_applied_without_overclaiming_quality
    row = classify(
      current_row(
        face_count: 108,
        seconds: 0.09,
        density_hits: 12,
        fallback_counts: { 'unsupportedFeatureGeometry' => 1 },
        quality_status: 'captured'
      )
    )

    assert_equal('policy_applied', row.fetch('verdict'))
    assert_includes(row.fetch('verdictReason'), 'feature policy applied')
    assert_includes(row.fetch('verdictReason'), 'unsupportedFeatureGeometry=1')
    assert_equal(8, row.fetch('comparison').fetch('faceCountDelta'))
  end

  def test_classifies_baseline_equivalent_rows_as_neutral
    row = classify(current_row)

    assert_equal('neutral', row.fetch('verdict'))
  end

  def test_classifies_policy_rows_without_quality_capture_as_neutral
    row = classify(current_row(density_hits: 12))

    assert_equal('neutral', row.fetch('verdict'))
  end

  def test_fails_rows_when_supported_forced_subdivision_pressure_was_skipped
    row = classify(
      current_row(
        quality_status: 'captured',
        forced_summary: {
          'supportedInputCounts' => { 'anchor' => 1 },
          'skippedInputCounts' => {},
          'hitCount' => 0
        }
      )
    )

    assert_equal('failed', row.fetch('verdict'))
    assert_includes(row.fetch('verdictReason'), 'forced subdivision')
  end

  def test_broad_corridor_density_is_not_classified_as_topology_improvement
    row = classify(
      current_row(
        face_count: 108,
        density_hits: 20,
        quality_status: 'captured',
        quality_summary: {
          'status' => 'captured',
          'families' => { 'linear_corridor' => { 'sampleCount' => 8 } },
          'roleSummaries' => { 'centerline' => { 'sampleCount' => 8 } }
        }
      )
    )

    assert_equal('neutral', row.fetch('verdict'))
    refute_includes(row.fetch('verdictReason'), 'feature policy applied')
  end

  def test_classifies_refused_missing_policy_and_slow_rows
    assert_equal('failed', classify(current_row(outcome: 'refused')).fetch('verdict'))
    assert_equal('failed', classify(current_row(policy: nil)).fetch('verdict'))
    assert_equal(
      'regressed',
      classify(current_row(seconds: 0.13, density_hits: 1)).fetch('verdict')
    )
  end

  def test_normalizes_patch_scope_field_names_for_replay_and_result_rows
    row = classify(
      current_row(density_hits: 1, quality_status: 'captured').tap do |current|
        current['affectedPatchScope'] = current.delete('patchScope')
      end
    )

    assert_equal('policy_applied', row.fetch('verdict'))
    refute(row.fetch('comparison').fetch('patchScopeChanged'))
  end

  def test_compares_planar_interior_metrics_when_present_on_current_and_baseline_rows
    row = classify(
      current_row(
        face_count: 90,
        vertex_count: 45,
        planar_interior_metrics: {
          'faceCount' => 12,
          'vertexCount' => 8,
          'qualityStatus' => 'captured'
        }
      ),
      baseline: current_row(
        face_count: 100,
        vertex_count: 50,
        planar_interior_metrics: {
          'faceCount' => 30,
          'vertexCount' => 20,
          'qualityStatus' => 'captured'
        },
        policy: nil
      )
    )

    comparison = row.fetch('comparison')

    assert_includes(comparison.keys, 'planarInterior')
    assert_equal(
      {
        'baselineFaceCount' => 30,
        'faceCountDelta' => -18,
        'baselineVertexCount' => 20,
        'vertexCountDelta' => -12,
        'qualityStatus' => 'captured'
      },
      comparison.fetch('planarInterior')
    )
  end

  def test_fails_rows_with_accepted_seam_mismatch_evidence
    row = classify(
      current_row(
        seam_summary: {
          'status' => 'failed',
          'comparisonMode' => 'planned_vs_registry',
          'mismatchCategory' => 'topology_mismatch',
          'maxZGap' => 0.0
        }
      )
    )

    assert_equal('failed', row.fetch('verdict'))
    assert_includes(row.fetch('verdictReason'), 'seam')
  end

  private

  def classify(row, baseline: baseline_row)
    document = SU_MCP::Terrain::FeatureAwareAdaptiveBaselineResultClassifier.annotate(
      baseline_document: { 'rows' => [baseline] },
      current_document: { 'rows' => [row] }
    )
    document.fetch('rows').first
  end

  def baseline_row
    current_row(policy: nil)
  end

  def current_row(
    face_count: 100,
    vertex_count: 50,
    seconds: 0.1,
    outcome: 'edited',
    density_hits: 0,
    fallback_counts: {},
    policy: :default,
    quality_status: nil,
    forced_summary: nil,
    quality_summary: nil,
    planar_interior_metrics: nil,
    seam_summary: nil
  )
    {
      'rowId' => 'feature-row',
      'seconds' => seconds,
      'outcome' => outcome,
      'faceCount' => face_count,
      'vertexCount' => vertex_count,
      'dirtyWindow' => { 'columns' => 9, 'rows' => 9 },
      'patchScope' => { 'affectedPatchCount' => 1, 'replacementPatchCount' => 9 },
      'adaptivePolicySummary' => policy_summary(
        policy,
        density_hits,
        fallback_counts,
        forced_summary
      ),
      'featureQualitySummary' => quality_payload(quality_summary, quality_status),
      'planarInteriorMetrics' => planar_interior_metrics,
      'seamValidationSummary' => seam_summary
    }.compact
  end

  def quality_payload(explicit_summary, status)
    return explicit_summary if explicit_summary

    quality_summary_for_status(status)
  end

  def policy_summary(policy, density_hits, fallback_counts, forced_summary)
    return nil if policy.nil?

    {
      'policyFingerprint' => 'policy',
      'densityHitCount' => density_hits,
      'hardProtectedToleranceHitCount' => 0,
      'fallbackCounts' => fallback_counts,
      'forcedSubdivisionSummary' => forced_summary
    }.compact
  end

  def quality_summary_for_status(status)
    return nil unless status

    { 'status' => status }
  end
end
