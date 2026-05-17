# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/features/terrain_feature_geometry'
require_relative '../../../src/su_mcp/terrain/output/feature_aware_adaptive_policy'

class FeatureAwareAdaptivePolicyTest < Minitest::Test
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

  private

  def build_policy(feature_geometry:)
    SU_MCP::Terrain::FeatureAwareAdaptivePolicy.new(
      feature_geometry: feature_geometry,
      state: state,
      base_tolerance: 0.01
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
end
