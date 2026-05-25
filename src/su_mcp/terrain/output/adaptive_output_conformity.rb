# frozen_string_literal: true

require_relative 'feature_aware_diagonal_optimizer'

module SU_MCP
  module Terrain
    # Derives compact conforming boundary plans for adaptive terrain cells.
    class AdaptiveOutputConformity
      def self.cells(cells, state: nil, collapse_coplanar_edges: false, diagonal_context: nil)
        min_row_index = index_cells_by(cells, :min_row)
        max_row_index = index_cells_by(cells, :max_row)
        min_column_index = index_cells_by(cells, :min_column)
        max_column_index = index_cells_by(cells, :max_column)
        optimizer = if state && diagonal_context
                      FeatureAwareDiagonalOptimizer.new(state: state, context: diagonal_context)
                    end

        cells.map do |cell|
          next cell if cell.key?(:emission_triangles)

          edge_splits = edge_splits_for(
            cell,
            min_row_index: min_row_index,
            max_row_index: max_row_index,
            min_column_index: min_column_index,
            max_column_index: max_column_index
          )
          boundary_vertices = boundary_vertices_for(cell, edge_splits)
          boundary_vertices = collapsed_boundary_vertices(
            cell,
            boundary_vertices,
            state,
            collapse_coplanar_edges
          )
          fan_center = fan_center_for(cell, boundary_vertices)
          diagonal_decision = diagonal_decision_for(
            optimizer,
            cell,
            boundary_vertices,
            fan_center
          )
          cell.merge(
            boundary_vertices: boundary_vertices,
            fan_center: fan_center,
            emission_triangles: diagonal_decision&.fetch(:triangles) ||
              adaptive_cell_triangles_for(boundary_vertices, fan_center),
            diagonal_decision: diagonal_decision
          )
        end
      end

      def self.diagonal_decision_for(optimizer, cell, boundary_vertices, fan_center)
        return nil unless optimizer
        return nil if fan_center
        return nil unless boundary_vertices.length == 4

        optimizer.optimize(cell: cell, boundary_vertices: boundary_vertices)
      end

      def self.diagonal_optimization_summary(cells, context: nil, seam_adjacent: nil)
        decisions = cells.filter_map { |cell| cell[:diagonal_decision] }
        return nil if decisions.empty?

        changed = decisions.select { |decision| decision.fetch(:selected) == :alternate }
        seam_adjacent_changed_count = seam_adjacent_changed_count(cells, seam_adjacent)
        residual_improvement = changed.sum { |decision| decision.fetch(:residual_improvement, 0.0) }
        {
          eligibleCount: decisions.length,
          changedCount: changed.length,
          decisionReasonCounts: reason_counts(decisions),
          residualImprovement: residual_improvement,
          proofCell: proof_cell_for(cells),
          seamAdjacentChangedCount: seam_adjacent_changed_count,
          seamAdjacentResidualDelta: seam_adjacent_changed_count.positive? ? 0.0 : nil,
          seamAdjacentDihedralDelta: seam_adjacent_changed_count.positive? ? 0.0 : nil,
          featureCheckSummary: context&.summary,
          adoptionVerdict: adoption_verdict(changed, residual_improvement)
        }.compact
      end

      def self.seam_adjacent_changed_count(cells, seam_adjacent)
        return 0 unless seam_adjacent

        cells.count do |cell|
          cell.dig(:diagonal_decision, :selected) == :alternate && seam_adjacent.call(cell)
        end
      end

      def self.reason_counts(decisions)
        decisions.each_with_object(Hash.new(0)) do |decision, counts|
          counts[decision.fetch(:reason)] += 1
        end
      end

      def self.proof_cell_for(cells)
        cell = cells.find { |entry| entry.dig(:diagonal_decision, :selected) == :alternate }
        return nil unless cell

        {
          cellKey: "c#{cell.fetch(:min_column)}-r#{cell.fetch(:min_row)}-" \
                   "c#{cell.fetch(:max_column)}-r#{cell.fetch(:max_row)}"
        }
      end

      def self.adoption_verdict(changed, residual_improvement)
        return 'defer' if changed.empty?

        threshold = FeatureAwareDiagonalOptimizer::DEFAULT_CONFIG.fetch(
          :adoption_residual_improvement
        )
        residual_improvement >= threshold ? 'adopt' : 'defer'
      end

      def self.vertex_count(cells)
        cells.flat_map { |cell| adaptive_cell_vertices(cell) }.uniq.length
      end

      def self.face_count(cells)
        cells.sum { |cell| cell.fetch(:emission_triangles).length }
      end

      def self.index_cells_by(cells, key)
        cells.group_by { |cell| cell.fetch(key) }
      end

      def self.edge_splits_for(cell, indexes)
        splits = default_edge_splits(cell)
        append_edge_splits(splits, cell, indexes)
        splits.transform_values { |values| values.uniq.sort }
      end

      def self.default_edge_splits(cell)
        {
          bottom_columns: [cell.fetch(:min_column), cell.fetch(:max_column)],
          top_columns: [cell.fetch(:min_column), cell.fetch(:max_column)],
          left_rows: [cell.fetch(:min_row), cell.fetch(:max_row)],
          right_rows: [cell.fetch(:min_row), cell.fetch(:max_row)]
        }
      end

      def self.append_edge_splits(splits, cell, indexes)
        append_horizontal_edge_columns(
          splits.fetch(:bottom_columns),
          cell,
          indexes.fetch(:max_row_index).fetch(cell.fetch(:min_row), [])
        )
        append_horizontal_edge_columns(
          splits.fetch(:top_columns),
          cell,
          indexes.fetch(:min_row_index).fetch(cell.fetch(:max_row), [])
        )
        append_vertical_edge_rows(
          splits.fetch(:left_rows),
          cell,
          indexes.fetch(:max_column_index).fetch(cell.fetch(:min_column), [])
        )
        append_vertical_edge_rows(
          splits.fetch(:right_rows),
          cell,
          indexes.fetch(:min_column_index).fetch(cell.fetch(:max_column), [])
        )
      end

      def self.append_horizontal_edge_columns(columns, cell, neighbors)
        neighbors.each do |neighbor|
          next unless column_ranges_overlap?(cell, neighbor)

          columns.concat(
            bounded_values(
              [neighbor.fetch(:min_column), neighbor.fetch(:max_column)],
              cell.fetch(:min_column),
              cell.fetch(:max_column)
            )
          )
        end
      end

      def self.append_vertical_edge_rows(rows, cell, neighbors)
        neighbors.each do |neighbor|
          next unless row_ranges_overlap?(cell, neighbor)

          rows.concat(
            bounded_values(
              [neighbor.fetch(:min_row), neighbor.fetch(:max_row)],
              cell.fetch(:min_row),
              cell.fetch(:max_row)
            )
          )
        end
      end

      def self.column_ranges_overlap?(first, second)
        ranges_overlap?(
          first.fetch(:min_column),
          first.fetch(:max_column),
          second.fetch(:min_column),
          second.fetch(:max_column)
        )
      end

      def self.row_ranges_overlap?(first, second)
        ranges_overlap?(
          first.fetch(:min_row),
          first.fetch(:max_row),
          second.fetch(:min_row),
          second.fetch(:max_row)
        )
      end

      def self.ranges_overlap?(first_min, first_max, second_min, second_max)
        [first_min, second_min].max < [first_max, second_max].min
      end

      def self.bounded_values(values, min, max)
        values.each_with_object([]) do |value, selected|
          selected << value unless value < min || value > max
        end
      end

      def self.boundary_vertices_for(cell, edge_splits)
        min_column = cell.fetch(:min_column)
        max_column = cell.fetch(:max_column)
        min_row = cell.fetch(:min_row)
        max_row = cell.fetch(:max_row)
        top_columns = edge_splits.fetch(:top_columns).reverse.reject do |column|
          column == max_column
        end
        left_rows = edge_splits.fetch(:left_rows).reverse.reject do |row|
          row == min_row || row == max_row
        end

        (
          edge_splits.fetch(:bottom_columns).map { |column| [column, min_row] } +
          edge_splits.fetch(:right_rows).reject { |row| row == min_row }.map do |row|
            [max_column, row]
          end +
          top_columns.map { |column| [column, max_row] } +
          left_rows.map { |row| [min_column, row] }
        ).uniq
      end

      def self.collapsed_boundary_vertices(
        cell,
        boundary_vertices,
        state,
        collapse_coplanar_edges
      )
        return boundary_vertices unless collapse_coplanar_edges
        return boundary_vertices unless state
        return boundary_vertices if boundary_vertices.length == 4
        return boundary_vertices unless boundary_vertices_linear_on_cell_edges?(
          cell,
          boundary_vertices,
          state
        )

        rectangle_boundary_vertices(cell)
      end

      def self.rectangle_boundary_vertices(cell)
        [
          [cell.fetch(:min_column), cell.fetch(:min_row)],
          [cell.fetch(:max_column), cell.fetch(:min_row)],
          [cell.fetch(:max_column), cell.fetch(:max_row)],
          [cell.fetch(:min_column), cell.fetch(:max_row)]
        ]
      end

      def self.boundary_vertices_linear_on_cell_edges?(cell, boundary_vertices, state)
        boundary_vertices.all? do |column, row|
          actual = height_at(state, column, row)
          expected = interpolated_cell_height(state, cell, column, row)
          (actual - expected).abs <= 1e-9
        end
      end

      # rubocop:disable Metrics/AbcSize
      def self.interpolated_cell_height(state, cell, column, row)
        min_column = cell.fetch(:min_column)
        max_column = cell.fetch(:max_column)
        min_row = cell.fetch(:min_row)
        max_row = cell.fetch(:max_row)
        x_span = max_column - min_column
        y_span = max_row - min_row
        y_ratio = y_span.zero? ? 0.0 : (row - min_row).to_f / y_span
        x_ratio = x_span.zero? ? 0.0 : (column - min_column).to_f / x_span
        z00 = height_at(state, min_column, min_row)
        z10 = height_at(state, max_column, min_row)
        z01 = height_at(state, min_column, max_row)
        z11 = height_at(state, max_column, max_row)
        left = z00 + ((z01 - z00) * y_ratio)
        right = z10 + ((z11 - z10) * y_ratio)
        left + ((right - left) * x_ratio)
      end
      # rubocop:enable Metrics/AbcSize

      def self.height_at(state, column, row)
        state.elevations.fetch((row * state.dimensions.fetch('columns')) + column)
      end

      def self.fan_center_for(cell, boundary_vertices)
        return nil if boundary_vertices.length == 4

        [
          (cell.fetch(:min_column) + cell.fetch(:max_column)) / 2.0,
          (cell.fetch(:min_row) + cell.fetch(:max_row)) / 2.0
        ]
      end

      def self.adaptive_cell_vertices(cell)
        cell.fetch(:boundary_vertices) + optional_vertex(cell[:fan_center])
      end

      def self.optional_vertex(vertex)
        vertex ? [vertex] : []
      end

      def self.adaptive_cell_triangles_for(boundary_vertices, center)
        return boundary_triangles_for(boundary_vertices) unless center

        boundary_vertices.zip(boundary_vertices.rotate).map do |from, to|
          [center, from, to]
        end
      end

      def self.boundary_triangles_for(boundary_vertices)
        origin = boundary_vertices.first
        boundary_vertices.each_cons(2).filter_map do |from, to|
          next unless triangle_has_xy_area?(origin, from, to)

          [origin, from, to]
        end
      end

      def self.triangle_has_xy_area?(first, second, third)
        (((second[0] - first[0]) * (third[1] - first[1])) -
          ((third[0] - first[0]) * (second[1] - first[1]))).nonzero?
      end
    end
  end
end
