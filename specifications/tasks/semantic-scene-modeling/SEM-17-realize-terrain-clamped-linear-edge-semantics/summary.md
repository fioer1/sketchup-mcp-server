# Summary: SEM-17 Realize Terrain-Clamped Linear Edge Semantics

**Task ID**: `SEM-17`
**Status**: `implemented`
**Date**: `2026-05-27`

## Shipped Behavior

- `retaining_edge + hosting.mode: "edge_clamp"` now samples the resolved host surface and builds a terrain-clamped linear edge shell instead of falling back to planar `z = 0` geometry.
- Unhosted planar `retaining_edge` behavior remains compatible, including optional `definition.elevation` as the planar base.
- Added canonical `edge_restraint` under `create_site_element` for low path/hardscape restraints, curbs, setts, and stone or metal edging.
- `edge_restraint` is hosted-only for SEM-17 with `hosting.mode: "edge_clamp"` and `definition.mode: "polyline"`, `definition.polyline`, `definition.height`, and `definition.thickness`.
- `edge_restraint.definition.elevation`, public alias element types such as `curb` or `path_edge`, and width-as-edge-dimension aliases are refused or omitted from the public contract.
- Hosted linear-edge failures plan host sections before wrapper creation, so invalid hosts, sample misses, and station-cap overflow do not leave partial managed objects.
- Managed metadata preserves semantic type plus linear-edge `height` and `thickness` for both retained walls and restraint edges.
- Generated retaining-edge, edge-restraint, and path geometry now hides only coplanar internal triangulation edges. Boundary edges and non-coplanar hard arrises remain visible.
- Public MCP catalog and docs now explain retaining-edge versus edge-restraint selection, edge-clamp-only hosting for linear edges, explicit edge centerline behavior, and why outside path restraints should clamp to terrain or a surface that exists under the edge centerline.

## Contract Alignment

- Public entrypoint remains `create_site_element`; no new tool was added.
- Runtime validator, request-shape contract, normalizer, command hosting matrix, builder registry, native schema, contract fixtures, docs, and public posture tests agree on the `edge_restraint` type and field set.
- Discoverability exists before a bad call through `tools/list` descriptions and docs, and after a bad call through contextual refusal details with `allowedValues`.
- `surfaceOffset` remains documented and tested as approximate acceptance evidence for z=0/off-terrain regressions, not exact edge-topology validation.

## Validation Evidence

- Full Ruby test suite after final hard-edge correction:
  - `bundle exec rake ruby:test`
  - `1610 runs`, `21823 assertions`, `0 failures`, `0 errors`, `42 skips`
- Full runtime lint after final hard-edge correction:
  - `bundle exec rake ruby:lint`
  - `381 files inspected`, `no offenses detected`
- Package verification after final hard-edge correction:
  - `bundle exec rake package:verify`
  - produced `dist/su_mcp-1.15.0.rbz`
- Focused geometry checks covered:
  - hosted retaining-edge multi-z shell output
  - invalid host/sample-miss/station-cap refusals without created groups
  - retaining-edge planar compatibility
  - edge-restraint create/replace metadata
  - path and retaining-edge internal triangulation hiding while preserving hard and boundary edges
- Public contract checks covered:
  - native tool catalog schema exposure
  - native contract fixture posture
  - public MCP docs posture
  - semantic request validation, normalization, and malformed-shape recovery
  - `surfaceOffset` pass/fail evidence for terrain-relative semantic edges

## Review Disposition

- Local `task-review` deterministic pass ran `tldr bugbot`, `tldr smells`, `tldr hotspots`, and `tldr secure`.
  - `bugbot`: `0` L1 findings; `7` L2 findings.
  - Production L2 finding was the optional keyword expansion on `RetainingEdgeBuilder#initialize`; accepted as non-blocking dependency injection with no caller break.
  - Test-helper signature and long-test-method findings were accepted as non-blocking.
  - `tldr secure`: no findings.
- PAL `grok-4.3` final review found no blocking issues.
  - Low observations about optional constructor complexity, retained `retaining_edge` elevation compatibility, and wording consistency were accepted as non-blocking.
- Post-review delta check for the final edge-visibility correction found no required changes.
  - The medium note about the `0.999` coplanar-normal threshold is accepted as an appropriate local tolerance for the current scope and can be tuned later if real geometry proves it too permissive or strict.

## Live SketchUp Verification

- Deployed changed runtime files into the SketchUp plugin and reloaded them with `eval_ruby`.
- Rebuilt the native runtime and verified `ping`.
- Queried the public MCP HTTP `tools/list` endpoint with `curl` and confirmed the updated `create_site_element` catalog text was live.
- Created realistic hosted verification scenes on existing terrain during the implementation pass, including terrain-clamped retaining edges and edge restraints beside sinuous draped paths.
- User visually reviewed the final path/edge behavior and confirmed the corrected catalog guidance created the edge correctly on the first try.
- Created a draped path on the canonical existing terrain after adding path triangle hiding; user visually inspected it, liked it, and removed it.
- The final hard-edge correction was copied and reloaded into SketchUp after tests. No additional retained-edge visual object was left in the scene for this correction.

## Remaining Gaps

- Path-relative restraint derivation is still a follow-up: callers must provide the explicit edge centerline rather than referencing a path plus side/alignment.
- `surfaceOffset` remains approximate bounds-anchor validation, not exact edge-topology validation.
- The final hard-edge visibility rule is tested and loaded, but a fresh live retained-edge object was not left in the scene after that last correction.
