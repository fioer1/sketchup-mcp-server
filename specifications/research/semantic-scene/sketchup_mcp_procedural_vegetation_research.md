# Procedural Vegetation Roadmap for SketchUp MCP

_Updated: 2026-05-22_  
_Update scope: rectified against current Semantic Scene Modeling and Staged Asset Reuse product lanes, while preserving research pressure for generated/variant asset capabilities._

## Executive Summary

This document evaluates procedural vegetation ideas for a Ruby SketchUp MCP extension. It is not a direct Unreal Engine roadmap. Unreal Foliage, PCG, and Procedural Vegetation Editor (PVE) are useful because they expose durable patterns: authored presets, point-based placement, deterministic generation, density/spacing policies, reusable instances, terrain frames, and controlled variation. The product decision is how those ideas fit into SketchUp's existing semantic and staged-asset lanes.

Current repo reality has two strong lanes:

- **Semantic generated proxies**: `create_site_element` owns `planting_mass`, `tree_proxy`, terrain relationships, deterministic proxy generation, Managed Scene Object metadata, and JSON-safe semantic results.
- **Staged asset reuse**: `curate_staged_asset`, `list_staged_assets`, and `instantiate_staged_asset` own approved in-scene Asset Exemplars, editable Asset Instances, source lineage, asset-set metadata, and source stability.

Those lanes cover important workflows but leave a gap: staged assets are reusable but static beyond placement transforms, while semantic proxies are generated but intentionally low-fidelity. Current staged-asset behavior can vary scale, position, and orientation. It does not safely support slight geometry, material, or texture variants. That limitation matters for vegetation, where users often want a set of related shrubs, groundcover clumps, seasonal color variants, or tree silhouettes that look related but not copy-pasted.

The gap should not be solved by arbitrary procedural mutation of approved staged assets. Many staged assets have UV-mapped textures. Editing their mesh, UVs, materials, or textures casually can break authored appearance and designer trust. The safer product direction is a **variation-safe generated asset lane**: only assets explicitly authored or approved for variation, or extension-owned generated low-poly/proxy sources, may produce controlled variants with deterministic lineage and geometry budgets.

This document therefore has three kinds of recommendations:

- **Current implementation guidance**: follow existing SEM/SAR ownership and public tools.
- **Proposed product-lane changes**: evaluate a generated/variant asset sub-capability that may require PRD/HLD updates.
- **Research-only speculation**: keep PVE/PCG recipe ideas available without treating them as current contracts.

## Classification Legend

Each major recommendation below is labeled:

- **Current**: matches shipped or task-backed repo behavior and can guide implementation now.
- **Proposal**: argues for changing or extending product lanes; requires PRD/HLD/task updates before implementation.
- **Research**: a useful idea, analogy, or future concept that is not ready to drive product work.

## Source-of-Truth Cross-Validation

Use these documents as authority when separating current guidance from proposals:

| Source | Status in this document |
|---|---|
| `specifications/prds/prd-semantic-scene-modeling.md` | Current source for semantic creation, Managed Scene Objects, `planting_mass`, `tree_proxy`, stable identity, and compact public contracts. |
| `specifications/hlds/hld-semantic-scene-modeling.md` | Current source for Ruby semantic runtime ownership, builders, metadata, operation boundaries, serialization, and identity-preserving rebuild posture. |
| `specifications/tasks/semantic-scene-modeling/SEM-16-realize-terrain-sampled-planting-mass-proxy-representation/task.md` | Current source for `planting_mass + hosting.mode: "surface_drape" + representation.mode: "proxy_mass"` generated proxy behavior. |
| `specifications/prds/prd-staged-asset-reuse.md` | Current source for approved Asset Exemplars, editable Asset Instances, source lineage, protection, and curated in-scene reuse. |
| `specifications/hlds/hld-asset-exemplar-reuse.md` | Current source for staged-asset discovery, approval, asset-set metadata, instantiation, replacement posture, and source stability. |
| `specifications/tasks/staged-asset-reuse/SAR-01-curate-and-discover-approved-asset-exemplars/task.md` | Current/completed source for curation and `list_staged_assets`. |
| `specifications/tasks/staged-asset-reuse/SAR-02-instantiate-editable-asset-instances/task.md` | Current/completed source for `instantiate_staged_asset`, editable instances, and source lineage. |
| `specifications/tasks/staged-asset-reuse/SAR-04-replace-proxies-with-staged-assets/task.md` | Draft source for proxy-to-staged-asset replacement. |
| `specifications/tasks/staged-asset-reuse/SAR-06-tiled-groundcover-area-placement/task.md` | Draft source for repeated groundcover/tile placement from approved staged assets. |
| `specifications/research/asset-reuse/low_poly_garden_vegetation_inventory.md` | Current reference for low-poly vegetation prompts and category-specific asset-set metadata examples. |

