# Size: MTA-44B Add Contained Production Feature Cut Graph Output

**Task ID**: MTA-44B  
**Title**: Add Contained Production Feature Cut Graph Output  
**Status**: calibrated  
**Created**: 2026-05-28  
**Last Updated**: 2026-06-03  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)  

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
  - `validation:hosted-matrix`
  - `validation:performance`
  - `validation:persistence`
  - `host:special-scene`
- **Likely Analog Class**: production topology slice constrained to seam-safe local terrain output

### Identity Notes
- Refreshed after planning: this is a contained production feature-cut slice with committed full hosted visual, performance, stale-cut, no-delete, and persistence validation.
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
| Validation Burden Suspicion | 4 | Requires special contained scenes, visible topology proof, performance timing, stale-cut removal, no-delete, and persistence evidence. |
| Dependency / Coordination Suspicion | 3 | Requires MTA-44A and depends on prior feature-aware adaptive and patch lifecycle behavior. |
| Scope Volatility Suspicion | 2 | Scope is bounded to contained cuts and explicit skips, but cross-boundary pressure from MTA-44C remains nearby. |
| Confidence | 2 | Production boundary and split templates are clear, but local topology emission is unproven in host. |

### Early Signals
- Current feature view already provides active geometry, but circles are underrepresented as topology-forcing boundaries.
- Existing forced subdivision pressure is not equivalent to inserting exact off-grid cut vertices.
- The task avoids incorrect seams by skipping boundary-touching enhancement until MTA-44C.
- Baseline replay rows do not prove contained circular or diagonal cuts; new contained fixtures are required.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds production-visible topology for contained planar, circle, corridor/diagonal, and off-grid control cases. |
| Technical Change Surface | 4 | Crosses feature geometry, adaptive subdivision, compaction, conformity rewrite, mesh emission, command/replay evidence, and hosted validation. |
| Implementation Friction Risk | 4 | Deterministic local split templates must preserve conformity while avoiding CDT/general triangulation scope. |
| Validation Burden Risk | 4 | Special hosted scenes, visual topology proof, timing, stale-cut removal, no-delete failure proof, and persistence checks are required beyond repo baseline. |
| Dependency / Coordination Risk | 3 | Depends on MTA-44A oracle routing plus forced subdivision, seam/component lifecycle, planar compaction, and replay harness behavior. |
| Discovery / Ambiguity Risk | 2 | Planning resolved the major model choices; tactical helper placement and fixture shape remain. |
| Scope Volatility Risk | 2 | Contained scope is explicit, but boundary and local-complexity skips must resist pressure to absorb MTA-44C. |
| Rework Risk | 3 | Host-visible topology and oracle routing are likely to expose at least one meaningful correction loop. |
| Confidence | 2 | Strong planning evidence, but no contained production cut fixture has proven the approach yet. |

### Analog Brief
- `MTA-44A` matches oracle routing through production output; actual change surface and validation were high because helper correctness did not prove mesh emission.
- `MTA-45` matches effective-feature occlusion/visible topology risk; hosted evidence caught topology behavior that counters would miss.
- `MTA-40` matches forced subdivision and performance risk; pressure helped but was not equivalent to final emitted topology.
- `MTA-43`/`MTA-36` match lifecycle/no-delete/registry sensitivity; replay metadata alone did not prove mutation safety.
- No exact calibrated analog exists for contained feature-cut insertion, so prediction combines topology-output risk with lifecycle/host validation analogs.

### Top Assumptions
- `topologyCutConstraints` can be derived from effective feature geometry without adding public MCP contract fields.
- `targetCellSize: 1` subdivision normally reduces contained circle/corridor/path cases into supported one- or two-segment local fragments.
- Tagged cut vertices can route through `ComposedHeightOracle` without changing existing fan-center elevation semantics.
- New contained 8m base-patch fixtures can exercise visible cuts without requiring `MTA-44C` cross-patch behavior.

### Estimate Breakers
- Final conforming cells still contain disjoint/multi-origin fragments after forced subdivision.
- Mesh emission cannot distinguish inserted cut vertices from existing fractional fan centers cleanly.
- Dirty rebuild or no-delete lifecycle paths drop feature policy/oracle/cut inputs under hosted conditions.
- Hosted visuals show counters passing while actual topology, ownership, stale-cut removal, or timing fails.

### Predicted Notes
- Score `4` values are not from routine CI or hosted smoke; they reflect a wide production output surface plus required special-scene visual/performance/persistence/no-delete validation.
- Confidence stays moderate-low until contained production fixtures prove actual emitted topology.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

### Confirmed Drivers
- Wide technical surface remains correct: feature geometry, forced subdivision, compaction,
  conformity rewrite, mesh emission, lifecycle fallback, replay evidence, and hosted validation all
  remain in scope.
- Validation burden `4` is supported by special-scene visual topology proof, performance timing,
  dirty full-rebuild preservation, stale-cut removal, no-delete failure proof, and persistence
  checks. This is beyond routine hosted matrix breadth.
- Implementation friction `4` is supported by the need to preserve conformed boundaries while adding
  deterministic cut triangles without drifting into CDT/general triangulation.

### Contested Drivers / Missing Evidence
- `targetCellSize: 1` may not reduce all contained circle/corridor cases into supported local
  fragments; plan now treats that as explicit local-complexity skip evidence rather than a hidden
  implementation decision.
- Actual performance threshold and fixture placement remain implementation-time evidence, not
  planning facts.
- Hosted proof is still required before confidence can move above `2`.

### Score Changes
- None.

### Recommendation
- Keep the prediction unchanged and proceed to implementation with the finalized premortem gates.
  Treat any pressure to support cross-patch/seam or general triangulation cases as scope drift into
  `MTA-44C`.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

