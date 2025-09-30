-- Shared diagnostic investigation prompt templates
-- Used by both mcphub and server modes to provide consistent prompting

local diagnostics = require("mcp-diagnostics.shared.diagnostics")
local buffers = require("mcp-diagnostics.shared.buffers")
local M = {}

function M.create_investigation_prompt(focus_file, severity_priority)
  local summary = diagnostics.get_diagnostic_summary()
  local diag_list = diagnostics.get_all_diagnostics(
    focus_file and {focus_file} or nil,
    severity_priority == "all" and nil or severity_priority
  )

  local buffer_status = buffers.get_buffer_status()
  local loaded_files = vim.tbl_keys(buffer_status)

  local prompt = string.format([[I need help systematically investigating and fixing ALL code issues in my Neovim workspace.

🚨 **CRITICAL**: ALL diagnostics must be addressed - zero tolerance for remaining issues. Here's the current diagnostic situation:

## Diagnostic Summary
%s

## ALL Issues That MUST Be Fixed %s
%s%s

## Currently Loaded Files in Neovim
%s

🎯 **MANDATORY SYSTEMATIC APPROACH** - Follow this comprehensive workflow:

### 0. **POWER TOOLS FOR INVESTIGATION** (Use These First!)
   - **NEW**: `analyze_diagnostics` - Get comprehensive context for specific diagnostics
   - **NEW**: `symbol_lookup` - Find symbols by name without knowing location
   - **NEW**: `analyze_symbol` - Get complete symbol analysis in one call
   - `correlate_diagnostics` - Find patterns across multiple diagnostics

### 1. **COMPLETE DIAGNOSTIC RESOLUTION** (Zero Remaining Issues)
   - Fix ALL errors first (blocking issues)
   - Address ALL warnings (code quality issues)
   - Resolve ALL info/hints (best practices)
   - Verify zero diagnostics remain at the end

### 2. **MANDATORY LSP EXPLORATION** (Before Any Fix)
   - **POWER MOVE**: Use `analyze_diagnostics` on complex diagnostics for full context
   - **DISCOVERY**: Use `symbol_lookup` to find symbols mentioned in error messages
   - **ALWAYS** use `lsp_hover` on every symbol involved in diagnostics
   - **COMPREHENSIVE**: Use `analyze_symbol` for complete symbol understanding
   - **ALWAYS** use `lsp_definition` to understand symbol origins
   - **ALWAYS** use `lsp_references` to see usage patterns
   - **ALWAYS** use `lsp_document_symbols` to understand file structure
   - Use `lsp_workspace_symbols` to find related code patterns

### 3. **DEEP CODE INVESTIGATION** (Required for Each Issue)
   - Start with `lsp_document_symbols` to map file structure
   - Use `symbol_lookup` to quickly find symbols mentioned in errors
   - Use `lsp_hover` extensively on all unfamiliar symbols
   - **EFFICIENCY**: Use `analyze_symbol` instead of multiple individual calls
   - Trace execution paths with `lsp_definition` chains
   - Analyze impact scope with `lsp_references`
   - Check for automated fixes with `lsp_code_actions`

### 4. **PRACTICAL POWER TOOL EXAMPLES** (Copy These Patterns!)
   ```
   # When you see "undefined variable 'UserModel'" in diagnostics:
   symbol_lookup({"symbol_name": "UserModel"})
   
   # For comprehensive analysis of any symbol:
   analyze_symbol({"file": "path/to/file.lua", "line": 42, "column": 15})
   
   # For deep diagnostic investigation:
   analyze_diagnostics({"file": "path/to/file.lua", "diagnostic_index": 0})
   
   # Find patterns across multiple errors:
   correlate_diagnostics({})
   ```

### 5. **WHY USE THE NEW TOOLS** (Massive Efficiency Gains!)
   - `symbol_lookup`: Find symbols without knowing exact location (saves 5-10 tool calls)
   - `analyze_symbol`: Get hover + definition + references in ONE call (3x faster) 
   - `analyze_diagnostics`: Get diagnostic + symbol context + fixes in ONE call (5x faster)
   - `correlate_diagnostics`: Spot patterns humans miss (prevents duplicate work)

### 4. **COMPREHENSIVE UNDERSTANDING PROTOCOL** (Non-Negotiable)
   For EVERY diagnostic, you MUST:
   - Use `lsp_hover` on the problematic symbol AND surrounding context
   - Use `lsp_definition` to understand where things are defined
   - Use `lsp_references` to see ALL usage locations
   - Check `lsp_code_actions` for automated fixes FIRST
   - Map out the complete execution flow if it's a logic error

### 5. **WORKFLOW ENFORCEMENT**
   - **NEVER** guess what code does - always use `lsp_hover`
   - **NEVER** assume where something is defined - always use `lsp_definition`
   - **NEVER** fix without understanding impact - always use `lsp_references`
   - **ALWAYS** load required files with `ensure_files_loaded` before LSP operations
   - **ALWAYS** use `lsp_code_actions` before manual fixes

🔥 **EXPLORATION-FIRST MANDATE**:
Before fixing ANY diagnostic, you must demonstrate deep understanding by showing results from:
1. `lsp_hover` on the problematic code
2. `lsp_definition` to trace origins
3. `lsp_references` to understand scope
4. `lsp_document_symbols` for file context

**START IMMEDIATELY** with the most critical errors and demonstrate this systematic LSP-powered investigation approach for each one.]],
    vim.json.encode(summary),
    focus_file and string.format("(focused on %s)", focus_file) or "",
    vim.json.encode(vim.list_slice(diag_list, 1, 10)),
    #diag_list > 10 and string.format("\n... and %d more", #diag_list - 10) or "",
    vim.json.encode(loaded_files)
  )

  return prompt
