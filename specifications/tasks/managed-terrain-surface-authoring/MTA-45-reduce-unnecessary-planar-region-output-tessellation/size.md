# Size: MTA-45 Reduce Unnecessary Planar Region Output Tessellation

**Task ID**: MTA-45  
**Title**: Reduce Unnecessary Planar Region Output Tessellation  
**Status**: challenged  
**Created**: 2026-05-17  
**Last Updated**: 2026-05-18  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: none yet  

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

No material drift recorded yet.
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

- `archetype:performance-sensitive`
- `scope:managed-terrain`
- `systems:terrain-kernel`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:validation-service`
- `systems:managed-object-metadata`
- `validation:hosted-matrix`
- `validation:performance`
- `validation:persistence`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `risk:partial-state`
- `volatility:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
