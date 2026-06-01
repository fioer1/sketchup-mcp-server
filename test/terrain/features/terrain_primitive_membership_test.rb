# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/features/terrain_feature_geometry_builder'
require_relative '../../../src/su_mcp/terrain/features/terrain_primitive_membership'

class TerrainPrimitiveMembershipTest < Minitest::Test
  def test_circle_membership_rejects_points_inside_bounds_but_outside_circle
    classifier = primitive_membership
    circle = {
      'primitive' => 'circle',
      'ownerLocalCenterRadius' => [5.0, 5.0, 2.0]
    }

    assert_equal(:inside, classifier.classify(point: [5.0, 5.0], primitive: circle))
    assert_equal(:outside, classifier.classify(point: [6.9, 6.9], primitive: circle))
  end

  def test_circle_boundary_band_is_deterministic
    classifier = primitive_membership
    circle = {
      'primitive' => 'circle',
      'ownerLocalCenterRadius' => [0.0, 0.0, 2.0]
    }

    assert_equal(
      :boundary,
      classifier.classify(point: [2.0 + 5e-8, 0.0], primitive: circle, tolerance: 1e-6)
    )
    assert_equal(
      :outside,
      classifier.classify(point: [2.0 + 5e-4, 0.0], primitive: circle, tolerance: 1e-6)
    )
  end

  def test_rectangle_membership_uses_bounds_without_circle_tolerance_rules
    classifier = primitive_membership
    rectangle = {
      'primitive' => 'rectangle',
      'ownerLocalBounds' => [[1.0, 1.0], [4.0, 4.0]]
    }

    assert_equal(:inside, classifier.classify(point: [2.0, 2.0], primitive: rectangle))
    assert_equal(:boundary, classifier.classify(point: [4.0, 2.0], primitive: rectangle))
    assert_equal(:outside, classifier.classify(point: [4.1, 2.0], primitive: rectangle))
  end

  def test_point_membership_uses_explicit_tolerance_for_fixed_controls
    classifier = primitive_membership
    point = {
      'primitive' => 'point',
      'ownerLocalPoint' => [2.0, 3.0]
    }

    assert_equal(:inside, classifier.classify(point: [2.0, 3.0], primitive: point))
    assert_equal(
      :inside,
      classifier.classify(point: [2.0 + 5e-8, 3.0], primitive: point, tolerance: 1e-6)
    )
    assert_equal(
      :outside,
      classifier.classify(point: [2.0 + 5e-4, 3.0], primitive: point, tolerance: 1e-6)
    )
  end

  private

  def primitive_membership
    SU_MCP::Terrain::TerrainPrimitiveMembership
  end
end
