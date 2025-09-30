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

  -- diagnostic_hotspots tool - find most problematic files
  mcphub.add_tool(server_name, {
    name = "diagnostic_hotspots",
    description = "🔥 CRITICAL PRIORITY TOOL: Identify the most problematic files ranked by diagnostic severity to focus remediation efforts. Files are scored by: errors×3 + warnings×2 + info + hints×0.5. Start fixing the highest-scored files first for maximum impact on code quality.",
    inputSchema = {
      type = "object",
      properties = {
        limit = {
          type = "number",
          description = "Maximum number of problematic files to return (default: 10). Start with top 3-5 files for focused remediation."
        }
      }
    },
    handler = function(_req, res)
      local limit = _req.params.limit or 10
      local hotspots = diagnostics.get_problematic_files(limit)
      return res:text(vim.json.encode(hotspots), "application/json"):send()
    end
  })

  -- diagnostic_stats tool - advanced analytics
  mcphub.add_tool(server_name, {
    name = "diagnostic_stats",
    description = "📊 COMPREHENSIVE ANALYSIS TOOL: Get advanced diagnostic statistics with error pattern analysis and source breakdown. Essential for understanding systemic issues and planning comprehensive code quality improvements. Reveals recurring patterns that indicate architectural or process issues.",
    handler = function(_req, res)
      local stats = diagnostics.get_diagnostic_stats()
      return res:text(vim.json.encode(stats), "application/json"):send()
    end
  })

  -- diagnostic_by_severity tool - severity-filtered diagnostics
  mcphub.add_tool(server_name, {
    name = "diagnostic_by_severity",
    description = "🎯 FOCUSED REMEDIATION TOOL: Get diagnostics filtered by specific severity level. Use 'error' for blocking issues that prevent compilation/execution, 'warn' for quality issues, 'info' for suggestions, 'hint' for optimizations. Essential for systematic issue resolution by priority level.",
    inputSchema = {
      type = "object",
      properties = {
        severity = {
          type = "string",
          enum = { "error", "warn", "info", "hint" },
          description = "Severity level to filter by. Start with 'error' for critical issues, then 'warn' for quality issues."
        }
      },
      required = { "severity" }
    },
    handler = function(_req, res)
      local severity = _req.params.severity
      local filtered_diagnostics = diagnostics.get_diagnostics_by_severity(severity)
      return res:text(vim.json.encode(filtered_diagnostics), "application/json"):send()
    end
  })
end

function M.register_lsp_tools(mcphub, server_name, server_config)
  server_config = server_config or {}

  -- LSP hover tool with enhanced description
  mcphub.add_tool(server_name, {
    name = "lsp_hover",
    description = "🔍 CRITICAL INVESTIGATION TOOL: Get comprehensive symbol information including types, documentation, and signatures. NOW SUPPORTS BOTH position-based AND name-based lookup! Use this EXTENSIVELY - hover on EVERY symbol you encounter during diagnostic investigation. This is your primary tool for understanding what code does before making any changes. Never guess what a symbol does - always hover first!",
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

  -- Symbol lookup by name tool
  mcphub.add_tool(server_name, {
    name = "symbol_lookup",
    description = "🎯 REVOLUTIONARY SYMBOL FINDER: Find ANY symbol by name across the entire workspace without knowing its location! No more hunting through files - just specify the symbol name and optional context. Perfect for 'Find the UserModel class' or 'Where is the validate function?' queries. Supports context disambiguation when multiple symbols match. This changes everything!",
    inputSchema = {
      type = "object",
      properties = {
        symbol_name = {
          type = "string",
          description = "Name or partial name of the symbol to find"
        },
        context_file = {
          type = "string",
          description = "Optional: File context for disambiguation (when multiple symbols match)"
        },
        max_results = {
          type = "number",
          description = "Maximum number of results to return (default: 20)"
        }
      },
      required = { "symbol_name" }
    },
    handler = function(_req, res)
      local symbols = lsp.get_workspace_symbols(_req.params.symbol_name)

      -- Apply context filtering if provided
      if _req.params.context_file and symbols then
        local filtered = {}
        for _, symbol in ipairs(symbols) do
          if symbol.location and symbol.location.uri then
            local file_path = vim.uri_to_fname(symbol.location.uri)
            if file_path:match(_req.params.context_file) then
              table.insert(filtered, symbol)
            end
          end
        end
        symbols = filtered
      end

      -- Apply result limit
      if _req.params.max_results and symbols and #symbols > _req.params.max_results then
        symbols = vim.list_slice(symbols, 1, _req.params.max_results)
      end

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

  -- Comprehensive symbol analysis tool (chaining multiple LSP operations)
  mcphub.add_tool(server_name, {
    name = "analyze_symbol",
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
      local analysis = lsp_extra.analyze_symbol(_req.params.file, _req.params.line, _req.params.column)
      return res:text(vim.json.encode(analysis), "application/json"):send()
    end
  })

  -- Diagnostic context analysis tool
  mcphub.add_tool(server_name, {
    name = "analyze_diagnostics",
    description = "🎯 DIAGNOSTIC DEEP DIVE: Analyze specific diagnostics with comprehensive context including symbol analysis, code actions, and related diagnostics. Use this for complex errors that need thorough investigation before fixing.",
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

      local analysis = lsp_extra.analyze_diagnostics(_req.params.file, diagnostic)
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

end

function M.register_file_refresh_tools(mcphub, server_name, server_config)
  server_config = server_config or {}

  -- refresh_after_external_changes tool
  mcphub.add_tool(server_name, {
    name = "refresh_after_external_changes",
    description = "🔄 ESSENTIAL: Force refresh all watched files after external changes (modifications and deletions) with smart diagnostic waiting. No more sleep delays - uses event-driven LSP readiness detection. Handles file deletions and general refresh. Use this when you've made changes outside of Neovim.",
    inputSchema = {
      type = "object",
      properties = {
        files = {
          type = "array",
          items = { type = "string" },
          description = "Specific files to monitor for diagnostic updates (optional)"
        },
        deleted_files = {
          type = "array",
          items = { type = "string" },
          description = "Files that were deleted (optional)"
        },        max_wait_ms = {
          type = "number",
          description = "Maximum time to wait for diagnostic updates in milliseconds (default: 5000)"
        }
      }
    },
    handler = function(_req, res)
      local files = _req.files or {}
      local deleted_files = _req.deleted_files or {}
      local max_wait_ms = _req.max_wait_ms or 5000

      -- Handle file deletions first if specified
      local deletion_results = {}
      if #deleted_files > 0 then
        for _, filepath in ipairs(deleted_files) do
          lsp_extra.handle_file_deleted(filepath)
          deletion_results[filepath] = { deleted = true }
        end
      end
      -- Use the improved unified refresh system
      local unified_refresh = require("mcp-diagnostics.shared.unified_refresh")
      local result = unified_refresh.refresh_after_external_changes(files, max_wait_ms)

return res:text(vim.json.encode({
        message = result.message or "External refresh completed",
        success = result.success,
        details = result,
        deletions = deletion_results,
        deleted_count = #deleted_files
      }), "application/json"):send()
    end
  })
end

return M
