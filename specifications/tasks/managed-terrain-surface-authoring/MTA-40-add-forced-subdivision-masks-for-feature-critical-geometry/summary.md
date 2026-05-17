# Summary: MTA-40 Add Forced Subdivision Masks For Feature-Critical Geometry

**Task ID**: `MTA-40`
**Status**: `completed`
**Captured**: `2026-05-17`

## Shipped Local Behavior

- Added `FeatureAwareForcedSubdivisionMask`, an internal output-only forced-mask policy helper for
  supported feature-critical subdivision pressure.
- Supported forced-mask inputs now include output anchors, rectangle/circle protected boundaries,
  and corridor side-transition, endpoint-cap, falloff, and overlap reference segments.
- Unsupported forced-mask inputs are skipped with compact internal counters, including broad
  corridor pressure, unsupported pressure primitives, and unsupported corridor reference roles.
- Threaded forced split pressure through `FeatureAwareAdaptivePolicy#split_pressure_for` and
  `TerrainOutputPlan.adaptive_split_probe` separately from residual tolerance and MTA-39 density
  pressure.
- Preserved valid-heightmap disposable mesh output behavior for unsupported forced-mask cases by
  treating them as skipped output pressure rather than new command refusals.
- Extended internal adaptive policy summaries with `forcedSubdivisionSummary` containing compact
  supported input counts, skipped input counts, and forced split hit count.
- Extended replay quality summaries with role-level sample grouping so corridor interiors can be
  distinguished from side, cap, falloff, and overlap detail.
- Fixed the hosted planar-region density bug found during live verification: no-falloff
  `planar_region` intent no longer emits broad adaptive pressure, positive planar blend emits only
  edge falloff reference detail, and feature-aware adaptive output collapses coplanar conformance
  fan edges where intermediate edge vertices are exactly linear.
- Kept planar quality sampling after removing planar output pressure by sampling planar intent
  regions directly in the hosted quality probe.
- Hardened result classification so supported forced-mask pressure with zero forced hits fails, and
  broad corridor centerline density alone does not count as topology improvement.
- Kept public MCP tool names, request schemas, dispatcher routes, and response shapes unchanged.

## Validation Evidence

- Initial TDD skeleton red baseline:
  - `74 runs, 7672 assertions, 4 failures, 3 errors`
- Focused MTA-40 skeleton batch after implementation:
  - `74 runs, 7699 assertions, 0 failures, 0 errors`
- Full terrain suite:
  - `800 runs, 15237 assertions, 0 failures, 0 errors, 3 skips`
- Full Ruby tests:
  - `bundle exec rake ruby:test`
  - final post-live-overlay-backout rerun: `1464 runs, 17844 assertions, 0 failures, 0 errors, 41 skips`
- Full Ruby lint:
  - `bundle exec rake ruby:lint`
  - `361 files inspected, no offenses detected`
- Package verification:
  - `bundle exec rake package:verify`
  - produced `dist/su_mcp-1.9.0.rbz`
- Planar bug focused checks:
  - `bundle exec ruby -Itest test/terrain/features/terrain_feature_geometry_builder_test.rb`
  - `16 runs, 74 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec ruby -Itest test/terrain/output/feature_aware_adaptive_policy_test.rb`
  - `8 runs, 35 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec ruby -Itest test/terrain/output/terrain_output_plan_test.rb`
  - final post-live-overlay-backout rerun: `24 runs, 261 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec ruby -Itest test/terrain/output/terrain_mesh_generator_test.rb`
  - final post-live-overlay-backout rerun: `74 runs, 1698 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec ruby -Itest test/terrain/probes/feature_aware_adaptive_baseline_quality_sampler_test.rb`
  - `3 runs, 22 assertions, 0 failures, 0 errors, 0 skips`
- Focused command checks:
  - `42 runs, 367 assertions, 0 failures, 0 errors`
- Focused contract checks:
  - `16 runs, 6647 assertions, 0 failures, 0 errors`
- Focused replay/probe checks:
  - `18 runs, 705 assertions, 0 failures, 0 errors`
- Post-review classifier hardening:
  - `bundle exec ruby -Itest test/terrain/probes/feature_aware_adaptive_baseline_result_classifier_test.rb`
  - `7 runs, 19 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec rubocop --cache false src/su_mcp/terrain/probes/feature_aware_adaptive_baseline_result_classifier.rb`
  - `1 file inspected, no offenses detected`

## Code Review

- Deterministic local review ran Bugbot, smells, hotspots, secure, focused tests, lint, package
  verification, and manual review of the changed production and test paths.
- `tldr secure` reported no findings.
- Bugbot's remaining production high finding is a false positive: it compares the unchanged public
  class method `self.annotate(baseline_document:, current_document:)` with the private instance
  method `annotate`.
- Bugbot's remaining info findings are test-helper signature expansions.
- PAL codereview with `model: "grok-4.3"` completed with no blocker above low severity.
- One PAL low note was addressed: the classifier's corridor-family check now sorts keys before
  comparing to `linear_corridor`.
