# Summary: SEM-16 Realize Terrain-Sampled Planting Mass Proxy Representation

**Task ID**: `SEM-16`
**Status**: `implemented`
**Date**: `2026-05-22`

## Shipped Behavior

- Added `SU_MCP::Semantic::GeneratedComponentLibrary` for owned, reusable generated component definitions stamped with semantic ownership attributes.
- Componentized `tree_proxy` as an internal realization change: the accepted SEM-04 trunk/canopy topology now lives in a generated definition, and the managed wrapper contains a component instance.
- Preserved `tree_proxy + terrain_anchored` behavior by resolving terrain height before wrapper creation and placing the generated component instance at the anchored location.
- Added `SU_MCP::Semantic::PlantingMassProxyBuilder` for `planting_mass + representation.mode: "proxy_mass"`.
- Kept non-`proxy_mass` planting behavior compatible with the existing single face plus pushpull fallback.
- Added fixed-datum planting proxy output with underlay faces and deterministic low-poly motif component instances.
- Added `planting_mass + hosting.mode: "surface_drape"` support using existing target resolution and `SurfaceHeightSampler` prepared sampling contexts.
- Updated planting proxy motif generation to the accepted low-poly matrix, edge, grass, and perennial geometry vocabulary, with generated `planting_motif v7` definitions keyed by planting category and average height.
- Updated surface-draped planting underlay generation so softened underlay perimeter points and the underlay center are sampled through the prepared `SurfaceHeightSampler` context instead of interpolating terrain height after corner sampling.
- Added `SU_MCP::Semantic::SurfaceFrameEvaluator` for repeated internal-unit surface frames from prepared sample contexts.
- Passed public `metadata` through internal semantic builder params so generated-definition and deterministic-policy code can use source identity without adding public fields.
- Updated the native tool catalog and MCP tool reference docs to list `planting_mass -> surface_drape`.
- Preserved the public `create_site_element` request shape; seed, spacing, count, style, edge fade, and component-strategy controls remain unexposed internal policy.

## Contract Alignment

- Public command surface remains `create_site_element`.
- Public schema does not expose planting seed, spacing, count, style, edge fade, or generated-component controls.
- Runtime hosting validation now accepts `planting_mass -> surface_drape` and still refuses unsupported hosted combinations with contextual `allowedValues`.
- Discoverability exists before a bad call through the native catalog/docs hosted-pair guidance and after a bad call through `unsupported_hosting_mode` refusal details.
- Response shape remains the existing semantic success/refusal envelope with JSON-serializable managed-object data.

## Coverage

- Generated component lifecycle:
  - owned definition creation and stamping
  - reuse without rebuilding
  - fallback enumerable lookup when indexed lookup returns nil
  - unowned name collision refusal
  - cleanup when a definition build block fails
- Surface frame evaluation:
  - internal-unit parity with `SurfaceHeightSampler`
  - runtime face classification refusal for points inside bounds but outside the actual face
- Tree proxy:
  - wrapper contains a generated component instance
  - SEM-04 topology assertions run against the generated definition
  - terrain-anchored placement remains anchored before wrapper mutation
- Planting mass:
  - proxy mode delegates to procedural proxy builder
  - fixed-datum proxy produces underlay faces plus motif component instances
  - surface-drape proxy samples hosted terrain before wrapper mutation
  - fallback prism path remains for non-proxy requests
- Runtime and contract posture:
  - `planting_mass -> surface_drape` hosting acceptance
  - metadata pass-through into builder params
  - public no-hidden-control request posture
  - native catalog/docs hosted-pair wording

## Validation Evidence

- Focused SEM-16 skeleton set:
  - `bundle exec ruby -Itest -e 'ARGV.each { |path| load path }' test/semantic/generated_component_library_test.rb test/semantic/surface_frame_evaluator_test.rb test/semantic/tree_proxy_builder_test.rb test/semantic/planting_mass_builder_test.rb test/semantic/semantic_commands_test.rb test/runtime/public_mcp_contract_posture_test.rb test/runtime/native/mcp_runtime_loader_test.rb`
  - `136 runs`, `884 assertions`, `0 failures`, `0 errors`, `8 skips`
- Semantic suite:
  - `bundle exec ruby -Itest -e 'Dir["test/semantic/**/*_test.rb"].sort.each { |path| load path }'`
  - `204 runs`, `771 assertions`, `0 failures`, `0 errors`
