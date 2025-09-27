-- Enhanced MCP-Hub tool descriptions with stronger encouragement for LSP tool usage

local M = {}
local diagnostics = require("mcp-diagnostics.shared.diagnostics")
local lsp = require("mcp-diagnostics.shared.lsp")
local buffers = require("mcp-diagnostics.shared.buffers")
local lsp_extra = require("mcp-diagnostics.shared.lsp_extra")

function M.register_all(mcphub, server_name, server_config)
  server_config = server_config or {}
  -- Enhanced diagnostic tools
  M.register_diagnostic_tools(mcphub, server_name, server_config)

  -- Enhanced LSP tools
  M.register_lsp_tools(mcphub, server_name, server_config)

  -- Enhanced buffer management tools
  M.register_buffer_tools(mcphub, server_name, server_config)

  -- Enhanced file loading and correlation tools
  M.register_enhanced_tools(mcphub, server_name, server_config)

  -- File refresh tools
  M.register_file_refresh_tools(mcphub, server_name, server_config)
end

function M.register_diagnostic_tools(mcphub, server_name, server_config)
  server_config = server_config or {}

  -- diagnostics_get tool with enhanced description
  mcphub.add_tool(server_name, {
    name = "diagnostics_get",
    description = "🚨 CRITICAL: Get ALL diagnostics that MUST be addressed. Every single diagnostic represents a code quality issue that needs fixing. Use this as your starting point for comprehensive error elimination. Filter by severity or source to prioritize, but remember: ALL diagnostics should ultimately be resolved to achieve zero-defect code quality.",
    inputSchema = {
      type = "object",
      properties = {
        files = {
          type = "array",
          items = { type = "string" },
          description = "Specific files to analyze (all loaded files if not specified). Focus on files with highest diagnostic counts first."
        },
        severity = {
          type = "string",
          enum = { "error", "warn", "info", "hint" },
          description = "Filter by severity: 'error' (blocking issues), 'warn' (quality issues), 'info' (suggestions), 'hint' (optimizations). Start with errors, but address ALL severities."
        },
        source = {
          type = "string",
          description = "Filter by LSP source (e.g. 'pylsp', 'eslint', 'typescript'). Use to focus on specific toolchain feedback, but don't ignore any source."
        }
      }
    },
    handler = function(_req, res)
      local files = _req.params.files
      local severity = _req.params.severity
      local source = _req.params.source

      local diag_results = diagnostics.get_all_diagnostics(files, severity, source)
      return res:text(vim.json.encode(diag_results), "application/json"):send()
    end
  })

  -- diagnostics_summary tool with enhanced description
  mcphub.add_tool(server_name, {
    name = "diagnostics_summary",
    description = "📊 ESSENTIAL: Get diagnostic overview to understand the scope of issues requiring fixes. Use this to prioritize your systematic approach to achieving zero diagnostics. High counts indicate areas needing immediate attention with LSP tool investigation.",
    handler = function(_req, res)
      local summary = diagnostics.get_diagnostic_summary()
      return res:text(vim.json.encode(summary), "application/json"):send()
    end
  })
end

