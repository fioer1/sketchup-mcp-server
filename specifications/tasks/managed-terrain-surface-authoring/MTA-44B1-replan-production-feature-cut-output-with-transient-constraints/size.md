# Size: MTA-44B1 Deliver Production Off-Grid Feature Cut Output

**Task ID**: MTA-44B1  
**Title**: Deliver Production Off-Grid Feature Cut Output  
**Status**: seeded  
**Created**: 2026-06-03  
**Last Updated**: 2026-06-03  

**Related Task**: [task.md](./task.md)  
**Related Plan**: none yet  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:feature`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-kernel`
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:terrain-state`
  - `systems:public-contract`
- **Distinguishing Validation / Host Shape**:
  - `validation:hosted-matrix`
  - `validation:performance`
  - `host:special-scene`
- **Likely Analog Class**: constrained feature-boundary cut islands inside adaptive terrain output

### Identity Notes
- Seeded from the defined `MTA-44B1` task, technical discovery notes, failed `MTA-44B` calibration,
  and CDT prior-art tasks.
- This is not global CDT enablement; the estimation shape is contained/off-grid feature-boundary cut
  generation with explicit 44C boundary management.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Suspicion-level only. Refresh this section before prediction if planning changes task shape.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds production-visible off-grid topology for multiple supported feature types while public contracts stay stable. |
| Technical Change Surface | 4 | Likely spans effective feature geometry, transient output constraints, cut graph/triangulation, height ownership, adaptive output, and mesh emission. |
| Hidden Complexity Suspicion | 4 | Prior 44B failed on composed topology, height semantics, shape-specific drift, and stale derived constraints. |
| Validation Burden Suspicion | 4 | Needs special hosted visual/topology/height proof, composed cases, later-edit interaction, safe fallback/no-delete evidence, and timing. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-44A, existing effective feature/oracle behavior, adaptive output internals, CDT prior art, and the MTA-44C boundary. |
| Scope Volatility Suspicion | 3 | Scope is intentionally bounded to contained cut islands, but implementation may pressure CDT reuse, adaptive fallback, or 44C seam work. |
| Confidence | 2 | Business goal and failure lessons are clear; implementation architecture is not planned yet. |

### Early Signals
- MTA-44B is the closest negative analog: local counters and manifoldness did not prove product-correct terrain topology.
- Existing CDT code is prior art only; direct reuse risks importing patch/global CDT and residual-reconstruction assumptions.
- The task must keep cross-seam, cross-patch, registry/readback, and save/reopen hardening out of 44B1 and defer that proof to MTA-44C.
- The new plan must choose a constrained cut-generation path before any credible predicted estimate.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | <0-4> | <short note> |
| Technical Change Surface | <0-4> | <short note> |
| Implementation Friction Risk | <0-4> | <short note> |
| Validation Burden Risk | <0-4> | <short note; repo baseline closeout is usually 2> |
| Dependency / Coordination Risk | <0-4> | <short note> |
| Discovery / Ambiguity Risk | <0-4> | <short note> |
| Scope Volatility Risk | <0-4> | <short note> |
| Rework Risk | <0-4> | <short note> |
| Confidence | <0-4> | <short note> |

### Analog Brief
- Not filled yet.

### Top Assumptions
- Not filled yet.

### Estimate Breakers
- Not filled yet.

### Predicted Notes
- Not filled yet.
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
| Functional Scope | <0-4> | <short note> |
| Technical Change Surface | <0-4> | <short note> |
| Actual Implementation Friction | <0-4> | <short note> |
| Actual Validation Burden | <0-4> | <short note; score only extra burden beyond repo baseline> |
| Actual Dependency Drag | <0-4> | <short note> |
| Actual Discovery Encountered | <0-4> | <short note> |
| Actual Scope Volatility | <0-4> | <short note; returning to plan is not volatility> |
| Actual Rework | <0-4> | <short note; normal correction is not high rework> |
| Final Confidence in Completeness | <0-4> | <short note> |

### Inflation Check
- **Validation exceeded baseline?** <yes/no + why>
- **Meaningful rework beyond normal correction?** <yes/no + why>
- **Task boundary changed?** <yes/no + why>
- **Any `4` justified by domination/repeated blockers/revert/redesign?** <yes/no/not applicable>
- **Unrun required evidence reflected in confidence?** <yes/no/not applicable>
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

- **Classification**: <baseline closeout | quick contained retest | one material blocker | expanded matrix/special setup | repeated blockers/heavy investigation/revert>
- **Distinguishing Evidence**:
  - <only evidence that changes the estimate; do not paste full logs>
- **Gaps**: <none or confidence-relevant gaps>
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

- **Most Underestimated**: <dimension + reusable reason>
- **Most Overestimated**: <dimension + reusable reason>
- **Future Similar Tasks Should Assume**: <short lesson>
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:managed-terrain`
- `systems:terrain-kernel`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:terrain-state`
- `systems:public-contract`
- `validation:hosted-matrix`
- `validation:performance`
- `host:special-scene`
- `contract:no-public-shape-change`
- `risk:partial-state`
- `risk:performance-scaling`
- `friction:high`
- `volatility:medium`
<!-- SIZE:TAGS:END -->
