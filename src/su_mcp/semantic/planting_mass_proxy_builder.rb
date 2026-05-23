# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength, Metrics/AbcSize, Metrics/ParameterLists, Naming/VariableNumber, Layout/LineLength

require_relative 'builder_refusal'
require_relative 'generated_component_library'
require_relative 'scene_properties'
require_relative 'surface_frame_evaluator'
require_relative 'surface_height_sampler'

module SU_MCP
  module Semantic
    # Builds deterministic low-poly procedural planting proxy geometry for planting masses.
    class PlantingMassProxyBuilder
      DEFAULT_SPACING = 24.0
      DEFAULT_EDGE_FADE = 16.5
      DEFAULT_MIN_MOTIF_COUNT = 12
      DEFAULT_MAX_MOTIF_COUNT = 32
      UNDERLAY_CORNER_SOFTENING = 0.24
      METERS_TO_INCHES = 39.370_078_740_157_48
      REFERENCE_AVERAGE_HEIGHT_M = 0.28
      MOTIF_VERSION = '7'
      MOTIF_KEYS = %i[matrix_motif edge_motif grass_motif perennial_motif].freeze

      def initialize(scene_properties: SceneProperties.new,
                     component_library: GeneratedComponentLibrary.new,
                     surface_sampler: SurfaceHeightSampler.new,
                     frame_evaluator: SurfaceFrameEvaluator.new)
        @scene_properties = scene_properties
        @component_library = component_library
        @surface_sampler = surface_sampler
        @frame_evaluator = frame_evaluator
      end

      def build(model:, params:, destination: nil)
        payload = params.fetch('definition')
        build_plan = build_plan_for(payload: payload, params: params)
        materials = planting_materials(model.materials)
        definitions = motif_definitions(model: model, payload: payload, materials: materials)
        target_collection = destination || model.active_entities
        group = target_collection.add_group
        scene_properties.apply!(model: model, group: group, params: params)
        emit_underlay(
          group.entities,
          build_plan.fetch(:underlay_points),
          materials.fetch(:underlay),
          center: build_plan[:underlay_center]
        )
        build_plan.fetch(:placements).each do |placement|
          group.entities.add_instance(
            definitions.fetch(placement.fetch(:definition_key)),
            transformation_for(placement)
          )
        end
        group
      end

      private

      attr_reader :scene_properties, :component_library, :surface_sampler, :frame_evaluator

      def build_plan_for(payload:, params:)
        boundary = payload.fetch('boundary').map { |point| [point[0].to_f, point[1].to_f] }
        if params.dig('hosting', 'mode') == 'surface_drape'
          surface_plan(boundary: boundary, params: params)
        else
          fixed_plan(boundary: boundary, payload: payload)
        end
      end

      def fixed_plan(boundary:, payload:)
        elevation = payload.fetch('elevation', 0.0).to_f
        rng = deterministic_rng(payload: payload, boundary: boundary)
        placements = motif_candidates(boundary, rng).map do |candidate|
          placement_for_candidate(
            candidate,
            rng,
            origin: [candidate[0], candidate[1], elevation],
            x_axis: [1.0, 0.0, 0.0],
            y_axis: [0.0, 1.0, 0.0],
            up_axis: [0.0, 0.0, 1.0]
          )
        end
        {
          underlay_points: softened_underlay_points(
            boundary.map { |point| [point[0], point[1], elevation] }
          ),
          underlay_center: polygon_centroid(boundary) + [elevation],
          placements: placements
        }
      end

      def surface_plan(boundary:, params:)
        context = surface_context(params)
        rng = deterministic_rng(payload: params.fetch('definition'), boundary: boundary)
        underlay_points = softened_underlay_points(boundary).map do |point|
          sampled_point(context, point[0], point[1], role: 'planting_underlay')
        end
        center_xy = polygon_centroid(boundary)
        underlay_center = sampled_point(context, center_xy[0], center_xy[1], role: 'planting_underlay')
        placements = motif_candidates(boundary, rng).map do |candidate|
          frame = frame_evaluator.frame_from_context(
            context: context,
            x_value: candidate[0],
            y_value: candidate[1]
          )
          if frame[:outcome] != 'ready'
            raise terrain_sample_miss_refusal('planting_motif',
                                              candidate.first(2))
          end

          placement_for_candidate(candidate, rng, **frame.fetch(:frame))
        end
        { underlay_points: underlay_points, underlay_center: underlay_center, placements: placements }
      end

      def surface_context(params)
        host_target = params.dig('hosting', 'resolved_target')
        context = surface_sampler.prepare_context(host_target)
        raise invalid_hosting_target_refusal if context.fetch(:face_entries).empty?

        context
      end

      def sampled_point(context, x_value, y_value, role:)
        sampled_z = surface_sampler.sample_z_from_context(
          context: context,
          x_value: x_value,
          y_value: y_value
        )
        raise terrain_sample_miss_refusal(role, [x_value, y_value]) if sampled_z.nil?

        [x_value, y_value, sampled_z]
      end

      def motif_definitions(model:, payload:, materials:)
        MOTIF_KEYS.to_h do |key|
          definition = component_library.definition_for(
            model: model,
            family: 'planting_motif',
            version: MOTIF_VERSION,
            signature: motif_signature(payload, key),
            generator: self.class.name
          ) do |entities|
            emit_motif_geometry(entities, key, payload.fetch('averageHeight').to_f, materials)
          end
          [key, definition]
        end
      end

      def motif_signature(payload, key)
        [
          key,
          payload.fetch('plantingCategory', 'generic'),
          format('height=%.9f', payload.fetch('averageHeight').to_f)
        ].join('|')
      end

      def emit_motif_geometry(entities, key, height, materials)
        scale = prototype_height_scale(height)
        case key
        when :edge_motif
          emit_edge_motif_geometry(entities, materials, scale)
        when :grass_motif
          emit_grass_motif_geometry(entities, materials, scale)
        when :perennial_motif
          emit_perennial_motif_geometry(entities, materials, scale)
        else
          emit_matrix_motif_geometry(entities, materials, scale)
        end
      end

      def emit_matrix_motif_geometry(entities, materials, scale)
        [
          [0.00, 0.00, 0.0, 1.00],
          [0.26, 0.10, 0.7, 0.82],
          [-0.22, 0.16, 1.9, 0.72],
          [0.12, -0.24, 3.8, 0.66],
          [-0.30, -0.16, 5.2, 0.58]
        ].each_with_index do |point, index|
          x_value, y_value, angle, point_scale = point
          leaf_cluster_geometry(
            entities,
            materials,
            m(x_value * scale),
            m(y_value * scale),
            0.0,
            angle,
            point_scale * scale,
            variant: index
          )
        end
      end

      def emit_edge_motif_geometry(entities, materials, scale)
        [
          [-0.18, 0.00, -0.2, 0.72],
          [0.08, 0.06, 0.5, 0.58],
          [0.25, -0.08, 0.1, 0.48]
        ].each do |x_value, y_value, angle, point_scale|
          edge_fragment_geometry(entities, materials, m(x_value * scale), m(y_value * scale),
                                 0.0, angle, point_scale * scale)
        end
      end

      def emit_grass_motif_geometry(entities, materials, scale)
        [
          [-0.22, 0.02, -0.20, 0.86],
          [0.08, 0.00, 0.16, 1.00],
          [0.34, -0.02, 0.42, 0.78]
        ].each do |x_value, y_value, angle, point_scale|
          grass_fan_geometry(entities, materials, m(x_value * scale), m(y_value * scale),
                             0.0, angle, point_scale * scale)
        end
      end

      def emit_perennial_motif_geometry(entities, materials, scale)
        leaf_cluster_geometry(entities, materials, m(-0.18 * scale), m(-0.04 * scale),
                              0.0, 0.3, 0.82 * scale, variant: 1)
        perennial_mound_geometry(entities, materials, m(0.18 * scale), m(0.08 * scale),
                                 0.0, -0.2, 0.86 * scale)
      end

      def prototype_height_scale(height)
        [(height.to_f / METERS_TO_INCHES) / REFERENCE_AVERAGE_HEIGHT_M, 0.35].max
      end

      def m(value)
        value.to_f * METERS_TO_INCHES
      end

      def emit_underlay(entities, points, material, center: nil)
        return if points.length < 3

        center ||= [
          points.sum { |point| point[0] } / points.length.to_f,
          points.sum { |point| point[1] } / points.length.to_f,
          points.sum { |point| point[2] } / points.length.to_f
        ]
        points.each_with_index do |point, index|
          add_colored_face(entities, [center, point, points[(index + 1) % points.length]], material)
        end
      end

      def softened_underlay_points(points)
        points.each_with_index.flat_map do |point, index|
          previous_point = points[(index - 1) % points.length]
          next_point = points[(index + 1) % points.length]
          [
            interpolate_point(point, previous_point, UNDERLAY_CORNER_SOFTENING),
            interpolate_point(point, next_point, UNDERLAY_CORNER_SOFTENING)
          ]
        end
      end

      def interpolate_point(first, second, factor)
        first.each_index.map do |index|
          first[index] + ((second[index] - first[index]) * factor)
        end
      end

      def motif_candidates(boundary, rng)
        candidates = grid_candidates(boundary, rng)
        candidates = [polygon_centroid(boundary) + [1.0]] if candidates.empty?
        candidates.first(DEFAULT_MAX_MOTIF_COUNT)
      end

      def grid_candidates(boundary, rng)
        min_x, max_x, min_y, max_y = bounds(boundary)
        spacing = DEFAULT_SPACING
        candidates = []
        4.times do
          candidates = grid_candidates_for(
            min_x: min_x,
            max_x: max_x,
            min_y: min_y,
            max_y: max_y,
            spacing: spacing,
            boundary: boundary,
            rng: rng
          )
          break if candidates.length >= DEFAULT_MIN_MOTIF_COUNT

          spacing /= 1.5
        end
        candidates
      end

      def grid_candidates_for(min_x:, max_x:, min_y:, max_y:, spacing:, boundary:, rng:)
        xs = grid_values(min_x + (spacing / 2.0), max_x, spacing)
        ys = grid_values(min_y + (spacing / 2.0), max_y, spacing)
        xs.product(ys)
          .filter_map { |point| jittered_candidate(point, boundary, spacing, rng) }
          .shuffle(random: rng)
      end

      def grid_values(start_value, max_value, spacing)
        values = []
        value = start_value
        while value < max_value
          values << value
          value += spacing
        end
        values
      end

      def bounds(points)
        xs = points.map(&:first)
        ys = points.map { |point| point[1] }
        [xs.min, xs.max, ys.min, ys.max]
      end

      def polygon_centroid(points)
        [
          points.sum { |point| point[0] } / points.length.to_f,
          points.sum { |point| point[1] } / points.length.to_f
        ]
      end

      def jittered_candidate(point, boundary, spacing, rng)
        jittered = [
          point[0] + rng.rand((-spacing * 0.32)..(spacing * 0.32)),
          point[1] + rng.rand((-spacing * 0.32)..(spacing * 0.32))
        ]
        return nil unless point_in_polygon?(jittered, boundary)

        edge_distance = distance_to_polygon_edge(jittered[0], jittered[1], boundary)
        edge_factor = (edge_distance / DEFAULT_EDGE_FADE).clamp(0.0, 1.0)
        return nil if rng.rand > (0.18 + (edge_factor * 0.72))

        jittered + [edge_factor]
      end

      def placement_for_candidate(candidate, rng, origin:, x_axis:, y_axis:, up_axis:)
        definition_key = choose_definition(candidate[2], rng)
        yaw = rng.rand(0.0...(Math::PI * 2.0))
        scale_x, scale_y, scale_z = instance_scale_values(definition_key, candidate[2], rng)
        scaled_x = scale_axis(rotated_axis(x_axis, y_axis, yaw), scale_x)
        scaled_y = scale_axis(rotated_axis(y_axis, x_axis, -yaw), scale_y)
        scaled_up = scale_axis(up_axis, scale_z)
        {
          definition_key: definition_key,
          origin: origin,
          x_axis: scaled_x,
          y_axis: scaled_y,
          up_axis: scaled_up
        }
      end

      def choose_definition(edge_factor, rng)
        return :edge_motif if edge_factor < 0.22 && rng.rand < 0.72

        roll = rng.rand
        return :matrix_motif if roll < 0.54
        return :grass_motif if roll < 0.80
        return :edge_motif if roll < 0.93

        :perennial_motif
      end

      def instance_scale_values(definition_key, edge_factor, rng)
        edge_scale = 0.72 + (edge_factor * 0.32)
        base = case definition_key
               when :matrix_motif then rng.rand(0.82..1.18)
               when :edge_motif then rng.rand(0.68..1.06)
               when :grass_motif then rng.rand(0.76..1.14)
               when :perennial_motif then rng.rand(0.74..1.04)
               else rng.rand(0.80..1.10)
               end
        base *= edge_scale
        [
          base * rng.rand(0.84..1.18),
          base * rng.rand(0.82..1.16),
          base * rng.rand(0.82..1.12)
        ]
      end

      def deterministic_rng(payload:, boundary:)
        seed_text = [
          payload.fetch('plantingCategory', 'generic'),
          payload.fetch('averageHeight'),
          payload.fetch('elevation', 'surface'),
          boundary.map { |point| point.map { |value| format('%.6f', value) }.join(',') }.join('|')
        ].join('|')
        Random.new(seed_text.each_byte.reduce(17) do |accumulator, byte|
          ((accumulator * 31) + byte) & 0x7fffffff
        end)
      end

      def point_in_polygon?(point, polygon)
        x_value, y_value = point
        inside = false
        j = polygon.length - 1
        polygon.each_index do |i|
          xi, yi = polygon[i]
          xj, yj = polygon[j]
          intersects = ((yi > y_value) != (yj > y_value)) &&
                       (x_value < ((xj - xi) * (y_value - yi) / (yj - yi)) + xi)
          inside = !inside if intersects
          j = i
        end
        inside
      end

      def transformation_for(placement)
        origin = placement.fetch(:origin)
        transformation = Geom::Transformation.axes(
          point(origin),
          vector(placement.fetch(:x_axis)),
          vector(placement.fetch(:y_axis)),
          vector(placement.fetch(:up_axis))
        )
        return transformation if transformation.respond_to?(:origin) && transformation.origin

        placement
      rescue StandardError
        placement
      end

      def point(values)
        Geom::Point3d.new(values[0], values[1], values[2])
      end

      def vector(values)
        Geom::Vector3d.new(values[0], values[1], values[2])
      end

      def planting_materials(materials)
        {
          leaf_1: material(materials, 'EXP planting mass leaf olive', [82, 126, 83]),
          leaf_2: material(materials, 'EXP planting mass leaf bluegreen', [92, 143, 119]),
          leaf_3: material(materials, 'EXP planting mass young green', [132, 164, 88]),
          grass_1: material(materials, 'EXP planting mass grass gold green', [156, 151, 82]),
          grass_2: material(materials, 'EXP planting mass grass fresh green', [112, 151, 79]),
          flower: material(materials, 'EXP planting mass muted flower accent', [183, 151, 204]),
          stem: material(materials, 'EXP planting mass seed stem', [118, 100, 70]),
          underlay: material(materials, 'EXP planting mass translucent underlay', [70, 118, 78],
                             alpha: 0.35)
        }
      end

      def material(materials, name, rgb, alpha: nil)
        material = materials[name] || materials.add(name)
        if defined?(Sketchup::Color) && material.respond_to?(:color=)
          material.color = Sketchup::Color.new(*rgb)
        end
        material.alpha = alpha if alpha && material.respond_to?(:alpha=)
        material
      end

      def leaf_cluster_geometry(entities, materials, x_value, y_value, z_value, rotation, scale,
                                variant: 0)
        7.times do |index|
          angle = rotation + (Math::PI * 2.0 * index / 7.0) + (index.even? ? 0.08 : -0.06)
          length = m((index.even? ? 0.20 : 0.15) * scale)
          width = m((index.even? ? 0.055 : 0.044) * scale)
          leaf_z = z_value + m((index.even? ? 0.010 : 0.020) * scale)
          add_simple_leaf(
            entities,
            angle,
            length,
            width,
            leaf_z,
            materials[((index + variant) % 3).zero? ? :leaf_3 : :leaf_1],
            offset: [x_value, y_value, 0.0],
            scale: scale
          )
        end
        add_low_poly_mound(entities, m(0.16 * scale), m(0.10 * scale), m(0.030 * scale), 7, materials[:leaf_2],
                           offset: [x_value, y_value, z_value])
      end

      def edge_fragment_geometry(entities, materials, x_value, y_value, z_value, rotation, scale)
        [-0.35, 0.12, 0.58].each_with_index do |angle, index|
          add_simple_leaf(
            entities,
            rotation + angle,
            m((0.16 - (index * 0.018)) * scale),
            m(0.042 * scale),
            z_value + m((0.006 + (index * 0.006)) * scale),
            materials[:leaf_2],
            offset: [x_value, y_value, 0.0],
            scale: scale
          )
        end
      end

      def grass_fan_geometry(entities, materials, x_value, y_value, z_value, rotation, scale)
        9.times do |index|
          angle = rotation - 0.95 + (index * 0.24)
          length = m((0.34 + ((index % 3) * 0.05)) * scale)
          width = m((0.028 + ((index % 2) * 0.006)) * scale)
          lean = -0.10 + (index * 0.025)
          add_grass_blade(entities, angle, length, width, z_value, lean,
                          index.even? ? materials[:grass_1] : materials[:grass_2],
                          offset: [x_value, y_value, 0.0])
        end
      end

      def perennial_mound_geometry(entities, materials, x_value, y_value, z_value, rotation, scale)
        add_low_poly_mound(entities, m(0.28 * scale), m(0.22 * scale), m(0.26 * scale), 9, materials[:leaf_1],
                           offset: [x_value, y_value, z_value])
        5.times do |index|
          angle = rotation + (Math::PI * 2.0 * index / 5.0)
          stem_x = x_value + m(Math.cos(angle) * 0.12 * scale)
          stem_y = y_value + m(Math.sin(angle) * 0.10 * scale)
          add_seed_stem(entities, stem_x, stem_y, z_value + m(0.24 * scale),
                        z_value + m((0.42 + ((index % 2) * 0.08)) * scale),
                        materials[:stem], materials[:flower], scale: scale)
        end
      end

      def add_simple_leaf(entities, angle, length, half_width, z_value, material,
                          offset: [0.0, 0.0, 0.0], scale: 1.0)
        origin_x, origin_y, origin_z = offset
        direction = [Math.cos(angle), Math.sin(angle), 0.0]
        side = [-Math.sin(angle), Math.cos(angle), 0.0]
        base = [origin_x, origin_y, origin_z + z_value]
        left = [
          origin_x + (direction[0] * length * 0.44) + (side[0] * half_width),
          origin_y + (direction[1] * length * 0.44) + (side[1] * half_width),
          origin_z + z_value + m(0.018 * scale)
        ]
        right = [
          origin_x + (direction[0] * length * 0.44) - (side[0] * half_width),
          origin_y + (direction[1] * length * 0.44) - (side[1] * half_width),
          origin_z + z_value + m(0.012 * scale)
        ]
        tip = [origin_x + (direction[0] * length), origin_y + (direction[1] * length),
               origin_z + z_value + m(0.040 * scale)]
        add_colored_face(entities, [base, left, tip], material)
        add_colored_face(entities, [base, tip, right], material)
      end

      def add_grass_blade(entities, angle, length, half_width, z_value, lean, material,
                          offset: [0.0, 0.0, 0.0])
        origin_x, origin_y, origin_z = offset
        direction = [Math.cos(angle), Math.sin(angle), 0.0]
        side = [-Math.sin(angle), Math.cos(angle), 0.0]
        lean_direction = [Math.cos(angle + lean), Math.sin(angle + lean), 0.0]
        base_left = [origin_x + (side[0] * half_width), origin_y + (side[1] * half_width),
                     origin_z + z_value]
        base_right = [origin_x - (side[0] * half_width), origin_y - (side[1] * half_width),
                      origin_z + z_value]
        mid_left = [
          origin_x + (direction[0] * length * 0.42) + (side[0] * half_width * 0.62),
          origin_y + (direction[1] * length * 0.42) + (side[1] * half_width * 0.62),
          origin_z + z_value + (length * 0.46)
        ]
        mid_right = [
          origin_x + (direction[0] * length * 0.42) - (side[0] * half_width * 0.62),
          origin_y + (direction[1] * length * 0.42) - (side[1] * half_width * 0.62),
          origin_z + z_value + (length * 0.43)
        ]
        tip = [
          origin_x + (lean_direction[0] * length * 0.92),
          origin_y + (lean_direction[1] * length * 0.92),
          origin_z + z_value + (length * 0.72)
        ]
        add_quad_as_triangles(entities, base_left, base_right, mid_right, mid_left, material)
        add_colored_face(entities, [mid_left, mid_right, tip], material)
      end

      def add_low_poly_mound(entities, radius_x, radius_y, height, segments, material,
                             offset: [0.0, 0.0, 0.0])
        origin_x, origin_y, origin_z = offset
        base = ngon_points(origin_x, origin_y, origin_z, radius_x, radius_y, segments)
        shoulder = (0...segments).map do |index|
          angle = Math::PI * 2.0 * (index + 0.25) / segments
          [
            origin_x + (Math.cos(angle) * radius_x * 0.78),
            origin_y + (Math.sin(angle) * radius_y * 0.78),
            origin_z + (height * 0.52)
          ]
        end
        top = [origin_x, origin_y, origin_z + height]
        add_colored_face(entities, base.reverse, material)
        segments.times do |index|
          next_index = (index + 1) % segments
          add_quad_as_triangles(entities, base[index], base[next_index], shoulder[next_index],
                                shoulder[index], material)
          add_colored_face(entities, [shoulder[index], shoulder[next_index], top], material)
        end
      end

      def add_seed_stem(entities, x_value, y_value, z0, z1, stem_material, flower_material,
                        scale: 1.0)
        radius = m(0.010 * scale)
        sides = 5
        bottom = ngon_points(x_value, y_value, z0, radius, radius, sides)
        top = ngon_points(x_value, y_value, z1, radius * 0.72, radius * 0.72, sides)
        sides.times do |index|
          next_index = (index + 1) % sides
          add_quad_as_triangles(entities, bottom[index], bottom[next_index], top[next_index], top[index],
                                stem_material)
        end
        add_low_poly_mound(entities, m(0.030 * scale), m(0.026 * scale), m(0.026 * scale), 6, flower_material,
                           offset: [x_value, y_value, z1])
      end

      def add_quad_as_triangles(entities, first, second, third, fourth, material)
        add_colored_face(entities, [first, second, third], material)
        add_colored_face(entities, [first, third, fourth], material)
      end

      def add_colored_face(entities, points, material)
        face = entities.add_face(*points)
        return unless face

        face.material = material if face.respond_to?(:material=)
        face.back_material = material if face.respond_to?(:back_material=)
        face
      end

      def ngon_points(x_value, y_value, z_value, radius_x, radius_y, sides)
        (0...sides).map do |index|
          angle = Math::PI * 2.0 * index / sides
          [x_value + (Math.cos(angle) * radius_x), y_value + (Math.sin(angle) * radius_y), z_value]
        end
      end

      def distance_to_polygon_edge(x_value, y_value, polygon)
        polygon.each_with_index.map do |point, index|
          next_point = polygon[(index + 1) % polygon.length]
          distance_to_segment(x_value, y_value, point[0], point[1], next_point[0], next_point[1])
        end.min || 0.0
      end

      def distance_to_segment(point_x, point_y, start_x, start_y, end_x, end_y)
        vector_x = end_x - start_x
        vector_y = end_y - start_y
        length_squared = (vector_x * vector_x) + (vector_y * vector_y)
        if length_squared <= 1.0e-9
          return Math.sqrt(((point_x - start_x)**2) + ((point_y - start_y)**2))
        end

        factor = (((point_x - start_x) * vector_x) + ((point_y - start_y) * vector_y)) / length_squared
        clamped = factor.clamp(0.0, 1.0)
        closest_x = start_x + (clamped * vector_x)
        closest_y = start_y + (clamped * vector_y)
        Math.sqrt(((point_x - closest_x)**2) + ((point_y - closest_y)**2))
      end

      def rotated_axis(primary, secondary, yaw)
        [
          (primary[0] * Math.cos(yaw)) + (secondary[0] * Math.sin(yaw)),
          (primary[1] * Math.cos(yaw)) + (secondary[1] * Math.sin(yaw)),
          (primary[2] * Math.cos(yaw)) + (secondary[2] * Math.sin(yaw))
        ]
      end

      def scale_axis(axis, scale)
        axis.map { |component| component.to_f * scale.to_f }
      end

      def invalid_hosting_target_refusal
        BuilderRefusal.new(
          code: 'invalid_hosting_target',
          message: 'Hosting target does not expose sampleable terrain geometry.',
          details: { section: 'hosting', role: 'planting_mass' }
        )
      end

      def terrain_sample_miss_refusal(role, xy)
        BuilderRefusal.new(
          code: 'terrain_sample_miss',
          message: 'Terrain sampling missed for planting mass proxy geometry.',
          details: { section: 'hosting', role: role, xy: xy }
        )
      end
    end
  end
end

# rubocop:enable Metrics/ClassLength, Metrics/AbcSize, Metrics/ParameterLists, Naming/VariableNumber, Layout/LineLength
