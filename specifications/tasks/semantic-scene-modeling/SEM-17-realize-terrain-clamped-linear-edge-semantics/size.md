# Size: SEM-17 Realize Terrain-Clamped Linear Edge Semantics

**Task ID**: SEM-17  
**Title**: Realize Terrain-Clamped Linear Edge Semantics  
**Status**: calibrated  
**Created**: 2026-05-23  
**Last Updated**: 2026-05-27  

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
  - `systems:surface-sampling`
  - `systems:public-contract`
  - `systems:validation-service`
- **Distinguishing Validation / Host Shape**: `validation:contract`, `validation:hosted-smoke`
- **Likely Analog Class**: hosted semantic linear hardscape behavior with public contract expansion

### Identity Notes
- Task combines a concrete hosted-behavior bugfix for `retaining_edge + edge_clamp` with a new canonical semantic type, `edge_restraint`.
- Planning refinement narrowed `edge_restraint` to hosted-only `polyline`/`height`/`thickness`; `definition.elevation` remains a `retaining_edge` compatibility field rather than a new restraint field.
- Dominant shape is semantic runtime geometry plus public schema/docs/test parity, with `surfaceOffset` validation used as acceptance guidance rather than exact edge topology.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Suspicion-level only. Refresh this section before prediction if planning changes task shape.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Fixes one advertised hosted behavior and adds a new semantic element type through `create_site_element`. |
| Technical Change Surface | 4 | Likely spans builders, validator, normalizer, registry, command hosting matrix, native schema, contract fixtures, docs, and validation examples/tests. |
| Hidden Complexity Suspicion | 3 | Terrain-clamped edge geometry, z=0 fallback prevention, unit conversion, partial-state safety, and approximate surface-offset validation can hide defects. |
| Validation Burden Suspicion | 3 | Needs automated contract/behavior coverage plus hosted terrain checks; may include a specific z=0 validation regression scene. |
| Dependency / Coordination Suspicion | 2 | Depends on existing SEM-13 terrain sampling patterns, SVR-02 `surfaceOffset`, and hosted SketchUp access, but no external service dependency. |
| Scope Volatility Suspicion | 2 | Scope is bounded, but hosted linear-edge vocabulary, centerline sampling limits, and validation expectations remain likely review pressure points. |
| Confidence | 2 | Task and draft plan are specific, but the seeded contract choices still need implementation-time proof and likely review. |

### Early Signals
- The runtime already accepts `retaining_edge -> edge_clamp`, but the builder currently ignores hosting and can emit z=0 geometry.
- `edge_restraint` changes the public semantic vocabulary and therefore must move schema, validator, docs, tests, and metadata together; its field set intentionally excludes `definition.elevation`.
- Existing `PathDrapeBuilder` and `SurfaceHeightSampler` provide close analog seams, reducing novelty but not removing edge-body geometry risk.
- Existing `surfaceOffset` validation can catch the reported failure mode, but only with approximate bounds-derived anchors.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Fixes an advertised hosted behavior and adds one canonical semantic type, but stays inside `create_site_element` and avoids new aliases/tools. |
| Technical Change Surface | 4 | Crosses validator, normalizer, request-shape contract, recovery, command hosting, builder registry, shared geometry realizer, metadata, native catalog, docs, fixtures, and validation examples. |
| Implementation Friction Risk | 3 | Existing sampler/refusal seams help, but terrain-clamped edge shell geometry, no-partial-wrapper ordering, station caps, and create/replace parity add meaningful resistance. |
| Validation Burden Risk | 3 | Requires focused semantic, command, contract/schema, docs posture, scene-validation, and hosted SketchUp matrix evidence beyond fake-host tests. |
| Dependency / Coordination Risk | 2 | Depends on shipped SEM-08/13/15/16, STI-02, SVR-02, and hosted validation access, but no external service or cross-team dependency is unresolved. |
| Discovery / Ambiguity Risk | 2 | Major contract decisions are resolved; remaining uncertainty is live geometry behavior, transformed host sampling, and centerline-only visual sufficiency. |
| Scope Volatility Risk | 2 | Scope is bounded by no new dimension fields, no aliases, and hosted-only `edge_restraint`, though side sampling or validation overclaim pressure could reopen scope. |
| Rework Risk | 3 | If real SketchUp face emission, transform sampling, or partial-state cleanup assumptions fail, the shared realizer or command lifecycle may need localized structural correction. |
| Confidence | 2 | Plan is specific and consensus-reviewed, but confidence stays moderate until premortem and hosted behavior prove the highest-risk seams. |

