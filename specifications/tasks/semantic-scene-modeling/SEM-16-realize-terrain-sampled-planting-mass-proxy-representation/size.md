# Size: SEM-16 Realize Terrain-Sampled Planting Mass Proxy Representation

**Task ID**: SEM-16  
**Title**: Realize Terrain-Sampled Planting Mass Proxy Representation  
**Status**: calibrated  
**Created**: 2026-05-22  
**Last Updated**: 2026-05-22  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:feature`
- **Primary Scope Area**: `scope:semantic-scene-modeling`
- **Likely Systems Touched**:
  - `systems:semantic-builders`
  - `systems:semantic-hosting`
  - `systems:scene-query`
  - `systems:surface-sampling`
  - `systems:test-support`
- **Distinguishing Validation / Host Shape**: `validation:hosted-smoke`, `validation:performance`, `host:routine-smoke`, `contract:no-public-shape-change`
- **Likely Analog Class**: hosted semantic proxy generation with reusable generated components

### Identity Notes
- Task combines a behavior upgrade behind an existing public contract with internal generated-component lifecycle work.
- Dominant shape is semantic runtime geometry plus host-sensitive component definitions, sampling, frame orientation, and no-public-shape-drift validation.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Suspicion-level only. Refresh this section before prediction if planning changes task shape.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Upgrades planting proxy behavior, adds contextual hosting support, and componentizes existing tree proxy. |
| Technical Change Surface | 4 | Spans semantic builders, generated component definitions, test fakes, surface sampling/frame reuse, command matrix, and contract checks. |
| Hidden Complexity Suspicion | 3 | SketchUp component definitions, terrain/frame sampling, deterministic procedural geometry, and partial-state refusal paths can hide defects. |
| Validation Burden Suspicion | 3 | Needs focused automated coverage plus hosted checks for definitions, sloped terrain, replacement/undo, and visual quality. |
| Dependency / Coordination Suspicion | 2 | Existing seams are available, but implementation depends on staged-asset frame behavior and hosted SketchUp access. |
| Scope Volatility Suspicion | 2 | Public contract is bounded, but planning expanded to include tree componentization and future generated-component reuse. |
| Confidence | 2 | Draft plan is detailed, but host behavior and component lifecycle remain unimplemented and unproven. |

### Early Signals
- The task explicitly rejects a reduced baked-only proxy and targets prototype-level procedural motif/component behavior.
- `tree_proxy` componentization is in scope as no-visual-change enabling work.
- `planting_mass -> surface_drape` is behavior realization using existing hosting fields, not a schema-field addition.
- Hosted validation is required because fakes cannot prove real component definitions, face/frame behavior, or rollback.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Delivers full planting proxy realization plus tree componentization, but stays behind existing public creation surface. |
| Technical Change Surface | 4 | Layered runtime work across generated definitions, two builders, command hosting, surface z/frame seams, fakes, contract tests, and docs/guidance checks. |
| Implementation Friction Risk | 3 | Main resistance is component lifecycle, frame extraction/reuse, deterministic motif planning, and live-safe geometry emission. |
| Validation Burden Risk | 3 | Requires more than routine unit checks: hosted component-definition, sloped terrain, replacement/undo, visual, and near-cap performance evidence. |
| Dependency / Coordination Risk | 2 | Depends on existing semantic, scene-query, staged-asset frame, and hosted SketchUp validation access; no external service dependency. |
| Discovery / Ambiguity Risk | 2 | Decisions are mostly resolved; remaining ambiguity is motif face-count details and exact hosted tuning. |
| Scope Volatility Risk | 2 | Scope shifted during planning but is now bounded by no public controls and no tree visual redesign. |
| Rework Risk | 3 | If generated definition lifecycle or frame reuse assumptions fail in SketchUp, meaningful localized redesign could be needed. |
| Confidence | 2 | Plan is specific, but confidence stays moderate until premortem and hosted behavior prove the riskiest seams. |

### Analog Brief
- `SEM-15` is the closest hosted semantic creation analog. It predicted high technical/validation risk, but actual implementation stayed bounded because sampler/refusal seams fit; SEM-16 is larger because it adds generated component lifecycle and procedural geometry.
- `STI-04` is the closest no-public-shape-change scene-query optimization analog. It reinforces preserving ambiguity/transform semantics while reusing optimized seams; SEM-16 has higher host-mutation risk.
- `SEM-04` has no size ledger, but its task/plan are the tree-proxy geometry baseline; SEM-16 must preserve its topology rather than treat componentization as a visual rewrite.
- `SEM-13` path drape is a strong behavioral analog: prepared sampling matters, and live performance can expose problems that unit fakes miss.

### Top Assumptions
- A small generated-component library seam can be added without becoming a generic procedural renderer.
- `SurfaceFrameResolver` behavior can be reused or extracted internally without coupling planting proxy to staged-asset public request shape.
- Prototype motif defaults are close enough to start implementation and can be tuned only with hosted evidence.
- Hosted SketchUp validation access is available before closeout.

### Estimate Breakers
- `model.definitions` lifecycle in real SketchUp mutates previous managed objects or cannot be safely owned by attributes.
- Surface-frame extraction requires a larger refactor of staged asset placement than planned.
- Near-cap planting proxies perform poorly enough to require redesign of motif count, sampling, or component strategy.
- Public contract/docs drift expands into schema fields, exposed controls, or response evidence.

### Predicted Notes
- This is a large semantic runtime feature even though the public request shape stays stable.
- Validation is scored `3` because generated component definitions, visual proxy quality, terrain frames, replacement/undo, and performance need host evidence beyond routine closeout.
- Rework risk is higher than normal because the most important assumptions are host-sensitive and only partially provable with fakes.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

### Confirmed Drivers
- Functional scope remains `3`: the task is more than a local fix because it
  delivers planting proxy realization, contextual hosted behavior, and tree proxy
  componentization, but it still avoids new public request shape.
- Technical change surface remains `4`: premortem confirmed generated component
  lifecycle, frame extraction, command hosting, fakes, builders, and hosted
  validation all matter.
- Validation burden remains `3`: this is not just routine hosted breadth; the
  plan must prove model-global definitions, replacement/undo, near-cap
  performance, and visual quality in real SketchUp.
- Rework risk remains `3`: if definition lifecycle or bulk frame extraction
  assumptions fail, implementation may need meaningful localized redesign.

### Contested Drivers / Missing Evidence
- Whether SketchUp operation abort fully rolls back component definitions is
  unproven; the plan now requires explicit cleanup/proof rather than assuming
  host behavior.
- Whether `SurfaceFrameResolver` can be extracted into a bulk evaluator without
  wider staged-asset refactor remains an implementation-time uncertainty.
- Whether prototype constants produce decent visual output in the managed runtime
  remains hosted-review evidence, not a unit-test fact.
- Hosted validation access and near-cap scene setup remain required closeout
  evidence.

### Score Changes
- None. Premortem findings added gates and guardrails, but they confirm the
  original high technical surface / high validation / moderate confidence shape
  rather than resizing it.

### Recommendation
- Confirm the challenged estimate. Do not split before implementation, but begin
  with generated-component lifecycle tests and bulk surface-frame extraction; if
  either fails materially, record drift before proceeding to planting motif work.
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
| Functional Scope | 3 | Delivered planting proxy realization, surface-drape hosting, generated motif definitions, and no-visual-change tree componentization behind the existing command surface. |
| Technical Change Surface | 4 | Touched semantic builders, generated definitions, command hosting, surface sampling/frame evaluation, fakes/tests, native schema/docs, and hosted SketchUp validation. |
| Actual Implementation Friction | 3 | Component lifecycle and hosted geometry quality required meaningful adjustment, especially motif sizing/materials and underlay sampling on wavy terrain. |
| Actual Validation Burden | 3 | Exceeded baseline through expanded hosted visual/geometry matrix, wave-terrain setup, and a material underlay fix/redeploy/retest loop. |
| Actual Dependency Drag | 2 | Depended on existing semantic command plumbing, scene-query sampling seams, generated definitions, and live SketchUp access, but no external service dependency. |
| Actual Discovery Encountered | 3 | Live visual checks changed execution: accepted motif geometry needed direct production porting, and softened underlay needed prepared-context sampling. |
| Actual Scope Volatility | 1 | Accepted outcome stayed stable; adjustments returned implementation to planned terrain-sampled procedural proxy behavior rather than changing the task boundary. |
| Actual Rework | 3 | The planting proxy slice was revisited after it appeared complete, replacing placeholder/tuned geometry with accepted low-poly motifs and correcting underlay sampling. |
| Final Confidence in Completeness | 3 | Strong automated, review, and hosted evidence; residual risks are bounded to deferred area-scaled density and optional exact-bound CI hardening. |

### Inflation Check
- **Validation exceeded baseline?** Yes. Routine tests/review/live checks were baseline, but the extra wave-terrain matrix and underlay fix/redeploy/retest loop materially expanded validation.
- **Meaningful rework beyond normal correction?** Yes. Planting geometry was reworked after initial closeout-level evidence because visual quality missed the accepted target.
- **Task boundary changed?** No. The work stayed inside SEM-16's planned proxy realization and hosted validation scope.
- **Any `4` justified by domination/repeated blockers/revert/redesign?** No. Technical surface is `4` by breadth; no other `4` is justified by execution domination.
- **Unrun required evidence reflected in confidence?** Not applicable. Required hosted evidence ran; confidence remains `3` because density scaling and exact-bound CI assertions are residual follow-ups.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

- **Classification**: expanded hosted matrix plus one material fix/redeploy/retest loop
- **Distinguishing Evidence**:
  - Focused SEM-16 tests, semantic suite, RuboCop, full CI/package, local review, and PAL `grok-4.3` review completed.
  - Live SketchUp verification covered fixed and surface-draped pockets, refusals, replacement/undo, tree componentization, accepted motif geometry parity, and a `50m..110m` wave-terrain patch matrix.
  - Wave-terrain motif origins matched prepared-context terrain samples to floating-point precision; softened underlay max terrain delta was `<= 0.024m`.
- **Gaps**: generated-definition GC deferred; area-scaled planting density deferred; exact motif-bound assertions remain optional CI hardening.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

- **Most Underestimated**: visual geometry fidelity and hosted interpretation cost; structural motif richness was not enough without exact accepted proportions/materials and user-visible scene review.
- **Most Overestimated**: scope volatility; the task needed rework but did not materially change public contract, acceptance target, or task boundary.
- **Future Similar Tasks Should Assume**: hosted procedural geometry tasks need direct accepted-geometry parity checks, an explicit density policy for large footprints, and at least one adversarial terrain validation scene before closeout.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:semantic-scene-modeling`
- `systems:semantic-builders`
- `systems:semantic-hosting`
- `systems:surface-sampling`
- `systems:generated-components`
- `validation:expanded-hosted-matrix`
- `host:sketchup-live`
- `contract:no-public-shape-change`
- `risk:visual-geometry-fidelity`
- `risk:density-scaling`
- `rework:high`
- `volatility:low`
- `confidence:strong`
<!-- SIZE:TAGS:END -->
