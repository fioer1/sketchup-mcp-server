# frozen_string_literal: true

require_relative 'feature_intent_set'

module SU_MCP
  module Terrain
    # Builds normalized feature regions consumed by composed height semantics.
    class TerrainOracleSemanticRegionBuilder
      def build(feature)
        region = oracle_region_for(feature)
        return nil unless region

        region.merge(
          'id' => "#{feature.fetch('id')}:oracle-semantic",
          'featureId' => feature.fetch('id'),
          'kind' => feature.fetch('kind'),
          'role' => oracle_role_for(feature),
          'sourceCategory' => source_category_for(feature),
          'revision' => feature_revision(feature)
        ).merge(oracle_payload_for(feature))
      end

      private

      def feature_revision(feature)
        Integer(feature.dig('provenance', 'updatedAtRevision') ||
          feature.dig('lifecycle', 'updatedAtRevision') ||
          0)
      end

      def oracle_region_for(feature)
        payload = FeatureIntentSet.stringify_keys(feature.fetch('payload', {}))
        case feature.fetch('kind')
        when 'preserve_region', 'planar_region', 'target_region', 'fairing_region',
             'inferred_heightfield'
          primitive_region(payload.fetch('region'))
        when 'fixed_control'
          fixed_control_region(payload.fetch('control', {}))
        when 'survey_control'
          return nil unless payload.key?('supportRegion')

          primitive_region(payload.fetch('supportRegion'))
        end
      end

      def primitive_region(region_payload)
        region = FeatureIntentSet.stringify_keys(region_payload || {})
        case region.fetch('type')
        when 'rectangle'
          rectangle_region(region.fetch('bounds'))
        when 'circle'
          circle_region(region)
        else
          raise ArgumentError, "unsupported region primitive #{region['type'].inspect}"
        end
      end

      def rectangle_region(bounds)
        {
          'primitive' => 'rectangle',
          'ownerLocalBounds' => [
            [bounds.fetch('minX'), bounds.fetch('minY')],
            [bounds.fetch('maxX'), bounds.fetch('maxY')]
          ]
        }
      end

      def circle_region(region)
        center = region.fetch('center')
        {
          'primitive' => 'circle',
          'ownerLocalCenterRadius' => [
            center.fetch('x'), center.fetch('y'), region.fetch('radius')
          ]
        }
      end

      def fixed_control_region(control_payload)
        control = FeatureIntentSet.stringify_keys(control_payload || {})
        point = FeatureIntentSet.stringify_keys(control.fetch('point', {}))
        return nil unless fixed_control_elevation(control, point)

        {
          'primitive' => 'point',
          'ownerLocalPoint' => [point.fetch('x'), point.fetch('y')]
        }
      end

      def oracle_payload_for(feature)
        payload = FeatureIntentSet.stringify_keys(feature.fetch('payload', {}))
        case feature.fetch('kind')
        when 'fixed_control'
          control = FeatureIntentSet.stringify_keys(payload.fetch('control', {}))
          point = FeatureIntentSet.stringify_keys(control.fetch('point', {}))
          elevation = fixed_control_elevation(control, point)
          elevation ? { 'controlElevation' => elevation } : {}
        when 'target_region'
          target = payload['targetElevation'] || payload.dig('operation', 'targetElevation')
          target ? { 'targetElevation' => target } : {}
        when 'planar_region'
          controls = payload['planarControls'] || payload['controls'] ||
                     payload.dig('constraints', 'planarControls')
          controls ? { 'planarControls' => controls } : {}
        else
          {}
        end
      end

      def oracle_role_for(feature)
        return 'protected' if feature.fetch('kind') == 'preserve_region'
        return 'planar' if feature.fetch('kind') == 'planar_region'
        return 'target' if feature.fetch('kind') == 'target_region'

        Array(feature.fetch('roles', [])).first || 'support'
      end

      def source_category_for(feature)
        case feature.fetch('kind')
        when 'preserve_region' then 'preserve'
        when 'planar_region' then 'planar'
        when 'target_region' then 'target'
        when 'fixed_control' then 'fixed'
        else 'support'
        end
      end

      def fixed_control_elevation(control, point)
        return control['elevation'] if control.key?('elevation')

        point['z']
      end
    end
  end
end
