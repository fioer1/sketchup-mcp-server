# LayOut MCP Read-Only Capability Design

Date: 2026-07-14
Branch: feature/layout-mcp

## Goal

Add an independent LayOut capability to the existing SketchUp MCP extension so MCP clients can inspect `.layout` documents alongside SketchUp models. The first version is read-only and focuses on document/page inventory, page inspection, and text search. It must not modify `.layout` files.

## Context

The repository is a Ruby SketchUp extension with MCP tool registration, command dispatch, and native tool schemas owned inside the extension runtime. Public MCP contract changes currently touch:

- `src/su_mcp/runtime/tool_dispatcher.rb`
- `src/su_mcp/runtime/runtime_command_factory.rb`
- `src/su_mcp/runtime/native/native_tool_catalog.rb`

To keep upstream updates manageable, LayOut behavior will live in its own capability folder and only use minimal runtime registration hooks.

The project already depends on `rubyzip`, and LayOut files can be inspected as ZIP archives containing XML resources. That makes a read-only Ruby parser practical without introducing a second runtime.

## Non-Goals

- No `.layout` file writes.
- No viewport replacement or sheet editing.
- No LayOut application automation.
- No changes to SketchUp scene or geometry tools.
- No broad refactor of runtime registration.

## Proposed Architecture

Create a new capability folder:

```text
src/su_mcp/layout/
  layout_commands.rb
  layout_document_reader.rb

test/layout/
  layout_commands_test.rb
  layout_document_reader_test.rb
```

`LayoutDocumentReader` owns ZIP/XML file inspection and returns plain Ruby hashes and arrays. It has no MCP knowledge.

`LayoutCommands` owns MCP-facing request handling, argument validation, refusal shapes, and calls into the reader.

Runtime integration stays small:

- Add `require_relative '../layout/layout_commands'` in `RuntimeCommandFactory`.
- Add a `layout_commands` command target to `build_command_targets`.
- Add `layout_*` mappings in `ToolDispatcher::TOOL_METHODS`.
- Add a `layout_tool_catalog` section in `NativeToolCatalog#entries`.

## MCP Tools

### `layout_get_document_info`

Input:

```json
{ "path": "H:/path/to/file.layout" }
```

Returns:

- `success`
- `path`
- `fileSize`
- `pageCount`
- `pageSize`
- `entries`
- `warnings`

### `layout_list_pages`

Input:

```json
{ "path": "H:/path/to/file.layout" }
```

Returns ordered page summaries:

- `index`
- `name`
- `xmlPath`
- `bounds` when available
- `textCount` when available

### `layout_inspect_page`

Input:

```json
{
  "path": "H:/path/to/file.layout",
  "pageIndex": 2
}
```

or:

```json
{
  "path": "H:/path/to/file.layout",
  "pageName": "FLOORPLAN (PROPOSED)"
}
```

Returns:

- page identity
- text snippets
- entity/type counts derived from XML tags
- referenced resource paths found in page XML
- raw XML path, not raw XML body

### `layout_find_text`

Input:

```json
{
  "path": "H:/path/to/file.layout",
  "query": "KITCHEN"
}
```

Returns page-level matches with short snippets. Matching is case-insensitive by default.

## Refusal Shape

All failures return JSON-serializable hashes:

```ruby
{
  success: false,
  refusal: {
    reason: 'layout_file_not_found',
    message: 'LayOut file does not exist.',
    details: { path: path }
  }
}
```

Expected reasons:

- `missing_path`
- `layout_file_not_found`
- `invalid_layout_extension`
- `layout_archive_unreadable`
- `layout_page_not_found`
- `invalid_page_selector`

## Data Handling

The reader opens the archive read-only through `Zip::File`. It extracts only XML text needed for summaries. Returned snippets are capped to avoid oversized MCP responses.

The implementation should tolerate unknown LayOut XML structure by reporting evidence from archive paths and XML tags instead of depending on undocumented complete schemas.

## Testing

Unit tests should create small synthetic `.layout` archives with representative XML files. Tests should verify:

- document info for valid archives
- page listing preserves page order
- page selection by name and index
- text search returns page-scoped snippets
- refusal shapes for missing files, bad extension, unreadable archive, and invalid page selector

Runtime tests should verify:

- dispatcher routes each `layout_*` tool to `LayoutCommands`
- native tool catalog includes all new tool definitions and schemas

## Upstream Compatibility

The feature branch keeps `origin` pointed at upstream and pushes custom work to `fork`. The implementation minimizes future rebase conflicts by isolating behavior under `src/su_mcp/layout/` and keeping shared runtime edits limited to registration.

If upstream later adds its own LayOut capability, the isolated directory and `layout_*` tool prefix make conflict resolution straightforward.