> Append only. Log material estimate drift, not routine TDD/review/live-check correction.

| Date | Checkpoint | Event Type | Severity (1-3) | Dimension Affected | Predictable Earlier? | Notes |
|---|---|---|---:|---|---|---|
| 2026-06-02 | Live contained circle verification | Scope / rework | 2 | Implementation Friction Risk, Rework Risk | Yes | Hosted off-grid circle evidence showed the planned one-/two-fragment rewrite templates underrepresent realistic contained circle cells. Plan amended narrowly to support single simple same-origin open chains of any fragment count without CDT/general triangulation; branching, disjoint, closed-loop, and multi-origin cells remain skipped. |
| 2026-06-03 | Live contained corridor verification | Rework / approach | 2 | Implementation Friction Risk, Rework Risk, Validation Burden Risk | Yes | Hosted corridor evidence showed XY topology can be present while cut vertices still receive wrong heights. Plan reopened Step 03 narrowly for cut-local height anchors, rewrite interpolation, explicit-height mesh emission, and evidence that separates topology success from height success. |

### Drift Notes
- Material drift recorded for the connected-chain rewrite expansion discovered during live circle
  verification.
- Material drift recorded for the cut-local height-semantics addendum discovered during live
  corridor verification.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | The attempted slice still targeted production-visible contained feature cuts for circles, corridors, planar boundaries, and control points, but no production behavior is accepted for commit. |
| Technical Change Surface | 4 | Actual work crossed feature geometry, topology constraints, output planning, adaptive rewrite, mesh emission, oracle semantics, replay evidence, and hosted verification. |
| Actual Implementation Friction | 4 | The adaptive/no-CDT strategy became dominated by cut-cell fragmentation, boundary propagation, height-anchor ordering, composed-feature semantics, and stale-domain behavior. |
| Actual Validation Burden | 4 | Hosted special scenes and repeated fix/reload/retest loops changed the closeout from acceptance validation into failure diagnosis and replan evidence. |
| Actual Dependency Drag | 3 | The slice depended on MTA-44A effective geometry/oracle routing, adaptive output internals, hosted SketchUp deployment/reload, and lifecycle assumptions about generated terrain. |
| Actual Discovery Encountered | 4 | Live validation changed the core model: output cut constraints must be transient per generated mesh, and adaptive templates alone may not handle composed/intersecting feature boundaries. |
| Actual Scope Volatility | 4 | The accepted outcome changed from a production feature-cut implementation to blocked closure with follow-up MTA-44B1. |
| Actual Rework | 4 | Multiple completed slices were revisited, including circle, square, corridor, composed-feature, height-anchor, polygon-domain, and snapping experiments, with the implementation direction now planned for revert. |
| Final Confidence in Completeness | 1 | Confidence is low for MTA-44B as a completed implementation; confidence is high only in the failure diagnosis and the need for MTA-44B1 replanning. |

### Actual Signals
- Green local tests did not prove production readiness because hosted SketchUp visuals exposed manifold-but-wrong output and stale height-domain behavior.
- The decisive breaker was not only topology quality; it was the lifetime mismatch between disposable output constraints and durable edit history.
- The no-CDT/adaptive-only assumption may still be viable for a narrower fallback, but it was not proven as the general production strategy for composed contained cuts.

### Actual Notes
- Score `4` values are justified by abandoned implementation direction, repeated hosted blocker loops, and replan/revert outcome, not by routine test breadth.
- This calibration should be used as an analog for terrain topology tasks where local green tests and mesh manifoldness can mask product-model failure.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

Validation classification: repeated hosted blocker/fix loop ending in blocked production closeout.

- Automated checks reached a green local affected-suite state and RuboCop was clean for the changed runtime/test surface.
- Hosted SketchUp scenes proved useful evidence but did not produce acceptable production behavior: corridor-only became mostly acceptable, circle quality improved in simple cases, and composed circle-plus-corridor remained semantically wrong.
- Later polygon/oracle experiments fixed one composed-height symptom but proved the wrong lifetime model because old feature domains could keep constraining later fairing.
- Final review status is incomplete for production closeout; the proper review target is the MTA-44B1 plan and implementation, not this reverted patch.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

Prediction was directionally right about high technical surface, implementation friction, validation burden, and rework risk. The estimate breakers were real: hosted visuals showed counters and manifoldness could pass while topology ownership, shape readability, and height semantics failed.

Underestimated:
- Discovery/ambiguity should have been higher. The plan treated disposable output constraints as straightforwardly derivable from effective geometry, but live validation exposed a deeper lifetime distinction between generated mesh constraints and durable terrain edit history.
- Scope volatility should have had a stronger closeout-risk signal because the no-CDT constraint made full composed-boundary support uncertain.

Overestimated or misframed:
- Performance/persistence/no-delete breadth was less decisive than geometry semantics. The dominant risk was not proving many lifecycle modes; it was proving that the topology model itself was correct.
- Local replay rows were useful diagnostics but could not substitute for hosted visual/product validation.

Future analog lesson:
- For managed-terrain topology tasks, score discovery high when the plan relies on deterministic adaptive templates instead of a general constrained triangulation path, especially when composed/intersecting feature boundaries and later fairing are in scope.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:managed-terrain`
- `systems:terrain-kernel`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `validation:hosted-matrix`
- `host:special-scene`
- `host:repeated-fix-loop`
- `contract:no-public-shape-change`
- `risk:partial-state`
- `friction:high`
- `rework:high`
- `volatility:high`
- `confidence:low`
<!-- SIZE:TAGS:END -->
