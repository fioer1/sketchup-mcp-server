# Task: MTA-44C Harden Feature Cuts Across Seams And Patch Lifecycle
**Task ID**: `MTA-44C`
**Title**: `Harden Feature Cuts Across Seams And Patch Lifecycle`
**Status**: `defined`
**Priority**: `core`
**Date**: `2026-05-28`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)
- [Superseded MTA-44 task](../MTA-44-add-sparse-local-detail-tiles-and-composed-height-oracle/task.md)

## Problem Statement

Contained feature cuts can safely improve local terrain output, but real terrain edits often touch
or cross patch boundaries. Without seam synchronization and bounded component promotion, inserted
off-grid cut vertices can create cracks, mismatched retained neighbors, duplicate faces, or unsafe
replacement mutations.

This task expands production feature cut graph output from contained cases to seam-aware,
patch-lifecycle-safe terrain regeneration.

The feature-cut model remains the same as MTA-44B: active effective feature geometry drives current
topology requirements, and obsolete cuts disappear when their source constraints are retired,
superseded, or occluded. This task does not introduce a second cross-patch renderer or a durable
history of local detail cells. It makes the same production feature-cut path safe when selected
cut cells touch retained boundaries or cross patch/component boundaries.

The key correctness standard is that an unsupported cross-patch cut must be skipped before
mutation rather than emitted partially. Incomplete enhancement coverage is acceptable; cracked,
duplicated, or silently mismatched seam topology is not.

## Goals

- Support feature cuts that touch or cross patch boundaries through bounded component planning.
- Ensure neighboring patches agree on seam vertices, seam ordering, and oracle-derived seam heights.
- Replace vague local-detail windows with cut-cell and cut-boundary graph reasons in lifecycle
  planning evidence.
- Preserve no-delete mutation safety, retained-output safety, registry/readback, and save/reopen
  behavior.
- Prove cross-patch feature cuts with hosted replay, seam validation, timing, face count, and
  fallback evidence.

## Acceptance Criteria

```gherkin
Scenario: Feature cuts crossing patch boundaries synchronize seams
  Given active feature geometry whose cut graph crosses one or more patch boundaries
  When terrain output regenerates through the production patch lifecycle
  Then every affected neighboring patch uses compatible seam vertices
  And seam heights come from the composed height oracle
  And seam validation reports no open gaps, mismatched chains, or unsupported retained-boundary conflicts

Scenario: Component planning promotes only the required cut neighborhood
  Given a dirty edit window with feature cuts that cross adjacent patch boundaries
  When patch component planning runs
  Then replacement patches include the required cut and conformance neighborhood
  And graph reasons identify cut-boundary, retained-boundary, safety-margin, and conformance roles
  And promotion remains within bounded policy or safely skips enhancement before mutation

Scenario: Existing valid edits remain safe when cross-patch enhancement cannot be emitted
  Given a valid terrain edit whose active feature cuts exceed seam or component policy
  When output regeneration attempts cross-patch feature cut planning
  Then the local cut enhancement safely falls back or skips before replacing old output
  And the valid edit does not become a public refusal solely because enhancement is unavailable
  And old output remains intact if replacement validation fails

Scenario: Hosted evidence proves local improvement without global refinement
  Given replay rows containing cross-patch planar, circular, and corridor feature cuts
  When MTA-44C verification completes
  Then rows record timing, face count, dirty-window scope, replacement patch scope, seam status, and fallback status
  And successful rows show local topology improvement without unexplained global face-count growth
  And every row receives an improved, neutral, regressed, skipped, or failed verdict
```

## Non-Goals

- Adding local CDT islands, native acceleration, or public backend selection.
- Making generated mesh topology the terrain source of truth.
- Exposing patch ids, seam graphs, raw cut cells, or mesh vertices in public MCP responses.
- Supporting arbitrary unsupported feature primitives beyond the normalized feature geometry accepted
  by prior tasks.
- Replacing the patch lifecycle or no-delete mutation model.

## Business Constraints

- Cross-patch feature cuts must not trade visual precision for unreliable terrain ownership.
- Hosted evidence must demonstrate local improvement, seam safety, and bounded face-count impact.
- Valid terrain edits must degrade safely when precise feature cuts cannot be emitted.
- Public terrain tool behavior and response contracts must remain stable.

## Technical Constraints

- `MTA-44A` composed height oracle must exist first.
- `MTA-44B` contained production feature cut output must exist first.
- The solution must build on MTA-42 seam contracts and MTA-43 component planning rather than adding a
  parallel patch replacement system.
- Cut graph seam records must be deterministic for repeated runs over the same active feature state.
- Component graph reasons should be based on active cut cells, cut boundaries, retained boundaries,
  conformance, and safety margin roles rather than vague local-detail windows.
- PatchLifecycle no-delete mutation, retained neighbor safety, registry/readback, and save/reopen
  behavior must remain intact.

## Dependencies

- `MTA-44A`
- `MTA-44B`
- `MTA-42`
- `MTA-43`
- `MTA-36`
- [Superseded MTA-44 task](../MTA-44-add-sparse-local-detail-tiles-and-composed-height-oracle/task.md)

## Relationships

- replaces the seam/component/lifecycle portion of `MTA-44`
- follows `MTA-44B`
- informs any later local CDT, native acceleration, or advanced feature-primitive task

## Related Technical Plan

- none yet

## Success Metrics

- Cross-patch feature cuts validate without seam gaps or mismatched retained boundaries.
- Component promotion is bounded and explained by compact graph reasons.
- Fallback and skip outcomes happen before mutation and preserve old output.
- Hosted replay evidence records timing, face count, seam status, patch scope, and verdicts.
- Public MCP contracts remain unchanged.
