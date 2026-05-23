# Task: SEM-16 Realize Terrain-Sampled Planting Mass Proxy Representation
**Task ID**: `SEM-16`
**Title**: `Realize Terrain-Sampled Planting Mass Proxy Representation`
**Status**: `implemented`
**Priority**: `P1`
**Date**: `2026-05-22`

## Linked HLD

- [Semantic Scene Modeling](../../../hlds/hld-semantic-scene-modeling.md)

## Problem Statement

The sectioned `create_site_element` contract already accepts `planting_mass` requests with `representation.mode: "proxy_mass"`, and agents are using that shape for real site-design objects such as runoff-receiving planting pockets. The current builder output, however, treats the request as a simple push-pulled boundary polygon. For shallow planting features this produces a crude cube-like extrusion rather than a legible planting proxy.

That gap matters because `proxy_mass` is already part of the public representation vocabulary. If the output remains a blocky prism, agents have a valid semantic request that still creates a visually misleading scene object and pushes normal planting workflows back toward manual geometry cleanup or asset replacement before the design is ready for curated assets.

There is already a scratch SketchUp Ruby prototype in [`procedural_terrain_planting_mass.rb`](../../../../procedural_terrain_planting_mass.rb) that demonstrates the target behavior: parameterized public-meter inputs, terrain sampling, footprint underlay mesh, seeded point placement inside the footprint, edge fading, low-poly plant motif/component definitions, style and spacing controls, and JSON-safe result evidence. This task promotes the useful behavior from that experiment into the semantic runtime implementation without carrying over eval-style command shape, new public request fields, ad hoc metadata, entity-id-only targeting, or ad hoc raycast sampling.

This task makes `planting_mass + hosting.mode: "surface_drape" + representation.mode: "proxy_mass"` produce a terrain-sampled procedural planting proxy while preserving the existing semantic element type, metadata identity, and sectioned `create_site_element` request shape.

The task should also componentize the existing `tree_proxy` generated mesh as an internal implementation improvement, without changing its accepted SEM-04 visual baseline, public contract, terrain-anchored behavior, or serializer output. `tree_proxy` is already the acceptable proxy reference; componentization is valuable because it proves the reusable generated-proxy realization pattern that planting-mass motifs need.

## Goals

- make `planting_mass` requests using `representation.mode: "proxy_mass"` produce a terrain-sampled procedural planting mass instead of a plain extruded block
- realize `hosting.mode: "surface_drape"` as the primary correct hosting mode for terrain-dependent planting masses using the existing sectioned hosting contract
- preserve the existing `planting_mass` contract, including `definition.mode: "mass_polygon"`, `boundary`, `averageHeight`, optional `elevation`, optional `plantingCategory`, `representation.material`, and managed-object metadata
- adapt the scratch prototype's useful behavior into semantic-owned runtime code, including deterministic motif placement, terrain-aware elevation, low-poly planting components or baked geometry, and optional underlay representation
- reuse the existing optimized scene-query and semantic sampling seams for terrain resolution instead of reimplementing sampling inside the planting proxy generator
- route validation, refusals, metadata, and response evidence through existing semantic command plumbing
- componentize the current `tree_proxy` generated mesh without redesigning its silhouette or request contract, so generated semantic proxies share a practical component-definition/instance pattern
- keep the output lightweight, deterministic, and suitable for early design iteration rather than high-fidelity asset placement
- provide enough automated and SketchUp-hosted verification to prevent regression back to a single cube-like prism

## Acceptance Criteria

