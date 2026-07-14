# LayOut MCP Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build read-only MCP tools that inspect `.layout` documents without modifying them.

**Architecture:** Add an isolated `SU_MCP::Layout` capability folder. `LayoutDocumentReader` owns archive/XML inspection and returns plain hashes; `LayoutCommands` owns MCP input validation and refusal envelopes; runtime files only register the new tools.

**Tech Stack:** Ruby, Minitest, `rubyzip`, SketchUp MCP native runtime catalog.

## Global Constraints

- Keep new LayOut behavior isolated under `src/su_mcp/layout/`.
- Keep shared runtime edits limited to tool registration and command target wiring.
- Do not write or mutate `.layout` files in Phase 1.
- Do not add a second MCP server or external runtime.
- Do not use undocumented LayOut app automation in the audit phase.
- Keep `.runtime_package/` untracked and out of commits.

---

### Task 1: LayOut Document Reader

**Files:**
- Create: `src/su_mcp/layout/layout_document_reader.rb`
- Test: `test/layout/layout_document_reader_test.rb`

**Interfaces:**
- Produces: `SU_MCP::Layout::LayoutDocumentReader.new(path).document_info`
- Produces: `SU_MCP::Layout::LayoutDocumentReader.new(path).pages`
- Produces: `SU_MCP::Layout::LayoutDocumentReader.new(path).inspect_page(page_index: nil, page_name: nil)`
- Produces: `SU_MCP::Layout::LayoutDocumentReader.new(path).find_text(query, case_sensitive: false)`
- Raises: `SU_MCP::Layout::LayoutDocumentReader::ArchiveUnreadable` for invalid archives.

- [ ] **Step 1: Write failing reader tests**

Create a synthetic `.layout` zip in `Dir.mktmpdir` with:

```ruby
Zip::File.open(path, create: true) do |zip|
  zip.get_output_stream('pages/page-001.xml') do |io|
    io.write('<page name="Cover Page" width="17" height="11"><text>Cover Title</text></page>')
  end
  zip.get_output_stream('pages/page-002.xml') do |io|
    io.write('<page name="FLOORPLAN (PROPOSED)"><text>Kitchen Note</text><viewport ref="model.skp"/></page>')
  end
end
```

Assert:

- `document_info[:pageCount] == 2`
- `pages.map { |page| page[:name] } == ['Cover Page', 'FLOORPLAN (PROPOSED)']`
- `inspect_page(page_name: 'FLOORPLAN (PROPOSED)')[:textSnippets]` includes `Kitchen Note`
- `find_text('kitchen')` returns one match on page index `1`
- invalid zip raises `ArchiveUnreadable`

- [ ] **Step 2: Run reader tests to verify they fail**

Run:

```powershell
ruby -Itest test/layout/layout_document_reader_test.rb
```

Expected: fail because `layout_document_reader.rb` does not exist.

- [ ] **Step 3: Implement `LayoutDocumentReader`**

Implement read-only archive inspection with `Zip::File.open(path)`. Use `REXML::Document` for best-effort XML parsing, fall back to regex/text evidence if XML parsing fails. Return capped snippets, no raw XML bodies.

- [ ] **Step 4: Run reader tests to verify they pass**

Run:

```powershell
ruby -Itest test/layout/layout_document_reader_test.rb
```

Expected: 0 failures.

---

### Task 2: MCP-Facing Layout Commands

**Files:**
- Create: `src/su_mcp/layout/layout_commands.rb`
- Test: `test/layout/layout_commands_test.rb`

**Interfaces:**
- Consumes: `SU_MCP::Layout::LayoutDocumentReader`
- Produces command methods:
  - `layout_get_document_info(args)`
  - `layout_list_pages(args)`
  - `layout_inspect_page(args)`
  - `layout_find_text(args)`

- [ ] **Step 1: Write failing command tests**

Test success cases with a synthetic `.layout` fixture and refusal cases:

- `{}` returns `success: false`, reason `missing_path`
- missing path returns `layout_file_not_found`
- `.txt` extension returns `invalid_layout_extension`
- invalid archive returns `layout_archive_unreadable`
- missing page selector returns `invalid_page_selector`
- unknown page returns `layout_page_not_found`

- [ ] **Step 2: Run command tests to verify they fail**

Run:

