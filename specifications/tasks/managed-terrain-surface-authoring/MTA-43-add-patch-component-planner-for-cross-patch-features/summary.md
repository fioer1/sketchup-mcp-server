# Summary: MTA-43 Add Patch Component Planner For Cross-Patch Features

**Task ID**: `MTA-43`
**Status**: `implemented`
**Completed**: `2026-05-23`

## Shipped Behavior

- Added `SU_MCP::Terrain::PatchLifecycle::PatchComponentPlanner` for bounded dirty-window patch
  component planning.
- Preserved the existing lifecycle keys consumed by adaptive output:
  `affectedPatchIds`, `replacementPatchIds`, `affectedPatches`, `replacementPatches`, and
  `conformanceRing`.
- Added internal component metadata for retained-boundary patches, safety-margin patches,
  component summaries, budget summaries, graph reasons, and over-budget budget verdicts.
- Threaded one sealed `adaptive_lifecycle_resolution` through `TerrainOutputPlan`,
  command baseline evidence, feature patch batching, adaptive seam artifacts, mesh mutation, and
  registry writes.
- Preserved local dirty-window semantics by keeping the command dirty window tied to the actual
  changed region while using feature/protected windows as component sources.
- Kept over-budget component scope on the sealed dirty replacement path when ownership, registry,
  and seam checks are safe; full adaptive fallback remains reserved for independent unsafe
  existing-output cases.
- Extended replay/result/classifier internals to record component summaries, component budgets,
  expected promotion, expected over-budget status, and actual fallback status without exposing
  those fields in public MCP responses.

## Validation Evidence

- `bundle exec ruby -Itest test/terrain/commands/terrain_surface_commands_test.rb`
  - `45 runs, 393 assertions, 0 failures`
- `bundle exec ruby -Itest test/terrain/output/terrain_output_plan_test.rb`
  - `40 runs, 310 assertions, 0 failures`
- `bundle exec ruby -Itest test/terrain/output/terrain_mesh_generator_test.rb`
  - `79 runs, 1968 assertions, 0 failures`
- `bundle exec rake ruby:lint`
  - `375 files inspected, no offenses detected`
- `bundle exec rake ruby:test`
  - `1555 runs, 20820 assertions, 0 failures, 0 errors, 41 skips`
- `bundle exec rake package:verify`
  - produced `dist/su_mcp-1.13.0.rbz`
- `git diff --check`
  - passed

## Code Review

- Ran local task-review-style structural checks with `tldr` security/bugbot/smell/complexity
  coverage over the changed terrain surface.
- Ran PAL `codereview` with `model: "grok-4.3"`, continuation id
  `c12911b4-d2f9-46a6-8e46-c9611e67b372`.
- Accepted and fixed review findings for resolver-recompute guards, classifier evidence, and
  expanded no-leak vocabulary.
- Corrected the later-discovered planning mismatch where over-budget component scope had been
  implemented as forced full adaptive fallback. The corrected path records `over_budget` as budget
  evidence and still uses bounded dirty replacement when the existing output is safe.
- Challenged broad or duplicate concerns where the existing integration tests and command boundary
  already covered the behavior.

## Hosted SketchUp Verification

Hosted checks were run through the public terrain command path after review follow-up. Later Step 6
perf validation was rerun after the user deployed a fresh packaged extension. All targeted proof
terrains used placement origins with `x >= 50m`.

| Row | Placement X | Result |
|---|---:|---|
| Local no-promotion | `50m` | Edited successfully; `promotedCount = 0`; graph reasons `dirty_window`; replacement stayed bounded to 4 patches; public result leaked no component internals; seam validation passed. |
| Cross feature/protected promotion | `80m` | Seed and follow-up edits succeeded; final dirty window stayed one affected patch; `promotedCount = 3`; graph reasons included `feature_boundary_crossing`, `protected_boundary_crossing`, and `conformance`; replacement stayed bounded to 9 patches; public result leaked no component internals; seam validation passed. |
| Promoted patch replacement proof | `50m` | Direct hosted proof compared legacy dirty replacement (`9` patches) against MTA-43 component replacement (`12` patches). The `3` extra promoted patch old faces were removed after regeneration, while an unrelated outside patch retained its old faces. |
| Over-budget bounded replacement | `110m` | Seed and follow-up edits succeeded; component budget status `over_budget`; bounded dirty replacement completed; registry/readback remained valid. |
| Repeated edit/readback | `140m` | Two edits succeeded; registry status valid with 9 patches; repository readback loaded revision 3. |

