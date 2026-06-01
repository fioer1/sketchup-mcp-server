# frozen_string_literal: true

require_relative '../features/terrain_primitive_membership'

module SU_MCP
  module Terrain
    # Compiles oracle semantic primitives into numeric hot-path shape data.
    module TerrainOracleSemanticShape
      TOLERANCE = TerrainPrimitiveMembership::DEFAULT_TOLERANCE

      module_function

      def compile(region)
        case region.fetch('primitive')
        when 'point'
          compile_point(region)
        when 'circle'
          compile_circle(region)
        when 'rectangle'
          compile_rectangle(region)
        else
          raise ArgumentError, "unsupported primitive #{region['primitive'].inspect}"
        end
      end

      def bounds(shape)
        [
          shape.fetch(:min_x),
          shape.fetch(:max_x),
          shape.fetch(:min_y),
          shape.fetch(:max_y)
        ]
      end

      def bounds_contain_xy?(shape, x, y)
        x.between?(shape.fetch(:min_x), shape.fetch(:max_x)) &&
          y.between?(shape.fetch(:min_y), shape.fetch(:max_y))
      end

      def compile_point(region)
        point = region.fetch('ownerLocalPoint').map(&:to_f)
        x = point.fetch(0)
        y = point.fetch(1)
        {
          type: :point,
          x: x,
          y: y,
          min_x: x - TOLERANCE,
          max_x: x + TOLERANCE,
          min_y: y - TOLERANCE,
          max_y: y + TOLERANCE
        }
      end

      def compile_circle(region)
        center_x, center_y, radius = region.fetch('ownerLocalCenterRadius').map(&:to_f)
        radius_with_tolerance = radius + TOLERANCE
        {
          type: :circle,
          x: center_x,
          y: center_y,
          radius_with_tolerance_squared: radius_with_tolerance**2,
          min_x: center_x - radius_with_tolerance,
          max_x: center_x + radius_with_tolerance,
          min_y: center_y - radius_with_tolerance,
          max_y: center_y + radius_with_tolerance
        }
      end

      def compile_rectangle(region)
        rect = TerrainPrimitiveMembership.rectangle_extents(region.fetch('ownerLocalBounds'))
        {
          type: :rectangle,
          min_x: rect.fetch(:min_x) - TOLERANCE,
          max_x: rect.fetch(:max_x) + TOLERANCE,
          min_y: rect.fetch(:min_y) - TOLERANCE,
          max_y: rect.fetch(:max_y) + TOLERANCE
        }
      end
    end
  end
end
