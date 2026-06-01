# Size: MTA-44B Add Contained Production Feature Cut Graph Output

**Task ID**: MTA-44B  
**Title**: Add Contained Production Feature Cut Graph Output  
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
  - `systems:terrain-kernel`
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:surface-sampling`
  - `systems:validation-service`
- **Distinguishing Validation / Host Shape**:
  - `validation:hosted-smoke`
  - `validation:persistence`
  - `host:special-scene`
- **Likely Analog Class**: production topology slice constrained to seam-safe local terrain output

### Identity Notes
- Seeded from the revised MTA-44 split. This task must produce real output in the normal regenerate path while explicitly skipping seam-touching cases.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Suspicion-level only. Refresh this section before prediction if planning changes task shape.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds visible production local topology for contained feature cuts. |
| Technical Change Surface | 4 | Crosses feature geometry, cut-cell planning, mesh emission, validation, and readback evidence. |
| Hidden Complexity Suspicion | 4 | Cut topology, base-cell suppression, circular boundaries, and stale-cut removal can fail subtly. |
| Validation Burden Suspicion | 3 | Needs special hosted scenes and persistence evidence, but seam-crossing cases are deliberately skipped. |
| Dependency / Coordination Suspicion | 3 | Requires MTA-44A and depends on prior feature-aware adaptive and patch lifecycle behavior. |
| Scope Volatility Suspicion | 3 | Contained safety envelope may need tightening once exact cut-cell rules are planned. |
| Confidence | 2 | Production boundary is clear, but local triangulation and circular feature representation are unproven. |

### Early Signals
- Current feature view already provides active geometry, but circles are underrepresented as topology-forcing boundaries.
- Existing forced subdivision pressure is not equivalent to inserting exact off-grid cut vertices.
- The task avoids incorrect seams by skipping boundary-touching enhancement until MTA-44C.
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
- `systems:terrain-kernel`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:surface-sampling`
- `systems:validation-service`
- `validation:hosted-smoke`
- `validation:persistence`
- `host:special-scene`
- `contract:no-public-shape-change`
- `risk:partial-state`
- `friction:high`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
