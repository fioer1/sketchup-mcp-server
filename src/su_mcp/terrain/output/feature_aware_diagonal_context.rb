# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Derived, bounds-gated feature/protection view for diagonal scoring.
    class FeatureAwareDiagonalContext
      SUPPORTED_REFERENCE_ROLES = %w[side_transition endpoint_cap falloff overlap].freeze

      def initialize(feature_geometry: nil, state: nil, config: {})
        @feature_geometry = feature_geometry
        @state = state
        @config = config
        @exact_check_count = 0
        @supported_input_counts = supported_input_counts
        @skipped_input_counts = skipped_input_counts
        @protected_bounds = normalized_protected_bounds
        @reference_segments = normalized_reference_segments
        @aggregate_bounds = aggregate_bounds_for(protected_bounds + reference_segments)
      end

      def safety_for(bounds)
        owner = owner_bounds(bounds)
        return safe_result unless aggregate_intersects?(owner)

        @exact_check_count += protected_bounds.length + reference_segments.length
        {
          candidate_safety: candidate_safety_for(owner),
          feature_alignment: feature_alignment_for(owner)
        }
      end

      def summary
        {
          supportedInputCounts: supported_input_counts,
          skippedInputCounts: skipped_input_counts,
          exactCheckCount: @exact_check_count,
          featureCheckBudget: config.fetch(:feature_check_budget, nil)
        }.compact
      end

      private

      attr_reader :feature_geometry, :state, :config, :protected_bounds, :reference_segments,
                  :aggregate_bounds

      def safe_result
        { candidate_safety: { baseline: :safe, alternate: :safe }, feature_alignment: nil }
      end

      def feature_alignment_for(owner)
        return nil unless reference_segments.any? { |entry| bounds_intersect?(entry, owner) }

        :baseline
      end

      def supported_input_counts
        counts = {}
        protected_count = protected_regions.count { |entry| supported_region?(entry) }
        counts[:protected_boundary] = protected_count if protected_count.positive?
        reference_count = reference_segments_raw.count do |entry|
          SUPPORTED_REFERENCE_ROLES.include?(entry['role'].to_s)
        end
        counts[:reference_segment] = reference_count if reference_count.positive?
        counts
      end

      def skipped_input_counts
        unsupported_reference_count = reference_segments_raw.count do |entry|
          !SUPPORTED_REFERENCE_ROLES.include?(entry['role'].to_s)
        end
        unsupported_region_count = protected_regions.count { |entry| !supported_region?(entry) }
        counts = {}
        counts[:unsupported_reference_role] = unsupported_reference_count if
          unsupported_reference_count.positive?
        counts[:unsupported_protected_region] = unsupported_region_count if
          unsupported_region_count.positive?
        counts
      end

      def protected_regions
        feature_geometry ? feature_geometry.protected_regions : []
      end

      def reference_segments_raw
        feature_geometry ? feature_geometry.reference_segments : []
      end

      def normalized_protected_bounds
        protected_regions.filter_map do |entry|
          next unless supported_region?(entry)

          protected_entry(entry)
        end
      end

      def normalized_reference_segments
        reference_segments_raw.filter_map do |entry|
          next unless SUPPORTED_REFERENCE_ROLES.include?(entry['role'].to_s)

          start_point = entry['ownerLocalStart']
          end_point = entry['ownerLocalEnd']
          next unless point_pair?(start_point) && point_pair?(end_point)

          {
            min_x: [start_point.fetch(0), end_point.fetch(0)].min,
            min_y: [start_point.fetch(1), end_point.fetch(1)].min,
            max_x: [start_point.fetch(0), end_point.fetch(0)].max,
            max_y: [start_point.fetch(1), end_point.fetch(1)].max
          }
        rescue KeyError, TypeError
          nil
        end
      end

      def supported_region?(entry)
        %w[rectangle circle].include?(entry['primitive'])
      end

      def candidate_safety_for(owner)
        {
          baseline: diagonal_status([owner.fetch(:min_x), owner.fetch(:min_y)],
                                    [owner.fetch(:max_x), owner.fetch(:max_y)], owner),
          alternate: diagonal_status([owner.fetch(:max_x), owner.fetch(:min_y)],
                                     [owner.fetch(:min_x), owner.fetch(:max_y)], owner)
        }
      end

      def diagonal_status(start_point, end_point, owner)
        crossed = protected_bounds.any? do |entry|
          bounds_intersect?(entry.fetch(:bounds), owner) &&
            protected_boundary_crossed?(entry, start_point, end_point)
        end
        crossed ? :unsafe : :safe
      end

      def protected_boundary_crossed?(entry, start_point, end_point)
        case entry.fetch(:primitive)
        when 'rectangle'
          entry.fetch(:edges).any? do |edge_start, edge_end|
            segments_intersect?(start_point, end_point, edge_start, edge_end)
          end
        else
          true
        end
      end

      def shape_bounds(entry)
        case entry['primitive']
        when 'rectangle'
          rectangle_bounds(entry['ownerLocalShape'] || entry['ownerLocalBounds'])
        when 'circle'
          circle_bounds(entry['ownerLocalCenterRadius'] || entry['ownerLocalShape'])
        end
      end

      def protected_entry(entry)
        bounds = shape_bounds(entry)
        return nil unless bounds

        result = { primitive: entry['primitive'], bounds: bounds }
        result[:edges] = rectangle_edges(bounds) if entry['primitive'] == 'rectangle'
        result
      end

      def rectangle_edges(bounds)
        min_x = bounds.fetch(:min_x)
        min_y = bounds.fetch(:min_y)
        max_x = bounds.fetch(:max_x)
        max_y = bounds.fetch(:max_y)
        [
          [[min_x, min_y], [max_x, min_y]],
          [[max_x, min_y], [max_x, max_y]],
          [[max_x, max_y], [min_x, max_y]],
          [[min_x, max_y], [min_x, min_y]]
        ]
      end

      def rectangle_bounds(shape)
        return nil unless shape.is_a?(Array) && shape.length == 2

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
        return nil unless shape.is_a?(Array) && shape.length == 3

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

      def owner_bounds(bounds)
        {
          min_x: value_from(bounds, :min_column).to_f,
          min_y: value_from(bounds, :min_row).to_f,
          max_x: value_from(bounds, :max_column).to_f,
          max_y: value_from(bounds, :max_row).to_f
        }
      end

      def value_from(hash, key)
        hash.fetch(key) { hash.fetch(key.to_s) }
      end

      def aggregate_bounds_for(entries)
        entries = entries.compact
        return nil if entries.empty?

        normalized = entries.map { |entry| entry[:bounds] || entry }
        {
          min_x: normalized.map { |entry| entry.fetch(:min_x) }.min,
          min_y: normalized.map { |entry| entry.fetch(:min_y) }.min,
          max_x: normalized.map { |entry| entry.fetch(:max_x) }.max,
          max_y: normalized.map { |entry| entry.fetch(:max_y) }.max
        }
      end

      def aggregate_intersects?(owner)
        aggregate_bounds && bounds_intersect?(aggregate_bounds, owner)
      end

      def bounds_intersect?(first, second)
        first.fetch(:min_x) <= second.fetch(:max_x) &&
          first.fetch(:max_x) >= second.fetch(:min_x) &&
          first.fetch(:min_y) <= second.fetch(:max_y) &&
          first.fetch(:max_y) >= second.fetch(:min_y)
      end

      def segments_intersect?(first_start, first_end, second_start, second_end)
        orientations = [
          orientation(first_start, first_end, second_start),
          orientation(first_start, first_end, second_end),
          orientation(second_start, second_end, first_start),
          orientation(second_start, second_end, first_end)
        ]
        collinear_touch?(orientations, first_start, first_end, second_start, second_end) ||
          crossing_touch?(orientations)
      end

      def collinear_touch?(orientations, first_start, first_end, second_start, second_end)
        [
          [orientations.fetch(0), second_start, first_start, first_end],
          [orientations.fetch(1), second_end, first_start, first_end],
          [orientations.fetch(2), first_start, second_start, second_end],
          [orientations.fetch(3), first_end, second_start, second_end]
        ].any? do |orientation_value, point, start_point, end_point|
          orientation_value.zero? && point_on_segment?(point, start_point, end_point)
        end
      end

      def crossing_touch?(orientations)
        orientations.fetch(0) != orientations.fetch(1) &&
          orientations.fetch(2) != orientations.fetch(3)
      end

      def orientation(first, second, third)
        value = ((second.fetch(1) - first.fetch(1)) * (third.fetch(0) - second.fetch(0))) -
                ((second.fetch(0) - first.fetch(0)) * (third.fetch(1) - second.fetch(1)))
        return 0 if value.abs <= 1e-9

        value.positive? ? 1 : 2
      end

      def point_on_segment?(point, start_point, end_point)
        point.fetch(0).between?(*[start_point.fetch(0), end_point.fetch(0)].minmax) &&
          point.fetch(1).between?(*[start_point.fetch(1), end_point.fetch(1)].minmax)
      end

      def point_pair?(point)
        point.is_a?(Array) && point.length >= 2
      end
    end
  end
end
