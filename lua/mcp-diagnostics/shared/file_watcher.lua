-- Shared file watcher for MCP Diagnostics
-- Provides unified file auto-reload functionality for both mcphub and server modes

local config = require("mcp-diagnostics.shared.config")
local M = {}

-- Global state for file watchers
local file_watchers = {}
local buffer_file_times = {}

-- Get file modification time
local function get_file_mtime(filepath)
  local stat = vim.loop.fs_stat(filepath)
  return stat and stat.mtime.sec or 0
end

function M.setup_watcher(filepath, bufnr, log_prefix)
  if file_watchers[filepath] then
    return -- Already watching this file
  end

  -- Check if auto-reload is disabled
  local reload_mode = config.get_auto_reload_mode()
  if reload_mode == "none" then
    config.log_debug(string.format("Auto-reload disabled, skipping watcher for: %s", filepath), log_prefix or "[Shared File Watcher]")
    return
  end

  log_prefix = log_prefix or "[Shared File Watcher]"
  config.log_debug(string.format("Setting up file watcher for: %s", filepath), log_prefix)

  -- Store initial modification time
  buffer_file_times[filepath] = get_file_mtime(filepath)

  -- Create file watcher using vim.loop (libuv)
  local watcher = vim.loop.new_fs_event()
  if not watcher then
    config.log_debug(string.format("Failed to create file watcher for: %s", filepath), log_prefix)
    return
  end

  file_watchers[filepath] = watcher

  local function on_file_change(err, _filename, _events)
    if err then
      config.log_debug(string.format("File watcher error for %s: %s", filepath, err), log_prefix)
      return
    end

    -- Check if file actually changed (avoid duplicate events)
    local current_mtime = get_file_mtime(filepath)
    local last_mtime = buffer_file_times[filepath] or 0

    if current_mtime > last_mtime then
      buffer_file_times[filepath] = current_mtime

      local current_reload_mode = config.get_auto_reload_mode()
      config.log_debug(string.format("File changed: %s (reload_mode: %s)", filepath, current_reload_mode), log_prefix)

      vim.schedule(function()
        -- Check if buffer is still valid and loaded
        if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then

          if current_reload_mode == "ask" then
            local filename = vim.fn.fnamemodify(filepath, ":t")
            local choice = vim.fn.confirm(
              string.format("File %s has been modified externally. Reload?", filename),
              "&Yes\n&No\n&Always\n&Never", 1, "Question"
            )

            if choice == 1 then -- Yes (reload once)
              current_reload_mode = "reload"
            elseif choice == 2 then -- No (skip this time)
              return
            elseif choice == 3 then -- Always (change config and reload)
              -- This would need config updating capability
              current_reload_mode = "reload"
            elseif choice == 4 then -- Never (disable watching)
              M.cleanup_watcher(filepath)
              return
            end
          end

          if current_reload_mode == "reload" then
            -- Reload the buffer content
            local ok, err_msg = pcall(function()
              vim.api.nvim_buf_call(bufnr, function()
                vim.cmd('edit!')
              end)
            end)

            if ok then
              config.log_debug(string.format("Successfully reloaded buffer: %s", filepath), log_prefix)
              vim.notify("Auto-reloaded: " .. vim.fn.fnamemodify(filepath, ":t"), vim.log.levels.INFO)

              -- Notify LSP of file change via lsp_interact
              local lsp_interact = package.loaded["mcp-diagnostics.shared.lsp_interact"]
              if lsp_interact then
                lsp_interact.handle_file_changed(filepath, bufnr)
              end
            else
              config.log_debug(string.format("Failed to reload buffer %s: %s", filepath, tostring(err_msg)), log_prefix)
            end
          else
            config.log_debug(string.format("File changed but reload skipped for: %s", filepath), log_prefix)
            vim.notify(string.format("File %s changed externally (reload disabled)", vim.fn.fnamemodify(filepath, ":t")), vim.log.levels.WARN)

            -- Still notify LSP even if we don't reload the buffer
            local lsp_interact = package.loaded["mcp-diagnostics.shared.lsp_interact"]
            if lsp_interact then
              lsp_interact.handle_file_changed(filepath, bufnr)
            end
          end
        else
          -- Buffer is no longer valid, clean up watcher
          M.cleanup_watcher(filepath)
        end
      end)
    end
  end

  -- Start watching the file
  local ok, watch_err = pcall(function()
    watcher:start(filepath, {}, on_file_change)
  end)

  if not ok then
    config.log_debug(string.format("Failed to start file watcher for %s: %s", filepath, tostring(watch_err)), log_prefix)
    file_watchers[filepath] = nil
    watcher:close()
  else
    config.log_debug(string.format("File watcher started for: %s", filepath), log_prefix)

    -- Set up buffer cleanup when buffer is deleted
    vim.api.nvim_create_autocmd("BufDelete", {
      buffer = bufnr,
      callback = function()
        M.cleanup_watcher(filepath)
      end,
      once = true,
      desc = string.format("Cleanup file watcher for %s", filepath)
    })
  end