```gherkin
Scenario: planting_mass proxy_mass creates a terrain-sampled procedural proxy
  Given a valid `create_site_element` request uses `elementType: "planting_mass"`
  And the request uses `hosting.mode: "surface_drape"` with a resolvable terrain host
  And the request uses `representation.mode: "proxy_mass"`
  When the element is created
  Then the resulting Managed Scene Object reads as a planting mass rather than a single box-like extrusion
  And the output includes terrain-sampled placement or underlay geometry derived from the requested footprint
  And the output includes repeated low-poly planting motifs, components, or baked motif geometry distributed within the requested boundary
  And the proxy remains contained within or intentionally derived from the requested boundary and average height

Scenario: shallow planting pockets do not collapse into dumb cubes
  Given a `planting_mass` request describes a small runoff-receiving pocket with low `averageHeight`
  And the request uses `hosting.mode: "surface_drape"` with a resolvable terrain host
  And the request uses `representation.mode: "proxy_mass"`
  When the element is created
  Then the proxy is not represented only as one push-pulled polygonal prism
  And the result remains visually inspectable as a low planting feature at the requested site elevation

Scenario: prototype behavior is promoted without prototype command shape
  Given `procedural_terrain_planting_mass.rb` demonstrates terrain-sampled procedural planting output
  When the semantic runtime adopts the useful behavior
  Then callers still use `create_site_element` with the existing sectioned `planting_mass` contract
  And the implementation does not expose `generate_from_params`, eval-style entity ids, or the prototype's standalone metadata namespace as the public contract
  And source identity, placement, lifecycle, material, and status continue to use the existing semantic runtime conventions

Scenario: terrain sampling reuses optimized scene-query infrastructure
  Given scene-query surface sampling and profile generation already provide optimized target-bounded sampling behavior
  When `planting_mass + proxy_mass` needs terrain elevations or terrain-derived placement evidence
  Then the implementation reuses existing sampling seams such as `SampleSurfaceSupport`, `SampleSurfaceQuery`, `SampleSurfaceProfileGenerator`, `SurfaceHeightSampler`, or capability-local wrappers around those seams
  And the implementation does not use the scratch prototype's broad `Model#raytest` fallback as the production terrain sampling path
  And sample misses, invalid hosting targets, or excessive sample requests return existing-style structured refusals

Scenario: prototype controls become internal deterministic policy
  Given the prototype supports seed, spacing, count, style, edge fade, underlay, and component strategy controls
  When its behavior is adapted behind the existing `planting_mass + proxy_mass` contract
  Then those controls are not exposed as new public request fields by default
  And the implementation derives deterministic internal defaults from the existing request, model context, and semantic metadata
  And any later decision to expose a control requires an explicit contract update outside this task

Scenario: the existing planting_mass contract remains stable
  Given existing clients already send sectioned `planting_mass` requests
  When proxy-mass representation quality is improved
  Then the public element type remains `planting_mass`
  And the supported definition mode remains `mass_polygon`
  And the existing hosting section is used to express terrain drape behavior without adding a new public request section
  And the existing native schema and contract fixtures do not require new planting-mass request fields for this task
  And existing metadata, placement, lifecycle, material, and serializer result shapes remain JSON-serializable and compatible

Scenario: procedural proxy output remains lightweight and deterministic
  Given the task improves early-design proxy quality rather than asset fidelity
  When the same normalized planting-mass request is executed against the same model context
  Then the builder produces deterministic geometry suitable for tests and repeatable review
  And the output does not depend on staged assets, live asset search, randomness, or external services

Scenario: unsupported representation assumptions remain explicit
  Given `tree_proxy` already has its own accepted proxy baseline
  When this task is implemented
  Then tree proxy geometry is not visually redesigned by this task
  And componentizing `tree_proxy` preserves the accepted SEM-04 topology and scaling invariants
  And `tree_proxy + terrain_anchored` behavior from SEM-15 remains unchanged
  And `water_feature_proxy`, `seat`, `tree_instance`, or other next-wave semantic families are not promoted as part of this work

Scenario: tree_proxy componentization is an internal realization change
  Given the existing `tree_proxy` builder already creates an accepted connected volumetric proxy
  When the implementation componentizes that proxy
  Then callers still use the same `create_site_element` `tree_proxy` request shape
  And managed-object metadata, placement, lifecycle, and serialization remain compatible
  And builder tests continue to prove the same trunk, canopy, terrain-anchor, and deterministic scaling invariants
  And the componentized output does not introduce new tree-style or species-specific public controls
