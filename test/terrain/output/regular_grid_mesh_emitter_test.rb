# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/semantic_test_support'
require_relative '../../../src/su_mcp/terrain/output/derived_output_entity_store'
require_relative '../../../src/su_mcp/terrain/output/regular_grid_mesh_emitter'

class RegularGridMeshEmitterTest < Minitest::Test
  include SemanticTestSupport

  def test_emits_regular_grid_faces_with_ownership_metadata
    vertices = [
      [0, 0, 0], [1, 0, 0],
      [0, 1, 0], [1, 1, 0]
    ]

    emitter.emit_faces_via_builder(entities, vertices, 2, 2, {})

    assert_equal(1, entities.build_calls)
    assert_equal(2, entities.faces.length)
    assert_equal([[0, 0, 0], [0, 0, 1]], entities.faces.map { |face| ownership_tuple(face) })
  end

  def test_emits_non_patch_adaptive_faces_from_projected_points
    state = Object.new
    cell = {
      emission_triangles: [
        [[:a], [:b], [:c]]
      ]
    }

    emitter.emit_adaptive_faces_via_builder(entities, state, [cell])

    assert_equal(1, entities.faces.length)
    assert_equal([[0, 0, 0], [1, 0, 0], [0, 1, 0]], entities.faces.fetch(0).points)
  end

  private

  def emitter
    @emitter ||= SU_MCP::Terrain::RegularGridMeshEmitter.new(
      derived_output_store: store,
      vertex_projector: StubVertexProjector.new
    )
  end

  def store
    @store ||= SU_MCP::Terrain::DerivedOutputEntityStore.new
  end

  def entities
    @entities ||= build_semantic_model.active_entities
  end

  def ownership_tuple(face)
    %w[gridCellColumn gridCellRow gridTriangleIndex].map do |key|
      face.get_attribute('su_mcp_terrain', key)
    end
  end

  class StubVertexProjector
    POINTS = {
      [:a] => [0, 0, 0],
      [:b] => [1, 0, 0],
      [:c] => [0, 1, 0]
    }.freeze

    def adaptive_vertex_for_planned_point(_state, point)
      POINTS.fetch(point)
    end
  end
end