- Other PAL low notes were dispositioned:
  - Contract no-leak coverage already includes `supportedInputCounts` and `skippedInputCounts`.
  - Rectangle boundary corner coverage is already handled by existing segment endpoint checks,
    including degenerate edges.
  - Shared primitive-predicate extraction was not made because it would add cross-class coupling for
    a small forced-mask-specific distinction.

## Contract And Docs

- Public terrain command contracts did not change.
- Contract no-leak coverage was expanded for forced-mask and forced-subdivision vocabulary,
  including compact summary keys and owner-local reference segment terms.
- User-facing docs were reviewed by scope and were not updated because there is no public setup,
  request, response, or tool behavior change.

## Hosted Verification Status

- Live SketchUp verification was run after deployment through the reusable MTA-38 replay harness
  with `include_quality: true`.
- The hosted replay terrain origins satisfied the required `x >= 50m` placement constraint:
  - baseline terrain world bounds: `x=320.0m..344.0m`;
  - large timing terrain world bounds: `x=420.0m..453.45m`;
  - wide timing terrain world bounds: `x=465.0m..499.38m`.
- Final captured artifacts after the planar-density fix:
  - `test/terrain/replay/feature_aware_adaptive_baseline_results_mta40_full_final.json`;
  - `test/terrain/replay/feature_aware_adaptive_baseline_results_mta40_full_final_annotated.json`.
  - `test/terrain/replay/feature_aware_adaptive_baseline_results_mta40_perf_summary.json`.
- Hosted result pack:
  - `18` rows captured;
  - outcomes: `3 created`, `15 edited`, `0 refused`;
  - annotated verdicts against the MTA-39 quality baseline: `15 policy_applied`, `3 neutral`,
    `0 regressed`;
  - total command row time after policy caching: `91.9363s`;
  - quality evidence: `15 captured`, `3 not_applicable`.
- Planar bug rerun evidence:
  - no-falloff planar geometry builder live check at `origin_x_m=50.0` returned no pressure
    regions, no reference segments, `target_cell_size=nil`, and `density_hit_count=0`;
  - one-way live occlusion check at `origin_x_m=50.0` suppressed an older target under planar while
    preserving a newer target on top of planar;
  - isolated `large-varied-planar-pad-timing` rerun after the coplanar collapse had
    `densityHitCount=0`, `forcedHitCount=0`, and `100%` planar-region quality;
  - fully inside the isolated large planar rectangle, emitted triangles dropped from `860` to
    `376` by removing coplanar conformance fan triangles;
  - final full replay planar rows retained `100%` planar-region quality:
    `planar-pad-intersect` face count `1577`, density hit count `52`, forced hit count `42`,
    and face delta `-106` versus MTA-39;
  - final full replay `large-varied-planar-pad-timing` retained `100%` planar-region quality,
    face count `67189`, density hit count `0`, forced hit count `295`, and face delta `-2515`
    versus MTA-39.
- Forced subdivision evidence:
  - `10` rows recorded positive forced split hits;
  - corridor rows recorded `corridor_detail: 4` supported inputs with broad corridor pressure
    skipped compactly;
  - survey/fairing rows that intersect the survey control recorded both `anchor: 1` and
    `corridor_detail: 4` supported inputs;
  - forced hit counts ranged from `42` to `299` on the affected rows.
- MTA-39 quality baseline comparison:
  - face-count delta was `0` on `2/18` rows;
  - face-count delta was negative on `15/18` rows after coplanar fan collapse;
  - face-count delta was `+28` on `wide-varied-fairing-large-timing`;
  - no row crossed the classifier timing or face-count regression threshold after policy caching.
- Three-run performance recapture:
  - command total runs: `91.9363s`, `91.6726s`, `92.9693s`;
  - average command total: `92.1928s` with `0.5596s` population standard deviation;
  - average harness quality total: `17.5708s`;
  - face counts and vertex counts were stable across all three runs for all `18` rows;
  - averaged row timing left `0/18` rows over the `25%` timing threshold.
- Dirty-window and patch-scope comparison:
  - `0/18` rows changed dirty-window scope versus the MTA-39 quality baseline;
  - `0/18` rows changed affected patch scope versus the MTA-39 quality baseline.
- Registry/readback and lifecycle checks:
  - exactly one live owner existed for each replay terrain source id;
  - recursive live scene face counts after the final full rerun were
    `1789`, `57773`, and `24366`.

## Remaining Gaps

- Exact hard-feature topology, segment-aligned edges, seam upgrades, sparse local detail tiles, and
  CDT islands remain outside MTA-40.
- Literal single-polygon/two-triangle planar patch emission across multiple adaptive patches remains
  outside MTA-40; the implemented fix removes planar density pressure and collapses coplanar
  conformance fan triangles inside the existing adaptive patch/cell output path.
- Save/reopen was not run as a separate SketchUp process restart check; live registry/readback
  succeeded in the active hosted model and is the recorded lifecycle evidence for this task.
