# Size: MTA-42 Upgrade Adaptive Seam Contracts For Feature-Driven Splits

**Task ID**: MTA-42
**Title**: Upgrade Adaptive Seam Contracts For Feature-Driven Splits
**Status**: calibrated
**Created**: 2026-05-15
**Last Updated**: 2026-05-22

**Related Task**: [task.md](./task.md)
**Related Plan**: [plan.md](./plan.md)
**Related Summary**: [summary.md](./summary.md)

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:validation-heavy`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:managed-object-metadata`
  - `systems:public-contract`
  - `systems:validation-service`
- **Validation Modes**:
  - `validation:contract`
  - `validation:hosted-matrix`
  - `validation:performance`
  - `validation:persistence`
  - `validation:regression`
- **Likely Analog Class**: MTA-36 adaptive patch lifecycle, but with higher seam/topology validation pressure

### Identity Notes
- Refined as adaptive patch/cell seam-contract work, not CDT and not MTA-43 component planning.
- Public contracts should remain unchanged, but no-leak contract coverage is material.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Enables feature-driven splits to remain valid across patch boundaries. |
| Technical Change Surface | 3 | Likely touches seam planning, retained spans, metadata/digests, validation, and mutation safety. |
| Hidden Complexity Suspicion | 4 | Seam bugs can create cracks, T-junctions, ownership ambiguity, or invalid retained boundaries. |
| Validation Burden Suspicion | 4 | Requires seam-sensitive hosted rows, persistence/readback, performance, and no-delete evidence. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-36/MTA-38/MTA-39/MTA-40 behavior and hosted replay access. |
| Scope Volatility Suspicion | 2 | Planning narrowed the task to direct-neighbor promotion and explicit non-CDT boundaries, but MTA-43 drift remains a risk. |
| Confidence | 2 | Draft plan is bounded, but hosted/no-delete fallback proof remains implementation-sensitive. |

### Early Signals
- High-risk boundary correctness task.
- Retained neighbor spans and promotion/refusal decisions are central.
- Valid heightmap create/edit mesh generation must remain intact.
- Blocks component planning and local detail, but does not implement them.

### Early Estimate Notes
- Seed refreshed before prediction to reflect the non-CDT, direct-neighbor-only plan.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a multi-step internal seam contract workflow while preserving public create/edit behavior. |
| Technical Change Surface | 3 | Touches adaptive output planning, registry metadata, generator mutation gates, replay evidence, and contract tests. |
| Implementation Friction Risk | 3 | Sealed plan handoff, safe fallback sequencing, and promotion stop rules can force structural correction. |
| Validation Burden Risk | 3 | Requires expanded seam-sensitive hosted rows, no-delete/fallback proof, persistence/readback, and timing/face-count evidence beyond routine closeout. |
| Dependency / Coordination Risk | 3 | Sequenced on MTA-36/MTA-38/MTA-39/MTA-40 behavior and hosted SketchUp replay availability. |
| Discovery / Ambiguity Risk | 2 | Major choices are planned, but fallback rollback proof and host/readback tolerance can still expose implementation facts. |
| Scope Volatility Risk | 2 | Boundaries are explicit, but pressure to drift into MTA-43 component planning remains credible. |
| Rework Risk | 3 | Hosted seam/no-delete evidence may reveal geometry or mutation sequencing corrections after local tests pass. |
| Confidence | 2 | Premortem closed the main design gaps, but required hosted proof and fallback mechanics are not yet observed. |

### Analog Brief

- MTA-36 is the closest lifecycle analog: single-mesh logical patch ownership, dirty replacement, registry/readback, no-delete behavior, and hosted validation all matter here.
- MTA-38 is the closest harness analog: evidence capture and result classification can cost more than pure implementation.
- MTA-40 is the closest topology-affecting predecessor: hosted checks exposed conformance behavior not fully covered by local tests.
- MTA-45 is a useful recent output-topology warning: local policy changes were not enough until hosted/visual evidence forced refinement.
- No calibrated analog exactly covers deterministic seam digest plus retained-neighbor validation; prediction combines MTA-36 lifecycle risk with MTA-40/MTA-45 topology-validation risk.

