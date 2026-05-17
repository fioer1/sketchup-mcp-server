# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Derived output-only mask that applies feature-critical subdivision pressure.
    class FeatureAwareForcedSubdivisionMask # rubocop:disable Metrics/ClassLength
      ANCHOR_FORCED_CELL_SIZE = 1
      PROTECTED_BOUNDARY_FORCED_CELL_SIZE = 2
      CORRIDOR_DETAIL_FORCED_CELL_SIZE = 2
      CORRIDOR_DETAIL_ROLES = %w[side_transition endpoint_cap falloff overlap].freeze

      def initialize(feature_geometry:, state:)
        @feature_geometry = feature_geometry
        @state = state
        @hit_count = 0
        @output_anchor_candidates = if feature_geometry
                                      feature_geometry.output_anchor_candidates
                                    else
                                      []
                                    end
        @protected_regions = feature_geometry ? feature_geometry.protected_regions : []
        @pressure_regions = feature_geometry ? feature_geometry.pressure_regions : []
        @reference_segments = feature_geometry ? feature_geometry.reference_segments : []
        @forced_anchors = normalized_forced_anchors
        @protected_boundaries = normalized_protected_boundaries
        @corridor_detail_segments = normalized_corridor_detail_segments
        @supported_input_counts = build_supported_input_counts
        @skipped_input_counts = build_skipped_input_counts
        @aggregate_bounds = aggregate_mask_bounds
      end

      def split_required?(bounds, column_span:, row_span:, owner_bounds: nil)
        owner = owner_bounds || self.owner_bounds(bounds)
        return false unless aggregate_bounds_intersect?(owner)

        target = target_cell_size(owner)
        required = target && (column_span > target || row_span > target)
        @hit_count += 1 if required
        !!required
      end

      def summary
        {
          supportedInputCounts: supported_input_counts,
          skippedInputCounts: skipped_input_counts,
          hitCount: @hit_count
        }
      end

      private

      attr_reader :feature_geometry, :state, :output_anchor_candidates, :protected_regions,
                  :pressure_regions, :reference_segments, :forced_anchors,
                  :protected_boundaries, :corridor_detail_segments, :supported_input_counts,
                  :skipped_input_counts, :aggregate_bounds

      def target_cell_size(owner)
        targets = []
        targets.concat(anchor_cell_sizes(owner))
        targets.concat(protected_boundary_cell_sizes(owner))
        targets.concat(corridor_detail_cell_sizes(owner))
        targets.min
      end

      def anchor_cell_sizes(owner)
        forced_anchors.filter_map do |anchor|
          next unless point_intersects_owner?(anchor, owner)

          ANCHOR_FORCED_CELL_SIZE
        end
      end

      def protected_boundary_cell_sizes(owner)
        protected_boundaries.filter_map do |boundary|
          next unless protected_boundary_intersects_owner?(boundary, owner)

          PROTECTED_BOUNDARY_FORCED_CELL_SIZE
        end
      end

      def corridor_detail_cell_sizes(owner)
        corridor_detail_segments.filter_map do |segment|
          next unless segment_intersects_owner?(segment, owner)

          CORRIDOR_DETAIL_FORCED_CELL_SIZE
        end
      end

      def build_supported_input_counts
        counts = {}
        counts[:anchor] = output_anchor_candidates.length if output_anchor_candidates.any?
        boundary_count = protected_regions.count { |region| supported_region?(region) }
        counts[:protected_boundary] = boundary_count if boundary_count.positive?
        detail_count = reference_segments.count do |segment|
          CORRIDOR_DETAIL_ROLES.include?(segment['role'].to_s)
        end
        counts[:corridor_detail] = detail_count if detail_count.positive?
        counts
      end

      def build_skipped_input_counts
        counts = {}
        broad_corridor_count = pressure_regions.count do |region|
          broad_corridor_pressure?(region)
        end
        unsupported_pressure_count = pressure_regions.count do |region|
          unsupported_pressure_primitive?(region)
        end
        unsupported_reference_count = reference_segments.count do |segment|
          unsupported_reference_role?(segment)
        end
        counts[:broad_corridor_pressure] = broad_corridor_count if broad_corridor_count.positive?
        counts[:unsupported_pressure_primitive] = unsupported_pressure_count if
          unsupported_pressure_count.positive?
        counts[:unsupported_reference_role] = unsupported_reference_count if
          unsupported_reference_count.positive?
        counts
      end

      def protected_boundary_intersects_owner?(boundary, owner)
        return false unless terrain_bounds_intersect?(boundary.fetch(:bounds), owner)

        case boundary.fetch(:primitive)
        when 'rectangle'
          boundary.fetch(:edges).any? do |edge_start, edge_end|
            segment_points_intersect_owner?(edge_start, edge_end, owner)
          end
        when 'circle'
          circle_boundary_intersects_owner?(boundary, owner)
        else
          false
        end
      end

      def circle_boundary_intersects_owner?(boundary, owner)
        center_x = boundary.fetch(:center_x)
        center_y = boundary.fetch(:center_y)
        radius = boundary.fetch(:radius)
        closest = [
          center_x.clamp(owner.fetch(:min_x), owner.fetch(:max_x)),
          center_y.clamp(owner.fetch(:min_y), owner.fetch(:max_y))
        ]
        radius_sq = radius * radius
        radius_sq.between?(
          squared_distance([center_x, center_y], closest),
          farthest_distance_sq(center_x, center_y, owner)
        )
      rescue TypeError, KeyError
        false
      end

      def segment_intersects_owner?(segment, owner)
        return false unless terrain_bounds_intersect?(segment.fetch(:bounds), owner)

        segment_points_intersect_owner?(
          segment.fetch(:start),
          segment.fetch(:end),
          owner
        )
      end

      def segment_points_intersect_owner?(start_point, end_point, owner)
        return false unless valid_point_pair?(start_point) && valid_point_pair?(end_point)
        return true if point_intersects_owner?(start_point, owner)
        return true if point_intersects_owner?(end_point, owner)

        rectangle_edges(**owner).any? do |edge_start, edge_end|
          segments_intersect?(start_point, end_point, edge_start, edge_end)
        end
      end

      def rectangle_edges(min_x:, min_y:, max_x:, max_y:)
        [
          [[min_x, min_y], [max_x, min_y]],
          [[max_x, min_y], [max_x, max_y]],
          [[max_x, max_y], [min_x, max_y]],
          [[min_x, max_y], [min_x, min_y]]
        ]
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

      def point_intersects_owner?(point, owner)
        return false unless valid_point_pair?(point)

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

      def farthest_distance_sq(center_x, center_y, bounds)
        farthest_x = [bounds.fetch(:min_x), bounds.fetch(:max_x)].map do |x|
          (x - center_x).abs
        end.max
        farthest_y = [bounds.fetch(:min_y), bounds.fetch(:max_y)].map do |y|
          (y - center_y).abs
        end.max
        (farthest_x * farthest_x) + (farthest_y * farthest_y)
      end

      def squared_distance(first, second)
        dx = first.fetch(0) - second.fetch(0)
        dy = first.fetch(1) - second.fetch(1)
        (dx * dx) + (dy * dy)
      end

      def valid_point_pair?(point)
        point.is_a?(Array) && point.length >= 2
      end

      def shape_payload(entry)
        entry['ownerLocalShape'] || entry['ownerLocalBounds'] || entry['ownerLocalCenterRadius']
      end

      def normalized_forced_anchors
        output_anchor_candidates.filter_map do |anchor|
          point = anchor['ownerLocalPoint']
          next unless valid_point_pair?(point)

          [point.fetch(0), point.fetch(1)]
        rescue KeyError, TypeError
          nil
        end
      end

      def normalized_protected_boundaries
        protected_regions.filter_map do |region|
          case region['primitive']
          when 'rectangle'
            normalized_rectangle_boundary(region)
          when 'circle'
            normalized_circle_boundary(region)
          end
        end
      end

      def normalized_rectangle_boundary(region)
        shape = shape_payload(region)
        return nil unless shape.is_a?(Array) && shape.length == 2

        min, max = shape
        min_x, max_x = [min.fetch(0), max.fetch(0)].minmax
        min_y, max_y = [min.fetch(1), max.fetch(1)].minmax
        {
          primitive: 'rectangle',
          bounds: { min_x: min_x, min_y: min_y, max_x: max_x, max_y: max_y },
          edges: rectangle_edges(min_x: min_x, min_y: min_y, max_x: max_x, max_y: max_y)
        }
      rescue KeyError, TypeError, NoMethodError
        nil
      end

      def normalized_circle_boundary(region)
        shape = shape_payload(region)
        return nil unless shape.is_a?(Array) && shape.length == 3

        center_x, center_y, radius = shape
        {
          primitive: 'circle',
          center_x: center_x,
          center_y: center_y,
          radius: radius,
          bounds: {
            min_x: center_x - radius,
            min_y: center_y - radius,
            max_x: center_x + radius,
            max_y: center_y + radius
          }
        }
      rescue TypeError
        nil
      end

      def normalized_corridor_detail_segments
        reference_segments.filter_map do |segment|
          next unless CORRIDOR_DETAIL_ROLES.include?(segment['role'].to_s)

          normalized_segment(segment['ownerLocalStart'], segment['ownerLocalEnd'])
        end
      end

      def normalized_segment(start_point, end_point)
        return nil unless valid_point_pair?(start_point) && valid_point_pair?(end_point)

        start_pair = [start_point.fetch(0), start_point.fetch(1)]
        end_pair = [end_point.fetch(0), end_point.fetch(1)]
        {
          start: start_pair,
          end: end_pair,
          bounds: {
            min_x: [start_pair.fetch(0), end_pair.fetch(0)].min,
            min_y: [start_pair.fetch(1), end_pair.fetch(1)].min,
            max_x: [start_pair.fetch(0), end_pair.fetch(0)].max,
            max_y: [start_pair.fetch(1), end_pair.fetch(1)].max
          }
        }
      rescue KeyError, TypeError
        nil
      end

      def aggregate_mask_bounds
        bounds = []
        bounds.concat(forced_anchors.map { |point| point_bounds(point) })
        bounds.concat(protected_boundaries.map { |boundary| boundary.fetch(:bounds) })
        bounds.concat(corridor_detail_segments.map { |segment| segment.fetch(:bounds) })
        merge_bounds(bounds)
      end

      def point_bounds(point)
        { min_x: point.fetch(0), min_y: point.fetch(1),
          max_x: point.fetch(0), max_y: point.fetch(1) }
      end

      def merge_bounds(bounds)
        return nil if bounds.empty?

        {
          min_x: bounds.map { |entry| entry.fetch(:min_x) }.min,
          min_y: bounds.map { |entry| entry.fetch(:min_y) }.min,
          max_x: bounds.map { |entry| entry.fetch(:max_x) }.max,
          max_y: bounds.map { |entry| entry.fetch(:max_y) }.max
        }
      end

      def aggregate_bounds_intersect?(owner)
        aggregate_bounds && terrain_bounds_intersect?(aggregate_bounds, owner)
      end

      def terrain_bounds_intersect?(first, second)
        first.fetch(:min_x) <= second.fetch(:max_x) &&
          first.fetch(:max_x) >= second.fetch(:min_x) &&
          first.fetch(:min_y) <= second.fetch(:max_y) &&
          first.fetch(:max_y) >= second.fetch(:min_y)
      end

      def supported_region?(region)
        %w[rectangle circle].include?(region['primitive'])
      end

      def unsupported_reference_role?(segment)
        !CORRIDOR_DETAIL_ROLES.include?(segment['role'].to_s)
      end

      def unsupported_pressure_primitive?(region)
        !%w[rectangle circle corridor].include?(region['primitive'])
      end

      def broad_corridor_pressure?(region)
        region['primitive'] == 'corridor'
      end
    end
  end
end
