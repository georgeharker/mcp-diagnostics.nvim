-- Enhanced diagnostic investigation prompt templates
-- Improved version with stronger emphasis on complete diagnostic resolution and LSP tool usage

local diagnostics = require("mcp-diagnostics.shared.diagnostics")
local buffers = require("mcp-diagnostics.shared.buffers")
local M = {}

-- Generate enhanced diagnostic investigation guide
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

### 1. **COMPLETE DIAGNOSTIC RESOLUTION** (Zero Remaining Issues)
   - Fix ALL errors first (blocking issues)
   - Address ALL warnings (code quality issues)
   - Resolve ALL info/hints (best practices)
   - Verify zero diagnostics remain at the end

### 2. **MANDATORY LSP EXPLORATION** (Before Any Fix)
   - **ALWAYS** use `lsp_hover` on every symbol involved in diagnostics
   - **ALWAYS** use `lsp_definition` to understand symbol origins
   - **ALWAYS** use `lsp_references` to see usage patterns
   - **ALWAYS** use `lsp_document_symbols` to understand file structure
   - Use `lsp_workspace_symbols` to find related code patterns

### 3. **DEEP CODE INVESTIGATION** (Required for Each Issue)
   - Start with `lsp_document_symbols` to map file structure
   - Use `lsp_hover` extensively on all unfamiliar symbols
   - Trace execution paths with `lsp_definition` chains
   - Analyze impact scope with `lsp_references`
   - Check for automated fixes with `lsp_code_actions`

### 🎯 **DEFINITION EXPLORATION MANDATE** (Critical for Understanding)
   - **NEVER** assume you understand what a symbol does without seeing its definition
   - **ALWAYS** use `lsp_definition` to navigate to symbol origins and read the actual implementation
   - **TRACE DEFINITION CHAINS**: Follow definitions through multiple files to understand complete context
   - **EXPLORE DEFINITION CONTEXT**: Use `lsp_document_symbols` on definition files to understand their structure
   - **VERIFY DEFINITION UNDERSTANDING**: Use `lsp_hover` on definition locations to confirm types and behavior
   - The definition location contains the TRUTH about what code actually does - always explore it!

### 4. **COMPREHENSIVE UNDERSTANDING PROTOCOL** (Non-Negotiable)
   For EVERY diagnostic, you MUST:
   - Use `lsp_hover` on the problematic symbol AND surrounding context
   - Use `lsp_definition` to understand where things are defined AND explore those definition locations
   - **EXPLORE DEFINITIONS DEEPLY**: Navigate to definitions and understand the actual implementation
   - Use `lsp_references` to see ALL usage locations
   - Check `lsp_code_actions` for automated fixes FIRST
   - Map out the complete execution flow if it's a logic error

### 5. **WORKFLOW ENFORCEMENT** (Definition-First Approach)
   - **NEVER** guess what code does - always use `lsp_hover`
   - **NEVER** assume where something is defined - always use `lsp_definition` AND explore the definition
   - **NEVER** accept surface-level understanding - always explore definitions to see actual implementations
   - **NEVER** fix without understanding impact - always use `lsp_references`
   - **ALWAYS** load required files with `ensure_files_loaded` before LSP operations
   - **ALWAYS** use `lsp_code_actions` before manual fixes
   - **ALWAYS** read and understand the actual definition code, not just its signature

🔥 **EXPLORATION-FIRST MANDATE**:
Before fixing ANY diagnostic, you must demonstrate deep understanding by showing results from:
1. `lsp_hover` on the problematic code
2. `lsp_definition` to trace origins AND exploration of the definition locations
3. `lsp_references` to understand scope
4. `lsp_document_symbols` for file context

**START IMMEDIATELY** with the most critical errors and demonstrate this systematic LSP-powered investigation approach, with particular emphasis on exploring definitions to understand what code actually does.]],
    vim.json.encode(summary),
    focus_file and string.format("(focused on %s)", focus_file) or "",
    vim.json.encode(vim.list_slice(diag_list, 1, 10)),
    #diag_list > 10 and string.format("\n... and %d more", #diag_list - 10) or "",
    vim.json.encode(loaded_files)
  )

  return prompt
