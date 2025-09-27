
local M = {}
local diagnostics = require("mcp-diagnostics.shared.diagnostics")
local lsp = require("mcp-diagnostics.shared.lsp")
local buffers = require("mcp-diagnostics.shared.buffers")
local extra = require("mcp-diagnostics.mcphub.tools_extra")

function M.register_all(mcphub, server_name, server_config)
  server_config = server_config or {}
  -- Use extra tools with stronger prompting
  extra.register_all(mcphub, server_name, server_config)
end

function M.register_diagnostic_tools(mcphub, server_name, server_config)
  server_config = server_config or {}

  -- diagnostics_get tool
  mcphub.add_tool(server_name, {
    name = "diagnostics_get",
    description = "Get diagnostics for specified files with optional filtering",
    inputSchema = {
      type = "object",
      properties = {
        files = {
          type = "array",
          items = { type = "string" },
          description = "Files to get diagnostics for (all if not specified)"
        },
        severity = {
          type = "string",
          enum = { "error", "warn", "info", "hint" },
          description = "Filter by severity level"
        },
        source = {
          type = "string",
          description = "Filter by diagnostic source (e.g. 'pylsp', 'eslint')"
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

  -- diagnostics_summary tool
  mcphub.add_tool(server_name, {
    name = "diagnostics_summary",
    description = "Get diagnostic summary with counts by severity and file",
    handler = function(_req, res)
      local summary = diagnostics.get_diagnostic_summary()
      return res:text(vim.json.encode(summary), "application/json"):send()
    end
  })
end

function M.register_lsp_tools(mcphub, server_name, server_config)
  server_config = server_config or {}

  -- LSP hover tool
  mcphub.add_tool(server_name, {
    name = "lsp_hover",
    description = "Get LSP hover information for a position in a file",
    inputSchema = {
      type = "object",
      properties = {
        file = { type = "string", description = "File path" },
        line = { type = "number", description = "Line number (0-based)" },
        column = { type = "number", description = "Column number (0-based)" }
      },
      required = { "file", "line", "column" }
    },
    handler = function(_req, res)
      local hover_info = lsp.get_hover_info(_req.params.file, _req.params.line, _req.params.column)
      return res:text(vim.json.encode(hover_info), "application/json"):send()
    end
  })

  -- LSP definition tool
  mcphub.add_tool(server_name, {
    name = "lsp_definition",
    description = "Get LSP definition for a symbol at a position",
    inputSchema = {
      type = "object",
      properties = {
        file = { type = "string", description = "File path" },
        line = { type = "number", description = "Line number (0-based)" },
        column = { type = "number", description = "Column number (0-based)" }
      },
      required = { "file", "line", "column" }
    },
    handler = function(_req, res)
      local definitions = lsp.get_definitions(_req.params.file, _req.params.line, _req.params.column)
      return res:text(vim.json.encode(definitions), "application/json"):send()
    end
  })

  -- LSP references tool
  mcphub.add_tool(server_name, {
    name = "lsp_references",
    description = "Get LSP references for a symbol at a position",
    inputSchema = {
      type = "object",
      properties = {
        file = { type = "string", description = "File path" },
        line = { type = "number", description = "Line number (0-based)" },
        column = { type = "number", description = "Column number (0-based)" }
      },
      required = { "file", "line", "column" }
    },
    handler = function(_req, res)
      local references = lsp.get_references(_req.params.file, _req.params.line, _req.params.column)
      return res:text(vim.json.encode(references), "application/json"):send()
    end
  })

  -- LSP document symbols tool
  mcphub.add_tool(server_name, {
    name = "lsp_document_symbols",
    description = "Get document symbols for a file",
    inputSchema = {
      type = "object",
      properties = {
        file = { type = "string", description = "File path" }
      },
      required = { "file" }
    },
    handler = function(_req, res)
      local symbols = lsp.get_document_symbols(_req.params.file)
      return res:text(vim.json.encode(symbols), "application/json"):send()
    end
  })

  -- LSP workspace symbols tool
  mcphub.add_tool(server_name, {
    name = "lsp_workspace_symbols",
    description = "Get workspace symbols with optional query",
    inputSchema = {
      type = "object",
      properties = {
        query = { type = "string", description = "Search query for symbols" }
      }
    },
    handler = function(_req, res)
      local symbols = lsp.get_workspace_symbols(_req.params.query)
      return res:text(vim.json.encode(symbols), "application/json"):send()
    end
  })

  -- LSP code actions tool
  mcphub.add_tool(server_name, {
    name = "lsp_code_actions",
    description = "Get available code actions for a position",
    inputSchema = {
      type = "object",
      properties = {
        file = { type = "string", description = "File path" },
        line = { type = "number", description = "Line number (0-based)" },
        column = { type = "number", description = "Column number (0-based)" },
        end_line = { type = "number", description = "End line number (0-based)" },
        end_column = { type = "number", description = "End column number (0-based)" }
      },
      required = { "file", "line", "column" }
    },
    handler = function(_req, res)
      local actions = lsp.get_code_actions(_req.params.file, _req.params.line, _req.params.column, _req.params.end_line, _req.params.end_column)
      return res:text(vim.json.encode(actions), "application/json"):send()
    end
  })
end

function M.register_buffer_tools(mcphub, server_name, server_config)
  server_config = server_config or {}

  -- buffer_status tool
  mcphub.add_tool(server_name, {
    name = "buffer_status",
    description = "Get status of all loaded buffers",
    handler = function(_req, res)
      local status = buffers.get_buffer_status()
      return res:text(vim.json.encode(status), "application/json"):send()
    end
  })
end

return M