## Current Product Lanes

### Current: Semantic Generated Proxies

Semantic generated vegetation belongs to `create_site_element` when it is an early-design Managed Scene Object.

Current semantic vegetation scope:

- `tree_proxy` is a semantic element type, not a staged asset.
- `planting_mass` is a semantic element type.
- `planting_mass + representation.mode: "proxy_mass"` creates deterministic low-poly planting motif instances and terrain-derived underlay geometry from the requested boundary.
- `planting_mass + hosting.mode: "surface_drape"` expresses terrain-following planting behavior.
- Semantic proxy output must remain JSON-safe, deterministic, lightweight, and owned by Ruby semantic builders/collaborators.
- Public proxy controls should remain compact. SEM-16 explicitly does not expose seed, spacing, count, style, edge-fade, or component-strategy fields as current public `planting_mass` controls.

Semantic generated proxies are good for:

- early site layout;
- legible design intent;
- terrain-following planting pockets;
- deterministic generated motif distribution;
- stable Managed Scene Object identity for later revision or replacement.

Semantic generated proxies are not good for:

- final curated asset quality;
- UV-mapped presentation assets;
- broad asset-library variation;
- botanical realism;
- uncontrolled plant graphs.

### Current: Staged Asset Reuse

Staged asset reuse belongs to the staged-asset tools when the workflow starts from a human-curated in-model source.

Current staged-asset scope:

- `curate_staged_asset` marks an existing group/component instance as an approved Asset Exemplar.
- `list_staged_assets` discovers approved Asset Exemplars using structured filters.
- `instantiate_staged_asset` creates a separate editable Asset Instance at model root with source lineage and placement evidence.
- Current instantiation supports placement-level variation, including position, optional direct scale, and orientation behavior where supported.
- Asset Exemplars and Asset Instances are distinct domain objects.
- Normal reuse workflows must not mutate source Asset Exemplars in place.
- Category-specific metadata can live under JSON-safe `assetAttributes`; vegetation fields are examples, not universal schema.

Staged assets are good for:

- reliable reuse of approved in-scene assets;
- project-scoped vegetation libraries;
- preserving curated source quality;
- source lineage;
- proxy-to-asset upgrade once SAR-04 exists;
- placement variation where transforms are sufficient.

Staged assets are not currently good for:

- procedural geometry variants;
- UV-safe material or texture variants;
- recipe-driven asset generation;
- converting one exemplar into a family of related generated assets;
- distinguishing "generated but not approved" versus "generated and approved for reuse".

## Gap Analysis

### Proposal: Static Exemplar Reuse Versus Controlled Asset Variation

The current product lanes leave a meaningful middle ground uncovered.

The desired user outcome is not arbitrary asset mutation. It is controlled variety:

- a clipped hedge and a looser hedge family derived from the same design role;
- two or three canopy silhouettes for a low-poly tree family;
- seasonal color variants when the asset was authored with swappable material slots;
- repeated groundcover tiles that vary slightly without visible copy-paste patterns;
- shrub families that share metadata, style, scale range, and lineage without requiring every variant to be separately hand-placed.

Current SAR can place one exemplar many times with transform variation. That solves repetition only partly. It does not create asset-level variety. Current SEM can generate proxy geometry, but proxy generation is semantic-object output, not an asset-library model. The missing product question is:

> Should SketchUp MCP support variation-safe generated Asset Instances or generated Asset Exemplars, and if so, should that live inside SAR, beside SAR, or as a bridge from SEM-generated proxy sources?

### Current Constraint: UV-Mapped Staged Assets Are Protected

Most ordinary staged assets should be treated as authored artifacts. If they have UV-mapped textures, procedural edits can break:

- UV alignment;
- material appearance;
- texture seams;
- author expectations;
- source-exemplar integrity;
- downstream visual review.

Therefore, current and proposed behavior should use this default rule:

