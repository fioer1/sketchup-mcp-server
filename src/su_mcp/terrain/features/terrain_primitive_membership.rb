# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Point membership classification for normalized terrain feature primitives.
    module TerrainPrimitiveMembership
      DEFAULT_TOLERANCE = 1e-9

      module_function

      def classify(point:, primitive:, tolerance: DEFAULT_TOLERANCE)
        normalized = normalize_primitive(primitive)
        case normalized.fetch('primitive')
        when 'point'
          classify_point(point, normalized.fetch('ownerLocalPoint'), tolerance)
        when 'circle'
          classify_circle(point, normalized.fetch('ownerLocalCenterRadius'), tolerance)
        when 'rectangle'
          classify_rectangle(point, normalized.fetch('ownerLocalBounds'), tolerance)
        else
          raise ArgumentError, "unsupported primitive #{normalized['primitive'].inspect}"
        end
      end

      def classify_point(point, shape, tolerance)
        x, y = point_pair(point)
        shape_x, shape_y = shape.map(&:to_f)
        distance = Math.sqrt(((x - shape_x)**2) + ((y - shape_y)**2))
        distance <= tolerance.to_f ? :inside : :outside
      end

      def classify_circle(point, shape, tolerance)
        x, y = point_pair(point)
        center_x, center_y, radius = shape.map(&:to_f)
        distance = Math.sqrt(((x - center_x)**2) + ((y - center_y)**2))
        return :boundary if (distance - radius).abs <= tolerance.to_f
        return :inside if distance < radius

        :outside
      end

      def classify_rectangle(point, bounds, tolerance)
        x, y = point_pair(point)
        rect = rectangle_extents(bounds)
        return :inside if rectangle_interior?(x, y, rect, tolerance)
        return :boundary if rectangle_boundary?(x, y, rect, tolerance)
        return :inside if x.between?(rect.fetch(:min_x), rect.fetch(:max_x)) &&
                          y.between?(rect.fetch(:min_y), rect.fetch(:max_y))

        :outside
      end

      def rectangle_extents(bounds)
        min, max = bounds
        min_x, max_x = [value_at(min, 0), value_at(max, 0)].map(&:to_f).minmax
        min_y, max_y = [value_at(min, 1), value_at(max, 1)].map(&:to_f).minmax
        { min_x: min_x, max_x: max_x, min_y: min_y, max_y: max_y }
      end

      def rectangle_interior?(x, y, rect, tolerance)
        tol = tolerance.to_f
        x.between?(rect.fetch(:min_x) + tol, rect.fetch(:max_x) - tol) &&
          y.between?(rect.fetch(:min_y) + tol, rect.fetch(:max_y) - tol)
      end

      def rectangle_boundary?(x, y, rect, tolerance)
        tol = tolerance.to_f
        near_x = x.between?(rect.fetch(:min_x) - tol, rect.fetch(:max_x) + tol)
        near_y = y.between?(rect.fetch(:min_y) - tol, rect.fetch(:max_y) + tol)
        on_vertical = near_y && on_axis_edge?(x, rect.fetch(:min_x), rect.fetch(:max_x), tol)
        on_horizontal = near_x && on_axis_edge?(y, rect.fetch(:min_y), rect.fetch(:max_y), tol)
        on_vertical || on_horizontal
      end

      def on_axis_edge?(value, min, max, tolerance)
        (value - min).abs <= tolerance || (value - max).abs <= tolerance
      end

      def normalize_primitive(primitive)
        primitive.transform_keys(&:to_s)
      end

      def point_pair(point)
        return [point.fetch(0).to_f, point.fetch(1).to_f] if point.is_a?(Array)

        [point.fetch('x') { point.fetch(:x) }.to_f,
         point.fetch('y') { point.fetch(:y) }.to_f]
      end

      def value_at(point, index)
        point.fetch(index)
      end
    end
  end
end
