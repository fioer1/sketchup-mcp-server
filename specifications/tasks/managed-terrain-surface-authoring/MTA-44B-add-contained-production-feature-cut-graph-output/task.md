# Task: MTA-44B Add Contained Production Feature Cut Graph Output
**Task ID**: `MTA-44B`
**Title**: `Add Contained Production Feature Cut Graph Output`
**Status**: `closed-blocked`
**Priority**: `core`
**Date**: `2026-05-28`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)
- [Superseded MTA-44 task](../MTA-44-add-sparse-local-detail-tiles-and-composed-height-oracle/task.md)

## Problem Statement

Feature-aware adaptive output can increase density near important features, but it still does not
guarantee that off-grid feature boundaries, breaklines, or control points appear as actual terrain
topology. Target circles, diagonal corridor edges, and planar boundaries can be underrepresented if
the system only applies broad pressure or residual tolerance.

This task adds the first production feature cut graph slice for topologically safe, contained cases.
It must use the normal terrain regenerate path and must not create a hidden experimental renderer.

The intended behavior is constraint-driven local topology, not fuzzy local high-resolution windows.
Feature cuts are regenerated from the current effective feature geometry each time output is
planned. Refinement should be limited to cells intersected by active topology-forcing constraints,
cells containing required off-grid control points, or cells whose current triangulation exceeds
tolerance against the composed height oracle. An edit's broad influence or support window is not
itself the refinement footprint.

The reverse case is part of the model: if older target, circular, diagonal, or rounded cuts are
superseded or occluded by a newer active planar feature, those old cuts must disappear because they
are no longer present in the effective feature geometry. Local topology is derived output, not
accumulated edit history.

## Goals

- Derive local cut requirements from active effective feature geometry rather than edit history.
- Emit exact local cuts for contained feature boundaries, breaklines, and required off-grid points
  through the normal production terrain output path.
- Use the composed height oracle for all inserted off-grid vertices.
- Refine only cells selected by active cut constraints or residual requirements.
- Safely skip local cut enhancement when the cut footprint would touch retained seams or cross
  unsupported patch/component boundaries.
- Remove obsolete local cuts automatically when newer active features supersede or occlude the
  constraints that created them.

## Acceptance Criteria

```gherkin
Scenario: Contained planar boundary produces local production cuts
  Given a managed terrain edit whose active planar boundary crosses interior base cells inside one safe regenerated component
  When terrain output regenerates through the normal production path
  Then only cells selected by the active feature cut graph are locally replaced
  And inserted cut vertices receive heights from the composed height oracle
  And unaffected neighboring cells keep the existing production output shape

Scenario: Contained circular or diagonal feature boundary is represented as topology
  Given active feature geometry for a target circle or diagonal corridor edge fully contained away from retained seams
  When terrain output regenerates
  Then the feature boundary is approximated by deterministic topology-forcing cut segments
  And the local face growth is limited to selected cut or residual cells
  And the public response remains sanitized and contract-compatible

Scenario: Later feature state removes obsolete cuts
  Given previous active target features created local cut topology
  And a newer active planar feature supersedes or occludes those constraints inside its domain
  When terrain output regenerates from the current effective feature view
  Then obsolete interior cuts are not emitted
  And only currently active topology-forcing constraints influence local replacement cells

Scenario: Unsupported boundary-touching cuts skip enhancement safely
  Given an active feature cut footprint that touches a retained seam or crosses unsupported patch/component boundaries
  When contained feature cut output planning runs
  Then local cut enhancement is skipped before mutation
  And the valid terrain edit still succeeds through the existing production output path
  And old output remains intact if replacement validation fails
```

## Non-Goals

- Supporting cuts that touch retained seams or require cross-patch synchronization.
- Solving bounded component promotion for feature cuts.
- Introducing local CDT islands, native acceleration, or public backend selection.
- Exposing raw feature graphs, cut cells, patch ids, or inserted mesh vertices in public command responses.
- Broadly densifying edit influence windows as a proxy for precise feature topology.

## Business Constraints

- The task must deliver production-visible improvement through existing terrain tools.
- The task must avoid the previous CDT trap of proving behavior in a non-production path.
- Valid terrain edits must not be refused merely because local cut enhancement is unavailable.
- Local face-count growth must be attributable to active feature constraints, not fuzzy refinement
  windows.

## Technical Constraints

- `MTA-44A` composed height oracle must exist first.
- `EffectiveFeatureView` and `TerrainFeatureGeometryBuilder` remain the source of active topology
  constraints.
- Feature cuts must be regenerated from current active feature geometry, not accumulated as durable
  edit-history topology.
- Boundary-touching or cross-patch cut cases must safely skip enhancement until `MTA-44C`.
- Circular regions must be represented as topology-forcing boundary geometry where the active
  feature semantics require a cut, rather than only as broad pressure regions.
- The task must distinguish topology-forcing constraints from soft influence/support domains.
- PatchLifecycle ownership, no-delete mutation, registry/readback, and public MCP contracts must
  remain unchanged.

## Dependencies

- `MTA-44A`
- `MTA-40`
- `MTA-43`
- `MTA-45`
- [Superseded MTA-44 task](../MTA-44-add-sparse-local-detail-tiles-and-composed-height-oracle/task.md)

## Relationships

- replaces the contained production local-detail output portion of `MTA-44`
- follows `MTA-44A`
- blocks `MTA-44C`

## Related Technical Plan

- [Technical Implementation Plan](./plan.md)

## Success Metrics

- Contained planar, circular, and diagonal feature cases produce production-visible local topology.
- Local face-count growth is limited to selected cut/residual cells.
- Boundary-touching cases skip enhancement without refusing valid edits or mutating old output.
- Superseded or occluded feature constraints no longer produce stale cut topology.
- Save/reopen and readback evidence remain reliable with no public contract drift.