### Top Assumptions

- Existing adaptive conformity output can provide enough ordered boundary material for seam records without replacing the adaptive path.
- Full rebuild fallback can be made safe through pre-erase planning plus abortable SketchUp mutation, or can refuse before mutation when not proven.
- Registry seam metadata can remain compact while retaining losslessly reconstructable canonical positions.
- Hosted replay rows can be added to the MTA-38 harness without building a separate validation system.

### Estimate Breakers

- Full rebuild fallback cannot be made no-delete without a larger generator staging refactor.
- Retained-neighbor validation needs live geometry reconstruction rather than registry seam records as source of truth.
- Direct-neighbor promotion proves insufficient for common valid heightmap edits, forcing early MTA-43 component planning.
- Hosted rows reveal frequent fallback/performance regressions or host/readback tolerance instability.

### Predicted Notes

- Validation is scored above baseline because this task needs seam-sensitive hosted evidence, fallback/no-delete proof, persistence/readback, and performance comparison, not merely routine live smoke.
- Rework risk is high because the most likely defects appear at the boundary between pure planned geometry and live SketchUp mutation.
- Confidence remains moderate after premortem because fallback safety, post-mutation seam verification, and hosted rows still need implementation evidence.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

### Confirmed Drivers

- Functional Scope `3`, Technical Change Surface `3`, and Implementation Friction `3` still fit the finalized plan: the task is internal but spans adaptive planning, registry metadata, generator mutation, replay evidence, and no-leak contracts.
- Validation Burden `3` is justified by extra hosted seam rows, fallback/no-delete proof, persistence/readback, and timing/face-count interpretation beyond routine closeout.
- Rework Risk `3` remains justified because the premortem added post-mutation retained seam verification and a hard two-stage fallback precondition, both of which can expose generator sequencing corrections.

### Contested Drivers / Missing Evidence

- The main uncertainty is not public contract breadth; it is whether two-stage full rebuild fallback can be proven without a larger generator staging refactor.
- Hosted evidence may show common promoted-patch outer-boundary exhaustion, which would pressure scope toward MTA-43 but should remain outside MTA-42 unless the task boundary is deliberately reopened.
- Confidence cannot rise until implementation proves post-mutation seam verification can run before operation commit and abort cleanly.

### Score Changes

- None. Premortem findings sharpened the guardrails but did not change the predicted size profile.

### Recommendation

- Proceed with the finalized plan. Treat fallback safety, post-mutation retained seam verification, and promotion-exhaustion frequency as the first implementation drift checkpoints.
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
| Functional Scope | 2 | Shipped an internal seam-contract, registry, refusal-gate, replay-evidence slice. It did not ship direct-neighbor promotion, safe full-rebuild fallback, or pre-erase retained-Z hard gating. |
| Technical Change Surface | 3 | Touched adaptive output planning, generator mutation gating, patch registry metadata, replay/result artifacts, classifier behavior, and no-leak contract tests. |
| Actual Implementation Friction | 2 | Several contained adjustments were needed around retained Z handling, evidence wiring, and dead helper cleanup, but no redesign or abandoned implementation direction occurred. |
| Actual Validation Burden | 3 | Exceeded baseline closeout through live SketchUp reload/replay, negative no-delete seam smoke, and a clean serialized three-run performance pack after invalid/contaminated perf captures were removed. |
| Actual Dependency Drag | 2 | Depended on MTA-36/MTA-38/MTA-40 behavior and live SketchUp deployment/reload access, but dependencies did not block implementation once hosted checks were available. |
| Actual Discovery Encountered | 2 | Closeout clarified that MTA-42's realized business value is seam safety/evidence foundation, not the full promotion planner originally envisioned in the plan. |
| Actual Scope Volatility | 2 | The accepted implementation closed as a narrower seam metadata and pre-mutation guard slice; planned direct-neighbor promotion, full fallback, and retained-Z hard gates remain future work, but the task did not become a different kind of task. |
| Actual Rework | 2 | Review/live/perf follow-up caused localized cleanup and reruns, including removing an unused validator helper and rerunning clean perf, but no broad code rewrite. |
| Final Confidence in Completeness | 3 | Strong evidence for the shipped slice: full tests, scoped lint, package verify, PAL review, hosted replay, no-delete smoke, and perf pack. Confidence is not `4` because downstream promotion/Z-hard-gate gaps remain explicit. |
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

