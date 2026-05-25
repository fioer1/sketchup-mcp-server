# MTA-43 Implementation Queue

This queue is the Step 03 hardened implementation queue for MTA-43. It exists so
implementation can resume safely after context compaction without narrowing the
task to only early unit-test slices.

Before creating or changing production code, reload this file together with
`task.md`, `plan.md`, and `size.md`.

## Guardrail

Planner unit tests are only the first layer. A behavior is not delivered until
the downstream integration path that consumes it is also covered:

- `TerrainOutputPlan`
- command evidence and feature patch batching
- `TerrainMeshGenerator`
- registry writes and no-delete behavior
- replay/result/classifier evidence
- public no-leak contract coverage
- hosted SketchUp validation where plain Ruby cannot prove behavior

## Expanded Queue

| # | Slice | Required Coverage | Focused Validation |
|---:|---|---|---|
| 1 | Pure component planner shape | New `PatchComponentPlanner` preserves existing keys: `affectedPatchIds`, `replacementPatchIds`, `affectedPatches`, `replacementPatches`, `conformanceRing` | `bundle exec ruby -Itest test/terrain/output/patch_lifecycle/patch_component_planner_test.rb` |
| 2 | Local dirty window stays local | Dirty-only window produces current local affected/replacement/conformance scope, no promotion verdict, no far patches | planner test |
| 3 | Feature boundary crossing | Individual feature source windows crossing patches promote connected component; records `feature_boundary_crossing`; bounded component size | planner test |
| 4 | Protected boundary crossing | Protected source windows promote connected component; records `protected_boundary_crossing`; role counts are correct | planner test |
| 5 | Retained seam dependency | Retained seam source can promote retained neighbor; records `retained_seam_dependency`; classifies retained-boundary role | planner test |
| 6 | Conformance role | Conformance patches remain distinct from affected/replacement and record `conformance` reason where relevant | planner test |
| 7 | Safety-margin metadata | Safety-margin patches are reported as metadata only and do not expand replacement scope | planner test |
| 8 | Local-detail placeholder | Empty local-detail sources are accepted as shape-only; non-empty local-detail sources fail fast as unsupported | planner negative test |
| 9 | Budget policy constants | Defaults are enforced: `maxReplacementPatchCount: 25`, `maxPromotionRadius: 2` | planner test |
| 10 | Budget overrun verdict | Over-budget component records internal budget status, counts/radius/reasons, and no raw patch IDs | planner test |
| 11 | Evidence-only budget signals | Replacement/affected ratio and full-grid proximity are evidence only, not hard gates | planner test |
| 12 | Output plan sealed carrier | `TerrainOutputPlan.dirty_window` carries `adaptive_lifecycle_resolution` before adaptive cells/seams are built | `terrain_output_plan_test.rb` |
| 13 | Output plan uses sealed domains | Adaptive cells are built from sealed replacement/conformance domains, not a recomputed resolver result | output plan test |
| 14 | Seam artifacts use sealed scope | Sealed seam plan replacement IDs match the component resolution replacement IDs | output plan test |
| 15 | Source-of-truth invariant | Successful component-planned output paths fail if old `PatchWindowResolver` recompute is invoked after sealing, including component-source output planning and presealed generator consumption | output plan + generator tests |
| 16 | Feature patch bundles use sealed roles | `TerrainFeaturePlanner#prepare_patch_batch` receives sealed resolution and includes affected/replacement/conformance/retained/safety roles | feature planner or command test |
| 17 | Command feature context uses sealed resolution | `TerrainSurfaceCommands#cdt_patch_feature_context` stops recomputing resolver scope and passes sealed lifecycle resolution | `terrain_surface_commands_test.rb` |
| 18 | Command evidence uses sealed resolution | Baseline evidence records component summary/timing from sealed resolution, not independent resolver output | command test |
| 19 | Component timing bucket | Component planning timing is recorded alongside command output, dirty-window, adaptive-planning, mutation, total | command/probe test |
| 20 | Mesh dirty replacement uses sealed scope | `TerrainMeshGenerator` uses sealed replacement IDs for ownership lookup, seam gate, planned patches, erase, and registry writes | `terrain_mesh_generator_test.rb` |
| 21 | Over-budget stays on safe dirty path | Output planning records the over-budget verdict from component sources, and generator still uses sealed dirty replacement when ownership, seam gate, and registry checks pass | output plan + mesh generator tests |
| 22 | Over-budget valid heightmap succeeds | Valid heightmap does not publicly refuse solely because local component budget was exceeded | mesh generator/command test |
| 23 | Unsafe fallback failure keeps old output | If an independent unsafe existing-output fallback fails, old output/registry remain intact through existing refusal behavior | mesh generator no-delete test |
| 24 | Retained seam mismatch no-delete | Registry/seam topology or digest mismatch refuses before erase and preserves old output | mesh generator test |
| 25 | No mutation-time replan | Retained seam validation failure does not trigger component replan/retry during mutation | mesh generator test |
| 26 | Registry reflects final path | Registry writes reflect component-planned dirty replacement or an independent unsafe fallback, without mixed partial state | mesh generator test |
| 27 | MTA-46 residual-probe guard | Promoted adaptive domains do not duplicate residual/error probes for the same split decision | `terrain_output_plan_test.rb` |
| 28 | Public success response no leak | Public command success payload hides component roles, patch IDs, seam records, registry records, budget internals, fallback internals | `terrain_contract_stability_test.rb` |
| 29 | Public refusal response no leak | Existing sanitized refusal shape remains stable for ownership/seam/registry failures | contract + command tests |
| 30 | No public schema/catalog change | Native tool catalog, dispatcher, request schemas, README/docs remain unchanged unless implementation intentionally violates plan | contract review + final diff check |
| 31 | Replay result component summary | Result document records component counts, max component size, role counts, promoted count, budget status, and actual fallback category only when a fallback path is used | `feature_aware_adaptive_baseline_result_document_test.rb` |
| 32 | Replay summary no raw IDs | Checked-in replay/result summaries omit raw patch IDs, seam records, registry records, budget internals | result document + contract tests |
| 33 | Classifier expected promotion | Expected bounded promotion is not treated as patch-scope regression when `expectedPromotion` is true and `componentPlanSummary.promotedCount` is positive | `feature_aware_adaptive_baseline_result_classifier_test.rb` |
| 34 | Classifier expected over-budget verdict | Expected over-budget component verdict is non-regression when component budget status is `over_budget` and mesh evidence exists | classifier test |
| 35 | Classifier unexpected expansion | Broad unexplained patch-scope expansion remains regression/failure | classifier test |
| 36 | Classifier unexpected fallback | Unexpected fallback remains regression/failure | classifier test |
| 37 | Classifier seam/missing mesh failures | Seam validation failure or missing mesh evidence remains failed | classifier test |
| 38 | Contract vocabulary expansion | Add MTA-43 no-leak terms: `componentPlanSummary`, `componentBudget`, `roleCounts`, `componentCount`, `maxComponentSize`, `promotedCount`, `graphReasons`, `maxReplacementPatchCount`, `maxPromotionRadius`, `over_budget_component`, `retainedBoundary`, `safetyMargin`, and graph reason values | contract test |
| 39 | Hosted local no-promotion row | Local edit remains patch-local or existing conformance scope; unaffected patches excluded | hosted replay |
| 40 | Hosted feature/protected promotion row | Cross-patch feature/protected source produces bounded component with roles and no full regeneration by default | hosted replay |
| 41 | Hosted retained seam row | Retained seam promotion/refusal preserves old output on mismatch | hosted replay |
| 42 | Hosted over-budget bounded row | Over-budget records budget verdict, stays on bounded dirty replacement when safe, and records timing/face impact | hosted replay |
| 43 | Hosted repeated edit/readback | Repeated edits, reload/readback, registry/entity lifecycle remain consistent | hosted replay/readback |
| 44 | Hosted retained-Z status | Either validate a small safe z-inclusive hook or explicitly record retained-Z limitation | hosted evidence |
| 45 | Broad validation | Full Ruby test suite, lint, package verification | `bundle exec rake ruby:test`, `bundle exec rake ruby:lint`, `bundle exec rake package:verify` |
| 46 | Closeout artifacts | Update `summary.md`, task status/metadata as needed, record hosted gaps, run estimate calibration | Step 06/07 |

## First Skeleton Batch

Create the failing surface before production implementation:

1. `test/terrain/output/patch_lifecycle/patch_component_planner_test.rb`
2. `test/terrain/output/terrain_output_plan_test.rb`
3. `test/terrain/output/terrain_mesh_generator_test.rb`
4. `test/terrain/commands/terrain_surface_commands_test.rb`
5. `test/terrain/contracts/terrain_contract_stability_test.rb`
6. `test/terrain/probes/feature_aware_adaptive_baseline_result_document_test.rb`
7. `test/terrain/probes/feature_aware_adaptive_baseline_result_classifier_test.rb`

## Completion Rule

Do not close MTA-43 while only planner-level behavior is green. The task is
complete only when the sealed component lifecycle resolution is consumed by
output planning, command evidence, feature patch bundles, mesh mutation,
registry writes, replay artifacts, no-leak contract tests, and hosted evidence
or explicitly recorded hosted blockers.
