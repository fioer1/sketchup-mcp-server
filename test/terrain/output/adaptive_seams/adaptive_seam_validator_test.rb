# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../src/su_mcp/terrain/output/adaptive_seams/adaptive_seam_contract'
require_relative '../../../../src/su_mcp/terrain/output/adaptive_seams/adaptive_seam_validator'

class AdaptiveSeamValidatorTest < Minitest::Test
  def test_planned_counterparts_pass_when_topology_and_z_values_match
    result = validate(planned_record, retained_record)

    assert_equal(:passed, result.fetch(:status))
    assert_equal('planned_vs_registry', result.fetch(:comparisonMode))
    assert_equal(0.0, result.fetch(:maxZGap))
  end

  def test_topology_digest_match_with_z_mismatch_fails_for_z_only_reason
    retained = retained_record(z_values: [1.0, 1.0, 1.00000001])

    result = validate(planned_record, retained)

    assert_equal(:failed, result.fetch(:status))
    assert_equal('z_mismatch', result.fetch(:mismatchCategory))
    assert_operator(result.fetch(:maxZGap), :>, 1e-9)
  end

  def test_records_max_z_gap_across_entire_chain
    retained = retained_record(z_values: [1.0, 1.000000002, 1.00000001])

    result = validate(planned_record, retained)

    assert_in_delta(0.00000001, result.fetch(:maxZGap), 1e-12)
  end

  def test_rejects_schema_policy_owner_edge_topology_and_malformed_mismatches
    expectations = {
      schema_version_mismatch: retained_record(schema_version: 2),
      output_policy_fingerprint_mismatch: retained_record(policy_fingerprint: 'other-policy'),
      owner_edge_identity_mismatch: retained_record(edge_index: 5),
      topology_mismatch: retained_record(positions: [[4, 0], [4, 1], [4, 4]]),
      malformed_seam_record: retained_record(positions: [[4, 0]])
    }

    expectations.each do |category, retained|
      result = validate(planned_record, retained)

      assert_equal(:failed, result.fetch(:status), "expected #{category} to fail")
      assert_equal(category.to_s, result.fetch(:mismatchCategory))
    end
  end

  def test_registry_source_of_truth_is_not_overridden_by_geometry_hint
    result = SU_MCP::Terrain::AdaptiveSeams::AdaptiveSeamValidator.validate_retained(
      planned: planned_record,
      retained: retained_record(positions: [[4, 0], [4, 1], [4, 4]]),
      geometry_hint: retained_record
    )

    assert_equal(:failed, result.fetch(:status))
    assert_equal('topology_mismatch', result.fetch(:mismatchCategory))
  end

  private

  def validate(planned, retained)
    SU_MCP::Terrain::AdaptiveSeams::AdaptiveSeamValidator.validate_retained(
      planned: planned,
      retained: retained
    )
  end

  def planned_record(**overrides)
    record(
      side: 'east',
      patch_id: 'adaptive-patch-v1-c0-r0',
      neighbor_patch_id: 'adaptive-patch-v1-c1-r0',
      positions: [[4, 0], [4, 2], [4, 4]],
      z_values: [1.0, 1.0, 1.0],
      **overrides
    )
  end

  def retained_record(**overrides)
    record(
      side: 'west',
      patch_id: 'adaptive-patch-v1-c1-r0',
      neighbor_patch_id: 'adaptive-patch-v1-c0-r0',
      positions: [[4, 4], [4, 2], [4, 0]],
      z_values: [1.0, 1.0, 1.0],
      **overrides
    )
  end

  def record(**options)
    side = options.fetch(:side)
    positions = options.fetch(:positions)
    SU_MCP::Terrain::AdaptiveSeams::AdaptiveSeamContract.build(
      schema_version: options.delete(:schema_version) { 1 },
      policy_fingerprint: options.delete(:policy_fingerprint) { 'policy-a' },
      edge_axis: %w[east west].include?(side) ? 'column' : 'row',
      edge_index: options.delete(:edge_index) { edge_index_for(side, positions) },
      **options
    )
  rescue ArgumentError
    options.merge(malformed: true)
  end

  def edge_index_for(side, positions)
    positions.first.fetch(%w[east west].include?(side) ? 0 : 1)
  end
end