Validation classification: expanded matrix/special hosted closeout.

Distinguishing evidence:

- Final full Ruby suite passed: `1518 runs, 19272 assertions, 0 failures, 0 errors, 41 skips`.
- Final MTA-42 scoped RuboCop passed across `18` changed-source/test files; full-repo RuboCop is currently blocked by unrelated untracked `procedural_terrain_planting_mass.rb` namespace/offense pollution.
- Package verification passed and produced `dist/su_mcp-1.11.0.rbz`; `git diff --check` passed.
- `tldr secure src/su_mcp/terrain` reported `0` findings.
- PAL codereview with `model: "grok-4.3"` found no blocking or non-blocking issues after local inspection.
- Hosted replay after live reload: `18` rows, `0` refusals, `18` seam evidence rows, `0` seam failures, `maxZGap: 0.0`, and classifier output `15 policy_applied / 3 neutral / 0 failed`.
- Live negative no-delete smoke corrupted retained seam digests before partial edit; command refused with `terrain_output_ownership_invalid` and preserved face count `76191 -> 76191`.
- Clean three-run hosted performance pack after fresh restart/deploy averaged `79.396059s` command time versus MTA-45 `78.4496s` (`+1.2%`), with stable face/vertex counts and no row over the `25%` timing threshold.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

### Inflation Check

- Validation exceeded repo baseline because the task required hosted replay evidence, a targeted no-delete negative smoke, and a clean three-run performance comparison after invalid captures were removed.
- Rework was localized review/live/perf cleanup, not redesign-level churn.
- Scope changed materially from the plan: the completed slice is a seam-contract/guard/evidence foundation, while promotion, full fallback, and retained-Z hard gating remain explicit gaps.
- No `4` score is justified: validation and scope discussion were material, but they did not dominate delivery through repeated blockers, revert, or redesign.
- Confidence is strong for the shipped slice and reduced only for the planned-but-unshipped downstream behaviors.

### Underestimated

- Scope volatility was moderately underweighted. The plan assumed direct-neighbor promotion and full fallback could fit inside MTA-42, but the effective closeout stopped at metadata, pre-erase retained validation, no-delete refusal, and evidence plumbing.
- Validation interpretation was underweighted. Performance captures needed contamination checks and a clean three-run rerun before the result was usable.

### Overestimated

- Implementation friction was slightly overestimated. The seam metadata and retained-validation slice integrated without a large generator staging refactor.
- Dependency drag was not as severe as predicted once live SketchUp reload/check access was available.

### Future Analog Lesson

For feature-aware terrain topology tasks, estimate the seam-safety/evidence foundation separately from promotion/fallback planners. A task can materially improve safety by preventing silent one-sided mutation while still leaving the higher-value cross-patch promotion behavior to the next task.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:validation-heavy`
- `scope:managed-terrain`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:managed-object-metadata`
- `validation:hosted-matrix`
- `validation:performance`
- `validation:persistence`
- `risk:partial-state`
- `risk:metadata-storage`
- `contract:no-public-shape-change`
- `volatility:medium`
- `confidence:high`
<!-- SIZE:TAGS:END -->