Owner-level registry/readback checks after hosted runs:

- Local no-promotion: registry valid, 9 patches, readback loaded revision 2.
- Cross feature/protected promotion: registry valid, 9 patches, readback loaded revision 3.
- Over-budget bounded replacement: registry valid after dirty replacement, readback loaded revision 3.
- Repeated edit/readback: registry valid, 9 patches, readback loaded revision 3.

## Contract And Docs

- Public MCP request schemas, tool catalog entries, dispatcher routing, and normal success payload
  shape were intentionally unchanged.
- Contract tests assert public success/refusal payloads do not leak component summaries, component
  budgets, role counts, graph reasons, patch IDs, seam records, registry records, or fallback
  internals.
- No README or user-facing usage docs were changed because there is no public tool/schema/workflow
  change.

## Performance Evidence

The final three-pass hosted timing capture was run after the user deployed a fresh packaged
extension:

- Runs: `3`.
- Rows per run: `18`.
- Refused rows: `0 / 0 / 0`.
- Component rows: `15`.
- Over-budget rows: `6`.
- Mean total: `78.291227s`, stdev `1.049852s`.
- Mean component planning: `0.028851s`.
- Mean adaptive planning: `7.366014s`.
- Mean mutation: `21.202518s`.
- Compared with MTA-46 run 2: `-0.502635s` / `-0.638%`.
- Compared with MTA-42 run 2: `+0.232449s` / `+0.298%`.

Artifacts:

- `test/terrain/replay/feature_aware_adaptive_baseline_results_mta43_component_timing_fresh_perf_run_1.json`
- `test/terrain/replay/feature_aware_adaptive_baseline_results_mta43_component_timing_fresh_perf_run_2.json`
- `test/terrain/replay/feature_aware_adaptive_baseline_results_mta43_component_timing_fresh_perf_run_3.json`
- `test/terrain/replay/feature_aware_adaptive_baseline_results_mta43_component_timing_fresh_perf_summary.json`

This removed the earlier accidental full-fallback adaptive planning cost. The fresh packaged run is
effectively neutral against the MTA-42/MTA-46 timing baselines while still recording component
planning, promotion, and over-budget evidence.

## Promotion Proof

The original replay corpus did not demonstrate a row where MTA-43 replaced more patches than the
pre-MTA-43 dirty resolver. A targeted hosted proof was added:

- Legacy dirty replacement scope: `9` patches.
- MTA-43 component replacement scope: `12` patches.
- Extra promoted replacement patches:
  `adaptive-patch-v1-c3-r0`, `adaptive-patch-v1-c3-r1`, `adaptive-patch-v1-c3-r2`.
- Old faces in those extra promoted patches before regeneration: `2` each.
- Old face survivors after regeneration: `0` for each extra promoted patch.
- Outside control patch `adaptive-patch-v1-c0-r3`: `2` old faces before and `2` survivors after.

Artifact:
`test/terrain/replay/feature_aware_adaptive_baseline_results_mta43_promoted_patch_proof.json`.

## Remaining Gaps

- Retained seam dependency behavior is covered by unit/integration tests and hosted seam validation
  passed for emitted replacement rows, but a hosted retained-seam mismatch/no-delete row was not
  forced in the live model during closeout.
- Retained-Z hard pre-erase gating remains a recorded limitation: hosted evidence validates current
  seam summaries and `maxZGap`, while z-inclusive retained dependency hard gating is still deferred.
- The final three-pass performance capture was rerun against a freshly deployed packaged extension.
