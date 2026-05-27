# Task: SEM-17 Realize Terrain-Clamped Linear Edge Semantics
**Task ID**: `SEM-17`
**Title**: `Realize Terrain-Clamped Linear Edge Semantics`
**Status**: `completed`
**Priority**: `P1`
**Date**: `2026-05-23`

## Linked HLD

- [Semantic Scene Modeling](../../../hlds/hld-semantic-scene-modeling.md)

## Problem Statement

The public semantic creation contract advertises `retaining_edge` with `hosting.mode: "edge_clamp"`, and the runtime accepts and routes that request shape. The current builder behavior, however, still creates retaining-edge geometry at `definition.elevation` or `z = 0` instead of resolving the requested terrain host. That makes the contract misleading for terrain-aware path and edging workflows: a request can appear valid, produce a managed object with metadata, material, and tag, and still fail the core spatial expectation that the edge follows the target terrain.

The same client pressure also exposes a vocabulary gap. Stone, setts, curb, or restraint edges used to hold a path or hardscape surface edge are not always retaining walls and are not paths themselves. Forcing those objects into either `path` or `retaining_edge` loses semantic intent even when the underlying geometry uses the same linear, terrain-following hardscape realization.

This task makes the advertised `retaining_edge + edge_clamp` behavior materially true and introduces one canonical `edge_restraint` semantic type backed by the same terrain-clamped linear edge realization. It keeps the work inside `create_site_element`, preserves Managed Scene Object identity, and pairs creation behavior with usable `surfaceOffset` validation guidance so clients can catch z=0 or off-terrain regressions after creation.

## Goals

- make `retaining_edge + hosting.mode: "edge_clamp"` create terrain-clamped linear edge geometry instead of silently falling back to planar z=0 output
- add canonical `edge_restraint` as a semantic type for curbs, setts, and stone restraint edges along path or hardscape surface edges without adding multiple public aliases
- support terrain-aware linear edge dimensions through existing linear-edge vocabulary: `polyline`, `height`, and `thickness` for `edge_restraint`, while preserving optional `elevation` only for compatible unhosted planar `retaining_edge` behavior
- reuse the existing semantic terrain sampling, hosting resolution, refusal, metadata, validation, and schema conventions rather than adding a separate edge creation tool
- document and test `validate_scene_update` `surfaceOffset` usage for semantic linear edges so clients can verify that created edges are actually near the intended terrain

## Acceptance Criteria

```gherkin
Scenario: retaining_edge edge_clamp follows the targeted terrain
  Given a sampleable terrain or surface target is available
  And a valid `create_site_element` request uses `elementType: "retaining_edge"`
  And the request uses `hosting.mode: "edge_clamp"` with a resolvable host target
  When the element is created
  Then the resulting managed retaining edge varies in elevation in response to the targeted surface
  And the created edge is not emitted entirely at `z = 0` unless the sampled target surface is also at `z = 0`
  And the created edge remains a separate Managed Scene Object rather than mutating or becoming part of terrain source state

Scenario: edge_clamp refuses instead of degrading to planar output
  Given a `retaining_edge` request uses `hosting.mode: "edge_clamp"`
  When the host target cannot be resolved, exposes no sampleable surface geometry, or required samples miss the target surface
  Then `create_site_element` returns a structured refusal
  And the runtime does not create a planar fallback edge at `z = 0`
  And the refusal remains JSON-serializable and does not expose raw SketchUp objects

Scenario: edge_restraint is accepted as the canonical curb and restraint semantic type
  Given a valid `create_site_element` request uses `elementType: "edge_restraint"`
  And the request supplies a linear definition for a curb, sett, or stone restraint edge along a path or hardscape surface edge
  And the request uses terrain-aware hosting against a resolvable surface target
  When the element is created
  Then the resulting Managed Scene Object uses semantic type `edge_restraint`
  And its realized geometry is terrain-clamped using the same linear edge behavior as hosted retaining edges
  And the public contract does not also require or advertise separate `curb`, `retaining_curb`, or `path_edge` element-type aliases

Scenario: edge_restraint dimensions are semantically explicit
  Given an `edge_restraint` request includes `definition.mode: "polyline"`, `definition.polyline`, `definition.height`, `definition.thickness`, material, hosting, placement, representation, and lifecycle sections as applicable
  When the request is validated and normalized
  Then public length values are interpreted through the existing meter-to-internal-unit boundary
  And unsupported, missing, or non-positive dimensions are refused with field-specific details
  And `definition.elevation` is not accepted for `edge_restraint` because hosted `edge_clamp` sampling owns the terrain-relative base elevation
  And new public dimension aliases or offset fields are not required to express the restraint edge
  And successful builder-facing inputs remain JSON-safe and do not expose raw SketchUp objects across public boundaries

Scenario: public schemas and docs match live edge behavior
  Given `create_site_element` is inspected through runtime schema, contract fixtures, tests, and user-facing documentation
  When linear edge semantics are reviewed
  Then `retaining_edge -> edge_clamp` is documented as terrain-clamped behavior rather than planar edge output
  And `edge_restraint` appears as the canonical semantic type for curb or sett restraint edges
  And the documented request examples use the same fields and hosting modes accepted by the runtime

Scenario: surfaceOffset validation can catch off-terrain semantic edges
  Given a semantic `retaining_edge` or `edge_restraint` has been created against a terrain host
  And `validate_scene_update` is called with `geometryRequirements.kind: "surfaceOffset"` against that edge and the same surface reference
  When the created edge is near the expected terrain-relative offset
  Then validation passes for the configured anchors and tolerance
  And when the edge is incorrectly emitted at `z = 0` against nonzero terrain
  Then validation fails with `surfaceOffset` failed-anchor evidence rather than only confirming existence, material, or tag

Scenario: path and terrain authoring semantics remain separate
  Given existing clients use `path + surface_drape` for terrain-following path surfaces
  When hosted linear edge semantics are implemented
  Then path creation behavior, path metadata, and path validation remain compatible
  And the task does not mutate terrain heightmap state or absorb hardscape objects into managed terrain source state
  And terrain authoring tools may still reference semantic hardscape explicitly without this task making them part of terrain state
```

