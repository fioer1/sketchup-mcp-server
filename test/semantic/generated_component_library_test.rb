# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/semantic_test_support'
require_relative '../../src/su_mcp/semantic/builder_refusal'
require_relative '../../src/su_mcp/semantic/generated_component_library'

class GeneratedComponentLibraryTest < Minitest::Test
  include SemanticTestSupport

  def setup
    @model = build_semantic_model
    @library = SU_MCP::Semantic::GeneratedComponentLibrary.new
  end

  def test_creates_owned_definition_with_stable_identity_attributes
    definition = @library.definition_for(
      model: @model,
      family: 'tree_proxy',
      version: '1',
      signature: 'height=5.5',
      generator: 'TreeProxyBuilder'
    ) do |entities|
      entities.add_face([0, 0, 0], [1, 0, 0], [0, 1, 0])
    end

    assert_equal(1, @model.definitions.length)
    assert_equal(definition, @model.definitions[definition.name])
    assert_equal('su_mcp.semantic.generated',
                 definition.get_attribute('su_mcp_generated_component', 'namespace'))
    assert_equal('tree_proxy', definition.get_attribute('su_mcp_generated_component', 'family'))
    assert_equal('1', definition.get_attribute('su_mcp_generated_component', 'version'))
    assert_equal('height=5.5',
                 definition.get_attribute('su_mcp_generated_component', 'signature'))
    assert_equal(1, definition.entities.faces.length)
  end

  def test_reuses_matching_owned_definition_without_rebuilding_geometry
    first = @library.definition_for(
      model: @model,
      family: 'planting_motif',
      version: '1',
      signature: 'groundcover'
    ) { |entities| entities.add_face([0, 0, 0], [1, 0, 0], [0, 1, 0]) }

    second = @library.definition_for(
      model: @model,
      family: 'planting_motif',
      version: '1',
      signature: 'groundcover'
    ) { |entities| entities.add_face([0, 0, 0], [2, 0, 0], [0, 2, 0]) }

    assert_same(first, second)
    assert_equal(1, first.entities.faces.length)
  end

  def test_reuses_matching_owned_definition_when_index_lookup_returns_nil
    definitions_class = Class.new(SemanticTestSupport::FakeDefinitionsCollection) do
      def [](_name)
        nil
      end
    end
    definitions = definitions_class.new(
      id_sequence: SemanticTestSupport::IdSequence.new,
      layer: SceneQueryTestSupport::FakeLayer.new('Layer0'),
      material: SceneQueryTestSupport::FakeMaterial.new('Default')
    )
    model = Struct.new(:definitions).new(definitions)
    first = @library.definition_for(
      model: model,
      family: 'planting_motif',
      version: '1',
      signature: 'fallback'
    ) { |entities| entities.add_face([0, 0, 0], [1, 0, 0], [0, 1, 0]) }

    second = @library.definition_for(
      model: model,
      family: 'planting_motif',
      version: '1',
      signature: 'fallback'
    ) { |entities| entities.add_face([0, 0, 0], [2, 0, 0], [0, 2, 0]) }

    assert_same(first, second)
    assert_equal(1, definitions.length)
    assert_equal(1, first.entities.faces.length)
  end

  def test_refuses_to_reuse_unowned_definition_with_matching_name
    name = @library.definition_name(family: 'tree_proxy', version: '1', signature: 'abc')
    @model.definitions.add(name)

    refusal = assert_raises(SU_MCP::Semantic::BuilderRefusal) do
      @library.definition_for(
        model: @model,
        family: 'tree_proxy',
        version: '1',
        signature: 'abc'
      ) { |entities| entities.add_cpoint([0.0, 0.0, 0.0]) }
    end

    assert_equal('generated_definition_ownership_conflict', refusal.code)
    assert_equal({ family: 'tree_proxy', version: '1', signature: 'abc' }, refusal.details)
  end

  def test_removes_new_owned_definition_when_build_block_fails
    assert_raises(RuntimeError) do
      @library.definition_for(
        model: @model,
        family: 'planting_motif',
        version: '1',
        signature: 'broken'
      ) do |entities|
        entities.add_face([0, 0, 0], [1, 0, 0], [0, 1, 0])
        raise 'boom'
      end
    end

    assert_equal(0, @model.definitions.length)
    assert_equal(1, @model.definitions.removed_definitions.length)
  end
end
