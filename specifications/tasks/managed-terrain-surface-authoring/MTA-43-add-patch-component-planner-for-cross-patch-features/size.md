# Size: MTA-43 Add Patch Component Planner For Cross-Patch Features

**Task ID**: MTA-43  
**Title**: Add Patch Component Planner For Cross-Patch Features  
**Status**: calibrated
**Created**: 2026-05-15  
**Last Updated**: 2026-05-25

**Related Task**: [task.md](./task.md)  
**Related Plan**: none yet  
**Related Summary**: [summary.md](./summary.md)

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:performance-sensitive`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:validation-service`
  - `systems:managed-object-metadata`
- **Validation Modes**:
  - `validation:hosted-matrix`
  - `validation:performance`
  - `validation:persistence`
  - `validation:regression`
- **Likely Analog Class**: MTA-36 dirty-window patch lifecycle with stronger cross-patch planning pressure

### Identity Notes
- Seeded as the bounded-promotion task. The core risk is preserving local edit economics while allowing required cross-patch correctness.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds cross-patch feature correctness while preserving bounded edits. |
| Technical Change Surface | 3 | Likely spans planning graph, patch roles, promotion/refusal, diagnostics, and validation. |
| Hidden Complexity Suspicion | 4 | Component promotion can accidentally broaden edits or undermine no-delete behavior. |
| Validation Burden Suspicion | 4 | Needs hosted matrices for local, adjacent, cross-patch, over-budget, timing, face count, and readback cases. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-42 seam contracts and MTA-36 lifecycle semantics. |
| Scope Volatility Suspicion | 3 | Planning may need to narrow patch roles or promotion policies. |
| Confidence | 2 | Direction is clear, but component budgets and row design need technical planning. |

### Early Signals
- Directly threatens dirty-window/local-edit performance if poorly scoped.
- Must record component size and patch roles in evidence.
- Blocks sparse local detail.

### Early Estimate Notes
- Seed only. Do not treat this as the predicted implementation estimate.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

