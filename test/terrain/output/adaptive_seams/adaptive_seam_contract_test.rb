# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../src/su_mcp/terrain/output/adaptive_seams/adaptive_seam_contract'

class AdaptiveSeamContractTest < Minitest::Test
  def test_canonical_orientation_matches_counterpart_owner_sides
    east = contract_record(
      side: 'east',
      patch_id: 'adaptive-patch-v1-c0-r0',
      neighbor_patch_id: 'adaptive-patch-v1-c1-r0',
      positions: [[4, 0], [4, 2], [4, 4]]
    )
    west = contract_record(
      side: 'west',
      patch_id: 'adaptive-patch-v1-c1-r0',
      neighbor_patch_id: 'adaptive-patch-v1-c0-r0',
      positions: [[4, 4], [4, 2], [4, 0]]
    )

    assert_equal([[4, 0], [4, 2], [4, 4]], east.fetch(:positions))
    assert_equal(east.fetch(:positions), west.fetch(:positions))
    assert_equal(east.fetch(:chainDigest), west.fetch(:chainDigest))
  end

  def test_horizontal_orientation_is_west_to_east_independent_of_owner_side
    north = contract_record(
      side: 'north',
      patch_id: 'adaptive-patch-v1-c0-r0',
      neighbor_patch_id: 'adaptive-patch-v1-c0-r1',
      positions: [[4, 4], [2, 4], [0, 4]]
    )
    south = contract_record(
      side: 'south',
      patch_id: 'adaptive-patch-v1-c0-r1',
      neighbor_patch_id: 'adaptive-patch-v1-c0-r0',
      positions: [[0, 4], [2, 4], [4, 4]]
    )

    assert_equal([[0, 4], [2, 4], [4, 4]], north.fetch(:positions))
    assert_equal(north.fetch(:positions), south.fetch(:positions))
    assert_equal(north.fetch(:chainDigest), south.fetch(:chainDigest))
  end

  def test_digest_excludes_patch_side_neighbor_sketchup_and_z_fields
    baseline = contract_record(
      side: 'east',
      patch_id: 'patch-a',
      neighbor_patch_id: 'patch-b',
      positions: [[4, 0], [4, 2], [4, 4]],
      z_values: [1.0, 2.0, 3.0],
      sketchup_entity_id: 101
    )
    unstable = contract_record(
      side: 'west',
      patch_id: 'patch-b',
      neighbor_patch_id: 'patch-a',
      positions: [[4, 4], [4, 2], [4, 0]],
      z_values: [9.0, 8.0, 7.0],
      sketchup_entity_id: 202
    )

    assert_equal(baseline.fetch(:chainDigest), unstable.fetch(:chainDigest))
  end

  def test_world_edge_record_is_structural_but_has_no_neighbor_patch
    record = contract_record(
      side: 'west',
      patch_id: 'adaptive-patch-v1-c0-r0',
      neighbor_patch_id: nil,
      boundary_kind: 'world_edge',
      positions: [[0, 4], [0, 0]]
    )

    assert_equal('world_edge', record.fetch(:boundaryKind))
    refute_includes(record.keys, :neighborPatchId)
    assert_equal([[0, 0], [0, 4]], record.fetch(:positions))
    assert_equal(1, record.fetch(:segmentCount))
  end

  def test_rejects_non_reconstructable_positions
    error = assert_raises(ArgumentError) do
      contract_record(
        side: 'east',
        patch_id: 'adaptive-patch-v1-c0-r0',
        positions: [[4, 0]]
      )
    end

    assert_match(/positions/i, error.message)
  end

  def test_deduplicates_interior_positions_but_preserves_endpoints
    record = contract_record(
      side: 'east',
      patch_id: 'adaptive-patch-v1-c0-r0',
      positions: [[4, 0], [4, 2], [4, 2], [4, 4]]
    )

    assert_equal([[4, 0], [4, 2], [4, 4]], record.fetch(:positions))
    assert_equal({ start: [4, 0], finish: [4, 4] }, record.fetch(:endpoints))
  end

  private

  def contract_record(**options)
    SU_MCP::Terrain::AdaptiveSeams::AdaptiveSeamContract.build(
      schema_version: 1,
      policy_fingerprint: 'policy-a',
      edge_axis: edge_axis_for(options.fetch(:side)),
      edge_index: edge_index_for(options.fetch(:side), options.fetch(:positions)),
      **options
    )
  end

  def edge_axis_for(side)
    %w[east west].include?(side) ? 'column' : 'row'
  end

  def edge_index_for(side, positions)
    positions.first.fetch(%w[east west].include?(side) ? 0 : 1)
  end
end
