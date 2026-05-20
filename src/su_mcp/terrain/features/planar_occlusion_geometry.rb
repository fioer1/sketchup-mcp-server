# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Pure geometry helpers for planar occlusion clipping of feature-output inputs.
    module PlanarOcclusionGeometry
      module_function

      def entry_contained_by_region?(entry, region)
        if entry.key?('ownerLocalStart') && entry.key?('ownerLocalEnd')
          return segment_contained_by_region?(entry, region)
        end

        shape = entry['ownerLocalShape'] || entry['ownerLocalBounds'] ||
                entry['ownerLocalCenterRadius']
        case entry['primitive']
        when 'rectangle'
          rectangle_contained_by_region?(shape, region)
        when 'circle'
          circle_contained_by_region?(shape, region)
        when 'corridor'
          segment_points_contained_by_region?(shape.fetch('centerline'), region)
        else
          false
        end
      rescue KeyError, TypeError, NoMethodError
        false
      end

      def entry_intersects_region?(entry, region)
        entry_bounds = bounds_for_entry(entry)
        region_bounds = bounds_for_region(region)
        return false unless entry_bounds && region_bounds

        rectangle_bounds_intersect?(entry_bounds, region_bounds)
      end

      def segment_contained_by_region?(segment, region)
        segment_points_contained_by_region?(
          [segment.fetch('ownerLocalStart'), segment.fetch('ownerLocalEnd')],
          region
        )
      end

      def segment_points_contained_by_region?(points, region)
        points.all? { |point| point_contained_by_region?(point, region) }
      end

      def rectangle_contained_by_region?(shape, region)
        min, max = shape
        [[min.fetch(0), min.fetch(1)], [min.fetch(0), max.fetch(1)],
         [max.fetch(0), min.fetch(1)], [max.fetch(0), max.fetch(1)]].all? do |point|
          point_contained_by_region?(point, region)
        end
      end

      def circle_contained_by_region?(shape, region)
        center_x, center_y, radius = shape
        [[center_x - radius, center_y], [center_x + radius, center_y],
         [center_x, center_y - radius], [center_x, center_y + radius]].all? do |point|
          point_contained_by_region?(point, region)
        end
      end

      def point_contained_by_region?(point, region)
        case region.fetch('primitive')
        when 'rectangle'
          min, max = region.fetch('ownerLocalBounds')
          point.fetch(0).between?(*[min.fetch(0), max.fetch(0)].minmax) &&
            point.fetch(1).between?(*[min.fetch(1), max.fetch(1)].minmax)
        when 'circle'
          center_x, center_y, radius = region.fetch('ownerLocalCenterRadius')
          dx = point.fetch(0) - center_x
          dy = point.fetch(1) - center_y
          ((dx * dx) + (dy * dy)) <= radius * radius
        else
          false
        end
      rescue KeyError, TypeError
        false
      end

      def outside_rectangles(source, clip)
        [
          ['left', bounds_hash(source.fetch(:min_x), source.fetch(:min_y),
                               clip.fetch(:min_x), source.fetch(:max_y))],
          ['right', bounds_hash(clip.fetch(:max_x), source.fetch(:min_y),
                                source.fetch(:max_x), source.fetch(:max_y))],
          ['bottom', bounds_hash(clip.fetch(:min_x), source.fetch(:min_y),
                                 clip.fetch(:max_x), clip.fetch(:min_y))],
          ['top', bounds_hash(clip.fetch(:min_x), clip.fetch(:max_y),
                              clip.fetch(:max_x), source.fetch(:max_y))]
        ].select { |_name, bounds| positive_area?(bounds) }
      end

      def outside_segment_intervals(clip_interval)
        [
          [0.0, clip_interval.fetch(0)],
          [clip_interval.fetch(1), 1.0]
        ].select { |start_t, end_t| (end_t - start_t) > 1e-9 }
      end

      def segment_rectangle_clip_interval(start_point, end_point, bounds)
        delta_x = end_point.fetch(0) - start_point.fetch(0)
        delta_y = end_point.fetch(1) - start_point.fetch(1)
        interval = clip_parametric_axis(0.0, 1.0, start_point.fetch(0), delta_x,
                                        bounds.fetch(:min_x), bounds.fetch(:max_x))
        return nil unless interval

        clip_parametric_axis(interval.fetch(0), interval.fetch(1), start_point.fetch(1),
                             delta_y, bounds.fetch(:min_y), bounds.fetch(:max_y))
      end

      def clip_parametric_axis(t_min, t_max, origin, delta, min_value, max_value)
        if delta.abs <= 1e-9
          return origin.between?(min_value, max_value) ? [t_min, t_max] : nil
        end

        first = (min_value - origin) / delta
        second = (max_value - origin) / delta
        axis_min, axis_max = [first, second].minmax
        clipped_min = [t_min, axis_min].max
        clipped_max = [t_max, axis_max].min
        clipped_min <= clipped_max ? [clipped_min, clipped_max] : nil
      end

      def segment_point_at(start_point, end_point, ratio)
        [
          start_point.fetch(0) + ((end_point.fetch(0) - start_point.fetch(0)) * ratio),
          start_point.fetch(1) + ((end_point.fetch(1) - start_point.fetch(1)) * ratio)
        ]
      end

      def bounds_for_entry(entry)
        return bounds_for_points([entry.fetch('ownerLocalStart'), entry.fetch('ownerLocalEnd')]) if
          entry.key?('ownerLocalStart') && entry.key?('ownerLocalEnd')

        shape_bounds_for_entry(entry)
      rescue KeyError, TypeError, NoMethodError
        nil
      end

      def shape_bounds_for_entry(entry)
        case entry['primitive']
        when 'rectangle'
          rectangle_bounds(entry['ownerLocalShape'] || entry['ownerLocalBounds'])
        when 'circle'
          circle_bounds(entry['ownerLocalShape'] || entry['ownerLocalCenterRadius'])
        when 'corridor'
          bounds_for_points(entry.fetch('ownerLocalShape').fetch('centerline'))
        end
      end

      def bounds_for_region(region)
        case region.fetch('primitive')
        when 'rectangle'
          rectangle_bounds(region.fetch('ownerLocalBounds'))
        when 'circle'
          circle_bounds(region.fetch('ownerLocalCenterRadius'))
        end
      rescue KeyError, TypeError
        nil
      end

      def rectangle_bounds(shape)
        min, max = shape
        bounds_hash(
          [min.fetch(0), max.fetch(0)].min,
          [min.fetch(1), max.fetch(1)].min,
          [min.fetch(0), max.fetch(0)].max,
          [min.fetch(1), max.fetch(1)].max
        )
      rescue KeyError, TypeError, NoMethodError
        nil
      end

      def circle_bounds(shape)
        center_x, center_y, radius = shape
        bounds_hash(center_x - radius, center_y - radius, center_x + radius, center_y + radius)
      rescue TypeError
        nil
      end

      def bounds_for_points(points)
        bounds_hash(
          points.map { |point| point.fetch(0) }.min,
          points.map { |point| point.fetch(1) }.min,
          points.map { |point| point.fetch(0) }.max,
          points.map { |point| point.fetch(1) }.max
        )
      rescue KeyError, TypeError, NoMethodError
        nil
      end

      def intersection_bounds(first, second)
        return nil unless first && second && rectangle_bounds_intersect?(first, second)

        bounds_hash(
          [first.fetch(:min_x), second.fetch(:min_x)].max,
          [first.fetch(:min_y), second.fetch(:min_y)].max,
          [first.fetch(:max_x), second.fetch(:max_x)].min,
          [first.fetch(:max_y), second.fetch(:max_y)].min
        )
      end

      def rectangle_bounds_intersect?(first, second)
        first.fetch(:min_x) <= second.fetch(:max_x) &&
          first.fetch(:max_x) >= second.fetch(:min_x) &&
          first.fetch(:min_y) <= second.fetch(:max_y) &&
          first.fetch(:max_y) >= second.fetch(:min_y)
      end

      def positive_area?(bounds)
        bounds.fetch(:max_x) - bounds.fetch(:min_x) > 1e-9 &&
          bounds.fetch(:max_y) - bounds.fetch(:min_y) > 1e-9
      end

      def bounds_hash(min_x, min_y, max_x, max_y)
        { min_x: min_x, min_y: min_y, max_x: max_x, max_y: max_y }
      end

      def bounds_to_shape(bounds)
        [
          [bounds.fetch(:min_x), bounds.fetch(:min_y)],
          [bounds.fetch(:max_x), bounds.fetch(:max_y)]
        ]
      end
    end
  end
end
