# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/features/terrain_feature_geometry_builder'
require_relative '../../../src/su_mcp/terrain/features/terrain_feature_geometry'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'
require_relative '../../../src/su_mcp/terrain/output/feature_aware_adaptive_policy'

class FeatureAwareAdaptivePolicyTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_missing_feature_geometry_uses_baseline_policy_with_fallback_summary
    policy = build_policy(feature_geometry: nil)

    assert_in_delta(0.01, policy.local_tolerance_for(bounds(0, 0, 8, 8)), 0.000001)
    assert_nil(policy.target_cell_size_for(bounds(0, 0, 8, 8)))
    assert_equal(
      {
        absentFeatureGeometry: 1,
        partialFeatureGeometry: 0,
        unsupportedFeatureGeometry: 0
      },
      policy.summary.fetch(:fallbackCounts)
    )
  end

  def test_strictest_overlapping_tolerance_wins_and_soft_pressure_cannot_weaken_it
    policy = build_policy(
      feature_geometry: geometry(
        outputAnchorCandidates: [
          {
            'id' => 'hard-control',
            'featureId' => 'feature-hard',
            'role' => 'control',
            'strength' => 'hard',
            'ownerLocalPoint' => [4.0, 4.0]
          }
        ],
        pressureRegions: [
          rectangle_pressure('firm-region', 'firm', [[2.0, 2.0], [6.0, 6.0]], 2),
          rectangle_pressure('soft-region', 'soft', [[0.0, 0.0], [8.0, 8.0]], 4)
        ]
      )
    )

    assert_in_delta(0.0025, policy.local_tolerance_for(bounds(3, 3, 5, 5)), 0.000001)
    assert_in_delta(0.01, policy.local_tolerance_for(bounds(10, 10, 12, 12)), 0.000001)
  end

  def test_target_cell_size_uses_strictest_overlapping_density_pressure
    policy = build_policy(
      feature_geometry: geometry(
        pressureRegions: [
          rectangle_pressure('soft-target', 'soft', [[0.0, 0.0], [8.0, 8.0]], 4),
          rectangle_pressure('firm-corridor', 'firm', [[2.0, 2.0], [6.0, 6.0]], 1)
        ]
      )
    )

    assert_equal(1, policy.target_cell_size_for(bounds(3, 3, 5, 5)))
    assert_equal(4, policy.target_cell_size_for(bounds(7, 7, 8, 8)))
    assert_nil(policy.target_cell_size_for(bounds(10, 10, 12, 12)))
  end

  def test_summary_is_deterministic_compact_and_aggregate_only
    first = build_policy(feature_geometry: hard_and_density_geometry)
    second = build_policy(feature_geometry: hard_and_density_geometry)

    first.local_tolerance_for(bounds(3, 3, 5, 5))
    first.target_cell_size_for(bounds(3, 3, 5, 5))
    second.local_tolerance_for(bounds(3, 3, 5, 5))
    second.target_cell_size_for(bounds(3, 3, 5, 5))

    first_summary = first.summary
    assert_equal(first_summary, second.summary)
    assert_match(/\A[a-f0-9]{64}\z/, first_summary.fetch(:policyFingerprint))
    assert_match(/\A[a-f0-9]{64}\z/, first_summary.fetch(:featureGeometryDigest))
    assert_equal({ min: 0.0025, max: 0.0025 }, first_summary.fetch(:toleranceRange))
    assert_equal(1, first_summary.fetch(:hardProtectedToleranceHitCount))
    assert_equal(1, first_summary.fetch(:densityHitCount))
    refute_includes(JSON.generate(first_summary), 'ownerLocalPoint')
    refute_includes(JSON.generate(first_summary), 'ownerLocalShape')
  end

  def test_partial_or_unsupported_geometry_degrades_without_public_refusal
    policy = build_policy(
      feature_geometry: geometry(
        pressureRegions: [
          { 'id' => 'unsupported-shape', 'featureId' => 'bad', 'primitive' => 'polygon' }
        ],
        limitations: [
          { 'featureId' => 'bad', 'category' => 'polygon_derivation', 'reason' => 'unsupported' }
        ]
      )
    )

    assert_in_delta(0.01, policy.local_tolerance_for(bounds(0, 0, 8, 8)), 0.000001)
    assert_nil(policy.target_cell_size_for(bounds(0, 0, 8, 8)))
    assert_equal(1, policy.summary.fetch(:fallbackCounts).fetch(:unsupportedFeatureGeometry))
  end

  def test_supported_forced_masks_are_classified_separately_from_tolerance_and_density
    policy = build_policy(
      feature_geometry: geometry(
        outputAnchorCandidates: [
          {
            'id' => 'hard-control',
            'featureId' => 'feature-hard',
            'role' => 'control',
            'strength' => 'hard',
            'ownerLocalPoint' => [4.0, 4.0]
          }
        ],
        protectedRegions: [
          {
            'id' => 'protected',
            'featureId' => 'feature-protected',
            'role' => 'protected',
            'primitive' => 'rectangle',
            'ownerLocalBounds' => [[2.0, 2.0], [6.0, 6.0]]
          }
        ]
      )
    )

    pressure = policy.split_pressure_for(bounds(3, 3, 5, 5), column_span: 2, row_span: 2)

    assert_equal(true, pressure.fetch(:forced_split))
    assert_equal(false, pressure.fetch(:density_split))
    assert_nil(pressure.fetch(:target_cell_size))
    assert_in_delta(0.0025, pressure.fetch(:tolerance), 0.000001)
    assert_equal(
      {
        supportedInputCounts: { anchor: 1, protected_boundary: 1 },
        skippedInputCounts: {},
        hitCount: 1
      },
      policy.summary.fetch(:forcedSubdivisionSummary)
    )
  end

  def test_unsupported_forced_mask_inputs_are_skipped_without_density_pressure
    policy = build_policy(
      feature_geometry: geometry(
        pressureRegions: [
          {
            'id' => 'corridor-pressure',
            'featureId' => 'corridor',
            'role' => 'centerline',
            'strength' => 'firm',
            'primitive' => 'corridor',
            'ownerLocalShape' => {
              'centerline' => [[0.0, 4.0], [8.0, 4.0]],
              'width' => 2.0,
              'blendDistance' => 1.0
            },
            'targetCellSize' => 1
          },
          { 'id' => 'polygon-pressure', 'featureId' => 'polygon', 'primitive' => 'polygon' }
        ]
      )
    )

    pressure = policy.split_pressure_for(bounds(0, 0, 8, 8), column_span: 8, row_span: 8)

    assert_equal(false, pressure.fetch(:forced_split))
    assert_equal(false, pressure.fetch(:density_split))
    assert_nil(pressure.fetch(:target_cell_size))
    assert_equal(
      {
        supportedInputCounts: {},
        skippedInputCounts: { broad_corridor_pressure: 1, unsupported_pressure_primitive: 1 },
        hitCount: 0
      },
      policy.summary.fetch(:forcedSubdivisionSummary)
    )
  end

  def test_corridor_reference_segments_force_side_and_cap_detail_not_centerline_pressure
    policy = build_policy(
      feature_geometry: geometry(
        pressureRegions: [
          {
            'id' => 'corridor-pressure',
            'featureId' => 'corridor',
            'role' => 'centerline',
            'strength' => 'firm',
            'primitive' => 'corridor',
            'ownerLocalShape' => {
              'centerline' => [[0.0, 4.0], [8.0, 4.0]],
              'width' => 2.0,
              'blendDistance' => 1.0
            },
            'targetCellSize' => 1
          }
        ],
        referenceSegments: [
          reference_segment('side', 'side_transition', [0.0, 6.0], [8.0, 6.0]),
          reference_segment('cap', 'endpoint_cap', [0.0, 2.0], [0.0, 6.0]),
          reference_segment('center', 'centerline', [0.0, 4.0], [8.0, 4.0])
        ]
      )
    )

    side = policy.split_pressure_for(bounds(2, 5, 6, 7), column_span: 4, row_span: 2)
    interior = policy.split_pressure_for(bounds(2, 3, 6, 5), column_span: 4, row_span: 2)

    assert_equal(true, side.fetch(:forced_split))
    assert_equal(false, interior.fetch(:forced_split))
    assert_equal(
      { corridor_detail: 2 },
      policy.summary.fetch(:forcedSubdivisionSummary).fetch(:supportedInputCounts)
    )
  end

  def test_clipped_feature_geometry_removes_older_planar_interior_density_pressure
    policy = build_policy(
      feature_geometry: feature_geometry_for([
                                               fairing_feature(
                                                 'fairing-crossing',
                                                 region: rectangle_region(
                                                   min: [0.0, 0.0],
                                                   max: [6.0, 5.0]
                                                 )
                                               ),
                                               planar_feature('planar-overwrite', revision: 2)
                                             ])
    )

    inside = policy.split_pressure_for(bounds(2, 2, 3, 3), column_span: 4, row_span: 4)
    outside = policy.split_pressure_for(bounds(0, 2, 1, 3), column_span: 4, row_span: 4)

    assert_nil(inside.fetch(:target_cell_size))
    assert_equal(false, inside.fetch(:density_split))
    assert_equal(4, outside.fetch(:target_cell_size))
    assert_equal(false, outside.fetch(:density_split))
  end

  def test_clipped_feature_geometry_removes_older_planar_interior_circle_pressure
    policy = build_policy(
      feature_geometry: feature_geometry_for([
                                               target_feature('target-crossing', radius: 2.0),
                                               planar_feature('planar-overwrite', revision: 2)
                                             ])
    )

    inside = policy.split_pressure_for(bounds(2, 2, 3, 3), column_span: 4, row_span: 4)
    outside = policy.split_pressure_for(bounds(4, 2, 5, 3), column_span: 4, row_span: 4)

    assert_nil(inside.fetch(:target_cell_size))
    assert_equal(false, inside.fetch(:density_split))
    assert_equal(4, outside.fetch(:target_cell_size))
    assert_equal(false, outside.fetch(:density_split))
  end

  def test_clipped_feature_geometry_removes_older_planar_interior_forced_corridor_detail
    policy = build_policy(
      feature_geometry: feature_geometry_for([
                                               corridor_feature(
                                                 'corridor-crossing',
                                                 width: 1.0,
                                                 side_blend: {
                                                   'distance' => 0.0,
                                                   'falloff' => 'none'
                                                 },
                                                 start_point: [0.0, 2.5],
                                                 end_point: [6.0, 2.5]
                                               ),
                                               planar_feature('planar-overwrite', revision: 2)
                                             ])
    )

    inside = policy.split_pressure_for(bounds(2, 2, 3, 3), column_span: 4, row_span: 4)
    outside = policy.split_pressure_for(bounds(0, 2, 1, 3), column_span: 4, row_span: 4)

    assert_equal(false, inside.fetch(:forced_split))
    assert_equal(true, outside.fetch(:forced_split))
  end

  def test_clipped_feature_geometry_preserves_newer_overlay_pressure_inside_planar_region
    policy = build_policy(
      feature_geometry: feature_geometry_for([
                                               planar_feature('planar-base', revision: 1),
                                               target_feature(
                                                 'target-over-planar',
                                                 radius: 1.0,
                                                 revision: 2
                                               )
                                             ])
    )

    inside = policy.split_pressure_for(bounds(2, 2, 3, 3), column_span: 4, row_span: 4)

    assert_equal(4, inside.fetch(:target_cell_size))
    assert_equal(false, inside.fetch(:density_split))
  end

  def test_split_pressure_marks_fairing_only_density_pressure_for_residual_gate
    policy = build_policy(
      feature_geometry: geometry(
        pressureRegions: [
          fairing_pressure('fairing-circle', 'circle', [4.0, 4.0, 3.0], 4)
        ]
      )
    )

    pressure = policy.split_pressure_for(bounds(1, 1, 7, 7), column_span: 6, row_span: 6)

    assert_equal(0.005, pressure.fetch(:tolerance))
    assert_equal(4, pressure.fetch(:target_cell_size))
    assert_equal(true, pressure.fetch(:density_split))
    assert_equal(true, pressure.fetch(:fairing_only_density_split))
    assert_equal(true, pressure.fetch(:planar_compaction_residual_guard))
  end

  def test_split_pressure_keeps_target_and_hard_break_density_out_of_fairing_gate
    policy = build_policy(
      feature_geometry: geometry(
        pressureRegions: [
          target_pressure('target-circle', 'circle', [4.0, 4.0, 3.0], 4),
          hard_break_pressure('hard-break', [[0.0, 0.0], [8.0, 8.0]], 4)
        ]
      )
    )

    target = policy.split_pressure_for(bounds(1, 1, 7, 7), column_span: 6, row_span: 6)

    assert_equal(4, target.fetch(:target_cell_size))
    assert_equal(true, target.fetch(:density_split))
    assert_equal(false, target.fetch(:fairing_only_density_split))
  end

  def test_planar_compaction_ignores_fairing_only_density_pressure
    policy = build_policy(
      feature_geometry: geometry(
        planarRegions: [
          planar_region('planar-pad', [[2.0, 2.0], [6.0, 6.0]])
        ],
        pressureRegions: [
          fairing_pressure('fairing-circle', 'circle', [4.0, 4.0, 3.0], 4)
        ]
      )
    )

    assert_equal(
      true,
      policy.planar_compaction_candidate?(bounds(2, 2, 4, 4), column_span: 2, row_span: 2)
    )
  end

  def test_planar_compaction_keeps_authoritative_density_pressure
    policy = build_policy(
      feature_geometry: geometry(
        planarRegions: [
          planar_region('planar-pad', [[2.0, 2.0], [6.0, 6.0]])
        ],
        pressureRegions: [
          fairing_pressure('fairing-circle', 'circle', [4.0, 4.0, 3.0], 4),
          target_pressure('target-circle', 'circle', [4.0, 4.0, 3.0], 4)
        ]
      )
    )

    assert_equal(
      false,
      policy.planar_compaction_candidate?(bounds(2, 2, 4, 4), column_span: 2, row_span: 2)
    )
  end

  def test_planar_compaction_ignores_broad_survey_support_density_away_from_anchor
    policy = build_policy(
      feature_geometry: geometry(
        outputAnchorCandidates: [
          output_anchor('survey-anchor', 'survey_anchor', [5.5, 5.5])
        ],
        planarRegions: [
          planar_region('planar-pad', [[2.0, 2.0], [6.0, 6.0]])
        ],
        pressureRegions: [
          survey_pressure('survey-support', 'circle', [4.0, 4.0, 3.0], 2)
        ]
      )
    )

    assert_equal(
      true,
      policy.planar_compaction_candidate?(bounds(2, 2, 4, 4), column_span: 2, row_span: 2)
    )
  end

  def test_planar_compaction_keeps_survey_anchor_forced_detail
    policy = build_policy(
      feature_geometry: geometry(
        outputAnchorCandidates: [
          output_anchor('survey-anchor', 'survey_anchor', [3.0, 3.0])
        ],
        planarRegions: [
          planar_region('planar-pad', [[2.0, 2.0], [6.0, 6.0]])
        ],
        pressureRegions: [
          survey_pressure('survey-support', 'circle', [4.0, 4.0, 3.0], 2)
        ]
      )
    )

    assert_equal(
      false,
      policy.planar_compaction_candidate?(bounds(2, 2, 4, 4), column_span: 2, row_span: 2)
    )
  end

  private

  def build_policy(feature_geometry:)
    SU_MCP::Terrain::FeatureAwareAdaptivePolicy.new(
      feature_geometry: feature_geometry,
      state: state,
      base_tolerance: 0.01
    )
  end

  def feature_geometry_for(features)
    SU_MCP::Terrain::TerrainFeatureGeometryBuilder.new.build(
      state: state_with_features(features)
    )
  end

  def hard_and_density_geometry
    geometry(
      outputAnchorCandidates: [
        {
          'id' => 'hard-control',
          'featureId' => 'feature-hard',
          'role' => 'control',
          'strength' => 'hard',
          'ownerLocalPoint' => [4.0, 4.0]
        }
      ],
      pressureRegions: [
        rectangle_pressure('firm-corridor', 'firm', [[2.0, 2.0], [6.0, 6.0]], 1)
      ]
    )
  end

  def geometry(values = {})
    SU_MCP::Terrain::TerrainFeatureGeometry.new(values)
  end

  def planar_region(id, owner_local_bounds)
    {
      'id' => id,
      'featureId' => id,
      'role' => 'planar_interior',
      'primitive' => 'rectangle',
      'ownerLocalBounds' => owner_local_bounds
    }
  end

  def rectangle_pressure(id, strength, owner_local_bounds, target_cell_size)
    {
      'id' => id,
      'featureId' => id,
      'role' => strength == 'firm' ? 'centerline' : 'target_support',
      'strength' => strength,
      'primitive' => 'rectangle',
      'ownerLocalShape' => owner_local_bounds,
      'targetCellSize' => target_cell_size
    }
  end

  def fairing_pressure(id, primitive, owner_local_shape, target_cell_size)
    role_pressure(id, 'fairing_support', primitive, owner_local_shape, target_cell_size)
  end

  def target_pressure(id, primitive, owner_local_shape, target_cell_size)
    role_pressure(id, 'target_support', primitive, owner_local_shape, target_cell_size)
  end

  def hard_break_pressure(id, owner_local_bounds, target_cell_size)
    role_pressure(id, 'hard_break', 'rectangle', owner_local_bounds, target_cell_size)
  end

  def survey_pressure(id, primitive, owner_local_shape, target_cell_size)
    role_pressure(id, 'survey_anchor', primitive, owner_local_shape, target_cell_size, 'firm')
  end

  def role_pressure(id, role, primitive, owner_local_shape, target_cell_size, strength = 'soft')
    {
      'id' => id,
      'featureId' => id,
      'role' => role,
      'strength' => strength,
      'primitive' => primitive,
      'ownerLocalShape' => owner_local_shape,
      'targetCellSize' => target_cell_size
    }
  end

  def output_anchor(id, role, owner_local_point)
    {
      'id' => id,
      'featureId' => id,
      'role' => role,
      'strength' => 'firm',
      'ownerLocalPoint' => owner_local_point
    }
  end

  def reference_segment(id, role, start_point, end_point)
    {
      'id' => id,
      'featureId' => 'corridor',
      'role' => role,
      'strength' => 'firm',
      'ownerLocalStart' => start_point,
      'ownerLocalEnd' => end_point,
      'targetCellSize' => 2
    }
  end

  def bounds(min_column, min_row, max_column, max_row)
    {
      min_column: min_column,
      min_row: min_row,
      max_column: max_column,
      max_row: max_row
    }
  end

  def state
    Struct.new(:origin, :spacing).new(
      { 'x' => 0.0, 'y' => 0.0 },
      { 'x' => 1.0, 'y' => 1.0 }
    )
  end

  def state_with_features(features)
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => 8, 'rows' => 6 },
      elevations: Array.new(48, 1.0),
      revision: 1,
      state_id: 'mta45-policy-state',
      feature_intent: {
        'schemaVersion' => 3,
        'revision' => 1,
        'generation' => SU_MCP::Terrain::FeatureIntentSet::DEFAULT_GENERATION,
        'features' => features
      }
    )
  end

  def feature(id:, kind:, roles:, payload:, revision: 1)
    {
      'id' => id,
      'kind' => kind,
      'sourceMode' => 'explicit_edit',
      'roles' => roles,
      'priority' => 1,
      'payload' => payload,
      'provenance' => { 'originClass' => 'test', 'originOperation' => kind,
                        'createdAtRevision' => revision, 'updatedAtRevision' => revision }
    }
  end

  def corridor_feature(id, width:, side_blend:, start_point:, end_point:, revision: 1)
    feature(id: id, kind: 'linear_corridor',
            roles: %w[centerline side_transition endpoint_cap control],
            payload: {
              'startControl' => {
                'point' => { 'x' => start_point.fetch(0), 'y' => start_point.fetch(1) },
                'elevation' => 1.0
              },
              'endControl' => {
                'point' => { 'x' => end_point.fetch(0), 'y' => end_point.fetch(1) },
                'elevation' => 2.0
              },
              'width' => width,
              'sideBlend' => side_blend
            },
            revision: revision)
  end

  def planar_feature(id, revision: 1)
    feature(id: id, kind: 'planar_region', roles: %w[support boundary],
            payload: {
              'region' => rectangle_region(min: [1.0, 1.0], max: [4.0, 4.0])
            },
            revision: revision)
  end

  def target_feature(id, radius:, revision: 1)
    feature(id: id, kind: 'target_region', roles: %w[support falloff],
            payload: { 'region' => circle_region(center: [3.0, 3.0], radius: radius) },
            revision: revision)
  end

  def fairing_feature(id, region:, revision: 1)
    feature(id: id, kind: 'fairing_region', roles: %w[support],
            payload: { 'region' => region },
            revision: revision)
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
    {
      'type' => 'circle',
      'center' => { 'x' => center.fetch(0), 'y' => center.fetch(1) },
      'radius' => radius
    }
  end
end