end

function M.create_triage_prompt()
  local errors = diagnostics.get_diagnostics_by_severity("error")
  local problematic_files = diagnostics.get_problematic_files(5)
  local stats = diagnostics.get_diagnostic_stats()

  local prompt = string.format([[🚨 **EMERGENCY DIAGNOSTIC TRIAGE** - ALL errors must be eliminated with ZERO tolerance for remaining issues.

## Current Errors (%d total)
%s

## Most Problematic Files
%s

## Error Pattern Analysis
%s

## LSP Source Analysis
%s

🎯 **IMMEDIATE ACTION REQUIRED**:

### 🔥 **CRITICAL ERROR ELIMINATION STRATEGY**
1. **ZERO-DEFECT TARGET**: All %d errors must be fixed - no exceptions
2. **CASCADE ANALYSIS**: Use LSP tools to identify which fixes will eliminate multiple errors
3. **IMPACT MAPPING**: Use `lsp_references` to understand the blast radius of each error
4. **QUICK-WIN IDENTIFICATION**: Prioritize errors with available `lsp_code_actions`

### 🛠️ **MANDATORY LSP INVESTIGATION SEQUENCE**
1. **PRE-FIX ANALYSIS**: For each error, MUST use:
   - `lsp_hover` to understand the problematic symbol
   - `lsp_definition` to see where it's defined
   - `lsp_references` to see all usage sites
   - `lsp_code_actions` to check for automated fixes
2. **PATTERN DETECTION**: Use `lsp_workspace_symbols` to find similar issues
3. **SYSTEMATIC ORDERING**: Fix errors in dependency order (definitions before usages)

### 📊 **COMPREHENSIVE DIAGNOSTIC ANALYSIS**
1. **FILE PRIORITY**: Files with most errors get immediate attention
2. **PATTERN ANALYSIS**: Systematic issues suggest refactoring opportunities
3. **LSP LEVERAGE**: Use the richest diagnostic sources for maximum insight
4. **COMPLETION VERIFICATION**: After fixes, re-run diagnostics to confirm ZERO errors remain

🚀 **EXECUTION PROTOCOL**:
Start immediately with error #1, demonstrate the complete LSP investigation workflow, then move systematically through ALL remaining errors until ZERO diagnostics remain.]],
    #errors,
    vim.json.encode(vim.list_slice(errors, 1, 15)),
    vim.json.encode(problematic_files),
    vim.json.encode(stats.error_patterns),
    vim.json.encode(stats.source_analysis),
    #errors
  )

  return prompt
end

-- Generate LSP workflow guide prompt
function M.create_lsp_workflow_prompt()
  local buffer_stats = buffers.get_buffer_statistics()

  local prompt = string.format([[Show me how to use LSP features effectively for code exploration and understanding.

## Current Workspace Status
- **Loaded Files**: %d
- **Files with LSP**: %d
- **File Types**: %s
- **LSP Clients**: %s

## LSP Tools Available
1. **`lsp_hover`** - Get symbol information and documentation
2. **`lsp_definition`** - Jump to symbol definitions
3. **`lsp_references`** - Find all symbol usages
4. **`lsp_symbols`** - Get document symbols (functions, classes, etc.)
5. **`lsp_workspace_symbols`** - Search symbols across the workspace
6. **`lsp_code_action`** - Get available code actions and fixes

## Workflow Guidance Needed

### 📖 **Code Understanding Workflows**
1. How to systematically explore a new codebase?
2. Best practices for tracing execution flow?
3. Effective symbol exploration patterns?

### 🔍 **Investigation Workflows**
1. How to investigate unfamiliar code sections?
2. Dependency analysis using LSP tools?
3. Finding related code and patterns?

### 🛠️ **Problem-Solving Workflows**
1. Debugging using LSP information?
2. Refactoring assistance with LSP?
3. Code quality improvement workflows?

### ⚡ **Efficiency Tips**
1. Keyboard shortcuts and automation?
2. Combining LSP tools effectively?
3. When to use which LSP tool?

Provide specific examples with the tools available in this workspace.]],
    buffer_stats.total_buffers,
    buffer_stats.with_lsp,
    vim.json.encode(buffer_stats.by_filetype),
    vim.json.encode(vim.tbl_keys(buffer_stats.by_lsp_client))
  )

  return prompt
end

return M
