# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/features/terrain_feature_geometry_builder'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'

class TerrainFeatureGeometryOracleSemanticsTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_normalized_oracle_geometry_preserves_circular_semantics_for_all_region_kinds
    geometry = SU_MCP::Terrain::TerrainFeatureGeometryBuilder.new.build(
      state: state_with_features([
                                   circular_target('target-circle'),
                                   circular_planar('planar-circle'),
                                   circular_preserve('preserve-circle'),
                                   circular_survey_support('survey-circle')
                                 ])
    )

    regions_by_feature = geometry.oracle_semantic_regions.to_h do |region|
      [region.fetch('featureId'), region]
    end

    %w[target-circle planar-circle preserve-circle survey-circle].each do |feature_id|
      assert_equal('circle', regions_by_feature.fetch(feature_id).fetch('primitive'))
      assert_equal(
        [3.0, 3.0, 1.5],
        regions_by_feature.fetch(feature_id).fetch('ownerLocalCenterRadius')
      )
    end
  end

  def test_oracle_semantic_regions_are_not_replaced_by_output_fragment_rectangles
    geometry = SU_MCP::Terrain::TerrainFeatureGeometryBuilder.new.build(
      state: state_with_features([
                                   circular_target('older-target', revision: 1),
                                   rectangular_planar('newer-planar', revision: 2)
                                 ])
    )

    target_region = geometry.oracle_semantic_regions.find do |region|
      region.fetch('featureId') == 'older-target'
    end

    assert_equal('circle', target_region.fetch('primitive'))
    assert_equal([3.0, 3.0, 1.5], target_region.fetch('ownerLocalCenterRadius'))
  end

  private

  def state_with_features(features)
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => 8, 'rows' => 8 },
      elevations: Array.new(64, 1.0),
      revision: 2,
      state_id: 'oracle-geometry-state',
      feature_intent: {
        'schemaVersion' => 3,
        'revision' => 2,
        'generation' => SU_MCP::Terrain::FeatureIntentSet::DEFAULT_GENERATION,
        'features' => features
      }
    )
  end

  def circular_target(id, revision: 1)
    feature(id, 'target_region', %w[support falloff],
            { 'region' => circular_region, 'targetElevation' => 7.0 }, revision)
  end

  def circular_planar(id, revision: 1)
    feature(id, 'planar_region', %w[support boundary],
            { 'region' => circular_region, 'planarControls' => planar_controls }, revision)
  end

  def circular_preserve(id, revision: 1)
    feature(id, 'preserve_region', %w[protected boundary], { 'region' => circular_region },
            revision)
  end

  def circular_survey_support(id, revision: 1)
    feature(
      id,
      'survey_control',
      %w[control support],
      {
        'control' => { 'id' => id, 'point' => { 'x' => 3.0, 'y' => 3.0 } },
        'supportRegion' => circular_region
      },
      revision
    )
  end

  def rectangular_planar(id, revision: 1)
    feature(
      id,
      'planar_region',
      %w[support boundary],
      {
        'region' => {
          'type' => 'rectangle',
          'bounds' => { 'minX' => 2.0, 'minY' => 2.0, 'maxX' => 4.0, 'maxY' => 4.0 }
        },
        'planarControls' => planar_controls
      },
      revision
    )
  end

  def feature(id, kind, roles, payload, revision)
    {
      'id' => id,
      'kind' => kind,
      'sourceMode' => 'explicit_edit',
      'semanticScope' => id,
      'strengthClass' => strength_for(kind),
      'roles' => roles,
      'priority' => 1,
      'payload' => payload,
      'affectedWindow' => window,
      'relevanceWindow' => window,
      'lifecycle' => {
        'status' => 'active',
        'supersededBy' => nil,
        'updatedAtRevision' => revision
      },
      'provenance' => {
        'originClass' => 'test',
        'originOperation' => kind,
        'createdAtRevision' => revision,
        'updatedAtRevision' => revision
      }
    }
  end

  def strength_for(kind)
    return 'hard' if %w[preserve_region fixed_control].include?(kind)
    return 'firm' if kind == 'survey_control'

    'soft'
  end

  def circular_region
    { 'type' => 'circle', 'center' => { 'x' => 3.0, 'y' => 3.0 }, 'radius' => 1.5 }
  end

  def planar_controls
    [
      { 'point' => { 'x' => 2.0, 'y' => 2.0, 'z' => 2.0 } },
      { 'point' => { 'x' => 4.0, 'y' => 2.0, 'z' => 4.0 } },
      { 'point' => { 'x' => 2.0, 'y' => 4.0, 'z' => 6.0 } }
    ]
  end

  def window
    { 'min' => { 'column' => 1, 'row' => 1 }, 'max' => { 'column' => 5, 'row' => 5 } }
  end
end
