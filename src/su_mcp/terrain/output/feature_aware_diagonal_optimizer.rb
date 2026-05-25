# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Pure deterministic optimizer for rectangular adaptive cell diagonals.
    class FeatureAwareDiagonalOptimizer
      DEFAULT_CONFIG = {
        residual_epsilon: 1e-6,
        adoption_residual_improvement: 0.01,
        timing_regression_percent: 25.0,
        seam_adjacent_dihedral_regression: 0.05,
        feature_check_budget: 256
      }.freeze

      def initialize(state:, context: nil, config: DEFAULT_CONFIG)
        @state = state
        @context = context
        @config = DEFAULT_CONFIG.merge(config)
        @elevations = state.elevations
        @column_count = state.dimensions.fetch('columns')
      end

      def optimize(cell:, boundary_vertices:)
        baseline = baseline_triangles(boundary_vertices)
        return fallback(:unsupported_geometry, baseline) unless boundary_vertices.length == 4

        alternate = alternate_triangles(boundary_vertices)
        safety = candidate_safety(cell)
        safety_choice = safety_choice(safety, baseline, alternate)
        return safety_choice if safety_choice

        baseline_planes = planes_for(baseline)
        alternate_planes = planes_for(alternate)
        residuals = residuals_for(cell, baseline_planes, alternate_planes)
        sample_count = residuals.fetch(:sample_count)
        return fallback(:no_metric_samples, baseline, sample_count: 0) if sample_count.zero?

        baseline_residual = residuals.fetch(:baseline)
        alternate_residual = residuals.fetch(:alternate)
        improvement = residual_improvement(baseline_residual, alternate_residual)
        if improvement > config.fetch(:residual_epsilon)
          decision(
            selected: :alternate,
            reason: :residual,
            triangles: alternate,
            baseline_residual: baseline_residual,
            alternate_residual: alternate_residual,
            residual_improvement: improvement,
            sample_count: sample_count
          )
        else
          decision(
            selected: :baseline,
            reason: :baseline_tie,
            triangles: baseline,
            baseline_residual: baseline_residual,
            alternate_residual: alternate_residual,
            residual_improvement: improvement,
            sample_count: sample_count
          )
        end
      end

      private

      attr_reader :state, :context, :config, :elevations, :column_count

      def baseline_triangles(boundary_vertices)
        [
          [boundary_vertices.fetch(0), boundary_vertices.fetch(1), boundary_vertices.fetch(2)],
          [boundary_vertices.fetch(0), boundary_vertices.fetch(2), boundary_vertices.fetch(3)]
        ]
      end

      def alternate_triangles(boundary_vertices)
        [
          [boundary_vertices.fetch(0), boundary_vertices.fetch(1), boundary_vertices.fetch(3)],
          [boundary_vertices.fetch(1), boundary_vertices.fetch(2), boundary_vertices.fetch(3)]
        ]
      end

      def candidate_safety(cell)
        return context.candidate_safety if context.respond_to?(:candidate_safety)

        return { baseline: :safe, alternate: :safe } unless context.respond_to?(:safety_for)

        context.safety_for(cell).fetch(:candidate_safety)
      end

      def safety_choice(safety, baseline, alternate)
        baseline_safe = safety.fetch(:baseline, :safe) == :safe
        alternate_safe = safety.fetch(:alternate, :safe) == :safe
        return nil if baseline_safe && alternate_safe

        if baseline_safe && !alternate_safe
          return decision(selected: :baseline, reason: :safety_veto, triangles: baseline)
        end
        if alternate_safe && !baseline_safe
          return decision(selected: :alternate, reason: :safety_veto, triangles: alternate)
        end

        decision(selected: :baseline, reason: :ambiguous_safety, triangles: baseline)
      end

      def residuals_for(cell, baseline_planes, alternate_planes)
        min_column = cell.fetch(:min_column)
        max_column = cell.fetch(:max_column)
        min_row = cell.fetch(:min_row)
        max_row = cell.fetch(:max_row)
        sample_count = 0
        baseline_residual = 0.0
        alternate_residual = 0.0
        (min_row..max_row).each do |row|
          (min_column..max_column).each do |column|
            next if corner_sample?(column, row, min_column, max_column, min_row, max_row)

            actual = height_at(column, row)
            baseline_plane = baseline_planes.fetch(baseline_triangle_index(cell, column, row))
            alternate_plane = alternate_planes.fetch(alternate_triangle_index(cell, column, row))
            baseline_residual += (actual - plane_height(baseline_plane, column, row)).abs
            alternate_residual += (actual - plane_height(alternate_plane, column, row)).abs
            sample_count += 1
          end
        end
        { sample_count: sample_count, baseline: baseline_residual, alternate: alternate_residual }
      end

      def residual_improvement(baseline_residual, alternate_residual)
        [baseline_residual - alternate_residual, 0.0].max
      end

      def height_at(column, row)
        elevations.fetch((row * column_count) + column)
      end

      def planes_for(triangles)
        triangles.map { |triangle| plane_coefficients(triangle) }
      end

      def plane_height(plane, column, row)
        a, b, c, d = plane
        -((a * column) + (b * row) + d) / c.to_f
      end

      def plane_coefficients(triangle)
        first, second, third = triangle.map { |vertex| vertex_with_height(vertex) }
        a = coefficient_a(first, second, third)
        b = coefficient_b(first, second, third)
        c = coefficient_c(first, second, third)
        d = -((a * first.fetch(:x)) + (b * first.fetch(:y)) + (c * first.fetch(:z)))
        [a, b, c, d]
      end

      def coefficient_a(first, second, third)
        ((second.fetch(:y) - first.fetch(:y)) * (third.fetch(:z) - first.fetch(:z))) -
          ((second.fetch(:z) - first.fetch(:z)) * (third.fetch(:y) - first.fetch(:y)))
      end

      def coefficient_b(first, second, third)
        ((second.fetch(:z) - first.fetch(:z)) * (third.fetch(:x) - first.fetch(:x))) -
          ((second.fetch(:x) - first.fetch(:x)) * (third.fetch(:z) - first.fetch(:z)))
      end

      def coefficient_c(first, second, third)
        ((second.fetch(:x) - first.fetch(:x)) * (third.fetch(:y) - first.fetch(:y))) -
          ((second.fetch(:y) - first.fetch(:y)) * (third.fetch(:x) - first.fetch(:x)))
      end

      def vertex_with_height(vertex)
        x = vertex.fetch(0)
        y = vertex.fetch(1)
        { x: x, y: y, z: height_at(x, y) }
      end

      def corner_sample?(column, row, min_column, max_column, min_row, max_row)
        (column == min_column || column == max_column) &&
          (row == min_row || row == max_row)
      end

      def baseline_triangle_index(cell, column, row)
        min_column = cell.fetch(:min_column)
        min_row = cell.fetch(:min_row)
        x_span = cell.fetch(:max_column) - min_column
        y_span = cell.fetch(:max_row) - min_row
        below_or_on_diagonal =
          ((row - min_row) * x_span) <= ((column - min_column) * y_span)
        below_or_on_diagonal ? 0 : 1
      end

      def alternate_triangle_index(cell, column, row)
        min_row = cell.fetch(:min_row)
        max_column = cell.fetch(:max_column)
        x_span = max_column - cell.fetch(:min_column)
        y_span = cell.fetch(:max_row) - min_row
        below_or_on_diagonal =
          ((row - min_row) * x_span) <= ((max_column - column) * y_span)
        below_or_on_diagonal ? 0 : 1
      end

      def fallback(reason, triangles, sample_count: nil)
        decision(
          selected: :baseline,
          reason: reason,
          triangles: triangles,
          sample_count: sample_count
        )
      end

      def decision(fields)
        {
          selected: fields.fetch(:selected),
          reason: fields.fetch(:reason),
          triangles: fields.fetch(:triangles),
          baseline_residual: fields.fetch(:baseline_residual, nil),
          alternate_residual: fields.fetch(:alternate_residual, nil),
          residual_improvement: fields.fetch(:residual_improvement, 0.0),
          sample_count: fields.fetch(:sample_count, nil)
        }.compact
      end
    end
  end
end
