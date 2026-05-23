# Summary: MTA-42 Upgrade Adaptive Seam Contracts For Feature-Driven Splits

**Task ID**: `MTA-42`
**Status**: `complete`
**Local Validation Date**: `2026-05-22`
**Hosted Validation Date**: `2026-05-22`

## Shipped Local Behavior

- Added internal adaptive seam contract helpers under
  `src/su_mcp/terrain/output/adaptive_seams/`:
  - `AdaptiveSeamContract` builds canonical patch-side seam records with deterministic
    orientation, reconstructable positions, endpoints, segment count, policy fingerprint, Z values,
    world-edge markers, and a digest over schema, owner-local edge identity, and canonical
    positions only.
  - `AdaptiveSeamValidator` compares planned seams against retained registry seams with explicit
    mismatch categories for malformed records, schema mismatch, policy mismatch, owner-edge
    mismatch, topology mismatch, and planned-Z mismatch.
- Extended adaptive `TerrainOutputPlan` to produce internal seam records for patch boundaries,
  same-batch planned-vs-planned seam validation, dirty replacement/context seam marking, and a
  sealed seam plan carrying the validated replacement scope.
- Extended adaptive patch registry normalization to persist compact per-patch seam records and mark
  malformed seam metadata as patch-local `seamStatus: invalidated` instead of discarding unrelated
  valid patch records.
- Added `TerrainMeshGenerator` pre-erase seam gates for dirty adaptive replacement:
  - rejects missing or mutated sealed seam scope before mutation;
  - validates retained-neighbor seam topology/digest/policy against registry metadata before
    erasing old faces;
  - lazily upgrades legacy adaptive patch registries that predate MTA-42 seam records by validating
    missing retained seam metadata against the sealed retained-context plan and then backfilling
    current seam records into retained context patch metadata on the successful write;
  - preserves old output on seam mismatch by returning the existing sanitized ownership-refusal
    envelope.
- Kept retained pre-erase validation topology/digest/policy-only. Z-inclusive retained validation is
  documented as a hosted/post-emit verification responsibility to avoid broad refusal before
  replacement geometry exists.
- Extended internal hosted replay result artifacts and classifier behavior with
  `seamValidationSummary`; accepted rows with failed seam evidence classify as `failed`.
- Threaded generator seam summaries into command baseline evidence and replay rows so hosted
  captures record the seam status produced by the live adaptive patch generator.
- Kept public MCP request/response contracts unchanged. Contract no-leak coverage now blocks seam
  digest, chain, retained-span, promotion, mismatch-category, and raw seam vocabulary from public
  responses.

## Validation Evidence

- Focused MTA-42 batch:
  - `154 runs, 9954 assertions, 0 failures, 0 errors, 0 skips`
- Final full Ruby tests after Step 06 review cleanup:
  - `bundle exec rake ruby:test`
  - `1518 runs, 19272 assertions, 0 failures, 0 errors, 41 skips`
- Final MTA-42 scoped Ruby lint:
  - `bundle exec rubocop --cache false src/su_mcp/terrain/output/adaptive_seams src/su_mcp/terrain/output/terrain_output_plan.rb src/su_mcp/terrain/output/terrain_mesh_generator.rb src/su_mcp/terrain/output/patch_lifecycle/patch_registry_store.rb src/su_mcp/terrain/commands/terrain_surface_commands.rb src/su_mcp/terrain/probes/feature_aware_adaptive_baseline_replay.rb src/su_mcp/terrain/probes/feature_aware_adaptive_baseline_result_document.rb src/su_mcp/terrain/probes/feature_aware_adaptive_baseline_result_classifier.rb test/terrain/output/adaptive_seams test/terrain/output/terrain_output_plan_test.rb test/terrain/output/terrain_mesh_generator_test.rb test/terrain/output/patch_lifecycle/patch_registry_store_test.rb test/terrain/probes/feature_aware_adaptive_baseline_result_document_test.rb test/terrain/probes/feature_aware_adaptive_baseline_result_classifier_test.rb test/terrain/replay/feature_aware_adaptive_baseline_replay_test.rb test/terrain/contracts/terrain_contract_stability_test.rb`
  - `18 files inspected, no offenses detected`
