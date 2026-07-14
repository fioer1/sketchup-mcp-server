# LayOut MCP Roadmap

Date: 2026-07-14
Goal: Add an independent LayOut MCP capability to the SketchUp MCP extension while preserving upstream-friendly fork maintenance.

## Phase 0: Discovery And Guardrails

Status: complete for roadmap planning.

Findings:

- Runtime dependency: `Gemfile:5` already includes `rubyzip`, which is suitable for read-only `.layout` archive inspection.
- Tool dispatch: `src/su_mcp/runtime/tool_dispatcher.rb:6` owns `TOOL_METHODS`.
- Command assembly: `src/su_mcp/runtime/runtime_command_factory.rb:24` owns `build_command_targets`.
- Native MCP schema: `src/su_mcp/runtime/native/native_tool_catalog.rb:16` owns catalog entries.
- Public docs: `docs/mcp-tool-reference.md:5` owns tool inventory and usage notes.
- Contract sweep: `test/runtime/public_mcp_contract_posture_test.rb:67` verifies checked-in public tool inventory against runtime first-class tools.

Guardrails:

- Keep new LayOut behavior isolated under `src/su_mcp/layout/`.
- Keep shared runtime edits limited to tool registration and command target wiring.
- Do not write or mutate `.layout` files in Phase 1.
- Do not add a second MCP server or external runtime.
- Do not use undocumented LayOut app automation in the audit phase.

## Phase 1: Read-Only LayOut Audit Tools

Purpose: make MCP able to inspect `.layout` documents safely.

Implement:

- `src/su_mcp/layout/layout_document_reader.rb`
  - Open `.layout` files read-only with `Zip::File`.
  - List archive entries.
  - Discover page XML files.
  - Extract page names, page order, dimensions when available, XML tag counts, text snippets, and referenced resource paths.
- `src/su_mcp/layout/layout_commands.rb`
  - Validate MCP inputs.
  - Return refusal hashes for missing path, missing file, wrong extension, unreadable archive, and invalid page selector.
  - Expose command methods for:
    - `layout_get_document_info`
    - `layout_list_pages`
    - `layout_inspect_page`
    - `layout_find_text`

Wire:

- Add `layout_*` mappings in `ToolDispatcher::TOOL_METHODS`.
- Add `layout_commands` to `RuntimeCommandFactory#build_command_targets`.
- Add `layout_tool_catalog` to `NativeToolCatalog#entries`.
- Update `docs/mcp-tool-reference.md` and `test/support/public_mcp_contract_sweep.json`.

Verify:

- Unit tests for synthetic `.layout` archives.
- Dispatcher test for each new tool.
- Native catalog test or contract posture coverage for tool exposure.
- Run the smallest relevant Ruby test set.
- Manually call tools against `H:/项目/DAII-20260713-00/收到资料/Design Document Template.layout`.

Exit criteria:

- MCP exposes all four `layout_*` tools.
- Tools return useful audit output for the current 18-page package.
- Tools do not modify the `.layout` file.
- Branch pushes cleanly to `fork/feature/layout-mcp`.

## Phase 2: Project-Specific LayOut Package Audit Report

Purpose: turn raw audit tools into a repeatable check for this client package.

Implement:

- A report command or documented workflow that summarizes:
  - sheet count and sheet names
  - title block text evidence
  - visible note/title text by page
  - SketchUp viewport/resource references where detectable
  - missing or suspicious pages compared with expected package structure

Verify:

- Run against `Design Document Template.layout`.
- Save an audit output artifact under the project folder, not inside the MCP repo.

Exit criteria:

- The current package can be summarized without manually unzipping the file.
- Output is useful enough to guide LayOut sheet update work.

## Phase 3: Safe Write Spike

Purpose: explore whether `.layout` updates are safe enough to automate.

Implement:

- Read-only backup/diff harness first.
- Synthetic archive round-trip tests.
- A tiny, reversible text-only mutation spike on a copied `.layout` fixture.

Anti-pattern guards:

- Never mutate the original client file.
- Never assume XML structure without before/after validation.
- Do not ship write tools until copied files can be opened in LayOut manually.

Exit criteria:

- Decision recorded: continue write automation, switch to LayOut app automation, or keep MCP read-only.

## Phase 4: LayOut Editing Or Automation

Purpose: only after Phase 3 proves a safe path.

Possible directions:

- Controlled `.layout` package edits for text/title block updates.
- LayOut application automation if a reliable Windows path is found.
- Hybrid workflow where SketchUp MCP prepares scenes and LayOut audit tools guide manual sheet updates.

Exit criteria:

- A documented, validated path exists for the specific edit type before any public write tool is exposed.

## Maintenance Workflow

- Keep `origin` pointed to `SidhNor/sketchup-mcp-server`.
- Keep custom work on `feature/layout-mcp`, pushed to `fork`.
- Before major work, fetch upstream and rebase:

```powershell
git fetch origin
git rebase origin/main
git push --force-with-lease fork feature/layout-mcp
```

- Keep `.runtime_package/` untracked and out of commits.
