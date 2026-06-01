# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/regions/composed_height_oracle'
require_relative '../../../src/su_mcp/terrain/storage/terrain_state_serializer'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'

class ComposedHeightOraclePersistenceTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_serializer_round_trip_rebuilds_same_oracle_answers_and_sources
    state = SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => 3, 'rows' => 3 },
      elevations: Array.new(9, 1.0),
      revision: 1,
      state_id: 'persistence-state',
      feature_intent: feature_intent
    )

    serializer = SU_MCP::Terrain::TerrainStateSerializer.new
    loaded = serializer.deserialize(serializer.serialize(state)).fetch(:state)

    before = SU_MCP::Terrain::ComposedHeightOracle.build(state: state)
    after = SU_MCP::Terrain::ComposedHeightOracle.build(state: loaded)

    assert_equal(before.query('x' => 1.0, 'y' => 1.0), after.query('x' => 1.0, 'y' => 1.0))
  end

  private

  def feature_intent
    {
      'schemaVersion' => 3,
      'revision' => 1,
      'generation' => SU_MCP::Terrain::FeatureIntentSet::DEFAULT_GENERATION,
      'features' => [
        {
          'id' => 'target-circle',
          'kind' => 'target_region',
          'sourceMode' => 'explicit_edit',
          'semanticScope' => 'target-circle',
          'strengthClass' => 'soft',
          'roles' => %w[support falloff],
          'priority' => 1,
          'payload' => {
            'region' => {
              'type' => 'circle',
              'center' => { 'x' => 1.0, 'y' => 1.0 },
              'radius' => 1.0
            },
            'targetElevation' => 4.0
          },
          'affectedWindow' => window,
          'relevanceWindow' => window,
          'lifecycle' => {
            'status' => 'active',
            'supersededBy' => nil,
            'updatedAtRevision' => 1
          },
          'provenance' => {
            'originClass' => 'test',
            'originOperation' => 'target_height',
            'createdAtRevision' => 1,
            'updatedAtRevision' => 1
          }
        }
      ]
    }
  end

  def window
    { 'min' => { 'column' => 0, 'row' => 0 }, 'max' => { 'column' => 2, 'row' => 2 } }
  end
end
