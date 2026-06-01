# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/semantic_test_support'
require_relative '../../../src/su_mcp/terrain/output/feature_aware_diagonal_optimizer'
require_relative '../../../src/su_mcp/terrain/output/patch_lifecycle/patch_grid_policy'
require_relative '../../../src/su_mcp/terrain/output/terrain_mesh_generator'
require_relative '../../../src/su_mcp/terrain/output/terrain_output_plan'
require_relative '../../../src/su_mcp/terrain/probes/' \
                 'feature_aware_adaptive_baseline_quality_sampler'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'

class ComposedHeightOracleRoutingTest < Minitest::Test
  include SemanticTestSupport

  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_output_plan_seam_records_use_supplied_composed_height_oracle
    oracle = RecordingOracle.new
    plan = SU_MCP::Terrain::TerrainOutputPlan.full_grid(
      state: adaptive_state,
      terrain_state_summary: { digest: 'digest-1', revision: 1 },
      adaptive_patch_policy: patch_policy,
      height_oracle: oracle
    )

    refute_empty(oracle.grid_queries)
    assert(
      plan.adaptive_seam_records.all? do |record|
        record.fetch(:zValues).all? { |value| value >= RecordingOracle::GRID_HEIGHT_OFFSET }
      end
    )
  end

  def test_mesh_generator_emits_regular_and_adaptive_vertex_z_from_oracle
    model = build_semantic_model
    owner = model.active_entities.add_group
    oracle = RecordingOracle.new

    SU_MCP::Terrain::TerrainMeshGenerator.new.generate(
      owner: owner,
      state: adaptive_state,
      terrain_state_summary: { digest: 'digest-1', revision: 1 },
      output_plan: SU_MCP::Terrain::TerrainOutputPlan.full_grid(
        state: adaptive_state,
        terrain_state_summary: { digest: 'digest-1', revision: 1 },
        adaptive_patch_policy: patch_policy,
        height_oracle: oracle
      ),
      height_oracle: oracle
    )

    refute_empty(oracle.grid_queries + oracle.point_queries)
    assert(
      owner.entities.faces.flat_map(&:points).all? do |point|
        point.fetch(2) >= RecordingOracle::GRID_HEIGHT_OFFSET
      end
    )
  end

  def test_conformity_and_diagonal_optimizer_are_not_fed_raw_base_height_semantics
    oracle = RecordingOracle.new
    plan = SU_MCP::Terrain::TerrainOutputPlan.full_grid(
      state: adaptive_state,
      terrain_state_summary: { digest: 'digest-1', revision: 1 },
      adaptive_patch_policy: patch_policy,
      height_oracle: oracle
    )

    assert_equal(
      'composed_height_oracle',
      plan.diagonal_optimization_summary.fetch(:heightSource)
    )
    assert(
      plan.adaptive_cells.all? { |cell| cell.fetch(:height_source) == 'composed_height_oracle' }
    )
  end

  def test_adaptive_conformity_collapse_uses_supplied_composed_height_oracle
    oracle = RecordingOracle.new

    cells = SU_MCP::Terrain::AdaptiveOutputConformity.cells(
      conformity_cells_with_edge_split,
      state: adaptive_state,
      collapse_coplanar_edges: true,
      height_oracle: oracle
    )

    refute_empty(oracle.grid_queries)
    assert(cells.any? { |cell| cell.fetch(:boundary_vertices).length == 4 })
  end

  def test_adaptive_diagonal_optimizer_uses_supplied_composed_height_oracle
    oracle = RecordingOracle.new

    SU_MCP::Terrain::AdaptiveOutputConformity.cells(
      [{ min_column: 0, min_row: 0, max_column: 4, max_row: 4 }],
      state: adaptive_state,
      diagonal_context: RoutingDiagonalContext.new,
      height_oracle: oracle
    )

    refute_empty(oracle.grid_queries)
  end

  def test_quality_sampler_uses_oracle_for_expected_sample_height
    oracle = RecordingOracle.new
    sampler = SU_MCP::Terrain::FeatureAwareAdaptiveBaselineQualitySampler.new(
      model: RoutingFakeModel.new(RoutingFakeOwner.new('terrain-main')),
      repository: RoutingFakeRepository.new(adaptive_state),
      surface_query: RoutingPlanarSurfaceQuery.new,
      height_oracle_builder: ->(_state) { oracle },
      sample_budget: 4,
      clock: SteppingClock.new
    )

    sampler.capture(
      row: {
        'rowId' => 'oracle-quality',
        'publicCommandPayload' => {
          'targetReference' => { 'sourceElementId' => 'terrain-main' }
        }
      },
      result: { output: { derivedMesh: { simplificationTolerance: 0.01 } } },
      baseline_evidence: {}
    )

    refute_empty(oracle.point_queries)
  end

  private

  def adaptive_state
    @adaptive_state ||= SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => 9, 'rows' => 9 },
      elevations: Array.new(81, 1.0),
      revision: 1,
      state_id: 'routing-state',
      source_summary: { 'sourceElementId' => 'terrain-main' },
      feature_intent: {
        'schemaVersion' => 3,
        'revision' => 1,
        'generation' => SU_MCP::Terrain::FeatureIntentSet::DEFAULT_GENERATION,
        'features' => [target_feature]
      }
    )
  end

  def target_feature
    {
      'id' => 'routing-target',
      'kind' => 'target_region',
      'sourceMode' => 'explicit_edit',
      'semanticScope' => 'routing-target',
      'strengthClass' => 'soft',
      'roles' => %w[support falloff],
      'priority' => 1,
      'payload' => {
        'region' => {
          'type' => 'rectangle',
          'bounds' => { 'minX' => 0.0, 'minY' => 0.0, 'maxX' => 2.0, 'maxY' => 2.0 }
        },
        'targetElevation' => 5.0
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
  end

  def window
    { 'min' => { 'column' => 0, 'row' => 0 }, 'max' => { 'column' => 2, 'row' => 2 } }
  end

  def patch_policy
    SU_MCP::Terrain::PatchLifecycle::PatchGridPolicy.new(
      patch_cell_size: 4,
      patch_id_prefix: 'adaptive-patch',
      fingerprint_kind: 'adaptive-patch'
    )
  end

  def conformity_cells_with_edge_split
    [
      { min_column: 0, min_row: 0, max_column: 4, max_row: 4 },
      { min_column: 0, min_row: 4, max_column: 2, max_row: 8 }
    ]
  end

  class RecordingOracle
    GRID_HEIGHT_OFFSET = 100.0

    attr_reader :grid_queries, :point_queries

    def initialize
      @grid_queries = []
      @point_queries = []
    end

    def height_at_grid(column:, row:)
      grid_queries << [column, row]
      GRID_HEIGHT_OFFSET + column + row
    end

    def height_at(point)
      point_queries << point
      GRID_HEIGHT_OFFSET + point.fetch('x').to_f + point.fetch('y').to_f
    end

    def query(point)
      { 'height' => height_at(point), 'sourceCategory' => 'oracle_spy' }
    end
  end

  class RoutingFakeOwner
    def initialize(source_element_id)
      @source_element_id = source_element_id
    end

    def get_attribute(dictionary, key)
      return @source_element_id if dictionary == 'su_mcp' && key == 'sourceElementId'

      nil
    end
  end

  class RoutingFakeModel
    attr_reader :entities

    def initialize(owner)
      @entities = RoutingFakeEntities.new([owner])
    end
  end

  class RoutingFakeEntities
    def initialize(items)
      @items = items
    end

    def to_a
      @items
    end
  end

  class RoutingFakeRepository
    def initialize(state)
      @state = state
    end

    def load(_owner)
      { outcome: 'loaded', state: @state }
    end
  end

  class RoutingPlanarSurfaceQuery
    def execute(entities:, params:, scene_entities: nil)
      raise 'owner missing' if entities.empty? || scene_entities.empty?

      {
        success: true,
        results: params.fetch('sampling').fetch('points').map do |point|
          { status: 'hit', hitPoint: { z: point.fetch(:x) + point.fetch(:y) } }
        end
      }
    end
  end

  class RoutingDiagonalContext
    def candidate_safety
      { baseline: :safe, alternate: :safe }
    end

    def summary
      {}
    end
  end

  class SteppingClock
    def initialize
      @values = [10.0, 10.123]
    end

    def monotonic_seconds
      @values.shift
    end
  end
end
