# Size: MTA-41 Add Optional Deterministic Feature-Aware Diagonal Optimization

**Task ID**: MTA-41
**Title**: Add Optional Deterministic Feature-Aware Diagonal Optimization
**Status**: calibrated
**Created**: 2026-05-15
**Last Updated**: 2026-05-26

**Related Task**: [task.md](./task.md)
**Related Plan**: [plan.md](./plan.md)
**Related Summary**: [summary.md](./summary.md)

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:feature`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:validation-service`
- **Distinguishing Validation / Host Shape**:
  - `validation:hosted-matrix`
  - `validation:performance`
  - `validation:contract`
  - `validation:regression`
- **Likely Analog Class**: adaptive output visual-quality optimization with feature-policy and hosted proof constraints

### Identity Notes
- Refreshed after planning as an optional/evidence-gated emitted-geometry optimization, not a
  downstream dependency.
- The core risk is false-positive completion: diagnostics without changed emitted triangles and a
  predeclared metric effect.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Internal output-quality behavior for rectangular adaptive cells only. |
| Technical Change Surface | 3 | Spans optimizer, derived feature context, conformity emission, replay/result evidence, no-leak tests, and hosted proof. |
| Hidden Complexity Suspicion | 3 | Main risks are metric validity, feature-check scaling, protected ambiguity, and metadata-only proof. |
| Validation Burden Suspicion | 3 | Requires targeted changed-diagonal proof, repeated hosted timing, seam-adjacent review, and contract/no-leak checks. |
| Dependency / Coordination Suspicion | 2 | Depends on MTA-38/MTA-39/MTA-40 substrates and hosted SketchUp access, but no public contract coordination. |
| Scope Volatility Suspicion | 2 | May be adopted, deferred, or rejected depending on evidence. |
| Confidence | 2 | Plan is specific, but payoff and hosted proof still need implementation evidence. |

### Early Signals
- No downstream dependency; deferral/rejection is an acceptable outcome if evidence is weak.
- Adoption requires actual changed `emission_triangles`, not only internal counters.
- Residual sampling and hosted proof shape are estimate drivers.
- Public command contracts are expected to remain unchanged.

### Early Estimate Notes
- Seed only. Do not treat this as the predicted implementation estimate.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Adds optional internal diagonal choice for rectangular adaptive cells only; no public workflow or broad backend behavior. |
| Technical Change Surface | 3 | Crosses pure optimizer, feature/protected context, conformity emission, mesh consumption assumptions, replay/result/classifier internals, and no-leak coverage. |
| Implementation Friction Risk | 3 | Exact residual sampling, deterministic precedence, feature-check budgets, and proof isolation can resist naive implementation. |
| Validation Burden Risk | 3 | Requires special changed-diagonal proof, repeated hosted timing, seam-adjacent metric review, contract/no-leak checks, and adoption/defer/reject evidence beyond routine unit tests. |
| Dependency / Coordination Risk | 2 | Relies on in-repo MTA-38 replay, MTA-39 policy, MTA-40 forced/protected context, MTA-42/MTA-43 safety boundaries, and hosted SketchUp access. |
| Discovery / Ambiguity Risk | 2 | Major planning choices are resolved; remaining unknowns are fixture sensitivity, exact thresholds, and whether measured value is sufficient for adoption. |
| Scope Volatility Risk | 2 | The plan explicitly permits defer/reject and excludes MTA-44/CDT/seam/component scope, but weak evidence may pressure replanning. |
| Rework Risk | 3 | High chance of revisiting early tests/diagnostics if they prove counters rather than real emitted geometry or if hosted proof does not exercise changed cells. |
| Confidence | 2 | Finalized plan is specific and premortem-patched, but implementation and hosted evidence are still pending. |

### Analog Brief

- MTA-39 is the closest feature-policy/output-plan analog: policy behavior was bounded, but hosted
  quality evidence and classifier semantics needed careful interpretation.
- MTA-40 is the closest topology-pressure analog: live validation exposed geometry-policy and
  timing issues that local tests did not fully predict.
