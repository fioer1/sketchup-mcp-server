# Summary: MTA-44A Establish Effective Feature Composed Height Oracle

**Task ID**: `MTA-44A`  
**Title**: `Establish Effective Feature Composed Height Oracle`  
**Status**: `implementation-complete`  
**Date**: `2026-06-01`

## Shipped Behavior

MTA-44A establishes a SketchUp-free composed height oracle for managed terrain state plus current
effective feature geometry. The oracle preserves base-grid bilinear/no-data behavior, applies
deterministic feature precedence, keeps circular primitives as circle semantics for height
queries, shares planar height math with planar edit behavior, and routes production composed-height
reads through the oracle.

Implemented slices:

- Added `TerrainPrimitiveMembership` for deterministic point, circle, and rectangle membership.
- Added `TerrainOracleSemanticRegionBuilder` and `oracleSemanticRegions` on
  `TerrainFeatureGeometry` so oracle-relevant feature primitives retain explicit circle data.
- Added `PlanarHeightModel` and reused it from both planar edits and oracle planar evaluation.
- Added `ComposedHeightOracle` over `TerrainStateElevationSampler`, effective feature geometry,
  primitive membership, and planar model caching.
- Routed composed-height reads in output planning, adaptive conformity, diagonal optimization,
  mesh vertex emission, seam Z values, and feature-aware replay quality sampling.
- Added an oracle semantic token to adaptive patch policy fingerprinting so output/readback
  invalidates when oracle semantics can affect emitted Z.
- Fixed command-path regeneration after live verification exposed that production edit output was
  planning from raw edit state instead of the feature-merged output state.
- Fixed command-path oracle construction so `TerrainSurfaceCommands` builds one output oracle per
  output state and passes it to `TerrainOutputPlan` and `TerrainMeshGenerator`; this prevents
  repeated oracle/feature-geometry rebuilds during adaptive residual probing.
- Optimized the composed-oracle hot path after large replay timing exposed an oracle cost
  regression:
  - cached integer-grid height answers per oracle, including `nil` and out-of-bounds answers
  - used direct integer-grid base reads instead of point/hash sampling for grid-aligned queries
  - compiled semantic regions, precedence ordering, planar-region partitions, and primitive numeric
    shape data once per oracle
  - precomputed circle tolerance radii and avoided per-query matched-region arrays
  - used packed integer cache keys for in-bounds grid samples to reduce hot-loop allocation
  - computed conformity-collapse cell corner heights once per cell instead of once per boundary
    vertex
  - avoided constructing oracles for CDT/low-level fallback paths outside MTA-44A scope

## Scope Boundary

This task does not implement circular mesh cuts, inserted off-grid vertices, feature cut graphs,
local-detail state, schema v4, or cross-patch feature-cut hardening. Circle work in this task is
height semantics and oracle routing, not circular topology. MTA-44B/MTA-44C own contained cut graph
output and seam-safe feature cuts.

Public MCP tool names, request schemas, dispatcher routes, and response shapes were intentionally
left unchanged. No user-facing docs were required because the public contract did not change.

## Automated Validation

Local validation run before hosted/live verification:

- Focused oracle/routing suite: `144 runs, 2353 assertions, 0 failures`.
- Full Ruby suite: `1635 runs, 21906 assertions, 0 failures, 42 skips`.
- Full RuboCop: `393 files inspected, no offenses detected`.
- Package verification: `bundle exec rake package:verify`, produced
  `dist/su_mcp-1.15.0.rbz`.

Additional focused validation after the live-discovered command-path fixes:

- Command/routing/fingerprint suite:
  `46 runs, 408 assertions, 0 failures, 0 errors, 0 skips`.
- Oracle/direct-read/command harness:
  `67 runs, 470 assertions, 0 failures, 0 errors, 0 skips`.
- RuboCop on latest command routing files:
  `2 files inspected, no offenses detected`.

Final validation after the command-path and oracle hot-path fixes:

- Focused oracle/routing suite:
  `65 runs, 466 assertions, 0 failures, 0 errors, 0 skips`.
- Affected terrain/oracle/output/command/probe suite:
  `181 runs, 2626 assertions, 0 failures, 0 errors, 0 skips`.
- Full Ruby suite:
  `1639 runs, 21926 assertions, 0 failures, 0 errors, 42 skips`.
- RuboCop on final changed runtime/test files:
  `4 files inspected, no offenses detected`.
- Package verification: `bundle exec rake package:verify`, produced
  `dist/su_mcp-1.15.0.rbz`.

The deployed SketchUp plugin files were hash-checked or reloaded against the local workspace for the
command surface, output plan, adaptive conformity, diagonal optimizer, composed oracle, and oracle
semantic shape helper.

## Code Review

Task-review and `grok-4.3` review were run on the completed local change set before hosted/live
SketchUp verification and reported no correctness findings. Live verification then exposed a real
production command-path miss: state/oracle answers were correct, but adaptive output planning could
still use the raw edit state and could rebuild the oracle during planning. That follow-up was fixed
locally, deployed, and verified with focused automated tests plus live SketchUp checks.

A later performance review with `grok-4.3` was run after the oracle hot-path work. Accepted bounded
findings were a real hot-path allocation in `ComposedHeightOracle#height_at_grid` and repeated
conformity-collapse corner reads. The literal cache-key suggestion still allocated array keys, so
the implemented fix uses packed integer keys for in-bounds grid samples and explicit tuple keys only
for non-integer/out-of-bounds cases. Broader suggestions for planning/diagonal local caches were
intentionally not applied because the per-oracle grid cache already shares sampled heights across
planning, conformity, seams, and diagonal optimization; adding separate per-loop caches would
duplicate memory and plumbing without proving a new semantic gap.