### Analog Brief
- `SEM-15` is the closest hosted semantic creation analog. It stayed bounded because sampler/refusal seams fit, but no-partial-wrapper ordering, create/replace parity, and live hosted validation were decisive.
- `SEM-16` is a larger hosted procedural geometry analog. It warns that fake-host tests can miss visual/geometry defects and that hosted validation can drive meaningful localized fixes.
- `SVR-02` is the validation analog. It supports using `surfaceOffset` for approximate z=0/off-terrain checks while warning against exact topology claims.
- `STI-02` is the surface-sampling lineage. It reinforces transform-aware sampling risk and the need to reuse internal sampling seams instead of routing through public tools.
- No calibrated `SEM-13` size ledger exists, but its implementation summary is a strong behavioral analog for prepared sampling, station caps, and live terrain-following checks.

### Top Assumptions
- `SurfaceHeightSampler` prepared contexts can be reused for repeated linear-edge station sampling without new public sampling tools.
- Centerline/station-only sampling is sufficient for SEM-17 acceptance, with side/thickness sampling deferred unless hosted validation disproves it.
- Hosted feasibility can be planned before wrapper creation, or operation handling can otherwise prove no partial managed object remains.
- Docs/schema can keep `edge_restraint` and `retaining_edge` contrastive enough to avoid semantic duplication confusion.

### Estimate Breakers
- Real SketchUp transformed or nested host sampling disagrees with fake-host behavior.
- Centerline-only sampling produces unacceptable visible floating/burying on representative edge restraints.
- Hosted sample-miss or invalid-host paths leave empty groups or stale managed metadata.
- Native catalog, docs, fixtures, and runtime validation drift because the new semantic type touches many public-contract files.

### Predicted Notes
- Predicted size is high on technical surface because a narrow semantic behavior still crosses public contract, builder geometry, hosted sampling, metadata, docs, and validation guidance.
- Validation is `3`, not `4`, because hosted validation is expected repo baseline for runtime geometry work; it becomes higher only if repeated host fix/retest loops or special-scene blockers dominate implementation.
- Rework risk is `3` because the shared realizer and no-partial-wrapper design are structurally important and host-sensitive.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

### Confirmed Drivers
- Technical Change Surface remains `4`: premortem confirmed the change spans public contract maps, native schema/prose, docs, fixtures, command hosting, builder geometry, metadata, validation, and hosted checks.
- Validation Burden remains `3`: hosted matrix work is required, but the plan now treats it as normal runtime closeout unless cross-slope/transform/no-partial checks trigger repeated fix loops or special-scene blockers.
- Rework Risk remains `3`: the shared realizer, hosted pre-wrapper ordering, and transform-sensitive sampling are structural enough that live failures could require localized redesign.
- Scope Volatility remains `2`: the plan rejected aliases and new dimension fields, and the premortem converted side-sampling pressure into a hosted cross-slope gate rather than broadening scope immediately.

### Contested Drivers / Missing Evidence
- Centerline-only station sampling is still the main contested semantics driver; hosted cross-slope evidence must prove it is visually acceptable or force scope reconsideration.
- No-partial-wrapper behavior is not proven by planning; implementation must show hosted retaining-edge feasibility occurs before wrapper creation and invalid host/sample miss leaves no managed object.
- Contract drift remains a live risk because `edge_restraint` touches several public surfaces; phase 1 now has an atomic public-surface gate.
- Hosted transformed/nested host behavior remains unproven until SketchUp validation.