> Approved Asset Exemplars are not procedurally mutated unless they explicitly declare a variation-safe policy.

Safe variation options, from least to most invasive:

1. Placement transforms: position, scale, orientation. This is current SAR territory.
2. Curated sibling exemplars: multiple approved variants selected by metadata.
3. Declared material-slot swaps: only where an exemplar states that specific material slots may be swapped.
4. Generated low-poly/proxy variants: only where the extension owns geometry/mapping and budget.
5. Authored procedural recipes: only for assets explicitly created for recipe-driven variation.

## Unreal and PVE Lessons Reconciled

### Current/Research: Foliage Mode

Unreal Foliage Mode shows why reusable asset types, density controls, random scale/yaw, surface alignment, and batch operations matter. In SketchUp MCP, the current analogs are split:

- placement transforms and source reuse belong to staged assets;
- semantic planting regions and deterministic generated motifs belong to `planting_mass`;
- broad paint/brush UI is not a current public MCP goal.

Product pressure from Foliage Mode: SAR-06-style area placement and per-instance orientation are more important than a paint UI.

### Current/Research: Procedural Foliage Spawner

Unreal's procedural spawner uses seed density, overlap/collision radius, clustering, priority, and blocking volumes. The transferable pattern is deterministic candidate generation and pruning, not biological simulation.

Current alignment:

- SEM-16 already owns deterministic planting proxy generation.
- Future SAR-06 area coverage can reuse deterministic placement and skip/refusal evidence.

Proposal pressure:

- If repeated staged-asset placement needs density, collision, and terrain filters, those policies should be formalized as staged-asset area-placement behavior, not hidden in semantic proxy code.

### Current/Research: PCG Framework

PCG's useful pattern is:

```text
spatial input -> point data -> attributes -> filters -> transforms -> output
```

SketchUp MCP translation:

```text
intent/boundary/target
  -> surface or terrain sampling
  -> candidate points
  -> filters and budgets
  -> placement frames
  -> generated proxy output or staged Asset Instances
  -> metadata, lineage, diagnostics
```

Current guidance: use this as an internal pipeline pattern only. Do not expose a public PCG graph.

Proposal pressure: if variant-safe generated assets become a product lane, recipes may use PCG-like internals, but public tools should still expose bounded intent, not arbitrary nodes.

### Proposal/Research: Procedural Vegetation Editor (PVE)

PVE is more relevant to asset generation than to scattering. Its strongest transferable idea is preset discipline: start from authored plant presets and produce controlled variants rather than synthesizing everything from scratch.

PVE should not become a SketchUp MCP clone target. Nanite, skeletal vegetation, wind, per-leaf detail, and full plant-growth graphs are outside the SketchUp runtime posture.

The useful PVE pressure is this:

> Curated staged assets solve reuse, but not variation. If we want asset families rather than repeated clones, we need variation-safe presets, recipes, signatures, and lineage.

That pressure should feed a product-lane proposal, not current SEM/SAR implementation guidance.

## Revised Capability Ladder

### Level 0: Semantic Proxy Objects

**Classification: Current**

Purpose: create semantic site objects that are legible and revisable.

Includes:

- `tree_proxy`;
- `planting_mass`;
- `representation.mode: "proxy_mass"`;
- Managed Scene Object metadata;
- terrain relationship fields where supported.

### Level 1: Terrain-Sampled Planting Proxies

**Classification: Current**

Purpose: make `planting_mass + proxy_mass` visually useful without requiring curated assets.

Includes:

- deterministic motif placement;
- terrain-derived underlay;
- component definition reuse where implemented;
- no new public seed/spacing/style controls by default;
- JSON-safe evidence through semantic command plumbing.

### Level 2: Curated Exemplar Discovery and Instantiation

**Classification: Current**

Purpose: reuse approved in-scene assets safely.

Includes:

- `curate_staged_asset`;
- `list_staged_assets`;
- `instantiate_staged_asset`;
- Asset Exemplar approval;
- Asset Instance source lineage;
- optional project asset-set metadata under `assetAttributes`;
- position, scale, and orientation placement behavior.

### Level 3: Proxy-to-Asset Replacement

**Classification: Draft / Current planned**

Purpose: upgrade lower-fidelity proxies to approved Asset Instances without losing business identity.

Owned by SAR-04, not by semantic proxy generation.

Expected behavior:

- preserve `sourceElementId`;
- preserve semantic role where required;
- write source exemplar lineage;
- avoid mutating the source Asset Exemplar;
- return JSON-safe replacement evidence.

### Level 4: Tiled or Area Placement from Staged Assets

**Classification: Draft / Current planned**

Purpose: cover regions with repeated approved tile/clump assets without scaling one rigid object over varied terrain.

Owned by SAR-06-style area coverage.

Expected behavior:

- tile-capable metadata;
- placement cap or refusal path;
- per-instance source lineage;
- per-instance or summarized surface evidence;
- no mutation of source exemplars.

### Level 5: Variation-Safe Generated Asset Variants

**Classification: Proposal**

Purpose: bridge static curated reuse and low-fidelity semantic generation.

Possible scope:

- generated variants from extension-owned low-poly/proxy sources;
- generated Asset Instances with recipe/signature lineage;
- optional promotion of generated results into approved Asset Exemplars after explicit curation;
- material-slot swaps only where assets declare swappable slots;
- curated sibling variant families selected through staged-asset metadata;
- generated clump/groundcover tile variants only for assets designed for that.

This level requires product-lane changes before implementation.

### Level 6: Rich PVE-Like Plant Recipes

**Classification: Research**

Purpose: preserve a long-term idea for curated plant-family generation.

This is not current product guidance. It may become relevant only after Level 5 proves useful and safe.

## Product-Lane Change Proposal

### Proposal: Generated Asset Variants

#### Problem

Staged assets currently treat curated geometry as static source material. That is correct for source safety, especially when assets have UV-mapped textures. But vegetation workflows often need controlled variation that is more than placement transforms:

- sibling forms in the same planting family;
- seasonal or material variants;
- subtle low-poly silhouette variety;
- repeated groundcover or shrub clumps that avoid obvious duplication.

Current SAR cannot express that as asset-level variation. Current SEM can generate proxies, but those proxies are semantic representations, not reusable staged assets with asset lineage and approval state.

#### Candidate Ownership

Recommended direction:

> Add an asset-generation or generated-variant sub-capability adjacent to SAR, consumed by SAR replacement/instantiation workflows, rather than folding the behavior into semantic builders.

Rationale:

- The generated result is asset-like: it needs source lineage, variant evidence, approval state, and reuse policy.
- SEM should keep owning semantic intent and proxy representation.
- SAR should keep owning exemplar/instance identity, source protection, and asset workflows.
- A SAR-adjacent sub-capability can consume generated semantic proxy sources where useful without making semantic builders responsible for asset libraries.

Possible product names, research-only:

- Generated Asset Variant;
- Variation-Safe Asset;
- Generated Asset Instance;
- Generated Asset Exemplar Candidate.

#### Candidate Public Surface

No public tool is proposed as current guidance. If promoted, possible shapes include:

- a new staged-asset tool such as `create_staged_asset_variant`;
- an extension to `instantiate_staged_asset` that accepts a variation policy only for variation-safe exemplars;
- an explicit curation flow that turns a generated variant into an approved Asset Exemplar.

Any public surface must update:

- native tool catalog;
- dispatcher tests;
- contract fixtures;
- docs;
- staged-asset PRD/HLD;
- SAR task backlog.

#### Candidate Inputs

Inputs should be bounded and JSON-safe:

- source exemplar reference or generated-proxy source reference;
- asset-set metadata;
- recipe or variation policy id;
- deterministic seed/signature;
- representation target;
- allowed variation parameters;
- geometry budget;
- material-slot policy, if any;
- output approval policy.

Not acceptable:

- arbitrary public node graph;
- free-form Ruby;
- unbounded random generation;
- mesh/UV mutation of ordinary UV-mapped exemplars;
- hidden mutation of approved source assets.

#### Candidate Outputs

Outputs should include:

- generated variant identity;
- source exemplar or source semantic object lineage;
- recipe/policy id;
- deterministic signature;
- generated component definition identity when applicable;
- material-slot or sibling-variant evidence;
- geometry budget evidence;
- approval state;
- editable Managed Scene Object / Asset Instance classification where applicable.

#### Variation-Safe Policy

A source is variation-safe only when at least one of these is true:

- it is an extension-owned generated low-poly/proxy source with known geometry and material behavior;
- it is an Asset Exemplar explicitly marked with variation metadata;
- it belongs to a curated sibling family where variants are separate approved exemplars;
- it declares material slots that may be swapped without UV edits;
- it is a tile/clump asset designed for procedural placement or shape variation.

