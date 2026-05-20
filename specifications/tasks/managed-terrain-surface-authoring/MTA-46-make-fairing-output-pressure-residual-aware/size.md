# Size: MTA-46 Make Fairing Output Pressure Residual-Aware

**Task ID**: MTA-46  
**Title**: Make Fairing Output Pressure Residual-Aware  
**Status**: seeded  
**Created**: 2026-05-20  
**Last Updated**: 2026-05-20  

**Related Task**: [task.md](./task.md)  
**Related Plan**: none yet  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:performance-sensitive`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**: `systems:terrain-output`, `systems:terrain-kernel`,
  `systems:command-layer`, `systems:validation-service`
- **Distinguishing Validation / Host Shape**: `validation:hosted-matrix`,
  `validation:performance`, `host:special-scene`, `contract:no-public-shape-change`
- **Likely Analog Class**: feature-aware adaptive output pressure refinement after hosted topology
  observation

### Identity Notes

- The task refines internal fairing-derived output pressure, not public terrain edit contracts.
- The key differentiator is circular fairing pressure over low-error or planar output, discovered
  through MTA-45 hosted visual inspection.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Suspicion-level only. Refresh this section before prediction if planning changes task shape.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Behavior-visible output compaction refinement for fairing pressure, but no new public operation. |
| Technical Change Surface | 3 | Likely crosses feature-aware policy, adaptive output split decisions, replay evidence, and hosted validation. |
| Hidden Complexity Suspicion | 3 | Error-gated fairing pressure must avoid naive planar override and preserve real bumpy-terrain detail. |
| Validation Burden Suspicion | 3 | Needs focused policy/output tests plus hosted circular fairing-over-planar and bumpy fairing evidence. |
| Dependency / Coordination Suspicion | 2 | Depends on MTA-38/MTA-39/MTA-40/MTA-45 behavior and hosted SketchUp access. |
| Scope Volatility Suspicion | 2 | Boundary is clear, but planning may discover whether only fairing or broader soft pressure needs treatment. |
| Confidence | 2 | The defect is well observed, but the safe residual-aware rule needs planning and proof. |

### Early Signals

- MTA-45 live inspection showed clean planar compaction after the planar edit, but dense output after
  later circular fairing over the same low-error area.
- Replay evidence showed `densityHitCount` returning on survey/fairing rows while planar quality
  remained within tolerance.
- The current policy treats `fairing_support` as unconditional soft density pressure with
  `targetCellSize=4`; this is likely over-broad for low-error cells.
- Circular fairing must stay in scope because the observed broad fairing region is circular, not a
  rectangular proxy authored by the user.
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

- `archetype:performance-sensitive`
- `scope:managed-terrain`
- `systems:terrain-output`
- `systems:terrain-kernel`
- `systems:command-layer`
- `systems:validation-service`
- `validation:hosted-matrix`
- `validation:performance`
- `host:special-scene`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `volatility:medium`
- `friction:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
