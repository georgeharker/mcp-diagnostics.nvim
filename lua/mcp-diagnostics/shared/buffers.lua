-- Shared buffer management for MCP Diagnostics
-- Provides unified buffer operations for both mcphub and server modes

local config = require("mcp-diagnostics.shared.config")
local M = {}

-- Setup detection for when user intentionally edits a hidden buffer
local function setup_user_edit_detection(bufnr, filepath)
  -- Set up autocmd to detect when buffer becomes visible due to user action
  vim.api.nvim_create_autocmd({"BufWinEnter", "BufEnter"}, {
    buffer = bufnr,
    once = true, -- Only trigger once
    callback = function()
      -- Check if buffer is now listed (indicating user action)
      local is_listed = vim.api.nvim_buf_get_option(bufnr, 'buflisted')
      local is_hidden = vim.api.nvim_buf_get_option(bufnr, 'bufhidden')

      if is_listed and is_hidden == 'hide' then
        -- User has made buffer listed (via :edit or similar), make it fully visible
        vim.api.nvim_buf_set_option(bufnr, 'bufhidden', '')
        config.log_debug(string.format("Buffer %d (%s) made fully visible by user action", bufnr, filepath), "[Shared Buffers]")
      end
    end,
    desc = "Make hidden buffer fully visible when user edits it"
  })
end

local function get_buffer_name(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return "[No Name]"
  end
  return name
end

-- Check if buffer is a real file (not special buffer)
local function is_real_file_buffer(bufnr)
  local buftype = vim.api.nvim_buf_get_option(bufnr, 'buftype')
  local name = get_buffer_name(bufnr)
  return buftype == '' and name ~= '[No Name]'
end

-- Get comprehensive buffer status
function M.get_buffer_status()
  config.log_debug("Getting buffer status", "[Shared Buffers]")

  local status = {}
  local buffers = vim.api.nvim_list_bufs()

  for _, bufnr in ipairs(buffers) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local name = get_buffer_name(bufnr)
      local is_loaded = vim.api.nvim_buf_is_loaded(bufnr)

      if is_loaded then
        -- Check if buffer represents a real file
        -- Get LSP client info
        local lsp_clients = {}
        -- Neovim 0.10+
        local clients = vim.lsp.get_clients({ bufnr = bufnr })
        for _, client in ipairs(clients) do
          table.insert(lsp_clients, client.name)
        end

        -- Get buffer info
        local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
        local modified = vim.api.nvim_buf_get_option(bufnr, 'modified')
        local readonly = vim.api.nvim_buf_get_option(bufnr, 'readonly')
        local line_count = vim.api.nvim_buf_line_count(bufnr)

        -- Get file stats if available
        local file_exists = vim.fn.filereadable(name) == 1
        local file_size = file_exists and vim.fn.getfsize(name) or 0

        status[name] = {
          bufnr = bufnr,
          loaded = is_loaded,
          -- Backward compatibility fields
          auto_reload = config.is_feature_enabled('auto_reload_files'),
          -- Enhanced fields for real files
          filetype = filetype,
          modified = modified,
          readonly = readonly,
          line_count = line_count,
          file_exists = file_exists,
          file_size = file_size,
          lsp_clients = lsp_clients,
          has_lsp = #lsp_clients > 0
        }
      end
    end
  end

  config.log_debug(string.format("Found %d loaded file buffers", vim.tbl_count(status)), "[Shared Buffers]")
  return status
end

function M.ensure_buffer_loaded(filepath, enable_auto_reload)
  config.log_debug(string.format("Ensuring buffer loaded: %s", filepath), "[Shared Buffers]")

  -- Default auto-reload based on configuration
  if enable_auto_reload == nil then
    enable_auto_reload = config.is_feature_enabled('auto_reload_files')
  end

  -- First, try to find existing buffer (reuse where possible)
  local bufnr = vim.fn.bufnr(filepath)
  local buffer_created = false

  if bufnr == -1 then
    -- Buffer doesn't exist, create it as unlisted/hidden
    bufnr = vim.fn.bufnr(filepath, true)
    buffer_created = true

    -- Make the buffer unlisted and hidden so it doesn't appear in CodeCompanion UI
    vim.api.nvim_buf_set_option(bufnr, 'buflisted', false)
    vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'hide')

    -- Set up autocmd to make buffer visible when user intentionally edits it
    vim.schedule(function()
      setup_user_edit_detection(bufnr, filepath)
    end)

    config.log_debug(string.format("Created unlisted buffer %d for file: %s", bufnr, filepath), "[Shared Buffers]")
  else
    -- Buffer exists - reuse it
    config.log_debug(string.format("Reusing existing buffer %d for file: %s", bufnr, filepath), "[Shared Buffers]")
  end

  if not vim.api.nvim_buf_is_loaded(bufnr) then
    -- Load the buffer
    vim.fn.bufload(bufnr)
  end

  -- Set up auto-reload if requested and file watching is available
  if enable_auto_reload and vim.fn.filereadable(filepath) == 1 then
    local file_watcher = require("mcp-diagnostics.shared.file_watcher")
    file_watcher.setup_watcher(filepath, bufnr, "[Shared Buffers]")
  end

  local loaded = vim.api.nvim_buf_is_loaded(bufnr)
  config.log_debug(string.format("Buffer %s loaded: %s, auto-reload: %s",
    filepath, tostring(loaded), tostring(enable_auto_reload)), "[Shared Buffers]")

  return bufnr, loaded
