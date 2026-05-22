# Size: MTA-46 Make Fairing Output Pressure Residual-Aware

**Task ID**: MTA-46  
**Title**: Make Fairing Output Pressure Residual-Aware  
**Status**: challenged
**Created**: 2026-05-20  
**Last Updated**: 2026-05-20  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)
**Related Summary**: [summary.md](./summary.md)

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
| Functional Scope | 2 | Behavior-visible output compaction refinement in an existing fairing workflow; no new public operation. |
| Technical Change Surface | 3 | Crosses feature-aware policy, adaptive split planning, internal evidence/replay, and hosted validation surfaces. |
| Implementation Friction Risk | 3 | Must gate fairing before subdivision while preserving bumpy detail, shared soft pressure behavior, forced masks, and circular intent. |
| Validation Burden Risk | 3 | Requires special two-sided fixture/hosted proof, topology compactness checks, bumpy preservation, and repeated timing bands beyond routine closeout. |
| Dependency / Coordination Risk | 2 | Depends on implemented MTA-38/MTA-39/MTA-40/MTA-45 behavior and hosted SketchUp access. |
| Discovery / Ambiguity Risk | 2 | Main rule is settled, but exact internal API shape, fixture sufficiency, and bounds-overstatement evidence remain tactical unknowns. |
| Scope Volatility Risk | 1 | Scope is deliberately narrowed to `fairing_support`; shared soft pressure is gated by regression coverage rather than accepted expansion. |
| Rework Risk | 2 | Hosted topology/performance may require one localized correction, following MTA-45/MTA-40 lessons, but plan has explicit falsification gates. |
| Confidence | 3 | Strong planning evidence and analogs; final confidence depends on implementation and hosted proof. |

### Analog Brief

- Closest analog: MTA-45. It looked like a planar policy/output compaction task, but hosted output
  exposed additional topology behavior; expect at least one validation-driven correction path.
- MTA-39 supports the policy/evidence shape: allocation, quality, timing, and face-count signals
  must stay separate.
- MTA-40 supports preserving forced subdivision independently from density/residual gates.
- MTA-38 supports the hosted replay evidence pattern and repeated timing-band expectation.

### Top Assumptions

- `FeatureAwareAdaptivePolicy` can expose fairing-only pressure classification without changing
  public command output.
- `TerrainOutputPlan` can reuse existing residual probes before density subdivision without a new
  residual cache.
- Existing or small new replay fixtures can isolate low-error fairing-over-planar and bumpy circular
  fairing cases.
- Hosted SketchUp validation access remains available for final topology and timing proof.

### Estimate Breakers

- `fairing_support` classification cannot be threaded without broad policy or output-plan redesign.
- Circular bounds overstatement proves material enough that exact circle handling is needed inside
  MTA-46.
- Bumpy fairing detail is lost under the residual gate and requires a different rule than planned.
- Hosted timing shows repeated unacceptable regression from residual probing.

### Predicted Notes

- Treat this as a medium-large internal output-policy task, not a small density-threshold tweak.
- Validation score is `3` because the plan requires special two-sided hosted topology/performance
  evidence; unrun hosted evidence remains a confidence condition, not completed validation burden.
- Scope volatility is low unless implementation expands beyond `fairing_support` or changes public
  contract behavior.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

### Confirmed Drivers
- Functional scope remains `2`: behavior-visible output compaction changes an existing workflow
  without adding a public operation.
- Technical surface and friction remain high because the plan crosses policy classification,
  output split timing, compaction interaction, internal evidence, replay fixtures, and hosted proof.
- Validation burden remains `3` because the distinguishing work is special two-sided topology and
  performance evidence, not routine CI or a routine hosted matrix.
- Premortem additions fit the predicted risk shape: current-heightfield residual source,
  pre-recursion split proof, stale fairing-marker compaction guard, circular bounds sensitivity, and
  duplicate-probe guard.

### Contested Drivers / Missing Evidence
- Exact internal policy-to-output API shape remains implementation-time tactical ambiguity, but not
  enough to change scope while the ownership boundary is fixed.
- Existing replay rows may not isolate both acceptance sides; this is already an estimate breaker
  only if new fixture work expands materially beyond the planned focused rows.
- Hosted timing regression risk is real but not yet evidence of validation burden `4`; repeated
  blockers or redesign would be drift, not current prediction.

### Score Changes
- None. Premortem findings strengthen the existing `3` implementation-friction and validation
  scores rather than raising them.

### Recommendation
- Proceed with implementation under the finalized plan. Record drift if circular bounds require
  exact topology, if bumpy preservation needs a different rule, if residual probing causes repeated
  timing failure, or if public contract shape unexpectedly changes.
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
