# STI-04 Implementation Summary
**Task ID**: `STI-04`
**Status**: `completed`
**Date**: `2026-05-18`

## Shipped

- Added lightweight target field readers to `SceneQuerySerializer` so filtering can compare identity, attribute, and metadata fields without building full public match hashes for every candidate.
- Added `TargetingQuery#filter_adapter` as the shared adapter-aware filtering path for `find_entities`, direct target-reference resolution, and validation target selectors.
- Added group/component container enumeration to `ModelAdapter` for sourceElementId pre-scans.
- Kept `sourceElementId` lookup conservative: multiple container matches can short-circuit as ambiguous, but zero or one container match falls back to exhaustive lightweight recursive scanning so lower-level duplicates are not hidden.
- Routed `TargetReferenceResolver` non-native lookups through the shared optimized targeting path while preserving native `entityId` and `persistentId` lookup behavior.
- Updated `SampleSurfaceQuery` target resolution to use lightweight target-reference matching where available.
- Removed the unused `all_entities_recursive` collection from `sample_surface_z` command execution when recursive path entries are supplied.

## Validation

- Full Ruby suite passed: `533 runs, 1985 assertions, 0 failures, 0 errors, 2 skips`.
- Focused scene-query, scene-validation, staged-asset, and semantic suites passed after the changes: `259 runs, 981 assertions, 0 failures, 0 errors, 2 skips`.
- RuboCop passed on touched Ruby source and test files with `--cache false`.
- Regression tests cover:
  - sourceElementId-only filtering serializes only final public matches
  - lower-level sourceElementId lookup remains discoverable
  - container plus lower-level duplicate sourceElementId returns `ambiguous`
  - direct target-reference resolution reuses shared filtering
  - validation target selectors reuse shared filtering and retain public-surface filtering
  - sample-surface target resolution avoids full match serialization
  - `sample_surface_z` command execution avoids unused recursive entity enumeration

## Code Review

- Grok 4.3 codereview was run on the completed change set.
- The main correctness concern identified during review was the original single-container fast path hiding a lower-level duplicate sourceElementId.
- That finding was addressed by making the sourceElementId path conservative: only multiple container matches return early; otherwise the exhaustive lightweight recursive scan runs.
- After the refactor, Grok 4.3 reported no required fixes and no blocking findings.

## Live SketchUp Verification

- Live `find_entities` by `sourceElementId` resolved `STR-002` correctly.
- Live missing sourceElementId lookup returned `none` without returning to the original multi-second serialization-heavy path.
- Live `find_entities` by `entityId`, `persistentId`, and attribute `name` resolved the expected entity.
- Live `get_entity_info` by `sourceElementId` and `entityId` resolved correctly.
- Live `measure_scene` bounds for a missing target returned the expected structured `target_resolution_failed` refusal.
- Live `sample_surface_z` profile returned valid ordered profile results.
- After the conservative ambiguity-preserving refactor, representative sourceElementId timings stayed under one second in the large scene:
  - `STR-002`: about `0.75s`
  - missing segment sourceElementId: about `0.74s`

## Contract and Docs

- No public MCP tool names, schemas, request shapes, response shapes, or refusal payload contracts changed.
- No user-facing docs were required for this task because the change is an internal performance and correctness hardening of existing query behavior.
- Task metadata was added retrospectively in `task.md`, `plan.md`, and `size.md`.

## Remaining Gaps

- `sample_surface_z` profile still materializes recursive path entries to preserve nested transform semantics. A future path-aware resolver could reduce that remaining cost, but it was intentionally out of scope for STI-04.
