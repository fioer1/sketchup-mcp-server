# Size: MTA-44 Add Sparse Local Detail Tiles And Composed Height Oracle

**Task ID**: MTA-44  
**Title**: Add Sparse Local Detail Tiles And Composed Height Oracle  
**Status**: closed-superseded  
**Created**: 2026-05-15  
**Last Updated**: 2026-05-28  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:feature`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:command-layer`
  - `systems:public-contract`
  - `systems:serialization`
  - `systems:terrain-state`
  - `systems:terrain-storage`
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:test-support`
- **Validation Modes**:
  - `validation:contract`
  - `validation:hosted-matrix`
  - `validation:performance`
  - `validation:persistence`
  - `validation:migration`
- **Likely Analog Class**: new terrain state/output layer on top of MTA-36 lifecycle and MTA-43 component planning

### Identity Notes
- Seed refreshed after planning. The task is a strategic local-resolution slice with new state,
  oracle, tile-local output topology, corridor-aware source derivation, public no-leak constraints,
  and hosted comparator evidence.
- Closed as superseded on 2026-05-28. The challenged estimate remains historical risk evidence for
  MTA-44A through MTA-44C, but this ledger is no longer an active implementation estimate.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 4 | Adds true local high-detail capability without global source-grid refinement. |
| Technical Change Surface | 4 | Likely touches command orchestration, state/storage, serialization, height queries, output planning, mesh generation, contract guards, and hosted evidence. |
| Hidden Complexity Suspicion | 4 | Composed height precedence, local-detail boundaries, and readback can hide significant complexity. |
| Validation Burden Suspicion | 4 | Needs hosted performance, face count, persistence, boundary, component, and comparison evidence. |
| Dependency / Coordination Suspicion | 3 | Depends on seam contracts and component planning before local detail can cross patch boundaries safely. |
| Scope Volatility Suspicion | 3 | Supported edit families and fallback semantics already needed refinement during planning. |
| Confidence | 2 | Architecture direction is clear, but local-cell emission, seam lattice, and hosted comparator behavior are unproven. |

### Early Signals
- State/oracle change, not just output policy.
- Needs evidence against equivalent global refinement pressure.
- Depends on MTA-36, MTA-40, MTA-42, and MTA-43; optional CDT/native work remains excluded.
- Corridor is first-class but role-filtered; survey/fairing are neutral by default.
- Valid heightmap edits must not fail because local-detail enhancement falls back.

### Early Estimate Notes
- Seed only. Do not treat this as the predicted implementation estimate.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

| Dimension | Predicted (0-4) | Notes |
|---|---:|---|
| Functional Scope | 4 | Adds durable sparse local detail, composed oracle, internal tile creation, sub-grid output, fallback semantics, and hosted comparator evidence. |
| Technical Change Surface | 4 | Crosses command orchestration, state/schema/storage, oracle/readback, output planning, mesh emission, forced masks, seam/component planning, replay/classifier, and contract guards. |
| Implementation Friction | 4 | Multiple unimplemented surfaces must line up: schema v4, shared oracle, tile-local cells, base-cell suppression, corridor chunking, and seam/component fallback. |
| Validation Burden | 4 | Beyond baseline closeout: requires migration/readback, no-delete/fallback, equivalent-global comparator, row-class classifier, and repeated hosted performance evidence. |
| Dependency / Coordination Drag | 3 | Depends materially on MTA-36 lifecycle, MTA-40 forced masks, MTA-42 seams, MTA-43 components, and hosted SketchUp replay access. |
| Discovery / Ambiguity | 3 | Core architecture is decided, but schema field shape, tile triggers, seam-lattice mechanics, and feature-critical metadata remain tactical proof points. |
| Scope Volatility | 3 | Planning already reshaped supported modes and refusal semantics; further split pressure is possible if local-cell or seam behavior proves too broad. |
| Rework Pressure | 3 | Prior analogs show hosted evidence can force a second output layer or lifecycle correction after local tests appear green. |
| Confidence | 2 | Plan is specific, but no local-detail state, oracle, local-cell output, or comparator implementation exists yet. |

### Analog Brief

- MTA-36 is the closest lifecycle analog: live validation forced a single-mesh logical patch model
  and stronger no-delete gates. MTA-44 inherits that host-sensitivity.
- MTA-38/MTA-39 provide the reusable replay/classifier pattern and warn that quality claims need
  captured quality evidence, not counters alone.
- MTA-40 shows unsupported output pressure should degrade/skip rather than refuse valid edits.
- MTA-42/MTA-43 are direct dependencies for seam/component evidence, but their retained-Z and
  retained-seam gaps remain estimate breakers.
- MTA-45 is the strongest quality-gated analog: hosted visual/replay evidence forced an extra
  emitted-output layer after local tests looked green.

### Top Assumptions

- Public MCP request/response shapes remain unchanged.
- `local_detail_cells` can be integrated into the existing adaptive mesh path without CDT/native
  geometry.
- Corridor local detail can stay role-filtered and chunked without broad centerline/interior
  refinement.
- Equivalent-global comparison can remain harness-only and cheap enough for hosted evidence.

### Estimate Breakers

- Local-detail seam lattice cannot produce deterministic touched-seam chains without a broader seam
  redesign.
- Tile-local cell emission causes duplicate/gap topology or requires arbitrary/rotated geometry
  beyond the bounded axis-aligned model.
- Equivalent-global comparator or hosted replay becomes too slow or unstable for repeated-run
  evidence.
- Public contract changes become necessary to express local-detail intent.

### Predicted Notes

- This is intentionally estimated as a very high change surface and validation burden. The high
  scores come from new state plus output topology plus hosted comparator evidence, not routine CI or
  routine live validation.
- Confidence stays moderate-low until local-cell mesh topology and seam/component fallback are
  proven on live hosted rows.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

### Confirmed Drivers

- Premortem confirmed the high technical surface: seam lattice, direct height reads, corridor
  chunking, fallback categories, and comparator evidence are all material implementation seams.
- Validation burden remains `4` because MTA-44 requires extra migration/readback, hosted no-delete,
  equivalent-global comparator, row-class classifier, and repeated timing evidence beyond routine
  repo closeout.
- Implementation friction remains `4` because several new surfaces must align before any hosted
  must-improve row can pass: schema v4, oracle, tile-local cells, base suppression, seam ordering,
  and fallback routing.

### Contested Drivers / Missing Evidence

- Corridor coverage could still be over- or under-sized until implementation proves chunk-level
  evidence and the `80%` eligible-length threshold on large timing rows.
- Seam-lattice work could split if deterministic touched-seam ordering cannot be implemented inside
  MTA-42/MTA-43 seams without broader retained-neighbor redesign.
- Equivalent-global comparator cost is still unproven; if replay runtime becomes unstable, the
  validation burden remains high and confidence may drop.

### Score Changes

- No score changes after challenge. The premortem added guardrails but did not reduce the core
  uncertainty or change the task boundary.

### Recommendation

- Keep the estimate challenged at very high scope/change/validation. During implementation, treat
  seam-lattice determinism, direct oracle-use guard, corridor chunk coverage, and comparator runtime
  as early drift sentinels; split follow-on scope if any one of those requires CDT/native or public
  contract changes.
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

- `archetype:feature`
- `scope:managed-terrain`
- `systems:public-contract`
- `systems:serialization`
- `systems:terrain-state`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `validation:hosted-matrix`
- `validation:performance`
- `validation:persistence`
- `validation:migration`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `risk:metadata-storage`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
