# Task: MTA-44B1 Deliver Production Off-Grid Feature Cut Output
**Task ID**: `MTA-44B1`
**Title**: `Deliver Production Off-Grid Feature Cut Output`
**Status**: `defined`
**Priority**: `core`
**Date**: `2026-06-03`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)
- [MTA-44B technical discovery notes](./technical-discovery-notes.md)
- [Superseded MTA-44 task](../MTA-44-add-sparse-local-detail-tiles-and-composed-height-oracle/task.md)

## Problem Statement

Current production terrain output does not reliably represent off-grid feature edits as actual mesh
topology. Feature-aware adaptive pressure can add density near important areas, but target circles,
diagonal corridor edges, non-grid-aligned planar or rectangle boundaries, breaklines, and off-grid
control points can still be approximated by broad refinement rather than by terrain vertices and
edges that coincide with the intended feature geometry.

MTA-44B did not change that business premise; it failed to deliver it. The task and plan
underrepresented the real implementation complexity by treating a bounded adaptive rewrite as likely
enough for the production slice. Live validation showed that simple cases could improve, but the
approach could still produce manifold-but-wrong terrain, lose height semantics on visible cuts,
underrepresent composed feature intersections, and drift into shape-specific fixes.

This task replaces MTA-44B as the same business capability with a more realistic scope and proof
standard. Production off-grid feature-cut output must come from the current effective feature
geometry, must be proven on simple and composed off-grid cases, and must start from a constrained
cut-generation approach rather than another adaptive-only/local-template plan. Existing CDT work is
relevant prior art and implementation input, but it is not assumed to be directly reusable in its
current form. A key regression guard from the failed MTA-44B implementation is that any derived cut
or height constraints used to generate output must remain disposable derived output metadata, not
authoritative terrain state or accumulated edit history that blocks later terrain edits.

## Goals

- Make supported off-grid feature edits read as real production terrain geometry, with mesh vertices
  and edges that coincide with intended circles, diagonal corridors, non-grid-aligned boundaries,
  breaklines, and control points.
- Generate off-grid cut topology from the current effective feature geometry through the normal
  production terrain output path.
- Preserve correct heights on inserted cut vertices and adjacent terrain so visible topology is not
  merely correct in XY.
- Support composed or intersecting off-grid feature boundaries through a constrained cut-generation
  approach, using existing CDT work as prior art where useful.
- Keep adaptive rewrite limited to explicitly proven simple-case fast paths or safe fallback, not
  the general solution.
- Preserve normal editability so later valid terrain edits are not blocked by stale derived output
  constraints.

## Acceptance Criteria

```gherkin
Scenario: Off-grid feature boundaries are emitted as production topology
  Given a managed terrain edit has an active off-grid circle, diagonal corridor edge, non-grid-aligned rectangle, planar boundary, or breakline fully inside a safe regenerated area
  When terrain output regenerates through the production path
  Then the generated terrain contains vertices and edges that represent the active off-grid feature boundary
  And inserted off-grid vertices receive heights from the current composed terrain context
  And local face growth is attributable to selected cut or residual cells rather than broad influence windows

Scenario: Off-grid control points are emitted as production vertices
  Given an active terrain feature requires a control point whose XY position does not coincide with the base grid
  When terrain output regenerates through the production path
  Then the generated terrain includes a production vertex at that off-grid control point
  And the vertex height matches the current composed terrain context
  And neighboring unaffected cells retain the existing production output shape

Scenario: Composed feature boundaries produce correct terrain or safe fallback
  Given active off-grid feature boundaries intersect or overlap within the same output area
  When production output generation runs
  Then the resulting terrain either represents the composed boundaries without incorrect heights, topology gaps, or shape-specific patching
  Or the enhancement safely falls back before mutation while preserving valid terrain edit behavior and existing output integrity

Scenario: Later terrain edits are not blocked by stale derived output constraints
  Given prior off-grid feature-cut output was generated for a target, circle, rectangle, corridor, control point, or planar feature
  When a later valid terrain edit affects the same terrain area
  Then the later edit changes the generated surface according to the edited terrain state
  And stale derived output constraints from prior output generations do not continue to impose old heights or boundaries

Scenario: Obsolete current-feature cuts disappear from output
  Given previous active feature geometry created off-grid local cut topology
  And newer active feature state supersedes or occludes those requirements
  When terrain output regenerates from the current effective feature geometry
  Then obsolete cut topology is not emitted
  And only currently active topology-forcing constraints influence replacement cells

Scenario: Constrained cut-generation path is evidence based
  Given local and hosted validation covers off-grid simple cuts, off-grid control points, composed intersections, and later-edit interaction
  When the implementation plan is completed
  Then the plan defines a constrained cut-generation path for composed off-grid topology
  And existing CDT implementation is evaluated as prior art or reusable input rather than assumed to be drop-in production code
  And any adaptive rewrite use is limited to explicitly proven simple-case fast paths or safe fallback behavior
  And the plan includes explicit performance and fallback gates
```

