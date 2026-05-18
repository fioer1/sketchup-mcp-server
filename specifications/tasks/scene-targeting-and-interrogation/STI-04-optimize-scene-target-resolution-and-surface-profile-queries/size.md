# Size: STI-04 Optimize Scene Target Resolution and Surface Profile Queries

**Task ID**: STI-04  
**Title**: Optimize Scene Target Resolution and Surface Profile Queries  
**Status**: calibrated  
**Created**: 2026-05-18  
**Last Updated**: 2026-05-18  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:performance-sensitive`
- **Primary Scope Area**: `scope:scene-targeting-interrogation`
- **Likely Systems Touched**:
  - `systems:target-resolution`
  - `systems:scene-query`
  - `systems:serialization`
  - `systems:surface-sampling`
  - `systems:validation-service`
- **Distinguishing Validation / Host Shape**: `validation:performance`, `host:routine-smoke`, `contract:no-public-shape-change`
- **Likely Analog Class**: shared scene-query performance hardening

### Identity Notes
- Plan-only evidence frames this as an internal optimization across existing targeting consumers, not a public contract expansion.
- The dominant risk is preserving recursive/nested ambiguity semantics while replacing serialization-heavy filtering.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Suspicion-level only. Refresh this section before prediction if planning changes task shape.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Moderate behavior hardening across existing lookup and sampling flows; no new public tool behavior. |
| Technical Change Surface | 3 | Plan touches query filtering, serializer readers, adapter traversal, target references, validation selectors, and sample-surface command flow. |
| Hidden Complexity Suspicion | 3 | Nested groups/components, lower-level sourceElementId storage, duplicate ambiguity, and profile path entries can hide regressions. |
| Validation Burden Suspicion | 2 | Normal repo closeout plus representative hosted/performance smoke is expected. |
| Dependency / Coordination Suspicion | 1 | Work is mostly self-contained inside existing scene-query seams. |
| Scope Volatility Suspicion | 1 | Plan has clear non-goals and no public contract change. |
| Confidence | 3 | Plan is bounded and has concrete acceptance criteria, but host-scale performance remains a required proof point. |

### Early Signals
- The task explicitly preserves public MCP contracts and existing resolution states.
- The plan calls out a known correctness trap: a single container sourceElementId match can hide a lower-level duplicate.
- `sample_surface_z` optimization is bounded to removing unused traversal while preserving path entries for transforms.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Improves existing lookup/profile behavior across several tools without adding new public modes or schemas. |
| Technical Change Surface | 3 | Layered internal change across `TargetingQuery`, serializer readers, adapter traversal, target-reference resolution, validation, and sample-surface command wiring. |
| Implementation Friction Risk | 2 | Main friction is preserving ambiguity and nested traversal semantics while changing filtering internals. |
| Validation Burden Risk | 2 | Requires focused tests, full Ruby suite, lint, review, and routine hosted/performance smoke; this is repo-baseline for runtime behavior. |
| Dependency / Coordination Risk | 1 | Existing seams are available; no external sequencing or public migration is planned. |
| Discovery / Ambiguity Risk | 2 | Plan already identifies performance root cause, but nested component and duplicate-ID semantics need careful proof. |
| Scope Volatility Risk | 1 | Non-goals are tight: no public contract changes, no cache/index, no new query operators. |
| Rework Risk | 2 | A too-aggressive fast path or missed sample-surface path dependency could force localized correction. |
| Confidence | 3 | Plan is specific and bounded; confidence depends on proving representative hosted performance and no ambiguity regression. |

### Analog Brief
- `STI-03` is a nearby surface-sampling analog but larger: it changed public request shape and hosted geometry behavior, so it overstates public-contract and validation risk for STI-04.
- `SVR-03` is a useful target-resolution/measurement analog, but it introduced a new public MCP tool; STI-04 is lower functional scope because it changes internal resolution behavior only.
- `STI-02` is a geometry-heavy explicit sampling analog; STI-04 reuses that surface and should not inherit first-generation geometry-tool friction unless path-entry handling regresses.

### Top Assumptions
- Existing serializer semantics are accurate enough to expose equivalent field readers.
- `sourceElementId` exact matching can be optimized without changing `none`, `unique`, or `ambiguous` resolution behavior.
- `sample_surface_z` always receives path-aware entries through the command path when nested transforms matter.
- Representative hosted smoke is available to verify large-scene performance and direct-reference consumers.

### Estimate Breakers
- If preserving duplicate ambiguity requires a more complex path-aware index, technical surface and friction rise.
- If component-definition traversal differs between container pre-scan and full recursion, hosted validation could expose hidden correctness work.
- If validation must prove many scene shapes beyond routine smoke, validation burden rises above baseline.
- If public response shapes or tool schemas need adjustment to expose optimization evidence, the task becomes a contract change.

### Predicted Notes
- Plan-only estimate lands as moderate functional scope with high-ish technical surface: the behavior is not broad, but it crosses shared runtime seams.
- Validation stays at `2` because the plan requires normal full-suite/review/hosted performance closeout, not a special matrix or repeated fix loop.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

### Confirmed Drivers
- Not filled yet.

### Contested Drivers / Missing Evidence
- Not filled yet.

### Score Changes
- None.

### Recommendation
- Not filled yet.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

> Append only. Log material estimate drift, not routine TDD/review/live-check correction.

| Date | Checkpoint | Event Type | Severity (1-3) | Dimension Affected | Predictable Earlier? | Notes |
|---|---|---|---:|---|---|---|

### Drift Notes
- No material drift recorded yet.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Shipped internal performance and correctness hardening across existing query consumers without new public behavior. |
| Technical Change Surface | 3 | Touched shared targeting, serializer readers, adapter traversal, target-reference resolution, validation selectors, and sample-surface command wiring. |
| Actual Implementation Friction | 2 | Main resistance was preserving duplicate ambiguity and nested/lower-level lookup semantics while changing scan internals. |
| Actual Validation Burden | 2 | Full suite, lint, external review, and routine live SketchUp/performance smoke are baseline closeout for this runtime change. |
| Actual Dependency Drag | 1 | Existing scene-query and sample-surface seams were available; no external sequencing blocker occurred. |
| Actual Discovery Encountered | 2 | Review exposed a concrete ambiguity trap in the first sourceElementId fast path, but it was localized and anticipated by the plan risks. |
| Actual Scope Volatility | 0 | Task boundary did not change; no public contract, cache, indexing, or new query operators were added. |
| Actual Rework | 2 | Localized refactor corrected the sourceElementId fast path after review so lower-level duplicates remain visible. |
| Final Confidence in Completeness | 4 | Automated, external review, and requested live SketchUp evidence are complete; remaining path-aware resolver work is explicitly out of scope. |

### Inflation Check
- **Validation exceeded baseline?** No. External review, full Ruby validation, lint, and routine live SketchUp smoke are expected closeout for this runtime surface.
- **Meaningful rework beyond normal correction?** Yes, but localized. The sourceElementId fast path was refactored after review to preserve duplicate ambiguity.
- **Task boundary changed?** No. The work stayed within internal target-resolution and sample-profile performance hardening.
- **Any `4` justified by domination/repeated blockers/revert/redesign?** Not applicable; no dimension is scored `4`.
- **Unrun required evidence reflected in confidence?** Not applicable. The requested live SketchUp checks ran; no persistent hosted performance harness was required for this task.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

- **Classification**: baseline closeout with localized review follow-up
- **Distinguishing Evidence**:
  - Full Ruby suite passed with `533 runs, 1985 assertions, 0 failures, 0 errors, 2 skips`.
  - RuboCop passed on touched Ruby source and test files.
  - Grok 4.3 codereview identified the single-container ambiguity risk; the sourceElementId path was refactored and revalidated.
  - Live SketchUp smoke covered sourceElementId, entityId, persistentId, attribute lookup, `get_entity_info`, missing-target `measure_scene`, and `sample_surface_z` profile behavior.
  - Representative live sourceElementId timings stayed under one second after the conservative refactor.
- **Gaps**: none for the requested closeout. Further path-aware profile optimization is a future out-of-scope improvement.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

- **Most Underestimated**: Rework risk was directionally right but the specific ambiguity correction was more concrete than the plan-only estimate could prove.
- **Most Overestimated**: None materially. Validation, friction, and technical surface landed close to prediction.
- **Future Similar Tasks Should Assume**: Shared scene-query performance changes need explicit duplicate/ambiguity regression tests, not only timing checks.
### Delta Notes
- The plan's estimate breakers were well aligned: preserving old resolution semantics was the real risk, while public contract and dependency risks stayed low.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:performance-sensitive`
- `scope:scene-targeting-interrogation`
- `systems:target-resolution`
- `systems:scene-query`
- `systems:serialization`
- `systems:surface-sampling`
- `validation:performance`
- `host:routine-smoke`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `risk:regression-breadth`
- `volatility:low`
- `friction:medium`
- `rework:medium`
- `confidence:high`
<!-- SIZE:TAGS:END -->
