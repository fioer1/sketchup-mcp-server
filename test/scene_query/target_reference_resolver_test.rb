# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/scene_query_test_support'
require_relative '../../src/su_mcp/scene_query/target_reference_resolver'

class TargetReferenceResolverTest < Minitest::Test
  include SceneQueryTestSupport

  def setup
    @model = build_metadata_target_model
    Sketchup.active_model_override = @model
    @resolver = SU_MCP::TargetReferenceResolver.new
  end

  def teardown
    Sketchup.active_model_override = nil
  end

  def test_resolves_nested_managed_object_by_source_element_id
    result = @resolver.resolve('sourceElementId' => 'garden-shed-001')

    assert_equal('unique', result[:resolution])
    assert_equal(702, result.fetch(:entity).entityID)
  end

  def test_resolves_nested_managed_object_by_entity_id
    result = @resolver.resolve('entityId' => '702')

    assert_equal('unique', result[:resolution])
    assert_equal(7002, result.fetch(:entity).persistent_id)
  end

  def test_resolves_entity_id_with_direct_model_lookup_without_recursive_traversal
    entity = build_scene_query_group(
      entity_id: 812,
      origin_x: 0,
      layer: FakeLayer.new('Structures'),
      material: FakeMaterial.new('Timber'),
      details: { persistent_id: 8812 }
    )
    adapter = FastLookupAdapter.new(entity_by_id: entity)
    resolver = SU_MCP::TargetReferenceResolver.new(adapter: adapter)

    result = resolver.resolve('entityId' => '812')

    assert_equal('unique', result[:resolution])
    assert_same(entity, result.fetch(:entity))
    assert_equal([[:find_entity_by_id, '812']], adapter.calls)
  end

  def test_resolves_persistent_id_with_native_lookup_without_recursive_traversal
    entity = build_scene_query_group(
      entity_id: 813,
      origin_x: 0,
      layer: FakeLayer.new('Structures'),
      material: FakeMaterial.new('Timber'),
      details: { persistent_id: 8813 }
    )
    adapter = FastLookupAdapter.new(entity_by_persistent_id: entity)
    resolver = SU_MCP::TargetReferenceResolver.new(adapter: adapter)

    result = resolver.resolve('persistentId' => '8813')

    assert_equal('unique', result[:resolution])
    assert_same(entity, result.fetch(:entity))
    assert_equal([[:find_entity_by_persistent_id, '8813']], adapter.calls)
  end

  def test_resolve_container_ignores_native_entity_id_match_when_entity_is_not_container
    face = build_scene_query_face(
      entity_id: 815,
      origin_x: 1,
      layer: FakeLayer.new('Structures'),
      material: FakeMaterial.new('Timber'),
      details: { persistent_id: 8815 }
    )
    adapter = FastLookupAdapter.new(entity_by_id: face)
    resolver = SU_MCP::TargetReferenceResolver.new(adapter: adapter)

    result = resolver.resolve_container('entityId' => '815')

    assert_equal('none', result[:resolution])
    refute_includes(result.keys, :entity)
    assert_equal([[:find_entity_by_id, '815']], adapter.calls)
  end

  def test_resolve_container_ignores_native_persistent_id_match_when_entity_is_not_container
    face = build_scene_query_face(
      entity_id: 816,
      origin_x: 1,
      layer: FakeLayer.new('Structures'),
      material: FakeMaterial.new('Timber'),
      details: { persistent_id: 8816 }
    )
    adapter = FastLookupAdapter.new(entity_by_persistent_id: face)
    resolver = SU_MCP::TargetReferenceResolver.new(adapter: adapter)

    result = resolver.resolve_container('persistentId' => '8816')

    assert_equal('none', result[:resolution])
    refute_includes(result.keys, :entity)
    assert_equal([[:find_entity_by_persistent_id, '8816']], adapter.calls)
  end

  def test_resolves_container_source_element_id_without_recursive_entity_scan
    layer = FakeLayer.new('Structures')
    material = FakeMaterial.new('Timber')
    parent = build_scene_query_group(
      entity_id: 814,
      origin_x: 0,
      layer: layer,
      material: material,
      details: {
        persistent_id: 8814,
        attributes: { 'su_mcp' => { 'sourceElementId' => 'parent-container-001' } }
      }
    )
    lower_level_duplicate = build_scene_query_face(
      entity_id: 815,
      origin_x: 1,
      layer: layer,
      material: material,
      details: {
        persistent_id: 8815,
        attributes: { 'su_mcp' => { 'sourceElementId' => 'parent-container-001' } }
      }
    )
    adapter = FastLookupAdapter.new(
      container_entities: [parent],
      recursive_entities: [parent, lower_level_duplicate]
    )
    resolver = SU_MCP::TargetReferenceResolver.new(adapter: adapter)

    result = resolver.resolve_container('sourceElementId' => 'parent-container-001')

    assert_equal('unique', result[:resolution])
    assert_same(parent, result.fetch(:entity))
    assert_equal([:group_component_entities_recursive], adapter.calls)
  end

  def test_resolve_container_preserves_ambiguity_for_duplicate_container_source_element_ids
    layer = FakeLayer.new('Structures')
    material = FakeMaterial.new('Timber')
    first_parent = build_scene_query_group(
      entity_id: 817,
      origin_x: 0,
      layer: layer,
      material: material,
      details: {
        persistent_id: 8817,
        attributes: { 'su_mcp' => { 'sourceElementId' => 'duplicate-parent-001' } }
      }
    )
    second_parent = build_scene_query_group(
      entity_id: 818,
      origin_x: 2,
      layer: layer,
      material: material,
      details: {
        persistent_id: 8818,
        attributes: { 'su_mcp' => { 'sourceElementId' => 'duplicate-parent-001' } }
      }
    )
    adapter = FastLookupAdapter.new(container_entities: [first_parent, second_parent])
    resolver = SU_MCP::TargetReferenceResolver.new(adapter: adapter)

    result = resolver.resolve_container('sourceElementId' => 'duplicate-parent-001')

    assert_equal('ambiguous', result[:resolution])
    refute_includes(result.keys, :entity)
    assert_equal([:group_component_entities_recursive], adapter.calls)
  end

  def test_verifies_unique_container_source_element_id_with_recursive_scan
    adapter = FastLookupAdapter.new(entity_by_source_element_id: @model.entities.last)
    resolver = SU_MCP::TargetReferenceResolver.new(adapter: adapter)

    result = resolver.resolve('sourceElementId' => 'duplicate-managed-001')

    assert_equal('unique', result[:resolution])
    assert_equal(%i[group_component_entities_recursive all_entities_recursive], adapter.calls)
  end

  def test_returns_none_when_no_entity_matches
    result = @resolver.resolve('sourceElementId' => 'missing-element-001')

    assert_equal('none', result[:resolution])
    refute_includes(result.keys, :entity)
  end

  def test_returns_ambiguous_when_multiple_entities_match
    result = @resolver.resolve('sourceElementId' => 'duplicate-managed-001')

    assert_equal('ambiguous', result[:resolution])
    refute_includes(result.keys, :entity)
  end

  def test_raises_field_aware_error_for_unsupported_reference_fields
    error = assert_raises(SU_MCP::TargetReferenceResolver::InvalidReference) do
      @resolver.resolve('legacyId' => '702')
    end

    assert_equal('unsupported_request_field', error.code)
    assert_equal('targetReference.legacyId', error.details.fetch(:field))
    assert_equal(%w[sourceElementId persistentId entityId], error.details.fetch(:allowedFields))
  end

  private

  class FastLookupAdapter
    attr_reader :calls

    def initialize(
      entity_by_id: nil,
      entity_by_persistent_id: nil,
      entity_by_source_element_id: nil,
      container_entities: nil,
      recursive_entities: nil
    )
      @entity_by_id = entity_by_id
      @entity_by_persistent_id = entity_by_persistent_id
      @entity_by_source_element_id = entity_by_source_element_id
      @container_entities = container_entities
      @recursive_entities = recursive_entities
      @calls = []
    end

    def find_entity_by_id(id)
      @calls << [:find_entity_by_id, id]
      @entity_by_id
    end

    def find_entity_by_persistent_id(persistent_id)
      @calls << [:find_entity_by_persistent_id, persistent_id]
      @entity_by_persistent_id
    end

    def all_entities_recursive
      @calls << :all_entities_recursive
      @recursive_entities || [@entity_by_source_element_id].compact
    end

    def group_component_entities_recursive
      @calls << :group_component_entities_recursive
      @container_entities || [@entity_by_source_element_id].compact
    end
  end

  def build_metadata_target_model
    layer = FakeLayer.new('Structures')
    material = FakeMaterial.new('Timber')

    nested_managed = build_scene_query_group(
      entity_id: 702,
      origin_x: 12,
      layer: layer,
      material: material,
      details: {
        name: 'Garden Shed',
        persistent_id: 7002,
        entities: [],
        attributes: { 'su_mcp' => { 'sourceElementId' => 'garden-shed-001' } }
      }
    )
    duplicate_one = build_scene_query_group(
      entity_id: 703,
      origin_x: 16,
      layer: layer,
      material: material,
      details: {
        name: 'Duplicate A',
        persistent_id: 7003,
        entities: [],
        attributes: { 'su_mcp' => { 'sourceElementId' => 'duplicate-managed-001' } }
      }
    )
    duplicate_two = build_scene_query_group(
      entity_id: 704,
      origin_x: 20,
      layer: layer,
      material: material,
      details: {
        name: 'Duplicate B',
        persistent_id: 7004,
        entities: [],
        attributes: { 'su_mcp' => { 'sourceElementId' => 'duplicate-managed-001' } }
      }
    )
    parent_group = build_scene_query_group(
      entity_id: 701,
      origin_x: 10,
      layer: layer,
      material: material,
      details: {
        name: 'Organization Group',
        persistent_id: 7001,
        entities: [nested_managed, duplicate_one]
      }
    )

    FakeModel.new(
      state: {
        entities: [parent_group, duplicate_two],
        active_entities: [],
        selection: [],
        materials: [material],
        layers: [layer],
        bounds: build_bounds(origin_x: -5)
      },
      details: { options: default_options }
    )
  end
end
