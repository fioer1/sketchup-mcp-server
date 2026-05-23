# frozen_string_literal: true

module SU_MCP
  module Semantic
    # Evaluates repeated internal-unit surface frames from a prepared semantic sampling context.
    class SurfaceFrameEvaluator
      NORMAL_TOLERANCE = 0.001

      def frame_from_context(context:, x_value:, y_value:)
        hits = context.fetch(:face_entries).filter_map do |face_entry|
          sample_face(face_entry, x_value: x_value, y_value: y_value)
        end
        return refused('surface_frame_miss') if hits.empty?

        build_frame(hits.max_by { |hit| hit.fetch(:origin)[2] })
      end

      private

      def sample_face(face_entry, x_value:, y_value:)
        surface = face_entry[:surface]
        if surface
          return sample_fake_surface(
            surface,
            face_entry,
            x_value: x_value,
            y_value: y_value
          )
        end

        sample_runtime_face(face_entry, x_value: x_value, y_value: y_value)
      end

      # rubocop:disable Metrics/AbcSize
      def sample_fake_surface(surface, face_entry, x_value:, y_value:)
        local_x, local_y, = inverse_transform_components(
          x_value,
          y_value,
          0.0,
          Array(face_entry[:transform_chain])
        )
        return nil unless local_x.between?(surface.fetch(:x_range).first,
                                           surface.fetch(:x_range).last)
        return nil unless local_y.between?(surface.fetch(:y_range).first,
                                           surface.fetch(:y_range).last)

        slope_x = surface.fetch(:slope_x, 0.0).to_f
        slope_y = surface.fetch(:slope_y, 0.0).to_f
        local_z = surface.fetch(:z).to_f +
                  (slope_x * (local_x - surface.fetch(:x_range).first)) +
                  (slope_y * (local_y - surface.fetch(:y_range).first))
        world_x, world_y, world_z = apply_transform_components(
          local_x,
          local_y,
          local_z,
          Array(face_entry[:transform_chain])
        )
        {
          origin: [world_x, world_y, world_z],
          normal: normalize([-slope_x, -slope_y, 1.0])
        }
      end
      # rubocop:enable Metrics/AbcSize

      def sample_runtime_face(face_entry, x_value:, y_value:)
        plane = face_entry[:world_plane]
        world_point = runtime_world_point(plane, x_value: x_value, y_value: y_value)
        return nil unless world_point
        return nil unless inside_bounds?(x_value, y_value, face_entry[:world_xy_bounds])

        local_point = world_to_local_point(world_point, Array(face_entry[:transform_chain]))
        return nil unless point_on_face?(face_entry[:face], local_point)

        {
          origin: [world_point.x.to_f, world_point.y.to_f, world_point.z.to_f],
          normal: normalize(plane.first(3))
        }
      end

      def runtime_world_point(plane, x_value:, y_value:)
        return nil unless plane

        a_value, b_value, c_value, d_value = plane
        return nil if c_value.to_f.abs <= NORMAL_TOLERANCE

        z_value = -((a_value.to_f * x_value.to_f) + (b_value.to_f * y_value.to_f) + d_value.to_f) /
                  c_value.to_f
        point(x_value, y_value, z_value)
      end

      def inside_bounds?(x_value, y_value, bounds)
        return true unless bounds

        x_value.to_f.between?(bounds[:min_x], bounds[:max_x]) &&
          y_value.to_f.between?(bounds[:min_y], bounds[:max_y])
      end

      def build_frame(hit)
        up_axis = upward(hit.fetch(:normal))
        x_axis = projected_model_x(up_axis)
        return refused('degenerate_surface_frame') if x_axis.nil?

        {
          outcome: 'ready',
          frame: {
            origin: hit.fetch(:origin),
            x_axis: x_axis,
            y_axis: normalize(cross(up_axis, x_axis)),
            up_axis: up_axis
          }
        }
      end

      def refused(code)
        {
          outcome: 'refused',
          refusal: {
            code: code,
            details: { section: 'hosting' }
          }
        }
      end

      def projected_model_x(up_axis)
        x_axis = cross([0.0, 1.0, 0.0], up_axis)
        return nil if magnitude(x_axis) <= NORMAL_TOLERANCE

        normalize(x_axis)
      end

      def upward(vector)
        normalized = normalize(vector)
        normalized[2].negative? ? normalized.map(&:-@) : normalized
      end

      def normalize(vector)
        length = magnitude(vector)
        return [0.0, 0.0, 1.0] if length.zero?

        vector.map { |component| component.to_f / length }
      end

      def magnitude(vector)
        Math.sqrt(vector.sum { |component| component.to_f * component.to_f })
      end

      def cross(first, second)
        [
          (first[1] * second[2]) - (first[2] * second[1]),
          (first[2] * second[0]) - (first[0] * second[2]),
          (first[0] * second[1]) - (first[1] * second[0])
        ]
      end

      def apply_transform_components(x_value, y_value, z_value, transform_chain)
        transform_chain.reduce([x_value, y_value, z_value]) do |components, transformation|
          next components unless transformation.respond_to?(:apply)

          transformation.apply(*components)
        end
      end

      def inverse_transform_components(x_value, y_value, z_value, transform_chain)
        transform_chain.reverse.reduce([x_value, y_value, z_value]) do |components, transformation|
          next components unless transformation.respond_to?(:inverse_apply)

          transformation.inverse_apply(*components)
        end
      end

      def world_to_local_point(world_point, transform_chain)
        transform_chain.reverse.reduce(world_point) do |point_value, transformation|
          if transformation.respond_to?(:inverse) && point_value.respond_to?(:transform)
            point_value.transform(transformation.inverse)
          elsif transformation.respond_to?(:inverse_apply)
            x_value, y_value, z_value = transformation.inverse_apply(
              point_value.x,
              point_value.y,
              point_value.z
            )
            point(x_value, y_value, z_value)
          else
            point_value
          end
        end
      end

      def point(x_value, y_value, z_value)
        geom_point = Geom::Point3d.new(x_value.to_f, y_value.to_f, z_value.to_f)
        return geom_point if point_matches?(geom_point, x_value, y_value, z_value)

        Struct.new(:x, :y, :z).new(x_value.to_f, y_value.to_f, z_value.to_f)
      end

      def point_matches?(point, x_value, y_value, z_value)
        point.respond_to?(:x) &&
          same_value?(point.x, x_value) &&
          same_value?(point.y, y_value) &&
          same_value?(point.z, z_value)
      end

      def same_value?(first, second)
        (first.to_f - second.to_f).abs <= Float::EPSILON
      end

      def point_on_face?(face, point)
        return true unless face.respond_to?(:classify_point)

        face_classification_values.include?(face.classify_point(point))
      rescue StandardError
        false
      end

      def face_classification_values
        [
          Sketchup::Face::PointInside,
          Sketchup::Face::PointOnEdge,
          Sketchup::Face::PointOnVertex,
          :inside,
          :on_edge,
          :on_vertex
        ].compact
      end
    end
  end
end
