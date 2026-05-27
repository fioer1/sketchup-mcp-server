# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/semantic_test_support'
require_relative '../../src/su_mcp/semantic/retaining_edge_builder'

class RetainingEdgeBuilderTest < Minitest::Test
  include SemanticTestSupport

  class FakeSurfaceSampler
    attr_reader :prepare_context_calls, :sample_z_from_context_calls

    def initialize(sampleable: true, &sample_block)
      @sampleable = sampleable
      @sample_block = sample_block || ->(**_kwargs) { 0.0 }
      @prepare_context_calls = 0
      @sample_z_from_context_calls = 0
    end

    def prepare_context(entity)
      @prepare_context_calls += 1
      { entity: entity, face_entries: @sampleable ? [{}] : [] }
    end

    def sample_z_from_context(context:, **kwargs)
      @sample_z_from_context_calls += 1
      @sample_block.call(
        entity: context.fetch(:entity),
        x_value: kwargs.fetch(:x_value),
        y_value: kwargs.fetch(:y_value)
      )
    end
  end

  def setup
    @model = build_semantic_model
    @builder = SU_MCP::Semantic::RetainingEdgeBuilder.new
  end

  def test_build_creates_a_retaining_edge_mass_from_polyline_height_and_thickness
    group = @builder.build(
      model: @model,
      params: {
        'elementType' => 'retaining_edge',
        'sceneProperties' => {
          'tag' => 'Edges'
        },
        'representation' => {
          'material' => 'Stone'
        },
        'definition' => {
          'mode' => 'polyline',
          'polyline' => [[2.0, 0.0], [8.0, 0.0], [8.0, 4.0]],
          'height' => 0.45,
          'thickness' => 0.25,
          'elevation' => 0.0
        }
      }
    )

    assert_instance_of(SemanticTestSupport::FakeGroup, group)
    assert_equal(1, group.entities.faces.length)
    assert_equal([0.45], group.entities.faces.first.pushpull_calls)
    assert_equal('Edges', group.layer.name)
  end

  def test_build_creates_retaining_edge_into_supplied_destination_collection
    parent_group = @model.active_entities.add_group

    group = @builder.build(
      model: @model,
      destination: parent_group.entities,
      params: {
        'elementType' => 'retaining_edge',
        'definition' => {
          'mode' => 'polyline',
          'polyline' => [[2.0, 0.0], [8.0, 0.0], [8.0, 4.0]],
          'height' => 0.45,
          'thickness' => 0.25
        }
      }
    )

    assert_same(group, parent_group.entities.groups.last)
    assert_equal(1, @model.active_entities.groups.length)
  end

  def test_hosted_edge_clamp_creates_sampled_multi_z_shell_without_planar_pushpull
    sampler = FakeSurfaceSampler.new do |**kwargs|
      kwargs.fetch(:x_value) / 10.0
    end
    builder = SU_MCP::Semantic::RetainingEdgeBuilder.new(
      surface_sampler: sampler,
      station_spacing: 100.0
    )

    group = builder.build(
      model: @model,
      params: {
        'elementType' => 'retaining_edge',
        'definition' => {
          'mode' => 'polyline',
          'polyline' => [[0.0, 0.0], [10.0, 0.0]],
          'height' => 0.45,
          'thickness' => 0.25,
          'elevation' => 99.0
        },
        'hosting' => {
          'mode' => 'edge_clamp',
          'resolved_target' => Object.new
        }
      }
    )

    all_points = group.entities.faces.flat_map(&:points).uniq
    z_values = all_points.map { |point| point[2] }.uniq.sort

    assert_includes(z_values, 0.0)
    assert_includes(z_values, 1.0)
    assert_includes(z_values, 0.45)
    assert_includes(z_values, 1.45)
    assert_empty(group.entities.faces.flat_map(&:pushpull_calls))
    assert_equal(1, sampler.prepare_context_calls)
    assert_operator(sampler.sample_z_from_context_calls, :>=, 2)
  end

  def test_hosted_edge_clamp_refuses_unsampleable_host_without_creating_group
    builder = SU_MCP::Semantic::RetainingEdgeBuilder.new(
      surface_sampler: FakeSurfaceSampler.new(sampleable: false)
    )

    error = assert_raises(SU_MCP::Semantic::BuilderRefusal) do
      builder.build(
        model: @model,
        params: hosted_retaining_edge_params
      )
    end

    assert_equal('invalid_hosting_target', error.code)
    assert_equal('hosting', error.details[:section])
    assert_empty(@model.active_entities.groups)
  end

  def test_hosted_edge_clamp_refuses_station_sample_miss_without_creating_group
    sampler = FakeSurfaceSampler.new do |**kwargs|
      kwargs.fetch(:x_value).zero? ? 0.0 : nil
    end
    builder = SU_MCP::Semantic::RetainingEdgeBuilder.new(surface_sampler: sampler)

    error = assert_raises(SU_MCP::Semantic::BuilderRefusal) do
      builder.build(
        model: @model,
        params: hosted_retaining_edge_params
      )
    end

    assert_equal('terrain_sample_miss', error.code)
    assert_equal('hosting', error.details[:section])
    assert_empty(@model.active_entities.groups)
  end

  def test_hosted_edge_clamp_refuses_station_limit_without_creating_group
    builder = SU_MCP::Semantic::RetainingEdgeBuilder.new(
      surface_sampler: FakeSurfaceSampler.new,
      station_spacing: 1.0,
      station_limit: 2
    )

    error = assert_raises(SU_MCP::Semantic::BuilderRefusal) do
      builder.build(
        model: @model,
        params: hosted_retaining_edge_params
      )
    end

    assert_equal('linear_edge_tessellation_limit_exceeded', error.code)
    assert_equal('definition.polyline', error.details[:field])
    assert_empty(@model.active_entities.groups)
  end

  def test_hides_internal_generated_edges_without_hiding_boundary_edges
    internal_edge = SemanticTestSupport::FakeEdge.new
    internal_edge.faces = [fake_face_normal(0.0, 0.0, 1.0), fake_face_normal(0.0, 0.0, 1.0)]
    hard_edge = SemanticTestSupport::FakeEdge.new
    hard_edge.faces = [fake_face_normal(0.0, 0.0, 1.0), fake_face_normal(1.0, 0.0, 0.0)]
    boundary_edge = SemanticTestSupport::FakeEdge.new
    boundary_edge.faces = [fake_face_normal(0.0, 0.0, 1.0)]

    @builder.send(:hide_internal_edges, [internal_edge, hard_edge, boundary_edge])

    assert(internal_edge.hidden?)
    refute(hard_edge.hidden?)
    refute(boundary_edge.hidden?)
  end

  private

  def fake_face_normal(x_value, y_value, z_value)
    normal = Struct.new(:x, :y, :z).new(x_value, y_value, z_value)
    Struct.new(:normal).new(normal)
  end

  def hosted_retaining_edge_params
    {
      'elementType' => 'retaining_edge',
      'definition' => {
        'mode' => 'polyline',
        'polyline' => [[0.0, 0.0], [10.0, 0.0]],
        'height' => 0.45,
        'thickness' => 0.25
      },
      'hosting' => {
        'mode' => 'edge_clamp',
        'resolved_target' => Object.new
      }
    }
  end
end