#### Minimum Validation Before PRD/HLD Update

Before changing SAR or introducing a new asset-generation lane, prove:

- a representative variation-safe low-poly plant can generate deterministic variants;
- ordinary UV-mapped exemplars refuse procedural mesh/UV/material mutation;
- source exemplars remain unchanged;
- generated variants carry lineage and signatures;
- geometry budgets prevent runaway component definitions;
- generated results can be serialized without raw SketchUp objects;
- a user can understand whether a result is approved, editable, reusable, or only a generated instance.

## Architecture Guidance

### Current: Keep Semantic Generation in Semantic Builders

`PlantingMassBuilder`, `PlantingMassProxyBuilder`, `TreeProxyBuilder`, generated component reuse helpers, terrain/surface sampling wrappers, and semantic serializers are the right home for current proxy output.

Do not move semantic proxy generation into staged assets just because the output contains plant-like motifs. The semantic object remains the durable unit of intent.

### Current: Keep Asset Exemplar and Asset Instance Rules in SAR

Asset approval, source stability, asset-set metadata, instantiation, lineage, and replacement belong to staged assets.

Do not classify component definitions globally as exemplars by default. Current HLD guidance prefers curated group/component instances because definition-level metadata can unintentionally classify every instance of a shared definition.

### Proposal: Add a Generated Variant Boundary

If generated asset variants are promoted, use a boundary like:

```text
Source Exemplar or Generated Proxy Source
  -> variation-safe policy check
  -> recipe/preset resolver
  -> deterministic variant generator
  -> generated component definition or instance
  -> lineage + signature metadata
  -> optional curation/approval state
  -> staged-asset serializer / semantic replacement consumer
```

This boundary should not expose raw SketchUp objects or internal graph nodes.

## Public MCP Surface

### Current Tools

Current public tools relevant to vegetation are:

- `create_site_element`;
- `set_entity_metadata`;
- `curate_staged_asset`;
- `list_staged_assets`;
- `instantiate_staged_asset`.

Current docs describe:

- `planting_mass -> surface_drape`;
- `tree_proxy -> terrain_anchored`;
- `planting_mass` with `representation.mode: "proxy_mass"` creating deterministic low-poly planting motif instances and terrain-derived underlay geometry.

### Draft / Planned Tooling

`replace_with_staged_asset` is a SAR-04 draft concept, not a current shipped public tool in the catalog checked for this update.

### Proposal-Only Tooling

Any generated-variant tool is proposal-only. The research may discuss possible names and shapes, but must not present them as current MCP surface.

## Data and Metadata Model

### Current Semantic Metadata

Semantic Managed Scene Objects preserve fields such as:

- `sourceElementId`;
- `semanticType`;
- `status`;
- `plantingCategory` where supported;
- `speciesHint` where supported;
- lifecycle and representation data through current semantic conventions.

### Current Staged-Asset Metadata

Asset Exemplar and Asset Instance metadata includes:

- approval state;
- asset identity;
- source lineage;
- asset-set metadata;
- category-specific `assetAttributes`;
- placement and bounds evidence where requested.

Vegetation-specific `assetAttributes` may include:

- `assetSet`;
- `assetKey`;
- `archetype`;
- `plantingRole`;
- `representedSpecies`;
- `designHeightMeters`;
- `heightRangeMeters`;
- `heightClass`;
- `style`;
- `variantHints`;
- `usageNotes`.

These are examples for vegetation, not universal fields for every asset category. `designHeightMeters` is design-component evidence and should not trigger automatic height fitting during instantiation.

### Proposal: Variation Metadata

Generated asset variants would need explicit metadata, for example:

```yaml
variationPolicy:
  mode: variation_safe
  allowedKinds:
    - material_slot_swap
    - generated_low_poly_geometry
  protectedKinds:
    - source_mesh_uvs
    - source_texture_maps
  recipeId: low_poly_shrub_fullness_v1
  generatorVersion: su_mcp_generated_variant/1
  deterministicSignature: sha256:...
```

This is not a current contract. It is a candidate shape to evaluate.

### Research: Recipe Terms

Terms such as `VegetationKit`, `PlantPalette`, `PlantAssetRecipe`, `MotifDefinition`, and `RepresentationTier` may remain useful as research vocabulary, but current-state sections should map them to repo concepts:

