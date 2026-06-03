# frozen_string_literal: true

require 'set'

module SU_MCP
  module Terrain
    module AdaptivePatches
      # Persists adaptive patch registry records while retaining unaffected patch entries.
      class OutputRegistryWriter
        def initialize(patch_registry_store:, seam_gate:)
          @patch_registry_store = patch_registry_store
          @seam_gate = seam_gate
        end

        def write(owner:, output_plan:, patches:)
          patch_registry_store.write!(
            owner: owner,
            registry: {
              outputPolicyFingerprint: output_plan.adaptive_patch_policy.output_policy_fingerprint,
              stateDigest: output_plan.state_digest,
              stateRevision: output_plan.state_revision,
              ownerTransformSignature: nil,
              patches: retained_patches(owner, output_plan, patches) + patches
            }
          )
        end

        private

        attr_reader :patch_registry_store, :seam_gate

        def retained_patches(owner, output_plan, patches)
          patch_ids = patches.to_set { |patch| patch.fetch(:patchId) }
          retained = patch_registry_store.read(owner).fetch(:patches, []).reject do |patch|
            patch_ids.include?(patch.fetch(:patchId))
          end
          retained.map do |patch|
            patch_record_with_current_seams(patch, output_plan)
          end
        end

        def patch_record_with_current_seams(patch, output_plan)
          seam_records = seam_gate.records_for(output_plan).select do |record|
            record.fetch(:patchId) == patch.fetch(:patchId)
          end
          return patch if seam_records.empty?

          patch.merge(seamRecords: seam_records, seamStatus: 'valid')
        end
      end
    end
  end
end