- MTA-43 is the strongest proof-quality analog: green tests and metadata were insufficient until a
  targeted proof showed actual changed patch regeneration. MTA-41 mirrors that with changed
  emitted diagonals.
- MTA-42 provides seam-contract context, but its seam checks do not prove hidden diagonal or
  seam-adjacent shading safety.
- No calibrated analog exactly covers deterministic diagonal optimization, so confidence stays
  moderate-low until hosted proof exists.

### Top Assumptions

- The final rectangular adaptive cells expose enough source samples to compute a meaningful
  non-corner triangle-plane residual for at least one targeted proof.
- The optimizer can run after final cell selection without changing adaptive split decisions,
  PatchLifecycle, or SketchUp mutation code.
- Derived feature geometry can be normalized and bounds-gated cheaply enough without preemptive
  indexing.
- Internal result documents can carry aggregate diagonal evidence without public response drift.

### Estimate Breakers

- The replay corpus and targeted proof cannot produce actual changed `emission_triangles` without
  broad fixture or planner changes.
- Residual improvement requires denser sampling, local detail, CDT, or exact breakline topology
  beyond the planned rectangular-cell scope.
- Feature/protected lookup exceeds the declared check budget and needs an index or broader feature
  geometry rewrite.
- Hosted proof shows timing regression or seam-adjacent slope/shading regression that blocks
  adoption.

### Predicted Notes

- Functional scope is `2` because the user-visible outcome is optional output quality, not a new
  workflow or dependency in the MTA sequence.
- Technical surface and validation are `3` because the task must prove real emitted topology,
  metric value, no public leak, and hosted behavior across several internal surfaces.
- Rework risk is `3` specifically because local tests can easily optimize the wrong thing. Drift
  should be recorded if implementation starts passing counters without changed geometry, if a
  broader fixture is needed, or if hosted validation changes the adoption gate.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

### Confirmed Drivers

- Functional Scope `2` remains appropriate: the task is an optional internal output-quality
  optimization for rectangular adaptive cells, with no public workflow, sparse local detail, CDT,
  seam, component, or PatchLifecycle behavior.
- Technical Change Surface `3` remains appropriate: the finalized plan spans optimizer, derived
  feature context, conformity emission, internal replay/result/classifier evidence, mesh-consumer
  assumptions, and no-leak coverage.
- Validation Burden Risk `3` remains appropriate: the premortem confirmed special changed-diagonal
  proof, hosted repeated timing, seam-adjacent non-regression, and internal/public contract checks
  are required beyond routine unit tests.
- Rework Risk `3` remains appropriate: the dominant risk is local tests or diagnostics proving the
  wrong thing, especially counters without changed `emission_triangles`.

### Contested Drivers / Missing Evidence

- The largest unresolved evidence gap is whether the existing replay corpus or a targeted
  `x >= 50m` proof can produce an isolated rectangular changed-diagonal cell with non-corner source
  samples.
- Feature-check-count budgets are planned but not measured. If derived feature cardinality exceeds
  the budget, implementation may need a simple bucket/index.
- Seam-adjacent behavior remains host-sensitive because seam contracts do not validate hidden
  diagonal shading or dihedral effects.
- Adoption value remains unknown until metric and timing evidence exists; defer/reject remains a
  valid outcome, not an estimate failure.

### Score Changes

- No predicted score changes.
- Premortem changes strengthened Phase 0, emitted-triangle integration proof, and hosted proof-cell
  identification, but they fit inside the already-predicted Technical Change Surface `3`,
  Validation Burden Risk `3`, and Rework Risk `3`.

### Recommendation

- Proceed with the finalized plan.
- Record size drift during implementation if the targeted proof needs broader planner changes, if
  feature lookup requires indexing or feature-geometry redesign, if hosted validation causes
  repeated fix/redeploy loops, if seam-adjacent metrics block adoption, or if any public contract
  shape change becomes necessary.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

