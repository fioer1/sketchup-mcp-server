# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../support/semantic_test_support'
require_relative '../../../../src/su_mcp/terrain/output/patch_lifecycle/patch_registry_store'

class PatchRegistryStoreTest < Minitest::Test
  include SemanticTestSupport

  def test_registry_key_is_configurable_for_cdt_or_adaptive_owners
    owner = build_semantic_model.active_entities.add_group
    store = SU_MCP::Terrain::PatchLifecycle::PatchRegistryStore.new(
      registry_key: 'cdtPatchRegistry'
    )

    store.write!(
      owner: owner,
      registry: {
        outputPolicyFingerprint: 'fingerprint-a',
        stateDigest: 'digest-1',
        stateRevision: 1,
        patches: [{ patchId: 'cdt-patch-v1-c0-r0', faceCount: 2 }]
      }
    )

    assert_instance_of(String, owner.get_attribute('su_mcp_terrain', 'cdtPatchRegistry'))
    assert_equal(
      ['cdt-patch-v1-c0-r0'],
      store.read(owner).fetch(:patches).map { |patch| patch.fetch(:patchId) }
    )
  end

  def test_registry_round_trips_reconstructable_patch_side_seam_records
    owner = build_semantic_model.active_entities.add_group
    store = SU_MCP::Terrain::PatchLifecycle::PatchRegistryStore.new(
      registry_key: 'adaptivePatchRegistry'
    )

    store.write!(
      owner: owner,
      registry: {
        outputPolicyFingerprint: 'fingerprint-a',
        stateDigest: 'digest-1',
        stateRevision: 1,
        patches: [
          {
            patchId: 'adaptive-patch-v1-c0-r0',
            faceCount: 2,
            seamRecords: [
              {
                schemaVersion: 1,
                side: 'east',
                edgeAxis: 'column',
                edgeIndex: 4,
                boundaryKind: 'neighbor',
                neighborPatchId: 'adaptive-patch-v1-c1-r0',
                positions: [[4, 0], [4, 2], [4, 4]],
                endpoints: { start: [4, 0], finish: [4, 4] },
                segmentCount: 2,
                chainDigest: 'digest-a',
                outputPolicyFingerprint: 'fingerprint-a'
              }
            ]
          }
        ]
      }
    )

    seam_records = store.read(owner).fetch(:patches).first.fetch(:seamRecords)

    assert_equal([[4, 0], [4, 2], [4, 4]], seam_records.first.fetch(:positions))
    assert_equal(2, seam_records.first.fetch(:segmentCount))
  end

  def test_malformed_patch_seam_records_invalidate_only_that_patch_for_local_replacement
    owner = build_semantic_model.active_entities.add_group
    store = SU_MCP::Terrain::PatchLifecycle::PatchRegistryStore.new(
      registry_key: 'adaptivePatchRegistry'
    )

    store.write!(
      owner: owner,
      registry: {
        outputPolicyFingerprint: 'fingerprint-a',
        stateDigest: 'digest-1',
        stateRevision: 1,
        patches: [
          {
            patchId: 'adaptive-patch-v1-c0-r0',
            faceCount: 2,
            seamRecords: [{ schemaVersion: 1, positions: [[4, 0]] }]
          },
          {
            patchId: 'adaptive-patch-v1-c1-r0',
            faceCount: 2,
            seamRecords: []
          }
        ]
      }
    )

    patches = store.read(owner).fetch(:patches)

    assert_equal('invalidated', patches.fetch(0).fetch(:seamStatus))
    assert_equal('valid', patches.fetch(1).fetch(:seamStatus))
  end
end