```

## Non-Goals

- redesigning the accepted `tree_proxy` visual baseline or tree proxy contract
- changing `tree_proxy` terrain anchoring semantics
- adding new semantic element types such as `water_feature_proxy`, `seat`, `tree_instance`, or `terrain_patch`
- replacing planting proxies with staged Asset Instances
- implementing `replace_with_staged_asset` or changing staged asset reuse policy
- adding species-specific planting design intelligence, recommendations, or high-fidelity botanical generation
- changing the public `create_site_element` sectioned request shape
- adding new public `planting_mass` controls for seed, spacing, count, style, edge fade, underlay, or component strategy
- promoting the scratch script's standalone method names, global module, metadata dictionary, or entity-id-only targeting as public API

## Business Constraints

- valid `planting_mass` proxy requests should produce useful early-design scene objects without requiring primitive fallback or manual cleanup
- `proxy_mass` must remain an early-design representation, not a substitute for curated assets or final planting documentation
- planting proxy improvements must preserve stable Managed Scene Object identity so later revision, replacement, or asset upgrade workflows can still target the same business object
- the task should address real agent usage of `representation.mode: "proxy_mass"` rather than inventing a new proxy family that existing clients do not call

## Technical Constraints

- Ruby remains the owner of semantic geometry, request interpretation, builder routing, and SketchUp API usage
- generated proxy component definitions, if used for `tree_proxy` or planting
  motifs, must be owned by the semantic runtime and scoped through existing
  command operation, lifecycle, placement, and metadata behavior
- `PlantingMassBuilder` or a capability-local collaborator should own planting-mass proxy geometry; command, transport, and serializer layers should not grow geometry logic
- the scratch script is reference/prototype evidence, not production architecture; implementation must align with existing semantic normalizer, validator, target resolver, metadata writer, and operation boundary behavior
- public inputs remain meter-valued at the MCP boundary and normalized to SketchUp internal units before builder execution
- outputs and refusals must remain JSON-serializable and must not expose raw SketchUp objects
- the task must preserve `sceneProperties`, `representation.material`, placement destination handling, metadata writes, and operation rollback behavior
- terrain lookup must reuse existing target resolution and optimized scene-query sampling/profile infrastructure rather than duplicating traversal, visibility, transform, ambiguity, or sampling-cap rules in the planting proxy generator
- existing request validation and semantic refusal helpers must remain the authority for supported `planting_mass` inputs; this task should not add builder-only parsing for hidden public fields
- response evidence and metadata must use existing semantic output, serializer, and managed-object plumbing; the proxy generator should return geometry/evidence data for those layers to normalize rather than defining a parallel response envelope
- automated tests must cover deterministic builder-level proxy invariants and regression away from one unarticulated extrusion; SketchUp-hosted or manual verification must cover terrain-sampled visual output against the prototype baseline

## Dependencies

- `SEM-02`
- `SEM-04`
- `SEM-08`
- `SEM-14`
- `SEM-15`
- [`procedural_terrain_planting_mass.rb`](../../../../procedural_terrain_planting_mass.rb)
- [`STI-02`](../../scene-targeting-and-interrogation/STI-02-explicit-surface-interrogation-via-sample-surface-z/task.md)

## Relationships

- informs `SAR-04` because better planting proxies provide a clearer lower-fidelity target for later staged-asset replacement
- complements `SEM-04` by preserving its accepted tree proxy geometry while changing internal realization
- preserves `SEM-15` terrain-anchored tree behavior while using tree proxy as the generated-component precedent for planting proxies

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- representative `planting_mass + surface_drape + proxy_mass` requests create a reviewed planting-like proxy rather than a single push-pulled polygonal prism
- representative `tree_proxy` requests produce the same accepted proxy shape after componentization, with no public contract or terrain-anchor drift
- the semantic runtime can reproduce the useful prototype behavior through `create_site_element`, including terrain-aware placement and seeded procedural motif distribution
- implementation uses existing scene-query/profile sampling and semantic command plumbing rather than productionizing the scratch script's ad hoc raycast, metadata, validation, output handling, or public parameter object
- the runoff-receiving planting pocket scenario can be created through `create_site_element` without primitive fallback and without producing a cube-like block
- automated tests fail if the builder regresses to one unarticulated extruded face for `proxy_mass`
- existing `planting_mass` contract tests and managed-object serialization behavior continue to pass unchanged
