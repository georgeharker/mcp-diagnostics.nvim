
local M = {}
local investigation = require("mcp-diagnostics.shared.prompts.investigation")
local extra = require("mcp-diagnostics.shared.prompts.investigation_extra")

function M.register_all(mcphub, server_name, server_config)
  server_config = server_config or {}

  -- Diagnostic investigation guide
  mcphub.add_prompt(server_name, {
    name = "diagnostic_investigation_guide",
    description = "🚨 CRITICAL: Comprehensive guide for ELIMINATING ALL diagnostics using systematic LSP investigation. Zero-defect approach with mandatory tool usage patterns.",
    handler = function(_req, res)
      local guide = extra.create_investigation_prompt(nil, nil)
      return res:user():text("🚨 I need help systematically ELIMINATING ALL diagnostics in my Neovim session using comprehensive LSP investigation")
                :llm():text(guide):send()
    end
  })

  -- Error triage prompt
  mcphub.add_prompt(server_name, {
    name = "error_triage",
    description = "🔥 EMERGENCY: Critical error elimination strategy with zero tolerance for remaining issues. Mandatory LSP investigation protocols.",
    handler = function(_req, res)
      local triage = extra.create_triage_prompt()
      return res:user():text("🔥 EMERGENCY: Help me systematically eliminate ALL errors with comprehensive LSP investigation approach")
                :llm():text(triage):send()
    end
  })

  -- LSP workflow guide
  mcphub.add_prompt(server_name, {
    name = "lsp_workflow_guide",
    description = "🎯 MASTER LSP TOOLKIT: Comprehensive workflow guide for systematic code exploration and understanding. Mandatory usage patterns for investigation success.",
    handler = function(_req, res)
      local workflow = extra.create_lsp_workflow_prompt()
      return res:user():text("🎯 Show me the MASTER LSP workflow for systematic code exploration and comprehensive diagnostic resolution")
                :llm():text(workflow):send()
    end
  })
end

function M.create_investigation_guide(summary)
  local guide = [[
# Neovim Diagnostic Investigation Guide

## Current Diagnostic Summary
Total diagnostics: ]] .. summary.total .. [[

Breakdown by severity:
- Errors: ]] .. summary.errors .. [[
- Warnings: ]] .. summary.warnings .. [[
- Info: ]] .. summary.info .. [[
- Hints: ]] .. summary.hints .. [[

Files affected: ]] .. summary.files .. [[

## Investigation Strategy

1. **Start with errors** - These are blocking issues that need immediate attention
2. **Group by file** - Fix multiple issues in the same file together
3. **Group by source** - Similar tools often have related issues
4. **Check configuration** - Many issues stem from misconfiguration

## Next Steps

Use the diagnostic tools to:
- Get detailed error information: `diagnostics_get` with severity filter
- Investigate specific files with multiple issues
- Use LSP tools for code navigation and quick fixes
]]

  return guide
end

function M.create_error_triage(errors)
  if #errors == 0 then
    return "Great! No errors found in your current Neovim session."
  end

  local by_file = {}
  for _, error in ipairs(errors) do
    local file = error.filename
    if not by_file[file] then
      by_file[file] = {}
    end
    table.insert(by_file[file], error)
  end

  local triage = "# Error Triage Report\n\n"

  -- Sort files by error count
  local files_sorted = {}
  for file, file_errors in pairs(by_file) do
    table.insert(files_sorted, {file = file, count = #file_errors, errors = file_errors})
  end
  table.sort(files_sorted, function(a, b) return a.count > b.count end)

  triage = triage .. "## Priority Order (by error count)\n\n"

  for i, file_info in ipairs(files_sorted) do
    triage = triage .. string.format("### %d. %s (%d errors)\n", i, file_info.file, file_info.count)

    for j, error in ipairs(file_info.errors) do
      triage = triage .. string.format("- Line %d: %s", error.lnum + 1, error.message)
      if error.source then
        triage = triage .. string.format(" (%s)", error.source)
      end
      triage = triage .. "\n"

      if j >= 3 then -- Limit to first 3 errors per file
        triage = triage .. string.format("  ... and %d more errors\n", file_info.count - 3)
        break
      end
    end
    triage = triage .. "\n"
  end

  return triage
end

function M.create_lsp_workflow_guide()
  return [[
# LSP Workflow Guide for Neovim

## Available LSP Tools

1. **lsp_hover** - Get documentation and type information
   - Use when you need to understand what a symbol does
   - Shows function signatures, documentation, types

2. **lsp_definition** - Jump to where something is defined
   - Use to understand code structure
   - Navigate to function/variable definitions

3. **lsp_references** - Find all uses of a symbol
   - Use before refactoring to see impact
   - Understand code dependencies

4. **lsp_document_symbols** - Get overview of file structure
   - Use to navigate large files
   - Understand code organization

5. **lsp_workspace_symbols** - Search symbols across project
   - Use to find functions/classes by name
   - Explore unfamiliar codebases

6. **lsp_code_actions** - Get available fixes and refactorings
   - Use when you see diagnostics
   - Access language-specific tools

## Effective Workflow

1. Start with **document_symbols** to understand file structure
2. Use **hover** to understand unfamiliar code
3. Use **definition** and **references** to trace code flow
4. Use **code_actions** to fix issues and refactor
5. Use **workspace_symbols** to find related code

## Tips

- Always check diagnostics first - they guide where to focus
- Use hover liberally - documentation saves time
- References before refactoring - avoid breaking changes
- Code actions often provide the best fixes
]]
end

return M
