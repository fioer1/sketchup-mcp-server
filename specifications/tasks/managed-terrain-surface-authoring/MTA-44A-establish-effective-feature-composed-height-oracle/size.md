# Size: MTA-44A Establish Effective Feature Composed Height Oracle

**Task ID**: MTA-44A  
**Title**: Establish Effective Feature Composed Height Oracle  
**Status**: calibrated  
**Created**: 2026-05-28  
**Last Updated**: 2026-06-01  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:feature`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-state`
  - `systems:terrain-storage`
  - `systems:serialization`
  - `systems:terrain-kernel`
  - `systems:surface-sampling`
  - `systems:terrain-output`
- **Distinguishing Validation / Host Shape**:
  - `validation:migration`
  - `validation:compatibility`
  - `validation:persistence`
- **Likely Analog Class**: production terrain state/read model refactor with feature-aware output dependencies

### Identity Notes
- Seeded from the MTA-44 split discussion. This task makes the active height truth model production-visible while intentionally leaving mesh topology unchanged.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Suspicion-level only. Refresh this section before prediction if planning changes task shape.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Changes the production height truth model but should preserve visible output. |
| Technical Change Surface | 4 | Height reads are spread across sampling, validation, output planning, state, and readback. |
| Hidden Complexity Suspicion | 3 | Feature precedence, circular membership, occlusion, and direct-read exceptions can hide divergence. |
| Validation Burden Suspicion | 3 | Needs parity, precedence, persistence, and compatibility evidence beyond a narrow unit slice. |
| Dependency / Coordination Suspicion | 2 | Depends on existing feature view, feature geometry, and recent seam/component groundwork. |
| Scope Volatility Suspicion | 2 | The boundary is clearer after the split, but direct-read classification may reshape the plan. |
| Confidence | 2 | Concept is clear; scattered raw height reads and precedence details remain unplanned. |

### Early Signals
- Direct `state.elevations` reads already exist in several output and validation paths.
- Existing `EffectiveFeatureView` and `TerrainFeatureGeometryBuilder` provide the right active feature substrate.
- Circular features are currently present as primitives, but bounding-box pressure and partial occlusion limitations can weaken semantic height correctness.
- The task must avoid creating a second renderer or public contract drift.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

