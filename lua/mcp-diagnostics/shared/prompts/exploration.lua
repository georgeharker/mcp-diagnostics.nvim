-- Shared code exploration prompt templates
-- Used by both mcphub and server modes for LSP-powered code exploration

local lsp = require("mcp-diagnostics.shared.lsp")
local buffers = require("mcp-diagnostics.shared.buffers")
local M = {}

-- Generate LSP code exploration prompt
function M.create_exploration_prompt(entry_point, exploration_goal)
  -- Ensure the entry point is loaded
  lsp.ensure_file_loaded(entry_point)

  local symbols = lsp.get_document_symbols(entry_point) or {}
  local buffer_status = buffers.get_buffer_status()

  local exploration_guides = {
    understand_structure = "exploring the overall code structure and relationships",
    trace_execution = "tracing code execution paths and flow",
    find_usage = "finding where symbols and functions are used",
    analyze_dependencies = "analyzing dependencies and imports"
  }

  local goal_description = exploration_guides[exploration_goal] or "general code exploration"

  local prompt = string.format([[I want to explore and understand code starting from `%s`. My goal is %s.

## Starting Point: %s
Document symbols found:
%s%s

## Currently Loaded Files
%s

Please guide me through systematic exploration using LSP tools:

### For Understanding Structure:
1. Use `lsp_symbols` to see all symbols in key files
2. Use `lsp_definition` on important symbols to understand their implementations
3. Use `lsp_references` to see how components connect
4. Use `lsp_workspace_symbols` to find related symbols across the project

### For Tracing Execution:
1. Start with entry functions using `lsp_hover` for signatures
2. Use `lsp_definition` to follow function calls
3. Use `lsp_references` to see all call sites
4. Map out the execution flow step by step

### For Finding Usage:
1. Use `lsp_references` on symbols to see all usage locations
2. Use `lsp_workspace_symbols` to find similar or related symbols
3. Analyze usage patterns and contexts

### For Dependency Analysis:
1. Use `lsp_definition` on imports/includes to understand dependencies
2. Use `lsp_workspace_symbols` to find all related modules
3. Map out the dependency tree

**Important**: Before exploring any file, ensure it's loaded with `ensure_files_loaded`.

Guide me step by step through this exploration, suggesting specific LSP tool invocations and explaining what to look for in the results.]],
    entry_point,
    goal_description,
    entry_point,
    vim.json.encode(vim.list_slice(symbols, 1, 15)),
    #symbols > 15 and string.format("\n... and %d more symbols", #symbols - 15) or "",
    vim.json.encode(vim.tbl_keys(buffer_status))
  )

  return prompt
end

function M.create_error_fixing_prompt(error_file, error_line, error_message)
  if not error_file or not error_line then
    return nil, "error_file and error_line are required"
  end

  local line_num = tonumber(error_line)
  if not line_num then
    return nil, "error_line must be a valid number"
  end

  -- Convert to 0-based indexing for LSP
  local lsp_line = line_num - 1

  lsp.ensure_file_loaded(error_file)

  local diagnostics = require("mcp-diagnostics.shared.diagnostics")
  local file_diagnostics = diagnostics.get_all_diagnostics({error_file})
  local hover_info = lsp.get_hover_info(error_file, lsp_line, 0) or {}
  local code_actions = lsp.get_code_actions(error_file, lsp_line, 0) or {}

  local prompt = string.format([[🚨 **CRITICAL ERROR RESOLUTION REQUIRED** - I need to systematically fix an error in `%s` at line %d%s.

## ALL Diagnostics for %s (Every One Must Be Fixed)
%s

## Initial LSP Context Information
Hover info at error location:
%s

## Available Automated Fixes (Check These FIRST)
%s

🎯 **MANDATORY ERROR ELIMINATION WORKFLOW** - Follow every step:

### Step 1: **DEEP ERROR ANALYSIS** (Required Before Any Fix)
- **MANDATORY**: Use `lsp_hover` on the error symbol AND all surrounding symbols
- **MANDATORY**: Use `lsp_definition` to trace where problematic symbols are defined
- **MANDATORY**: Use `lsp_document_symbols` to understand file structure context
- Interpret ALL diagnostic information - not just this error
- Explain what the error means in the broader code context

### Step 2: **COMPREHENSIVE ROOT CAUSE INVESTIGATION**
- **MANDATORY**: Use `lsp_references` to see ALL usage sites of problematic symbols
- **MANDATORY**: Check `lsp_workspace_symbols` for related patterns across the codebase
- Trace the complete execution flow using `lsp_definition` chains
- Identify if this is an isolated issue or part of a systematic problem

### Step 3: **AUTOMATED-FIRST FIX STRATEGY**
- **FIRST PRIORITY**: Use `lsp_code_actions` for automated fixes
- **MANDATORY**: Use `lsp_references` to assess impact of any proposed changes
- Plan manual fixes ONLY if automation isn't available
- Consider ALL potential side effects and cascading fixes needed

### Step 4: **SAFE IMPLEMENTATION PROTOCOL**
- **MANDATORY**: Re-check `lsp_references` before making changes
- Fix in dependency order (definitions before usages)
- Use `lsp_hover` to verify changes maintain correct types
- Address ANY related diagnostics simultaneously

### Step 5: **ZERO-DEFECT VERIFICATION**
- **MANDATORY**: Re-run diagnostics to confirm error is eliminated
- **MANDATORY**: Check that NO new diagnostics were introduced
- Use `lsp_references` to verify dependent code still works correctly
- Address ANY remaining diagnostics in the file

🚀 **START IMMEDIATELY** with comprehensive LSP analysis - demonstrate hover, definition, and references usage for this error before proposing any fixes.]],
    error_file,
    line_num,
    error_message and string.format(': "%s"', error_message) or '',
    error_file,
    vim.json.encode(file_diagnostics),
    vim.json.encode(hover_info),
    vim.json.encode(code_actions)
  )

  return prompt
