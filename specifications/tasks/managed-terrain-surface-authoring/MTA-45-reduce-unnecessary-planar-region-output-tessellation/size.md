# Size: MTA-45 Reduce Unnecessary Planar Region Output Tessellation

**Task ID**: MTA-45  
**Title**: Reduce Unnecessary Planar Region Output Tessellation  
**Status**: calibrated
**Created**: 2026-05-17  
**Last Updated**: 2026-05-20

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:performance-sensitive`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-kernel`
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:validation-service`
  - `systems:managed-object-metadata`
- **Validation Modes**:
  - `validation:hosted-matrix`
  - `validation:performance`
  - `validation:persistence`
  - `validation:regression`
- **Likely Analog Class**: MTA-40 feature-aware adaptive output follow-up with MTA-36 patch lifecycle validation pressure

### Identity Notes
- Seeded as a bounded planar-output compaction task after MTA-40 removed broad planar pressure but left excess planar interior tessellation from older pressure leaking through later absolute planar edits.
- Primary complexity is stack-order and intersection awareness: older corridor/target/survey/fairing pressure must be clipped or suppressed only where a later absolute planar footprint covers it, while newer overlays remain authoritative.
- Public MCP contracts are explicit non-goals; risk concentrates in feature-geometry planning inputs, output topology, patch ownership, intersection-aware suppression, newer-feature precedence, and hosted replay evidence.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Reduces visible planar-region output complexity by preventing older pressure leakage through later absolute planar footprints while preserving stitching, newer overlays, falloff behavior, and lifecycle semantics. |
| Technical Change Surface | 3 | Likely spans feature-geometry planning inputs, adaptive output policy, planar-specific replay evidence, and ownership/readback checks; mesh generation should remain mostly validation surface unless downstream compaction is later gated in. |
| Hidden Complexity Suspicion | 3 | Intersection-aware clipping of older crossing pressure can expose boundary stitching, newer-feature precedence, and topology/quality tradeoffs inside the current patch-cell path. |
| Validation Burden Suspicion | 3 | Hosted replay must compare face/vertex counts, quality, timing, dirty-window scope, patch scope, registry/readback, and no-delete behavior. |
| Dependency / Coordination Suspicion | 2 | Depends on MTA-40, MTA-39, MTA-38, and MTA-36 baselines, but stays inside the managed terrain runtime and does not alter public contracts. |
| Scope Volatility Suspicion | 2 | Scope is bounded to no-falloff planar compaction and falloff-edge pressure, but planning may need to record limits if the current output path cannot safely compact a case. |
| Confidence | 2 | Problem and baselines are well defined, but no technical plan exists yet and safe compaction strategy remains unproven. |

### Early Signals
- MTA-40 live validation is the direct source signal: planar pressure was reduced, but older feature pressure can still leak through later absolute planar edits and keep planar interiors over-tessellated.
- Later absolute planar regions should suppress older underlying pressure only where the planar footprint intersects it; older pressure outside the footprint and newer pressure above the planar edit remain valid.
- Acceptance depends on preserving stitched patch-owned output, not introducing detached overlay plates, holes, or unowned cross-patch faces.
- Newer corridor, target, survey, and fairing features over planar edits must stay authoritative.
- Evidence must remain comparable with the MTA-38 replay corpus and MTA-40 final result pack.

### Early Estimate Notes
- Seed only. Do not treat this as the predicted implementation estimate.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

| Dimension | Predicted (0-4) | Rationale |
|---|---:|---|
| Functional Scope | 3 | Corrects visible planar-output behavior across older-under-planar and newer-over-planar stack-order cases while preserving falloff, lifecycle, and public workflows. |
| Technical Change Surface | 3 | Primary work is feature-geometry planning-input clipping, but proof spans adaptive policy, forced masks, replay metrics, contract no-leak checks, and hosted patch lifecycle evidence. |
| Implementation Friction Risk | 3 | Primitive splitting/subtraction is bounded, but stack-order direction, outside-fragment preservation, forced-reference paths, and fallback limitations can resist naive implementation. |
| Validation Burden Risk | 3 | Requires focused unit/integration/contract coverage plus planar-interior metrics, hosted replay comparison, quality, dirty scope, patch scope, registry/readback, no-delete, and three-run timing evidence. This is above routine hosted smoke, but not yet assumed blocker-heavy. |
| Dependency / Coordination Risk | 2 | Depends on MTA-40, MTA-39, MTA-38, and MTA-36 baselines plus hosted SketchUp access, all in-repo or established validation paths. |
| Discovery / Ambiguity Risk | 2 | Major architecture and clipping boundaries are resolved. Remaining uncertainty is tactical metric placement, fixture shape, and whether existing replay rows are sufficient. |
| Scope Volatility Risk | 2 | Scope is bounded by explicit exclusions: no global planar merge, no two-triangle cross-patch export, no public contract delta, and circular partial intersections can remain limitations. |
| Rework Risk | 3 | MTA-40 showed live planar behavior can force corrections after local tests pass; likely rework centers on clipping edge cases, metric attribution, and hosted timing/face-count interpretation. |
| Confidence | 3 | Plan is specific, analog-backed, and matrix-shaped, but hosted evidence and planar-interior metric feasibility remain completion gates. |

### Analog Brief

- MTA-40 is the closest analog. Its actual validation burden reached `4` after live planar-density,
  conformance fan, and performance issues required fix/redeploy/rerun loops. MTA-45 inherits that
  hosted risk but has a narrower semantic target.
- MTA-39 is the policy analog. It showed that broad face allocation can look plausible locally but
  fail quality/performance interpretation, so MTA-45 must separate face count, planar quality, and
  timing evidence.
- MTA-38 is the replay harness analog. Reuse its result-pack path, but expect metric/result
  interpretation work.
- MTA-36 is the lifecycle analog. Do not alter patch ownership or no-delete semantics casually;
  hosted registry/readback evidence is required.

### Top Assumptions

- Rectangular planar footprint subtraction for older segment and rectangle-pressure primitives is
  enough to prove the core task behavior.
- Current feature revision ordering is reliable enough to distinguish older-under-planar from
  newer-over-planar feature primitives.
- Internal/replay-only planar-interior metrics can be added without public response changes.
- Existing MTA-40 planar rows are likely sufficient as the hosted baseline unless metric evidence is
  ambiguous.

### Estimate Breakers

- Rectangular older crossing corridor/detail cannot be clipped without a broader geometry library or
  downstream topology rewrite.
- Replay metrics cannot attribute planar-interior face/vertex changes without adding a new hosted
  row or redesigning result capture.
- Hosted validation shows dirty-window, patch ownership, registry/readback, or no-delete regression.
- New diagnostics leak into public command responses or require schema/dispatcher/docs changes.

### Predicted Signals

- Positive: core semantic boundary is upstream of policy planning and avoids post-emission face
  surgery.
- Positive: current code already has containment-based occlusion, feature revision data, MTA-40
  forced-mask summaries, and reusable replay artifacts.
- Caution: reference/detail forced paths are as important as pressure regions.
- Caution: total face count is not enough; planar-interior metrics are a required proof signal.

### Predicted Notes

- Validation is scored `3` because the task requires planar-specific hosted evidence and repeated
  timing comparison beyond routine local closeout, but repeated blocker-heavy validation is not
  assumed before execution.
- Rework risk is scored `3` because MTA-40's closest actual analog found planar behavior late in
  hosted validation.
- Confidence is `3` because planning resolved the main architecture and clipping matrix; it should
  drop if the metric path or required rectangular clipping case becomes unsupported.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

### Confirmed Drivers

- Functional Scope `3` remains appropriate: the task corrects a visible stack-order planar output
  behavior while preserving public workflows and explicit downstream topology non-goals.
- Technical Change Surface `3` remains appropriate: the primary code boundary is feature geometry,
  but validation and proof cross adaptive policy, forced masks, replay metrics, contracts, and
  hosted lifecycle evidence.
- Validation Burden Risk `3` remains appropriate: premortem evidence made planar-interior metrics
  mandatory and hosted comparison non-negotiable. This is above routine closeout, but not yet
  repeated-blocker or redesign-dominated.
- Rework Risk `3` remains appropriate because the closest analog, MTA-40, discovered planar behavior
  late in hosted validation, and the premortem identified likely revisit points around segment
  clipping, metric attribution, and no-leak vocabulary.

### Contested Drivers / Missing Evidence

- The main contested validation driver is metric feasibility. If emitted-face centroid
  classification is not safe, implementation must provide an equivalent planned-cell metric or
  reopen planning.
- Existing hosted rows may be sufficient, but that remains conditional until planar-interior metrics
  land. A new hosted row is a possible validation expansion, not current scope.
- Rectangular corridor/reference clipping is assumed bounded. If it requires a generic polygon
  library, downstream topology rewrite, or mesh surgery, Technical Change Surface and Rework Risk
  are underpredicted.
- Public no-leak coverage is planned, but exact new diagnostic vocabulary is unknown until
  implementation. Contract risk is controlled by gate, not eliminated.

### Score Changes

- No predicted score changes after challenge.
- Premortem sharpened guardrails and made some validation mandatory, but it did not add a new public
  surface, new backend, exact circular clipping requirement, or cross-patch compaction scope.

### Recommendation

Proceed with implementation from the finalized plan. Record size drift if rectangular
planar-over-crossing-corridor clipping falls back, planar-interior metrics require new hosted
harness design, public response/schema changes become necessary, hosted validation enters repeated
fix/redeploy loops, or downstream compaction becomes required to satisfy the core success metric.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

### 2026-05-18 - Public Circle Pressure Clipping Scope Tightened

- **Trigger**: Step 03 coverage review challenged the finalized plan's allowance for partial circle
  pressure fallback.
- **Evidence**: Public terrain edits support circle regions for `target_height`,
  `survey_point_constraint`, and `local_fairing`; retaining an older partial circle pressure
  primitive wholesale would keep older density/tolerance pressure active inside a later rectangular
  no-falloff planar footprint, which violates the task's stack-order acceptance criteria.
- **Plan Delta**: `plan.md` now requires rectangular planar occlusion over public circle-pressure
  inputs to suppress planar-interior density/tolerance pressure while preserving outside influence.
  Exact circular arc fragments are not required; clipping can use policy-effective outside rectangle
  fragments because the current adaptive policy already consumes circle pressure via effective
  bounds. Partial circular planar occluders remain conservative limitation cases.
- **Affected Estimate Dimensions**: Functional Scope remains `3`, but Implementation Friction Risk
  and Rework Risk trend higher within `3` because pressure clipping now includes circle-pressure
  effective-bound subtraction, not only corridor/detail segments and rectangle pressure.
- **Known Estimate Breaker Comparison**: This does not yet hit the broader-geometry-library or
  downstream-topology-rewrite breaker; it will become material upward drift if public circle
  pressure cannot be clipped with bounded geometry-builder logic.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

| Dimension | Actual (0-4) | Evidence |
|---|---:|---|
| Functional Scope | 3 | Behavior-visible stack-order compaction across older corridor/reference pressure and public target/survey/fairing circle-pressure inputs under later absolute planar edits. |
| Technical Change Surface | 3 | Layered change across feature geometry clipping, command-side internal evidence, replay row propagation, classifier comparison, and focused contract/regression tests. |
| Actual Implementation Friction | 3 | The slice needed a material plan correction for public circle-pressure clipping plus bounded rectangle/segment subtraction helpers, but avoided a geometry-library or mesh-topology rewrite. |
| Actual Validation Burden | 4 | Hosted validation materially changed the implementation: visual inspection exposed that pressure clipping still left a full-grid-looking planar interior, requiring another code slice, deployment, reload, replay, and targeted live visual probes. |
| Actual Dependency Drag | 2 | The implementation depended on MTA-38/MTA-40 replay semantics, MTA-39 policy behavior, and MTA-36 lifecycle expectations; hosted SketchUp access remains the unclosed dependency. |
| Actual Discovery Encountered | 3 | Discovery centered on the distinction between pressure suppression and actual emitted planar-core compaction. The missing layer was internal planar-region propagation plus adaptive-cell coalescing. |
| Actual Scope Volatility | 2 | Scope tightened from allowing public circle-pressure fallback to requiring rectangular planar occlusion over public circle-pressure inputs, but the accepted outcome remained MTA-45 planar compaction. |
| Actual Rework | 3 | A hosted pass after apparent local completion forced revisiting the implementation and plan interpretation; the fix touched feature geometry, adaptive policy, output planning, command evidence, tests, deployment, and hosted replay. |
| Final Confidence in Completeness | 4 | Local validation, contract/lint/package checks, hosted replay, right-side scene placement proof, targeted circle no-falloff proof, replay-fixture planar falloff proof, and three-run hosted performance comparison are now complete. Residual risk is limited to further topology optimization beyond patch-local coalescing. |
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

### Classification

- **Completed validation burden**: hosted-fix loop beyond baseline.
- **Hosted status**: completed after one material implementation correction and redeploy/replay.
- **Review status**: deterministic local review plus PAL `grok-4.3` review completed; no accepted
  blocker remained.

### Distinguishing Evidence

- Initial TDD skeleton red baseline: `51 runs, 797 assertions, 10 failures`.
- Focused mapped implementation batch: `110 runs, 7882 assertions, 0 failures`.
- Full Ruby suite after hosted fix: `1483 runs, 17939 assertions, 0 failures, 41 skips`.
- Full lint: `362 files inspected, no offenses`.
- Package verification produced `dist/su_mcp-1.11.0.rbz`.
- Contract stability passed: `16 runs, 6647 assertions, 0 failures`.
- Security scan reported `0` findings.
- Hosted MTA-38 replay against the MTA-40 final baseline captured `18` rows with `15 policy_applied`,
  `3 neutral`, and `0 regressed` verdicts.
- Final hosted replay artifacts are
  `feature_aware_adaptive_baseline_results_mta45_coalesced.json` and
  `feature_aware_adaptive_baseline_results_mta45_coalesced_annotated.json`.
- Hosted performance recapture is retained in
  `feature_aware_adaptive_baseline_results_mta45_perf_summary.json`. Raw per-run hosted JSONs were
  pruned after summary generation; the summary embeds the per-run timing values.
- Three-run hosted performance versus the MTA-40 final performance summary: command total runs were
  `77.7084s`, `78.5265s`, and `79.1140s`; mean command total was `78.4496s`, `-14.9%` versus the
  MTA-40 mean of `92.1928s`; mean harness quality total was `15.5895s`, `-11.3%` versus MTA-40; all
  `18` rows had stable face/vertex counts and `0/18` rows exceeded the `25%` timing-regression
  threshold.
- The same retained performance summary also records direct three-run hosted performance versus the
  original reusable baseline repeat captures. The original baseline command total runs were
  `85.1113s`, `85.2140s`, and `87.3607s`; MTA-45 averaged `78.4496s` versus the original baseline
  mean of `85.8953s`, a `-8.7%` change. `0/18` rows exceeded the `25%` threshold versus that
  original baseline. The MTA-45 planar rows reduced faces and timing versus the original baseline.
- Right-side scene placement passed: replay terrains remained at `x=320.0m..344.0m`,
  `x=420.0m..453.45m`, and `x=465.0m..499.38m`.
- Final planar replay rows retained `100%` planar-region quality. `planar-pad-intersect` had face
  delta `-28` and planned planar interior `32` faces; `large-varied-planar-pad-timing` had face
  delta `-666` and planned planar interior `212` faces.
- Additional live visual probes remained visible at `x >= 50m`: the circle-pressure no-falloff
  proof at `x=560.0m..572.0m`, and the authoritative replay-fixture falloff proof
  `mta45-large-corridor-planar-falloff-live` at `x=620.0m..653.45m`. The replay-fixture sequence
  created the large complicated terrain, applied the local target and diagonal corridor edits, then
  applied the final planar pad with `1.5m` smooth falloff; the final mesh had `67339` faces and
  centroid counts of `592` in the planar rectangle and `5781` in the planar-plus-falloff envelope.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

### Inflation Check

- Validation exceeded repo baseline because hosted visual inspection found a real underimplementation
  and forced another production slice plus redeploy/replay.
- Validation burden reaches `4` because live evidence changed the implementation after local
  closeout, even though it did not require a revert.
- Rework is high because pressure clipping was insufficient; emitted planar-core compaction had to
  be added through feature geometry and output planning.
- Scope volatility was real but bounded: public circle-pressure clipping became required, while the
  task's core planar-compaction outcome stayed unchanged.

### Underestimated

- The plan underweighted public circle-pressure inputs for `target_height`,
  `survey_point_constraint`, and `local_fairing`; exact circular arc geometry was still unnecessary,
  but effective-bound subtraction had to become part of the accepted rectangular occlusion path.
- The plan also underweighted the emitted-topology layer. Suppressing older pressure was necessary
  but not sufficient; no-falloff planar interiors needed an explicit coalescing path.

### Overestimated

- The feared estimate breaker did not occur: rectangular pressure, circle-pressure effective bounds,
  and reference segment clipping were implementable inside `TerrainFeatureGeometryBuilder` without a
  broader geometry library, output mesh surgery, or public contract change.
- The hosted visual check, not code review, was the material rework driver.

### Future Analog Lesson

- For feature-aware terrain output tasks, public feature shapes should be enumerated before accepting
  a fallback limitation. Circle region support can often be handled by policy-effective bounds if
  the downstream policy already operates on effective rectangular extents.
- Planned-cell metrics are acceptable as internal replay evidence when live emitted-face
  classification is unavailable, but they must be paired with live visual/centroid face-count probes
  when the acceptance criterion is visible planar compactness.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:performance-sensitive`
- `scope:managed-terrain`
- `systems:command-layer`
- `systems:terrain-kernel`
- `systems:terrain-output`
- `systems:validation-service`
- `validation:contract`
- `validation:hosted-matrix`
- `host:single-fix-loop`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `friction:high`
- `volatility:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
