# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Classifies hosted replay rows by comparing a current result pack to its baseline pack.
    class FeatureAwareAdaptiveBaselineResultClassifier
      TIMING_REGRESSION_PERCENT = 25.0
      FACE_GROWTH_REGRESSION_PERCENT = 15.0

      def self.annotate(baseline_document:, current_document:)
        new(baseline_document: baseline_document, current_document: current_document).annotate
      end

      def initialize(baseline_document:, current_document:)
        @baseline_rows = baseline_document.fetch('rows').to_h { |row| [row.fetch('rowId'), row] }
        @current_document = current_document
      end

      def annotate
        current_document.merge(
          'rows' => current_document.fetch('rows').map { |row| annotate_row(row) }
        )
      end

      private

      attr_reader :baseline_rows, :current_document

      def annotate_row(row)
        baseline = baseline_rows[row.fetch('rowId')]
        verdict, reason = classify(row, baseline)
        row.merge(
          'verdict' => verdict,
          'verdictReason' => reason,
          'comparison' => comparison(row, baseline)
        )
      end

      def classify(row, baseline)
        return ['failed', 'missing baseline row'] unless baseline
        return ['failed', 'row refused or lacks mesh evidence'] unless accepted_mesh_row?(row)
        return ['failed', 'missing adaptive policy summary'] unless row['adaptivePolicySummary']

        validation_failure = validation_failure_reason(row)
        return ['failed', validation_failure] if validation_failure

        regression = regression_reason(row, baseline)
        return ['regressed', regression] if regression
        return ['policy_applied', policy_applied_reason(row, baseline)] if
          (feature_policy_applied?(row) || diagonal_adopted?(row)) && quality_captured?(row)

        ['neutral', delta_reason(row, baseline)]
      end

      def regression_reason(row, baseline)
        unexpected_fallback = unexpected_component_fallback_reason(row)
        return unexpected_fallback if unexpected_fallback
        return 'dirty window or patch scope changed' if
          scope_changed?(row, baseline) && !expected_component_change?(row)
        return 'timing exceeded regression threshold' if
          timing_delta_percent(row, baseline) > TIMING_REGRESSION_PERCENT &&
          !expected_component_change?(row)
        return 'face-count growth exceeded density threshold' if
          face_delta_percent(row, baseline) > FACE_GROWTH_REGRESSION_PERCENT &&
          !expected_component_change?(row)

        nil
      end

      def validation_failure_reason(row)
        return 'seam validation failed' if seam_validation_failed?(row)
        return 'supported forced subdivision pressure was skipped' if
          forced_subdivision_skipped?(row)

        nil
      end

      def unexpected_component_fallback_reason(row)
        return nil unless component_fallback(row)
        return nil if row['expectedFallback']

        "unexpected component fallback #{component_fallback(row)}"
      end

      def accepted_mesh_row?(row)
        row['outcome'] != 'refused' && row['faceCount']
      end

      def seam_validation_failed?(row)
        summary = row['seamValidationSummary']
        summary && summary['status'] == 'failed'
      end

      def scope_changed?(row, baseline)
        row['dirtyWindow'] != baseline['dirtyWindow'] ||
          patch_scope(row) != patch_scope(baseline)
      end

      def expected_component_change?(row)
        expected_component_promotion?(row) ||
          expected_component_over_budget?(row) ||
          expected_component_fallback?(row)
      end

      def expected_component_promotion?(row)
        return false unless row['expectedPromotion']

        summary = row['componentPlanSummary'] || {}
        summary.fetch('promotedCount', 0).to_i.positive?
      end

      def expected_component_fallback?(row)
        row['expectedFallback'] && component_fallback(row)
      end

      def expected_component_over_budget?(row)
        row['expectedOverBudget'] && component_budget_status(row) == 'over_budget'
      end

      def feature_policy_applied?(row)
        return false if broad_corridor_density_only?(row)

        policy_signal_count(row.fetch('adaptivePolicySummary')).positive?
      end

      def diagonal_adopted?(row)
        summary = row['diagonalOptimizationSummary'] || {}
        summary.fetch('changedCount', 0).to_i.positive? &&
          summary.fetch('residualImprovement', 0.0).to_f.positive? &&
          summary['proofCell'] &&
          summary['adoptionVerdict'] == 'adopt'
      end

      def policy_signal_count(summary)
        [
          summary.fetch('densityHitCount', 0),
          summary.fetch('hardProtectedToleranceHitCount', 0),
          summary.key?('toleranceRange') ? 1 : 0,
          forced_hit_count(summary)
        ].sum(&:to_i)
      end

      def forced_subdivision_skipped?(row)
        summary = row.fetch('adaptivePolicySummary')
        forced = summary['forcedSubdivisionSummary'] || summary[:forcedSubdivisionSummary]
        return false unless forced
        return false unless supported_forced_input_count(forced).positive?

        forced_hit_count(summary).zero?
      end

      def supported_forced_input_count(forced_summary)
        counts = forced_summary['supportedInputCounts'] ||
                 forced_summary[:supportedInputCounts] ||
                 {}
        counts.values.sum(&:to_i)
      end

      def forced_hit_count(summary)
        forced = summary['forcedSubdivisionSummary'] || summary[:forcedSubdivisionSummary]
        return 0 unless forced

        (forced['hitCount'] || forced[:hitCount]).to_i
      end

      def broad_corridor_density_only?(row)
        summary = row.fetch('adaptivePolicySummary')
        return false unless summary.fetch('densityHitCount', 0).positive?
        return false if forced_hit_count(summary).positive?

        corridor_quality_only?(row)
      end

      def corridor_quality_only?(row)
        quality = row['featureQualitySummary'] || {}
        families = quality['families'] || {}
        roles = quality['roleSummaries'] || {}
        return false unless families.keys.map(&:to_s).sort == ['linear_corridor']

        (roles.keys.map(&:to_s) - ['centerline']).empty?
      end

      def quality_captured?(row)
        row.dig('featureQualitySummary', 'status') == 'captured'
      end

      def policy_applied_reason(row, baseline)
        reason = "feature policy applied; #{delta_reason(row, baseline)}"
        fallback_text = fallback_reason(row)
        fallback_text ? "#{reason}; #{fallback_text}" : reason
      end

      def delta_reason(row, baseline)
        time_delta = timing_delta_percent(row, baseline).round(1)
        "faces #{signed(face_delta(row, baseline))}, time #{signed(time_delta)}%"
      end

      def fallback_reason(row)
        counts = row.dig('adaptivePolicySummary', 'fallbackCounts') || {}
        active = counts.filter_map { |key, value| "#{key}=#{value}" if value.to_i.positive? }
        return nil if active.empty?

        "fallback #{active.join(', ')}"
      end

      def comparison(row, baseline)
        return {} unless baseline

        {
          'baselineFaceCount' => baseline['faceCount'],
          'faceCountDelta' => face_delta(row, baseline),
          'faceCountDeltaPercent' => face_delta_percent(row, baseline).round(1),
          'baselineSeconds' => baseline['seconds'],
          'secondsDeltaPercent' => timing_delta_percent(row, baseline).round(1),
          'dirtyWindowChanged' => row['dirtyWindow'] != baseline['dirtyWindow'],
          'patchScopeChanged' => patch_scope(row) != patch_scope(baseline),
          'expectedPromotion' => row['expectedPromotion'],
          'expectedOverBudget' => row['expectedOverBudget'],
          'expectedFallback' => row['expectedFallback'],
          'componentBudgetStatus' => component_budget_status(row),
          'componentFallback' => component_fallback(row),
          'diagonalAdoptionVerdict' => diagonal_adoption_verdict(row),
          'planarInterior' => planar_interior_comparison(row, baseline)
        }.compact
      end

      def diagonal_adoption_verdict(row)
        summary = row['diagonalOptimizationSummary'] || {}
        summary['adoptionVerdict']
      end

      def component_budget_status(row)
        budget = row['componentBudget'] || {}
        budget['status']
      end

      def component_fallback(row)
        budget = row['componentBudget'] || {}
        budget['fallbackCategory']
      end

      def planar_interior_comparison(row, baseline)
        current = row['planarInteriorMetrics']
        before = baseline['planarInteriorMetrics']
        return nil unless current && before

        {
          'baselineFaceCount' => before['faceCount'],
          'faceCountDelta' => current.fetch('faceCount').to_i - before.fetch('faceCount').to_i,
          'baselineVertexCount' => before['vertexCount'],
          'vertexCountDelta' => current.fetch('vertexCount').to_i -
            before.fetch('vertexCount').to_i,
          'qualityStatus' => current['qualityStatus']
        }.compact
      end

      def patch_scope(row)
        row['patchScope'] || row['affectedPatchScope']
      end

      def face_delta(row, baseline)
        row.fetch('faceCount').to_i - baseline.fetch('faceCount').to_i
      end

      def face_delta_percent(row, baseline)
        percent_delta(row.fetch('faceCount').to_f, baseline.fetch('faceCount').to_f)
      end

      def timing_delta_percent(row, baseline)
        percent_delta(row.fetch('seconds').to_f, baseline.fetch('seconds').to_f)
      end

      def percent_delta(current, baseline)
        return 0.0 unless baseline.positive?

        ((current - baseline) / baseline) * 100.0
      end

      def signed(value)
        value.positive? ? "+#{value}" : value.to_s
      end
    end
  end
end
