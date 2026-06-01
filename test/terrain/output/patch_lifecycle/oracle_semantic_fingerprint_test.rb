# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../src/su_mcp/terrain/output/patch_lifecycle/patch_grid_policy'

class OracleSemanticFingerprintTest < Minitest::Test
  def test_patch_policy_fingerprint_changes_with_oracle_semantic_token
    base = SU_MCP::Terrain::PatchLifecycle::PatchGridPolicy.new(
      patch_id_prefix: 'adaptive-patch',
      fingerprint_kind: 'adaptive-patch',
      oracle_semantic_token: 'composed-height-oracle:v1'
    )
    changed = SU_MCP::Terrain::PatchLifecycle::PatchGridPolicy.new(
      patch_id_prefix: 'adaptive-patch',
      fingerprint_kind: 'adaptive-patch',
      oracle_semantic_token: 'composed-height-oracle:v2'
    )

    refute_equal(base.output_policy_fingerprint, changed.output_policy_fingerprint)
  end
end
