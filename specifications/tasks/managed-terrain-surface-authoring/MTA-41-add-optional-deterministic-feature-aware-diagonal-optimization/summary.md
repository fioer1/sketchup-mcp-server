# Summary: MTA-41 Add Optional Deterministic Feature-Aware Diagonal Optimization

**Task ID**: `MTA-41`
**Status**: `implemented`
**Local Validation Date**: `2026-05-25`
**Hosted Validation Status**: `passed; adoption supported`
**Adoption Verdict**: `adopted`
**Closeout Updated**: `2026-05-26`

## Shipped Local Behavior

- Added `FeatureAwareDiagonalOptimizer`, a pure deterministic two-candidate scorer for final
  rectangular adaptive cells.
- Optimizer scoring now precomputes candidate triangle planes, uses deterministic rectangle
  diagonal-line ownership for samples, streams baseline/alternate residual accumulation in one
  pass, and caches elevation/column-count access for the hot scoring path.
- Added predeclared internal thresholds for residual improvement, adoption residual effect, timing
  regression band, seam-adjacent non-regression, and feature-check budget.
- Scores both diagonal candidates against the same deterministic non-corner source-sample set using
  candidate triangle-plane residual.
- Keeps the existing lower-left to upper-right diagonal for exact ties, near-threshold ties,
  unsupported geometry, and cells without non-corner metric samples.
- Added `FeatureAwareDiagonalContext`, a derived feature/protection lookup view from effective
  feature geometry. It normalizes supported protected regions and reference segments once,
  bounds-gates exact checks, tracks skipped unsupported inputs, and distinguishes candidate safety
  when only one diagonal crosses a protected rectangle boundary.
- Integrated the optimizer in `AdaptiveOutputConformity` for four-vertex rectangular adaptive cells
  only. Center-fan conformance cells and regular-grid output remain unchanged.
- Added aggregate internal diagonal evidence: eligible count, changed count, reason counts,
  residual improvement, fixture-scoped proof-cell key, seam-adjacent changed count, optional
  seam-adjacent residual/dihedral deltas, feature-check summary, and adoption verdict.
- Threaded diagonal evidence through `TerrainOutputPlan`, command baseline evidence,
  `FeatureAwareAdaptiveBaselineReplay`, result document serialization, and classifier comparison.
- Extended public no-leak contract coverage for diagonal, proof-cell, optimizer, residual-delta,
  and candidate-topology vocabulary.
- Kept public MCP tool names, request schemas, dispatcher routes, public response shapes, and
  user-facing docs unchanged.

## Validation Evidence

- Initial skeleton red baseline:
  - `237 runs, 13160 assertions, 5 failures, 7 errors`
- Focused matrix after implementation:
  - `237 runs, 13230 assertions, 0 failures, 0 errors, 0 skips`
- Focused post-review safety-context check:
  - `bundle exec ruby -Itest test/terrain/output/feature_aware_adaptive_policy_test.rb`
  - `20 runs, 67 assertions, 0 failures, 0 errors, 0 skips`
- Focused post-review optimizer/plan check:
  - `bundle exec ruby -Itest -e 'ARGV.each { |path| require File.expand_path(path) }' test/terrain/output/feature_aware_diagonal_optimizer_test.rb test/terrain/output/terrain_output_plan_test.rb`
  - `48 runs, 345 assertions, 0 failures, 0 errors, 0 skips`
- Full Ruby tests after review follow-up:
  - `bundle exec rake ruby:test`
  - `1572 runs, 21624 assertions, 0 failures, 0 errors, 41 skips`
- Full Ruby lint after review follow-up:
  - `bundle exec rake ruby:lint`
  - `378 files inspected, no offenses detected`
- Package verification after review follow-up:
  - `bundle exec rake package:verify`
  - produced `dist/su_mcp-1.13.0.rbz`

## Code Review

- `$task-review --quick`-equivalent local checks were run over the changed terrain runtime surface
  after re-reading Step 06.
  - `RUBOCOP_CACHE_ROOT=tmp/.rubocop_cache tldr bugbot check --format json --no-fail --quiet --base-ref HEAD src/su_mcp/terrain`: `0` findings in the new optimizer/context files; the scoped run reported path-root artifacts for sibling changed files, but no actionable findings.
  - `tldr smells src/su_mcp/terrain --format json --quiet`: reported existing terrain hotspots and
    method-count smells, including `TerrainOutputPlan`, `TerrainMeshGenerator`, replay/classifier
    helpers, `FeatureAwareDiagonalContext`, and `FeatureAwareDiagonalOptimizer`. These remain
    observations rather than blockers because the task-owned additions keep the planned ownership
    split, focused tests cover the behavior, and full RuboCop passed.
  - `tldr hotspots src/su_mcp/terrain --format json --quiet`: confirmed the touched terrain output
    and replay files sit in existing high-churn/high-complexity areas; no new blocking issue was
    identified beyond the already accepted hosted-proof risk.
  - `tldr secure src/su_mcp/terrain --format json --quiet`: `0` findings.
  - The full `$task-review` subagent form was not run because the available subagent tool requires
    explicit user authorization to spawn agents. The Step 06 closeout therefore records the quick
    deterministic review plus this limitation instead of pretending the full agent review happened.
