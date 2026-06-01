# Task: MTA-44A Establish Effective Feature Composed Height Oracle
**Task ID**: `MTA-44A`
**Title**: `Establish Effective Feature Composed Height Oracle`
**Status**: `implementation-complete`
**Priority**: `core`
**Date**: `2026-05-28`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)
- [Superseded MTA-44 task](../MTA-44-add-sparse-local-detail-tiles-and-composed-height-oracle/task.md)

## Problem Statement

Feature-aware terrain output already has durable feature intent and an effective feature view, but
height queries still risk being split across base-grid elevation reads, samplers, output planning,
validation, and readback paths. Before local cut topology can be trusted, the runtime needs one
production height truth model built from current active feature intent, normalized feature geometry,
and base terrain state.

This task establishes that composed height oracle without changing mesh topology.

The superseded MTA-44 plan is useful background, but its sparse local-detail tile/window framing is
not the execution model for this split. The intended model is: active feature intent produces an
effective feature view, the effective feature view produces normalized feature geometry, the oracle
answers height semantics for that current model, and later feature-cut planning decides topology.
The oracle may use effective feature geometry to answer height and precedence questions, but it
must not become the object that decides where mesh cuts are emitted.

## Goals

- Provide a deterministic composed height oracle for current terrain state and effective feature
  geometry.
- Harden circular effective-feature handling so active circular target, planar, preserve/protected,
  and support regions remain semantically circular through feature selection, feature geometry, and
  oracle queries.
- Preserve existing production output behavior when no topology-changing local cuts are present.
- Ensure base-only terrain sampling remains compatible with the existing bilinear/base-grid behavior.
- Make active feature precedence explicit for planar, target, fixed/control, preserve, and base
  height behavior.
- Add guardrails so production height-query paths do not keep growing new raw base-height reads.

## Acceptance Criteria

```gherkin
Scenario: Base-only terrain preserves current height behavior
  Given a managed terrain state with no active feature geometry that changes height precedence
  When production sampling, validation, and readback ask for terrain height through the composed oracle
  Then oracle heights match the existing base-grid interpolation behavior within tolerance
  And mesh topology and public command response shapes remain unchanged

Scenario: Active feature height precedence is deterministic
  Given terrain state with active planar, target, fixed/control, preserve, and base-height contexts
  When the composed oracle is queried at points covered by those contexts
  Then the selected height source follows documented deterministic precedence
  And repeated queries across save and reload return the same height values

Scenario: Existing feature view remains the source of active constraints
  Given feature intent containing active, retired, and superseded features
  When the composed oracle is built for output planning or validation
  Then it uses the effective feature view rather than raw edit history
  And superseded or retired feature constraints do not affect oracle answers

Scenario: Circular active features remain circular through the effective feature model
  Given active circular target, planar, preserve/protected, and support-region feature intent
  When the effective feature view and terrain feature geometry are built
  Then selected circular features preserve their owner-local center and radius semantics
  And circular feature identity is not reduced to bounding-box-only behavior for height semantics
  And diagnostics identify unsupported or partially represented circular feature geometry explicitly

Scenario: Circular oracle semantics use circle membership rather than rectangular bounds
  Given an active circular target or planar feature whose bounding box covers points outside the circle
  When the composed oracle is queried at points inside the circle, outside the circle but inside the bounding box, and on the circular boundary tolerance band
  Then inside points use the circular feature's applicable height rule
  And outside-bounding-box-interior points do not incorrectly receive the circular feature's height rule
  And boundary tolerance behavior is deterministic and repeatable

Scenario: Newer active planar features suppress obsolete circular semantics
  Given older circular target or support features overlapped by a newer active absolute planar feature
  When effective feature geometry and oracle inputs are derived
  Then fully occluded obsolete circular feature semantics are removed from the effective oracle context
  And partially occluded circular semantics are either clipped deterministically or surfaced as a compact internal limitation
  And no stale circular height rule applies inside the newer planar feature's authoritative domain

Scenario: Production height paths do not bypass the oracle for behavior-defining reads
  Given a terrain output or validation path that needs composed terrain height
  When repository checks run
  Then behavior-defining height reads are routed through the composed oracle or explicitly classified as base-state mutation reads
  And any remaining direct base-grid reads are documented as non-oracle paths
```

## Non-Goals

- Adding feature cut graph output, inserted off-grid vertices, or local mesh cell replacement.
- Changing public MCP tool names, request schemas, or response shapes.
- Making generated mesh topology the terrain source of truth.
- Solving cross-patch seam synchronization for feature cuts.
- Emitting circular boundary segments or cut cells for mesh topology; this task only preserves
  circular semantics for active feature geometry and height/oracle behavior.
- Replacing existing edit kernels wholesale.

## Business Constraints

- The task must reduce MTA-44 implementation risk without creating a hidden alternate renderer.
- Existing terrain authoring workflows should remain visually and operationally unchanged.
- The oracle must support later production feature-cut work without exposing internal feature graphs
  in public responses.

## Technical Constraints

- `EffectiveFeatureView` remains the active-feature selector for current feature intent.
- `TerrainFeatureGeometryBuilder` remains the normalized feature geometry source.
- Circular primitives must remain distinguishable from rectangular bounds in oracle-relevant
  feature geometry and diagnostics.
- The composed oracle must be deterministic, SketchUp-free at the domain/planning layer, and
  JSON-safe where serialized evidence is produced.
- The oracle owns height semantics, not topology selection; feature cuts belong to later planning.
- Public command contracts and dispatcher behavior must remain unchanged.
- Existing PatchLifecycle ownership, no-delete mutation, registry, and readback behavior must not
  regress.

## Dependencies

- `MTA-40`
- `MTA-42`
- `MTA-43`
- `MTA-45`
- [Superseded MTA-44 task](../MTA-44-add-sparse-local-detail-tiles-and-composed-height-oracle/task.md)

## Relationships

- replaces the oracle portion of `MTA-44`
- blocks `MTA-44B`
- informs `MTA-44C`

## Related Technical Plan

- [Technical implementation plan](./plan.md)

## Success Metrics

- Base-only oracle parity is proven against existing sampling behavior.
- Active feature precedence is covered by deterministic tests.
- Circular feature selection, normalization, membership, and occlusion behavior is covered by
  deterministic tests.
- Save/reload or serializer evidence shows oracle inputs remain stable.
- Production height-query paths have an explicit oracle-use guard or documented exception list.
- No public MCP contract or response-shape drift is introduced.
