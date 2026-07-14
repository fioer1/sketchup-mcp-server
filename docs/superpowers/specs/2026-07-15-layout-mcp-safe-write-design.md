# LayOut MCP Safe Write Design

Date: 2026-07-15
Branch: feature/layout-mcp

## Goal

Add a narrowly scoped, safety-first write path for LayOut `.layout` files. The first mutable tools must operate only on copied output files, support limited text replacement, and validate the resulting document before reporting success.

## Context

Phase 1 added read-only LayOut audit tools:

- `layout_get_document_info`
- `layout_list_pages`
- `layout_inspect_page`
- `layout_find_text`

Those tools can read the current client package and confirm page count, page size, page names, XML paths, snippets, and resource evidence. Mutable work should build on this reader rather than inventing a second parser.

LayOut files are ZIP archives with XML content and referenced binary resources. Direct XML/package writes can corrupt a document if they alter references, viewport cache, page data, or binary entries incorrectly. The first write capability must therefore be conservative.

## Non-Goals

- No in-place overwrite of source `.layout` files.
- No viewport replacement.
- No dimension updates.
- No page geometry edits.
- No reference/resource relinking.
- No LayOut application automation.
- No broad XML schema rewrite.

## Proposed Tools

### `layout_copy_document`

Copies a `.layout` source file to an explicit output path, then validates the copied document with the existing reader.

Input:

```json
{
  "sourcePath": "H:/project/source.layout",
  "outputPath": "H:/project/output.layout"
}
```

Behavior:

- Refuses if `sourcePath` is missing, not found, unreadable, or not `.layout`.
- Refuses if `outputPath` is missing or not `.layout`.
- Refuses if `outputPath` equals `sourcePath`.
- Refuses if `outputPath` exists unless `overwriteOutput` is true.
- Copies bytes without interpreting archive entries.
- Validates the copied document by reading page count and page names.

### `layout_replace_text`

Creates a new `.layout` output file by copying all archive entries from `sourcePath` and replacing exact text occurrences in XML entries only.

Input:

```json
{
  "sourcePath": "H:/project/source.layout",
  "outputPath": "H:/project/output.layout",
  "findText": "PROJECT NAME",
  "replaceText": "MOLINA RESIDENCE"
}
```

Behavior:

- Requires an explicit `outputPath`.
- Never writes to `sourcePath`.
- Rewrites only XML archive entries.
- Copies binary/non-XML entries byte-for-byte.
- Performs exact string replacement by default.
- Returns changed entry count and replacement count.
- Validates output with the existing reader.
- Refuses if no replacements are found unless `allowNoop` is true.

### `layout_validate_document`

Validates that a `.layout` file is readable after copying or text replacement.

Input:

```json
{
  "path": "H:/project/output.layout"
}
```

Behavior:

- Reuses `LayoutDocumentReader`.
- Returns page count, page size evidence, and page names.
- Does not mutate the file.

## Refusal Shape

All write-path failures return JSON-serializable hashes:

```ruby
{
  success: false,
  refusal: {
    reason: 'layout_output_exists',
    message: 'Output LayOut file already exists.',
    details: { outputPath: output_path }
  }
}
```

Expected reasons:

- `missing_source_path`
- `missing_output_path`
- `missing_layout_path`
- `layout_file_not_found`
- `invalid_layout_extension`
- `layout_output_same_as_source`
- `layout_output_exists`
- `layout_archive_unreadable`
- `layout_no_replacements`
- `missing_find_text`

## Architecture

Add a writer beside the existing reader:

```text
src/su_mcp/layout/
  layout_document_reader.rb
  layout_document_writer.rb
  layout_commands.rb
```

`LayoutDocumentWriter` owns copy and XML-entry replacement mechanics. It has no MCP-specific schema knowledge and returns plain hashes.

`LayoutCommands` owns MCP-facing validation, refusal shape, and public command methods.

Runtime integration stays minimal:

- Add `layout_copy_document`, `layout_replace_text`, and `layout_validate_document` mappings to `ToolDispatcher`.
- Add native catalog entries with `destructive_hint: false` because writes target explicit output files, not source files.
- Update docs and public contract sweep.

## Safety Rules

- Every mutable tool must require `outputPath`.
- Source and output paths must not resolve to the same absolute path.
- Output overwrite is opt-in with `overwriteOutput: true`.
- Non-XML archive entries must be copied without text decoding.
- The output file must be validated after writing.
- Response evidence must include `sourcePath`, `outputPath`, `replacementCount` where relevant, and validation summary.

## Testing

Tests should create synthetic `.layout` archives with XML and binary entries.

Required tests:

- Copy preserves page count and binary resource bytes.
- Copy refuses same source/output path.
- Copy refuses existing output without `overwriteOutput`.
- Text replacement changes XML entries only.
- Text replacement preserves non-XML entries byte-for-byte.
- Text replacement refuses no-op replacements by default.
- Text replacement validates output document.
- Command tests cover all refusal shapes.
- Runtime dispatcher/catalog/docs/contract tests cover new tools.

## Manual Verification

Run `layout_copy_document` and a harmless `layout_replace_text` against a copied client package under:

```text
H:/项目/DAII-20260713-00/设计归档/
```

The original file under `收到资料` must remain unchanged.

## Future Work

After text-only safe writes are validated, later phases can investigate:

- RTF-aware text replacement.
- Title block field updates.
- Page-specific note updates.
- Viewport/reference manipulation only after a separate spike proves safe round-tripping.