```powershell
ruby -Itest test/layout/layout_commands_test.rb
```

Expected: fail because `LayoutCommands` does not exist.

- [ ] **Step 3: Implement `LayoutCommands`**

Implement validation and refusal shape:

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

Use `LayoutDocumentReader` for all archive inspection.

- [ ] **Step 4: Run command tests to verify they pass**

Run:

```powershell
ruby -Itest test/layout/layout_commands_test.rb
```

Expected: 0 failures.

---

### Task 3: Runtime Tool Registration

**Files:**
- Modify: `src/su_mcp/runtime/tool_dispatcher.rb`
- Modify: `src/su_mcp/runtime/runtime_command_factory.rb`
- Modify: `src/su_mcp/runtime/native/native_tool_catalog.rb`
- Modify: `test/runtime/tool_dispatcher_test.rb`
- Test: add or extend runtime/native catalog coverage.

**Interfaces:**
- Consumes: `SU_MCP::Layout::LayoutCommands`
- Produces public tool names:
  - `layout_get_document_info`
  - `layout_list_pages`
  - `layout_inspect_page`
  - `layout_find_text`

- [ ] **Step 1: Write failing dispatcher/catalog tests**

Extend `ToolDispatcherTest::CommandTarget` with private `layout_*` methods and add dispatch tests for each new tool. Add catalog assertions that `NativeToolCatalog.new.entries.map { |entry| entry.fetch(:name) }` includes all four names and that each schema requires `path`.

- [ ] **Step 2: Run runtime tests to verify they fail**

Run:

```powershell
ruby -Itest test/runtime/tool_dispatcher_test.rb
ruby -Itest test/runtime/native/native_tool_catalog_test.rb
```

Expected: fail until runtime registration exists.

- [ ] **Step 3: Wire runtime registration**

Add command mappings in `ToolDispatcher::TOOL_METHODS`, require and instantiate `LayoutCommands` in `RuntimeCommandFactory`, and add `layout_tool_catalog` entries to `NativeToolCatalog`.

- [ ] **Step 4: Run runtime tests to verify they pass**

Run the same two test commands. Expected: 0 failures.

---

### Task 4: Docs, Contract Sweep, And Real Fixture Check

**Files:**
- Modify: `docs/mcp-tool-reference.md`
- Modify: `test/support/public_mcp_contract_sweep.json`
- Test: `test/runtime/public_mcp_contract_posture_test.rb`

**Interfaces:**
- Consumes: public tool names from Task 3.
- Produces: user-facing reference docs and matching public tool inventory.

- [ ] **Step 1: Update docs and public contract sweep**

Add all four tools to tool inventory and add a concise `## LayOut document audit` section documenting read-only behavior and example payloads.

- [ ] **Step 2: Run contract posture test**

Run:

```powershell
ruby -Itest test/runtime/public_mcp_contract_posture_test.rb
```

Expected: 0 failures.

- [ ] **Step 3: Run targeted test suite**

Run:

```powershell
ruby -Itest test/layout/layout_document_reader_test.rb
ruby -Itest test/layout/layout_commands_test.rb
ruby -Itest test/runtime/tool_dispatcher_test.rb
ruby -Itest test/runtime/native/native_tool_catalog_test.rb
ruby -Itest test/runtime/public_mcp_contract_posture_test.rb
```

Expected: all pass.

- [ ] **Step 4: Manually check the client LayOut file**

Use a one-off Ruby command to call `SU_MCP::Layout::LayoutCommands` against:

```text
H:/项目/DAII-20260713-00/收到资料/Design Document Template.layout
```

Expected: `layout_get_document_info` reports 18 pages and `layout_list_pages` returns sheet names.

- [ ] **Step 5: Commit and push**

Run:

```powershell
git status --short
git add src/su_mcp/layout test/layout src/su_mcp/runtime/tool_dispatcher.rb src/su_mcp/runtime/runtime_command_factory.rb src/su_mcp/runtime/native/native_tool_catalog.rb test/runtime docs/mcp-tool-reference.md test/support/public_mcp_contract_sweep.json docs/superpowers/plans/2026-07-15-layout-mcp-phase1.md
git commit -m "feat(layout): add read-only LayOut audit tools"
git push
```

Expected: branch `feature/layout-mcp` pushes to `fork/feature/layout-mcp`.
