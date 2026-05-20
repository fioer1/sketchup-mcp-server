# Summary: MTA-45 Reduce Unnecessary Planar Region Output Tessellation

**Task ID**: `MTA-45`
**Status**: `completed`
**Captured**: `2026-05-20`

## Shipped Local Behavior

- Older pressure and reference geometry is now clipped before adaptive policy planning when a newer
  absolute no-falloff rectangular planar region covers only part of that older feature pressure.
- Fully occluded older non-protected pressure/reference entries are removed, while valid outside
  pressure is preserved as outside fragments.
- Older rectangular pressure and public circle-pressure inputs are split into policy-effective
  outside rectangle fragments under rectangular planar occlusion. Circle pressure uses effective
  bounds because the current adaptive policy consumes those pressure inputs through effective
  bounds.
- Older reference segments crossing rectangular planar regions are split parametrically so forced
  detail remains only outside the planar footprint.
- Protected pressure, positive planar falloff/blend detail, and newer corridor/target/survey/fairing
  features on top of a planar edit remain authoritative.
- Partial circular planar occluders stay conservative: intersecting primitives are retained and an
  internal limitation is recorded instead of fabricating unsupported circular subtraction geometry.
- Absolute planar regions are now carried as internal feature geometry so adaptive output can
  coalesce eligible planar-interior cells instead of only suppressing older pressure. This is the
  hosted-fix layer that makes the visible planar core compact rather than merely less pressured.
- Planar interior coalescing remains patch-local and preserves explicit falloff, conformance strips,
  protected detail, and newer feature overlays.
- Replay-only planar interior evidence now records planned-cell centroid metrics for active
  no-falloff rectangular planar interiors, including cell, face, and vertex counts.
- Replay result rows and classifier comparisons carry `planarInteriorMetrics`; public MCP request
  schemas, dispatcher routes, tool names, and public response shapes are unchanged.

## Validation Evidence

- Initial skeleton red baseline:
  - `51 runs, 797 assertions, 10 failures, 0 errors, 0 skips`
- Focused mapped implementation batch:
  - `110 runs, 7882 assertions, 0 failures`
- Full Ruby tests:
  - `bundle exec rake ruby:test`
  - final hosted-fix rerun: `1483 runs, 17939 assertions, 0 failures, 0 errors, 41 skips`
- Full Ruby lint:
  - `bundle exec rake ruby:lint`
  - `362 files inspected, no offenses`
- Package verification:
  - `bundle exec rake package:verify`
  - produced `dist/su_mcp-1.11.0.rbz`
- Focused contract stability:
  - `test/terrain/contracts/terrain_contract_stability_test.rb`
  - `16 runs, 6647 assertions, 0 failures`
- Focused changed-file RuboCop:
  - final hosted-fix focused pass: `9 files inspected, no offenses`
- Local security scan:
  - `tldr secure . --format json --quiet`
  - `0 findings`

## Code Review

- `$task-review` was adapted locally because subagent spawning was not authorized in this turn.
- `tldr bugbot check --format json --no-fail --quiet --base-ref HEAD .` reported `0` L1 findings.
- Remaining high Bugbot/L2 findings were dispositioned as false positives:
  - class-method vs instance-method `annotate` signature comparison in the result classifier;
  - test-helper line-mapping/signature noise.
- A production smell around `bounds_for_entry` was refactored into smaller entry/segment/shape
  helpers before final validation.
- A follow-up no-behavior-change cleanup extracted planar occlusion clipping out of
  `TerrainFeatureGeometryBuilder` into `PlanarOcclusionClipper` and `PlanarOcclusionGeometry`,
  removing the builder's class-length suppression while keeping the same clipping IDs, ordering, and
  output shapes.
- PAL `codereview` with `model: "grok-4.3"` completed. Its medium public-leak suggestion was
  rejected after local cross-check because `planarInteriorMetrics` is internal baseline/replay
  evidence and gating it by `cdt_output_enabled?` would remove needed hosted-path evidence. Its low
  circular-contained limitation suggestion was rejected because fully contained circular pressure is
  exactly removable; limitations remain reserved for partial unsupported circular occlusion.

## Contract And Docs

- Public terrain command contracts did not change.
- Contract stability coverage was rerun to prove internal planar metrics do not leak through public
  responses.
- User-facing docs were not updated because there is no public setup, request, response, or tool
  behavior change.
- The task plan and size drift log were updated to capture the tightened public circle-pressure
  clipping requirement.