| Research term | Current or proposed repo mapping |
|---|---|
| `VegetationKit` | Current `assetSet` + `assetAttributes`, or proposal-only preset family. |
| `PlantPalette` | Current staged-asset filters/metadata, current semantic internal defaults, or proposal-only palette. |
| `MotifDefinition` | Current semantic proxy-generation internal, not a public MCP contract. |
| `GeneratedComponentSignature` | Current generated component definition reuse pattern; proposal may extend it for generated asset variants. |
| `PlantAssetRecipe` | Proposal/research for generated variants; not current SAR or SEM contract. |
| `RepresentationTier` | Research shorthand; current contracts should use actual `representation.mode` values and staged-asset approval/instance classifications. |

## Task Backlog Reconciled to Repo

### Current / Completed

- `SEM-16`: terrain-sampled `planting_mass + proxy_mass` generated proxy behavior.
- `SAR-01`: curate and discover approved Asset Exemplars.
- `SAR-02`: instantiate editable Asset Instances with source lineage.
- `SAR-05`: orientation-aware placement, where relevant to staged asset placement behavior.

### Draft / Planned

- `SAR-04`: replace proxies with staged assets.
- `SAR-06`: tiled groundcover area placement.

### Proposed New Product Work

If generated variants are accepted as product direction, create new task shells rather than burying work in existing tasks:

1. **Define variation-safe staged asset metadata**
   - Decide how exemplars declare safe material slots, sibling families, tile variation support, or generated-source eligibility.
   - Update staged-asset PRD/HLD if accepted.

2. **Prototype generated low-poly asset variants**
   - Use extension-owned generated/proxy sources, not arbitrary UV-mapped staged assets.
   - Prove deterministic output and geometry budgets.

3. **Generated variant lineage and signature**
   - Define how generated component definitions and instances record source, recipe, generator version, and deterministic signature.

4. **Generated result approval policy**
   - Decide whether generated variants are Asset Instances only, Asset Exemplar candidates, or directly approved exemplars under strict conditions.

5. **Proxy-to-generated-variant replacement**
   - Evaluate whether SAR-04 should support replacing a semantic proxy with a generated variant in addition to an approved existing exemplar.

6. **Curated sibling variant discovery**
   - Support variant families through asset-set metadata before attempting procedural mesh or texture changes.

## Performance and Geometry Budget Guidance

### Current

SketchUp does not provide Unreal-style Nanite, GPU foliage instancing, automatic LOD, skeletal vegetation animation, or wind systems. Use:

- `ComponentDefinition` reuse;
- bounded instance counts;
- deterministic generation;
- explicit geometry budgets;
- structured refusals for excessive requests;
- underlay/proxy geometry for early design;
- approved staged assets for curated fidelity.

### Proposal

Generated variants need stricter budgets than ordinary instantiation:

- maximum generated definitions per source/recipe;
- maximum faces per generated variant;
- maximum instances per operation;
- deterministic signature reuse to avoid duplicate definitions;
- cleanup/stale-definition policy;
- refusal when a requested variant would exceed budget.

## Low-Poly Garden Inventory Usage

### Current

The low-poly garden inventory is reference material for curated in-model vegetation libraries and category-specific asset metadata. It is not itself a runtime catalog and does not imply automated Nano Banana, Meshy, GLB, FBX, or external ingestion support.

Use it for:

- prompt/reference guidance when humans create low-poly assets;
- candidate `assetAttributes`;
- project asset-set examples;
- staged-asset discovery and replacement scenarios;
- SAR-06 tile/coverage metadata examples.

### Proposal

If generated variants are promoted, parts of the inventory may become:

- curated sibling variant families;
- generated-source fixtures;
- recipe validation cases;
- variation-safe metadata examples.

Do not infer automatic procedural mutation rights from the inventory alone.

## What Remains Out of Scope

Current out-of-scope items:

- public arbitrary PCG graph;
- full PVE clone;
- Nanite, skeletal foliage, wind, or renderer-specific runtime features;
- live public marketplace or 3D Warehouse dependency for core workflows;
- arbitrary mutation of approved Asset Exemplars;
- procedural mesh/UV/material/texture changes to ordinary UV-mapped staged assets;
- per-leaf or per-blade geometry for dense planting masses;
- automatic external asset ingestion pipelines;
- broad recommendation/ranking logic;
- automatic design-height fitting from vegetation metadata.