No material drift recorded yet.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Shipped a limited internal emitted-geometry optimization for rectangular adaptive cells; no public workflow or contract change. |
| Technical Change Surface | 3 | Crossed optimizer/context, conformity output, output plan, command evidence, replay/result/classifier internals, and contract no-leak tests. |
| Actual Implementation Friction | 3 | Deterministic residual scoring, protected-boundary candidate safety, seam-adjacent evidence, and Ruby hot-path tuning required meaningful engineering adjustment beyond a direct implementation. |
| Actual Validation Burden | 3 | Exceeded normal closeout with expanded hosted replay/perf matrix, fresh SketchUp restart repeats, live artifact capture, bucket attribution, and review-driven proof fixes. |
| Actual Dependency Drag | 2 | Depended on MTA-38 replay harness, MTA-39/MTA-40 feature policy context, MTA-42 comparison baseline, deployed SketchUp access, and manual restart/deploy coordination. |
| Actual Discovery Encountered | 3 | Live timing and review evidence changed execution: the task needed explicit adoption evidence, seam-adjacent counting, cost-bucket analysis, and Ruby allocation/math reductions. |
| Actual Scope Volatility | 1 | The accepted outcome stayed inside the planned optional diagonal optimization boundary; added performance tuning and evidence capture were minor in-bound adjustments. |
| Actual Rework | 2 | Localized corrections revisited optimizer/context/conformity evidence after review and live timing, but no redesign, revert, or abandoned direction occurred. |
| Final Confidence in Completeness | 3 | Required local, review, hosted replay, no-leak, and clean restart perf evidence is present; only optional stricter same-runtime optimizer off/on benchmarking remains. |
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

Validation classified as `expanded matrix/special setup`, not routine-only closeout.

- Local evidence included failing skeleton baseline, focused matrix, full Ruby tests, full RuboCop,
  package verification, and post-optimization focused checks.
- Review evidence included PAL `gpt-5.4` matrix review, PAL final code review, and deterministic
  `$task-review --quick` checks; the full subagent review form was not run because agent spawning
  required explicit authorization.
- Hosted evidence included three deployed live captures, public no-leak smoke, three clean
  post-restart perf captures, three Ruby-optimized live-session perf captures, and three fresh
  post-restart optimized perf captures.
- The final fresh post-restart optimized perf artifacts are retained under `test/terrain/replay/`,
  matching the existing replay-result convention.
- The final hosted verdict supports adoption: changed emitted diagonals and residual improvement
  were present, deterministic signatures were stable, seam-adjacent aggregate deltas did not
  regress, public output did not leak internal diagnostics, and fresh optimized perf remained
  inside the predeclared timing tolerance.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

### Underestimated

- Performance proof cost was underweighted. The real closeout required baseline comparison against
  MTA-42/MTA-39, bucket attribution, a fresh restart repeat, and Ruby-side hot-loop optimization to
  explain the price of improved geometry.
- External review found real proof gaps: candidate-specific protected-boundary safety,
  seam-adjacent changed-cell evidence, residual clamping, and explicit adoption evidence.
- Artifact retention was missed until closeout; the final hosted JSON captures needed to be copied
  into `test/terrain/replay/` to make the adoption evidence durable and convention-compatible.

### Overestimated

- The replay corpus naturally produced changed emitted diagonals in every row, so the planned
  targeted `x >= 50m` fallback proof was not needed.
- Derived feature bounds-gating was enough; no bucket/index or feature-geometry redesign was
  required.
- Public docs and user-facing MCP contract updates were unnecessary because all diagnostic output
  remained internal.

### Future Analog Lesson

For performance-sensitive internal geometry-quality optimizations, estimate live evidence as a
first-class slice: changed emitted geometry, residual/visual metric, no public leak, artifact
retention, and at least one fresh restart perf matrix. Treat cost attribution and a possible Ruby
allocation/math pass as likely when adoption depends on proving the quality gain is worth the time.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:managed-terrain`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:validation-service`
- `systems:public-contract`
- `validation:hosted-matrix`
- `validation:performance`
- `validation:contract`
- `host:redeploy-restart`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `risk:review-rework`
- `friction:medium`
- `confidence:high`
<!-- SIZE:TAGS:END -->
