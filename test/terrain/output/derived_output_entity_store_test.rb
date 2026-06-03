# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/semantic_test_support'
require_relative '../../../src/su_mcp/terrain/output/derived_output_entity_store'
require_relative '../../../src/su_mcp/terrain/output/terrain_output_cell_window'

class DerivedOutputEntityStoreTest < Minitest::Test
  include SemanticTestSupport

  def test_marks_regular_grid_face_and_edges_as_derived_output
    face = entities.add_face([0, 0, 0], [1, 0, 0], [1, 1, 0])

    store.mark_derived(
      face,
      ownership: { column: 2, row: 3, triangle_index: 1 }
    )

    assert_equal(true, terrain_attribute(face, 'derivedOutput'))
    assert_equal(1, terrain_attribute(face, 'outputSchemaVersion'))
    assert_equal(2, terrain_attribute(face, 'gridCellColumn'))
    assert_equal(3, terrain_attribute(face, 'gridCellRow'))
    assert_equal(1, terrain_attribute(face, 'gridTriangleIndex'))
    face.edges.each do |edge|
      assert_equal(true, terrain_attribute(edge, 'derivedOutput'))
      assert(edge.hidden?)
    end
  end

  def test_owned_faces_for_cell_window_accepts_complete_metadata
    add_owned_face(column: 0, row: 0, triangle: 0)
    add_owned_face(column: 0, row: 0, triangle: 1)

    result = store.owned_faces_for_cell_window(entities, output_cell_window(0, 0, 0, 0))

    assert_equal(:owned, result.fetch(:outcome))
    assert_equal(2, result.fetch(:faces).length)
  end

  def test_owned_faces_for_cell_window_falls_back_for_duplicate_metadata
    add_owned_face(column: 0, row: 0, triangle: 0)
    add_owned_face(column: 0, row: 0, triangle: 0)

    result = store.owned_faces_for_cell_window(entities, output_cell_window(0, 0, 0, 0))

    assert_equal(:fallback, result.fetch(:outcome))
    assert_equal(:duplicate_ownership, result.fetch(:reason))
  end

  def test_batch_edge_marking_marks_shared_edges_once
    edge = CountingEdge.new
    faces = [
      FaceWithEdges.new([edge]),
      FaceWithEdges.new([edge])
    ]

    store.mark_unique_derived_edges(faces)

    assert_equal(1, edge.attribute_write_count)
    assert_equal(true, terrain_attribute(edge, 'derivedOutput'))
    assert(edge.hidden?)
  end

  private

  def store
    @store ||= SU_MCP::Terrain::DerivedOutputEntityStore.new
  end

  def entities
    @entities ||= build_semantic_model.active_entities
  end

  def add_owned_face(column:, row:, triangle:)
    face = entities.add_face([column, row, 0], [column + 1, row, 0], [column + 1, row + 1, 0])
    store.mark_derived(
      face,
      ownership: { column: column, row: row, triangle_index: triangle }
    )
    face
  end

  def output_cell_window(min_column, min_row, max_column, max_row)
    SU_MCP::Terrain::TerrainOutputCellWindow.new(
      {
        min_column: min_column,
        min_row: min_row,
        max_column: max_column,
        max_row: max_row
      }
    )
  end

  def terrain_attribute(entity, key)
    entity.get_attribute('su_mcp_terrain', key)
  end

  class FaceWithEdges
    attr_reader :edges

    def initialize(edges)
      @edges = edges
    end
  end

  class CountingEdge < SemanticTestSupport::FakeEdge
    attr_reader :attribute_write_count

    def initialize
      super
      @attribute_write_count = 0
    end

    def set_attribute(dictionary_name, key, value)
      @attribute_write_count += 1 if dictionary_name == 'su_mcp_terrain' &&
                                     key == 'derivedOutput'
      super
    end
  end
end
