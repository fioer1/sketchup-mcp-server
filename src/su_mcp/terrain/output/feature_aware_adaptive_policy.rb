# frozen_string_literal: true

require 'digest'
require 'json'

require_relative 'feature_aware_forced_subdivision_mask'

module SU_MCP
  module Terrain
    # Pure planning policy seam for feature-aware adaptive output.
    class FeatureAwareAdaptivePolicy # rubocop:disable Metrics/ClassLength
      HARD_MULTIPLIER = 0.25
      PROTECTED_MULTIPLIER = 0.25
      FIRM_MULTIPLIER = 0.5
      SOFT_MULTIPLIER = 1.0
      TOLERANCE_FLOOR_MULTIPLIER = 0.1

      def initialize(feature_geometry: nil, state: nil, base_tolerance: 0.01)
        @feature_geometry = feature_geometry
        @state = state
        @base_tolerance = base_tolerance
        @tolerance_hits = []
        @density_hit_count = 0
        @output_anchor_candidates = if feature_geometry
                                      feature_geometry.output_anchor_candidates
                                    else
                                      []
                                    end
        @protected_regions = feature_geometry ? feature_geometry.protected_regions : []
        @pressure_regions = feature_geometry ? feature_geometry.pressure_regions : []
        @planar_regions = feature_geometry ? normalized_planar_regions : []
        @supported_pressure_regions = normalized_supported_pressure_regions
        @forced_subdivision_mask = FeatureAwareForcedSubdivisionMask.new(
          feature_geometry: feature_geometry,
          state: state
        )
      end

      def local_tolerance_for(bounds)
        tolerance = applicable_tolerance_values(owner_bounds(bounds)).min || base_tolerance
        tolerance = [tolerance, base_tolerance * TOLERANCE_FLOOR_MULTIPLIER].max
        record_tolerance_hit(tolerance) if tolerance < base_tolerance
        tolerance
      end

      def target_cell_size_for(bounds)
        target = target_cell_size_for_owner(owner_bounds(bounds))
        @density_hit_count += 1 if target
        target
      end

      def planar_compaction_candidate?(bounds, column_span:, row_span:)
        owner = owner_bounds(bounds)
        return false unless planar_interior?(owner)
        return false if target_cell_size_for_owner(owner)
        return false if forced_subdivision_mask.target_cell_size_for_owner(owner)
        return false if local_tolerance_for_owner(owner) < base_tolerance

        column_span.positive? && row_span.positive?
      end

      def split_pressure_for(bounds, column_span:, row_span:)
        owner = owner_bounds(bounds)
        target_cell_size = target_cell_size_for_owner(owner)
        forced_split = forced_subdivision_mask.split_required?(
          bounds,
          column_span: column_span,
          row_span: row_span,
          owner_bounds: owner
        )
        tolerance = local_tolerance_for_owner(owner)
        @density_hit_count += 1 if target_cell_size
        record_tolerance_hit(tolerance) if tolerance < base_tolerance
        {
          tolerance: tolerance,
          target_cell_size: target_cell_size,
          density_split: density_split_required?(target_cell_size, column_span, row_span),
          forced_split: forced_split,
          planar_interior: planar_interior?(owner)
        }
      end

      def summary
        # Counters describe the completed planning pass that used this policy instance.
        {
          policyFingerprint: policy_fingerprint,
          featureGeometryDigest: feature_geometry_digest,
          toleranceRange: tolerance_range,
          hardProtectedToleranceHitCount: hard_protected_tolerance_hit_count,
          hardProtectedToleranceRange: hard_protected_tolerance_range,
          densityHitCount: @density_hit_count,
          forcedSubdivisionSummary: forced_subdivision_mask.summary,
          fallbackCounts: fallback_counts
        }.compact
      end

      def policy_fingerprint
        digest_for(
          baseTolerance: base_tolerance,
          hardMultiplier: HARD_MULTIPLIER,
          protectedMultiplier: PROTECTED_MULTIPLIER,
          firmMultiplier: FIRM_MULTIPLIER,
          softMultiplier: SOFT_MULTIPLIER,
          toleranceFloorMultiplier: TOLERANCE_FLOOR_MULTIPLIER,
          anchorForcedCellSize: FeatureAwareForcedSubdivisionMask::ANCHOR_FORCED_CELL_SIZE,
          protectedBoundaryForcedCellSize:
            FeatureAwareForcedSubdivisionMask::PROTECTED_BOUNDARY_FORCED_CELL_SIZE,
          corridorDetailForcedCellSize:
            FeatureAwareForcedSubdivisionMask::CORRIDOR_DETAIL_FORCED_CELL_SIZE
        )
      end

      private

      attr_reader :feature_geometry, :state, :base_tolerance, :forced_subdivision_mask,
                  :output_anchor_candidates, :protected_regions, :pressure_regions,
                  :planar_regions, :supported_pressure_regions

      def target_cell_size_for_owner(owner)
        matches = supported_pressure_regions.filter_map do |region|
          next unless terrain_bounds_intersect?(region.fetch(:bounds), owner)

          region.fetch(:target_cell_size)
        end
        matches.min
      end

      def local_tolerance_for_owner(owner)
        tolerance = applicable_tolerance_values(owner).min || base_tolerance
        [tolerance, base_tolerance * TOLERANCE_FLOOR_MULTIPLIER].max
      end

      def applicable_tolerance_values(owner)
        tolerance_values = []
        tolerance_values.concat(anchor_tolerance_values(owner))
        tolerance_values.concat(protected_region_tolerance_values(owner))
        tolerance_values.concat(pressure_region_tolerance_values(owner))
        tolerance_values.compact
      end

      def anchor_tolerance_values(owner)
        output_anchor_candidates.filter_map do |anchor|
          next unless point_intersects_owner?(anchor['ownerLocalPoint'], owner)

          base_tolerance * multiplier_for(anchor['strength'], anchor['role'])
        end
      end

      def protected_region_tolerance_values(owner)
        protected_regions.filter_map do |region|
          region_bounds = shape_bounds(region)
          next unless region_bounds && terrain_bounds_intersect?(region_bounds, owner)

          base_tolerance * PROTECTED_MULTIPLIER
        end
      end

      def pressure_region_tolerance_values(owner)
        supported_pressure_regions.filter_map do |region|
          next unless terrain_bounds_intersect?(region.fetch(:bounds), owner)

          base_tolerance * multiplier_for(region.fetch(:strength), region.fetch(:role))
        end
      end

      def record_tolerance_hit(tolerance)
        @tolerance_hits << tolerance
      end

      def hard_protected_tolerance_hit_count
        @tolerance_hits.count { |hit| hit <= base_tolerance * HARD_MULTIPLIER }
      end

      def tolerance_range
        range_for(@tolerance_hits)
      end

      def hard_protected_tolerance_range
        range_for(@tolerance_hits.select { |hit| hit <= base_tolerance * HARD_MULTIPLIER })
      end

      def range_for(values)
        return nil if values.empty?

        { min: values.min, max: values.max }
      end

      def multiplier_for(strength, role)
        normalized_strength = strength.to_s
        normalized_role = role.to_s
        return HARD_MULTIPLIER if normalized_strength == 'hard'
        return PROTECTED_MULTIPLIER if normalized_role.include?('protected')
        return FIRM_MULTIPLIER if normalized_strength == 'firm'

        SOFT_MULTIPLIER
      end

      def normalized_supported_pressure_regions
        pressure_regions.filter_map do |region|
          next unless %w[rectangle circle].include?(region['primitive'])

          bounds = shape_bounds(region)
          next unless bounds

          {
            bounds: bounds,
            target_cell_size: positive_integer(region['targetCellSize']),
            strength: region['strength'],
            role: region['role']
          }
        end
      end

      def normalized_planar_regions
        feature_geometry.planar_regions.filter_map do |region|
          next unless region['primitive'] == 'rectangle'

          bounds = shape_bounds(region)
          next unless bounds

          bounds
        end
      end

      def shape_bounds(entry)
        case entry['primitive']
        when 'rectangle'
          rectangle_bounds(shape_payload(entry))
        when 'circle'
          circle_bounds(shape_payload(entry))
        end
      end

      def shape_payload(entry)
        entry['ownerLocalShape'] || entry['ownerLocalBounds'] || entry['ownerLocalCenterRadius']
      end

      def rectangle_bounds(shape)
        return false unless shape.is_a?(Array) && shape.length == 2

        min, max = shape
        {
          min_x: [min.fetch(0), max.fetch(0)].min,
          min_y: [min.fetch(1), max.fetch(1)].min,
          max_x: [min.fetch(0), max.fetch(0)].max,
          max_y: [min.fetch(1), max.fetch(1)].max
        }
      rescue KeyError, TypeError, NoMethodError
        nil
      end

      def circle_bounds(shape)
        return false unless shape.is_a?(Array) && shape.length == 3

        center_x, center_y, radius = shape
        {
          min_x: center_x - radius,
          min_y: center_y - radius,
          max_x: center_x + radius,
          max_y: center_y + radius
        }
      rescue TypeError
        nil
      end

      def terrain_bounds_intersect?(first, second)
        first.fetch(:min_x) <= second.fetch(:max_x) &&
          first.fetch(:max_x) >= second.fetch(:min_x) &&
          first.fetch(:min_y) <= second.fetch(:max_y) &&
          first.fetch(:max_y) >= second.fetch(:min_y)
      end

      def terrain_bounds_contain?(outer, inner)
        outer.fetch(:min_x) <= inner.fetch(:min_x) &&
          outer.fetch(:max_x) >= inner.fetch(:max_x) &&
          outer.fetch(:min_y) <= inner.fetch(:min_y) &&
          outer.fetch(:max_y) >= inner.fetch(:max_y)
      end

      def planar_interior?(owner)
        planar_regions.any? { |region| terrain_bounds_contain?(region, owner) }
      end

      def point_intersects_owner?(point, owner)
        return false unless point.is_a?(Array) && point.length >= 2

        point.fetch(0).between?(owner.fetch(:min_x), owner.fetch(:max_x)) &&
          point.fetch(1).between?(owner.fetch(:min_y), owner.fetch(:max_y))
      rescue KeyError, TypeError
        false
      end

      def owner_bounds(bounds)
        min_column = bounds.fetch(:min_column) { bounds.fetch('min_column') }
        min_row = bounds.fetch(:min_row) { bounds.fetch('min_row') }
        max_column = bounds.fetch(:max_column) { bounds.fetch('max_column') }
        max_row = bounds.fetch(:max_row) { bounds.fetch('max_row') }
        {
          min_x: axis_value(min_column, 'x'),
          min_y: axis_value(min_row, 'y'),
          max_x: axis_value(max_column, 'x'),
          max_y: axis_value(max_row, 'y')
        }
      end

      def axis_value(index, axis)
        origin = state&.origin&.fetch(axis, 0.0) || 0.0
        spacing = state&.spacing&.fetch(axis, 1.0) || 1.0
        origin + (index * spacing)
      end

      def fallback_counts
        {
          absentFeatureGeometry: feature_geometry ? 0 : 1,
          partialFeatureGeometry: partial_feature_geometry? ? 1 : 0,
          unsupportedFeatureGeometry: unsupported_feature_geometry? ? 1 : 0
        }
      end

      def partial_feature_geometry?
        return false unless feature_geometry

        !feature_geometry.limitations.empty?
      end

      def unsupported_feature_geometry?
        return false unless feature_geometry

        unsupported_pressures = pressure_regions.any? do |region|
          !%w[rectangle circle].include?(region['primitive'])
        end
        unsupported_pressures || feature_geometry.failure_category != 'none'
      end

      def feature_geometry_digest
        return nil unless feature_geometry

        feature_geometry.feature_geometry_digest
      end

      def positive_integer(value)
        integer = value.to_i
        integer.positive? ? integer : nil
      end

      def density_split_required?(target_cell_size, column_span, row_span)
        return false unless target_cell_size

        column_span > target_cell_size || row_span > target_cell_size
      end

      def digest_for(value)
        Digest::SHA256.hexdigest(JSON.generate(value))
      end
    end
  end
end
