-- MCP Diagnostics Plugin for Neovim
-- Provides two integration approaches for MCP (Model Context Protocol) diagnostics and LSP

local M = {}

---@class McpDiagnosticsOpts
---@field mode string Integration mode: "mcphub" or "server"
---@field mcphub table|nil mcphub-specific configuration (when mode = "mcphub")
---@field server table|nil server-specific configuration (when mode = "server")

--- Setup the MCP diagnostics plugin
--- @param opts McpDiagnosticsOpts Configuration options
function M.setup(opts)
  opts = opts or {}

  if not opts.mode then
    vim.notify(
      "[MCP Diagnostics] No mode specified. Use 'mcphub' or 'server'. See :help mcp-diagnostics",
      vim.log.levels.ERROR
    )
    return false
  end

  if opts.mode == "mcphub" then
    return M.setup_mcphub(opts.mcphub or {})
  elseif opts.mode == "server" then
    return M.setup_server(opts.server or {})
  else
    vim.notify(
      "[MCP Diagnostics] Invalid mode '" .. opts.mode .. "'. Use 'mcphub' or 'server'.",
      vim.log.levels.ERROR
    )
    return false
  end
end

function M.setup_mcphub(opts)
  local has_mcphub, _mcphub = pcall(require, "mcphub")
  if not has_mcphub then
    vim.notify(
      "[MCP Diagnostics] mcphub.nvim is required for 'mcphub' mode. Please install it first.",
      vim.log.levels.ERROR
    )
    return false
  end

  local mcphub_integration = require("mcp-diagnostics.mcphub.init")
  return mcphub_integration.setup(opts)
end

function M.setup_server(opts)
  local server_integration = require("mcp-diagnostics.server.init")  --diagnostics:ignore:same-file
  return server_integration.setup(opts)
end

--- Quick setup for mcphub.nvim users
function M.mcphub()
  return M.setup({ mode = "mcphub" })
end

--- Quick setup for Node.js server users
function M.server()
  return M.setup({ mode = "server" })
end

M.mcphub_module = function()
  return require("mcp-diagnostics.mcphub.init")
end

M.server_module = function()
  return require("mcp-diagnostics.server.init")
end

return M
