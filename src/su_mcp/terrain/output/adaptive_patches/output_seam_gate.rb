# frozen_string_literal: true

require_relative '../adaptive_seams/adaptive_seam_validator'

module SU_MCP
  module Terrain
    module AdaptivePatches
      # Validates retained adaptive seams and formats seam diagnostics.
      class OutputSeamGate
        def initialize(patch_registry_store:)
          @patch_registry_store = patch_registry_store
        end

        def validate_before_mutation(owner:, output_plan:, replacement_patch_ids:)
          sealed = output_plan.sealed_adaptive_seam_plan
          return { status: :failed, reason: :missing_seam_plan } unless sealed
          return { status: :failed, reason: :sealed_scope_mismatch } unless
            sealed.replacement_patch_ids.sort == replacement_patch_ids.sort

          registry = patch_registry_store.read(owner)
          return { status: :failed, reason: :registry_invalid } unless
            registry.fetch(:status) == 'valid'

          retained_seam_validation(
            registry: registry,
            output_plan: output_plan,
            replacement_patch_ids: replacement_patch_ids
          )
        end

        def records_for(output_plan)
          return [] unless output_plan.respond_to?(:adaptive_seam_records)

          output_plan.adaptive_seam_records
        end

        def summary(output_plan, retained_result: nil)
          validations = Array(output_plan.adaptive_seam_validations)
          retained = retained_entry(retained_result)
          entries = validation_entries(validations, retained)
          {
            status: seam_status(entries),
            seamRecordCount: records_for(output_plan).length,
            validationCount: validations.length,
            replacementPatchCount: replacement_patch_count(output_plan),
            maxZGap: max_z_gap(entries),
            mismatchCategory: mismatch_category(entries),
            sameBatch: same_batch_entries(entries, validations.length),
            retained: retained
          }.compact
        end

        private

        attr_reader :patch_registry_store

        def retained_seam_validation(registry:, output_plan:, replacement_patch_ids:)
          patch_records = registry.fetch(:patches, []).to_h do |patch|
            [patch.fetch(:patchId), patch]
          end
          records_for(output_plan).each do |record|
            next unless retained_neighbor_record?(record, replacement_patch_ids)

            result = retained_record_validation(output_plan, patch_records, record)
            return result unless result.fetch(:status) == :passed
          end
          { status: :passed }
        end

        def retained_record_validation(output_plan, patch_records, record)
          retained_patch = patch_records[record.fetch(:neighborPatchId)]
          retained = retained_seam_record(retained_patch, record) ||
                     legacy_retained_context_seam_record(output_plan, retained_patch, record)
          return { status: :failed, reason: :retained_seam_missing } unless retained

          AdaptiveSeams::AdaptiveSeamValidator.validate_retained(
            planned: record_without_z(record),
            retained: record_without_z(retained)
          )
        end

        def retained_entry(retained_result)
          return nil unless retained_result

          validation_entry(retained_result)
        end

        def replacement_patch_count(output_plan)
          output_plan.sealed_adaptive_seam_plan&.replacement_patch_ids&.length
        end

        def validation_entries(validations, retained)
          entries = validations.map { |validation| validation_entry(validation) }
          retained ? entries + [retained] : entries
        end

        def seam_status(entries)
          entries.any? { |entry| entry.fetch(:status) == 'failed' } ? 'failed' : 'passed'
        end

        def max_z_gap(entries)
          entries.map { |entry| entry.fetch(:maxZGap, 0.0).to_f }.max || 0.0
        end

        def mismatch_category(entries)
          entries.find { |entry| entry[:mismatchCategory] }&.fetch(:mismatchCategory)
        end

        def same_batch_entries(entries, count)
          return nil if entries.empty?

          entries.first(count)
        end

        def validation_entry(validation)
          {
            status: validation.fetch(:status).to_s,
            comparisonMode: validation.fetch(:comparisonMode, nil),
            mismatchCategory: validation.fetch(:mismatchCategory, nil),
            reason: validation.fetch(:reason, nil)&.to_s,
            maxZGap: validation.fetch(:maxZGap, 0.0).to_f
          }.compact
        end

        def record_without_z(record)
          record.reject { |key, _value| key.to_s == 'zValues' }
        end

        def retained_neighbor_record?(record, replacement_patch_ids)
          record.fetch(:replacementSide, false) &&
            record.fetch(:boundaryKind) == 'neighbor' &&
            !replacement_patch_ids.include?(record.fetch(:neighborPatchId))
        end

        def retained_seam_record(patch_records, planned_record)
          patch = patch_records
          return nil unless patch && patch.fetch(:seamStatus, 'valid') == 'valid'

          patch.fetch(:seamRecords, []).find do |record|
            record.fetch(:neighborPatchId, nil) == planned_record.fetch(:patchId) &&
              record.fetch(:edgeAxis) == planned_record.fetch(:edgeAxis) &&
              record.fetch(:edgeIndex) == planned_record.fetch(:edgeIndex)
          end
        end

        def legacy_retained_context_seam_record(output_plan, retained_patch, planned_record)
          return nil unless retained_patch && retained_patch.fetch(:seamStatus, 'valid') == 'valid'
          return nil unless retained_patch.fetch(:seamRecords, []).empty?

          records_for(output_plan).find do |record|
            !record.fetch(:replacementSide, false) &&
              record.fetch(:patchId) == planned_record.fetch(:neighborPatchId) &&
              record.fetch(:neighborPatchId, nil) == planned_record.fetch(:patchId) &&
              record.fetch(:edgeAxis) == planned_record.fetch(:edgeAxis) &&
              record.fetch(:edgeIndex) == planned_record.fetch(:edgeIndex)
          end
        end
      end
    end
  end
end
