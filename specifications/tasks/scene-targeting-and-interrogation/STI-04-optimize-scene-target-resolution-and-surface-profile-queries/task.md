# Task: STI-04 Optimize Scene Target Resolution and Surface Profile Queries
**Task ID**: `STI-04`
**Title**: `Optimize Scene Target Resolution and Surface Profile Queries`
**Status**: `completed`
**Priority**: `P0`
**Date**: `2026-05-18`

## Linked HLD

- [Scene Targeting and Interrogation](../../../hlds/hld-scene-targeting-and-interrogation.md)

## Problem Statement

Representative scene targeting calls against large SketchUp scenes were taking several seconds even for exact `sourceElementId` lookups. The slow path came from scanning hundreds of thousands of recursive entities and serializing full target summaries for every candidate before filtering. The same cost also affected direct target-reference users such as `get_entity_info`, `measure_scene`, validation target selectors, and `sample_surface_z` profile requests.

This task hardens the shared scene-query path so common target-resolution flows remain correct and responsive without changing public MCP tool contracts.

## Goals

- reduce exact `sourceElementId` lookup latency for representative large scenes
- reuse one optimized targeting implementation across `find_entities`, direct target references, validation selectors, and sample-surface target resolution
- preserve nested group/component traversal and lower-level entity lookup semantics
- preserve ambiguity behavior when duplicate identifiers exist across containers and lower-level entities
- keep `sample_surface_z` profile sampling explicit-host, read-only, and significantly cheaper for repeated profile evidence

## Acceptance Criteria

```gherkin
Scenario: exact sourceElementId targeting avoids full match serialization
  Given a large SketchUp scene with managed entities
  When a caller resolves entities by only sourceElementId
  Then filtering uses lightweight field readers instead of serializing every candidate match
  And only final public matches are serialized for the response

Scenario: nested and lower-level sourceElementId lookup remains correct
  Given a sourceElementId is stored on a lower-level entity rather than a group or component
  When find_entities resolves that sourceElementId
  Then the lower-level entity can still be found
  And the response preserves the expected unique or ambiguous resolution state

Scenario: duplicate identifiers preserve ambiguity semantics
  Given a container entity and a lower-level entity share the same sourceElementId
  When a sourceElementId-only query is evaluated
  Then the response is ambiguous
  And the fast path does not hide the lower-level duplicate

Scenario: direct target-reference tools reuse optimized lookup
  Given a caller uses a sourceElementId targetReference through get_entity_info, measure_scene, or validation
  When the target reference is resolved
  Then the same optimized targeting field readers are used
  And public tool response shapes remain unchanged

Scenario: sample_surface_z profile avoids unused traversal work
  Given sample_surface_z receives recursive entity path entries for target resolution
  When a profile or point sampling request is executed
  Then the command does not also collect an unused recursive entity list
  And nested target transforms remain correct through entity path entries
```

## Non-Goals

- changing public MCP tool names, request schemas, or response shapes
- introducing cached model-wide indexes that survive across tool calls
- replacing SketchUp-owned entity traversal with a separate scene database
- changing sampling semantics, visibility policy, or terrain interpretation behavior
- adding ranking, fuzzy matching, or collection-aware targeting beyond the existing exact-match contract

## Business Constraints

- targeting and interrogation must remain reliable enough for downstream modeling, asset reuse, validation, and review workflows
- workflows should not need arbitrary Ruby just to compensate for slow or ambiguous target resolution
- optimizations must not trade correctness for speed in representative production scenes

## Technical Constraints

- Ruby remains the owner of target resolution, filtering, serialization, and SketchUp API access
- outputs must remain JSON-serializable and compatible with existing MCP clients
- `sourceElementId` remains the preferred workflow identity, with `persistentId` and `entityId` as supported alternatives
- nested group and component definitions must remain searchable where existing recursive traversal supported them
- `sample_surface_z` must preserve ancestor path information for nested transforms

## Dependencies

- `STI-01`
- `STI-02`
- `STI-03`
- [Scene Targeting and Interrogation HLD](../../../hlds/hld-scene-targeting-and-interrogation.md)
- [PRD: Scene Targeting and Interrogation](../../../prds/prd-scene-targeting-and-interrogation.md)

## Relationships

- hardens the `find_entities` MVP from `STI-01`
- hardens explicit host resolution used by `sample_surface_z` from `STI-02`
- improves profile sampling performance introduced by `STI-03`
- informs validation and measurement tools that consume shared target-reference resolution

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- representative `find_entities` sourceElementId lookups avoid the previous multi-second full-serialization path
- missing sourceElementId lookups complete through a lightweight exhaustive scan rather than a serialization-heavy scan
- direct target-reference tools and validation selectors share the optimized query path
- `sample_surface_z` profile requests avoid redundant recursive entity enumeration
- automated tests cover nested lookup, duplicate ambiguity, reused resolver behavior, and sample-surface resolution behavior