- The newer circular fairing-over-planar density behavior found after closeout is intentionally
  split to `MTA-46`; it is not part of the closed MTA-45 acceptance boundary.

## Hosted Verification Status

- Live SketchUp replay was run after deployment at the required right-side scene locations:
  baseline terrain `x=320.0m..344.0m`, large timing terrain `x=420.0m..453.45m`, and wide timing
  terrain `x=465.0m..499.38m`.
- The first hosted pass showed that pressure clipping alone underimplemented MTA-45: the large
  planar interior still looked full-grid. The fix added internal planar-region propagation and
  patch-local planar-cell coalescing.
- Final hosted result artifacts:
  - `test/terrain/replay/feature_aware_adaptive_baseline_results_mta45_coalesced.json`;
  - `test/terrain/replay/feature_aware_adaptive_baseline_results_mta45_coalesced_annotated.json`;
  - `test/terrain/replay/feature_aware_adaptive_baseline_results_mta45_perf_summary.json`.
- Raw hosted performance run JSONs were pruned after summary generation; the retained performance
  summary embeds per-run timing values and both the MTA-40 and original-baseline comparisons.
- Final annotated replay versus MTA-40 final:
  - `18` rows captured: `3 created`, `15 edited`, `0 refused`;
  - verdicts: `15 policy_applied`, `3 neutral`, `0 regressed`;
  - quality evidence: `15 captured`, `3 not_applicable`;
  - `planar-pad-intersect`: face delta `-28`, planned planar interior `32` faces, `100%`
    planar-region quality;
  - `large-varied-planar-pad-timing`: face delta `-666`, planned planar interior `212` faces,
    `100%` planar-region quality;
  - live geometry after run: `feature-aware-baseline-terrain` `1745` faces,
    `feature-aware-baseline-terrain-large-timing` `56826` faces, and
    `feature-aware-baseline-terrain-wide-timing` `24366` faces.
- Three-run hosted performance comparison against the MTA-40 final performance summary:
  - command total runs: `77.7084s`, `78.5265s`, `79.1140s`;
  - average command total: `78.4496s` with `0.5764s` population standard deviation, versus the
    MTA-40 three-run mean of `92.1928s` (`-14.9%`);
  - average harness quality total: `15.5895s`, versus the MTA-40 three-run mean of `17.5708s`
    (`-11.3%`);
  - face counts and vertex counts were stable across all three runs for all `18` rows;
  - `0/18` rows exceeded the `25%` timing-regression threshold versus MTA-40;
  - planar timing rows stayed below the MTA-40 mean: `planar-pad-intersect` averaged `0.176874s`
    (`-26.1%`) and `large-varied-planar-pad-timing` averaged `11.460067s` (`-15.8%`).
- Direct three-run hosted performance comparison against the original reusable baseline repeat
  captures:
  - baseline command total runs: `85.1113s`, `85.2140s`, `87.3607s`;
  - MTA-45 command total runs: `77.7084s`, `78.5265s`, `79.1140s`;
  - MTA-45 averaged `78.4496s` versus the original baseline mean of `85.8953s` (`-8.7%`);
  - `0/18` rows exceeded the `25%` timing threshold versus the original baseline;
  - `planar-pad-intersect` reduced faces by `126` versus the original baseline and averaged
    `-17.1%` timing;
  - `large-varied-planar-pad-timing` reduced faces by `1039` versus the original baseline and
    averaged `-12.0%` timing.
- Additional live visual probes were left in the scene at `x >= 50m` for inspection:
  - `mta45-large-corridor-planar-falloff-live` at `x=620.0m..653.45m`: exact
    `secondaryTimingTerrain` replay fixture, created from the large complicated terrain, then edited
    with `large-varied-local-target-timing`, `large-varied-corridor-diagonal-timing`, and finally the
    `large-varied-planar-pad-timing` rectangle changed only to `1.5m` smooth planar falloff. The
    final edit was accepted with `67339` faces and `34189` vertices; centroid counts were `592` in
    the planar rectangle, `62` in the rectangle inset beyond the falloff shoulder, and `5781` in the
    planar-plus-falloff envelope.
  - `mta45-circle-pressure-planar-no-falloff` at `x=560.0m..572.0m`: older circular target-height
    pressure followed by later no-falloff rectangular planar; planar core measured `2` faces and
    planar footprint measured `144` centroid faces.
  - `mta45-circle-pressure-planar-falloff` at `x=580.0m..592.0m` also remains visible as a smaller
    custom falloff comparison, but it is not the authoritative complicated-terrain/corridor fixture.