| Dimension | Predicted (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Establishes a production height truth model and circular primitive semantics across output/readback, while preserving public workflow shape. |
| Technical Change Surface | 3 | Layered change across feature geometry, oracle/domain sampling, output planning, mesh emission, readback/fingerprint, persistence tests, and no-leak posture. No public/schema change planned. |
| Implementation Friction | 3 | Main friction is routing all composed-height reads without parallel semantics, extracting/reusing planar math, and auditing direct base-read exceptions. |
| Validation Burden | 3 | Above baseline because it needs parity, precedence, direct-read audit, registry/readback, persistence/save-reopen, hosted replay, and timing-band evidence. |
| Dependency / Coordination Drag | 2 | Depends on recent feature-aware output, seam, lifecycle, and circular behavior groundwork, but remains inside owned terrain runtime. |
| Discovery / Ambiguity | 2 | Major design decisions are settled; residual ambiguity is tactical extraction/routing detail and hosted evidence availability. |
| Scope Volatility | 1 | The task was clarified into two workstreams but accepted outcome remains stable: effective primitive completeness plus height oracle, no topology. |
| Rework Pressure | 2 | Some localized rework is plausible around planar helper extraction and output/readback routing, but no rewrite direction is expected. |
| Confidence | 2 | Planning evidence is strong, but confidence is capped by cross-cutting routing, hosted validation, and the lack of a calibrated exact oracle analog. |

### Analog Brief

- `MTA-33` is the closest active-feature-selection analog. It warns that constructing context is not enough; production consumers and no-leak posture must be proven.
- `MTA-40` and `MTA-45` are the closest feature-aware output validation analogs. They justify Validation Burden `3` because hosted replay/performance and circular/planar behavior can reveal non-local issues.
- `MTA-43` is the registry/lifecycle evidence analog. It supports a higher technical-surface score because metadata must match real mutation/readback behavior, not just diagnostics.
- `MTA-12` confirms circular inputs are real public terrain shapes, but it is not a close implementation analog because MTA-44A should not change public contracts.
- No calibrated task exactly matches a shared composed height oracle across output planning, mesh emission, validation, readback, and quality sampling.

### Top Assumptions

- Effective feature geometry already contains enough payload to derive circular membership, target height, preserve/protected classification, and planar controls without a storage schema change.
- A shared planar helper can be extracted or introduced without destabilizing existing planar edit behavior.
- Output/readback height reads can be routed through an oracle seam without requiring topology or public contract changes.
- Hosted replay/save-reopen validation is available or can be explicitly documented as a gap.

### Estimate Breakers

- Planar controls cannot be evaluated with parity against existing planar edit semantics without a larger edit-kernel refactor.
- Direct base-height reads are more deeply embedded in production output/readback than research identified, making oracle authority a broader rewrite.
- Registry/readback fingerprinting needs public or durable schema changes rather than internal policy-token updates.
- Hosted validation exposes performance or save/reopen instability requiring redesign rather than tuning/caching.

### Predicted Notes

- Validation `3` is for extra oracle-specific persistence/readback/timing/audit burden beyond normal repo closeout, not for routine CI or standard hosted smoke alone.
- Scope volatility is low because MTA-44A now explicitly excludes MTA-44B/C topology work.
- Confidence remains moderate until implementation proves direct-read routing and hosted/readback behavior.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

### Confirmed Drivers
- Functional Scope `3` remains appropriate: the task establishes a production height truth model without public workflow or topology expansion.
- Technical Change Surface `3` remains appropriate: the plan crosses feature geometry, oracle/domain sampling, output/readback, registry/fingerprint, persistence, and no-leak posture, but avoids public/schema contract change.
- Implementation Friction `3` remains appropriate: premortem confirmed routing authority, planar-helper parity, and direct-read audit as real implementation gates.
- Validation Burden `3` remains appropriate: persistence/readback/timing/direct-read audit are extra validation beyond routine closeout.

### Contested Drivers / Missing Evidence
- Technical Change Surface could become `4` if direct-read routing requires broad restructuring across output and command layers rather than adding a shared oracle seam.
- Validation Burden should not rise above `3` unless hosted validation produces blocker defects, repeated fix/retest loops, special scene setup, performance redesign, or persistence/readback instability.
- Confidence remains capped at `2` because hosted save/reopen and readback behavior are not yet proven, and no exact calibrated oracle analog exists.
- The unavailable `gpt-5.3` adversarial consensus leg is a review gap, but the premortem and `grok-4.3` review did not expose an unresolved Tiger.

### Score Changes
- None. The premortem converted risks into guardrails and validation gates but did not add scope or change the task boundary.

### Recommendation
- Proceed with the finalized plan. Watch direct-read routing breadth, planar-helper extraction, registry/fingerprint invalidation, and hosted save/reopen/readback evidence as the primary drift signals.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

> Append only. Log material estimate drift, not routine TDD/review/live-check correction.

| Date | Checkpoint | Event Type | Severity (1-3) | Dimension Affected | Predictable Earlier? | Notes |
|---|---|---|---:|---|---|---|
| 2026-06-01 | Post-review plan-vs-diff reread | Missed planned integration consumer | 2 | Rework Pressure / Validation Confidence | Yes | After local and external review, a fresh plan audit found `AdaptiveOutputConformity` / diagonal optimization still using raw base elevations despite being a named oracle consumer. Scope did not expand, but completed routing/review needed a focused structural revisit and rerun. |

### Drift Notes
- Drift is not scope volatility: the accepted MTA-44A boundary stayed unchanged. It is recorded because the work had been treated as review-complete before a named planned integration point was found incomplete.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

| Dimension | Actual (0-4) | Evidence |
|---|---:|---|
| Functional Scope | 3 | Established a production composed height oracle and circular semantic retention without changing public workflow or topology. |
| Technical Change Surface | 4 | Cross-cutting runtime read-model change across feature geometry, planar math, command routing, output planning, conformity, diagonal optimization, mesh emission, quality sampling, fingerprints, persistence tests, package contents, and replay evidence. |
| Implementation Friction | 3 | Required structural correction after review to route named oracle consumers, plus hot-path tuning to make large replay timing acceptable. |
| Validation Burden | 4 | Exceeded repo baseline: live SketchUp checks exposed a command-path miss, replay/performance probes required repeated fix/redeploy/restart/rerun loops, and final evidence needed a clean three-run timing comparison. |
| Dependency / Coordination Drag | 2 | Stayed inside owned terrain runtime, but depended on prior feature-aware adaptive, patch lifecycle, replay harness, and hosted SketchUp deployment availability. |
| Discovery / Ambiguity | 3 | Implementation proved that correctness was not only oracle answers; production consumers, state selection, and performance cost had to be rediscovered and fixed. |
| Scope Volatility | 1 | Boundary stayed stable: MTA-44A remained height/oracle semantics only; circular topology and CDT were kept out of scope. |
| Rework Pressure | 3 | Meaningful revisit after the work looked review-complete: adaptive conformity/diagonal/raw-state routing and later oracle hot-path work had to be corrected. |
| Final Confidence in Completeness | 3 | Strong evidence for MTA-44A semantics and routing; remaining MTA-43 performance delta is measured and recorded as follow-up optimization rather than a completion blocker. |
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

Validation classified as **repeated blockers / heavy hosted investigation** rather than baseline
closeout. Automated evidence ended green: focused oracle/routing, affected terrain/oracle/output
suite, full Ruby suite, RuboCop, and package verification. Hosted evidence included focused scene
geometry, retained three-run large target replay after clean deploy, and MTA-43 timing comparison.
Live validation exposed one real command-path integration miss and a material oracle performance
regression, both fixed before closeout. Save/reopen was intentionally skipped as non-valuable for
this task; serializer round-trip coverage remained the persistence evidence.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

### Underestimated

- Technical Change Surface: prediction did not fully account for how many production consumers
  needed one oracle instance threaded through planning, conformance, seams, diagonal optimization,
  mesh emission, and replay quality sampling.
- Validation Burden: prediction expected hosted replay/timing, but not repeated live timeouts,
  restart/redeploy loops, and three-run clean-deploy performance comparison after hot-path work.
- Rework Pressure: plan anticipated localized routing risk, but missed that named consumers could
  still read raw/base state after the work appeared review-complete.

### Overestimated

- Scope Volatility: the task boundary did not materially change. User challenges returned the work
  to the plan rather than expanding MTA-44A into topology, CDT, or save/reopen work.

### Future Analog Lesson

For shared terrain read-model tasks, estimate the consumer-threading and live performance proof as
first-class work. Unit oracle correctness is not enough; adaptive planning, diagonal optimization,
mesh generation, and replay probes can preserve old behavior while multiplying call-path cost.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:managed-terrain`
- `systems:surface-sampling`
- `systems:terrain-output`
- `validation:persistence`
- `validation:hosted-replay`
- `validation:performance-comparison`
- `contract:no-public-shape-change`
- `risk:direct-height-read-routing`
- `risk:oracle-hot-path`
- `friction:high`
- `rework:meaningful-consumer-threading`
- `confidence:strong-with-measured-perf-gap`
<!-- SIZE:TAGS:END -->