end

function M.create_workspace_health_prompt()
  local diagnostics = require("mcp-diagnostics.shared.diagnostics")
  local summary = diagnostics.get_diagnostic_summary()
  local _all_diags = diagnostics.get_all_diagnostics()
  local buffer_status = buffers.get_buffer_status()
  local stats = diagnostics.get_diagnostic_stats()

  local prompt = string.format([[🏥 **CRITICAL CODEBASE HEALTH AUDIT** - Comprehensive analysis with ZERO-DEFECT TARGET:

## Overall Health Summary
%s

## Error Patterns (most common issues)
%s

## LSP Source Analysis
%s

## Buffer Status
Currently loaded files: %d
%s

🎯 **MANDATORY COMPREHENSIVE ANALYSIS** - Address every aspect:

### 🏥 **CRITICAL Health Assessment** (Zero Tolerance for Issues)
1. **SEVERITY ANALYSIS**: Every diagnostic represents a code quality failure
2. **HOTSPOT IDENTIFICATION**: Files requiring immediate LSP investigation and fixes
3. **PATTERN RECOGNITION**: Systematic issues that need architectural fixes
4. **LSP EFFECTIVENESS**: Which diagnostic sources provide the most actionable insights

### 🎯 **IMMEDIATE ACTION PRIORITIES** (All Must Be Addressed)
1. **CRITICAL PATH**: Sequence for eliminating ALL diagnostics efficiently
2. **LSP INVESTIGATION TARGETS**: Files requiring deep symbol exploration
3. **AUTOMATION OPPORTUNITIES**: Where `lsp_code_actions` can accelerate fixes
4. **SYSTEMATIC FIXES**: Patterns addressable through workspace-wide refactoring

### 🔧 **SYSTEMATIC ELIMINATION PLAN** (Follow This Protocol)
1. **IMMEDIATE LSP ACTIONS**: Specific tool usage for each critical issue
2. **EXPLORATION WORKFLOWS**: Mandatory `lsp_hover`/`definition`/`references` sequences
3. **ZERO-DEFECT ROADMAP**: Prioritized sequence to eliminate ALL diagnostics
4. **FILE LOADING STRATEGY**: Which files need `ensure_files_loaded` for complete analysis

### 🚀 **PREVENTION AND EXCELLENCE STRATEGIES**
1. **CONTINUOUS MONITORING**: Patterns that predict future diagnostic issues
2. **LSP OPTIMIZATION**: Configuration improvements for better diagnostic coverage
3. **QUALITY GATES**: Preventive measures to maintain zero-defect status
4. **SYSTEMATIC WORKFLOWS**: Establish LSP-first development practices

🚀 **EXECUTION MANDATE**:
Start immediately with the highest-priority diagnostics, demonstrate systematic LSP tool usage, and work toward complete elimination of ALL diagnostic issues.]],
    vim.json.encode(summary),
    vim.json.encode(stats.error_patterns),
    vim.json.encode(stats.source_analysis),
    vim.tbl_count(buffer_status),
    vim.json.encode(buffer_status)
  )

  return prompt
end

return M
