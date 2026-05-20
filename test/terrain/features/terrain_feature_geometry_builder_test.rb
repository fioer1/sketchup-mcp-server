# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/features/terrain_feature_geometry_builder'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'

# rubocop:disable Metrics/ClassLength
class TerrainFeatureGeometryBuilderTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_derives_hard_preserve_region_and_fixed_control_primitives
    geometry = builder.build(state: state_with_features([
                                                          preserve_feature('preserve-1'),
                                                          fixed_feature('fixed-1')
                                                        ]))

    assert_equal('rectangle', geometry.protected_regions.first.fetch('primitive'))
    assert_equal('hard', geometry.output_anchor_candidates.first.fetch('strength'))
    assert_equal([2.0, 2.0], geometry.output_anchor_candidates.first.fetch('ownerLocalPoint'))
    assert_equal([2, 2], geometry.output_anchor_candidates.first.fetch('gridPoint'))
  end

  def test_derives_corridor_firm_centerline_side_band_endpoint_cap_and_reference_segments
    geometry = builder.build(state: state_with_features([corridor_feature('corridor-1')]))

    assert_equal(%w[centerline endpoint_cap side_transition],
                 geometry.reference_segments.map { |segment| segment.fetch('role') }.uniq.sort)
    corridor = geometry.pressure_regions.find { |region| region.fetch('primitive') == 'corridor' }
    assert_equal('firm', corridor.fetch('strength'))
    assert_equal([[0.0, 2.0], [6.0, 2.0]], corridor.dig('ownerLocalShape', 'centerline'))
  end

  def test_corridor_forced_mask_inputs_are_reference_detail_not_broad_pressure
    geometry = builder.build(state: state_with_features([corridor_feature('corridor-1')]))
    forced_roles = geometry.reference_segments.map { |segment| segment.fetch('role') } -
                   ['centerline']
    broad_pressure = geometry.pressure_regions.find do |region|
      region.fetch('id') == 'corridor-1:corridor_pressure'
    end

    assert_equal(%w[endpoint_cap endpoint_cap side_transition side_transition],
                 forced_roles.sort)
    assert_equal('corridor', broad_pressure.fetch('primitive'))
    assert_equal('centerline', broad_pressure.fetch('role'))
  end

  def test_derives_survey_target_fairing_and_inferred_pressure_strengths
    geometry = builder.build(state: state_with_features([
                                                          survey_feature('survey-1'),
                                                          planar_feature('planar-1'),
                                                          target_feature('target-1'),
                                                          fairing_feature('fairing-1'),
                                                          inferred_feature('inferred-1')
                                                        ]))
    strengths_by_role = geometry.pressure_regions.to_h do |region|
      [region.fetch('role'), region.fetch('strength')]
    end

    assert_equal('firm', strengths_by_role.fetch('survey_anchor'))
    refute_includes(strengths_by_role.keys, 'planar_support')
    assert_equal('soft', strengths_by_role.fetch('target_support'))
    assert_equal('soft', strengths_by_role.fetch('fairing_support'))
    assert_equal('soft', strengths_by_role.fetch('hard_break'))
  end

  def test_planar_region_without_falloff_does_not_emit_broad_pressure
    geometry = builder.build(state: state_with_features([planar_feature('planar-1')]))
    planar_pressure = geometry.pressure_regions.find do |region|
      region.fetch('role') == 'planar_support'
    end

    assert_nil(planar_pressure)
    assert_empty(geometry.reference_segments)
  end

  def test_planar_region_with_falloff_emits_edge_detail_only
    geometry = builder.build(
      state: state_with_features([
                                   planar_feature(
                                     'planar-1',
                                     blend: { 'distance' => 1.0, 'falloff' => 'smooth' }
                                   )
                                 ])
    )

    assert_empty(geometry.pressure_regions)
    assert_equal(%w[falloff falloff falloff falloff],
                 geometry.reference_segments.map { |segment| segment.fetch('role') })
  end

  def test_later_absolute_planar_region_suppresses_older_soft_pressure_inside_support
    geometry = builder.build(
      state: state_with_features([
                                   target_feature('target-under-planar', radius: 1.0),
                                   planar_feature('planar-overwrite', revision: 2)
                                 ])
    )

    assert_empty(geometry.pressure_regions)
  end

  def test_newer_target_region_on_top_of_absolute_planar_region_is_preserved
    geometry = builder.build(
      state: state_with_features([
                                   planar_feature('planar-base', revision: 1),
                                   target_feature('target-over-planar', radius: 1.0, revision: 2)
                                 ])
    )

    roles = geometry.pressure_regions.map { |region| region.fetch('role') }

    assert_equal(['target_support'], roles)
  end

  def test_later_absolute_planar_region_suppresses_older_corridor_detail_inside_support
    geometry = builder.build(
      state: state_with_features([
                                   corridor_feature(
                                     'corridor-under-planar',
                                     start_point: [2.0, 2.0],
                                     end_point: [3.0, 2.0],
                                     width: 1.0,
                                     side_blend: { 'distance' => 0.0, 'falloff' => 'none' }
                                   ),
                                   planar_feature('planar-overwrite', revision: 2)
                                 ])
    )

    assert_empty(geometry.reference_segments)
    assert_empty(geometry.pressure_regions)
  end

  def test_later_absolute_planar_region_splits_older_crossing_corridor_detail_outside_footprint
    geometry = builder.build(
      state: state_with_features([
                                   corridor_feature('corridor-crossing'),
                                   planar_feature('planar-overwrite', revision: 2)
                                 ])
    )

    assert_empty(geometry.limitations)
    assert_equal(
      [
        ['corridor-crossing:centerline:0:outside-0', 'centerline', [0.0, 2.0], [1.0, 2.0]],
        ['corridor-crossing:centerline:0:outside-1', 'centerline', [4.0, 2.0], [6.0, 2.0]],
        ['corridor-crossing:endpoint_cap:3', 'endpoint_cap', [0.0, 4.0], [0.0, 0.0]],
        ['corridor-crossing:endpoint_cap:4', 'endpoint_cap', [6.0, 4.0], [6.0, 0.0]],
        ['corridor-crossing:side_transition:1:outside-0', 'side_transition', [0.0, 4.0],
         [1.0, 4.0]],
        ['corridor-crossing:side_transition:1:outside-1', 'side_transition', [4.0, 4.0],
         [6.0, 4.0]],
        ['corridor-crossing:side_transition:2', 'side_transition', [0.0, 0.0], [6.0, 0.0]]
      ],
      reference_segment_payloads(geometry)
    )
    geometry.reference_segments.each do |segment|
      assert_equal('corridor-crossing', segment.fetch('featureId'))
      assert_equal('firm', segment.fetch('strength'))
      assert_includes([1, 2], segment.fetch('targetCellSize'))
    end
  end

  def test_later_absolute_planar_region_subtracts_older_rectangle_pressure_outside_footprint
    geometry = builder.build(
      state: state_with_features([
                                   fairing_feature(
                                     'fairing-crossing',
                                     region: rectangle_region(min: [0.0, 0.0], max: [6.0, 5.0])
                                   ),
                                   planar_feature('planar-overwrite', revision: 2)
                                 ])
    )

    assert_empty(geometry.limitations)
    assert_equal(
      [
        ['fairing-crossing:fairing_support:outside-bottom', 'fairing_support', 'soft',
         [[1.0, 0.0], [4.0, 1.0]], 4],
        ['fairing-crossing:fairing_support:outside-left', 'fairing_support', 'soft',
         [[0.0, 0.0], [1.0, 5.0]], 4],
        ['fairing-crossing:fairing_support:outside-right', 'fairing_support', 'soft',
         [[4.0, 0.0], [6.0, 5.0]], 4],
        ['fairing-crossing:fairing_support:outside-top', 'fairing_support', 'soft',
         [[1.0, 4.0], [4.0, 5.0]], 4]
      ],
      pressure_region_payloads(geometry)
    )
  end

  def test_later_absolute_planar_region_clips_older_circle_pressure_by_effective_bounds
    geometry = builder.build(
      state: state_with_features([
                                   target_feature('target-crossing', radius: 2.0),
                                   planar_feature('planar-overwrite', revision: 2)
                                 ])
    )

    assert_empty(geometry.limitations)
    assert_equal(
      [
        ['target-crossing:target_support:outside-right', 'target_support', 'soft',
         [[4.0, 1.0], [5.0, 5.0]], 4],
        ['target-crossing:target_support:outside-top', 'target_support', 'soft',
         [[1.0, 4.0], [4.0, 5.0]], 4]
      ],
      pressure_region_payloads(geometry)
    )
  end

  def test_newer_corridor_on_top_of_absolute_planar_region_is_preserved
    geometry = builder.build(
      state: state_with_features([
                                   planar_feature('planar-base', revision: 1),
                                   corridor_feature(
                                     'corridor-over-planar',
                                     start_point: [2.0, 2.0],
                                     end_point: [3.0, 2.0],
                                     width: 1.0,
                                     side_blend: { 'distance' => 0.0, 'falloff' => 'none' },
                                     revision: 2
                                   )
                                 ])
    )

    assert_equal(5, geometry.reference_segments.length)
    assert_equal(['corridor'], geometry.pressure_regions.map { |region| region.fetch('primitive') })
  end

  def test_newer_survey_and_fairing_on_top_of_absolute_planar_region_are_preserved
    geometry = builder.build(
      state: state_with_features([
                                   planar_feature('planar-base', revision: 1),
                                   survey_feature('survey-over-planar', revision: 2),
                                   fairing_feature('fairing-over-planar', revision: 2)
                                 ])
    )

    assert_equal(['survey-over-planar'],
                 geometry.output_anchor_candidates.map { |anchor| anchor.fetch('id') })
    assert_equal(%w[fairing_support survey_anchor],
                 geometry.pressure_regions.map { |region| region.fetch('role') }.sort)
  end

  def test_positive_falloff_planar_region_does_not_occlude_older_pressure
    geometry = builder.build(
      state: state_with_features([
                                   target_feature('target-under-falloff-planar', radius: 1.0),
                                   planar_feature(
                                     'planar-with-falloff',
                                     blend: { 'distance' => 1.0, 'falloff' => 'smooth' },
                                     revision: 2
                                   )
                                 ])
    )

    assert_equal(['target_support'],
                 geometry.pressure_regions.map { |region| region.fetch('role') })
    assert_equal(%w[falloff falloff falloff falloff],
                 geometry.reference_segments.map { |segment| segment.fetch('role') })
  end

  def test_partial_circular_planar_occluder_retains_older_pressure_with_limitation
    geometry = builder.build(
      state: state_with_features([
                                   fairing_feature(
                                     'fairing-crossing-circle-planar',
                                     region: rectangle_region(min: [0.0, 0.0], max: [6.0, 5.0])
                                   ),
                                   planar_feature(
                                     'circle-planar-overwrite',
                                     region: circle_region(center: [3.0, 3.0], radius: 2.0),
                                     revision: 2
                                   )
                                 ])
    )

    assert_equal(['fairing_support'],
                 geometry.pressure_regions.map { |region| region.fetch('role') })
    assert_includes(JSON.generate(geometry.limitations), 'circle-planar-overwrite')
    assert_includes(JSON.generate(geometry.limitations), 'partial circular planar occlusion')
  end

  def test_later_absolute_planar_region_does_not_suppress_hard_protected_regions
    geometry = builder.build(
      state: state_with_features([
                                   preserve_feature('preserve-under-planar'),
                                   planar_feature('planar-overwrite', revision: 2)
                                 ])
    )

    assert_equal(['preserve-under-planar:protected'],
                 geometry.protected_regions.map { |region| region.fetch('id') })
    assert_equal(['protected_boundary'],
                 geometry.pressure_regions.map { |region| region.fetch('role') })
  end

  def test_derives_exact_geometry_for_all_geometry_producing_intents
    geometry = all_geometry_intent_geometry

    assert_exact_geometry_collection_counts(geometry)
    assert_exact_hard_and_firm_anchor_geometry(geometry)
    assert_exact_region_pressure_geometry(geometry)
    assert_exact_corridor_reference_geometry(geometry)
  end

  def test_hard_derivation_failure_sets_feature_geometry_failed
    feature = preserve_feature('broken-preserve', region: { 'type' => 'polygon' })
    geometry = builder.build(state: state_with_features([feature]))

    assert_equal('feature_geometry_failed', geometry.failure_category)
    assert_includes(JSON.generate(geometry.limitations), 'broken-preserve')
  end

  def test_firm_and_soft_derivation_gaps_continue_with_limitations
    feature = corridor_feature('weak-corridor', width: nil, side_blend: nil)
    geometry = builder.build(state: state_with_features([feature]))

    assert_equal('none', geometry.failure_category)
    assert_includes(JSON.generate(geometry.limitations), 'weak-corridor')
    assert(geometry.reference_segments.any? { |segment| segment.fetch('role') == 'centerline' })
  end

  def test_default_feature_source_uses_effective_view_and_excludes_retired_history
    geometry = builder.build(
      state: state_with_features([
                                   preserve_feature('active-preserve'),
                                   retired_feature(fixed_feature('retired-fixed'))
                                 ])
    )

    assert_equal(['active-preserve:protected'],
                 geometry.protected_regions.map { |region| region.fetch('id') })
    assert_empty(geometry.output_anchor_candidates)
  end

  private

  def builder
    @builder ||= SU_MCP::Terrain::TerrainFeatureGeometryBuilder.new
  end

  def all_geometry_intent_geometry
    builder.build(state: state_with_features([
                                               preserve_feature('preserve-1'),
                                               fixed_feature('fixed-1'),
                                               corridor_feature('corridor-1'),
                                               survey_feature('survey-1'),
                                               planar_feature('planar-1'),
                                               target_feature('target-1'),
                                               fairing_feature('fairing-1'),
                                               inferred_feature('inferred-1')
                                             ]))
  end

  def assert_exact_geometry_collection_counts(geometry)
    assert_empty(geometry.limitations)
    assert_equal('none', geometry.failure_category)
    assert_equal(2, geometry.output_anchor_candidates.length)
    assert_equal(1, geometry.protected_regions.length)
    assert_equal(6, geometry.pressure_regions.length)
    assert_equal(5, geometry.reference_segments.length)
    assert_equal(8, geometry.affected_windows.length)
  end

  def assert_exact_hard_and_firm_anchor_geometry(geometry)
    assert_equal(
      [['preserve-1:protected', 'rectangle', [[1.0, 1.0], [4.0, 4.0]]]],
      geometry.protected_regions.map do |region|
        [region.fetch('id'), region.fetch('primitive'), region.fetch('ownerLocalBounds')]
      end
    )
    assert_includes(anchor_payloads(geometry), ['fixed-1', 'control', 'hard', [2.0, 2.0], [2, 2]])
    assert_includes(anchor_payloads(geometry),
                    ['survey-1', 'survey_anchor', 'firm', [3.0, 3.0], [3, 3]])
  end

  def anchor_payloads(geometry)
    geometry.output_anchor_candidates.map do |anchor|
      [anchor.fetch('id'), anchor.fetch('role'), anchor.fetch('strength'),
       anchor.fetch('ownerLocalPoint'), anchor.fetch('gridPoint', nil)]
    end
  end

  def assert_exact_region_pressure_geometry(geometry)
    pressures_by_role = geometry.pressure_regions.to_h do |region|
      [region.fetch('role'), [region.fetch('strength'), region.fetch('primitive')]]
    end
    assert_equal(%w[firm rectangle], pressures_by_role.fetch('protected_boundary'))
    assert_equal(%w[firm circle], pressures_by_role.fetch('survey_anchor'))
    refute_includes(pressures_by_role.keys, 'planar_support')
    assert_equal(%w[soft circle], pressures_by_role.fetch('target_support'))
    assert_equal(%w[soft rectangle], pressures_by_role.fetch('fairing_support'))
    assert_equal(%w[soft rectangle], pressures_by_role.fetch('hard_break'))
  end

  def assert_exact_corridor_reference_geometry(geometry)
    corridor_pressure = geometry.pressure_regions.find do |region|
      region.fetch('id') == 'corridor-1:corridor_pressure'
    end
    assert_equal('corridor', corridor_pressure.fetch('primitive'))
    assert_equal([[0.0, 2.0], [6.0, 2.0]], corridor_pressure.dig('ownerLocalShape', 'centerline'))
    assert_equal(2.0, corridor_pressure.dig('ownerLocalShape', 'width'))
    assert_equal(1.0, corridor_pressure.dig('ownerLocalShape', 'blendDistance'))

    roles = geometry.reference_segments.map { |segment| segment.fetch('role') }
    assert_equal(1, roles.count('centerline'))
    assert_equal(2, roles.count('side_transition'))
    assert_equal(2, roles.count('endpoint_cap'))
  end

  def reference_segment_payloads(geometry)
    geometry.reference_segments.map do |segment|
      [
        segment.fetch('id'),
        segment.fetch('role'),
        segment.fetch('ownerLocalStart'),
        segment.fetch('ownerLocalEnd')
      ]
    end
  end

  def pressure_region_payloads(geometry)
    geometry.pressure_regions.map do |region|
      [
        region.fetch('id'),
        region.fetch('role'),
        region.fetch('strength'),
        region.fetch('ownerLocalShape'),
        region.fetch('targetCellSize')
      ]
    end
  end

  def state_with_features(features)
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => 8, 'rows' => 6 },
      elevations: Array.new(48, 1.0),
      revision: 1,
      state_id: 'mta23-state',
      feature_intent: {
        'schemaVersion' => 3,
        'revision' => 1,
        'generation' => SU_MCP::Terrain::FeatureIntentSet::DEFAULT_GENERATION,
        'features' => features
      }
    )
  end

  def feature(id:, kind:, roles:, payload:, affected_window: default_affected_window, revision: 1)
    {
      'id' => id,
      'kind' => kind,
      'sourceMode' => kind == 'inferred_heightfield' ? 'inferred_heightfield' : 'explicit_edit',
      'roles' => roles,
      'priority' => 1,
      'payload' => payload,
      'affectedWindow' => affected_window,
      'provenance' => { 'originClass' => 'test', 'originOperation' => kind,
                        'createdAtRevision' => revision, 'updatedAtRevision' => revision }
    }
  end

  def preserve_feature(id, region: { 'type' => 'rectangle', 'bounds' => bounds })
    feature(id: id, kind: 'preserve_region', roles: %w[protected boundary],
            payload: { 'region' => region })
  end

  def fixed_feature(id)
    feature(id: id, kind: 'fixed_control', roles: %w[control protected],
            payload: { 'control' => { 'id' => id, 'point' => { 'x' => 2.0, 'y' => 2.0 },
                                      'tolerance' => 0.05 } })
  end

  def retired_feature(feature)
    feature.merge('lifecycle' => {
                    'status' => 'retired',
                    'supersededBy' => nil,
                    'updatedAtRevision' => 1
                  })
  end

  def corridor_feature(id, width: 2.0, side_blend: { 'distance' => 1.0, 'falloff' => 'cosine' },
                       start_point: [0.0, 2.0], end_point: [6.0, 2.0], revision: 1)
    payload = {
      'startControl' => {
        'point' => { 'x' => start_point.fetch(0), 'y' => start_point.fetch(1) },
        'elevation' => 1.0
      },
      'endControl' => {
        'point' => { 'x' => end_point.fetch(0), 'y' => end_point.fetch(1) },
        'elevation' => 2.0
      }
    }
    payload['width'] = width if width
    payload['sideBlend'] = side_blend if side_blend
    feature(id: id, kind: 'linear_corridor',
            roles: %w[centerline side_transition endpoint_cap control], payload: payload,
            revision: revision)
  end

  def survey_feature(id, support_region: nil, revision: 1)
    support_region ||= circle_region(center: [3.0, 3.0], radius: 1.5)
    feature(id: id, kind: 'survey_control', roles: %w[control support],
            payload: { 'control' => { 'id' => id, 'point' => { 'x' => 3.0, 'y' => 3.0 } },
                       'supportRegion' => support_region },
            revision: revision)
  end

  def planar_feature(id, blend: nil, revision: 1, region: nil)
    region ||= { 'type' => 'rectangle', 'bounds' => bounds }
    region['blend'] = blend if blend
    feature(id: id, kind: 'planar_region', roles: %w[support boundary],
            payload: { 'region' => region }, revision: revision)
  end

  def target_feature(id, radius: 2.0, revision: 1, region: nil)
    region ||= circle_region(center: [3.0, 3.0], radius: radius)
    feature(id: id, kind: 'target_region', roles: %w[support falloff],
            payload: { 'region' => region }, revision: revision)
  end

  def fairing_feature(id, region: nil, revision: 1)
    feature(id: id, kind: 'fairing_region', roles: %w[support],
            payload: { 'region' => region || { 'type' => 'rectangle', 'bounds' => bounds } },
            revision: revision)
  end

  def inferred_feature(id)
    feature(id: id, kind: 'inferred_heightfield', roles: %w[hard_break soft_transition],
            payload: { 'region' => { 'type' => 'rectangle', 'bounds' => bounds } })
  end

  def default_affected_window
    { 'min' => { 'column' => 0, 'row' => 0 }, 'max' => { 'column' => 6, 'row' => 4 } }
  end

  def bounds
    { 'minX' => 1.0, 'minY' => 1.0, 'maxX' => 4.0, 'maxY' => 4.0 }
  end

  def rectangle_region(min:, max:)
    {
      'type' => 'rectangle',
      'bounds' => {
        'minX' => min.fetch(0),
        'minY' => min.fetch(1),
        'maxX' => max.fetch(0),
        'maxY' => max.fetch(1)
      }
    }
  end

  def circle_region(center:, radius:)
    {
      'type' => 'circle',
      'center' => { 'x' => center.fetch(0), 'y' => center.fetch(1) },
      'radius' => radius
    }
  end
end
# rubocop:enable Metrics/ClassLength
