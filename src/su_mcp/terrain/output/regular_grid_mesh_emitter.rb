# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Emits regular and non-patch adaptive terrain faces into SketchUp entities.
    class RegularGridMeshEmitter
      def initialize(derived_output_store:, vertex_projector:)
        @derived_output_store = derived_output_store
        @vertex_projector = vertex_projector
      end

      def emit_faces_via_builder(entities, vertices, columns, rows, ownership)
        unless entities.respond_to?(:build)
          return emit_faces(entities, vertices, columns, rows, ownership)
        end

        entities.build do |builder|
          emit_faces(builder, vertices, columns, rows, ownership)
        end
      end

      def emit_adaptive_faces_via_builder(entities, state, cells)
        return emit_adaptive_faces(entities, state, cells) unless entities.respond_to?(:build)

        entities.build do |builder|
          emit_adaptive_faces(builder, state, cells)
        end
      end

      def emit_cell_window_via_builder(entities, vertices, columns, cell_window, ownership)
        unless entities.respond_to?(:build)
          return emit_cell_window(entities, vertices, columns, cell_window, ownership)
        end

        entities.build do |builder|
          emit_cell_window(builder, vertices, columns, cell_window, ownership)
        end
      end

      def add_derived_face(entities, *points, ownership:, mark_edges: true)
        face = entities.add_face(*points)
        normalize_upward_face!(face)
        derived_output_store.mark_derived(face, ownership: ownership, mark_edges: mark_edges)
      end

      def normalize_upward_face!(face)
        return face unless face.respond_to?(:normal) && face.respond_to?(:reverse!)

        normal = face.normal
        return face unless normal.respond_to?(:z)

        return face unless normal.z.to_f.negative?

        face.reverse!
        face
      end

      def emit_faces(face_target, vertices, columns, rows, ownership)
        each_cell(columns, rows) do |column, row|
          add_cell_triangles(face_target, vertices, column, row, columns, ownership)
        end
      end

      def emit_adaptive_faces(face_target, state, cells)
        cells.each do |cell|
          add_adaptive_cell_triangles(face_target, state, cell)
        end
      end

      def emit_cell_window(face_target, vertices, columns, cell_window, ownership)
        cell_window.each_cell do |column, row|
          add_cell_triangles(face_target, vertices, column, row, columns, ownership)
        end
      end

      def add_adaptive_cell_triangles(entities, state, cell)
        cell.fetch(:emission_triangles).each do |triangle|
          add_derived_face(
            entities,
            *triangle.map do |vertex|
              vertex_projector.adaptive_vertex_for_planned_point(state, vertex)
            end,
            ownership: nil
          )
        end
      end

      def add_cell_triangles(entities, vertices, column, row, columns, ownership)
        lower_left = grid_vertex_at(vertices, column, row, columns)
        lower_right = grid_vertex_at(vertices, column + 1, row, columns)
        upper_left = grid_vertex_at(vertices, column, row + 1, columns)
        upper_right = grid_vertex_at(vertices, column + 1, row + 1, columns)

        add_derived_face(
          entities,
          lower_left,
          lower_right,
          upper_right,
          ownership: face_ownership(ownership, column, row, 0)
        )
        add_derived_face(
          entities,
          lower_left,
          upper_right,
          upper_left,
          ownership: face_ownership(ownership, column, row, 1)
        )
      end

      def each_cell(columns, rows)
        (0...(rows - 1)).each do |row|
          (0...(columns - 1)).each do |column|
            yield column, row
          end
        end
      end

      def grid_vertex_at(vertices, column, row, columns)
        vertices.fetch((row * columns) + column)
      end

      def face_ownership(ownership, column, row, triangle_index)
        ownership.merge(
          column: column,
          row: row,
          triangle_index: triangle_index
        )
      end

      private

      attr_reader :derived_output_store, :vertex_projector
    end
  end
end
