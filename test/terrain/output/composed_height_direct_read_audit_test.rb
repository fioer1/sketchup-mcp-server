# frozen_string_literal: true

require_relative '../../test_helper'

class ComposedHeightDirectReadAuditTest < Minitest::Test
  TARGETS = [
    'src/su_mcp/terrain/output/adaptive_output_conformity.rb',
    'src/su_mcp/terrain/output/feature_aware_diagonal_optimizer.rb',
    'src/su_mcp/terrain/output/terrain_output_plan.rb',
    'src/su_mcp/terrain/output/terrain_mesh_generator.rb',
    'src/su_mcp/terrain/probes/feature_aware_adaptive_baseline_quality_sampler.rb'
  ].freeze

  ALLOWED_DIRECT_READ_PATTERNS = [
    /state\.elevations\.any\?\(&:nil\?\)/,
    /state\.elevations\.each_with_index/,
    /coarse_pruning_bounds_only/,
    /low_level_state_without_oracle/
  ].freeze

  def test_behavior_defining_output_height_reads_are_oracle_backed_or_classified
    violations = TARGETS.flat_map do |path|
      root = File.expand_path('../../..', __dir__)
      File.readlines(File.join(root, path)).filter_map.with_index(1) do |line, number|
        next unless direct_height_read?(line)
        next if ALLOWED_DIRECT_READ_PATTERNS.any? { |pattern| line.match?(pattern) }

        "#{path}:#{number}: #{line.strip}"
      end
    end

    assert_empty(
      violations,
      'Unclassified direct height reads must route through the composed oracle or be ' \
      'classified as base mutation/storage/no-data/coarse-pruning/prototype:' \
      "\n" \
      "#{violations.join("\n")}"
    )
  end

  private

  def direct_height_read?(line)
    line.include?('state.elevations') ||
      line.include?('TerrainStateElevationSampler.new(state)') ||
      line.match?(/\belevations\[/)
  end
end
