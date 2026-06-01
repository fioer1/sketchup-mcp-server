# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Deterministic z = ax + by + c plane helper for terrain planar controls.
    class PlanarHeightModel
      GEOMETRY_TOLERANCE = 1e-9

      attr_reader :a, :b, :c

      def self.fit(controls)
        normalized = normalize_controls(controls)
        unique = unique_controls_for_fit(normalized)
        return nil if unique.length < 3
        return nil if collinear?(unique)

        matrix = normal_equation_matrix(unique)
        vector = normal_equation_vector(unique)
        coefficients = solve_3x3(matrix, vector)
        return nil unless coefficients&.all?(&:finite?)

        new(a: coefficients[0], b: coefficients[1], c: coefficients[2])
      end

      def self.normalize_controls(controls)
        Array(controls).map do |control|
          point = control.fetch('point') { control.fetch(:point) }
          {
            'x' => point.fetch('x') { point.fetch(:x) }.to_f,
            'y' => point.fetch('y') { point.fetch(:y) }.to_f,
            'z' => point.fetch('z') { point.fetch(:z) }.to_f
          }
        end
      end

      def self.unique_controls_for_fit(controls)
        controls.group_by { |control| [control.fetch('x'), control.fetch('y')] }
                .values
                .map(&:first)
      end

      def self.collinear?(controls)
        controls.combination(3).none? do |first, second, third|
          triangle_area_twice(first, second, third).abs > GEOMETRY_TOLERANCE
        end
      end

      def self.triangle_area_twice(first, second, third)
        ((second.fetch('x') - first.fetch('x')) * (third.fetch('y') - first.fetch('y'))) -
          ((second.fetch('y') - first.fetch('y')) * (third.fetch('x') - first.fetch('x')))
      end

      def self.normal_equation_matrix(controls)
        sx = controls.sum { |control| control.fetch('x') }
        sy = controls.sum { |control| control.fetch('y') }
        sxx = controls.sum { |control| control.fetch('x')**2 }
        syy = controls.sum { |control| control.fetch('y')**2 }
        sxy = controls.sum { |control| control.fetch('x') * control.fetch('y') }
        [[sxx, sxy, sx], [sxy, syy, sy], [sx, sy, controls.length.to_f]]
      end

      def self.normal_equation_vector(controls)
        [
          controls.sum { |control| control.fetch('x') * control.fetch('z') },
          controls.sum { |control| control.fetch('y') * control.fetch('z') },
          controls.sum { |control| control.fetch('z') }
        ]
      end

      def self.solve_3x3(matrix, vector)
        determinant = det3(matrix)
        return nil if determinant.abs <= GEOMETRY_TOLERANCE

        (0...3).map do |column|
          det3(replace_column(matrix, vector, column)) / determinant
        end
      end

      def self.det3(matrix)
        a, b, c = matrix
        (a[0] * ((b[1] * c[2]) - (b[2] * c[1]))) -
          (a[1] * ((b[0] * c[2]) - (b[2] * c[0]))) +
          (a[2] * ((b[0] * c[1]) - (b[1] * c[0])))
      end

      def self.replace_column(matrix, vector, column)
        matrix.map.with_index do |row, index|
          row.each_with_index.map do |value, row_column|
            row_column == column ? vector[index] : value
          end
        end
      end

      def initialize(values = nil, **keywords)
        coefficients = values || keywords
        @a = coefficients.fetch(:a)
        @b = coefficients.fetch(:b)
        @c = coefficients.fetch(:c)
      end

      def height_at(point)
        x = point.fetch('x') { point.fetch(:x) }.to_f
        y = point.fetch('y') { point.fetch(:y) }.to_f
        (a * x) + (b * y) + c
      end

      def to_h
        { a: a, b: b, c: c }
      end
    end
  end
end