end

-- Clean up a specific file watcher
function M.cleanup_watcher(filepath)
  local watcher = file_watchers[filepath]
  if watcher then
    watcher:stop()
    watcher:close()
    file_watchers[filepath] = nil
    buffer_file_times[filepath] = nil
    config.log_debug(string.format("Cleaned up file watcher for: %s", filepath), "[Shared File Watcher]")
  end
end

function M.cleanup_all_watchers()
  for _filepath, watcher in pairs(file_watchers) do
    watcher:stop()
    watcher:close()
  end
  file_watchers = {}
  buffer_file_times = {}
  config.log_debug("Cleaned up all file watchers", "[Shared File Watcher]")
end

-- Get status of all active watchers
function M.get_watcher_status()
  local status = {}
  for filepath, _watcher in pairs(file_watchers) do
    status[filepath] = {
      watching = true,
      last_mtime = buffer_file_times[filepath] or 0,
      current_mtime = get_file_mtime(filepath)
    }
  end
  return status
end

-- Check if a file is being watched
function M.is_watching(filepath)
  return file_watchers[filepath] ~= nil
end

function M.get_watcher_count()
  return vim.tbl_count(file_watchers)
end

 function M.check_file_staleness(filepath, _bufnr)
  if not filepath then
    return false
  end

  -- Get current file modification time
  local current_mtime = get_file_mtime(filepath)
  local stored_mtime = buffer_file_times[filepath]

  if not stored_mtime then
    -- File not being watched, consider it fresh
    return false
  end

  -- Check if file has been modified externally
  if current_mtime > stored_mtime then
    config.log_debug(string.format("File %s is stale (mtime: %d vs %d)", filepath, current_mtime, stored_mtime), "[File Watcher]")
    return true
  end

  return false
end

-- Check all watched files for staleness
function M.check_all_files_staleness()
  local stale_files = {}

  for filepath, _ in pairs(file_watchers) do
    if M.check_file_staleness(filepath, nil) then
      table.insert(stale_files, filepath)
    end
  end

  return stale_files
end
local unified_refresh = require("mcp-diagnostics.shared.unified_refresh")

 -- Force refresh all watched files (useful for external changes)
 function M.refresh_all_watched_files()
   config.log_debug("Force refreshing all watched files", "[File Watcher]")
   local files_to_refresh = {}

   for filepath, _ in pairs(file_watchers) do
     if M.check_file_staleness(filepath, nil) then
       -- Find the buffer for this file
       local bufnr = vim.fn.bufnr(filepath)
       if bufnr ~= -1 and vim.api.nvim_buf_is_valid(bufnr) then
         table.insert(files_to_refresh, filepath)
       end
     end
   end

   -- Use unified refresh system for perfect LSP synchronization
   if #files_to_refresh > 0 then
     local batch_result = unified_refresh.unified_batch_refresh(files_to_refresh, config.get_auto_reload_mode())

     config.log_debug(string.format("Unified refresh completed: %d/%d files succeeded",
       batch_result.success_count, batch_result.total_files), "[File Watcher]")

     if batch_result.success_count > 0 then
       vim.notify(string.format("Auto-refreshed %d files with LSP sync", batch_result.success_count), vim.log.levels.INFO)
     end

     return batch_result.results
   end

   return {}
 end

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    M.cleanup_all_watchers()
  end,
  desc = "Cleanup MCP diagnostics file watchers on exit",
  group = vim.api.nvim_create_augroup("MCPDiagnosticsFileWatcher", { clear = true })
})

return M
