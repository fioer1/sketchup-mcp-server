# LayOut MCP Safe Write Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add copy-only and text-replacement LayOut write tools that always write to an explicit output file and validate the result.

**Architecture:** Add `LayoutDocumentWriter` beside the existing reader. Extend `LayoutCommands` with write-path validation/refusals. Register three new public MCP tools through the same dispatcher, command factory target, native catalog, docs, and public contract sweep used by Phase 1.

**Tech Stack:** Ruby, rubyzip, Minitest, existing SketchUp MCP native runtime.

## Global Constraints

- No in-place overwrite of source `.layout` files.
- Every mutable tool must require `outputPath`.
- Source and output paths must not resolve to the same absolute path.
- Output overwrite is opt-in with `overwriteOutput: true`.
- Non-XML archive entries must be copied without text decoding.
- The output file must be validated after writing.
- No viewport replacement, dimension updates, page geometry edits, reference/resource relinking, or LayOut application automation.

---

### Task 1: LayoutDocumentWriter

**Files:**
- Create: `src/su_mcp/layout/layout_document_writer.rb`
- Test: `test/layout/layout_document_writer_test.rb`

**Interfaces:**
- Produces `SU_MCP::Layout::LayoutDocumentWriter.new.copy_document(source_path:, output_path:, overwrite_output: false)`
- Produces `SU_MCP::Layout::LayoutDocumentWriter.new.replace_text(source_path:, output_path:, find_text:, replace_text:, overwrite_output: false, allow_noop: false)`

Steps:

- [x] Write failing writer tests for copy, same path refusal, existing output refusal, XML-only text replacement, binary preservation, and no-op refusal.
- [x] Run `C:\Ruby32-x64\bin\ruby.exe -Itest test/layout/layout_document_writer_test.rb` and confirm it fails because the writer is missing.
- [x] Implement the writer with `FileUtils.cp` for copy and `Zip::File` archive rebuild for XML text replacement.
- [x] Run the writer test and confirm 0 failures.

### Task 2: LayoutCommands Write Methods

**Files:**
- Modify: `src/su_mcp/layout/layout_commands.rb`
- Modify: `test/layout/layout_commands_test.rb`

**Interfaces:**
- Produces `layout_copy_document(args)`
- Produces `layout_replace_text(args)`
- Produces `layout_validate_document(args)`

Steps:

- [x] Add failing command tests for all three tools and refusal reasons.
- [x] Run `C:\Ruby32-x64\bin\ruby.exe -Itest test/layout/layout_commands_test.rb` and confirm it fails.
- [x] Implement command methods and refusal mapping.
- [x] Run command tests and confirm 0 failures.

### Task 3: Runtime Registration, Docs, Contract

**Files:**
- Modify: `src/su_mcp/runtime/tool_dispatcher.rb`
- Modify: `src/su_mcp/runtime/native/native_tool_catalog.rb`
- Modify: `test/runtime/tool_dispatcher_test.rb`
- Modify: `test/runtime/native/native_tool_catalog_test.rb`
- Modify: `test/support/public_mcp_contract_sweep.json`
- Modify: `docs/mcp-tool-reference.md`

**Interfaces:**
- Produces public tools `layout_copy_document`, `layout_replace_text`, `layout_validate_document`.

Steps:

- [x] Add failing dispatcher/catalog tests for the three tools.
- [x] Run runtime tests and confirm they fail because tools are not registered.
- [x] Add dispatcher mappings and native catalog entries.
- [x] Update docs and public contract sweep.
- [x] Run runtime and public contract tests and confirm 0 failures.

### Task 4: Manual Verification, Commit, Push

**Files:**
- No additional source files expected.

Steps:

- [x] Run targeted tests:
  - `C:\Ruby32-x64\bin\ruby.exe -Itest test/layout/layout_document_reader_test.rb`
  - `C:\Ruby32-x64\bin\ruby.exe -Itest test/layout/layout_document_writer_test.rb`
  - `C:\Ruby32-x64\bin\ruby.exe -Itest test/layout/layout_commands_test.rb`
  - `C:\Ruby32-x64\bin\ruby.exe -Itest test/runtime/tool_dispatcher_test.rb`
  - `C:\Ruby32-x64\bin\ruby.exe -Itest test/runtime/native/native_tool_catalog_test.rb`
  - `C:\Ruby32-x64\bin\ruby.exe -Itest test/runtime/public_mcp_contract_posture_test.rb`
- [x] Run a real-file copy and harmless text replacement under `H:/项目/DAII-20260713-00/设计归档/`.
- [x] Confirm the original file under `收到资料` is unchanged.
- [ ] Commit with `feat(layout): add safe LayOut write tools`.
- [ ] Push to `fork/feature/layout-mcp`.
