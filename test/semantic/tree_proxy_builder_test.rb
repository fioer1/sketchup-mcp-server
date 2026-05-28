# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/semantic_test_support'
require_relative '../../src/su_mcp/semantic/builder_refusal'
require_relative '../../src/su_mcp/semantic/tree_proxy_builder'

class TreeProxyBuilderTest < Minitest::Test
  include SemanticTestSupport

  class FakeTerrainAnchorResolver
    attr_reader :calls

    def initialize(sample_z: 10.0, refusal: nil)
      @sample_z = sample_z
      @refusal = refusal
      @calls = []
    end

    def resolve(host_target:, anchor_xy:, role:)
      @calls << { host_target: host_target, anchor_xy: anchor_xy, role: role }
      raise @refusal if @refusal

      @sample_z
    end
  end

  def setup
    @model = build_semantic_model
    @builder = SU_MCP::Semantic::TreeProxyBuilder.new
  end

  def test_build_creates_a_varied_boulder_canopy_tree_proxy_mesh
    group = build_cherry_proxy

    assert_tree_wrapper(group)
    assert_generated_tree_definition(proxy_definition_for(group))
    assert_tree_mesh_geometry(proxy_definition_for(group))
  end

  def test_build_varies_soft_irregular_canopy_by_source_identity
    first_faces = tree_proxy_points_for('tree-seed-a')
    second_faces = tree_proxy_points_for('tree-seed-b')

    refute_equal(first_faces, second_faces)
  end

  def test_build_extends_stem_to_high_canopy_profiles
    group = tree_proxy_group_for('squat-test-0')
    proxy_mesh = proxy_definition_for(group)

    assert_includes(
      proxy_mesh.get_attribute('su_mcp_generated_component', 'signature'),
      'profile=squat_block'
    )

    cap_levels = horizontal_trunk_cap_levels(proxy_mesh)
    canopy_base_level = canopy_cap_levels(proxy_mesh).min

    assert_operator(cap_levels.last, :>, 5.5 * SU_MCP::Semantic::TreeProxyBuilder::TRUNK_TOP_RATIO)
    assert_operator(cap_levels.last, :>=, canopy_base_level)
  end

  def test_build_preserves_existing_tree_material_colors
    trunk_material = SceneQueryTestSupport::FakeMaterial.new('Codex-Tree-Trunk')
    trunk_material.color = [1, 2, 3]
    canopy_material = SceneQueryTestSupport::FakeMaterial.new('Codex-Tree-Canopy')
    canopy_material.color = [4, 5, 6]
    model = SemanticTestSupport::FakeModel.new(
      materials: SceneQueryTestSupport::FakeMaterialCollection.new([
                                                                     SceneQueryTestSupport::FakeMaterial.new('Default'),
                                                                     trunk_material,
                                                                     canopy_material
                                                                   ])
    )

    @builder.build(model: model, params: tree_proxy_params_for('material-seed'))

    assert_equal([1, 2, 3], trunk_material.color)
    assert_equal([4, 5, 6], canopy_material.color)
  end

  def test_build_reuses_definition_for_same_shape_seed_and_varies_definition_by_source_identity
    first_group = tree_proxy_group_for(
      'cache-seed',
      position: { 'x' => 14.0, 'y' => 37.7, 'z' => 0.0 }
    )
    second_group = tree_proxy_group_for(
      'cache-seed',
      position: { 'x' => -8.0, 'y' => 12.0, 'z' => 0.0 }
    )
    third_group = tree_proxy_group_for(
      'cache-seed-other',
      position: { 'x' => 14.0, 'y' => 37.7, 'z' => 0.0 }
    )

    first_definition = proxy_definition_for(first_group)
    second_definition = proxy_definition_for(second_group)
    third_definition = proxy_definition_for(third_group)

    assert_same(first_definition, second_definition)
    refute_same(first_definition, third_definition)
    refute_equal(proxy_signature_for(first_definition), proxy_signature_for(third_definition))
    refute_equal(
      transformation_origin(proxy_instance_for(first_group).transformation),
      transformation_origin(proxy_instance_for(second_group).transformation)
    )
  end

  def test_build_defaults_canopy_diameter_y_to_canopy_diameter_x_for_sectioned_input
    implicit_group = @builder.build(
      model: @model,
      params: {
        'elementType' => 'tree_proxy',
        'definition' => {
          'mode' => 'generated_proxy',
          'position' => { 'x' => 14.0, 'y' => 37.7, 'z' => 0.0 },
          'canopyDiameterX' => 6.0,
          'height' => 5.5,
          'trunkDiameter' => 0.45
        }
      }
    )
    explicit_group = @builder.build(
      model: @model,
      params: {
        'elementType' => 'tree_proxy',
        'definition' => {
          'mode' => 'generated_proxy',
          'position' => { 'x' => 14.0, 'y' => 37.7, 'z' => 0.0 },
          'canopyDiameterX' => 6.0,
          'canopyDiameterY' => 6.0,
          'height' => 5.5,
          'trunkDiameter' => 0.45
        }
      }
    )

    implicit_faces = implicit_group.entities.component_instances.first
                                   .definition
                                   .entities
                                   .faces
                                   .map(&:points)
    explicit_faces = explicit_group.entities.component_instances.first
                                   .definition
                                   .entities
                                   .faces
                                   .map(&:points)

    assert_equal(explicit_faces, implicit_faces)
  end

  def test_build_creates_tree_proxy_into_supplied_destination_collection
    parent_group = @model.active_entities.add_group

    group = @builder.build(
      model: @model,
      destination: parent_group.entities,
      params: {
        'elementType' => 'tree_proxy',
        'definition' => {
          'mode' => 'generated_proxy',
          'position' => { 'x' => 14.0, 'y' => 37.7, 'z' => 0.0 },
          'canopyDiameterX' => 6.0,
          'height' => 5.5,
          'trunkDiameter' => 0.45
        }
      }
    )

    assert_same(group, parent_group.entities.groups.last)
    assert_equal(1, @model.active_entities.groups.length)
  end

  def test_build_terrain_anchored_tree_uses_sampled_z_without_caller_offset
    host_target = Object.new
    anchor_resolver = FakeTerrainAnchorResolver.new(sample_z: 12.25)
    builder = SU_MCP::Semantic::TreeProxyBuilder.new(terrain_anchor_resolver: anchor_resolver)

    group = builder.build(
      model: @model,
      params: {
        'elementType' => 'tree_proxy',
        'definition' => {
          'mode' => 'generated_proxy',
          'position' => { 'x' => 14.0, 'y' => 37.7, 'z' => 99.0 },
          'canopyDiameterX' => 6.0,
          'height' => 5.5,
          'trunkDiameter' => 0.45
        },
        'hosting' => {
          'mode' => 'terrain_anchored',
          'resolved_target' => host_target
        }
      }
    )

    proxy_instance = group.entities.component_instances.first
    z_levels = proxy_instance.definition.entities.faces.flat_map do |face|
      face.points.map { |point| point[2] + transformation_origin(proxy_instance.transformation)[2] }
    end

    assert_equal([{ host_target: host_target, anchor_xy: [14.0, 37.7], role: 'tree_base' }],
                 anchor_resolver.calls)
    assert_in_delta(12.25, z_levels.min, 1e-9)
    assert_in_delta(17.75, z_levels.max, 1e-9)
  end

  def test_build_terrain_anchored_tree_refusal_creates_no_wrapper_group
    refusal = SU_MCP::Semantic::BuilderRefusal.new(
      code: 'terrain_sample_miss',
      message: 'Terrain sampling missed.',
      details: { section: 'hosting', role: 'tree_base' }
    )
    builder = SU_MCP::Semantic::TreeProxyBuilder.new(
      terrain_anchor_resolver: FakeTerrainAnchorResolver.new(refusal: refusal)
    )

    assert_raises(SU_MCP::Semantic::BuilderRefusal) do
      builder.build(
        model: @model,
        params: {
          'elementType' => 'tree_proxy',
          'definition' => {
            'mode' => 'generated_proxy',
            'position' => { 'x' => 14.0, 'y' => 37.7, 'z' => 99.0 },
            'canopyDiameterX' => 6.0,
            'height' => 5.5,
            'trunkDiameter' => 0.45
          },
          'hosting' => {
            'mode' => 'terrain_anchored',
            'resolved_target' => Object.new
          }
        }
      )
    end

    assert_equal(0, @model.active_entities.groups.length)
  end

  private

  def build_cherry_proxy
    @builder.build(model: @model, params: cherry_tree_proxy_params)
  end

  def cherry_tree_proxy_params
    tree_proxy_params_for('cherry-seed').merge(
      'sceneProperties' => {
        'name' => 'Cherry Proxy',
        'tag' => 'Trees'
      },
      'definition' => tree_proxy_params_for('cherry-seed').fetch('definition').merge(
        'speciesHint' => 'cherry'
      )
    )
  end

  def assert_tree_wrapper(group)
    assert_instance_of(SemanticTestSupport::FakeGroup, group)
    assert_equal(0, group.entities.groups.length)
    assert_equal(1, group.entities.component_instances.length)
    assert_equal(0, group.entities.faces.length)
    assert_equal('Cherry Proxy', group.name)
    assert_equal('Trees', group.layer.name)
  end

  def assert_generated_tree_definition(proxy_mesh)
    assert_equal('tree_proxy',
                 proxy_mesh.get_attribute('su_mcp_generated_component', 'family'))
    assert_equal(SU_MCP::Semantic::TreeProxyBuilder::COMPONENT_VERSION,
                 proxy_mesh.get_attribute('su_mcp_generated_component', 'version'))
    assert_includes(
      proxy_mesh.get_attribute('su_mcp_generated_component', 'signature'),
      "style=#{SU_MCP::Semantic::TreeProxyBuilder::STYLE_SIGNATURE}"
    )
    assert_match(
      /profile=(upright_oval|compact_high|squat_block|round_boulder|cut_boulder)/,
      proxy_mesh.get_attribute('su_mcp_generated_component', 'signature')
    )
  end

  def assert_tree_mesh_geometry(proxy_mesh)
    assert_equal(0, proxy_mesh.entities.groups.length)
    assert_empty(non_planar_faces(proxy_mesh))
    assert_operator(proxy_mesh.entities.faces.length, :<=, 120)
    assert_tree_face_counts(proxy_mesh)
    assert_tree_face_materials(proxy_mesh)
    assert_trunk_caps(proxy_mesh)

    mesh_points = proxy_mesh.entities.faces.flat_map(&:points)
    z_levels = mesh_points.map { |point| point[2] }.uniq.sort
    assert_in_delta(5.5, z_levels.last, 1e-9)
    assert_operator(z_levels.length, :>, 20)
    assert_points_within_tree_bounds(mesh_points)
  end

  def assert_tree_face_counts(proxy_mesh)
    face_size_counts = proxy_mesh.entities.faces.map { |face| face.points.length }.tally
    assert_equal(2, face_size_counts.fetch(6))
    assert_equal(104, face_size_counts.fetch(3))
    assert_equal(2, face_size_counts.fetch(10))
  end

  def assert_tree_face_materials(proxy_mesh)
    assert_equal(
      %w[Codex-Tree-Canopy Codex-Tree-Trunk],
      proxy_mesh.entities.faces.map { |face| face.material&.name }.uniq.sort
    )
  end

  def assert_trunk_caps(proxy_mesh)
    horizontal_caps = horizontal_trunk_caps(proxy_mesh)
    assert_equal(2, horizontal_caps.length)

    cap_levels = horizontal_caps.map { |face| face.points.first[2] }.sort
    assert_in_delta(0.0, cap_levels.first, 1e-9)
    assert_operator(cap_levels.last, :>=, 5.5 * SU_MCP::Semantic::TreeProxyBuilder::TRUNK_TOP_RATIO)

    base_cap = horizontal_caps.first
    assert_operator(span(base_cap.points, axis: 0), :>, 0.45 * 0.85)
    assert_operator(span(base_cap.points, axis: 1), :>, 0.45)
  end

  def non_planar_faces(group)
    group.entities.faces.select do |face|
      face.points.length > 3 && !planar_points?(face.points)
    end
  end

  def tree_proxy_points_for(source_element_id)
    tree_proxy_group_for(source_element_id)
      .entities
      .component_instances
      .first
      .definition
      .entities
      .faces
      .map(&:points)
  end

  def tree_proxy_group_for(source_element_id, position: nil)
    @builder.build(
      model: @model,
      params: tree_proxy_params_for(source_element_id, position: position)
    )
  end

  def tree_proxy_params_for(source_element_id, position: nil)
    {
      'elementType' => 'tree_proxy',
      'metadata' => { 'sourceElementId' => source_element_id },
      'definition' => {
        'mode' => 'generated_proxy',
        'position' => position || { 'x' => 14.0, 'y' => 37.7, 'z' => 0.0 },
        'canopyDiameterX' => 6.0,
        'canopyDiameterY' => 5.6,
        'height' => 5.5,
        'trunkDiameter' => 0.45
      }
    }
  end

  def proxy_instance_for(group)
    group.entities.component_instances.first
  end

  def proxy_definition_for(group)
    proxy_instance_for(group).definition
  end

  def proxy_signature_for(definition)
    definition.get_attribute('su_mcp_generated_component', 'signature')
  end

  def horizontal_face?(face)
    face.points.map { |point| point[2] }.uniq.length == 1
  end

  def horizontal_trunk_caps(proxy_mesh)
    proxy_mesh.entities.faces.select do |face|
      face.points.length == 6 && horizontal_face?(face)
    end
  end

  def canopy_cap_face?(face)
    face.points.length == 10 &&
      horizontal_face?(face) &&
      face.material&.name == 'Codex-Tree-Canopy'
  end

  def horizontal_trunk_cap_levels(proxy_mesh)
    horizontal_trunk_caps(proxy_mesh).map { |face| face.points.first[2] }.sort
  end

  def canopy_cap_levels(proxy_mesh)
    proxy_mesh.entities.faces
              .select { |face| canopy_cap_face?(face) }
              .flat_map { |face| face.points.map { |point| point[2] } }
  end

  def assert_points_within_tree_bounds(points)
    assert(points.all? { |point| point[0].abs <= 3.0 })
    assert(points.all? { |point| point[1].abs <= 2.8 })
    assert(points.all? { |point| point[2].between?(0.0, 5.5) })
  end

  def planar_points?(points, tolerance: 1e-9)
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

  def dot_product(left, right)
    left.zip(right).sum { |left_value, right_value| left_value.to_f * right_value.to_f }
  end

  def near_zero_vector?(vector, tolerance: 1e-9)
    vector.all? { |value| value.abs <= tolerance }
  end

  def span(points, axis:)
    coordinates = points.map { |point| point.fetch(axis) }
    coordinates.max - coordinates.min
  end

  def transformation_origin(transformation)
    return transformation.fetch(:origin) if transformation.is_a?(Hash)
    return [transformation.origin.x, transformation.origin.y, transformation.origin.z] if
      transformation.respond_to?(:origin) && transformation.origin

    [0.0, 0.0, 0.0]
  end
end