function M.register_lsp_tools(mcphub, server_name, server_config)
  server_config = server_config or {}

  -- LSP hover tool with enhanced description
  mcphub.add_tool(server_name, {
    name = "lsp_hover",
    description = "🔍 CRITICAL INVESTIGATION TOOL: Get comprehensive symbol information including types, documentation, and signatures. Use this EXTENSIVELY - hover on EVERY symbol you encounter during diagnostic investigation. This is your primary tool for understanding what code does before making any changes. Never guess what a symbol does - always hover first!",
    inputSchema = {
      type = "object",
      properties = {
        file = { type = "string", description = "File path (must be loaded in Neovim)" },
        line = { type = "number", description = "Line number (0-based indexing)" },
        column = { type = "number", description = "Column number (0-based indexing)" }
      },
      required = { "file", "line", "column" }
    },
    handler = function(_req, res)
      local hover_info = lsp.get_hover_info(_req.params.file, _req.params.line, _req.params.column)
      return res:text(vim.json.encode(hover_info), "application/json"):send()
    end
  })

  -- LSP definition tool with enhanced description
  mcphub.add_tool(server_name, {
    name = "lsp_definition",
    description = "🎯 ESSENTIAL NAVIGATION TOOL: Jump to where symbols are defined. Use this constantly to understand code structure and trace the origin of problematic symbols in diagnostics. Following definition chains helps you understand execution flow and identify root causes of errors. Never assume where something comes from - always check definitions!",
    inputSchema = {
      type = "object",
      properties = {
        file = { type = "string", description = "File path (must be loaded in Neovim)" },
        line = { type = "number", description = "Line number (0-based indexing)" },
        column = { type = "number", description = "Column number (0-based indexing)" }
      },
      required = { "file", "line", "column" }
    },
    handler = function(_req, res)
      local definitions = lsp.get_definitions(_req.params.file, _req.params.line, _req.params.column)
      return res:text(vim.json.encode(definitions), "application/json"):send()
    end
  })

  -- LSP references tool with enhanced description
  mcphub.add_tool(server_name, {
    name = "lsp_references",
    description = "⚡ IMPACT ANALYSIS TOOL: Find ALL locations where a symbol is used. MANDATORY before making any changes - helps you understand the blast radius and prevent breaking changes. Use this to see usage patterns, identify related diagnostics, and understand how fixes might affect other code. Critical for safe refactoring!",
    inputSchema = {
      type = "object",
      properties = {
        file = { type = "string", description = "File path (must be loaded in Neovim)" },
        line = { type = "number", description = "Line number (0-based indexing)" },
        column = { type = "number", description = "Column number (0-based indexing)" }
      },
      required = { "file", "line", "column" }
    },
    handler = function(_req, res)
      local references = lsp.get_references(_req.params.file, _req.params.line, _req.params.column)
      return res:text(vim.json.encode(references), "application/json"):send()
    end
  })

  -- LSP document symbols tool with enhanced description
  mcphub.add_tool(server_name, {
    name = "lsp_document_symbols",
    description = "🗺️ FILE STRUCTURE MAPPER: Get overview of all symbols in a file (functions, classes, variables, etc.). Use this FIRST when entering any file to understand the layout and organization. Essential for navigating large files and understanding code architecture. Start every investigation by mapping the terrain!",
    inputSchema = {
      type = "object",
      properties = {
        file = { type = "string", description = "File path (must be loaded in Neovim)" }
      },
      required = { "file" }
    },
    handler = function(_req, res)
      local symbols = lsp.get_document_symbols(_req.params.file)
      return res:text(vim.json.encode(symbols), "application/json"):send()
    end
  })

  -- LSP workspace symbols tool with enhanced description
  mcphub.add_tool(server_name, {
    name = "lsp_workspace_symbols",
    description = "🔎 PROJECT-WIDE DISCOVERY TOOL: Search for symbols across the entire workspace. Powerful for finding patterns, related implementations, and understanding how similar code is structured elsewhere. Use to discover alternatives, find examples of correct usage, and identify systematic issues that might affect multiple files.",
    inputSchema = {
      type = "object",
      properties = {
        query = { type = "string", description = "Search query for symbols (leave empty to get all symbols)" }
      }
    },
    handler = function(_req, res)
      local symbols = lsp.get_workspace_symbols(_req.params.query)
      return res:text(vim.json.encode(symbols), "application/json"):send()
    end
  })

  -- LSP code actions tool with enhanced description
  mcphub.add_tool(server_name, {
    name = "lsp_code_actions",
    description = "🛠️ AUTOMATED FIX PROVIDER: Get available automated fixes and refactorings. Check this FIRST before manual fixes - often provides quick, safe solutions for diagnostics. Shows import fixes, type corrections, refactoring options, and more. Prefer automated solutions over manual coding when available!",
    inputSchema = {
      type = "object",
      properties = {
        file = { type = "string", description = "File path (must be loaded in Neovim)" },
        line = { type = "number", description = "Line number (0-based indexing)" },
        column = { type = "number", description = "Column number (0-based indexing)" },
        end_line = { type = "number", description = "End line for range selection (optional)" },
        end_column = { type = "number", description = "End column for range selection (optional)" }
      },
      required = { "file", "line", "column" }
    },
    handler = function(_req, res)
      local actions = lsp.get_code_actions(_req.params.file, _req.params.line, _req.params.column, _req.params.end_line, _req.params.end_column)
      return res:text(vim.json.encode(actions), "application/json"):send()
    end
  })

  -- Enhanced ensure_files_loaded tool
  mcphub.add_tool(server_name, {
    name = "ensure_files_loaded",
    description = "📂 LSP PREREQUISITE TOOL: Load files into Neovim buffers so LSP tools can analyze them. MUST be used before running LSP operations on files not currently loaded. Essential for comprehensive codebase analysis - load all relevant files before investigation.",
    inputSchema = {
      type = "object",
      properties = {
        files = {
          type = "array",
          items = { type = "string" },
          description = "Array of file paths to load into Neovim buffers"
        }
      },
      required = { "files" }
    },
    handler = function(_req, res)
      local files = _req.params.files
      local results = {}

      for _, file in ipairs(files) do
        local success = lsp.ensure_file_loaded(file)
        table.insert(results, {file = file, loaded = success})
      end

      return res:text(vim.json.encode({
        loaded_files = results,
        message = string.format("Loaded %d files for LSP analysis", #results)
      }), "application/json"):send()
    end
  })
end

function M.register_buffer_tools(mcphub, server_name, server_config)
  server_config = server_config or {}

  -- buffer_status tool with enhanced description
  mcphub.add_tool(server_name, {
    name = "buffer_status",
    description = "📊 WORKSPACE OVERVIEW: Get status of all loaded buffers including LSP client information. Use to understand which files are available for LSP operations and identify files that need loading. Critical for planning comprehensive diagnostic investigations.",
    handler = function(_req, res)
      local status = buffers.get_buffer_status()
      return res:text(vim.json.encode(status), "application/json"):send()
    end
  })
end

function M.register_enhanced_tools(mcphub, server_name, server_config)
  server_config = server_config or {}

  -- Enhanced file loading tool
  mcphub.add_tool(server_name, {
    name = "ensure_files_loaded",
    description = "📂 CRITICAL LSP PREREQUISITE: Load multiple files into Neovim buffers with smart reload handling. MANDATORY before LSP operations on unloaded files. Handles external file changes based on auto_reload_mode config (reload/ask/none). Notifies LSP servers of file state changes. Essential for comprehensive codebase analysis.",
    inputSchema = {
      type = "object",
      properties = {
        files = {
          type = "array",
          items = { type = "string" },
          description = "Array of file paths to load into Neovim buffers. Use absolute paths for reliability."
        },
        reload_mode = {
          type = "string",
          enum = { "reload", "ask", "none" },
          description = "Override default auto_reload_mode: 'reload' (automatic), 'ask' (prompt user), 'none' (skip reload, may have stale data)"
        }
      },
      required = { "files" }
    },
    handler = function(_req, res)
      local files = _req.params.files
      local reload_mode = _req.params.reload_mode

      local results = lsp_extra.ensure_files_loaded(files, { reload_mode = reload_mode })
      return res:text(vim.json.encode(results), "application/json"):send()
    end
  })

  -- Enhanced file loading with smart waiting
  mcphub.add_tool(server_name, {
    name = "ensure_files_loaded_with_wait",
    description = "📂⏱️ ENHANCED FILE LOADING: Load files and intelligently wait for LSP diagnostics to be ready. Eliminates timing issues by monitoring LSP client readiness and diagnostic updates. Perfect for comprehensive analysis workflows.",
    inputSchema = {
      type = "object",
      properties = {
        files = {
          type = "array",
          items = { type = "string" },
          description = "Array of file paths to load and monitor"
        },
        reload_mode = {
          type = "string",
          enum = { "reload", "ask", "none" },
          description = "File reload handling mode"
        },
        max_wait_ms = {
          type = "number",
          description = "Maximum time to wait for LSP readiness (default: 5000ms)"
        }
      },
      required = { "files" }
    },
    handler = function(_req, res)
      local files = _req.params.files
      local reload_mode = _req.params.reload_mode
      local max_wait_ms = _req.params.max_wait_ms or 5000

      -- Load files first
      local load_results = lsp_extra.ensure_files_loaded(files, { reload_mode = reload_mode })

      -- Wait for LSP readiness and diagnostic updates
      local wait_result = lsp_extra.smart_refresh_and_wait(files, { max_wait_ms = max_wait_ms })

      return res:text(vim.json.encode({
        load_results = load_results,
        wait_result = wait_result,
        success = load_results.success and wait_result.success,
        total_wait_time_ms = wait_result.total_wait_time_ms,
        message = string.format("Loaded %d files and waited %dms for LSP readiness",
                               #files, wait_result.total_wait_time_ms or 0)
      }), "application/json"):send()
    end
  })
  -- Comprehensive symbol analysis tool (chaining multiple LSP operations)
  mcphub.add_tool(server_name, {
    name = "analyze_symbol_comprehensive",
    description = "🔍 POWER ANALYSIS TOOL: Perform comprehensive symbol analysis combining hover, definition, references, and document symbols in one operation. More efficient than individual LSP calls when you need complete symbol understanding. Perfect for deep diagnostic investigation.",
    inputSchema = {
      type = "object",
      properties = {
        file = { type = "string", description = "File path (will be auto-loaded if needed)" },
        line = { type = "number", description = "Line number (0-based indexing)" },
        column = { type = "number", description = "Column number (0-based indexing)" }
      },
      required = { "file", "line", "column" }
    },
    handler = function(_req, res)
      local analysis = lsp_extra.analyze_symbol_comprehensive(_req.params.file, _req.params.line, _req.params.column)
      return res:text(vim.json.encode(analysis), "application/json"):send()
    end
  })

  -- Diagnostic context analysis tool
  mcphub.add_tool(server_name, {
    name = "analyze_diagnostic_context",
    description = "🎯 DIAGNOSTIC DEEP DIVE: Analyze a specific diagnostic with comprehensive context including symbol analysis, code actions, and related diagnostics. Use this for complex errors that need thorough investigation before fixing.",
    inputSchema = {
      type = "object",
      properties = {
        file = { type = "string", description = "File path containing the diagnostic" },
        diagnostic_index = { type = "number", description = "Index of diagnostic in the file's diagnostic list (0-based)" }
      },
      required = { "file", "diagnostic_index" }
    },
    handler = function(_req, res)
      local file_diagnostics = diagnostics.get_all_diagnostics({_req.params.file})
      local diagnostic = file_diagnostics[_req.params.diagnostic_index + 1]

      if not diagnostic then
        return res:text(vim.json.encode({ error = "Diagnostic not found at specified index" }), "application/json"):send()
      end

      local analysis = lsp_extra.analyze_diagnostic_context(_req.params.file, diagnostic)
      return res:text(vim.json.encode(analysis), "application/json"):send()
    end
  })

  -- Diagnostic correlation tool
  mcphub.add_tool(server_name, {
    name = "correlate_diagnostics",
    description = "🧠 PATTERN RECOGNITION: Analyze relationships between diagnostics across files. Identifies symbols appearing in multiple errors, common error patterns, and potential cascading fixes. Critical for systematic error resolution and finding root causes.",
    handler = function(_req, res)
      local correlations = lsp_extra.correlate_diagnostics()
      return res:text(vim.json.encode(correlations), "application/json"):send()
    end
  })

  -- File deletion handler
  mcphub.add_tool(server_name, {
    name = "handle_file_deleted",
    description = "🗑️ FILE CLEANUP: Properly handle deleted files by notifying LSP servers and cleaning up buffers. Use when files are deleted externally to ensure LSP clients don't maintain stale references.",
    inputSchema = {
      type = "object",
      properties = {
        file = { type = "string", description = "Path of the deleted file" }
      },
      required = { "file" }
    },
    handler = function(_req, res)
      lsp_extra.handle_file_deleted(_req.params.file)
      return res:text(vim.json.encode({ message = "File deletion handled", file = _req.params.file }), "application/json"):send()
    end
  })
end

function M.register_file_refresh_tools(mcphub, server_name, server_config)
  server_config = server_config or {}

  -- refresh_after_external_changes tool
  mcphub.add_tool(server_name, {
    name = "refresh_after_external_changes",
    description = "🔄 ESSENTIAL: Force refresh all watched files after external changes with smart diagnostic waiting. No more sleep delays - uses event-driven LSP readiness detection. Use this when you've made changes outside of Neovim.",
    inputSchema = {
      type = "object",
      properties = {
        files = {
          type = "array",
          items = { type = "string" },
          description = "Specific files to monitor for diagnostic updates (optional)"
        },
        max_wait_ms = {
          type = "number",
          description = "Maximum time to wait for diagnostic updates in milliseconds (default: 5000)"
        }
      }
    },
    handler = function(_req, res)
      local files = _req.files or {}
      local max_wait_ms = _req.max_wait_ms or 5000

      local result = lsp_extra.smart_refresh_and_wait(files, { max_wait_ms = max_wait_ms })

return res:text(vim.json.encode({
        message = string.format("Smart refresh completed in %dms", result.total_wait_time_ms or 0),
        success = result.success,
        refresh_result = result.refresh_result,
        lsp_ready_result = result.lsp_ready_result,
        diagnostic_update_result = result.diagnostic_update_result,
        total_wait_time_ms = result.total_wait_time_ms
      }), "application/json"):send()
    end
  })

  -- check_file_staleness tool
  mcphub.add_tool(server_name, {
    name = "check_file_staleness",
    description = "🔍 DIAGNOSTIC: Check if any watched files have been modified externally and are out of sync. Use this to identify files that might need refreshing before running LSP operations.",
    inputSchema = {
      type = "object",
      properties = {}
    },
    handler = function(_req, res)
      local stale_files = lsp_extra.check_all_files_staleness()
      return res:text(vim.json.encode({
        message = string.format("Found %d potentially stale files", #stale_files),
        stale_files = stale_files
      }), "application/json"):send()
    end
  })
end

return M
