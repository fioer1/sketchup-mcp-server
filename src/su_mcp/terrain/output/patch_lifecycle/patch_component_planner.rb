# frozen_string_literal: true

require_relative 'patch_window_resolver'

module SU_MCP
  module Terrain
    module PatchLifecycle
      # Builds bounded internal patch components for dirty adaptive replacement.
      class PatchComponentPlanner
        DEFAULT_BUDGET = {
          maxReplacementPatchCount: 25,
          maxPromotionRadius: 2
        }.freeze

        def initialize(policy:, dimensions:)
          @policy = policy
          @dimensions = dimensions
        end

        def default_budget
          DEFAULT_BUDGET.dup
        end

        def resolve(
          cell_window:,
          feature_windows: [],
          protected_windows: [],
          retained_seam_dependencies: [],
          safety_margin_windows: [],
          local_detail_windows: [],
          budget: nil
        )
          validate_local_detail_sources!(local_detail_windows)

          affected_coords = coords_for_window(cell_window)
          component_coords = affected_coords.dup
          graph_reasons = ['dirty_window']

          component_coords = add_source_coords(
            component_coords,
            feature_windows,
            graph_reasons,
            'feature_boundary_crossing'
          )
          component_coords = add_source_coords(
            component_coords,
            protected_windows,
            graph_reasons,
            'protected_boundary_crossing'
          )
          retained_coords = retained_dependency_coords(retained_seam_dependencies)
          unless retained_coords.empty?
            component_coords = (component_coords + retained_coords).uniq
            graph_reasons << 'retained_seam_dependency'
          end

          replacement_coords = patch_coords_with_ring(component_coords)
          safety_coords = windows_to_coords(safety_margin_windows)
          component_promoted = (component_coords - affected_coords).any?
          if (component_promoted || !safety_coords.empty?) &&
             (replacement_coords - component_coords).any?
            graph_reasons << 'conformance'
          end

          build_resolution(
            affected_coords: affected_coords,
            component_coords: component_coords,
            replacement_coords: replacement_coords,
            retained_coords: retained_coords,
            safety_coords: safety_coords,
            graph_reasons: graph_reasons,
            budget: normalize_budget(budget)
          )
        end

        private

        attr_reader :policy, :dimensions

        def validate_local_detail_sources!(local_detail_windows)
          return if Array(local_detail_windows).empty?

          raise ArgumentError, 'non-empty local-detail boundary sources are unsupported in MTA-43'
        end

        def add_source_coords(component_coords, windows, graph_reasons, reason)
          coords = windows_to_coords(windows)
          return component_coords if coords.empty?

          graph_reasons << reason if crossing_source?(coords) || (coords - component_coords).any?
          (component_coords + coords).uniq
        end

        def crossing_source?(coords)
          coords.map { |coord| [coord.fetch(:column), coord.fetch(:row)] }.uniq.length > 1
        end

        def retained_dependency_coords(dependencies)
          Array(dependencies).filter_map do |dependency|
            patch_id = dependency.fetch(:neighborPatchId) do
              dependency.fetch('neighborPatchId', nil)
            end
            patch_id && parse_patch_id(patch_id)
          end.uniq
        end

        def build_resolution(
          affected_coords:,
          component_coords:,
          replacement_coords:,
          retained_coords:,
          safety_coords:,
          graph_reasons:,
          budget:
        )
          affected_ids = patch_ids(affected_coords)
          component_ids = patch_ids(component_coords)
          replacement_ids = patch_ids(replacement_coords)
          retained_ids = patch_ids(retained_coords)
          safety_ids = patch_ids(safety_coords)
          conformance_ids = replacement_ids - component_ids
          {
            affectedPatchIds: affected_ids,
            replacementPatchIds: replacement_ids,
            affectedPatches: patch_domains(affected_coords),
            replacementPatches: patch_domains(replacement_coords),
            conformanceRing: policy.conformance_ring,
            retainedBoundaryPatchIds: retained_ids,
            retainedBoundaryPatches: patch_domains(retained_coords),
            safetyMarginPatchIds: safety_ids,
            safetyMarginPatches: patch_domains(safety_coords),
            componentPlanSummary: component_summary(
              component_ids: component_ids,
              replacement_ids: replacement_ids,
              affected_ids: affected_ids,
              retained_ids: retained_ids,
              safety_ids: safety_ids,
              conformance_ids: conformance_ids,
              graph_reasons: graph_reasons
            ),
            componentBudget: budget_summary(
              budget,
              affected_coords: affected_coords,
              component_coords: component_coords,
              replacement_ids: replacement_ids
            )
          }
        end

        def component_summary(
          component_ids:,
          replacement_ids:,
          affected_ids:,
          retained_ids:,
          safety_ids:,
          conformance_ids:,
          graph_reasons:
        )
          {
            componentCount: component_ids.empty? ? 0 : 1,
            maxComponentSize: component_ids.length,
            promotedCount: (component_ids - affected_ids).length,
            roleCounts: {
              affected: affected_ids.length,
              replacement: replacement_ids.length,
              conformance: conformance_ids.length,
              retained_boundary: retained_ids.length,
              safety_margin: safety_ids.length
            },
            graphReasons: graph_reasons.uniq
          }
        end

        def budget_summary(budget, affected_coords:, component_coords:, replacement_ids:)
          status = if over_budget?(budget, affected_coords, component_coords, replacement_ids)
                     'over_budget'
                   else
                     'within_budget'
                   end
          {
            status: status,
            maxReplacementPatchCount: budget.fetch(:maxReplacementPatchCount),
            maxPromotionRadius: budget.fetch(:maxPromotionRadius),
            evidence: budget_evidence(affected_coords, replacement_ids)
          }
        end

        def budget_evidence(affected_coords, replacement_ids)
          total_patch_count = policy.patch_domains(dimensions).length
          affected_count = [affected_coords.length, 1].max
          {
            replacementToAffectedRatio: replacement_ids.length.to_f / affected_count,
            fullGridProximity: full_grid_proximity(replacement_ids, total_patch_count)
          }
        end

        def full_grid_proximity(replacement_ids, total_patch_count)
          return 0.0 if total_patch_count.zero?

          replacement_ids.length.to_f / total_patch_count
        end

        def over_budget?(budget, affected_coords, component_coords, replacement_ids)
          replacement_ids.length > budget.fetch(:maxReplacementPatchCount) ||
            promotion_radius(affected_coords, component_coords) > budget.fetch(:maxPromotionRadius)
        end

        def promotion_radius(affected_coords, component_coords)
          component_coords.map do |coord|
            affected_coords.map { |affected| patch_distance(affected, coord) }.min || 0
          end.max || 0
        end

        def patch_distance(first, second)
          (first.fetch(:column) - second.fetch(:column)).abs +
            (first.fetch(:row) - second.fetch(:row)).abs
        end

        def normalize_budget(value)
          default_budget.merge(value || {})
        end

        def windows_to_coords(windows)
          Array(windows).flat_map { |window| coords_for_window(window) }.uniq
        end

        def coords_for_window(window)
          min_patch = policy.patch_coords_for(
            column: window_value(window, :min_column, :minColumn),
            row: window_value(window, :min_row, :minRow)
          )
          max_patch = policy.patch_coords_for(
            column: window_value(window, :max_column, :maxColumn),
            row: window_value(window, :max_row, :maxRow)
          )
          (min_patch.fetch(:row)..max_patch.fetch(:row)).flat_map do |row|
            (min_patch.fetch(:column)..max_patch.fetch(:column)).map do |column|
              { column: column, row: row }
            end
          end
        end

        def window_value(window, method_name, hash_key)
          return window.public_send(method_name) if window.respond_to?(method_name)

          direct = optional_hash_value(window, method_name, hash_key, hash_key.to_s)
          return direct unless direct.nil?

          boundary = method_name.to_s.start_with?('min') ? 'min' : 'max'
          axis = method_name.to_s.include?('column') ? 'column' : 'row'
          nested = optional_hash_value(window, boundary.to_sym, boundary)
          return optional_hash_value(nested, axis.to_sym, axis) if nested

          window.fetch(method_name)
        end

        def optional_hash_value(hash, *keys)
          return nil unless hash.respond_to?(:key?) && hash.respond_to?(:fetch)

          key = keys.find { |candidate| hash.key?(candidate) }
          key.nil? ? nil : hash.fetch(key)
        end

        def patch_coords_with_ring(coords)
          max_bounds = policy.patch_grid_bounds(dimensions)
          coords.flat_map do |coord|
            rows = clipped_range(coord.fetch(:row), max_bounds.fetch(:max_patch_row))
            columns = clipped_range(coord.fetch(:column), max_bounds.fetch(:max_patch_column))
            rows.flat_map { |row| columns.map { |column| { column: column, row: row } } }
          end.uniq
        end

        def clipped_range(value, max_value)
          ([value - policy.conformance_ring, 0].max)..(
            [value + policy.conformance_ring, max_value].min
          )
        end

        def patch_ids(coords)
          coords.map { |coord| policy.patch_id_for_coords(coord.fetch(:column), coord.fetch(:row)) }
                .sort
        end

        def patch_domains(coords)
          domains = coords.map do |coord|
            policy.patch_domain(coord.fetch(:column), coord.fetch(:row), dimensions)
          end
          domains.sort_by { |patch| patch.fetch(:patchId) }
        end

        def parse_patch_id(patch_id)
          match = patch_id.match(/-c(\d+)-r(\d+)\z/)
          raise ArgumentError, "invalid patch id: #{patch_id}" unless match

          { column: match.captures.fetch(0).to_i, row: match.captures.fetch(1).to_i }
        end
      end
    end
  end
end
