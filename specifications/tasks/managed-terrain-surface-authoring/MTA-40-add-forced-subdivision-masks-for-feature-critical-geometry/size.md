# Size: MTA-40 Add Forced Subdivision Masks For Feature-Critical Geometry

**Task ID**: MTA-40
**Title**: Add Forced Subdivision Masks For Feature-Critical Geometry
**Status**: calibrated
**Created**: 2026-05-15
**Last Updated**: 2026-05-17

**Related Task**: [task.md](./task.md)
**Related Plan**: [plan.md](./plan.md)
**Related Summary**: [summary.md](./summary.md)

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:validation-heavy`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-state`
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:validation-service`
- **Validation Modes**:
  - `validation:hosted-matrix`
  - `validation:performance`
  - `validation:regression`
  - `validation:contract`
- **Likely Analog Class**: MTA-36 lifecycle with stronger feature-topology validation; MTA-20 feature intent as source context

### Identity Notes
- Seeded as the first topology-affecting feature-aware adaptive task.
- Existing hard-feature edit/state refusals remain, but disposable mesh generation from valid terrain heightmaps must degrade unsupported masks to fallback output rather than becoming a new refusal point.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Moves from feature-guided density to supported feature-critical topology pressure. |
| Technical Change Surface | 3 | Likely touches masks, adaptive split decisions, validation summaries, and output fallback routing. |
| Hidden Complexity Suspicion | 3 | Risk comes from feature geometry edge cases and distinguishing height correctness from topology correctness. |
| Validation Burden Suspicion | 3 | Requires hosted rows for supported masks, valid-heightmap mask fallback, existing hard edit refusal, no-delete, timing, and face count. |
| Dependency / Coordination Suspicion | 2 | Hard dependency on MTA-39 and the MTA-38 harness. |
| Scope Volatility Suspicion | 3 | Supported feature geometry boundary may need narrowing during technical planning. |
| Confidence | 2 | Architecture direction is clear; exact mask policy and edit-vs-output fallback boundary remain to plan. |

### Early Signals
- First major topology-affecting slice.
- Unsupported output masks must degrade safely without blocking disposable mesh generation from valid heightmaps.
- Existing hard-feature edit/state refusals remain part of the terrain validity boundary.
- Later seam work depends on this behavior being explicit.

### Early Estimate Notes
- Seed only. Do not treat this as the predicted implementation estimate.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

| Dimension | Predicted (0-4) | Rationale |
|---|---:|---|
| Functional Scope | 3 | Adds the first production forced-subdivision topology pressure for supported feature-critical geometry while preserving public workflows. |
| Technical Change Surface | 3 | Touches feature-view readiness, derived geometry/mask classification, adaptive policy, output-plan split integration, command fallback/no-leak behavior, replay evidence, and hosted validation. |
| Implementation Friction Risk | 3 | The core algorithm is bounded, but feature-view correctness, corridor boundary handling, separate forced-vs-density pressure, and output fallback boundaries can resist naive implementation. |
| Validation Burden Risk | 3 | Requires focused unit/integration/contract coverage plus hosted rows for supported masks, valid-heightmap unsupported-mask fallback, existing hard refusal preservation, corridor quality, timing, face count, dirty scope, and patch scope. This is above routine smoke but not yet assumed blocker-heavy. |
| Dependency / Coordination Risk | 2 | Depends on MTA-39 policy, MTA-38 replay harness, MTA-36 PatchLifecycle, and MTA-31/MTA-33 feature view behavior, all in-repo and already implemented. |
| Discovery / Ambiguity Risk | 2 | Major planning ambiguities are resolved. Remaining uncertainty is tactical helper shape, exact constants, fixture construction, and hosted interpretation. |
| Scope Volatility Risk | 2 | Scope is bounded by explicit exclusions: no exact breaklines, broad corridor densification, CDT, seam upgrades, public contracts, or forensic diagnostics. Volatility rises only if feature-view readiness exposes a direct supported-mask blocker. |
| Rework Risk | 3 | Likely rework centers on mask intersection rules, corridor proof, compact result summaries, and hosted dirty-scope/timing interpretation if early tests overfit simple cases. |
| Confidence | 3 | Plan is specific, analog-backed, and matrix-shaped, but confidence remains below high until hosted lifecycle/corridor evidence exists. |

### Analog Brief

- MTA-39 is the closest implementation analog: same adaptive policy/output-plan seam and replay
  evidence path. Its corridor broad-density reversal is a direct warning for MTA-40.
- MTA-38 is the validation analog: reusable hosted replay/result infrastructure exists, but row
  verdict interpretation and repeatable evidence remain meaningful work.
- MTA-36 is the lifecycle analog: local tests are insufficient for no-delete replacement,
  registry/readback, and hosted SketchUp lifecycle confidence.
- MTA-33 is the feature-view analog: hard/protected selection can be subtle; no-leak and
  patch-relevant feature handoff need explicit proof.
- MTA-31 and MTA-24/CDT evidence are negative scope guards: use feature geometry plumbing where
  useful, but do not switch this task to CDT or exact constrained topology.

### Top Assumptions

- A small internal forced-mask input view can be derived from existing `TerrainFeatureGeometry`
  without durable state or public contract changes.
- Supported point, rectangle/circle boundary, and corridor side/cap/falloff intersection rules can
  be deterministic and cheap enough for recursive adaptive planning.
- Feature-view readiness can be handled with targeted fixes for supported mask correctness rather
  than broad lifecycle/schema redesign.
- Compact counters and replay summaries are enough to validate behavior without forensic traces.

### Estimate Breakers

- Feature intent/effective-view handoff is inaccurate for supported masks and requires broad
  lifecycle, schema, or authoring redesign.
- Segment/corridor mask rules cannot be made useful without exact edge alignment, diagonal
  optimization, seam work, or CDT.
- Forced masks expand dirty-window or patch scope beyond command-selected output domains.
- Unsupported mask inputs cause public refusals or block valid-heightmap disposable mesh output.
- Hosted validation shows unacceptable face-count/timing growth or no-delete/registry/readback
  regressions.

### Predicted Notes

- Validation risk is scored `3` because hosted matrix and corridor-specific quality proof are core
  completion evidence, but repeated blocker-heavy fix loops are not assumed before execution.
- Rework risk is scored `3` because MTA-39 showed policy quality can require reinterpreting or
  reverting apparently plausible feature pressure.
- Confidence is `3` because Step 06 resolved architecture, supported scope, fallback boundary,
  diagnostics, dirty scope, and TDD sequencing; hosted behavior remains the main unknown.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

### Confirmed Drivers

- Functional Scope `3` remains appropriate: the task adds production topology pressure for
  supported feature-critical geometry, but avoids public workflow changes, exact topology, CDT, seam
  work, and public contract deltas.
- Technical Change Surface `3` remains appropriate: the work crosses feature view, derived mask
  inputs, adaptive policy, output planning, command fallback/no-leak behavior, replay summaries, and
  hosted validation, but stays within existing managed-terrain runtime layers.
- Validation Burden Risk `3` remains appropriate: hosted fallback, corridor quality, dirty-scope,
  timing, face-count, and readback evidence are required. This is more than routine smoke, but
  challenge evidence does not yet show repeated blockers or validation-dominated redesign.
- Rework Risk `3` remains appropriate because MTA-39 showed plausible feature-pressure behavior can
  require reinterpretation or reversal, especially around corridors.

### Contested Drivers / Missing Evidence

- Phase 0 feature-view readiness is the main contested dependency. If saved post-merge feature
  state, effective selection, patch relevance, or coordinate windows are wrong for supported masks,
  MTA-40 could need broader feature-view repair than predicted.
- Corridor quality remains a contested validation burden. The plan now requires corridor-specific
  planarity, width, interpolation, low-interior-face, boundary-detail, dirty-scope, and timing proof,
  but those metrics are not implemented yet.
- Hosted lifecycle evidence remains missing. Save/reopen or equivalent readback proof is required
  where practical, and any unrun portion must be called out as a closeout gap.
- Compact counters may still be insufficient for replay verdicts. If verdicts require richer
  evidence, the implementation must avoid drifting into forensic traces or public response changes.

### Score Changes

- No predicted score changes.
- The premortem sharpened validation gates but did not add a new public surface, new backend, exact
  topology claim, or new durable state model.

### Recommendation

Proceed with implementation from the finalized plan. Record size drift during implementation if any
of these estimate breakers occur: feature-view readiness requires broad lifecycle/schema redesign,
segment/corridor masks require exact topology or CDT, hosted validation enters repeated fix/redeploy
loops, unsupported masks cause valid-heightmap output refusals, dirty scope expands unexpectedly, or
compact summaries are insufficient without forensic/public evidence.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

No material drift recorded yet.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

| Dimension | Actual (0-4) | Evidence |
|---|---:|---|
| Functional Scope | 3 | Shipped production forced-subdivision pressure for supported anchors, protected boundaries, and corridor detail while preserving public terrain contracts. |
| Technical Change Surface | 3 | Changed feature geometry/policy, adaptive split planning, mesh conformance behavior, replay quality/result evidence, classifier logic, and focused contract no-leak coverage. |
| Actual Implementation Friction | 3 | Core mask rollout was bounded, but live planar-pressure behavior, coplanar fan collapse, and policy-planning cost required meaningful corrections before closeout. |
| Actual Validation Burden | 4 | Validation exceeded routine hosted matrix closeout: live checks found a planar-density bug, required deploy/reload/rerun loops, added planar-specific checks, and triggered a three-run performance recapture after optimization. |
| Actual Dependency Drag | 2 | Work depended on MTA-39 policy, MTA-38 replay harness, MTA-36 PatchLifecycle, and hosted SketchUp access, but no external dependency blocked completion. |
| Actual Discovery Encountered | 3 | Hosted validation exposed that no-falloff planar intent was still creating broad output pressure and that planning-time policy checks were the main timing regression source. |
| Actual Scope Volatility | 2 | The accepted outcome stayed recognizable, but closeout expanded within the same boundary to include planar pressure removal, coplanar conformance fan collapse, and performance caching. |
| Actual Rework | 3 | Previously passing behavior needed revisiting after live checks and timing comparison; fixes affected planar feature geometry, mesh output, classifier behavior, and policy performance. |
| Final Confidence in Completeness | 3 | Local tests, lint, package verification, review, hosted replay, three-run performance recapture, registry/readback, and MTA-39 comparison are strong; save/reopen and true two-triangle planar emission remain explicit gaps. |
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

Execution classification: repeated hosted fix/redeploy/rerun plus performance recapture.

Distinguishing evidence:
- TDD skeletons started red and the focused MTA-40 skeleton batch finished green.
- Full closeout passed `bundle exec rake ruby:test`, `bundle exec rake ruby:lint`, and
  `bundle exec rake package:verify`.
- Hosted replay captured `18` rows with `15 policy_applied`, `3 neutral`, and `0 regressed` against
  the MTA-39 quality baseline after the planar-density and policy-caching fixes.
- Three hosted performance runs averaged `92.1928s` command time with stable face/vertex counts and
  `0/18` rows over the timing threshold.
- Live registry/readback succeeded; separate save/reopen remained unrun and is tracked as a
  confidence gap rather than completed validation burden.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

Underestimated:
- Validation burden was materially higher than predicted. The prediction expected hosted matrix and
  corridor/quality proof, but did not fully price the planar-pressure defect, repeated live reruns,
  timing regression investigation, and three-run performance recapture.
- Discovery was higher than predicted because live output showed planar-region pressure and
  conformance fan behavior that local policy tests alone did not reveal.

Overestimated:
- Dependency drag did not exceed prediction. Existing MTA-38/MTA-39/MTA-36 infrastructure held up,
  and no external coordination or upstream redesign blocked the task.
- Public contract risk was lower than the task shape could have implied; public request/response
  shape stayed unchanged and no-leak coverage was enough.

Future analog lesson:
- For topology-affecting adaptive-output tasks, predicted validation should increase when the task
  can change face counts, dirty scope, or feature precedence in hosted SketchUp. Plan for at least
  one live-discovered geometry-policy correction and one performance comparison loop, even when the
  local policy seam is well tested.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:validation-heavy`
- `scope:managed-terrain`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:validation-service`
- `validation:hosted-matrix`
- `validation:performance`
- `validation:contract`
- `host:repeated-fix-loop`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `volatility:medium`
- `friction:high`
- `rework:high`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
