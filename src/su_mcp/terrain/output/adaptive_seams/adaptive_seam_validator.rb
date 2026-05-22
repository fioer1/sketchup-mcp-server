# frozen_string_literal: true

require 'digest'
require 'json'

module SU_MCP
  module Terrain
    module AdaptiveSeams
      # Compares planned seam records without consulting live SketchUp geometry.
      class AdaptiveSeamValidator
        PLANNED_Z_TOLERANCE = 1e-9

        def self.validate_retained(planned:, retained:, geometry_hint: nil)
          new(planned: planned, retained: retained, geometry_hint: geometry_hint).validate_retained
        end

        def self.structurally_valid?(record)
          record.is_a?(Hash) &&
            !record[:malformed] &&
            Array(record[:positions] || record['positions']).length >= 2 &&
            digest_matches_positions?(record)
        end

        def self.digest_matches_positions?(record)
          digest = record[:chainDigest] || record['chainDigest']
          return true unless digest

          digest == Digest::SHA256.hexdigest(
            JSON.generate(
              schemaVersion: record[:schemaVersion] || record['schemaVersion'],
              edgeAxis: record[:edgeAxis] || record['edgeAxis'],
              edgeIndex: record[:edgeIndex] || record['edgeIndex'],
              positions: record[:positions] || record['positions']
            )
          )
        end

        def self.failed(category, mode, max_z_gap = 0.0)
          {
            status: :failed,
            comparisonMode: mode,
            mismatchCategory: category,
            maxZGap: max_z_gap
          }
        end

        def initialize(planned:, retained:, geometry_hint: nil)
          @planned = planned
          @retained = retained
          @geometry_hint = geometry_hint
        end

        def validate_retained
          unless valid_record?(planned) && valid_record?(retained)
            return failed('malformed_seam_record')
          end

          return failed('schema_version_mismatch') unless same?(:schemaVersion)
          return failed('output_policy_fingerprint_mismatch') unless
            same?(:outputPolicyFingerprint)
          return failed('owner_edge_identity_mismatch') unless same?(:edgeAxis) && same?(:edgeIndex)
          return failed('topology_mismatch') unless same?(:chainDigest)

          max_gap = max_z_gap
          return failed('z_mismatch', max_gap) if max_gap > PLANNED_Z_TOLERANCE

          {
            status: :passed,
            comparisonMode: 'planned_vs_registry',
            maxZGap: max_gap,
            promotionEligible: false
          }
        end

        private

        attr_reader :planned, :retained, :geometry_hint

        def valid_record?(record)
          self.class.structurally_valid?(record)
        end

        def same?(key)
          value(planned, key) == value(retained, key)
        end

        def value(record, key)
          record.fetch(key) { record.fetch(key.to_s, nil) }
        end

        def max_z_gap
          planned_values = Array(value(planned, :zValues))
          retained_values = Array(value(retained, :zValues))
          # Some pre-erase retained checks intentionally compare topology only; the
          # post-emit host verification path owns z-inclusive retained validation.
          return 0.0 if planned_values.empty? || retained_values.empty?

          planned_values.zip(retained_values).map do |planned_z, retained_z|
            (planned_z.to_f - retained_z.to_f).abs
          end.max || 0.0
        end

        def failed(category, max_z_gap = 0.0)
          self.class.failed(category, 'planned_vs_registry', max_z_gap)
        end
      end
    end
  end
end