### Score Changes
- None. The premortem added gates and stricter tests, but those confirm the predicted high technical surface, high rework risk, and moderate confidence rather than changing the estimate.

### Recommendation
- Confirm the challenged estimate. Do not split before implementation, but start with public contract skeleton tests and treat cross-slope hosted evidence, no-partial-wrapper cleanup, and schema/docs parity as implementation gates rather than optional closeout polish.
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
| Functional Scope | 3 | Shipped real hosted `retaining_edge` behavior plus a new canonical hosted `edge_restraint` semantic type inside the existing creation flow. |
| Technical Change Surface | 4 | Crossed public contract maps, validator, normalizer, command hosting, builder registry, geometry generation, native catalog, docs, fixtures, scene validation tests, and hosted reload checks. |
| Actual Implementation Friction | 3 | Core implementation fit the plan, but live review exposed public catalog underguidance and the initial edge-visibility rule hid hard arrises, requiring localized correction. |
| Actual Validation Burden | 3 | Went beyond normal closeout with repeated live visual/reload loops, direct public MCP `tools/list` verification, full suite reruns after the final correction, and PAL review plus delta review. |
| Actual Dependency Drag | 2 | Relied on existing SEM/STI/SVR seams and required deployed SketchUp runtime access, but no upstream dependency blocked implementation. |
| Actual Discovery Encountered | 3 | Public MCP descriptions needed more operational guidance than planned, and visual review clarified that path-side restraints need better future abstraction. |
| Actual Scope Volatility | 1 | Accepted outcome stayed SEM-17; path internal-edge hiding and stronger catalog wording were minor adjacent adjustments rather than a new task shape. |
| Actual Rework | 2 | Revisited live geometry and catalog prose after review, including the final coplanar-only edge hiding correction, but changes stayed localized. |
| Final Confidence in Completeness | 3 | Automated, contract, package, review, public MCP, and live visual evidence are strong; remaining gaps are explicit follow-ons rather than blockers. |

### Inflation Check
- Validation exceeded normal baseline because live visual correction, public MCP catalog verification, and final delta review created extra closeout work; `3` is justified, not `4`.
- Rework was localized and did not require redesign or revert.
- The task boundary stayed stable; path-relative restraint derivation remains a follow-up, not scope absorbed into SEM-17.
- No `4` actual scores are used.
- Confidence is `3` because the final hard-edge correction was loaded and tested but not re-visualized with a fresh retained-edge object left in the scene.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

- **Classification**: expanded matrix / one material closeout loop
- **Distinguishing Evidence**:
  - Full tests, lint, package verification, task-review, PAL `grok-4.3` review, and PAL delta review passed.
  - Public MCP `tools/list` was verified with `curl` after catalog reload.
  - Hosted SketchUp visual checks covered terrain-clamped edge behavior and path internal-triangle hiding on existing terrain.
  - Final visibility rule changed from “shared edge” to “exactly two coplanar faces,” preserving hard arrises.
- **Gaps**:
  - No automatic path-relative edge derivation.
  - `surfaceOffset` remains approximate.
  - Final coplanar hard-edge correction was loaded and tested but not re-visualized with a new retained-edge object left in-scene.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

- **Most Underestimated**: public MCP discoverability and visual semantics. Correct runtime behavior was not enough; path-edge users needed explicit centerline/thickness/host-target guidance.
- **Most Overestimated**: dependency risk. Existing sampling, command, and validation seams were sufficient once the contract was aligned.
- **Future Similar Tasks Should Assume**: hosted semantic geometry tasks need both public tool wording review and live visual review for modeled edge readability, especially when generated triangulation is exposed.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:semantic-scene-modeling`
- `systems:semantic-builders`
- `systems:semantic-hosting`
- `systems:surface-sampling`
- `systems:public-contract`
- `systems:validation-service`
- `validation:contract`
- `validation:hosted-smoke`
- `contract:public-tool`
- `risk:partial-state`
- `risk:contract-drift`
- `risk:visual-semantics`
- `rework:localized`
- `confidence:strong`
<!-- SIZE:TAGS:END -->
