# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/output/terrain_output_plan'

class FeatureAwareDiagonalOptimizerTest < Minitest::Test
  def test_declares_metric_and_adoption_thresholds_before_scoring
    config = optimizer_class::DEFAULT_CONFIG

    assert_operator(config.fetch(:residual_epsilon), :>, 0.0)
    assert_operator(config.fetch(:adoption_residual_improvement), :>, 0.0)
    assert_operator(config.fetch(:timing_regression_percent), :>, 0.0)
    assert_operator(config.fetch(:seam_adjacent_dihedral_regression), :>, 0.0)
    assert_operator(config.fetch(:feature_check_budget), :>, 0)
  end

  def test_selects_alternate_diagonal_when_exact_residual_improves_beyond_epsilon
    result = optimizer.optimize(cell: cell, boundary_vertices: boundary_vertices)

    assert_equal(:alternate, result.fetch(:selected))
    assert_equal(:residual, result.fetch(:reason))
    assert_operator(result.fetch(:baseline_residual), :>, result.fetch(:alternate_residual))
    assert_equal(alternate_triangles, result.fetch(:triangles))
  end

  def test_keeps_baseline_for_exact_and_near_threshold_ties
    tie = optimizer_for(flat_state).optimize(cell: cell, boundary_vertices: boundary_vertices)
    near = optimizer_for(near_tie_state).optimize(cell: cell, boundary_vertices: boundary_vertices)

    assert_equal(:baseline, tie.fetch(:selected))
    assert_equal(:baseline_tie, tie.fetch(:reason))
    assert_equal(:baseline, near.fetch(:selected))
    assert_equal(:baseline_tie, near.fetch(:reason))
    assert_operator(near.fetch(:residual_improvement), :>=, 0.0)
  end

  def test_keeps_baseline_when_no_non_corner_samples_can_prove_value
    one_sample_cell = {
      min_column: 0,
      min_row: 0,
      max_column: 1,
      max_row: 1
    }
    one_sample_boundary = [[0, 0], [1, 0], [1, 1], [0, 1]]

    result = optimizer.optimize(cell: one_sample_cell, boundary_vertices: one_sample_boundary)

    assert_equal(:baseline, result.fetch(:selected))
    assert_equal(:no_metric_samples, result.fetch(:reason))
  end

  def test_safety_veto_precedes_residual_choice
    context = Struct.new(:candidate_safety, :summary).new(
      { baseline: :safe, alternate: :unsafe },
      {}
    )

    result = optimizer_for(residual_fixture_state, context: context)
             .optimize(cell: cell, boundary_vertices: boundary_vertices)

    assert_equal(:baseline, result.fetch(:selected))
    assert_equal(:safety_veto, result.fetch(:reason))
  end

  private

  def optimizer_class
    SU_MCP::Terrain.const_get(:FeatureAwareDiagonalOptimizer)
  end

  def optimizer
    optimizer_for(residual_fixture_state)
  end

  def optimizer_for(state, context: nil)
    optimizer_class.new(state: state, context: context)
  end

  def cell
    {
      min_column: 0,
      min_row: 0,
      max_column: 3,
      max_row: 3
    }
  end

  def boundary_vertices
    [[0, 0], [3, 0], [3, 3], [0, 3]]
  end

  def alternate_triangles
    [
      [[0, 0], [3, 0], [0, 3]],
      [[3, 0], [3, 3], [0, 3]]
    ]
  end

  def residual_fixture_state
    state_with_elevations(
      [
        -0.43065904845984737, -1.919322888910946, -1.5844052404272593,
        -0.012052421402118263,
        0.629466122389446, 1.998888535850278, 0.7005297133345278, 1.4394420044800014,
        -1.0446665014063536, 0.6426539609187927, 1.5214173138215656,
        0.42168602867378047,
        -0.4927838706575516, 1.2585669747468677, -1.8013351314116641,
        -0.6677658305734515
      ]
    )
  end

  def flat_state
    state_with_elevations(Array.new(16, 1.0))
  end

  def near_tie_state
    elevations = Array.new(16, 1.0)
    elevations[5] = 1.000000001
    state_with_elevations(elevations)
  end

  def state_with_elevations(elevations)
    Struct.new(:dimensions, :elevations).new(
      { 'columns' => 4, 'rows' => 4 },
      elevations
    )
  end
end