- Full-repo Ruby lint was rerun at closeout and is currently blocked by unrelated untracked
  `procedural_terrain_planting_mass.rb`, which introduces a second root namespace
  `ProceduralTerrainPlantingMass` and many offenses; the resulting namespace errors then cascade
  through existing `SU_MCP` files. This is not an MTA-42 failure, and the MTA-42 scoped lint target
  is clean.
- Package verification:
  - `bundle exec rake package:verify`
  - produced `dist/su_mcp-1.11.0.rbz`
- Diff hygiene:
  - `git diff --check`
  - no whitespace errors.
- Security/static review:
  - `tldr secure . --format json --quiet`
  - `0` findings.
- Post-hosted evidence handoff focused checks before final cleanup:
  - `bundle exec ruby -Itest test/terrain/replay/feature_aware_adaptive_baseline_replay_test.rb test/terrain/probes/feature_aware_adaptive_baseline_result_document_test.rb test/terrain/output/terrain_mesh_generator_test.rb`
  - `9 runs, 673 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec rubocop --cache false src/su_mcp/terrain/output/terrain_mesh_generator.rb src/su_mcp/terrain/commands/terrain_surface_commands.rb src/su_mcp/terrain/probes/feature_aware_adaptive_baseline_replay.rb test/terrain/replay/feature_aware_adaptive_baseline_replay_test.rb`
  - `4 files inspected, no offenses detected`
- Final focused cleanup checks:
  - `bundle exec ruby -Itest test/terrain/output/adaptive_seams/adaptive_seam_validator_test.rb test/terrain/output/adaptive_seams/adaptive_seam_contract_test.rb`
  - `5 runs, 20 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec rubocop --cache false src/su_mcp/terrain/output/adaptive_seams test/terrain/output/adaptive_seams`
  - `4 files inspected, no offenses detected`
- Legacy registry migration follow-up:
  - `bundle exec ruby -Itest test/terrain/output/terrain_mesh_generator_test.rb -n '/legacy_registry_missing_seam_records|retained_seam_mismatch/'`
  - `2 runs, 72 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec ruby -Itest test/terrain/output/terrain_mesh_generator_test.rb`
  - `77 runs, 1931 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec rubocop --cache false src/su_mcp/terrain/output/terrain_mesh_generator.rb test/terrain/output/terrain_mesh_generator_test.rb`
  - `2 files inspected, no offenses detected`

## Code Review

- Local `$task-review` deterministic pass ran without subagents because the available subagent tool
  requires explicit user authorization for delegated agent work. Direct structural commands were
  run: bugbot, smells, hotspots, secure, targeted code inspection, and diff inspection.
- Bugbot reported no L1 lint findings in the seam helper path after the final cleanup. Its scoped
  path analysis still had path-scope artifacts, including an incorrect `AdaptiveSeamContract.build`
  born-dead warning; direct call-site inspection confirms production use in
  `TerrainOutputPlan.seam_record_for_side`.
- `tldr smells` reports accepted seam-helper complexity:
  - `AdaptiveSeamContract.build` has a long parameter list because it mirrors the explicit internal
    seam-record schema.
  - `AdaptiveSeamValidator` digest and mismatch checks are compact ordered validators over a finite
    mismatch vocabulary.
- PAL codereview with `model: "grok-4.3"` completed after local code inspection and found no
  blocking or non-blocking issues. It explicitly accepted the topology/digest/policy-only retained
  pre-erase gate for this task scope because Z-inclusive retained proof is documented, tested, and
  captured through hosted/post-emit evidence.
- Final review cleanup removed the unused `AdaptiveSeamValidator.validate_world_edge` helper and its
  test instead of retaining a born-dead internal method.

