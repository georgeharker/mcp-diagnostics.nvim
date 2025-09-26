-- Health check for mcp-diagnostics plugin
local M = {}

local health = vim.health

function M.check()
  health.start("MCP Diagnostics Plugin")

  -- Store server config for later use
  local server_config = rawget(_G, '_mcp_diagnostics_server_config')

  -- Check plugin installation
  local has_plugin, plugin = pcall(require, "mcp-diagnostics")
  if has_plugin then
    health.ok("Plugin loaded successfully")
  else
    health.error("Plugin failed to load: " .. tostring(plugin))
    return
  end

  -- Check configuration
  if rawget(_G, '_mcp_diagnostics_mcphub_config') then
    local config = rawget(_G, '_mcp_diagnostics_mcphub_config')
    health.ok("Configuration found")
    health.info("Server name: " .. (config.server_name or "unknown"))
    health.info("Display name: " .. (config.displayName or "unknown"))
    health.info("Mode: mcphub")

    if config.auto_approve then
      health.ok("Auto-approve enabled")
    else
      health.info("Auto-approve disabled (manual confirmation required)")
    end

    if config.debug then
      health.info("Debug mode enabled")
    end
  elseif rawget(_G, '_mcp_diagnostics_server_config') then
    health.ok("Configuration found")
    health.info("Mode: server")
  else
    health.warn("No configuration found - run setup() first")
  end

  health.start("Dependencies")

  -- Check mcphub.nvim if in mcphub mode
  if rawget(_G, '_mcp_diagnostics_mcphub_config') then
    local has_mcphub, _mcphub = pcall(require, "mcphub")
    if has_mcphub then
      health.ok("mcphub.nvim is available")
    else
      health.error("mcphub.nvim not found but required for mcphub mode")
    end
  end

  -- Check LSP
  local lsp_clients = vim.lsp.get_clients()
  if #lsp_clients > 0 then
    health.ok(string.format("LSP clients attached (%d active)", #lsp_clients))
    for _, client in ipairs(lsp_clients) do
      health.info("  - " .. client.name)
    end
  else
    health.warn("No LSP clients attached - LSP tools will not work")
  end

  health.start("Core Modules")

  local core_modules = {
    "mcp-diagnostics.mcphub.core",
    "mcp-diagnostics.mcphub.tools",
    "mcp-diagnostics.mcphub.resources",
    "mcp-diagnostics.mcphub.prompts",
    "mcp-diagnostics.server.init"
  }

  for _, module_name in ipairs(core_modules) do
    local success, result = pcall(require, module_name)
    if success then
      health.ok(module_name .. " loaded")
    else
      -- Only error if it's a required module for current mode
      if rawget(_G, '_mcp_diagnostics_mcphub_config') and module_name:match("mcphub") then
        health.error(module_name .. " failed to load: " .. tostring(result))
      elseif server_config and module_name:match("server") then
        health.error(module_name .. " failed to load: " .. tostring(result))
      else
        health.info(module_name .. " (not loaded - different mode)")
      end
    end
  end

  health.start("Diagnostics")

  -- Check current diagnostics
  local all_diagnostics = vim.diagnostic.get()
  if #all_diagnostics > 0 then
    local error_count = 0
    local warn_count = 0
    local info_count = 0
    local hint_count = 0

    for _, diag in ipairs(all_diagnostics) do
      if diag.severity == vim.diagnostic.severity.ERROR then
        error_count = error_count + 1
      elseif diag.severity == vim.diagnostic.severity.WARN then
        warn_count = warn_count + 1
      elseif diag.severity == vim.diagnostic.severity.INFO then
        info_count = info_count + 1
      elseif diag.severity == vim.diagnostic.severity.HINT then
        hint_count = hint_count + 1
      end
    end

    health.ok(string.format("Diagnostics available: %d total", #all_diagnostics))
    if error_count > 0 then
      health.info(string.format("  - Errors: %d", error_count))
    end
    if warn_count > 0 then
      health.info(string.format("  - Warnings: %d", warn_count))
    end
    if info_count > 0 then
      health.info(string.format("  - Info: %d", info_count))
    end
    if hint_count > 0 then
      health.info(string.format("  - Hints: %d", hint_count))
    end
  else
    health.warn("No diagnostics found in current session")
  end

  health.start("Buffer Status")

  local loaded_buffers = 0
  local lsp_attached_buffers = 0

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      loaded_buffers = loaded_buffers + 1
      local buf_clients = vim.lsp.get_clients({ bufnr = buf })
      if #buf_clients > 0 then
        lsp_attached_buffers = lsp_attached_buffers + 1
      end
    end
  end

  health.ok(string.format("Loaded buffers: %d", loaded_buffers))
  if lsp_attached_buffers > 0 then
    health.ok(string.format("Buffers with LSP: %d", lsp_attached_buffers))
  else
    health.warn("No buffers have LSP attached")
  end

  -- Server mode specific checks
  if server_config then
    health.start("Server Mode")

    -- Check if Node.js is available
    local node_available = vim.fn.executable("node") == 1
    if node_available then
      health.ok("Node.js is available")
    else
      health.error("Node.js not found - required for server mode")
    end

    -- Check if server directory exists
    local server_path = vim.fn.getcwd() .. "/server/mcp-diagnostics"
    if vim.fn.isdirectory(server_path) == 1 then
      health.ok("Server directory found: " .. server_path)

      -- Check if built
      local dist_path = server_path .. "/dist/index.js"
      if vim.fn.filereadable(dist_path) == 1 then
        health.ok("Server is built (dist/index.js exists)")
      else
        health.warn("Server not built - run 'cd server/mcp-diagnostics && npm install && npm run build'")
      end
    else
      health.error("Server directory not found: " .. server_path)
    end
  end

  health.start("Recommendations")

  if not rawget(_G, '_mcp_diagnostics_mcphub_config') and not rawget(_G, '_mcp_diagnostics_server_config') then
    health.info("Run require('mcp-diagnostics').setup({ mode = 'mcphub' }) to get started")
  end

  if #lsp_clients == 0 then
    health.info("Setup LSP servers for better diagnostic and code navigation features")
  end

  if #all_diagnostics == 0 and #lsp_clients > 0 then
    health.info("Open files with errors/warnings to test diagnostic features")
  end
end

return M
