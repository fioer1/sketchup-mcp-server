# Summary: MTA-46 Make Fairing Output Pressure Residual-Aware

**Task ID**: `MTA-46`
**Status**: `implemented`
**Date**: `2026-05-20`

## Shipped Behavior

- Added internal fairing-only density classification in
  `FeatureAwareAdaptivePolicy#split_pressure_for`.
- Tightened fairing-only density output tolerance to the advisory output band
  (`base_tolerance * 0.5`, currently `0.005m` for the replay harness).
- Updated adaptive split probing so fairing-only density pressure cannot force a split unless the
  residual exceeds the local tolerance.
- Updated planar compaction so broad advisory `fairing_support` and `survey_anchor` density
  pressure no longer vetoes low-error planar coalescing.
- Added a residual guard for advisory-touched planar compaction so high-residual fairing/falloff
  edges stay split instead of being merged into the coarse center.
- Disabled the planar residual-probe shortcut for advisory-guarded cells, so fairing/falloff edge
  residual can split below the fairing target cell size.
- Preserved existing `target_support`, `hard_break`, forced-anchor, and bumpy fairing behavior.
- Kept public MCP terrain command names, schemas, dispatcher routes, response shapes, docs, and
  public refusal behavior unchanged.

## Coverage

- Policy tests prove:
  - circular `fairing_support` pressure is marked as fairing-only;
  - fairing-only split pressure uses `0.005m` tolerance;
  - `target_support` and `hard_break` density pressure stay outside the fairing gate;
  - planar compaction ignores fairing-only and broad survey-support density pressure;
  - planar compaction still respects overlapping authoritative target pressure;
  - actual survey anchors remain forced detail.
- Output-plan tests prove:
  - low-residual circular fairing-only pressure does not split a flat cell;
  - bumpy circular fairing still refines where residual exceeds tolerance;
  - mixed circular fairing can coarsen low-error cells and refine high-error cells;
  - the fairing gate uses one residual probe per split decision;
  - overlapping forced-anchor detail remains authoritative;
  - fairing-only density no longer blocks low-error planar coalescing;
  - high-residual fairing planar edges remain split;
  - advisory planar residual can split below the fairing target cell size.

## Validation Evidence

- `bundle exec ruby -Itest test/terrain/output/feature_aware_adaptive_policy_test.rb`
  - `18 runs`, `59 assertions`, `0 failures`, `0 errors`
- `bundle exec ruby -Itest test/terrain/output/terrain_output_plan_test.rb`
  - `33 runs`, `284 assertions`, `0 failures`, `0 errors`
- `bundle exec ruby -Itest test/terrain/contracts/terrain_contract_stability_test.rb`
  - `16 runs`, `6647 assertions`, `0 failures`, `0 errors`
- `bundle exec rake ruby:test`
  - `1498 runs`, `17974 assertions`, `0 failures`, `0 errors`, `41 skips`
- `bundle exec rake ruby:lint`
  - `364 files inspected`, `no offenses detected`
- `bundle exec rake package:verify`
  - emitted `dist/su_mcp-1.11.0.rbz`
- `tldr bugbot check --format json --no-fail --quiet --base-ref HEAD .`
  - `0` findings
  - note: bugbot's embedded RuboCop tool hit a read-only global cache path, but the separate repo
    RuboCop run above passed cleanly.

## Live SketchUp Deployment

The changed runtime files were copied into the SketchUp 2026 plugin support tree and reloaded
through the live MCP runtime at `172.23.240.1:9877`:

- `terrain/output/feature_aware_adaptive_policy.rb`
- `terrain/output/terrain_output_plan.rb`

Reload result:

- `mta46 residual-aware fairing policy reloaded`

## Hosted Diagnostic

Targeted hosted diagnostics on the cumulative large timing sequence showed the failure mode and the
final center/edge correction:

- Original broken behavior:
  - `large-varied-fairing-envelope-timing`: `56823` faces
  - planar interior: `1318` cells, `2636` faces
  - planar histogram: only dense `1x1`, `2x2`, and `4x4` cells
