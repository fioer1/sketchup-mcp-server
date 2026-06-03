# frozen_string_literal: true

require_relative '../regions/composed_height_oracle'

module SU_MCP
  module Terrain
    # Projects terrain state sample coordinates into SketchUp-space vertices.
    class TerrainVertexProjector
      def initialize(length_converter:, height_oracle: nil, height_oracle_state: nil)
        @length_converter = length_converter
        @height_oracle = height_oracle
        @height_oracle_state = height_oracle_state
      end

      def vertices_for(state, columns, rows)
        (0...rows).flat_map do |row|
          (0...columns).map do |column|
            vertex_for(state, column, row)
          end
        end
      end

      def vertex_for(state, column, row)
        origin = state.origin
        spacing = state.spacing
        [
          internal_length(origin.fetch('x') + (column * spacing.fetch('x'))),
          internal_length(origin.fetch('y') + (row * spacing.fetch('y'))),
          internal_length(height_at_grid(state, column, row))
        ]
      end

      def adaptive_vertex_for_planned_point(state, point)
        column, row = point
        return adaptive_vertex_at(state, column, row) if column.is_a?(Integer) && row.is_a?(Integer)

        adaptive_center_vertex_at(state, point)
      end

      def state_vertex_at(state, column, row)
        [
          state.origin.fetch('x') + (column * state.spacing.fetch('x')),
          state.origin.fetch('y') + (row * state.spacing.fetch('y')),
          state.origin.fetch('z') + height_at_grid(state, column, row)
        ]
      end

      def internal_length(value)
        length_converter.public_meters_to_internal(value)
      end

      def height_at_grid(state, column, row)
        height_oracle_for(state).height_at_grid(column: column, row: row)
      end

      private

      attr_reader :length_converter, :height_oracle, :height_oracle_state

      def adaptive_vertex_at(state, column, row)
        origin = state.origin
        spacing = state.spacing
        [
          internal_length(origin.fetch('x') + (column * spacing.fetch('x'))),
          internal_length(origin.fetch('y') + (row * spacing.fetch('y'))),
          internal_length(height_at_grid(state, column, row))
        ]
      end

      def adaptive_center_vertex_at(state, center)
        column, row = center
        origin = state.origin
        spacing = state.spacing
        [
          internal_length(origin.fetch('x') + (column * spacing.fetch('x'))),
          internal_length(origin.fetch('y') + (row * spacing.fetch('y'))),
          internal_length(fitted_adaptive_elevation_at(state, column, row))
        ]
      end

      def fitted_adaptive_elevation_at(state, column, row)
        min_column = column.floor
        min_row = row.floor
        max_column = column.ceil
        max_row = row.ceil
        x_ratio = max_column == min_column ? 0.0 : column - min_column
        y_ratio = max_row == min_row ? 0.0 : row - min_row
        z00 = height_at_grid(state, min_column, min_row)
        z10 = height_at_grid(state, max_column, min_row)
        z01 = height_at_grid(state, min_column, max_row)
        z11 = height_at_grid(state, max_column, max_row)
        bottom = z00 + ((z10 - z00) * x_ratio)
        top = z01 + ((z11 - z01) * x_ratio)
        bottom + ((top - bottom) * y_ratio)
      end

      def height_oracle_for(state)
        return height_oracle if height_oracle && state.equal?(height_oracle_state)

        ComposedHeightOracle.build(state: state)
      end
    end
  end
end
