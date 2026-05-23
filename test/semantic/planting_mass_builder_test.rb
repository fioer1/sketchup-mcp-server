# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/semantic_test_support'
require_relative '../../src/su_mcp/semantic/planting_mass_builder'

class PlantingMassBuilderTest < Minitest::Test
  include SemanticTestSupport

  def setup
    @model = build_semantic_model
    @builder = SU_MCP::Semantic::PlantingMassBuilder.new
  end

  def test_build_creates_a_planting_mass_from_boundary_and_average_height
    group = @builder.build(
      model: @model,
      params: {
        'elementType' => 'planting_mass',
        'sceneProperties' => {
          'name' => 'Hedge Mass'
        },
        'definition' => {
          'mode' => 'mass_polygon',
          'boundary' => [[0.0, 0.0], [4.0, 0.0], [4.0, 2.0], [0.0, 2.0]],
          'averageHeight' => 1.8,
          'plantingCategory' => 'hedge',
          'elevation' => 0.0
        }
      }
    )

    assert_instance_of(SemanticTestSupport::FakeGroup, group)
    assert_equal(1, group.entities.faces.length)
    assert_equal([1.8], group.entities.faces.first.pushpull_calls)
    assert_equal('Hedge Mass', group.name)
  end

  def test_build_creates_planting_mass_into_supplied_destination_collection
    parent_group = @model.active_entities.add_group

    group = @builder.build(
      model: @model,
      destination: parent_group.entities,
      params: {
        'elementType' => 'planting_mass',
        'definition' => {
          'mode' => 'mass_polygon',
          'boundary' => [[0.0, 0.0], [4.0, 0.0], [4.0, 2.0], [0.0, 2.0]],
          'averageHeight' => 1.8
        }
      }
    )

    assert_same(group, parent_group.entities.groups.last)
    assert_equal(1, @model.active_entities.groups.length)
  end

  def test_proxy_mass_build_creates_repeated_motifs_and_underlay_without_pushpull_prism
    group = @builder.build(
      model: @model,
      params: proxy_mass_params
    )

    assert_instance_of(SemanticTestSupport::FakeGroup, group)
    assert_operator(group.entities.component_instances.length, :>=, 12)
    assert_softened_exp_underlay(group)
    assert_empty(group.entities.faces.flat_map(&:pushpull_calls))
    assert_equal(4, @model.definitions.length)
    assert_equal('planting_motif',
                 group.entities.component_instances.first.definition
                      .get_attribute('su_mcp_generated_component', 'family'))
    assert_rich_motif_definitions
    assert_operator(unique_instance_definition_count(group), :>, 1)
  end

  def test_proxy_mass_build_is_deterministic_for_same_request
    first = @builder.build(model: @model, params: proxy_mass_params)
    second = @builder.build(model: @model, params: proxy_mass_params)

    assert_equal(
      instance_origins(first),
      instance_origins(second)
    )
    assert_equal(4, @model.definitions.length)
  end

  def test_surface_drape_proxy_samples_terrain_and_refuses_before_wrapper_on_miss
    terrain = terrain_surface(x_range: [0.0, 220.0], y_range: [0.0, 180.0], z: 4.0,
                              slope_x: 0.02)
    group = @builder.build(
      model: @model,
      params: proxy_mass_params(
        'hosting' => {
          'mode' => 'surface_drape',
          'resolved_target' => terrain
        }
      )
    )

    underlay_zs = group.entities.faces.flat_map { |face| face.points.map { |point| point[2] } }
    assert_operator(underlay_zs.max - underlay_zs.min, :>, 1.0)

    missing_terrain = terrain_surface(x_range: [500.0, 520.0], y_range: [500.0, 520.0], z: 4.0)
    groups_before_miss = @model.active_entities.groups.length
    assert_raises(SU_MCP::Semantic::BuilderRefusal) do
      @builder.build(
        model: @model,
        params: proxy_mass_params(
          'hosting' => {
            'mode' => 'surface_drape',
            'resolved_target' => missing_terrain
          }
        )
      )
    end
    assert_equal(groups_before_miss, @model.active_entities.groups.length)
  end

  private

  def proxy_mass_params(overrides = {})
    deep_merge(
      {
        'elementType' => 'planting_mass',
        'definition' => {
          'mode' => 'mass_polygon',
          'boundary' => [[0.0, 0.0], [220.0, 0.0], [220.0, 180.0], [0.0, 180.0]],
          'averageHeight' => 24.0,
          'plantingCategory' => 'groundcover',
          'elevation' => 3.0
        },
        'representation' => {
          'mode' => 'proxy_mass',
          'material' => 'Meadow'
        },
        'hosting' => {
          'mode' => 'none'
        },
        'metadata' => {
          'sourceElementId' => 'pocket-001'
        }
      },
      overrides
    )
  end

  def terrain_surface(x_range:, y_range:, z:, slope_x: 0.0, slope_y: 0.0)
    face = @model.active_entities.add_face(
      [x_range.first, y_range.first, z],
      [x_range.last, y_range.first, z],
      [x_range.last, y_range.last, z],
      [x_range.first, y_range.last, z]
    )
    face.details[:sample_surface] = {
      x_range: x_range,
      y_range: y_range,
      z: z,
      slope_x: slope_x,
      slope_y: slope_y
    }
    face
  end

  def instance_origins(group)
    group.entities.component_instances.map do |instance|
      transformation = instance.transformation
      if transformation.is_a?(Hash)
        transformation.fetch(:origin).map { |value| value.round(9) }
      elsif transformation.respond_to?(:origin) && transformation.origin
        [transformation.origin.x, transformation.origin.y, transformation.origin.z]
      else
        [0.0, 0.0, 0.0]
      end
    end
  end

  def assert_rich_motif_definitions
    assert_operator(@model.definitions.map { |definition| definition.entities.faces.length }.sum,
                    :>,
                    120)
  end

  def assert_softened_exp_underlay(group)
    assert_equal(8, group.entities.faces.length)
    assert(group.entities.faces.all? do |face|
      face.material.name == 'EXP planting mass translucent underlay'
    end)
  end

  def unique_instance_definition_count(group)
    group.entities.component_instances.map(&:definition).uniq.length
  end

  def deep_merge(base, overrides)
    return base unless overrides.is_a?(Hash)

    base.merge(overrides) do |_key, left, right|
      left.is_a?(Hash) && right.is_a?(Hash) ? deep_merge(left, right) : right
    end
  end
end
