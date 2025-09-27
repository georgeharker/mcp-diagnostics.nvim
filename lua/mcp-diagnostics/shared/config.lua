-- Shared configuration management for MCP Diagnostics
-- Provides unified access to configuration across mcphub and server modes

local M = {}

-- Default configurations for each mode
M.defaults = {
  mcphub = {
    server_name = "mcp-diagnostics",
    displayName = "Neovim Diagnostics & LSP",
    debug = false,
    auto_approve = false,
    lsp_timeout = 1000,
    enable_diagnostics = true,
    enable_lsp = true,
    enable_prompts = true,
    auto_register = true,
    auto_reload_files = true,
    auto_reload_mode = "auto", -- "auto", "prompt", "off"
    lsp_notify_mode = "auto", -- "auto", "manual", "disabled"
  },
  server = {
    server_address = '/tmp/nvim.sock',
    server_host = '127.0.0.1',
    server_port = 6666,
    auto_start_server = false,
    export_path = '/tmp/nvim_diagnostics.json',
    auto_build = false,
    auto_launch = false,
    node_server_path = nil,
    build_command = 'npm install && npm run build',
    build_cwd = nil,
    node_args = {},
    node_env = {},
    restart_on_crash = true,
    health_check_interval = 5000,
    auto_reload_files = true,
    auto_reload_mode = "auto", -- "auto", "prompt", "off"
    lsp_notify_mode = "auto", -- "auto", "manual", "disabled"
  }
}

-- Get the currently active configuration and mode
function M.get_active_config()
  -- Check for mcphub config first
  local mcphub_config = rawget(_G, '_mcp_diagnostics_mcphub_config')
  if mcphub_config then
    return mcphub_config, 'mcphub'
  end

  -- Check for server config
  local server_config = rawget(_G, '_mcp_diagnostics_server_config')
  if server_config then
    return server_config, 'server'
  end

  return nil, nil
end

-- Get configuration with proper defaults merged
function M.get_merged_config(user_config, mode)
  mode = mode or 'mcphub' -- Default to mcphub mode
  local defaults = M.defaults[mode] or {}

  if user_config then
    return vim.tbl_deep_extend("force", defaults, user_config)
  end

  return defaults
end

function M.is_feature_enabled(feature)
  local config, mode = M.get_active_config()
  if not config then
    return false
  end

  -- Common features across modes
  if feature == 'auto_reload_files' then
    return config.auto_reload_files ~= false
  elseif feature == 'debug' then
    return config.debug == true
  elseif feature == 'diagnostics' then
    return mode == 'server' or config.enable_diagnostics ~= false
  elseif feature == 'lsp' then
    return mode == 'server' or config.enable_lsp ~= false
  elseif feature == 'prompts' then
    return mode == 'server' or config.enable_prompts ~= false
  end

  return false
end

 -- Get auto reload mode configuration
 function M.get_auto_reload_mode()
   local config = M.get_active_config()
   if config and config.auto_reload_mode then
     return config.auto_reload_mode
   end
   return "reload" -- Default mode
 end

 -- Get LSP notify mode configuration
 function M.get_lsp_notify_mode()
   local config = M.get_active_config()
   if config and config.lsp_notify_mode then
     return config.lsp_notify_mode
   end
   return "auto" -- Default mode
 end

function M.get_lsp_timeout()
  local config = M.get_active_config()
  if config and config.lsp_timeout then
    return config.lsp_timeout
  end
  return 1000 -- Default timeout
end

-- Unified logging function
function M.log(level, message, prefix)
  if not M.is_feature_enabled('debug') and level == vim.log.levels.DEBUG then
    return
  end

  local _, mode = M.get_active_config()
  local log_prefix = prefix or string.format("[MCP Diagnostics %s]", mode or "unknown")

  vim.notify(log_prefix .. " " .. tostring(message), level or vim.log.levels.INFO)
end

-- Helper to log debug messages
function M.log_debug(message, prefix)
  M.log(vim.log.levels.DEBUG, message, prefix)
end

-- Helper to log info messages
function M.log_info(message, prefix)
  M.log(vim.log.levels.INFO, message, prefix)
end

-- Helper to log error messages
function M.log_error(message, prefix)
  M.log(vim.log.levels.ERROR, message, prefix)
end

return M
