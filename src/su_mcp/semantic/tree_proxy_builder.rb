# frozen_string_literal: true

require_relative 'planar_geometry_helper'
require_relative 'generated_component_library'
require_relative 'scene_properties'
require_relative 'terrain_anchor_resolver'

module SU_MCP
  module Semantic
    # Builds the SEM-02 `tree_proxy` geometry slice from an accepted low-poly
    # faceted proxy silhouette while keeping the public payload parametric.
    class TreeProxyBuilder # rubocop:disable Metrics/ClassLength
      include PlanarGeometryHelper

      TRUNK_SEGMENTS = 6
      CANOPY_SEGMENTS = 10
      TRUNK_ROTATION_RADIANS = Math::PI / 6.0
      CANOPY_ROTATION_RADIANS = Math::PI / 10.0

      TRUNK_ANCHOR_RATIO = 0.477409
      TRUNK_TOP_RATIO = 0.536117
      STEM_TOP_OVERLAP_RATIO = 0.012

      FAMILY = 'tree_proxy'
      COMPONENT_VERSION = '11'
      STYLE_SIGNATURE = 'image_tree_canopy_connected'
      MATERIAL_SPECS = {
        trunk: { name: 'Codex-Tree-Trunk', rgb: [102, 76, 54] },
        canopy: { name: 'Codex-Tree-Canopy', rgb: [86, 121, 83] }
      }.freeze

      CANOPY_PROFILES = [
        {
          name: 'upright_oval',
          rings: [
            { z_ratio: 0.34, radius_x_ratio: 0.20, radius_y_ratio: 0.18, vertical_jitter: 0.000 },
            { z_ratio: 0.48, radius_x_ratio: 0.46, radius_y_ratio: 0.38, vertical_jitter: 0.010 },
            { z_ratio: 0.66, radius_x_ratio: 0.58, radius_y_ratio: 0.50, vertical_jitter: 0.012 },
            { z_ratio: 0.84, radius_x_ratio: 0.48, radius_y_ratio: 0.42, vertical_jitter: 0.010 },
            { z_ratio: 1.00, radius_x_ratio: 0.20, radius_y_ratio: 0.18, vertical_jitter: 0.000 }
          ],
          ring_factors: [0.98, 1.01, 1.02, 1.00, 0.98],
          radius_range: [0.92, 1.06],
          axis_range: [0.92, 1.08],
          z_offset_range: [-0.55, 0.55],
          z_ratio_jitter: 0.016,
          lean: 0.13
        },
        {
          name: 'compact_high',
          rings: [
            { z_ratio: 0.58, radius_x_ratio: 0.24, radius_y_ratio: 0.22, vertical_jitter: 0.000 },
            { z_ratio: 0.67, radius_x_ratio: 0.62, radius_y_ratio: 0.56, vertical_jitter: 0.008 },
            { z_ratio: 0.78, radius_x_ratio: 0.72, radius_y_ratio: 0.66, vertical_jitter: 0.010 },
            { z_ratio: 0.90, radius_x_ratio: 0.60, radius_y_ratio: 0.54, vertical_jitter: 0.008 },
            { z_ratio: 1.00, radius_x_ratio: 0.26, radius_y_ratio: 0.24, vertical_jitter: 0.000 }
          ],
          ring_factors: [0.96, 1.00, 1.04, 1.00, 0.96],
          radius_range: [0.88, 1.08],
          axis_range: [0.90, 1.10],
          z_offset_range: [-0.45, 0.45],
          z_ratio_jitter: 0.010,
          lean: 0.10
        },
        {
          name: 'squat_block',
          rings: [
            { z_ratio: 0.66, radius_x_ratio: 0.78, radius_y_ratio: 0.60, vertical_jitter: 0.000 },
            { z_ratio: 0.72, radius_x_ratio: 0.98, radius_y_ratio: 0.78, vertical_jitter: 0.002 },
            { z_ratio: 0.82, radius_x_ratio: 1.00, radius_y_ratio: 0.80, vertical_jitter: 0.003 },
            { z_ratio: 0.92, radius_x_ratio: 0.96, radius_y_ratio: 0.78, vertical_jitter: 0.002 },
            { z_ratio: 1.00, radius_x_ratio: 0.74, radius_y_ratio: 0.58, vertical_jitter: 0.000 }
          ],
          ring_factors: [0.99, 1.01, 1.00, 1.01, 0.99],
          radius_range: [0.94, 1.04],
          axis_range: [0.92, 1.08],
          z_offset_range: [-0.18, 0.18],
          z_ratio_jitter: 0.004,
          lean: 0.05
        },
        {
          name: 'round_boulder',
          rings: [
            { z_ratio: 0.49, radius_x_ratio: 0.34, radius_y_ratio: 0.34, vertical_jitter: 0.000 },
            { z_ratio: 0.60, radius_x_ratio: 0.78, radius_y_ratio: 0.74, vertical_jitter: 0.010 },
            { z_ratio: 0.74, radius_x_ratio: 0.96, radius_y_ratio: 0.92, vertical_jitter: 0.012 },
            { z_ratio: 0.87, radius_x_ratio: 0.82, radius_y_ratio: 0.78, vertical_jitter: 0.010 },
            { z_ratio: 1.00, radius_x_ratio: 0.34, radius_y_ratio: 0.32, vertical_jitter: 0.000 }
          ],
          ring_factors: [0.96, 1.00, 1.02, 0.99, 0.96],
          radius_range: [0.90, 1.08],
          axis_range: [0.90, 1.08],
          z_offset_range: [-0.75, 0.75],
          z_ratio_jitter: 0.012,
          lean: 0.10
        },
        {
          name: 'cut_boulder',
          rings: [
            { z_ratio: 0.50, radius_x_ratio: 0.56, radius_y_ratio: 0.40, vertical_jitter: 0.000 },
            { z_ratio: 0.60, radius_x_ratio: 0.94, radius_y_ratio: 0.72, vertical_jitter: 0.004 },
            { z_ratio: 0.73, radius_x_ratio: 1.00, radius_y_ratio: 0.84, vertical_jitter: 0.006 },
            { z_ratio: 0.86, radius_x_ratio: 0.90, radius_y_ratio: 0.78, vertical_jitter: 0.004 },
            { z_ratio: 1.00, radius_x_ratio: 0.62, radius_y_ratio: 0.46, vertical_jitter: 0.000 }
          ],
          ring_factors: [0.98, 1.00, 1.04, 1.00, 0.98],
          radius_range: [0.86, 1.08],
          axis_range: [0.88, 1.12],
          z_offset_range: [-0.35, 0.35],
          z_ratio_jitter: 0.010,
          lean: 0.08
        }
      ].freeze
      CANOPY_RING_COUNT = CANOPY_PROFILES.first.fetch(:rings).length
      EntitiesOwner = Struct.new(:entities)

      def initialize(scene_properties: SceneProperties.new,
                     component_library: GeneratedComponentLibrary.new,
                     terrain_anchor_resolver: TerrainAnchorResolver.new)
        @scene_properties = scene_properties
        @component_library = component_library
        @terrain_anchor_resolver = terrain_anchor_resolver
      end

      def build(model:, params:, destination: nil)
        payload = normalized_payload(params)
        payload = apply_terrain_anchor(payload, params)
        definition = tree_definition(model: model, payload: payload)
        target_collection = destination || model.active_entities
        wrapper_group = target_collection.add_group
        scene_properties.apply!(model: model, group: wrapper_group, params: params)

        wrapper_group.entities.add_instance(
          definition,
          translation_for(tree_position(payload))
        )

        wrapper_group
      end

      private

      attr_reader :scene_properties, :component_library, :terrain_anchor_resolver

      def normalized_payload(params)
        payload = params.fetch('definition').dup
        canopy_diameter_x = payload.fetch('canopyDiameterX')
        payload['canopyDiameterY'] = canopy_diameter_x unless payload.key?('canopyDiameterY')
        payload['canopyDiameterY'] = canopy_diameter_x if payload['canopyDiameterY'].nil?
        payload['_shapeSeed'] = shape_seed_for(params: params, payload: payload)
        payload
      end

      def apply_terrain_anchor(payload, params)
        return payload unless params.dig('hosting', 'mode') == 'terrain_anchored'

        position = payload.fetch('position')
        # Hosted trees replace caller z with terrain height; caller z is not an offset.
        sampled_z = terrain_anchor_resolver.resolve(
          host_target: params.dig('hosting', 'resolved_target'),
          anchor_xy: [position.fetch('x').to_f, position.fetch('y').to_f],
          role: 'tree_base'
        )
        payload.merge(
          'position' => position.merge('z' => sampled_z)
        )
      end

      def build_trunk(group:, payload:, material: nil)
        base_ring = trunk_ring(payload: payload, z_ratio: 0.0)
        anchor_ring = trunk_ring(payload: payload, z_ratio: TRUNK_ANCHOR_RATIO)
        top_ring = trunk_ring(payload: payload, z_ratio: TRUNK_TOP_RATIO)

        add_ring_face(group: group, ring: base_ring, reverse: true, material: material)
        connect_rings_with_quads(
          group: group,
          lower_ring: base_ring,
          upper_ring: anchor_ring,
          material: material
        )
        connect_rings_with_quads(
          group: group,
          lower_ring: anchor_ring,
          upper_ring: top_ring,
          material: material
        )

        {
          anchor: anchor_ring,
          top: top_ring
        }
      end

      def tree_definition(model:, payload:)
        component_library.definition_for(
          model: model,
          family: FAMILY,
          version: COMPONENT_VERSION,
          signature: tree_signature(payload),
          generator: self.class.name
        ) do |entities|
          definition_payload = definition_payload_for(payload)
          definition_group = entities_owner(entities)
          materials = tree_materials(model.materials)
          trunk_rings = build_trunk(
            group: definition_group,
            payload: definition_payload,
            material: materials.fetch(:trunk)
          )
          build_canopy(
            group: definition_group,
            payload: definition_payload,
            trunk_rings: trunk_rings,
            materials: materials
          )
        end
      end

      def entities_owner(entities)
        EntitiesOwner.new(entities)
      end

      def definition_payload_for(payload)
        payload.merge('position' => { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 })
      end

      def tree_signature(payload)
        [
          "style=#{STYLE_SIGNATURE}",
          "profile=#{canopy_profile(payload).fetch(:name)}",
          format('seed=%08x', stable_seed(payload.fetch('_shapeSeed'))),
          format('height=%.9f', tree_height(payload)),
          format('canopy_x=%.9f', canopy_radius_x(payload) * 2.0),
          format('canopy_y=%.9f', canopy_radius_y(payload) * 2.0),
          format('trunk=%.9f', trunk_radius(payload) * 2.0)
        ].join('|')
      end

      def tree_position(payload)
        position = payload.fetch('position')
        {
          x: position.fetch('x').to_f,
          y: position.fetch('y').to_f,
          z: position.fetch('z', 0.0).to_f
        }
      end

      def tree_height(payload)
        payload.fetch('height').to_f
      end

      def canopy_diameter_y(payload)
        payload.fetch('canopyDiameterY', payload.fetch('canopyDiameterX')).to_f
      end

      def canopy_radius_x(payload)
        payload.fetch('canopyDiameterX').to_f / 2.0
      end

      def canopy_radius_y(payload)
        canopy_diameter_y(payload) / 2.0
      end

      def trunk_radius(payload)
        payload.fetch('trunkDiameter').to_f / 2.0
      end

      def trunk_ring(payload:, z_ratio:)
        build_ring(
          center: tree_position(payload),
          z_height: elevation_for(payload, z_ratio),
          radius_x: trunk_radius_at(payload: payload, z_ratio: z_ratio),
          radius_y: trunk_radius_at(payload: payload, z_ratio: z_ratio),
          segments: TRUNK_SEGMENTS,
          rotation: TRUNK_ROTATION_RADIANS
        )
      end

      def trunk_radius_at(payload:, z_ratio:)
        radius = trunk_radius(payload)
        case z_ratio
        when 0.0
          radius * 1.18
        when TRUNK_ANCHOR_RATIO
          radius
        else
          radius * 0.72
        end
      end

      def build_canopy(group:, payload:, trunk_rings:, materials:)
        variation = canopy_variation(payload)
        rings = canopy_rings(payload: payload, variation: variation)
        connect_stem_to_canopy(
          group: group,
          payload: payload,
          trunk_ring: trunk_rings.fetch(:top),
          canopy_ring: rings.first,
          material: materials.fetch(:trunk)
        )
        emit_canopy_shell(group: group, rings: rings, material: materials.fetch(:canopy))
      end

      def canopy_rings(payload:, variation:)
        variation.fetch(:profile).fetch(:rings).each_with_index.map do |definition, index|
          canopy_ring(payload: payload, definition: definition, index: index, variation: variation)
        end
      end

      def emit_canopy_shell(group:, rings:, material:)
        add_ring_face(
          group: group,
          ring: rings.first.reverse,
          smooth: true,
          material: material
        )
        rings.each_cons(2) do |lower_ring, upper_ring|
          connect_rings_with_quads(
            group: group,
            lower_ring: lower_ring,
            upper_ring: upper_ring,
            smooth: true,
            material: material
          )
        end
        add_ring_face(
          group: group,
          ring: rings.last,
          smooth: true,
          material: material
        )
      end

      def connect_stem_to_canopy(group:, payload:, trunk_ring:, canopy_ring:, material:)
        stem_top_z = stem_top_z(payload: payload, canopy_ring: canopy_ring)
        trunk_top_z = trunk_ring.first[2]
        if stem_top_z <= trunk_top_z
          add_ring_face(group: group, ring: trunk_ring, material: material)
          return
        end

        stem_top_ring = trunk_ring.map do |point|
          [
            point[0],
            point[1],
            stem_top_z.clamp(trunk_top_z, tree_position(payload)[:z] + tree_height(payload))
          ]
        end

        connect_rings_with_quads(
          group: group,
          lower_ring: trunk_ring,
          upper_ring: stem_top_ring,
          material: material
        )
        add_ring_face(group: group, ring: stem_top_ring, material: material)
      end

      def stem_top_z(payload:, canopy_ring:)
        canopy_ring.map { |point| point[2] }.min +
          (tree_height(payload) * STEM_TOP_OVERLAP_RATIO)
      end

      def elevation_for(payload, z_ratio)
        tree_position(payload)[:z] + (tree_height(payload) * z_ratio.to_f)
      end

      def build_ring(center:, z_height:, radius_x:, radius_y:,
                     segments:, rotation:, z_offsets: nil, radial_scales: nil,
                     angle_offsets: nil)
        Array.new(segments) do |index|
          angle = rotation + ((Math::PI * 2.0 * index) / segments.to_f) +
                  Array(angle_offsets)[index].to_f
          radial_scale = Array(radial_scales)[index] || 1.0
          [
            center.fetch(:x) + (Math.cos(angle) * radius_x.to_f * radial_scale),
            center.fetch(:y) + (Math.sin(angle) * radius_y.to_f * radial_scale),
            z_height.to_f + Array(z_offsets)[index].to_f
          ]
        end
      end

      def canopy_ring(payload:, definition:, index:, variation:)
        ring = build_ring(
          center: canopy_ring_center(payload, variation, index),
          z_height: canopy_ring_elevation(payload, definition, index, variation),
          radius_x: canopy_ring_radius(payload, definition, variation, index, :x),
          radius_y: canopy_ring_radius(payload, definition, variation, index, :y),
          segments: CANOPY_SEGMENTS,
          rotation: CANOPY_ROTATION_RADIANS + variation.fetch(:ring_rotations)[index],
          z_offsets: canopy_z_offsets(payload, definition, variation.fetch(:z_offsets)[index]),
          radial_scales: ring_radial_scales(
            variation.fetch(:radial_scales)[index],
            variation.fetch(:profile),
            index
          )
        )
        ring.map { |point| clamp_to_tree_bounds(point, payload) }
      end

      def canopy_ring_center(payload, variation, index)
        position = tree_position(payload)
        offset = variation.fetch(:ring_centers)[index]
        {
          x: position[:x] + offset[0],
          y: position[:y] + offset[1]
        }
      end

      def canopy_ring_elevation(payload, definition, index, variation)
        elevation_for(
          payload,
          definition.fetch(:z_ratio) + variation.fetch(:z_ratio_offsets)[index]
        )
      end

      def canopy_ring_radius(payload, definition, variation, index, axis)
        canopy_radius = axis == :x ? canopy_radius_x(payload) : canopy_radius_y(payload)
        variation_key = axis == :x ? :radius_x_scales : :radius_y_scales
        definition_key = axis == :x ? :radius_x_ratio : :radius_y_ratio

        canopy_radius * definition.fetch(definition_key) *
          variation.fetch(variation_key)[index]
      end

      def clamp_to_tree_bounds(point, payload)
        position = tree_position(payload)
        [
          point[0].clamp(
            position[:x] - canopy_radius_x(payload),
            position[:x] + canopy_radius_x(payload)
          ),
          point[1].clamp(
            position[:y] - canopy_radius_y(payload),
            position[:y] + canopy_radius_y(payload)
          ),
          point[2].clamp(position[:z], position[:z] + tree_height(payload))
        ]
      end

      def ring_radial_scales(radial_scales, profile, ring_index)
        ring_factor = profile.fetch(:ring_factors).fetch(ring_index)
        radial_scales.map { |scale| (scale * ring_factor).clamp(0.86, 1.08) }
      end

      def canopy_z_offsets(payload, definition, offsets)
        offsets.map do |offset|
          tree_height(payload) * definition.fetch(:vertical_jitter) * offset
        end
      end

      def canopy_variation(payload)
        random = Random.new(stable_seed(payload.fetch('_shapeSeed')))
        profile = canopy_profile(payload)
        lean = profile.fetch(:lean)
        axis_min, axis_max = profile.fetch(:axis_range)
        radius_min, radius_max = profile.fetch(:radius_range)
        z_min, z_max = profile.fetch(:z_offset_range)
        lean_x = canopy_radius_x(payload) * random_between(random, -lean, lean)
        lean_y = canopy_radius_y(payload) * random_between(random, -lean, lean)
        {
          profile: profile,
          ring_centers: ring_centers(random, payload, lean_x, lean_y),
          ring_rotations: ring_samples(random, -0.32, 0.32),
          radius_x_scales: ring_samples(random, axis_min, axis_max),
          radius_y_scales: ring_samples(random, axis_min, axis_max),
          z_ratio_offsets: z_ratio_offsets(random, profile),
          radial_scales: smoothed_ring_segment_samples(random, radius_min, radius_max),
          z_offsets: ring_segment_samples(random, z_min, z_max)
        }
      end

      def canopy_profile(payload)
        CANOPY_PROFILES.fetch(stable_seed(payload.fetch('_shapeSeed')) % CANOPY_PROFILES.length)
      end

      def ring_samples(random, min, max)
        Array.new(CANOPY_RING_COUNT) { random_between(random, min, max) }
      end

      def ring_segment_samples(random, min, max)
        Array.new(CANOPY_RING_COUNT) do
          Array.new(CANOPY_SEGMENTS) { random_between(random, min, max) }
        end
      end

      def smoothed_ring_segment_samples(random, min, max)
        ring_segment_samples(random, min, max).map do |samples|
          samples.each_index.map do |index|
            previous_value = samples[(index - 1) % samples.length]
            next_value = samples[(index + 1) % samples.length]
            ((previous_value + samples[index] + next_value) / 3.0).clamp(min, max)
          end
        end
      end

      def z_ratio_offsets(random, profile)
        jitter = profile.fetch(:z_ratio_jitter)
        [0.0] + Array.new(CANOPY_RING_COUNT - 2) do
          random_between(random, -jitter, jitter)
        end + [0.0]
      end

      def ring_centers(random, payload, lean_x, lean_y)
        CANOPY_RING_COUNT.times.map do |index|
          t = index.to_f / (CANOPY_RING_COUNT - 1)
          [
            (lean_x * t) + (canopy_radius_x(payload) * random_between(random, -0.065, 0.065)),
            (lean_y * t) + (canopy_radius_y(payload) * random_between(random, -0.065, 0.065))
          ]
        end
      end

      def random_between(random, min, max)
        min + (random.rand * (max - min))
      end

      def shape_seed_for(params:, payload:)
        [
          params.dig('metadata', 'sourceElementId'),
          payload['speciesHint'],
          payload.fetch('canopyDiameterX'),
          payload.fetch('canopyDiameterY'),
          payload.fetch('height'),
          payload.fetch('trunkDiameter')
        ].compact.join('|')
      end

      def stable_seed(value)
        value.to_s.each_byte.reduce(2_166_136_261) do |hash, byte|
          ((hash ^ byte) * 16_777_619) & 0xffffffff
        end
      end

      def tree_materials(materials)
        MATERIAL_SPECS.transform_values do |spec|
          material(materials, spec.fetch(:name), spec.fetch(:rgb))
        end
      end

      def material(materials, name, rgb)
        existing_material = materials[name]
        return existing_material if existing_material

        material = materials.add(name)
        material.color = rgb if material.respond_to?(:color=)
        material
      end

      def translation_for(position)
        origin = [position.fetch(:x), position.fetch(:y), position.fetch(:z)]
        transformation = Geom::Transformation.new(origin)
        return transformation if transformation.respond_to?(:origin) && transformation.origin

        { origin: origin }
      rescue StandardError
        { origin: origin }
      end

      def add_ring_face(group:, ring:, reverse: false, smooth: false, material: nil)
        ordered_ring = reverse ? ring.reverse : ring
        add_face(group: group, points: ordered_ring, smooth: smooth, material: material)
      end

      def connect_rings_with_quads(group:, lower_ring:, upper_ring:,
                                   segments: lower_ring.length, smooth: false, material: nil)
        segments.times do |index|
          next_index = (index + 1) % segments
          add_ring_segment_face(
            group: group,
            lower_start: lower_ring[index],
            lower_finish: lower_ring[next_index],
            upper_finish: upper_ring[next_index],
            upper_start: upper_ring[index],
            smooth: smooth,
            material: material
          )
        end
      end

      def add_ring_segment_face(group:, lower_start:, lower_finish:, upper_finish:,
                                upper_start:, smooth: false, material: nil)
        quad_points = [lower_start, lower_finish, upper_finish, upper_start]
        if planar_points?(quad_points)
          add_face(group: group, points: quad_points, smooth: smooth, material: material)
          return
        end

        add_face(
          group: group,
          points: [lower_start, lower_finish, upper_finish],
          smooth: smooth,
          material: material
        )
        add_face(
          group: group,
          points: [lower_start, upper_finish, upper_start],
          smooth: smooth,
          material: material
        )
      end

      def add_face(group:, points:, smooth: false, material: nil)
        face = group.entities.add_face(*points)
        apply_face_material(face, material)
        soften_face_edges(face) if smooth
        face
      end

      def apply_face_material(face, material)
        return unless material

        face.material = material if face.respond_to?(:material=)
        face.back_material = material if face.respond_to?(:back_material=)
      end

      def soften_face_edges(face)
        return unless face.respond_to?(:edges)

        face.edges.each do |edge|
          edge.soft = true if edge.respond_to?(:soft=)
          edge.smooth = true if edge.respond_to?(:smooth=)
        end
      end

      def planar_points?(points, tolerance: 1e-6)
        return true if points.length <= 3

        origin = points[0]
        normal = triangle_normal(origin, points[1], points[2])
        return true if near_zero_vector?(normal)

        points[3..].all? do |point|
          vector = subtract_points(point, origin)
          dot_product(normal, vector).abs <= tolerance
        end
      end

      def triangle_normal(point_a, point_b, point_c)
        cross_product(
          subtract_points(point_b, point_a),
          subtract_points(point_c, point_a)
        )
      end

      def subtract_points(point, origin)
        [
          point[0].to_f - origin[0].to_f,
          point[1].to_f - origin[1].to_f,
          point[2].to_f - origin[2].to_f
        ]
      end

      # rubocop:disable Metrics/AbcSize
      def cross_product(left, right)
        [
          (left[1].to_f * right[2].to_f) - (left[2].to_f * right[1].to_f),
          (left[2].to_f * right[0].to_f) - (left[0].to_f * right[2].to_f),
          (left[0].to_f * right[1].to_f) - (left[1].to_f * right[0].to_f)
        ]
      end
      # rubocop:enable Metrics/AbcSize

      def near_zero_vector?(vector, tolerance: 1e-9)
        vector.all? { |value| value.abs <= tolerance }
      end
    end
  end
end
