# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/output/terrain_vertex_projector'
require_relative '../../../src/su_mcp/terrain/state/heightmap_state'

class TerrainVertexProjectorTest < Minitest::Test
  def test_projects_grid_vertices_through_length_converter_and_supplied_oracle
    oracle = RecordingOracle.new
    projector = SU_MCP::Terrain::TerrainVertexProjector.new(
      length_converter: ScalingLengthConverter.new(multiplier: 10.0),
      height_oracle: oracle,
      height_oracle_state: state
    )

    assert_equal([20.0, 60.0, 130.0], projector.vertex_for(state, 1, 2))
    assert_equal([[1, 2]], oracle.grid_queries)
  end

  def test_projects_fractional_adaptive_center_with_bilinear_oracle_heights
    projector = SU_MCP::Terrain::TerrainVertexProjector.new(
      length_converter: ScalingLengthConverter.new(multiplier: 1.0),
      height_oracle: BilinearOracle.new,
      height_oracle_state: state
    )

    assert_equal([2.5, 5.0, 3.0], projector.adaptive_vertex_for_planned_point(state, [1.5, 1.5]))
  end

  private

  def state
    @state ||= SU_MCP::Terrain::HeightmapState.new(
      basis: {
        'xAxis' => [1.0, 0.0, 0.0],
        'yAxis' => [0.0, 1.0, 0.0],
        'zAxis' => [0.0, 0.0, 1.0],
        'vertical' => 'z_up'
      },
      origin: { 'x' => 1.0, 'y' => 2.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 2.0 },
      dimensions: { 'columns' => 3, 'rows' => 3 },
      elevations: Array.new(9, 0.0),
      revision: 1,
      state_id: 'projector-state'
    )
  end

  class ScalingLengthConverter
    def initialize(multiplier:)
      @multiplier = multiplier
    end

    def public_meters_to_internal(value)
      value.to_f * @multiplier
    end
  end

  class RecordingOracle
    attr_reader :grid_queries

    def initialize
      @grid_queries = []
    end

    def height_at_grid(column:, row:)
      @grid_queries << [column, row]
      column + row + 10.0
    end
  end

  class BilinearOracle
    def height_at_grid(column:, row:)
      column + row
    end
  end
end
