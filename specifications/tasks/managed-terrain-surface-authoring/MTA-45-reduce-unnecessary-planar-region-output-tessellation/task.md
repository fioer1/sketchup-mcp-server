# Task: MTA-45 Reduce Unnecessary Planar Region Output Tessellation
**Task ID**: `MTA-45`
**Title**: `Reduce Unnecessary Planar Region Output Tessellation`
**Status**: `planned`
**Priority**: `core`
**Date**: `2026-05-17`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)

## Problem Statement

MTA-40 removed broad no-falloff planar density pressure and collapsed some coplanar conformance
fan triangles, but hosted validation still showed planar regions carrying more vertices and
triangles than the visible planar intent needs. The remaining problem is stack-order pressure
leakage: a later no-falloff planar region is an absolute planar edit, so older underlying corridor,
target, survey, or fairing pressure must not translate through the intersecting part of the planar
footprint as interior tessellation. This must be intersection-aware: older feature pressure remains
valid outside the later planar footprint, but is suppressed or clipped where the later absolute
plane covers it. This override applies only because the planar edit is later in stack order; the
planar surface's flatness must not suppress features that are newer than the planar edit. Only newer
features applied on top of the planar edit, or explicit positive planar falloff/blend transition
detail, should add output pressure inside that planar area.

The system needs a follow-up task that makes planar-region output compact where the plane itself
does not require interior detail, without reintroducing detached overlay plates, holes, ownership
ambiguity, or broad triangulation changes outside the planar feature boundary.

## Goals

- Prevent older underlying feature pressure from driving tessellation inside later absolute
  no-falloff planar regions.
- Apply that suppression intersection-aware, preserving the older feature's valid pressure outside
  the later planar footprint.
- Reduce unnecessary vertices and triangles inside those planar interiors.
- Preserve correct stitching between planar regions and surrounding terrain output.
- Preserve newer features applied on top of a planar edit, including corridors, targets, survey
  corrections, and fairing effects.
- Ensure a planar edit's flatness does not override features that are newer than that planar edit.
- Keep positive planar falloff/blend behavior focused on edge transition detail rather than broad
  interior densification.
- Preserve PatchLifecycle ownership, registry/readback, dirty-window behavior, and no-delete
  replacement semantics.
- Prove the change with hosted replay evidence, including planar-specific face/vertex counts,
  quality, timing, and visual/readback checks.

## Acceptance Criteria

```gherkin
Scenario: Older underlying pressure does not pass through absolute planar interiors
  Given a managed terrain state with an active rectangular planar_region edit
  And the planar region has no positive falloff or blend
  And an older corridor, target, survey, or fairing feature intersects that planar footprint
  And no newer active feature intersects the planar region
  When adaptive terrain output is regenerated
  Then the older feature does not contribute feature-density or forced-subdivision pressure inside the planar footprint
  And the older feature may still contribute its own pressure outside the planar footprint
  And the planar region interior does not receive broad planar density pressure
  And emitted interior vertices and triangles are reduced compared with the MTA-40 final baseline
  And planar-region height quality remains within the existing local tolerance target

Scenario: Planar boundaries remain stitched to surrounding terrain
  Given an absolute planar region adjacent to non-planar terrain
  When adaptive output is regenerated through the hosted public command path
  Then the planar output remains connected to surrounding terrain without holes or detached plates
  And patch-owned faces still have complete ownership metadata
  And registry/readback succeeds after the edit

Scenario: Newer features on top of planar regions remain authoritative
  Given an absolute planar region
  And a newer corridor, target, survey, or fairing feature intersects that planar region
  When adaptive output is regenerated
  Then the newer feature remains represented according to its own feature-aware policy
  And the planar region's flatness does not suppress the newer feature's pressure or detail
  And planar compaction does not erase or flatten that newer feature
  And older features below the planar edit do not reintroduce unnecessary planar interior detail

Scenario: Planar falloff is treated as edge transition detail
  Given a planar_region edit with positive falloff or blend
  When adaptive output is regenerated
  Then additional output pressure is bounded to the falloff or transition edge area
  And the planar interior is not broadly densified solely because the region is planar

Scenario: Hosted evidence records planar-specific improvement
  Given the MTA-38 replay corpus and the MTA-40 final result pack
  When MTA-45 verification completes
  Then every relevant planar replay row records before/after face count and vertex count
  And every relevant planar replay row records planar-region quality
  And timing, dirty-window scope, affected patch scope, and fallback/no-delete outcomes are recorded
  And the task records whether planar tessellation was reduced without topology or quality regression
```

## Non-Goals

- Replacing the production adaptive patch/cell output path with a global CDT or TIN backend.
- Solving all exact hard-feature topology, seam lattice, patch component promotion, or sparse local
  detail tile behavior.
- Using detached planar overlay plates, unowned cross-patch faces, holes, or stitch/mortar strips as
  the normal planar compaction strategy.
- Changing public MCP tool names, request schemas, dispatcher routes, or public response shapes.
- Making generated mesh topology the terrain source of truth.
- Treating broad planar interior face growth as a successful quality signal.

## Business Constraints

- Planar edits are a visible authoring workflow; users should not see thousands of unnecessary
  triangles in a simple planar pad because older underlying feature pressure leaked through the
  later planar edit.
- The fix must preserve the intended stack order: a later absolute planar edit overrides older
  feature pressure inside its footprint, while later feature edits on top of that planar edit remain
  represented.
- Evidence must stay comparable with the reusable MTA-38 replay harness and the MTA-40 final result
  pack.
- If the current adaptive patch/cell path cannot safely compact a planar case, the task should
  record the limitation rather than ship a fragile topology workaround.

## Technical Constraints

- `MTA-40` is the baseline dependency because planar pressure removal, forced masks, replay quality
  sampling, and performance evidence are already established there.
- PatchLifecycle ownership and no-delete mutation semantics from `MTA-36` must remain intact.
- Feature-aware tolerance and density behavior from `MTA-39` must remain compatible.
- Positive planar falloff and newer feature overlays must be distinguished from absolute planar
  interiors.
- A planar edit's absolute nature applies backward in stack order only; it must not override newer
  feature overlays.
- Older feature pressure below a later absolute planar edit must be suppressed within the planar
  footprint without removing the older feature's valid pressure outside that footprint.
- Suppression must be based on geometric intersection with the planar footprint, not only on whether
  the older feature geometry is fully contained by that footprint.
- Dirty-window replacement must not leave stale compacted planar output behind.
- Hosted SketchUp validation is required because planar stitching, registry/readback, and visual
  topology cannot be fully proven by isolated unit tests.

## Dependencies

- `MTA-40`
- `MTA-39`
- `MTA-38`
- `MTA-36`
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)

## Relationships

- follows `MTA-40`
- informs `MTA-42`
- informs `MTA-43`
- informs `MTA-44`
- does not block optional `MTA-41`

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- MTA-45 replay evidence shows lower planar-row face and vertex counts than the MTA-40 final
  baseline where older feature pressure previously leaked through no-falloff planar rows.
- Planar-region quality remains within local tolerance on all relevant hosted replay rows.
- No relevant row regresses dirty-window scope, affected patch scope, registry/readback, or no-delete
  behavior.
- Newer corridor/target/survey/fairing features on top of planar regions remain represented in
  hosted validation.
- Three-run hosted performance comparison shows no unacceptable timing regression against the
  MTA-40 final performance summary.
