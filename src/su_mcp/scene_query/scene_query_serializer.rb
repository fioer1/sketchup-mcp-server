# frozen_string_literal: true

require_relative '../semantic/managed_object_metadata'
require_relative '../semantic/length_converter'

module SU_MCP
  SCENE_QUERY_TYPE_KEYS = {
    Sketchup::ComponentInstance => 'componentinstance',
    Sketchup::Group => 'group',
    Sketchup::Face => 'face',
    Sketchup::Edge => 'edge',
    Sketchup::Vertex => 'vertex',
    Sketchup::Text => 'text',
    Sketchup::Dimension => 'dimension'
  }.freeze

  # Normalizes SketchUp entities and bounds into MCP-safe hashes.
  class SceneQuerySerializer
    def initialize(length_converter: Semantic::LengthConverter.new)
      @length_converter = length_converter
    end

    def bounds_to_h(bounds)
      return nil unless bounds&.valid?

      {
        min: point_to_a(bounds.min),
        max: point_to_a(bounds.max),
        center: point_to_a(bounds.center),
        size: [safe_float(bounds.width), safe_float(bounds.height), safe_float(bounds.depth)]
      }
    end

    def serialize_entity(entity)
      data = base_entity_data(entity)
      data.merge!(instance_details(entity)) if group_or_component?(entity)
      data.compact
    end

    def entity_type_counts(entities)
      entities.each_with_object(Hash.new(0)) do |entity, counts|
        counts[entity_type_key(entity)] += 1
      end
    end

    def public_surface_entity?(entity)
      !Semantic::ManagedObjectMetadata.placeholder_entity?(entity)
    end

    def serialize_target_match(entity)
      {
        sourceElementId: target_identity_value(entity, 'sourceElementId'),
        persistentId: target_identity_value(entity, 'persistentId'),
        entityId: target_identity_value(entity, 'entityId'),
        type: entity_type_key(entity),
        name: target_attribute_value(entity, 'name'),
        tag: target_attribute_value(entity, 'tag'),
        material: target_attribute_value(entity, 'material')
      }.merge(
        serialize_target_metadata(entity).reject { |key, _| key == :managedSceneObject }
      ).compact
    end

    def serialize_target_metadata(entity)
      metadata = {
        managedSceneObject: target_metadata_value(entity, 'managedSceneObject'),
        semanticType: target_metadata_value(entity, 'semanticType'),
        status: target_metadata_value(entity, 'status'),
        state: target_metadata_value(entity, 'state'),
        structureCategory: target_metadata_value(entity, 'structureCategory')
      }
      metadata.delete_if { |_key, value| value.nil? }
      metadata
    end

    def target_identity_value(entity, key)
      case key
      when 'sourceElementId'
        source_element_id_for(entity)
      when 'persistentId'
        stringify_identifier(persistent_id_for(entity))
      when 'entityId'
        stringify_identifier(entity.entityID)
      end
    end

    def target_source_element_id?(entity, expected_value)
      source_element_id_for(entity) == expected_value
    end

    def target_reference_match?(entity, query)
      return target_source_element_id?(entity, query.fetch('sourceElementId')) \
        if query.keys == ['sourceElementId']

      query.all? { |key, value| target_identity_value(entity, key) == value }
    end

    def target_attribute_value(entity, key)
      case key
      when 'name'
        entity_name(entity)
      when 'tag'
        layer_name(entity)
      when 'material'
        material_name_for(entity)
      end
    end

    def target_metadata_value(entity, key)
      case key
      when 'managedSceneObject'
        managed_scene_object?(entity)
      else
        metadata_value(entity, key)
      end
    end

    def serialize_xy_sample_point(x_value, y_value)
      {
        x: public_meter_value(x_value),
        y: public_meter_value(y_value)
      }
    end

    def serialize_xyz_sample_point(x_value, y_value, z_value)
      serialize_xy_sample_point(x_value, y_value).merge(z: public_meter_value(z_value))
    end

    def serialize_sampling_evidence(evidence)
      serialized = {
        index: evidence.index,
        samplePoint: serialize_xy_sample_point(evidence.x, evidence.y),
        distanceAlongPathMeters: public_meter_value(evidence.distance_along_path_meters),
        pathProgress: public_meter_value(evidence.path_progress),
        status: evidence.status
      }
      if evidence.status == 'hit'
        serialized[:hitPoint] = serialize_xyz_sample_point(evidence.x, evidence.y, evidence.z)
      end
      serialized
    end

    def entity_type_key(entity)
      type_entry = SCENE_QUERY_TYPE_KEYS.find { |klass, _key| entity.is_a?(klass) }
      return type_entry.last if type_entry

      entity.class.name.split('::').last.downcase
    end

    private

    attr_reader :length_converter

    def base_entity_data(entity)
      {
        entityId: stringify_identifier(entity.entityID),
        persistentId: stringify_identifier(persistent_id_for(entity)),
        type: entity_type_key(entity),
        name: entity_name(entity),
        layer: layer_name(entity), material: material_name_for(entity),
        hidden: value_if_supported(entity, :hidden?),
        locked: value_if_supported(entity, :locked?),
        bounds: bounds_to_h(entity.bounds)
      }
    end

    def safe_float(value)
      return value unless value.respond_to?(:to_f)

      rounded_float(length_converter.internal_to_public_meters(value.to_f))
    end

    def point_to_a(point)
      return nil unless point

      [safe_float(point.x), safe_float(point.y), safe_float(point.z)]
    end

    def rounded_float(value)
      precision = configured_length_precision
      return value unless precision

      value.round(precision)
    end

    def configured_length_precision
      model = Sketchup.active_model
      return nil unless model.respond_to?(:options)

      units = model.options['UnitsOptions']
      return nil unless units

      precision = units['LengthPrecision']
      precision.is_a?(Numeric) ? precision.to_i : nil
    rescue StandardError
      nil
    end

    def entity_name(entity)
      name = entity.respond_to?(:name) ? entity.name.to_s : ''
      return name unless name.empty?

      return component_definition_name(entity) if entity.is_a?(Sketchup::ComponentInstance)

      entity_type_label(entity)
    end

    def component_definition_name(entity)
      definition_name = entity.definition&.name.to_s
      definition_name.empty? ? entity_type_label(entity) : definition_name
    end

    def layer_name(entity)
      entity.respond_to?(:layer) && entity.layer ? entity.layer.name : nil
    end

    def material_name_for(entity)
      return nil unless entity.respond_to?(:material)

      material = entity.material
      return nil unless material
      return material.display_name if material.respond_to?(:display_name)
      return material.name if material.respond_to?(:name)

      material.to_s
    end

    def value_if_supported(entity, method_name)
      entity.respond_to?(method_name) ? entity.public_send(method_name) : nil
    end

    def instance_details(entity)
      details = {
        definitionName: component_instance_definition_name(entity),
        childrenCount: entity_children_count(entity)
      }
      if entity.respond_to?(:transformation)
        details[:origin] = point_to_a(entity.transformation.origin)
      end
      details
    end

    def component_instance_definition_name(entity)
      entity.is_a?(Sketchup::ComponentInstance) ? entity.definition&.name : nil
    end

    def entity_children_count(entity)
      case entity
      when Sketchup::Group
        count_non_placeholder_children(entity.entities)
      when Sketchup::ComponentInstance
        count_non_placeholder_children(entity.definition.entities)
      else
        0
      end
    end

    def count_non_placeholder_children(collection)
      Semantic::ManagedObjectMetadata
        .collection_entities(collection)
        .count { |entity| !Semantic::ManagedObjectMetadata.placeholder_entity?(entity) }
    end

    def entity_type_label(entity)
      entity_type_key(entity).capitalize
    end

    def persistent_id_for(entity)
      return nil unless entity.respond_to?(:persistent_id)

      # rubocop:disable SketchupSuggestions/Compatibility
      entity.persistent_id
      # rubocop:enable SketchupSuggestions/Compatibility
    end

    def source_element_id_for(entity)
      return nil unless entity.respond_to?(:get_attribute)

      source_element_id = entity.get_attribute('su_mcp', 'sourceElementId')
      return nil if source_element_id.to_s.empty?

      source_element_id.to_s
    end

    def stringify_identifier(value)
      return nil if value.nil?

      value.to_s
    end

    def metadata_value(entity, key)
      return nil unless entity.respond_to?(:get_attribute)

      value = entity.get_attribute('su_mcp', key)
      return nil if value.to_s.empty?

      value.to_s
    end

    def managed_scene_object?(entity)
      return false if asset_exemplar?(entity)

      !source_element_id_for(entity).nil?
    end

    def asset_exemplar?(entity)
      return false unless entity.respond_to?(:get_attribute)

      entity.get_attribute('su_mcp', 'assetExemplar') == true
    end

    def public_meter_value(value)
      rounded_float(value.to_f)
    end

    def group_or_component?(entity)
      entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
    end
  end
end