Research-only future possibilities:

- PVE-like recipe families;
- generated asset exemplars;
- richer authored material-slot systems;
- external rendering asset references;
- asset-generation pipelines outside SketchUp that feed curated exemplars back into the model.

## Open Questions

### Current SEM/SAR Questions

1. Which staged-asset metadata fields should graduate into documented first-class filters after vegetation workflows stabilize?
2. How should SAR-04 classify supported replacement targets beyond `tree_proxy`?
3. Should SAR-06 create individual Asset Instances, a managed coverage group, or both?
4. Which generated component definition cleanup policy is acceptable for semantic proxies?

### Product-Lane Change Questions

1. Should generated variants live inside SAR, beside SAR, or as a separate asset-generation capability consumed by SAR?
2. Should generated variants ever become approved Asset Exemplars automatically, or should explicit curation always be required?
3. What metadata is sufficient to declare an Asset Exemplar variation-safe?
4. Is material-slot swapping valuable enough to become first-class, given UV-mapped asset constraints?
5. Should semantic proxies be usable as sources for generated Asset Instances, or should they stay purely semantic representations?
6. What is the minimum user-facing control set for variation without exposing arbitrary graphs?

### Research Questions

1. Which PVE concepts remain useful after excluding graphs, Nanite, skeletal vegetation, and full plant simulation?
2. Can recipe signatures be simple enough for SketchUp users and agents to understand?
3. Which vegetation categories benefit most from generated variants versus curated sibling exemplars?
4. What validation scene best reveals copy-paste repetition in groundcover and shrub masses?

## Updated Recommendations

### Current Implementation Guidance

1. Keep `planting_mass + proxy_mass` implementation in semantic runtime builders/collaborators.
2. Keep curated exemplar discovery, instantiation, lineage, and replacement in staged assets.
3. Use current public tools exactly as documented: `create_site_element`, `curate_staged_asset`, `list_staged_assets`, and `instantiate_staged_asset`.
4. Treat `replace_with_staged_asset` as SAR-04 draft until implementation lands.
5. Do not add public seed/spacing/style controls to `planting_mass` without a separate contract task.
6. Protect approved staged assets from implicit procedural mutation.

### Product-Lane Proposal

Evaluate a SAR-adjacent generated/variant asset capability. It should be explicitly variation-safe, deterministic, budgeted, lineage-rich, and hostile to arbitrary UV/mesh/material mutation.

This is the main new idea preserved by the rectification.

### Research Posture

Keep PVE and PCG as pressure sources. They should challenge product boundaries where justified, but they should not quietly become public MCP graphs, renderer features, or unsupported asset-generation promises.

## Acceptance Criteria for Future Edits

- Each major recommendation is labeled current, proposal, or research.
- New ideas that challenge SEM/SAR are preserved when argued, not filtered out by current architecture.
- Current task status remains accurate.
- Current implementation guidance does not depend on unratified proposals.
- Product-lane proposals name affected artifacts, ownership movement, and validation needed before PRD/HLD updates.
- Current staged assets are described as approved in-scene Asset Exemplars and editable Asset Instances with source lineage.
- Generated/variant asset concepts explain why current exemplar instantiation and placement transforms are insufficient.
- Vegetation-specific metadata remains optional `assetAttributes` in current-state sections unless a proposal explicitly promotes schema changes.
- `PlantAssetRecipe`, `VegetationKit`, representation-tier, PCG, or PVE language may remain only when maturity is explicit.
- UV-mapped staged assets are protected by default.

## Appendix A: Current Public Tool Check

The relevant current public tools checked during this rectification are:

- `create_site_element`;
- `set_entity_metadata`;
- `curate_staged_asset`;
- `instantiate_staged_asset`;
- `list_staged_assets`.

The current docs and native tool catalog do not expose `replace_with_staged_asset` or generated-variant tooling as shipped public tools at the time of this update.

## Appendix B: External Analog Takeaway

The useful external lesson is not "copy Unreal." It is:

```text
Authored preset discipline
  + deterministic placement/generation
  + explicit source lineage
  + bounded variation
  + geometry budgets
  + safe reuse policy
```

For SketchUp MCP, that becomes:

```text
Semantic intent
  -> generated proxy when early design is enough
  -> approved Asset Exemplar when curated source quality is needed
  -> proposed variation-safe generated asset only when transform variation is insufficient
```
