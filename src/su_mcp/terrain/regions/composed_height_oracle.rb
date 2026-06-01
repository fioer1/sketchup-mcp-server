# frozen_string_literal: true

require_relative 'terrain_state_elevation_sampler'
require_relative 'planar_height_model'
require_relative 'terrain_oracle_semantic_shape'
require_relative '../features/terrain_feature_geometry'
require_relative '../features/terrain_feature_geometry_builder'
require_relative '../features/terrain_primitive_membership'

module SU_MCP
  module Terrain
    # Authoritative SketchUp-free terrain height read model.
    class ComposedHeightOracle
      SEMANTIC_TOKEN = 'composed-height-oracle:v1'
      PRECEDENCE_RANKS = {
        'fixed' => 0,
        'preserve' => 1,
        'planar' => 2,
        'target' => 3,
        'support' => 4
      }.freeze
      TOLERANCE = TerrainPrimitiveMembership::DEFAULT_TOLERANCE
      TOLERANCE_SQUARED = TOLERANCE * TOLERANCE

      def self.build(state:, feature_geometry: nil)
        geometry = feature_geometry || feature_geometry_for(state)
        new(state: state, feature_geometry: geometry)
      end

      def self.semantic_token
        SEMANTIC_TOKEN
      end

      def self.feature_geometry_for(state)
        return TerrainFeatureGeometryBuilder.new.build(state: state) if
          state.respond_to?(:feature_intent)

        TerrainFeatureGeometry.new
      end

      def initialize(state:, feature_geometry: nil)
        @state = state
        @feature_geometry = feature_geometry
        @base_sampler = TerrainStateElevationSampler.new(state)
        @planar_models = {}
        @grid_height_cache = {}
        @columns = state.dimensions.fetch('columns')
        @rows = state.dimensions.fetch('rows')
        @origin_x = state.origin.fetch('x')
        @origin_y = state.origin.fetch('y')
        @spacing_x = state.spacing.fetch('x')
        @spacing_y = state.spacing.fetch('y')
        @semantic_regions = compiled_semantic_regions
        @planar_regions = @semantic_regions.select do |region|
          region.fetch(:source_category) == 'planar'
        end
        @semantic_bounds = semantic_bounds_for(@semantic_regions)
      end

      def height_at(point)
        query(point).fetch('height')
      end

      def height_at_grid(column:, row:)
        key = grid_height_cache_key(column, row)
        return @grid_height_cache.fetch(key) if @grid_height_cache.key?(key)

        @grid_height_cache[key] = height_at_grid_uncached(column, row)
      end

      def query(point)
        return query_result(nil, 'out_of_bounds') unless base_sampler.inside_bounds?(point)

        base_height = base_sampler.elevation_at(point)
        return query_result(nil, 'no_data') if base_height.nil?

        feature_query = feature_query(point, base_height)
        return feature_query if feature_query

        query_result(base_height, 'base')
      end

      def semantic_token
        self.class.semantic_token
      end

      private

      attr_reader :state, :feature_geometry, :base_sampler, :columns, :rows,
                  :origin_x, :origin_y, :spacing_x, :spacing_y

      def feature_query(point, base_height)
        x, y = TerrainPrimitiveMembership.point_pair(point)
        feature_query_xy(x, y, base_height)
      end

      def feature_query_xy(x, y, base_height)
        return nil unless semantic_bounds_contain_xy?(x, y)

        @semantic_regions.each do |region|
          next unless shape_bounds_contain_xy?(region.fetch(:shape), x, y)
          next unless contains_xy?(region, x, y)
          next if suppressed_by_newer_planar_xy?(x, y, region)

          result = query_region_xy(region, x, y, base_height)
          return result if result
        end
        nil
      end

      def height_at_grid_uncached(column, row)
        return height_at_grid_via_point(column, row) unless integer_grid_index?(column, row)
        return nil unless grid_inside_bounds?(column, row)

        base_height = direct_base_grid_height(column, row)
        return nil if base_height.nil?

        x = origin_x + (column * spacing_x)
        y = origin_y + (row * spacing_y)
        query = feature_query_xy(x, y, base_height)
        query ? query.fetch('height') : base_height
      end

      def height_at_grid_via_point(column, row)
        height_at(
          'x' => origin_x + (column * spacing_x),
          'y' => origin_y + (row * spacing_y)
        )
      end

      def integer_grid_index?(column, row)
        column.is_a?(Integer) && row.is_a?(Integer)
      end

      def grid_inside_bounds?(column, row)
        column.between?(0, columns - 1) && row.between?(0, rows - 1)
      end

      def grid_height_cache_key(column, row)
        return [column, row] unless integer_grid_index?(column, row)
        return (row * columns) + column if grid_inside_bounds?(column, row)

        [:grid, column, row]
      end

      def direct_base_grid_height(column, row)
        value = state.elevations.fetch((row * columns) + column)
        value&.to_f
      end

      def precedence_rank(category)
        PRECEDENCE_RANKS.fetch(category, 5)
      end

      def suppressed_by_newer_planar_xy?(x, y, region)
        return false if region.fetch(:source_category) == 'planar'

        @planar_regions.each do |candidate|
          next unless candidate.fetch(:revision) > region.fetch(:revision)

          return true if contains_xy?(candidate, x, y)
        end
        false
      end

      def query_region_xy(region, x, y, base_height)
        case region.fetch(:source_category)
        when 'fixed'
          fixed_query(region)
        when 'preserve'
          query_result(base_height, 'preserve', 'featureId' => region.fetch(:feature_id))
        when 'target'
          target_query(region)
        when 'planar'
          planar_query(region, x, y)
        end
      end

      def fixed_query(region)
        return nil if region[:control_elevation].nil?

        query_result(
          region.fetch(:control_elevation),
          'fixed',
          'featureId' => region.fetch(:feature_id)
        )
      end

      def target_query(region)
        return nil if region[:target_elevation].nil?

        query_result(
          region.fetch(:target_elevation),
          'target',
          'featureId' => region.fetch(:feature_id)
        )
      end

      def planar_query(region, x, y)
        model = planar_model(region)
        return nil unless model

        query_result(model.height_at('x' => x, 'y' => y), 'planar',
                     'featureId' => region.fetch(:feature_id))
      end

      def planar_model(region)
        @planar_models[region.fetch(:feature_id)] ||= begin
          controls = region.fetch(:planar_controls, [])
          PlanarHeightModel.fit(controls)
        end
      end

      def compiled_semantic_regions
        raw_semantic_regions.map { |region| compile_region(region) }
                            .sort_by { |region| precedence_sort_key(region) }
      end

      def raw_semantic_regions
        return [] unless feature_geometry.respond_to?(:oracle_semantic_regions)

        feature_geometry.oracle_semantic_regions
      end

      def compile_region(region)
        normalized = region.transform_keys(&:to_s)
        {
          feature_id: normalized.fetch('featureId'),
          source_category: normalized.fetch('sourceCategory'),
          revision: normalized.fetch('revision', 0).to_i,
          primitive: normalized.fetch('primitive'),
          control_elevation: numeric_or_nil(normalized['controlElevation']),
          target_elevation: numeric_or_nil(normalized['targetElevation']),
          planar_controls: normalized.fetch('planarControls', []),
          shape: compile_shape(normalized)
        }
      end

      def precedence_sort_key(region)
        [
          precedence_rank(region.fetch(:source_category)),
          -region.fetch(:revision),
          region.fetch(:feature_id)
        ]
      end

      def compile_shape(region)
        TerrainOracleSemanticShape.compile(region)
      end

      def semantic_bounds_for(regions)
        first_shape = regions.first&.fetch(:shape)
        return nil unless first_shape

        initial_bounds = TerrainOracleSemanticShape.bounds(first_shape)
        regions.drop(1).each_with_object(initial_bounds) do |region, bounds|
          shape = region.fetch(:shape)
          bounds[0] = [bounds.fetch(0), shape.fetch(:min_x)].min
          bounds[1] = [bounds.fetch(1), shape.fetch(:max_x)].max
          bounds[2] = [bounds.fetch(2), shape.fetch(:min_y)].min
          bounds[3] = [bounds.fetch(3), shape.fetch(:max_y)].max
        end
      end

      def semantic_bounds_contain_xy?(x, y)
        return false unless @semantic_bounds

        x.between?(@semantic_bounds.fetch(0), @semantic_bounds.fetch(1)) &&
          y.between?(@semantic_bounds.fetch(2), @semantic_bounds.fetch(3))
      end

      def shape_bounds_contain_xy?(shape, x, y)
        TerrainOracleSemanticShape.bounds_contain_xy?(shape, x, y)
      end

      def contains_xy?(region, x, y)
        shape = region.fetch(:shape)
        case shape.fetch(:type)
        when :point
          point_contains_xy?(shape, x, y)
        when :circle
          circle_contains_xy?(shape, x, y)
        when :rectangle
          rectangle_contains_xy?(shape, x, y)
        end
      end

      def point_contains_xy?(shape, x, y)
        (((x - shape.fetch(:x))**2) + ((y - shape.fetch(:y))**2)) <=
          TOLERANCE_SQUARED
      end

      def circle_contains_xy?(shape, x, y)
        dx = x - shape.fetch(:x)
        dy = y - shape.fetch(:y)
        distance_squared = (dx * dx) + (dy * dy)
        distance_squared <= shape.fetch(:radius_with_tolerance_squared)
      end

      def rectangle_contains_xy?(shape, x, y)
        x.between?(shape.fetch(:min_x), shape.fetch(:max_x)) &&
          y.between?(shape.fetch(:min_y), shape.fetch(:max_y))
      end

      def numeric_or_nil(value)
        value&.to_f
      end

      def query_result(height, source_category, extra = {})
        { 'height' => height, 'sourceCategory' => source_category }.merge(extra)
      end
    end
  end
end
