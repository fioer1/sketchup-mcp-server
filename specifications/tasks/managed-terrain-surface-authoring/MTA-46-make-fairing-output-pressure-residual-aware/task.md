# Task: MTA-46 Make Fairing Output Pressure Residual-Aware
**Task ID**: `MTA-46`
**Title**: `Make Fairing Output Pressure Residual-Aware`
**Status**: `defined`
**Priority**: `core`
**Date**: `2026-05-20`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)

## Problem Statement

MTA-45 proved that absolute planar regions can compact when older pressure is clipped and no later
feature overlays reintroduce output detail. A follow-up hosted inspection found a separate pressure
policy issue: a later broad circular `local_fairing` edit can make an otherwise flat or low-error
planar area look dense again. The final heightfield can remain within planar quality tolerance, but
fairing support is currently treated as unconditional soft density pressure. That pressure can force
subdivision across the fairing envelope, including inside already-planar or newly-planar cells where
additional triangles do not represent meaningful surface change.

The task exists to make fairing-derived output pressure residual-aware enough that fairing still
represents genuinely bumpy or high-error terrain, while avoiding dense output over regions whose
post-edit surface is already low-error.

## Goals

- Prevent `fairing_support` pressure from forcing dense adaptive output over cells whose post-edit
  heightfield is already low-error or planar enough to simplify.
- Preserve fairing behavior on genuinely uneven terrain where the resulting surface still needs
  output detail.
- Keep circular fairing regions in scope, including the large circular fairing-over-planar replay
  case discovered during MTA-45.
- Preserve authoritative feature detail for survey anchors, corridor detail, protected boundaries,
  and other non-fairing pressure.
- Preserve public MCP terrain command contracts and response shapes.
- Prove the behavior with local policy/output tests and hosted SketchUp replay or fixture evidence.

## Acceptance Criteria

```gherkin
Scenario: Circular fairing over low-error planar area does not force dense output
  Given a managed terrain with a rectangular absolute planar region
  And a newer circular local_fairing region overlaps the planar rectangle
  And the post-fairing heightfield inside the planar rectangle remains within the configured output tolerance
  When adaptive terrain output is regenerated
  Then fairing_support pressure alone does not prevent low-error planar cells from simplifying
  And the planar rectangle does not return to full-grid-like triangle density
  And planar-region quality remains within local tolerance

Scenario: Circular fairing over bumpy terrain still preserves needed detail
  Given a managed terrain with a circular local_fairing region over uneven terrain
  And the post-fairing heightfield still has cells whose residual error exceeds output tolerance
  When adaptive terrain output is regenerated
  Then the fairing region retains enough adaptive detail to represent the remaining surface shape
  And low-error portions of the same fairing region may simplify
  And no terrain edit evidence falsely reports the fairing as unsupported or ignored

Scenario: Non-fairing feature pressure remains authoritative
  Given survey anchors, corridor detail, protected boundaries, or forced subdivision inputs overlap a low-error region
  When adaptive terrain output is regenerated
  Then those non-fairing inputs continue to apply their existing feature-aware output policy
  And the residual-aware fairing behavior does not suppress authoritative hard, firm, protected, or forced detail

Scenario: Hosted replay records the fairing-over-planar distinction
  Given the MTA-38 replay corpus and the MTA-45 fairing-over-planar observation
  When MTA-46 verification completes
  Then hosted evidence records the large circular fairing-over-planar case
  And the evidence compares face counts, planar-region quality, timing, and affected patch scope
  And the task records whether fairing pressure remains bounded to geometrically necessary output detail
```

## Non-Goals

- Replacing the production adaptive patch/cell output path with CDT, sparse local detail tiles, or
  a new mesh backend.
- Making planar regions globally override newer fairing edits regardless of measured output error.
- Removing circular fairing support or converting fairing into a planar-fit or grade-intent
  operation.
- Changing public terrain edit request schemas, tool names, dispatcher routes, or public response
  shapes.
- Solving exact circular topology, exact feature-boundary triangulation, or all future soft-pressure
  policy questions.

## Business Constraints

- Fairing is a visible finishing workflow; users should not see a nearly flat surface return to
  full-grid-like tessellation simply because a broad fairing region overlapped it.
- Fairing must remain useful for smoothing rough terrain and should not become a no-op on surfaces
  that still require visible residual detail.
- The task should keep evidence comparable with the reusable MTA-38 replay harness and the MTA-45
  planar/fairing observation.

## Technical Constraints

- `MTA-45` is the immediate discovery source and provides the clean planar compaction comparison.
- `MTA-39` owns feature-aware tolerance and density policy behavior that this task must refine
  without breaking non-fairing pressure.
- `MTA-40` owns forced subdivision policy that must remain authoritative for feature-critical
  geometry.
- `MTA-38` replay artifacts should be used or extended for hosted timing and quality comparison.
- Circular fairing regions must remain represented as circular regions at the intent level; any
  policy simplification must not silently change user-authored fairing shape semantics.
- Hosted SketchUp validation is required because the defect is visible in emitted terrain topology,
  not only in feature evidence counters.

## Dependencies

- `MTA-45`
- `MTA-40`
- `MTA-39`
- `MTA-38`
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)

## Relationships

- follows `MTA-45`
- informs `MTA-42`
- informs `MTA-43`
- informs `MTA-44`
- relates to `MTA-27`

## Related Technical Plan

- none yet

## Success Metrics

- The large circular fairing-over-planar fixture no longer returns the planar rectangle to
  full-grid-like triangle density when measured error is low.
- Fairing over uneven terrain still retains output detail where residual error exceeds tolerance.
- Non-fairing authoritative pressure behavior remains unchanged in focused regression tests.
- Hosted evidence records face-count, quality, timing, and patch-scope comparison for the circular
  fairing-over-planar case.
