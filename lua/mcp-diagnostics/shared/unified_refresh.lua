-- Unified external file refresh system
-- Handles buffer reload + LSP notification in perfect synchronization
-- No more version mismatches or race conditions!

local config = require("mcp-diagnostics.shared.config")
local lsp_interact = require("mcp-diagnostics.shared.lsp_interact")

-- LSP Methods from protocol  
local LSP_METHODS = {
    hover = vim.lsp.protocol.Methods.textDocument_hover,
}

local M = {}

function M.unified_external_refresh(filepath, mode)
  mode = mode or config.get_auto_reload_mode()

  local bufnr = vim.fn.bufnr(filepath)
  if bufnr == -1 then
    config.log_debug(string.format("File not loaded in buffer: %s", filepath), "[Unified Refresh]")
    return { success = false, reason = "not_loaded" }
  end

  -- Handle different modes
  if mode == "off" then
    vim.notify(
      string.format("File %s changed externally (auto-reload disabled)", vim.fn.fnamemodify(filepath, ":t")),
      vim.log.levels.WARN
    )
    return { success = false, reason = "disabled" }
  elseif mode == "prompt" then
    local choice = vim.fn.confirm(
      string.format("File %s has been modified externally. Reload?", vim.fn.fnamemodify(filepath, ":t")),
      "&Yes\n&No", 1, "Question"
    )
    if choice ~= 1 then
      return { success = false, reason = "user_declined" }
    end
  end

  -- Capture version BEFORE reload
  local before_changedtick = vim.api.nvim_buf_get_changedtick(bufnr)

  -- Unified reload: use checktime to gracefully reload only if file changed
  local reload_success, reload_error = pcall(function()
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd('checktime')
    end)
  end)

  if not reload_success then
    config.log_error(string.format("Buffer reload failed: %s (%s)", filepath, reload_error), "[Unified Refresh]")
    return { success = false, reason = "reload_failed", error = reload_error }
  end

  -- Get the NEW changedtick that Neovim created
  local after_changedtick = vim.api.nvim_buf_get_changedtick(bufnr)

  -- Send LSP notification with Neovim's actual version (KEY INSIGHT!)
  -- Only notify LSP if file actually changed (checktime is smarter than edit!)
  if after_changedtick ~= before_changedtick then
    lsp_interact.notify_lsp_file_changed_with_version(filepath, bufnr, after_changedtick)
    config.log_debug(string.format("File changed, notified LSP: %s (tick %d -> %d)", 
      filepath, before_changedtick, after_changedtick), "[Unified Refresh]")
  else
    config.log_debug(string.format("File unchanged, no LSP notification needed: %s (tick %d)", 
      filepath, before_changedtick), "[Unified Refresh]")
  end


  return {
    success = true,
    before_version = before_changedtick,
    after_version = after_changedtick,
    version_changed = after_changedtick ~= before_changedtick,
    filepath = filepath
  }
end

-- Batch refresh multiple files
function M.unified_batch_refresh(filepaths, mode)
  local results = {}
  local success_count = 0

  for _, filepath in ipairs(filepaths) do
    local result = M.unified_external_refresh(filepath, mode)
    results[filepath] = result
    if result.success then
      success_count = success_count + 1
    end
  end

  return {
    success = success_count > 0,
    total_files = #filepaths,
    success_count = success_count,
    failed_count = #filepaths - success_count,
    results = results
  }
end

-- Wait for LSP to acknowledge the version change
function M.wait_for_lsp_acknowledgment(filepath, max_wait_ms)
  max_wait_ms = max_wait_ms or 3000
  local start_time = vim.loop.now()

  local bufnr = vim.fn.bufnr(filepath)
  if bufnr == -1 then
    return { success = false, reason = "buffer_not_found" }
  end

  -- Use synchronous LSP request to ensure LSP processed changes
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if #clients == 0 then
    return { success = false, reason = "no_lsp_clients" }
  end

  -- Use first available client for sync request
  local client = clients[1]

  -- Make a lightweight synchronous request to ensure LSP is caught up
  local params = {
    textDocument = {
      uri = vim.uri_from_bufnr(bufnr)
    },
    position = { line = 0, character = 0 }
  }

  local success, result = pcall(function()
    -- Use a timeout that's reasonable but not too long
    local timeout = math.min(max_wait_ms, 1000) -- Max 1 second for sync request
    return client.request_sync(LSP_METHODS.hover, params, timeout)
  end)

  local wait_time = vim.loop.now() - start_time

  if success and result then
    return {
      success = true,
      wait_time = wait_time,
      final_version = vim.api.nvim_buf_get_changedtick(bufnr),
      method = "sync_request",
      client_name = client.name
    }
  else
    return {
      success = false,
      reason = "sync_request_failed",
      wait_time = wait_time,
      error = result,
      client_name = client.name
    }
  end
end

-- Smart refresh with acknowledgment
function M.unified_refresh_and_wait(filepath, mode, max_wait_ms)
  local refresh_result = M.unified_external_refresh(filepath, mode)

  if not refresh_result.success then
    return refresh_result
  end

  -- Wait for LSP to acknowledge if version changed
  if refresh_result.version_changed then
    local wait_result = M.wait_for_lsp_acknowledgment(
      filepath,
      max_wait_ms
    )

    return {
      success = refresh_result.success and wait_result.success,
      refresh_result = refresh_result,
      wait_result = wait_result,
      total_time = wait_result.wait_time
    }
  else
    -- No version change, no need to wait
    return {
      success = true,
      refresh_result = refresh_result,
      no_wait_needed = true
    }
  end
end

return M