- PAL coverage-matrix review with `model: "gpt-5.4"` found real Step 03 gaps. The queue was revised
  before implementation to add threshold/config tests, explicit command-to-replay evidence
  propagation, proof-cell artifact coverage, seam-adjacent summary coverage, task-level
  adopt/defer/reject evidence, and diagonal no-leak vocabulary.
- PAL final code review with `model: "grok-4.3"` completed after local validation.
  - Accepted and fixed: candidate safety now distinguishes one unsafe protected-boundary diagonal
    from one safe diagonal.
  - Accepted and fixed: residual improvement is clamped to non-negative values.
  - Accepted and fixed: seam-adjacent changed cells are counted through a real checker when adaptive
    patch boundaries are available.
  - Rejected: possible stale `diagonalOptimizationSummary` after a command without an output plan.
    `record_baseline_evidence` already calls `reset_baseline_evidence!` when no output plan exists,
    clearing the whole evidence payload.
- Focused tests/lint and full Ruby test/lint/package verification were rerun after review follow-up.

## Contract And Docs

- Public terrain command contracts did not change.
- Contract no-leak coverage now blocks internal diagonal/proof/optimizer vocabulary from public
  success/refusal payloads.
- User-facing docs were reviewed by scope and were not updated because there is no public setup,
  request, response, schema, or workflow change.
- No finite public option set was added.

## Hosted Verification Status

- Live SketchUp bridge health check succeeded with `pong`.
- The final fresh post-restart optimized perf artifacts are retained in `test/terrain/replay/`,
  matching the existing replay-result convention:
  - `test/terrain/replay/feature_aware_adaptive_baseline_results_mta41_rubyopt_fresh_perf1_20260525T210012Z.json`
  - `test/terrain/replay/feature_aware_adaptive_baseline_results_mta41_rubyopt_fresh_perf2_20260525T210141Z.json`
  - `test/terrain/replay/feature_aware_adaptive_baseline_results_mta41_rubyopt_fresh_perf3_20260525T210308Z.json`
- Changed runtime/probe files were copied into the installed SketchUp plugin path, but the first
  broad reload attempt was cancelled by the user.
- A narrower hosted load check for the output files succeeded and confirmed:
  - `FeatureAwareDiagonalOptimizer` constant loaded;
  - `FeatureAwareDiagonalContext` constant loaded;
  - default diagonal config loaded;
  - `AdaptiveOutputConformity.diagonal_optimization_summary` is available.
- After fresh package deployment, the deployed extension loaded MTA-41 runtime and probe constants
  from the SketchUp plugin path and reported extension version `1.13.0`.
- Three hosted replay captures were run against the deployed package:
  - `feature_aware_adaptive_baseline_results_mta41_live_20260525T153954Z.json`
  - `feature_aware_adaptive_baseline_results_mta41_live_repeat2_20260525T154213Z.json`
  - `feature_aware_adaptive_baseline_results_mta41_live_repeat3_20260525T154342Z.json`
- All three captures produced `18` replay rows with `0` compact-result refusals.
- The diagonal decision signature was stable across all three captures:
  `c6c31bb8d4f6c41b0644df9e81ba6af2b8b886626a80d713486539b2989585b3`.
- The corpus naturally produced changed emitted diagonals in every row, so the targeted `x >= 50m`
  fallback proof was not needed for changed-diagonal evidence.
- Minimum changed diagonal count across live rows was `131`; minimum residual improvement was
  `0.2516500000000008`; every live row carried an `adopt` internal diagonal verdict and a
  fixture-scoped proof cell.
- The first hosted capture ran with quality sampling enabled: `15` rows captured feature quality
  and `3` create/timing setup rows were `not_applicable`.
- Every row had seam-adjacent changed cells and carried seam-adjacent residual/dihedral delta
  fields. Current deltas were `0.0`, so no residual or dihedral regression was recorded by the
  current aggregate metric.
- A hosted public-response no-leak smoke created `mta41-public-no-leak-live`; the public result
  contained `0` forbidden internal diagonal/proof/optimizer terms while internal baseline evidence
  still carried `diagonalOptimizationSummary`.