- Post-review focused regression:
  - `bundle exec ruby -Itest -e 'ARGV.each { |path| load path }' test/semantic/surface_frame_evaluator_test.rb test/semantic/generated_component_library_test.rb test/semantic/tree_proxy_builder_test.rb test/semantic/planting_mass_builder_test.rb`
  - `17 runs`, `80 assertions`, `0 failures`, `0 errors`
- Full CI after review follow-up:
  - `bundle exec rake ci`
  - RuboCop: `373 files inspected`, `no offenses detected`
  - Tests: `1532 runs`, `19328 assertions`, `0 failures`, `0 errors`, `41 skips`
  - Package: `dist/su_mcp-1.12.0.rbz`
- Geometry correction focused validation:
  - `bundle exec ruby -Itest -e 'ARGV.each { |path| load path }' test/semantic/planting_mass_builder_test.rb`
  - `5 runs`, `25 assertions`, `0 failures`, `0 errors`
  - `bundle exec ruby -Itest -e 'ARGV.each { |path| load path }' test/semantic/semantic_commands_test.rb`
  - `62 runs`, `298 assertions`, `0 failures`, `0 errors`
  - `RUBOCOP_CACHE_ROOT=tmp/.rubocop_cache bundle exec rubocop src/su_mcp/semantic/planting_mass_proxy_builder.rb test/semantic/planting_mass_builder_test.rb`
  - `2 files inspected`, `no offenses detected`

## Review Disposition

- Local `task-review` fallback ran `tldr bugbot`, `tldr smells`, `tldr hotspots`, and `tldr secure`.
  - No blocking issue was found in the changed runtime files.
  - Optional keyword constructor notes were reviewed as backward-compatible.
  - Unrelated lint findings were limited to pre-existing untracked local files outside `bundle exec rake ci`.
- PAL `grok-4.3` queue review amended the implementation queue before coding:
  - moved metadata pass-through earlier
  - added surface-frame unit parity coverage
  - added runtime no-public-control posture tests
  - kept tree topology assertions against generated definitions
  - recorded hosted closeout fields
- PAL `grok-4.3` final review found:
  - medium: runtime surface-frame sampling accepted points inside a face bounding box but outside the face
  - low: generated definition lookup should fall back to enumerable lookup when indexed lookup is unavailable or nil
- Follow-up changes:
  - `SurfaceFrameEvaluator` now classifies the local hit point with the face before accepting runtime frames.
  - `GeneratedComponentLibrary#find_definition` now falls back to enumerable name search when indexed lookup returns nil.
  - Regression tests were added for both findings.
- An additional local inspection fix moved tree and planting motif definition resolution before wrapper group creation to avoid empty wrapper mutations on generated-definition ownership conflicts.
- Geometry-generation follow-up review:
  - Local review found no blocking issue.
  - Warning accepted: large footprints can look sparse because `DEFAULT_MAX_MOTIF_COUNT = 32` is area-independent.
  - Warning accepted: automated tests do not lock exact motif definition bounds; live SketchUp verification covered the accepted matrix/grass parity.
  - PAL `grok-4.3` precommit review agreed no immediate fixes are required before calibration and classified both issues as low-severity residuals.

## Live SketchUp Verification

Live SketchUp verification was run on `2026-05-22` in a clean deployed extension session through the
public `create_site_element` command surface, with Ruby inspection used only for evidence capture.