| Dimension | Prediction (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Delivers real component promotion/fallback behavior for dirty adaptive output, but remains inside the managed-terrain adaptive path with no public contract change. |
| Technical Change Surface | 4 | Spans PatchLifecycle planning, `TerrainOutputPlan`, feature patch bundles, command evidence, mesh mutation/fallback, registry semantics, replay/result/classifier artifacts, and contract no-leak tests. |
| Implementation Friction | 3 | Main friction is removing successful-path resolver recomputes while preserving current local behavior, full fallback semantics, seam gates, and MTA-46 residual-probe reuse. |
| Validation Burden | 3 | Requires more than routine closeout: targeted hosted rows for promotion, seam behavior, over-budget full fallback, readback, and timing comparison, plus replay classifier updates. Not scored 4 unless hosted/perf loops dominate execution. |
| Dependency / Coordination Drag | 3 | Depends on MTA-36 lifecycle, MTA-38 replay harness, MTA-40 feature pressure, MTA-42 seam metadata, MTA-46 residual guard, and live SketchUp validation access. |
| Discovery / Ambiguity | 3 | First bounded component-promotion task; retained-Z remains gated and exact planner/mutation integration may expose implementation seams. Core scope is now bounded by the draft plan. |
| Scope Volatility | 2 | Planning already corrected refusal to full fallback and deferred local detail/CDT/native. Further volatility should be contained unless retained seam or fallback behavior proves incompatible. |
| Rework Pressure | 2 | Some revisiting of current resolver/evidence/mutation paths is expected, but the plan sequences this deliberately. Higher rework only if emitted topology contradicts component metadata. |
| Confidence | 2 | Moderate confidence: plan is specific and analog-informed, but implementation and hosted evidence remain required for the highest-risk behaviors. |

### Analog Brief

- MTA-36 is the closest lifecycle analog: actual work showed patch ownership and no-delete behavior
  can require structural correction and hosted performance evidence.
- MTA-42 is the closest seam analog: it delivered a narrower seam foundation and deferred direct
  promotion/fallback/retained-Z hard gating, so MTA-43 must not treat those as baseline.
- MTA-38 is the evidence analog: replay/result artifacts and hosted timing can add meaningful
  closeout burden even without public contract changes.
- MTA-40/MTA-45 show feature-pressure and emitted-topology evidence can overturn plausible internal
  policy assumptions; MTA-43 must prove emitted output, not only component metadata.
- No calibrated analog exists for arbitrary bounded cross-patch component promotion itself.

### Top Assumptions

- The existing full adaptive generation path is safe to reuse as the over-budget component fallback
  for valid heightmaps.
- The component planner can be introduced as derived planning metadata without changing public MCP
  command shapes.
- Retained seam topology/digest promotion-or-refusal is enough for MTA-43 if retained-Z remains
  explicitly gated by hosted/post-emit evidence.
- The replay harness can be extended without rebuilding the corpus format from scratch.

### Estimate Breakers

- Hosted validation shows over-budget full fallback erases output before replacement is safely
  planned, or breaks registry/readback.
- Retained seam behavior requires z-inclusive pre-erase hard gating rather than the planned
  hosted/post-emit evidence gate.
- Removing resolver recomputes forces a broad redesign of `TerrainOutputPlan` or mesh generator
  planning beyond the sealed-resolution carrier.
- Expected bounded promotion or fallback cannot be represented cleanly in replay/classifier
  artifacts without larger harness changes.

### Predicted Notes

- Treat contract drift as a breaker: any new public refusal code or response field requires catalog,
  dispatcher, fixtures, docs, and examples to move together.
- Validation Burden may become 4 only if hosted seam/fallback/performance loops repeatedly block
  closeout or force redesign.
- Confidence should increase only after pure planner, integration, no-leak, hosted replay/readback,
  and timing evidence all align with the draft plan.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

### Confirmed Drivers

- Premortem confirmed the dominant drivers: sealed-resolution drift, over-budget fallback ordering,
  retained seam ordering, public no-leak behavior, and hosted validation/readback.
- Technical Change Surface `4` remains justified because the finalized plan spans PatchLifecycle,
  output planning, command evidence, feature bundles, mesh mutation/fallback, replay/result
  artifacts, classifier behavior, and contract no-leak coverage.
- Validation Burden `3` remains justified as extra work beyond routine closeout because MTA-43 needs
  targeted hosted rows for promotion, retained seam behavior, over-budget full fallback, readback,
  and timing interpretation.
- Confidence `2` remains appropriate because the plan is specific, but the high-risk behavior is
  not proven until implementation and hosted evidence land.

### Contested Drivers / Missing Evidence

- Validation could become `4` if hosted fallback/seam/performance loops repeatedly block closeout,
  but the premortem converted the main failure paths into testable guardrails rather than evidence
  of inevitable validation domination.
- Scope Volatility stays `2`: planning already corrected the major behavior choice from budget
  refusal to full adaptive fallback. Further volatility depends on implementation evidence, not
  current planning ambiguity.
- Rework Pressure stays `2`: the plan intentionally revisits resolver ownership and mutation
  routing, but no completed implementation has been shown wrong yet.

### Score Changes

- None.

### Recommendation

- Proceed with the finalized plan as a high-risk, challenged estimate.
- Treat the premortem guardrails as implementation blockers: no successful-path resolver recompute,
  no dirty erase before over-budget full fallback, and no non-empty local-detail source behavior.
  Record drift only if implementation breaks these assumptions or hosted validation forces a
  redesign.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

No material drift recorded yet.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

| Dimension | Actual (0-4) | Evidence Notes |
|---|---:|---|
| Functional Scope | 3 | Delivered real bounded component planning, sealed lifecycle ownership, over-budget verdict behavior, replay/classifier evidence, and promoted-patch replacement proof without public contract changes. |
| Technical Change Surface | 4 | Cross-cut PatchLifecycle, `TerrainOutputPlan`, command evidence, feature patch batching, mesh mutation, registry/readback, replay artifacts, classifier behavior, no-leak contracts, and hosted performance evidence. |
| Actual Implementation Friction | 3 | Work followed the broad plan, but Step 6 exposed two meaningful corrections: over-budget had been implemented as forced full adaptive fallback, and the replay corpus did not actually prove expanded replacement mutation. |
| Actual Validation Burden | 3 | Exceeded repo baseline through external review follow-up, hosted checks, a material fix/reload/retest loop, targeted promoted-patch proof, and a fresh packaged three-pass performance rerun. Not `4`: validation did not force redesign/revert or repeated unstable blocker loops. |
| Actual Dependency Drag | 3 | Relied on MTA-36 lifecycle, MTA-38 evidence, MTA-40 feature pressure, MTA-42 seam behavior, MTA-46 residual assumptions, and active SketchUp hosted access. |
| Actual Discovery Encountered | 3 | Discovery materially changed confidence: the planned over-budget fallback interpretation was wrong, and replay promotion metadata did not imply actual extra patch regeneration. Both required evidence-backed correction. |
| Actual Scope Volatility | 1 | Task boundary stayed stable; corrections returned implementation to MTA-43's intended bounded component behavior rather than adding a new acceptance target. |
| Actual Rework | 3 | Meaningful revisiting occurred after apparently green work: removed forced full adaptive fallback, separated over-budget from actual fallback evidence, strengthened mutation tests, and added targeted hosted proof. |
| Final Confidence in Completeness | 3 | Strong automated, review, package, and hosted evidence exists; confidence is not 4 because hosted retained-seam mismatch/no-delete and retained-Z hard gating remain explicit gaps. |
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

Validation classification: expanded hosted/performance matrix with one material correction loop and
a targeted hosted proof.

- Full Ruby suite, lint, package verification, focused integration tests, and `git diff --check`
  passed after final fixes.
- PAL `grok-4.3` review completed; accepted findings were fixed and rerun through focused and broad
  validation.
- Hosted SketchUp rows covered local no-promotion, cross feature/protected promotion, over-budget
  bounded replacement, repeated edit/readback, public no-leak checks, timing buckets, seam
  summaries, and owner-level registry/readback.
- A targeted hosted proof compared legacy dirty scope (`9` patches) to MTA-43 component scope
  (`12` patches), proving the `3` extra promoted patches were actually regenerated while an
  outside patch remained untouched.
- A fresh packaged three-pass performance capture ended effectively neutral against MTA-42/MTA-46:
  mean `78.291227s`, `0` refused rows, `15` component rows, `6` over-budget rows,
  `0.028851s` mean component planning, `7.366014s` mean adaptive planning.
- Retained seam mismatch/no-delete live forcing and retained-Z hard pre-erase gating remain
  recorded gaps rather than hidden validation.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

### Inflation Check

- Validation did exceed repo baseline because hosted evidence found one real underimplementation and
  required fix/reload/retest, targeted promoted-patch proof, and fresh packaged perf capture. It did
  not dominate delivery or force redesign/revert, so it stays `3`, not `4`.
- Rework was meaningful after apparent green state, but it was localized to over-budget routing,
  replay/classifier evidence, and mutation proof rather than a broad rewrite.
- Scope did not materially change; the implementation returned to the finalized plan's bounded
  component intent rather than adding a new acceptance target.
- No `4` actual score is used except Technical Change Surface, where breadth across runtime,
  evidence, mutation, registry, and contract surfaces was the dominant driver.
- Confidence is capped at `3` because retained seam mismatch/no-delete and retained-Z hard gating
  are not fully hosted-proven.

### Underestimated

- The hardest risk was not the pure component graph; it was proving that one sealed lifecycle
  resolution affected real mutation, not only internal metadata.
- The replay corpus was insufficiently shaped for the core promotion claim: it recorded promoted
  counts, but its replacement envelopes were already broad enough that no row proved additional
  patch regeneration over the legacy dirty resolver.
- The over-budget planning language was ambiguous. "Do not reject a valid mesh" was implemented as
  forced full adaptive fallback at first, but the correct behavior is bounded dirty replacement when
  ownership, registry, and seam checks are safe.

### Overestimated

- The sealed-resolution carrier avoided a broader `TerrainOutputPlan` or mesh generator redesign.
- Full adaptive fallback was not needed for over-budget component scope and was actively harmful to
  performance evidence.
- Fresh packaged performance was effectively neutral against MTA-42/MTA-46 once forced full
  fallback was removed.

### Future Analog Lesson

For future managed-terrain component, seam, or sparse-local-detail tasks, estimate the pure planner
as the smaller slice. The dominant risk is proving the public command, evidence, mutation routing,
registry/readback, and hosted replay rows all observe the same sealed lifecycle resolution. Replay
metadata is not enough; include at least one fixture where new planning increases actual mutation
scope over the legacy path.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:performance-sensitive`
- `scope:managed-terrain`
- `systems:command-layer`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:terrain-repository`
- `validation:hosted-matrix`
- `validation:performance`
- `host:single-fix-loop`
- `contract:no-public-shape-change`
- `risk:partial-state`
- `risk:performance-scaling`
- `rework:medium`
- `confidence:high`
<!-- SIZE:TAGS:END -->