- First planar-compaction correction:
  - `large-varied-fairing-envelope-timing`: `54318` faces
  - planar interior: `111` cells
  - issue: center coalesced, but edge/falloff detail was over-coalesced
- Final residual-aware correction:
  - `large-varied-fairing-envelope-timing`: `54814` faces in the diagnostic capture
  - planar interior: `240` cells
  - histogram includes coarse center cells such as `16x16`, `14x16`, and `16x14`, while retaining
    small edge/falloff cells such as `1x*`, `2x*`, and `2x2`

The diagnostic JSON was pruned after the final three-run perf pack was retained.

## Hosted Replay Harness

After deploy/reload, the full hosted feature-aware adaptive replay harness was run through the live
SketchUp MCP runtime using the canonical replay corpus with `include_timing: true` and
`include_quality: true`.

- Result pack was used for validation and then pruned after the final three-run perf pack was
  retained.
- Rows captured: `18`

Key hosted quality rows:

- `large-varied-planar-pad-timing`
  - faces: `66523`
  - vertices: `33777`
  - planar interior planned metric: `106` cells, `212` faces, `184` vertices
  - planar-region quality: `100.0%` within local tolerance, max error `0.004815m`
- `large-varied-fairing-envelope-timing`
  - faces: `55097`
  - vertices: `27883`
  - planar interior planned metric: `320` cells, `640` faces, `514` vertices
  - fairing-region quality: `100.0%` within local tolerance, max error `0.004277m`
  - planar-region quality inside the same row: `100.0%` within local tolerance, max error
    `0.004568m`
- `wide-varied-fairing-large-timing`
  - faces: `24360`
  - vertices: `12378`
  - fairing-region quality: `100.0%` within local tolerance, max error `0.008093m`

## Perf Runs

Three full hosted timing captures were run with `include_timing: true`,
`include_quality: false`, and `clear_existing: true`.

- `test/terrain/replay/feature_aware_adaptive_baseline_results_mta46_perf_run_1.json`
- `test/terrain/replay/feature_aware_adaptive_baseline_results_mta46_perf_run_2.json`
- `test/terrain/replay/feature_aware_adaptive_baseline_results_mta46_perf_run_3.json`

Perf totals:

- run 1: `79.7706s`
- run 2: `78.7939s`
- run 3: `80.3252s`
- mean: `79.6299s`
- geometry stability: `18/18` stable face-count rows and `18/18` stable vertex-count rows

Selected perf rows:

- `large-varied-planar-pad-timing`: `66523` faces, run seconds `11.8682`, `11.6048`, `11.8960`
- `large-varied-fairing-envelope-timing`: `55097` faces, `27883` vertices, planar interior
  `640` faces, run seconds `12.5294`, `12.2179`, `12.2030`
- `wide-varied-fairing-large-timing`: `24360` faces, `12378` vertices, run seconds `6.4629`,
  `6.9294`, `6.6003`

## Classifier Comparison

Classifier annotation against `feature_aware_adaptive_baseline_results_mta45_coalesced.json`:

- The annotated JSON was pruned after the final three-run perf pack was retained.
- Verdicts: `10` `policy_applied`, `6` `regressed`, `2` `neutral`
- The `regressed` verdicts are timing-classifier verdicts; the three hosted perf runs above confirm
  stable geometry for all `18` replay rows.

Selected row comparisons:

- `large-varied-planar-pad-timing`
  - face delta: `0`
  - planar-interior face delta: `0`
- `large-varied-fairing-envelope-timing`
  - face delta: `-1729`
  - planar-interior face delta: `-1996`
  - planar-interior vertex delta: `-950`
  - dirty window and patch scope unchanged
- `wide-varied-fairing-large-timing`
  - face delta: `-6`
  - dirty window and patch scope unchanged

## Remaining Gaps

- The hosted fairing-over-planar row now coalesces the flat center and preserves residual edge
  detail, but other overlapping corridor endpoint/side-transition quality signals remain outside
  the MTA-46 fairing/planar scope.
- No public docs were changed because no public MCP contract, schema, command, setup path, or
  user-facing workflow changed.
- Step 07 calibration was intentionally not run yet.