## Non-Goals

- adding separate public aliases such as `curb`, `retaining_curb`, `sett_edge`, or `path_edge`
- adding new public linear-edge dimension fields such as `topOffset`, `embedDepth`, or a `width` alias in this task
- creating a new public MCP tool outside `create_site_element`
- implementing cross-band, check-band, or threshold-strip semantic types
- changing `path + surface_drape` behavior except where shared tests prove it remains compatible
- mutating, cutting, grading, or otherwise modifying the target terrain surface
- adding topology-aware edge-network validation or true polyline-derived validation anchors beyond the existing `surfaceOffset` validation posture
- changing staged asset, material library, or asset replacement workflows

## Business Constraints

- valid hosted edge requests must produce spatially trustworthy managed hardscape objects without requiring fallback Ruby or primitive construction
- `edge_restraint` must improve semantic clarity for curb, sett, and restraint-edge workflows without fragmenting the public vocabulary into synonyms
- created edges must remain Managed Scene Objects with stable identity, status, material, placement, and lifecycle behavior for later validation and revision
- validation guidance must support practical client acceptance checks that catch the known z=0 failure mode after creation

## Technical Constraints

- Ruby remains the owner of semantic request validation, hosting interpretation, terrain sampling consumption, geometry construction, metadata, and SketchUp API usage
- public MCP contract changes must update runtime schema, validator, normalizer, builder registry, dispatcher coverage, tests, and user-facing docs in the same change
- public length inputs must continue to be meter-valued at the MCP boundary and normalized to SketchUp internal units before builder execution
- `edge_restraint` must not accept `definition.elevation` in this task; hosted terrain sampling determines its base elevation
- hosted linear edge creation must reuse existing target resolution and surface sampling seams such as `SurfaceHeightSampler` or capability-local wrappers around the existing scene-query sampling infrastructure
- successful and refused flows must remain undo-safe and JSON-serializable
- `retaining_edge`, `edge_restraint`, `path`, and terrain authoring state must remain separate semantic or terrain objects; hardscape creation must not silently rewrite terrain source state
- `validate_scene_update` `surfaceOffset` may be used for acceptance checks, but this task must not overclaim it as exact edge-topology validation unless stronger anchor derivation is explicitly added and tested

## Dependencies

- `SEM-08`
- `SEM-13`
- [`SVR-02`](../../scene-validation-and-review/SVR-02-broaden-validate-scene-update-with-surface-relationship-and-reference-point-validation/task.md)
- [`STI-02`](../../scene-targeting-and-interrogation/STI-02-explicit-surface-interrogation-via-sample-surface-z/task.md)
- [Semantic Scene Modeling HLD](../../../hlds/hld-semantic-scene-modeling.md)
- [Managed Terrain Surface Authoring HLD](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Relationships

- complements `SEM-13` by applying terrain-following linear hardscape behavior to semantic edges rather than path surfaces
- uses `SVR-02` surface-offset validation as the existing post-create acceptance mechanism for terrain-relative edge placement
- informs future semantic band or threshold-strip work without implementing that vocabulary in this task

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- representative `retaining_edge + edge_clamp` requests no longer create planar z=0 geometry against nonzero terrain targets
- representative `edge_restraint` requests create managed, terrain-clamped linear hardscape objects through `create_site_element` without requiring fallback primitives
- hosted edge sample misses and invalid hosts return structured refusals instead of silent planar degradation
- runtime schema, contract fixtures, docs, and semantic tests agree on the canonical `edge_restraint` type and supported hosted edge behavior
- `validate_scene_update` `surfaceOffset` examples or tests demonstrate failure for an edge emitted at z=0 against a nonzero surface target