## Non-Goals

- Treating generated mesh topology as authoritative terrain state.
- Persisting derived output cut vertices, cut cells, or feature-cut height anchors as authoritative
  terrain state or edit history.
- Adding user-facing backend selectors or public raw cut-graph diagnostics.
- Shipping experimental adaptive rewrite behavior without hosted evidence for off-grid simple cases,
  composed feature intersections, and later-edit interactions.
- Solving cross-seam synchronization, cross-patch component promotion, retained-neighbor seam
  validation, or patch-lifecycle hardening. `MTA-44B1` may define compatibility requirements and
  safe skip/fallback behavior for these cases, but `MTA-44C` owns implementation and hosted proof.
- Defining durable protected or locked terrain semantics beyond existing preserve-zone behavior.

## Business Constraints

- Off-grid target, corridor, circle, rectangle, planar, breakline, and control-point edits must read
  as real terrain geometry when they are within the supported production scope.
- Feature-cut precision must not make normal later terrain edits appear broken.
- Output enhancement may degrade safely, but it must not corrupt existing terrain or silently emit
  misleading geometry.
- Public MCP terrain contracts and existing workflows must remain stable unless a separate contract
  task is defined.
- The task must not repeat the MTA-44B failure mode of treating green local topology counters as
  proof of acceptable production terrain geometry.

## Technical Constraints

- Terrain state remains authoritative; generated terrain output and cut-generation metadata remain
  disposable derived geometry.
- Effective feature view may inform disposable output constraints, but stale derived output
  constraints must not accumulate as authoritative terrain state or durable edit history.
- Off-grid simple feature cuts, off-grid control points, and composed feature intersections must be
  validated separately.
- Fallback or skip behavior must occur before destructive output replacement.
- Existing CDT code may inform the implementation, but the task must validate whether it can be
  adapted to the production output lifecycle before relying on it.
- Constrained cut generation and heavy geometry/math collaborators must remain SketchUp-free and
  data-only so they can later be offloaded to a native binding without changing terrain semantics.
- Any constrained triangulation or hybrid path must preserve current no-delete mutation behavior and
  must safely skip/fallback when it reaches cross-seam or patch-lifecycle cases outside the
  `MTA-44B1` contained-output scope. Patch lifecycle synchronization, registry/readback hardening,
  save/reopen proof, and cross-patch hosted verification remain `MTA-44C` scope.

## Dependencies

- `MTA-44A`
- `MTA-31`
- `MTA-42`
- `MTA-43`
- [MTA-44B technical discovery notes](./technical-discovery-notes.md)
- [Superseded MTA-44 task](../MTA-44-add-sparse-local-detail-tiles-and-composed-height-oracle/task.md)

## Relationships

- replaces the blocked `MTA-44B` attempt while preserving its original business premise
- precedes `MTA-44C` by defining the contained/off-grid output model and the safe skip/fallback
  boundary for cross-seam and cross-patch cases
- informs constrained cut generation, CDT reuse/adaptation, hybrid output, and transient
  output-constraint planning

## Related Technical Plan

- none yet

## Success Metrics

- Off-grid circle, corridor, rectangle/planar, breakline, and control-point cases have production-visible topology evidence or documented safe fallback.
- Simple contained off-grid cases and composed/intersecting off-grid cases have separate passing or safe-fallback evidence.
- Later terrain edits visibly affect areas previously shaped by off-grid feature-cut output.
- Hosted validation records manifoldness, height correctness, visual boundary fidelity, fallback posture, and timing.
- The technical plan defines a constrained cut-generation path and records how existing CDT work is
  reused, adapted, or rejected with evidence.
- No public terrain command contract drift occurs.
