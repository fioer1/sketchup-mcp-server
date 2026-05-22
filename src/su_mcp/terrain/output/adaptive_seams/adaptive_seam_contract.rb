# frozen_string_literal: true

require 'digest'
require 'json'

module SU_MCP
  module Terrain
    module AdaptiveSeams
      # Builds compact deterministic patch-side seam records for adaptive output.
      class AdaptiveSeamContract
        VERTICAL_SIDES = %w[east west].freeze

        def self.build(
          schema_version:,
          side:,
          patch_id:,
          edge_axis:,
          edge_index:,
          positions:,
          policy_fingerprint: nil,
          neighbor_patch_id: nil,
          boundary_kind: nil,
          z_values: nil,
          sketchup_entity_id: nil
        )
          new(
            schema_version: schema_version,
            side: side,
            patch_id: patch_id,
            edge_axis: edge_axis,
            edge_index: edge_index,
            positions: positions,
            policy_fingerprint: policy_fingerprint,
            neighbor_patch_id: neighbor_patch_id,
            boundary_kind: boundary_kind,
            z_values: z_values,
            sketchup_entity_id: sketchup_entity_id
          ).to_h
        end

        def initialize(options)
          @schema_version = options.fetch(:schema_version)
          @side = options.fetch(:side)
          @patch_id = options.fetch(:patch_id)
          @edge_axis = options.fetch(:edge_axis)
          @edge_index = options.fetch(:edge_index)
          @positions = options.fetch(:positions)
          @policy_fingerprint = options[:policy_fingerprint]
          @neighbor_patch_id = options[:neighbor_patch_id]
          @boundary_kind = options[:boundary_kind] || 'neighbor'
          @z_values = options[:z_values]
          @sketchup_entity_id = options[:sketchup_entity_id]
        end

        def to_h
          canonical_positions = self.class.canonical_positions(side, positions)
          validate_positions!(canonical_positions)
          record = {
            schemaVersion: schema_version,
            side: side,
            patchId: patch_id,
            boundaryKind: boundary_kind,
            edgeAxis: edge_axis,
            edgeIndex: edge_index,
            positions: canonical_positions,
            segmentCount: canonical_positions.length - 1,
            endpoints: {
              start: canonical_positions.first,
              finish: canonical_positions.last
            },
            chainDigest: chain_digest(canonical_positions),
            outputPolicyFingerprint: policy_fingerprint,
            zValues: canonical_z_values(canonical_positions)
          }.compact
          record[:comparisonMode] = 'world_edge' if boundary_kind == 'world_edge'
          record[:neighborPatchId] = neighbor_patch_id if neighbor_patch_id
          record[:sketchupEntityId] = sketchup_entity_id if sketchup_entity_id
          record
        end

        def self.canonical_positions(side, positions)
          normalized = Array(positions).map do |position|
            raise ArgumentError, 'seam positions must be coordinate pairs' unless
              position.is_a?(Array) && position.length >= 2

            [position.fetch(0), position.fetch(1)]
          end
          sorted = if VERTICAL_SIDES.include?(side.to_s)
                     normalized.sort_by { |column, row| [row, column] }
                   else
                     normalized.sort_by { |column, row| [column, row] }
                   end
          deduplicate(sorted)
        end

        def self.deduplicate(positions)
          positions.each_with_object([]) do |position, selected|
            selected << position unless selected.last == position
          end
        end

        private

        attr_reader :schema_version, :side, :patch_id, :edge_axis, :edge_index, :positions,
                    :policy_fingerprint, :neighbor_patch_id, :boundary_kind, :z_values,
                    :sketchup_entity_id

        def validate_positions!(canonical_positions)
          return if canonical_positions.length >= 2

          raise ArgumentError, 'seam positions must include at least two reconstructable points'
        end

        def chain_digest(canonical_positions)
          Digest::SHA256.hexdigest(
            JSON.generate(
              schemaVersion: schema_version,
              edgeAxis: edge_axis,
              edgeIndex: edge_index,
              positions: canonical_positions
            )
          )
        end

        def canonical_z_values(canonical_positions)
          return nil unless z_values

          original = Array(positions).map.with_index do |position, index|
            [[position.fetch(0), position.fetch(1)], z_values.fetch(index)]
          end.to_h
          canonical_positions.map { |position| original.fetch(position) }
        end
      end
    end
  end
end
