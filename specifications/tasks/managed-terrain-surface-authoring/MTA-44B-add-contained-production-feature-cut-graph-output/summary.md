# Summary: MTA-44B Add Contained Production Feature Cut Graph Output

**Task ID**: `MTA-44B`  
**Title**: `Add Contained Production Feature Cut Graph Output`  
**Status**: `closed-blocked`  
**Date**: `2026-06-03`

## Disposition

MTA-44B should not be committed as production implementation in its current state.

The task produced useful implementation evidence and several reusable design ideas, but live
SketchUp validation exposed incorrect assumptions in the plan and implementation strategy. The
attempt should be closed as blocked from production completion and replaced by
[MTA-44B1](../MTA-44B1-replan-production-feature-cut-output-with-transient-constraints/task.md).

The MTA-44B implementation patch should be reverted rather than salvaged as production behavior.
Reusable lessons belong in the follow-up task and technical discovery notes, not in dead runtime
helpers.

## What Worked

The implementation attempt proved several useful points:

- Active effective feature geometry can derive topology-forcing cut constraints for simple contained
  target, corridor, planar, and control-point cases.
- Cut constraints need height semantics, not only XY paths. Explicit parallel height anchors such as
  `ownerLocalPathHeights` and `ownerLocalPointHeight` are useful for current-output constraints.
- Boundary split propagation can remove T-junctions in simple corridor-only cases.
- Generic polygon membership is a useful primitive for oriented domains such as corridor tops or
  future non-grid-aligned rectangles.
- Hosted measurement harnesses were useful for distinguishing manifoldness, single-use raised
  edges, tiny slivers, and wrong in-domain heights.

These ideas are captured in
[MTA-44B1 technical discovery notes](../MTA-44B1-replan-production-feature-cut-output-with-transient-constraints/technical-discovery-notes.md).

## What Failed

The core failure is that MTA-44B blurred disposable output constraints with durable edit history.

Feature cuts and height/topology constraints are requirements for one generated mesh output pass.
They must not persist as constraints that keep affecting later terrain edits. During live
verification, older target/circle/corridor domains continued to influence later output, which made
fairing ineffective over previous shapes. That violates the expected terrain workflow.

The adaptive contained rewriter also proved insufficient for composed/intersecting boundaries:

- Circle plus corridor could be manifold while still semantically wrong.
- Multi-origin cut cells remained a real gap.
- Near-corner snapping improved numeric sliver metrics but damaged corridor shape when made more
  aggressive.
- Polygon oracle experiments fixed one corridor-over-circle height symptom but introduced the wrong
  lifetime model when wired through persisted feature intent.

## Validation Evidence

Local validation did pass for the attempted implementation and later fixes, but the green tests do
not make the task shippable because hosted validation exposed product-model failures.

Representative local validation from the last live-fix phase:

- Affected suite:
  `bundle exec ruby -Itest -e 'ARGV.each { |path| load path }' ...`
  across feature geometry, output policy, output plan, mesh generator, composed oracle, and replay:
  `213 runs, 3472 assertions, 0 failures, 0 errors, 0 skips`.
- RuboCop across affected runtime/test files:
  `14 files inspected, no offenses detected`.

Earlier focused runs also validated corridor-only manifold improvements and cut-height anchor
behavior. These validations are evidence for discovery, not acceptance for commit.

## Hosted SketchUp Evidence

Hosted fixtures were created with increasing x positions and left as visual/measurement evidence.

Key observations:

- `mta44b-live-corridor-x610-conservative`
  - corridor-only output became visually acceptable after reverting aggressive snapping
  - measured manifold
  - retained small slivers but no raised single-use internal edges
- `mta44b-live-composed-x630-conservative`
  - circle then corridor was manifold
  - corridor top still contained old circle-height vertices
- `mta44b-live-composed-x670-polygon-oracle`
  - polygon/oracle experiment made the corridor top planar through the circle overlap
  - subsequent fairing discussion showed this approach encoded the wrong durable-constraint
    lifetime and is not production-safe

The hosted result is therefore not "ready with a few bugs"; it is evidence that the plan is blocked
from production completion and needs a new task boundary.

## Code Review Status

The earlier implementation queue was reviewed during development, including second-opinion review
against gaps and the implementation handover. Final Step 06 code review should not be treated as
complete because the task is being closed before production closeout. The appropriate next review
target is the MTA-44B1 plan, not the current MTA-44B patch stack.

## Public Contract And Docs

Public MCP terrain request contracts were not intentionally changed. The attempted implementation
added internal evidence fields such as `featureCutSummary` in baseline/replay evidence. Those should
not be assumed safe to keep unless a later narrow diagnostic-only salvage commit explicitly validates
that they remain internal and separately invokable.

No user-facing docs should be updated to describe MTA-44B behavior because MTA-44B is not shipping.

## Salvage Guidance

Do not commit dead helper code solely to preserve work from the failed attempt.

Potentially useful ideas for MTA-44B1 planning:

- transient cut-local height anchors
- generic polygon/ring membership for current-output domains
- boundary split propagation as a contained/simple-case fallback
- hosted metrics for manifoldness, raised single-use edges, slivers, and wrong in-domain heights

Unsafe as current production behavior:

- always running `ContainedFeatureCutRewriter` from `TerrainOutputPlan`
- treating adaptive templates as the general solution for composed feature cuts
- wiring persisted feature intent into durable height-imposing oracle domains
- depending on stale composed-oracle domains to override cut-vertex heights
- aggressive near-corner snapping

## Follow-Up

Created follow-up task:

- [MTA-44B1 Replan Production Feature Cut Output With Transient Constraints](../MTA-44B1-replan-production-feature-cut-output-with-transient-constraints/task.md)
- [MTA-44B1 Technical Discovery Notes](../MTA-44B1-replan-production-feature-cut-output-with-transient-constraints/technical-discovery-notes.md)

Recommended next action before planning MTA-44B1:

1. Revert the MTA-44B runtime/test implementation changes.
2. Keep this `summary.md`, the MTA-44B1 task, and the MTA-44B1 technical discovery notes.
3. Plan MTA-44B1 from the corrected transient-output-constraint model, with an explicit
   adaptive-only versus CDT/hybrid decision gate.
