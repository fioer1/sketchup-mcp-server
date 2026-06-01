# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/regions/composed_height_oracle'
require_relative '../../../src/su_mcp/terrain/regions/terrain_state_elevation_sampler'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'

class ComposedHeightOracleTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_base_only_oracle_matches_existing_bilinear_sampler
    state = build_state(elevations: [
                          0.0, 10.0,
                          20.0, 30.0
                        ])
    oracle = build_oracle(state)
    sampler = SU_MCP::Terrain::TerrainStateElevationSampler.new(state)

    [
      { 'x' => 0.0, 'y' => 0.0 },
      { 'x' => 0.5, 'y' => 0.5 },
      { 'x' => 1.0, 'y' => 1.0 }
    ].each do |point|
      assert_in_delta(sampler.elevation_at(point), oracle.height_at(point), 1e-9)
      assert_equal('base', oracle.query(point).fetch('sourceCategory'))
    end
  end

  def test_base_only_oracle_preserves_no_data_and_out_of_bounds_behavior
    state = build_state(elevations: [
                          0.0, nil,
                          20.0, 30.0
                        ])
    oracle = build_oracle(state)

    assert_nil(oracle.height_at('x' => 0.5, 'y' => 0.5))
    assert_equal('no_data', oracle.query('x' => 0.5, 'y' => 0.5).fetch('sourceCategory'))
    assert_nil(oracle.height_at('x' => -0.1, 'y' => 0.5))
    assert_equal('out_of_bounds', oracle.query('x' => -0.1, 'y' => 0.5).fetch('sourceCategory'))
  end

  def test_grid_height_uses_cached_direct_grid_semantics
    state = build_state(elevations: [
                          0.0, nil,
                          20.0, 30.0
                        ])
    oracle = build_oracle(state)

    assert_equal(30.0, oracle.height_at_grid(column: 1, row: 1))
    assert_nil(oracle.height_at_grid(column: 1, row: 0))
    assert_nil(oracle.height_at_grid(column: 5, row: 0))

    cache = oracle.instance_variable_get(:@grid_height_cache)
    assert_equal(30.0, cache.fetch(3))
    assert(cache.key?(1), 'nil grid answers should still be cached')
    assert(cache.key?([:grid, 5, 0]), 'out-of-bounds grid answers should still be cached')
  end

  def test_grid_height_uses_feature_semantics_for_integer_grid_queries
    oracle = build_oracle(
      build_state(
        columns: 5,
        rows: 5,
        elevations: Array.new(25, 1.0),
        feature_intent: feature_intent([
                                         target_feature('target', target: 5.0)
                                       ])
      )
    )

    assert_equal(5.0, oracle.height_at_grid(column: 3, row: 3))
    assert_equal(1.0, oracle.height_at_grid(column: 0, row: 0))
  end

  def test_effective_feature_view_is_the_oracle_source_of_current_truth
    oracle = build_oracle(
      build_state(
        columns: 5,
        rows: 5,
        elevations: Array.new(25, 1.0),
        feature_intent: feature_intent(
          [
            target_feature('retired-target', target: 9.0, status: 'retired'),
            target_feature('active-target', target: 5.0)
          ]
        )
      )
    )

    query = oracle.query('x' => 3.0, 'y' => 3.0)

    assert_equal(5.0, query.fetch('height'))
    assert_equal('target', query.fetch('sourceCategory'))
    assert_equal('active-target', query.fetch('featureId'))
  end

  def test_precedence_prefers_preserve_planar_target_then_base_deterministically
    oracle = build_oracle(
      build_state(
        columns: 5,
        rows: 5,
        elevations: Array.new(25, 1.0),
        feature_intent: feature_intent([
                                         target_feature('target', target: 5.0),
                                         planar_feature('planar', revision: 2),
                                         preserve_feature('preserve', revision: 3)
                                       ])
      )
    )

    assert_equal('preserve', oracle.query('x' => 1.5, 'y' => 1.5).fetch('sourceCategory'))
    assert_equal('planar', oracle.query('x' => 3.5, 'y' => 2.5).fetch('sourceCategory'))
    assert_equal('target', oracle.query('x' => 1.5, 'y' => 3.0).fetch('sourceCategory'))
    assert_equal('base', oracle.query('x' => 0.0, 'y' => 0.0).fetch('sourceCategory'))
  end

  def test_fixed_control_point_height_precedes_overlapping_target
    oracle = build_oracle(
      build_state(
        columns: 5,
        rows: 5,
        elevations: Array.new(25, 1.0),
        feature_intent: feature_intent([
                                         target_feature('target', target: 5.0),
                                         fixed_control_feature('fixed', elevation: 12.0)
                                       ])
      )
    )

    fixed_query = oracle.query('x' => 3.0, 'y' => 3.0)

    assert_equal(12.0, fixed_query.fetch('height'))
    assert_equal('fixed', fixed_query.fetch('sourceCategory'))
    assert_equal('target', oracle.query('x' => 3.1, 'y' => 3.0).fetch('sourceCategory'))
  end

  def test_newer_planar_suppresses_older_circular_target_only_inside_planar_domain
    oracle = build_oracle(
      build_state(
        columns: 6,
        rows: 6,
        elevations: Array.new(36, 1.0),
        feature_intent: feature_intent([
                                         target_feature('older-circle', target: 8.0, revision: 1),
                                         planar_feature('newer-planar', revision: 2)
                                       ])
      )
    )

    assert_equal('planar', oracle.query('x' => 3.0, 'y' => 3.0).fetch('sourceCategory'))
    assert_equal('target', oracle.query('x' => 1.5, 'y' => 3.0).fetch('sourceCategory'))
    assert_equal('base', oracle.query('x' => 1.0, 'y' => 1.0).fetch('sourceCategory'))
  end

  private

  def build_oracle(state)
    SU_MCP::Terrain::ComposedHeightOracle.build(state: state)
  end

  def build_state(elevations:, columns: 2, rows: 2, feature_intent: nil)
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => columns, 'rows' => rows },
      elevations: elevations,
      revision: 1,
      state_id: 'oracle-state',
      feature_intent: feature_intent
    )
  end

  def feature_intent(features)
    {
      'schemaVersion' => 3,
      'revision' => 3,
      'generation' => SU_MCP::Terrain::FeatureIntentSet::DEFAULT_GENERATION,
      'features' => features
    }
  end

  def target_feature(id, target:, status: 'active', revision: 1)
    feature(
      id,
      'target_region',
      'soft',
      %w[support falloff],
      {
        'region' => circle_region(center: [3.0, 3.0], radius: 2.0),
        'targetElevation' => target
      },
      lifecycle(status, revision)
    )
  end

  def planar_feature(id, revision: 1)
    feature(
      id,
      'planar_region',
      'soft',
      %w[support boundary],
      {
        'region' => rectangle_region(min: [2.0, 2.0], max: [4.0, 4.0]),
        'controls' => [
          { 'point' => { 'x' => 2.0, 'y' => 2.0, 'z' => 2.0 } },
          { 'point' => { 'x' => 4.0, 'y' => 2.0, 'z' => 4.0 } },
          { 'point' => { 'x' => 2.0, 'y' => 4.0, 'z' => 6.0 } }
        ]
      },
      lifecycle('active', revision)
    )
  end

  def fixed_control_feature(id, elevation:, revision: 1)
    feature(
      id,
      'fixed_control',
      'hard',
      %w[control protected],
      {
        'control' => {
          'point' => { 'x' => 3.0, 'y' => 3.0 },
          'elevation' => elevation
        }
      },
      lifecycle('active', revision)
    )
  end

  def preserve_feature(id, revision: 1)
    feature(
      id,
      'preserve_region',
      'hard',
      %w[protected boundary],
      { 'region' => rectangle_region(min: [1.0, 1.0], max: [2.0, 2.0]) },
      lifecycle('active', revision)
    )
  end

  def feature(id, kind, strength, roles, payload, lifecycle)
    {
      'id' => id,
      'kind' => kind,
      'sourceMode' => 'explicit_edit',
      'semanticScope' => id,
      'strengthClass' => strength,
      'roles' => roles,
      'priority' => 1,
      'payload' => payload,
      'affectedWindow' => window,
      'relevanceWindow' => window,
      'lifecycle' => lifecycle,
      'provenance' => {
        'originClass' => 'test',
        'originOperation' => kind,
        'createdAtRevision' => lifecycle.fetch('updatedAtRevision'),
        'updatedAtRevision' => lifecycle.fetch('updatedAtRevision')
      }
    }
  end

  def lifecycle(status, revision)
    {
      'status' => status,
      'supersededBy' => nil,
      'updatedAtRevision' => revision
    }
  end

  def rectangle_region(min:, max:)
    {
      'type' => 'rectangle',
      'bounds' => {
        'minX' => min.fetch(0),
        'minY' => min.fetch(1),
        'maxX' => max.fetch(0),
        'maxY' => max.fetch(1)
      }
    }
  end

  def circle_region(center:, radius:)
    { 'type' => 'circle', 'center' => { 'x' => center.fetch(0), 'y' => center.fetch(1) },
      'radius' => radius }
  end

  def window
    { 'min' => { 'column' => 0, 'row' => 0 }, 'max' => { 'column' => 5, 'row' => 5 } }
  end
end
