# Size: MTA-44C Harden Feature Cuts Across Seams And Patch Lifecycle

**Task ID**: MTA-44C  
**Title**: Harden Feature Cuts Across Seams And Patch Lifecycle  
**Status**: seeded  
**Created**: 2026-05-28  
**Last Updated**: 2026-05-28  

**Related Task**: [task.md](./task.md)  
**Related Plan**: none yet  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:feature`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:terrain-state`
  - `systems:managed-object-metadata`
  - `systems:validation-service`
- **Distinguishing Validation / Host Shape**:
  - `validation:hosted-matrix`
  - `validation:performance`
  - `validation:persistence`
  - `host:save-reopen`
- **Likely Analog Class**: seam-sensitive patch lifecycle expansion for production terrain topology

### Identity Notes
- Seeded from the MTA-44 split. This task carries the hardest retained-boundary, seam, promotion, and no-delete risks after contained feature cuts exist.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Suspicion-level only. Refresh this section before prediction if planning changes task shape.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 4 | Expands production feature cuts from contained cases to real cross-patch terrain edits. |
| Technical Change Surface | 4 | Touches seams, component planning, patch replacement, retained boundaries, output validation, and hosted evidence. |
| Hidden Complexity Suspicion | 4 | Deterministic seam chains and retained-neighbor compatibility are likely failure points. |
| Validation Burden Suspicion | 4 | Requires hosted matrix, seam validation, performance, persistence, fallback, and no-delete evidence. |
| Dependency / Coordination Suspicion | 4 | Depends materially on MTA-44A, MTA-44B, MTA-42, MTA-43, and patch lifecycle behavior. |
| Scope Volatility Suspicion | 3 | Seam and component policy may force split or fallback limits during planning. |
| Confidence | 1 | Direction is clear, but the exact seam/component mechanics remain the main unknown. |

### Early Signals
- Current component planner explicitly rejects non-empty local-detail boundary sources.
- MTA-42 and MTA-43 are direct dependencies, and retained-Z/retained-seam gaps remain known risk areas.
- Failure mode is silent wrong terrain, not merely a public refusal.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

Not filled yet.
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

Not filled yet.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

Not filled yet.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

Not filled yet.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:managed-terrain`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:terrain-state`
- `systems:managed-object-metadata`
- `systems:validation-service`
- `validation:hosted-matrix`
- `validation:performance`
- `validation:persistence`
- `host:save-reopen`
- `contract:no-public-shape-change`
- `risk:partial-state`
- `confidence:low`
<!-- SIZE:TAGS:END -->
