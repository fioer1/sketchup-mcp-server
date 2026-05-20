# frozen_string_literal: true

require_relative 'planar_occlusion_geometry'

module SU_MCP
  module Terrain
    # Clips older feature-output geometry hidden by later absolute planar regions.
    class PlanarOcclusionClipper
      def initialize(absolute_planar_regions:, feature_revisions:)
        @absolute_planar_regions = absolute_planar_regions
        @feature_revisions = feature_revisions
      end

      def clip(anchors:, pressure_regions:, reference_segments:, limitations:)
        @limitations = limitations.dup
        {
          anchors: clipped_anchors(anchors),
          pressure_regions: pressure_regions.flat_map { |region| clipped_pressure_regions(region) },
          reference_segments: reference_segments.flat_map do |segment|
            clipped_reference_segments(segment)
          end,
          limitations: @limitations
        }
      end

      private

      attr_reader :absolute_planar_regions, :feature_revisions

      def clipped_anchors(anchors)
        anchors.reject do |anchor|
          anchor.fetch('strength') != 'hard' && occluded_point?(
            anchor.fetch('featureId'),
            anchor.fetch('ownerLocalPoint')
          )
        end
      end

      def clipped_pressure_regions(region)
        return [region] if region.fetch('role').to_s.include?('protected')

        absolute_planar_regions.reduce([region]) do |regions, planar|
          regions.flat_map { |entry| clip_pressure_region_for_planar(entry, planar) }
        end
      end

      def clipped_reference_segments(segment)
        absolute_planar_regions.reduce([segment]) do |segments, planar|
          segments.flat_map { |entry| clip_reference_segment_for_planar(entry, planar) }
        end
      end

      def clip_pressure_region_for_planar(region, planar)
        return [region] unless newer_planar_region?(planar, region.fetch('featureId'))

        planar_region = planar.fetch(:region)
        return [] if PlanarOcclusionGeometry.entry_contained_by_region?(region, planar_region)

        if planar_region.fetch('primitive') == 'rectangle'
          return subtract_rectangle_from_pressure(region, planar_region)
        end

        record_partial_circular_planar_limitation(region, planar) if
          PlanarOcclusionGeometry.entry_intersects_region?(region, planar_region)
        [region]
      end

      def clip_reference_segment_for_planar(segment, planar)
        return [segment] unless newer_planar_region?(planar, segment.fetch('featureId'))

        planar_region = planar.fetch(:region)
        return [] if PlanarOcclusionGeometry.segment_contained_by_region?(segment, planar_region)

        if planar_region.fetch('primitive') == 'rectangle'
          return subtract_rectangle_from_segment(segment, planar_region)
        end

        record_partial_circular_planar_limitation(segment, planar) if
          PlanarOcclusionGeometry.entry_intersects_region?(segment, planar_region)
        [segment]
      end

      def newer_planar_region?(planar, feature_id)
        planar.fetch(:revision) > feature_revisions.fetch(feature_id, 0)
      end

      def occluded_point?(feature_id, point)
        absolute_planar_regions.any? do |planar|
          next false unless planar.fetch(:revision) > feature_revisions.fetch(feature_id, 0)

          PlanarOcclusionGeometry.point_contained_by_region?(point, planar.fetch(:region))
        end
      end

      def subtract_rectangle_from_pressure(region, planar_region)
        return [region] unless %w[rectangle circle].include?(region['primitive'])

        source_bounds = PlanarOcclusionGeometry.bounds_for_entry(region)
        clip_bounds = PlanarOcclusionGeometry.intersection_bounds(
          source_bounds,
          PlanarOcclusionGeometry.bounds_for_region(planar_region)
        )
        return [region] unless clip_bounds

        PlanarOcclusionGeometry
          .outside_rectangles(source_bounds, clip_bounds)
          .map { |name, bounds| pressure_fragment(region, name, bounds) }
      end

      def subtract_rectangle_from_segment(segment, planar_region)
        clip_interval = PlanarOcclusionGeometry.segment_rectangle_clip_interval(
          segment.fetch('ownerLocalStart'),
          segment.fetch('ownerLocalEnd'),
          PlanarOcclusionGeometry.bounds_for_region(planar_region)
        )
        return [segment] unless clip_interval

        PlanarOcclusionGeometry
          .outside_segment_intervals(clip_interval)
          .map
          .with_index { |interval, index| segment_fragment(segment, interval, index) }
      end

      def pressure_fragment(region, name, bounds)
        region.merge(
          'id' => "#{region.fetch('id')}:outside-#{name}",
          'primitive' => 'rectangle',
          'ownerLocalShape' => PlanarOcclusionGeometry.bounds_to_shape(bounds)
        )
      end

      def segment_fragment(segment, interval, index)
        start_point = PlanarOcclusionGeometry.segment_point_at(
          segment.fetch('ownerLocalStart'),
          segment.fetch('ownerLocalEnd'),
          interval.fetch(0)
        )
        end_point = PlanarOcclusionGeometry.segment_point_at(
          segment.fetch('ownerLocalStart'),
          segment.fetch('ownerLocalEnd'),
          interval.fetch(1)
        )
        segment.merge(
          'id' => "#{segment.fetch('id')}:outside-#{index}",
          'ownerLocalStart' => start_point,
          'ownerLocalEnd' => end_point
        )
      end

      def record_partial_circular_planar_limitation(entry, planar)
        @limitations << {
          'featureId' => entry.fetch('featureId'),
          'category' => 'planar_occlusion_clipping',
          'reason' => "partial circular planar occlusion by #{planar.fetch(:feature_id)} " \
                      'is unsupported; retained primitive'
        }
      end
    end
  end
end