Final task-review and `grok-4.3` review after the fast-path helper extraction found no correctness
blockers. Structural review flagged `TerrainPrimitiveMembership.classify` as born-dead; it was
intentionally retained as the tested domain classifier API while the oracle uses optimized numeric
shape paths. An earlier unused `contains?` helper was removed. Grok suggested avoiding oracle-token
class access and out-of-bounds cache-key arrays; both were dispositioned as non-blocking because the
current command path does not build an oracle for the token, and non-integer/out-of-bounds cache keys
are not part of the hot replay path.

## Live SketchUp Verification

Live checks were run after deployment/restart with the latest fixes. Geometry was left in the scene
for visual inspection, primarily at `x >= 50m`.

Focused live rows:

- `mta44a-f2-circle-target`, x about `75m`: circular target-height disk at `2.0m`; bbox corner
  inside the square but outside the circle stayed flat.
- `mta44a-f3-circular-planar`, x about `100m`: circular sloped planar cap; bbox corner stayed flat.
- `mta44a-f4-preserve-precedence`, x about `125m`: raised target area with protected preserve
  island left at base height.
- `mta44a-f5-fixed-control-precedence`, x about `150m`: public command refused fixed-control
  conflict and left terrain unchanged.
- `mta44a-f6b-planar-suppresses-circle-fixed`, x about `205m`: newer planar `4.0m` region
  suppressed older circular `2.0m` target only inside planar domain.
- `mta44a-f7-current-effective-targets`, x about `230m`: overlapping target circles used current
  effective precedence; newer center cap won while adjacent/older regions remained applicable.
- `mta44a-f8-seam-readback`, x about `265m`: target rectangle crossing an adaptive seam sampled
  continuously at `2.0m`; seam check passed.

Replay terrain at x about `320m`:

- Main replay rows through `fairing-envelope-intersect` completed with seam checks passed.
- Target, corridor, planar, survey, and fairing behavior remained visually coherent after oracle
  routing.

Large timing terrain at x about `420m`:

- Large local target row completed in about `12s` after oracle-threading fix; before the fix the
  comparable row took about `63s`.
- Large corridor row completed in about `79s`; before the fix it exceeded the `300s` tool timeout.
- Large planar row completed in about `71s` with exact planar control residuals and seam check
  passed.
- Large survey row completed in about `107s`; the survey kernel changed only four samples and
  satisfied the survey point exactly, but adaptive component planning expanded one affected patch to
  `169` replacement patches.
- Large fairing row completed in about `92s`, improved residual from `0.02216` to `0.01566`, and
  replaced `196` patches because its dirty window covered nearly the full terrain.

The survey/fairing timing observation is a patch lifecycle/component replacement scope issue, not a
MTA-44A oracle correctness issue. It should be tracked separately under patch lifecycle or
performance work.

After the final oracle fast-path work and a clean deploy/restart, the retained hosted replay
evidence is the isolated three-run large target timing set:

- `test/terrain/replay/feature_aware_adaptive_baseline_results_mta44a_clean_fastpath_large_target_run_1.json`
- `test/terrain/replay/feature_aware_adaptive_baseline_results_mta44a_clean_fastpath_large_target_run_2.json`
- `test/terrain/replay/feature_aware_adaptive_baseline_results_mta44a_clean_fastpath_large_target_run_3.json`

All three retained rows passed seam validation and produced the same topology as the MTA-43
comparison baseline:

| Run | Row | Total | Command output planning | Faces | Vertices | Seam |
|---|---|---:|---:|---:|---:|---|
| 1 | `large-varied-local-target-timing` | 4.308s | 1.428s | 18770 | 9575 | passed |
| 2 | `large-varied-local-target-timing` | 4.403s | 1.514s | 18770 | 9575 | passed |
| 3 | `large-varied-local-target-timing` | 4.797s | 1.560s | 18770 | 9575 | passed |

Average retained MTA-44A clean fastpath timing was `4.503s` total and `1.500s` command output
planning. The MTA-43 three-run comparison average for the same row was `2.881s` total and `0.747s`
command output planning, with identical `18770` faces and `9575` vertices.

Save/reopen was intentionally not run; serializer round-trip coverage proves deterministic oracle
inputs and answers after persistence, and the user explicitly rejected save/reopen as useful live
verification for this task.

## Contract And Architecture Review

Runtime ownership stayed inside the SketchUp extension. The oracle is a domain/read-model service
used by command/output/probe layers; it does not expose raw SketchUp objects, alter public MCP tool
contracts, or move command behavior outside the extension runtime.

Remaining direct base-grid reads are classified as base mutation/storage/no-data/coarse-pruning or
test/prototype fallback paths. Public command responses do not expose oracle traces, raw feature
geometry, cut graph vocabulary, patch ids, seam graph internals, or inserted-vertex concepts.

No finite public option set changed, so there is no new before-call/after-call discoverability
surface to document.

## Remaining Gaps

- Large survey/fairing timing exposes patch lifecycle over-promotion or broad replacement scope.
  This is outside MTA-44A and should be tracked separately.
- Circular topology is intentionally not implemented or proven in MTA-44A; only circular height
  semantics and oracle routing are complete.
- Step 07 size calibration is still pending and should use this summary as closeout evidence.