end

-- Get buffer statistics
function M.get_buffer_statistics()
  local status = M.get_buffer_status()

  local stats = {
    total_buffers = vim.tbl_count(status),
    with_lsp = 0,
    by_filetype = {},
    by_lsp_client = {},
    total_lines = 0,
    total_size = 0,
    modified_files = 0,
    readonly_files = 0
  }

  for _, info in pairs(status) do
    -- Count LSP-enabled buffers
    if info.has_lsp then
      stats.with_lsp = stats.with_lsp + 1
    end

    -- Count by filetype
    local ft = info.filetype or 'none'
    stats.by_filetype[ft] = (stats.by_filetype[ft] or 0) + 1

    -- Count by LSP client
    for _, client in ipairs(info.lsp_clients) do
      stats.by_lsp_client[client] = (stats.by_lsp_client[client] or 0) + 1
    end

    -- Accumulate stats
    stats.total_lines = stats.total_lines + info.line_count
    stats.total_size = stats.total_size + info.file_size

    if info.modified then
      stats.modified_files = stats.modified_files + 1
    end

    if info.readonly then
      stats.readonly_files = stats.readonly_files + 1
    end
  end

  return stats
end

-- Find buffers matching certain criteria
function M.find_buffers(criteria)
  local status = M.get_buffer_status()
  local matches = {}

  for filepath, info in pairs(status) do
    local match = true

    -- Filter by filetype
    if criteria.filetype and info.filetype ~= criteria.filetype then
      match = false
    end

    -- Filter by LSP client
    if criteria.lsp_client then
      local has_client = false
      for _, client in ipairs(info.lsp_clients) do
        if client == criteria.lsp_client then
          has_client = true
          break
        end
      end
      if not has_client then
        match = false
      end
    end

    -- Filter by modified status
    if criteria.modified ~= nil and info.modified ~= criteria.modified then
      match = false
    end

    -- Filter by file existence
    if criteria.file_exists ~= nil and info.file_exists ~= criteria.file_exists then
      match = false
    end

    -- Filter by LSP availability
    if criteria.has_lsp ~= nil and info.has_lsp ~= criteria.has_lsp then
      match = false
    end

    if match then
      matches[filepath] = info
    end
  end

  return matches
end

-- Get loaded files as simple list
function M.get_loaded_files()
  local status = M.get_buffer_status()
  local files = {}

  for filepath, _ in pairs(status) do
    table.insert(files, filepath)
  end

  return files
end

-- Check if a specific file is loaded
function M.is_file_loaded(filepath)
  local bufnr = vim.fn.bufnr(filepath)
  return bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr)
end

-- Get buffer info for a specific file
function M.get_buffer_info(filepath)
  local status = M.get_buffer_status()
  return status[filepath]
end

return M
