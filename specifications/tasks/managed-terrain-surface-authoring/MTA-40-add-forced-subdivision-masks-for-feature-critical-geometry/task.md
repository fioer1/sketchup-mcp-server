# Task: MTA-40 Add Forced Subdivision Masks For Feature-Critical Geometry
**Task ID**: `MTA-40`
**Title**: `Add Forced Subdivision Masks For Feature-Critical Geometry`
**Status**: `completed`
**Priority**: `core`
**Date**: `2026-05-15`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)

## Problem Statement

Feature-aware tolerance and density can improve triangle allocation, but important design geometry
can still disappear if height residual alone says a cell is acceptable. Hard segments, protected
boundaries, anchors, local detail boundaries, and feature-critical geometry need explicit
subdivision pressure before the system can claim that feature intent affects output topology.

This task introduces forced subdivision masks for feature-critical geometry while preserving the
adaptive patch/cell production path. Existing hard-feature refusals remain part of heightmap edit
and feature-state validity, but disposable mesh generation from a valid terrain heightmap must not
become a new refusal point because a forced subdivision mask is unsupported.

## Goals

- Force adaptive subdivision around supported hard segments, protected boundaries, anchors, and
  feature-critical geometry.
- Preserve existing hard-feature refusal behavior for invalid heightmap edits or invalid feature
  state.
- Treat unsupported feature mask cases during disposable mesh generation as safe fallback/skip
  behavior, without refusing mesh creation from a valid terrain heightmap.
- Preserve existing PatchLifecycle ownership, dirty-window behavior, registry/readback, and
  no-delete replacement.
- Extend validation so height correctness is not confused with feature-topology correctness.
- Ensure corridor-related validation distinguishes compact planar corridor interiors from boundary,
  cap, falloff, and overlap detail instead of treating broad interior face growth as improvement.
- Prove the change with MTA-38 replay evidence and MTA-39 baseline deltas.

## Acceptance Criteria

```gherkin
Scenario: Supported feature-critical geometry forces subdivision
  Given a managed terrain replay row with supported hard or protected feature geometry
  When adaptive output is regenerated through the hosted public command path
  Then cells intersecting supported feature-critical geometry are subdivided according to policy
  And compact internal summaries, when needed, identify supported mask influence without per-cell traces
  And local face-count changes are attributable to the relevant feature windows

Scenario: Unsupported mask cases degrade without blocking disposable mesh output
  Given a valid managed terrain heightmap whose active feature view includes geometry outside the supported forced-mask policy
  When disposable adaptive mesh output planning detects the unsupported mask case
  Then the command still generates terrain geometry for the valid heightmap through a safe fallback path
  And unsupported feature mask influence is skipped or reduced before replacing old disposable output
  And old derived terrain output remains intact if fallback planning cannot produce replacement geometry
  And the public response remains sanitized and does not expose raw feature graphs or internal patch ids

Scenario: Feature topology validation distinguishes more than height residual
  Given a replay row where height samples pass but feature-critical geometry could be underrepresented
  When MTA-40 validation runs
  Then validation checks whether supported feature-critical geometry applied required local subdivision pressure
  And the task records failure when height residual passes but required subdivision pressure was skipped
  And corridor-related rows do not treat broad corridor interior densification as a successful topology improvement

Scenario: Live evidence is recorded for the same baseline corpus
  Given the MTA-38 replay corpus and MTA-39 feature-aware output policy
  When MTA-40 verification completes
  Then every relevant replay row records before/after timing
  And every relevant replay row records before/after face count
  And every relevant replay row records dirty-window and affected-patch scope
  And fallback/skip/no-delete outcomes are recorded compactly for unsupported feature mask cases
  And the task records a verdict of improved, neutral, regressed, or failed for each row
```

## Non-Goals

- Upgrading seam contracts, patch component promotion, sparse local detail tiles, local CDT islands,
  native acceleration, or public backend selection.
- Guaranteeing arbitrary hard-feature representation outside the supported adaptive mask policy.
- Broadly densifying corridor interiors as a proxy for corridor quality.
- Using stitch or mortar strips as the normal seam strategy.
- Making generated mesh topology the terrain source of truth.

## Business Constraints

- This is the first major topology-affecting feature-aware adaptive task and must be proven in
  hosted verification before downstream seam or component work relies on it.
- Existing invalid hard-feature edit refusals must remain intact.
- Unsupported feature mask cases in disposable mesh generation must degrade safely rather than
  silently approximate feature-critical topology or block mesh creation from a valid heightmap.
- Performance and face-count evidence must be comparable with the MTA-38 harness.

## Technical Constraints

- `MTA-39` feature-aware tolerance and density policy must exist first.
- Forced subdivision masks must be deterministic for repeated runs over the same terrain state.
- Corridor-related masks or validation must preserve the MTA-39 lesson that pure corridor interiors
  should remain compact when planar; detail belongs at boundaries, caps, falloff, and overlaps.
- PatchLifecycle ownership and no-delete mutation semantics from MTA-36 must remain intact.
- Public MCP tool names, request schemas, dispatcher routes, and response shapes must remain
  unchanged.
- CDT must not become the production path for this task.

## Dependencies

- `MTA-39`
- `MTA-38`
- `MTA-36`
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)

## Relationships

- blocks `MTA-42`
- informs optional `MTA-41`
- informs `MTA-43`

## Related Technical Plan

- [Technical implementation plan](./plan.md)

## Success Metrics

- Supported feature-critical geometry produces deterministic forced subdivision behavior with compact
  counters only where needed.
- Unsupported feature mask cases fall back or skip mask influence during disposable mesh generation
  while valid heightmap terrain output still produces geometry.
- Replay evidence reports localized face-count impact and timing impact.
- Corridor evidence, when present, reports planar/low-face interior behavior separately from
  boundary, cap, falloff, and overlap detail.
- Validation can fail a row where height residual passes but required feature subdivision is missing.
- Patch ownership, registry/readback, and repeated edit behavior remain reliable.
