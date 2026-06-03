# Planning Context: MTA-44B1

## Related Work Evidence

### Search Terms

- `MTA-44B1`, `MTA-44B`, `topologyCutConstraints`, `feature-cut`, `off-grid topology`
- `TerrainOutputConstraintContext`, `ConstrainedCutGraph`, `TriangulatedOutputPatch`
- `ownerLocalPathHeights`, `ownerLocalPointHeight`, `featureCutSummary`
- `CDT`, `TerrainCdtBackend`, `ResidualCdtEngine`, `StableDomainCdtSolver`
- `feature-aware adaptive`, `forced subdivision`, `composed height oracle`, `seam contract`, `component planner`

### Related-Work Summary

- `MTA-44B` is the nearest task but is a negative analog, not implemented baseline. Its status is
  `closed-blocked`; the implementation direction should be treated as failure evidence and planning
  input only.
- `MTA-44B` proved that active effective feature geometry can derive simple contained cut inputs,
  that cut constraints need explicit height ownership, and that hosted measurements can distinguish
  manifoldness from product-correct topology.
- `MTA-44B` also proved that adaptive/local-template rewriting is not sufficient as the general
  answer for composed feature cuts, and that durable feature-domain/oracle wiring can incorrectly
  constrain later edits.
- `MTA-44A` is implemented/calibrated and supplies the active composed height/oracle baseline.
  Its lesson is that unit oracle correctness is not enough; every production consumer must be
  routed through the intended height source and hosted performance must be measured.
- `MTA-39` and `MTA-40` are implemented/calibrated feature-aware adaptive-output precedents. They
  support reusing policy, diagnostics, replay, and hosted validation patterns, while warning that
  density/forced subdivision is not the same as emitted topology.
- `MTA-42` and `MTA-43` are implemented/calibrated seam/component lifecycle baselines. They are
  constraints for contained safe-skip behavior, not permission for `MTA-44B1` to absorb cross-seam
  or cross-patch hardening.
- `MTA-24` is implemented/calibrated CDT prior art. It supports constrained triangulation adapter
  and validation-envelope reuse, but its prototype/global/backend-center assumptions are not a
  drop-in production feature-cut architecture.

### Calibrated Analog Lessons

- Retrieval facets used: `archetype:feature`, `scope:managed-terrain`, `systems:terrain-output`,
  `systems:terrain-mesh-generator`, `systems:terrain-state`, `systems:public-contract`,
  `validation:hosted-matrix`, `validation:performance`, `host:special-scene`,
  `risk:partial-state`, `risk:performance-scaling`, `contract:no-public-shape-change`.
- `MTA-44B` actuals: implementation friction, validation burden, discovery, volatility, and rework
  all reached `4`. Dominant failure mode was product-model failure after green local tests:
  manifold-but-wrong topology, wrong cut heights, composed-feature errors, stale derived
  constraints, and replan/revert outcome.
- `MTA-24` actuals: CDT-like terrain work had friction/discovery/rework `4` and validation `4`.
  The useful lesson is to separate comparison/prototype infrastructure from production routing and
  keep native/CDT decisions evidence-driven.
- `MTA-44A` actuals: technical surface and validation rose to `4` because production height routing
  spanned more consumers than expected and hosted replay/performance exposed command-path misses.
- `MTA-40` actuals: validation rose to `4`; hosted output exposed geometry-policy defects that
  local policy tests did not catch. Future topology-affecting output tasks should plan at least one
  live geometry-policy correction loop.
- `MTA-42`/`MTA-43` actuals: seam/component metadata and replay evidence are not enough by
  themselves; proof must show actual mutation behavior and no-delete/fallback safety.
- No positive calibrated analog exactly matches contained off-grid feature-boundary constrained cut
  islands inside adaptive output. `MTA-44B` is the closest shape but is a blocked negative analog.

### Implemented-Versus-Planned Baseline

- Implemented/calibrated baseline: `MTA-39`, `MTA-40`, `MTA-42`, `MTA-43`, `MTA-44A`, and `MTA-24`
  as prototype prior art.
- Planned/blocked only: `MTA-44B` plan and runtime ideas. Treat `topologyCutConstraints`,
  `ContainedFeatureCutRewriter`, `featureCutSummary`, `ownerLocalPathHeights`, and
  `ownerLocalPointHeight` as planning artifacts and lessons unless reintroduced by `MTA-44B1`.
- Current code search found no runtime definitions for `TerrainOutputConstraintContext`,
  `ConstrainedCutGraph`, or `TriangulatedOutputPatch`.
- Current `TerrainFeatureGeometry` includes output anchors, protected regions, pressure regions,
  reference segments, affected windows, tolerances, planar regions, and oracle semantic regions,
  but no cut-topology collection.
- Current `TerrainOutputPlan` owns adaptive planning, compaction, conformity, seam artifacts, and
  height-oracle routing; it does not own a feature-cut constrained generation layer.
- Current `TerrainMeshGenerator` owns SketchUp mutation, no-delete/refusal posture, adaptive
  generation, and disabled-by-default CDT routing; it should consume accepted data rather than
  rediscovering raw source feature semantics.

### Reusable Decisions Or Patterns

- Keep public MCP terrain contracts stable unless a separate contract task is created.
- Keep topology/height cut requirements as disposable output-generation metadata derived per pass.
- Reuse current effective feature geometry and composed height/oracle semantics as inputs, but do
  not make either layer own final cut graph topology.
- Preserve compact internal diagnostics and replay evidence, but avoid exposing raw cut graphs or
  public backend selectors.
- Reuse no-delete and fallback-before-mutation discipline from `TerrainMeshGenerator` and patch
  lifecycle work.
- Reuse CDT adapter/result-envelope/validation ideas selectively; reject global CDT, residual
  reconstruction, private `cdt_patch` routing, and registry-heavy lifecycle machinery as the
  `MTA-44B1` implementation spine.

### Public Artifact Update List

- Expected public MCP request/response contract delta: none.
- If a public contract unexpectedly changes, update together: native tool catalog/schema,
  dispatcher/argument routing, command behavior, contract fixtures/tests, README/docs/examples, and
  no-leak tests.
- If diagnostics are added, keep them internal/aggregate and validate that public responses do not
  expose raw cut graph, patch ids, mesh vertices, or backend selector state.

### Host-Sensitive Notes

- SketchUp mutation is no-delete sensitive: fallback/skip must happen before erasing old derived
  output.
- Hosted visual proof is required because local counters, manifoldness, and face counts can pass
  while topology remains visually or semantically wrong.
- Stale derived constraints are a host-visible workflow failure: later fairing/edit operations must
  not be constrained by old output cut metadata or persisted feature domains.
- Boundary/seam behavior is host-sensitive and belongs to a safe skip/fallback boundary in
  `MTA-44B1`; cross-seam synchronization and cross-patch promotion remain `MTA-44C`.
- Performance evidence should use hosted replay/timing because adaptive output and oracle routing
  have previously exposed live hot-path costs not predicted by unit tests.

### Unresolved Related-Work Gaps

- Exact placement and shape of `TerrainOutputConstraintContext`, `ConstrainedCutGraph`, and
  `TriangulatedOutputPatch` remain Step 04/06 architecture research.
- The normalized primitive vocabulary for rings, paths, polygons, breaklines, points, and composed
  intersections is not yet chosen.
- The inserted-vertex height source order and missing-height fallback policy need explicit design.
- The safe contained-area definition must be made precise enough to avoid absorbing `MTA-44C`.
- Hosted feature-cut replay rows must be designed separately from the like-for-like adaptive
  baseline so experimental rows do not contaminate existing baseline interpretation.
