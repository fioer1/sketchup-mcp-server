# frozen_string_literal: true

require_relative 'planar_geometry_helper'
require_relative 'path_drape_builder'
require_relative 'scene_properties'

module SU_MCP
  module Semantic
    # Builds the SEM-02 `path` geometry slice from a centerline and width.
    class PathBuilder
      include PlanarGeometryHelper

      COPLANAR_NORMAL_DOT = 0.999

      def initialize(scene_properties: SceneProperties.new, drape_builder: PathDrapeBuilder.new)
        @scene_properties = scene_properties
        @drape_builder = drape_builder
      end

      def build(model:, params:, destination: nil)
        payload = params['definition'] || params.fetch('path')
        target_collection = destination || model.active_entities
        group = target_collection.add_group
        scene_properties.apply!(model: model, group: group, params: params)
        build_geometry(group: group, payload: payload, params: params)
        hide_internal_edges(group.entities)
        group
      end

      private

      attr_reader :scene_properties, :drape_builder

      def build_geometry(group:, payload:, params:)
        if params.dig('hosting', 'mode') == 'surface_drape'
          build_surface_drape(group, payload, params)
        else
          build_planar_path(group, payload)
        end
      end

      def build_surface_drape(group, payload, params)
        drape_builder.build(
          group: group,
          payload: payload,
          host_target: params.dig('hosting', 'resolved_target')
        )
      end

      def build_planar_path(group, payload)
        face = add_planar_face(
          group: group,
          points: corridor_polygon(payload.fetch('centerline'), payload.fetch('width')),
          elevation: payload.fetch('elevation', 0.0)
        )
        face.pushpull(-payload['thickness'].to_f) if payload.key?('thickness')
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
    end
  end
end
