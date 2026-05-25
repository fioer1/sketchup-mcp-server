# frozen_string_literal: true

require 'json'

require_relative '../../../test_helper'
require_relative '../../../../src/su_mcp/terrain/output/terrain_output_cell_window'
require_relative '../../../../src/su_mcp/terrain/output/patch_lifecycle/patch_grid_policy'
require_relative '../../../../src/su_mcp/terrain/output/patch_lifecycle/patch_component_planner'

class PatchComponentPlannerTest < Minitest::Test
  def test_dirty_window_preserves_existing_lifecycle_shape_without_promotion
    result = planner.resolve(cell_window: cell_window(5, 5, 5, 5))

    assert_equal(['patch-v1-c1-r1'], result.fetch(:affectedPatchIds))
    assert_includes(result.fetch(:replacementPatchIds), 'patch-v1-c0-r0')
    assert_includes(result.fetch(:replacementPatchIds), 'patch-v1-c2-r2')
    assert_equal(1, result.fetch(:conformanceRing))
    assert_empty(result.fetch(:retainedBoundaryPatchIds))
    assert_empty(result.fetch(:safetyMarginPatchIds))
    assert_equal('within_budget', result.dig(:componentBudget, :status))
    assert_equal(0, result.dig(:componentPlanSummary, :promotedCount))
    assert_equal(['dirty_window'], result.dig(:componentPlanSummary, :graphReasons))
  end

  def test_feature_boundary_crossing_promotes_connected_component_with_role_counts
    result = planner.resolve(
      cell_window: cell_window(1, 1, 1, 1),
      feature_windows: [cell_window(3, 3, 5, 5)]
    )

    assert_includes(result.dig(:componentPlanSummary, :graphReasons),
                    'feature_boundary_crossing')
    assert_operator(result.dig(:componentPlanSummary, :componentCount), :>=, 1)
    assert_operator(result.dig(:componentPlanSummary, :maxComponentSize), :>=, 2)
    assert_operator(result.dig(:componentPlanSummary, :promotedCount), :>=, 1)
    assert_operator(result.dig(:componentPlanSummary, :roleCounts).fetch(:replacement), :>=, 2)
  end

  def test_protected_boundary_crossing_records_protected_reason_and_roles
    result = planner.resolve(
      cell_window: cell_window(1, 1, 1, 1),
      protected_windows: [cell_window(3, 0, 5, 2)]
    )

    assert_includes(result.dig(:componentPlanSummary, :graphReasons),
                    'protected_boundary_crossing')
    assert_operator(result.dig(:componentPlanSummary, :roleCounts).fetch(:affected), :>=, 1)
    assert_operator(result.dig(:componentPlanSummary, :roleCounts).fetch(:replacement), :>=, 2)
  end

  def test_retained_seam_dependency_promotes_neighbor_and_classifies_retained_boundary
    retained_neighbor = 'patch-v1-c2-r1'

    result = planner.resolve(
      cell_window: cell_window(5, 5, 5, 5),
      retained_seam_dependencies: [
        { patchId: 'patch-v1-c1-r1', neighborPatchId: retained_neighbor }
      ]
    )

    assert_includes(result.fetch(:replacementPatchIds), retained_neighbor)
    assert_includes(result.fetch(:retainedBoundaryPatchIds), retained_neighbor)
    assert_includes(result.dig(:componentPlanSummary, :graphReasons),
                    'retained_seam_dependency')
    assert_operator(
      result.dig(:componentPlanSummary, :roleCounts).fetch(:retained_boundary),
      :>=,
      1
    )
  end

  def test_conformance_and_safety_margin_roles_do_not_expand_replacement_scope
    result = planner.resolve(
      cell_window: cell_window(5, 5, 5, 5),
      safety_margin_windows: [cell_window(12, 12, 12, 12)]
    )

    refute_includes(result.fetch(:replacementPatchIds), 'patch-v1-c3-r3')
    assert_includes(result.fetch(:safetyMarginPatchIds), 'patch-v1-c3-r3')
    assert_operator(result.dig(:componentPlanSummary, :roleCounts).fetch(:conformance), :>=, 1)
    assert_equal(1, result.dig(:componentPlanSummary, :roleCounts).fetch(:safety_margin))
    assert_includes(result.dig(:componentPlanSummary, :graphReasons), 'conformance')
  end

  def test_empty_local_detail_sources_are_shape_only_and_non_empty_sources_are_unsupported
    assert_equal(
      'within_budget',
      planner.resolve(
        cell_window: cell_window(5, 5, 5, 5),
        local_detail_windows: []
      ).dig(:componentBudget, :status)
    )

    error = assert_raises(ArgumentError) do
      planner.resolve(
        cell_window: cell_window(5, 5, 5, 5),
        local_detail_windows: [cell_window(5, 5, 6, 6)]
      )
    end
    assert_match(/local-detail/i, error.message)
  end

  def test_budget_defaults_and_over_budget_verdict
    result = planner.resolve(
      cell_window: cell_window(1, 1, 1, 1),
      feature_windows: [cell_window(0, 0, 15, 15)],
      budget: { maxReplacementPatchCount: 2, maxPromotionRadius: 1 }
    )

    budget = result.fetch(:componentBudget)
    assert_equal(25, planner.default_budget.fetch(:maxReplacementPatchCount))
    assert_equal(2, planner.default_budget.fetch(:maxPromotionRadius))
    assert_equal('over_budget', budget.fetch(:status))
    refute_includes(budget.keys, :fallbackCategory)
    refute_includes(budget.keys, :fallbackPath)
    refute_includes(JSON.generate(budget), 'patch-v1')
  end

  def test_ratio_and_full_grid_proximity_are_evidence_not_hard_gates
    result = planner.resolve(
      cell_window: cell_window(1, 1, 1, 1),
      feature_windows: [cell_window(0, 0, 4, 4)],
      budget: { maxReplacementPatchCount: 25, maxPromotionRadius: 2 }
    )

    evidence = result.fetch(:componentBudget).fetch(:evidence)
    assert_includes(evidence.keys, :replacementToAffectedRatio)
    assert_includes(evidence.keys, :fullGridProximity)
    assert_equal('within_budget', result.dig(:componentBudget, :status))
  end

  private

  def planner
    planner_class.new(
      policy: policy,
      dimensions: { 'columns' => 17, 'rows' => 17 }
    )
  end

  def planner_class
    SU_MCP::Terrain::PatchLifecycle.const_get(:PatchComponentPlanner)
  end

  def policy
    SU_MCP::Terrain::PatchLifecycle::PatchGridPolicy.new(
      patch_cell_size: 4,
      conformance_ring: 1
    )
  end

  def cell_window(min_column, min_row, max_column, max_row)
    SU_MCP::Terrain::TerrainOutputCellWindow.new(
      {
        min_column: min_column,
        min_row: min_row,
        max_column: max_column,
        max_row: max_row
      },
      full_bounds: { max_column: 15, max_row: 15 }
    )
  end
end
