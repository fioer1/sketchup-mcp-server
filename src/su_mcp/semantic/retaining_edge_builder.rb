# frozen_string_literal: true

require_relative 'builder_refusal'
require_relative 'length_converter'
require_relative 'planar_geometry_helper'
require_relative 'scene_properties'
require_relative 'surface_height_sampler'

module SU_MCP
  module Semantic
    # Builds the SEM-02 `retaining_edge` geometry slice from a polyline.
    class RetainingEdgeBuilder
      include PlanarGeometryHelper

      COPLANAR_NORMAL_DOT = 0.999
      DEFAULT_STATION_SPACING_METERS = 1.0
      DEFAULT_STATION_LIMIT = 1_000
      STATION_TOLERANCE = 1e-9

      def initialize(scene_properties: SceneProperties.new,
                     surface_sampler: SurfaceHeightSampler.new,
                     station_spacing: nil,
                     station_limit: DEFAULT_STATION_LIMIT)
        @scene_properties = scene_properties
        @surface_sampler = surface_sampler
        @station_spacing = station_spacing || meters_to_internal(DEFAULT_STATION_SPACING_METERS)
        @station_limit = station_limit
      end

      def build(model:, params:, destination: nil)
        payload = params.fetch('definition')
        target_collection = destination || model.active_entities
        return build_hosted_edge(model, target_collection, params, payload) if edge_clamp?(params)

        build_planar_edge(model, target_collection, params, payload)
      end

      private

      attr_reader :scene_properties, :surface_sampler, :station_spacing, :station_limit

      def build_planar_edge(model, target_collection, params, payload)
        group = target_collection.add_group
        scene_properties.apply!(model: model, group: group, params: params)
        face = add_planar_face(
          group: group,
          points: corridor_polygon(payload.fetch('polyline'), payload.fetch('thickness')),
          elevation: payload.fetch('elevation', 0.0)
        )
        face.pushpull(payload.fetch('height').to_f)
        hide_internal_edges(group.entities)
        group
      end

      def build_hosted_edge(model, target_collection, params, payload)
        sections = planned_hosted_sections(
          payload: payload,
          host_target: params.dig('hosting', 'resolved_target')
        )
        group = target_collection.add_group
        scene_properties.apply!(model: model, group: group, params: params)
        emit_hosted_edge_faces(group.entities, sections)
        hide_internal_edges(group.entities)
        group
      end

      def edge_clamp?(params)
        params.dig('hosting', 'mode') == 'edge_clamp'
      end

      def planned_hosted_sections(payload:, host_target:)
        sample_context = surface_sampler.prepare_context(host_target)
        raise invalid_hosting_target_refusal if sample_context.fetch(:face_entries).empty?

        stations = resample_polyline(payload.fetch('polyline'))
        raise tessellation_limit_refusal(stations.length) if stations.length > station_limit

        sections_for(
          stations: stations,
          height: payload.fetch('height'),
          thickness: payload.fetch('thickness'),
          sample_context: sample_context
        )
      end

      def resample_polyline(polyline)
        normalized = normalize_polyline(polyline)
        raise invalid_polyline_refusal if normalized.length < 2

        stations = [normalized.first]
        normalized.each_cons(2) do |start_point, end_point|
          intermediate_stations_for_segment(start_point, end_point).each do |station|
            append_station(stations, station)
          end
          append_station(stations, end_point)
        end
        stations
      end

      def normalize_polyline(polyline)
        Array(polyline).filter_map do |point|
          values = Array(point).first(2)
          next unless values.length == 2

          values.map(&:to_f)
        end
      end

      def intermediate_stations_for_segment(start_point, end_point)
        segment_vector = [end_point[0] - start_point[0], end_point[1] - start_point[1]]
        segment_length = Math.hypot(*segment_vector)
        raise invalid_polyline_refusal if segment_length <= STATION_TOLERANCE

        step_count = (segment_length / station_spacing).floor
        1.upto(step_count).filter_map do |step|
          distance = station_spacing * step
          next if distance >= (segment_length - STATION_TOLERANCE)

          ratio = distance / segment_length
          [
            start_point[0] + (segment_vector[0] * ratio),
            start_point[1] + (segment_vector[1] * ratio)
          ]
        end
      end

      def sections_for(stations:, height:, thickness:, sample_context:)
        half_thickness = thickness.to_f / 2.0
        tangents = stations.each_index.map { |index| tangent_for(stations, index) }
        normals = tangents.map { |tangent| [-tangent[1], tangent[0]] }

        stations.each_index.map do |index|
          base_z = sampled_base_z(stations[index], sample_context, index)
          section_for(
            center: stations[index],
            normal: normals[index],
            half_thickness: half_thickness,
            base_z: base_z,
            height: height.to_f
          )
        end
      end

      def tangent_for(stations, index)
        start_point, end_point = tangent_window_for(stations, index)
        direction = [end_point[0] - start_point[0], end_point[1] - start_point[1]]
        length = Math.hypot(*direction)
        raise invalid_polyline_refusal if length <= STATION_TOLERANCE

        [direction[0] / length, direction[1] / length]
      end

      def tangent_window_for(stations, index)
        return [stations[0], stations[1]] if index.zero?
        return [stations[-2], stations[-1]] if index == stations.length - 1

        [stations[index - 1], stations[index + 1]]
      end

      def sampled_base_z(station, sample_context, station_index)
        sampled_z = surface_sampler.sample_z_from_context(
          context: sample_context,
          x_value: station[0],
          y_value: station[1]
        )
        raise terrain_sample_miss_refusal(station_index) if sampled_z.nil?

        sampled_z
      end

      def section_for(center:, normal:, half_thickness:, base_z:, height:)
        left_xy = offset_point(center, normal, half_thickness)
        right_xy = offset_point(center, normal, -half_thickness)
        {
          left_base: [left_xy[0], left_xy[1], base_z],
          right_base: [right_xy[0], right_xy[1], base_z],
          left_top: [left_xy[0], left_xy[1], base_z + height],
          right_top: [right_xy[0], right_xy[1], base_z + height]
        }
      end

      def offset_point(center, normal, distance)
        [
          center[0] + (normal[0] * distance.to_f),
          center[1] + (normal[1] * distance.to_f)
        ]
      end

      def append_station(stations, station)
        return if stations.any? && duplicate_station?(stations.last, station)

        stations << station
      end

      def duplicate_station?(left, right)
        Math.hypot(left[0] - right[0], left[1] - right[1]) <= STATION_TOLERANCE
      end

      def emit_hosted_edge_faces(entities, sections)
        raise invalid_polyline_refusal if sections.length < 2

        return emit_hosted_edge_face_batch(entities, sections) unless entities.respond_to?(:build)

        entities.build do |builder|
          emit_hosted_edge_face_batch(builder, sections)
        end
      end

      def emit_hosted_edge_face_batch(face_target, sections)
        sections.each_cons(2) do |first_section, second_section|
          add_interval_faces(face_target, first_section, second_section)
        end
        add_end_cap(face_target, sections.first)
        add_end_cap(face_target, sections.last)
      end

      def add_interval_faces(face_target, first_section, second_section)
        add_quad(face_target, first_section[:left_top], first_section[:right_top],
                 second_section[:right_top], second_section[:left_top])
        add_quad(face_target, first_section[:left_base], second_section[:left_base],
                 second_section[:right_base], first_section[:right_base])
        add_quad(face_target, first_section[:left_base], first_section[:left_top],
                 second_section[:left_top], second_section[:left_base])
        add_quad(face_target, first_section[:right_base], second_section[:right_base],
                 second_section[:right_top], first_section[:right_top])
      end

      def add_end_cap(face_target, section)
        add_quad(face_target, section[:left_base], section[:right_base],
                 section[:right_top], section[:left_top])
      end

      def add_quad(face_target, first_point, second_point, third_point, fourth_point)
        [
          face_target.add_face(first_point, second_point, third_point),
          face_target.add_face(first_point, third_point, fourth_point)
        ]
      end

      def hide_internal_edges(entities)
        return unless entities.respond_to?(:grep)

        entities.grep(Sketchup::Edge).each do |edge|
          next unless internal_edge?(edge)

          edge.hidden = true
          edge.soft = true if edge.respond_to?(:soft=)
          edge.smooth = true if edge.respond_to?(:smooth=)
        end
      end

      def internal_edge?(edge)
        return false unless edge.respond_to?(:faces)

        faces = edge.faces
        faces.length == 2 && coplanar_faces?(faces[0], faces[1])
      rescue StandardError
        false
      end

      def coplanar_faces?(first_face, second_face)
        first_normal = normalized_components(first_face.normal)
        second_normal = normalized_components(second_face.normal)
        return false unless first_normal && second_normal

        first_normal.zip(second_normal).sum { |left, right| left * right }.abs >=
          COPLANAR_NORMAL_DOT
      end

      def normalized_components(normal)
        components = %i[x y z].map do |component|
          normal.respond_to?(component) ? normal.public_send(component).to_f : 0.0
        end
        length = Math.sqrt(components.sum { |value| value * value })
        return nil unless length.positive?

        components.map { |value| value / length }
      end

      def meters_to_internal(value)
        value.to_f * LengthConverter::METERS_TO_INTERNAL
      end

      def invalid_hosting_target_refusal
        BuilderRefusal.new(
          code: 'invalid_hosting_target',
          message: 'Hosting target does not expose sampleable surface geometry for linear edge.',
          details: { section: 'hosting' }
        )
      end

      def invalid_polyline_refusal
        BuilderRefusal.new(
          code: 'invalid_geometry',
          message: 'Linear edge polyline must contain at least two distinct points.',
          details: { section: 'definition', field: 'definition.polyline' }
        )
      end

      def terrain_sample_miss_refusal(station_index)
        BuilderRefusal.new(
          code: 'terrain_sample_miss',
          message: 'Terrain sampling missed at one or more linear edge stations.',
          details: { section: 'hosting', stationIndex: station_index }
        )
      end

      def tessellation_limit_refusal(station_count)
        BuilderRefusal.new(
          code: 'linear_edge_tessellation_limit_exceeded',
          message: 'Linear edge would create too many stations for safe geometry generation.',
          details: {
            section: 'definition',
            field: 'definition.polyline',
            stationCount: station_count,
            stationLimit: station_limit
          }
        )
      end
    end
  end
end
