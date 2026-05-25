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

  def test_expected_component_promotion_is_not_patch_scope_regression
    row = classify(
      current_row(
        patch_scope: { 'affectedPatchCount' => 1, 'replacementPatchCount' => 12 },
        component_summary: component_summary(promoted_count: 3),
        expected_promotion: true,
        quality_status: 'captured'
      ),
      baseline: current_row(policy: nil)
    )

    refute_equal('regressed', row.fetch('verdict'))
    assert_equal(true, row.fetch('comparison').fetch('expectedPromotion'))
    assert_equal(true, row.fetch('comparison').fetch('patchScopeChanged'))
  end

  def test_expected_over_budget_verdict_is_not_regression_with_mesh_evidence
    row = classify(
      current_row(
        face_count: 140,
        patch_scope: { 'affectedPatchCount' => 1, 'replacementPatchCount' => 16 },
        component_summary: component_summary(promoted_count: 15),
        component_budget: {
          'status' => 'over_budget'
        },
        expected_over_budget: true,
        quality_status: 'captured'
      ),
      baseline: current_row(policy: nil)
    )

    refute_equal('regressed', row.fetch('verdict'))
    assert_equal(true, row.fetch('comparison').fetch('expectedOverBudget'))
    assert_equal('over_budget', row.fetch('comparison').fetch('componentBudgetStatus'))
    refute_includes(row.fetch('comparison'), 'componentFallback')
  end

  def test_expected_fallback_annotation_without_component_fallback_remains_regression
    row = classify(
      current_row(
        patch_scope: { 'affectedPatchCount' => 1, 'replacementPatchCount' => 16 },
        expected_fallback: true
      ),
      baseline: current_row(policy: nil)
    )

    assert_equal('regressed', row.fetch('verdict'))
  end

  def test_unexpected_component_expansion_or_fallback_remains_regression
    unexpected_expansion = classify(
      current_row(
        patch_scope: { 'affectedPatchCount' => 1, 'replacementPatchCount' => 16 },
        component_summary: component_summary(promoted_count: 15)
      ),
      baseline: current_row(policy: nil)
    )
    unexpected_fallback = classify(
      current_row(
        component_budget: {
          'status' => 'over_budget',
          'fallbackCategory' => 'unsafe_existing_output'
        },
        expected_fallback: false
      ),
      baseline: current_row(policy: nil)
    )

    assert_equal('regressed', unexpected_expansion.fetch('verdict'))
    assert_equal('regressed', unexpected_fallback.fetch('verdict'))
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
    seam_summary: nil,
    patch_scope: { 'affectedPatchCount' => 1, 'replacementPatchCount' => 9 },
    component_summary: nil,
    component_budget: nil,
    expected_promotion: false,
    expected_over_budget: false,
    expected_fallback: false
  )
    {
      'rowId' => 'feature-row',
      'seconds' => seconds,
      'outcome' => outcome,
      'faceCount' => face_count,
      'vertexCount' => vertex_count,
      'dirtyWindow' => { 'columns' => 9, 'rows' => 9 },
      'patchScope' => patch_scope,
      'adaptivePolicySummary' => policy_summary(
        policy,
        density_hits,
        fallback_counts,
        forced_summary
      ),
      'featureQualitySummary' => quality_payload(quality_summary, quality_status),
      'planarInteriorMetrics' => planar_interior_metrics,
      'seamValidationSummary' => seam_summary,
      'componentPlanSummary' => component_summary,
      'componentBudget' => component_budget,
      'expectedPromotion' => expected_promotion,
      'expectedOverBudget' => expected_over_budget,
      'expectedFallback' => expected_fallback
    }.compact
  end

  def component_summary(promoted_count:)
    {
      'componentCount' => 1,
      'maxComponentSize' => promoted_count + 1,
      'promotedCount' => promoted_count,
      'roleCounts' => {
        'affected' => 1,
        'replacement' => promoted_count + 1,
        'conformance' => 3,
        'retained_boundary' => 0,
        'safety_margin' => 0
      },
      'graphReasons' => %w[dirty_window feature_boundary_crossing]
    }
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