## Contract And Docs

- Public terrain command names, request schemas, dispatcher routes, and public response shapes were
  not changed.
- User-facing docs were reviewed by scope and were not updated because no public usage, setup,
  request, response, or workflow contract changed.
- Internal replay/result artifacts changed, and their tests were updated in the same change.

## Hosted Verification

- Reloaded the deployed MTA-42 runtime/probe files inside live SketchUp 2026 through the hosted Ruby
  bridge and verified:
  - `AdaptiveSeamContract` and `AdaptiveSeamValidator` constants were loaded.
  - replay evidence keys include `seamValidationSummary`.
  - `TerrainMeshGenerator` exposes `last_adaptive_seam_validation_summary`.
- Captured the full hosted replay with timing and quality enabled:
  - Artifact: `test/terrain/replay/feature_aware_adaptive_baseline_results_mta42_live.json`
  - Annotated artifact:
    `test/terrain/replay/feature_aware_adaptive_baseline_results_mta42_live_annotated.json`
  - Captured at `2026-05-22T16:40:36+03:00` with extension version `1.11.0`.
  - `18` rows, `0` refusals.
  - `18` rows carried seam evidence.
  - `0` seam failures, `maxZGap: 0.0`.
  - Live geometry after final replay:
    - `feature-aware-baseline-terrain`: `1773` faces, `2698` edges.
    - `feature-aware-baseline-terrain-large-timing`: `55097` faces, `83000` edges.
    - `feature-aware-baseline-terrain-wide-timing`: `24360` faces, `36737` edges.
- Classified the hosted artifact against the reusable baseline:
  - `15` rows classified as `policy_applied`.
  - `3` rows classified as `neutral`.
  - `0` rows classified as `failed` or `regressed`.
- Captured a clean serialized three-run MTA-42 hosted performance pack after a fresh SketchUp
  restart/deploy, compared against the retained MTA-45 three-run performance baseline:
  - Run artifacts:
    - `test/terrain/replay/feature_aware_adaptive_baseline_results_mta42_perf_run_1.json`
    - `test/terrain/replay/feature_aware_adaptive_baseline_results_mta42_perf_run_2.json`
    - `test/terrain/replay/feature_aware_adaptive_baseline_results_mta42_perf_run_3.json`
  - Summary artifact:
    `test/terrain/replay/feature_aware_adaptive_baseline_results_mta42_perf_summary.json`
  - Total command seconds: mean `79.396059`, runs `77.845681`, `78.058778`, `82.283719`.
  - MTA-45 three-run baseline mean: `78.4496`, so MTA-42 is `+1.2%` command time.
  - Total harness quality seconds: mean `15.452101` versus MTA-45 `15.5895`, `-0.9%`.
  - Total faces were stable across all three runs at `464218`, `-3920` faces versus MTA-45
    coalesced geometry (`-0.8%`).
  - All `18` rows had stable face and vertex counts.
  - All seam statuses were `passed`; `0` seam failures.
  - No rows exceeded the `25%` timing threshold versus MTA-45. Largest row-level slowdown was
    `planar-pad-intersect` at `+8.3%`.
- Ran a live negative no-delete seam smoke on a fresh large replay terrain:
  - Created `feature-aware-baseline-terrain-large-timing`.
  - Corrupted retained registry seam digests before the first partial local edit.
  - Edit refused with `terrain_output_ownership_invalid`.
  - Face count remained `76191` before and after refusal, proving old output stayed intact.
  - Restored the registry and then reran the full hosted replay to reset the scene/artifact.

## Remaining Gaps

- Direct-neighbor promotion is not enabled as a mutating fallback in this local slice; unsafe or
  unconformed retained seam changes refuse before mutation.
- Post-emit/pre-commit retained Z verification is still not a hard generator gate; hosted replay
  records `maxZGap: 0.0` for current rows, while the pre-erase retained guard remains
  topology/digest/policy-only by design.