- Timing is the remaining caveat. Comparing current hosted captures to the checked-in
  `1.8.0` baseline result with the predeclared `25%` timing-regression band flagged:
  - run 1: `create-baseline` at `+54.8%`;
  - run 2: `create-baseline` at `+44.7%`;
  - run 3: `create-baseline` at `+44.1%` and `target-local-center` at `+26.5%`.
  These are small absolute changes on short rows and the comparison is across extension versions,
  not an isolated optimizer on/off benchmark, but the strict timing gate is not clean.
- After a SketchUp restart, three clean hosted perf captures were run with quality sampling off,
  timing on, and `clear_existing: true`:
  - `feature_aware_adaptive_baseline_results_mta41_clean_perf1_20260525T164842Z.json`
  - `feature_aware_adaptive_baseline_results_mta41_clean_perf2_20260525T165008Z.json`
  - `feature_aware_adaptive_baseline_results_mta41_clean_perf3_20260525T165135Z.json`
- Clean perf results:
  - `18` rows per run and `0` compact-result refusals;
  - stable diagonal signature across all three clean runs:
    `be58d0832af303dd3f54b671f151884e15f47eff3b05a25cc04f44dd19a90c24`;
  - maximum row timing spread across the three clean runs was `20.97%`, under the predeclared
    `25%` timing band;
  - large timing rows were materially steadier than the short rows: worst large-row spread was
    `7.97%`.
- Cost of the improved emitted geometry versus the closest pre-diagonal MTA-42 perf baseline:
  - MTA-42 three-run average total: `79.40s`;
  - MTA-41 clean three-run average total: `86.32s`;
  - total timing price: `+6.93s` / `+8.73%` across the full 18-row replay;
  - changed emitted diagonals bought by that price: `21,616`;
  - aggregate residual improvement bought by that price: `147.81`;
  - average timing price per changed diagonal: about `0.32ms`;
  - face-count and vertex-count deltas versus MTA-42: `0` for every row.
- Historical comparison against MTA-39 is less isolated because MTA-40/MTA-42 changed the pipeline
  before MTA-41, but the same replay totals are:
  - MTA-39 three-run average total: `82.63s`;
  - MTA-41 clean three-run average total: `86.32s`;
  - total timing delta: `+3.69s` / `+4.47%`.
- After Ruby-side optimizer hot-loop changes, three additional hosted captures were run from the
  live session:
  - `feature_aware_adaptive_baseline_results_mta41_rubyopt_perf1_20260525T180710Z.json`
  - `feature_aware_adaptive_baseline_results_mta41_rubyopt_perf2_20260525T180839Z.json`
  - `feature_aware_adaptive_baseline_results_mta41_rubyopt_perf3_20260525T181011Z.json`
- The optimized run preserved the same row count, face counts, vertex counts, and deterministic
  diagonal evidence. It reduced the targeted `commandOutputPlanning` bucket by `1.09s` versus the
  previous MTA-41 clean run, lowering the MTA-42-to-MTA-41 command-planning price from `+6.17s` to
  `+5.08s`.
- The optimized live-session wall-clock total was noisier: `89.53s` average, `+3.20s` over the
  previous clean MTA-41 run. Named timing buckets netted roughly flat, so the extra wall time is
  unbucketed/session overhead rather than a measured regression in diagonal command planning. Treat
  this run as evidence that the targeted bucket improved, not as a clean adoption-baseline
  replacement without a fresh SketchUp restart repeat.
- After a fresh SketchUp restart, three replacement optimized captures were run:
  - `feature_aware_adaptive_baseline_results_mta41_rubyopt_fresh_perf1_20260525T210012Z.json`
  - `feature_aware_adaptive_baseline_results_mta41_rubyopt_fresh_perf2_20260525T210141Z.json`
  - `feature_aware_adaptive_baseline_results_mta41_rubyopt_fresh_perf3_20260525T210308Z.json`
- Fresh optimized perf results:
  - total replay average: `86.92s`, only `+0.59s` / `+0.69%` versus the previous MTA-41 clean
    run;
  - total replay average versus MTA-42: `+7.52s` / `+9.48%`;
  - `commandOutputPlanning` still improved by `1.08s` versus the previous MTA-41 clean run;
  - MTA-42-to-MTA-41 command-planning price is now `+5.09s`, down from `+6.17s` before the Ruby hot
    loop changes;
  - all geometry counts remained unchanged.

## Remaining Gaps

- No required MTA-41 implementation or validation gaps remain for adoption.
- Hosted replay proves actual changed emitted diagonals, positive residual effect, deterministic
  repeated output, seam-adjacent aggregate non-regression, and no public leak.
- Clean post-restart perf repeat is within the predeclared `25%` timing band. The older
  cross-version comparison remains historical context, not a pure optimizer timing measurement.
- Optional future work: add an isolated optimizer off/on benchmark inside the same runtime if
  stricter cost isolation is needed, or move the scoring hot path native if future terrain planning
  accumulates similar `commandOutputPlanning` cost.