end

-- Generate enhanced error triage prompt
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

-- Generate enhanced LSP workflow guide prompt
function M.create_lsp_workflow_prompt()
  local buffer_stats = buffers.get_buffer_statistics()

  local prompt = string.format([[🚀 **MASTER LSP WORKFLOW** - Systematic code exploration and understanding using LSP tools as your primary investigation method.

## Current Workspace Status
- **Loaded Files**: %d
- **Files with LSP**: %d
- **File Types**: %s
- **LSP Clients**: %s

## 🔧 **MANDATORY LSP TOOLKIT** - Your Primary Investigation Arsenal
1. **`lsp_hover`** - **CRITICAL**: Use on EVERY unfamiliar symbol - provides types, documentation, signatures
2. **`lsp_definition`** - **ESSENTIAL**: Navigate to definitions and READ the actual implementation - never guess what code does
3. **`lsp_references`** - **VITAL**: See ALL usage sites - understand impact before changes
4. **`lsp_document_symbols`** - **REQUIRED**: Map file structure before diving into details
5. **`lsp_workspace_symbols`** - **POWERFUL**: Find patterns and related code across the project
6. **`lsp_code_actions`** - **FIRST CHOICE**: Check for automated fixes before manual work

## 🎯 **SYSTEMATIC INVESTIGATION WORKFLOWS** - Follow These Patterns

### 📖 **MANDATORY Code Understanding Protocol**
1. **File Entry**: ALWAYS start with `lsp_document_symbols` to map the terrain
2. **Symbol Investigation**: Use `lsp_hover` on EVERY function, class, variable you encounter
3. **Definition Deep-Dive**: Use `lsp_definition` to navigate to origins AND read the actual implementation code
4. **Usage Mapping**: Use `lsp_references` to see how things are used throughout the codebase
5. **Pattern Discovery**: Use `lsp_workspace_symbols` to find similar or related concepts

### 🔍 **DEEP Investigation Protocol** (For Any Unfamiliar Code)
1. **Structure First**: `lsp_document_symbols` → understand the file layout
2. **Context Building**: `lsp_hover` on key symbols → build understanding incrementally
3. **Definition Exploration**: `lsp_definition` chains → navigate to and READ actual implementations
4. **Impact Analysis**: `lsp_references` → understand dependencies and usage
5. **Pattern Matching**: `lsp_workspace_symbols` → find related implementations

### 🛠️ **DIAGNOSTIC Resolution Protocol** (For Every Error/Warning)
1. **Immediate Context**: `lsp_hover` on the problematic symbol AND its neighbors
2. **Root Cause Investigation**: `lsp_definition` to navigate to problem origins AND examine the actual code
3. **Blast Radius**: `lsp_references` to see what might break if you change it
4. **Automated Solutions**: `lsp_code_actions` to check for quick fixes FIRST
5. **Related Issues**: `lsp_workspace_symbols` to find similar problems

### ⚡ **HIGH-IMPACT Usage Patterns**
1. **Exploration Chain**: symbols → hover → definition (READ CODE) → references → related symbols
2. **Diagnostic Chain**: error location → hover → definition (READ IMPLEMENTATION) → references → code actions
3. **Refactoring Chain**: references → hover → definition (UNDERSTAND CODE) → code actions → workspace symbols
4. **Learning Chain**: symbols → hover → definition (STUDY IMPLEMENTATION) → workspace symbols (find examples)

### 🚨 **CRITICAL RULES** - Never Violate These
 - **NEVER** guess where something is defined - ALWAYS use `lsp_definition` AND read the actual code
 - **NEVER** accept just function signatures - ALWAYS explore definitions to see implementations
 - **NEVER** make assumptions about behavior - ALWAYS read the definition source code

🎯 **DEMONSTRATE MASTERY**: Show systematic LSP usage with concrete examples from this workspace, emphasizing definition exploration and code reading.]],
    buffer_stats.total_buffers,
    buffer_stats.with_lsp,
    vim.json.encode(buffer_stats.by_filetype),
    vim.json.encode(vim.tbl_keys(buffer_stats.by_lsp_client))
  )

  return prompt
end

return M