| ID | Case | Result | Evidence |
|---|---|---:|---|
| H0 | Runtime/catalog sanity | PASS | SEM-16 classes loaded; `SUPPORTED_HOSTING_MODES["planting_mass"] == ["surface_drape"]` |
| H1 | Fixed-datum shallow planting pocket | PASS | `sem16-fixed-pocket`; `2` underlay faces, `21` motif instances, fixed Z range `13.7795..13.7795` internal units |
| H2 | Surface-draped shallow planting pocket | PASS | `sem16-draped-pocket`; `2` underlay faces, `21` motif instances, face Z range `0.5591..3.0`, instance Z range `0.8257..2.7457` internal units |
| H3 | Sample miss refusal | PASS | Refused with `terrain_sample_miss`; no `sem16-miss-pocket` managed object remained |
| H4 | Hidden public controls refusal | PASS | `seed`, `spacing`, and `componentStrategy` refused as malformed request shape; no managed object remained |
| H5 | Componentized tree baseline | PASS | `sem16-tree-baseline`; wrapper has `1` component instance, `0` direct faces; generated tree definition has `182` faces |
| H6 | Terrain-anchored tree | PASS | `sem16-tree-anchored`; component origin Z `2.488188976377954` matched fixture plane expected Z within floating-point tolerance |
| H7 | Replacement and undo posture | PASS | Replaced `sem16-fixed-pocket` preserved `sourceElementId` with state `Replaced`; `Sketchup.undo` restored original persistent id `131065613` and state `Created` |
| H8 | Generated definition reuse / near-cap motif count | PASS | Creating `sem16-reuse-pocket` kept planting motif definition count at `2`; reused shallow motif definition with `28` instances, below cap `32` |
| H9 | Corrected rich low-poly motif probe | PASS | `sem16-rich-draped-pocket`; `21` instances across `3` motif definitions with `81`, `180`, and `18` definition faces; grass/leaf material variation; terrain-varying instance Z `1.1788..2.8963` |
| H10 | Accepted motif geometry parity | PASS | West planting pocket regenerated with `planting_motif v7`; matrix definition matched accepted bounds `0.8215 x 0.0600 x 0.6308m`, `180` faces, and EXP material counts; grass matched bounds `0.8973 x 0.3168 x 0.6246m`, `81` faces |
| H11 | Wave terrain hosted patch matrix | PASS | Generated validation terrain `sem16-wave-terrain-x50-validation-v1` over `x=50..110m`, `3840` terrain faces, and five hosted planting patches with different footprints/heights |
| H12 | Wave terrain surface hugging | PASS | Motif origins matched prepared-context terrain samples to floating-point precision (`~1e-15m` max deltas); softened underlay max terrain delta was `<= 0.024m` across all five patches |

Generated definition evidence after hosted verification:

- `SU_MCP planting_motif v1 groundcover|height=157.480314961`: leftover from the first tall fixed-pocket probe before the shallow H1 rerun, `3` definition faces.
- `SU_MCP planting_motif v1 groundcover|height=4.724409449`: reused by shallow fixed/draped/reuse pockets, `3` definition faces.
- `SU_MCP planting_motif v1 grass_motif|groundcover|height=7.086614173`: corrected rich probe grass fan motif, `81` definition faces.
- `SU_MCP planting_motif v1 matrix_motif|groundcover|height=7.086614173`: corrected rich probe matrix leaf cluster motif, `180` definition faces.
- `SU_MCP planting_motif v1 edge_motif|groundcover|height=7.086614173`: corrected rich probe edge feather motif, `18` definition faces.
- `SU_MCP planting_motif v7 matrix_motif|groundcover|height=11.023622047`: accepted matrix motif, `180` definition faces, live bounds `0.8215 x 0.0600 x 0.6308m`.
- `SU_MCP planting_motif v7 grass_motif|groundcover|height=11.023622047`: accepted grass motif, `81` definition faces, live bounds `0.8973 x 0.3168 x 0.6246m`.
- `SU_MCP planting_motif v7 edge_motif|groundcover|height=11.023622047`: accepted edge motif, `18` definition faces.
- `SU_MCP tree_proxy v1 height=94.488188976|canopy_x=70.866141732|canopy_y=62.992125984|trunk=7.086614173`: reused by both tree proxies, `182` definition faces.

Hosted test artifacts were intentionally left in the model for inspection:

- `sem16-fixture-terrain`
- `sem16-fixed-pocket`
- `sem16-draped-pocket`
- `sem16-reuse-pocket`
- `sem16-rich-draped-pocket`
- `sem16-tree-baseline`
- `sem16-tree-anchored`
- `sem16-wave-terrain-x50-validation-v1`
- `sem16-wave-patch-small-crest-v1`
- `sem16-wave-patch-long-ridge-v1`
- `sem16-wave-patch-mid-saddle-v1`
- `sem16-wave-patch-large-basin-v1`
- `sem16-wave-patch-diagonal-shoulder-v1`

## Estimation Calibration

- Task-estimation calibration is complete in `size.md`; final status is `calibrated`.

## Remaining Gaps

- Generated definitions are not garbage-collected when they become unused; the plan explicitly deferred generated-definition cleanup.
- Hosted visual verification passed for the SEM-16 matrix above after replacing the initial placeholder motif with the accepted production low-poly matrix/edge/grass/perennial motif vocabulary.
- Large planting footprints can still look sparse because motif count is capped at `32` independent of footprint area; area-scaled density is deferred.
- Automated tests assert rich generated motifs and materialized underlay, but exact accepted motif bounds remain covered by hosted verification rather than CI assertions.
