-- MCP Diagnostics Plugin for Neovim
-- Provides three integration approaches for MCP (Model Context Protocol) diagnostics and LSP

local M = {}

--- @class McpDiagnosticsOpts Configuration options
---@field mode string Integration mode: "mcphub", "server", or "codecompanion"
---@field mcphub table|nil mcphub-specific configuration (when mode = "mcphub")
---@field server table|nil server-specific configuration (when mode = "server")
---@field codecompanion table|nil codecompanion-specific configuration (when mode = "codecompanion")
---@field codecompanion.auto_register boolean|nil Route 2: Enable automatic dynamic registration (default: false)

--- Setup the MCP diagnostics plugin
--- @param opts McpDiagnosticsOpts Configuration options
--- @return boolean success True if setup succeeded
function M.setup(opts)
  opts = opts or {}

  if not opts.mode then
    vim.notify(
      "[MCP Diagnostics] No mode specified. Use 'mcphub', 'server', or 'codecompanion'. See :help mcp-diagnostics",
      vim.log.levels.ERROR
    )
    return false
  end

  if opts.mode == "mcphub" then
    local has_mcphub, _mcphub = pcall(require, "mcphub")
    if not has_mcphub then
      vim.notify(
        "[MCP Diagnostics] mcphub.nvim is required for 'mcphub' mode. Please install it first.",
        vim.log.levels.ERROR
      )
      return false
    end
    return require("mcp-diagnostics.mcphub").setup(opts.mcphub or {})
  elseif opts.mode == "server" then
    return require("mcp-diagnostics.server").setup(opts.server or {})
  elseif opts.mode == "codecompanion" then
    return require("mcp-diagnostics.codecompanion").setup(opts.codecompanion or {})
  else
    vim.notify(
      "[MCP Diagnostics] Invalid mode '" .. opts.mode .. "'. Use 'mcphub', 'server', or 'codecompanion'.",
      vim.log.levels.ERROR
    )
    return false
  end
end

return M
