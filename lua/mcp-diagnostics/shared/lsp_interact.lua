-- LSP interaction and buffer management
-- Handles file loading, LSP notifications, and buffer lifecycle
-- Coordinates with file watcher for change detection

local config = require("mcp-diagnostics.shared.config")
local M = {}

-- Track LSP file states for proper notifications
local file_states = {}

-- Helper function to get LSP clients for a buffer
local function get_lsp_clients(bufnr)
  if vim.lsp.get_clients then
    -- Neovim 0.10+
    return vim.lsp.get_clients({ bufnr = bufnr })
  else
    -- Neovim 0.9 and earlier
    return vim.lsp.get_active_clients({ bufnr = bufnr })
  end
end

-- LSP Protocol Notifications
local function notify_lsp_file_opened(filepath, bufnr)
  local mode = config.get_lsp_notify_mode()
  if mode == "disabled" then
    return
  end

  local clients = get_lsp_clients(bufnr)
  if #clients == 0 then
    return
  end

  local uri = vim.uri_from_fname(filepath)
  local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n')

  -- Get file language ID
  local language_id = vim.bo[bufnr].filetype or 'text'

  for _, client in ipairs(clients) do
    if client.server_capabilities.textDocumentSync then
      config.log_debug(string.format("Notifying LSP client %s that file opened: %s", client.name, filepath), "[LSP Interact]")

      client.notify('textDocument/didOpen', {
        textDocument = {
          uri = uri,
          languageId = language_id,
          version = 0,
          text = content
        }
      })
    end
  end

  file_states[filepath] = {
    uri = uri,
    version = 0,
    opened = true,
    bufnr = bufnr,
    last_changedtick = vim.api.nvim_buf_get_changedtick(bufnr)
  }
end

function M.notify_lsp_file_closed(filepath, bufnr)
  local mode = config.get_lsp_notify_mode()
  if mode == "disabled" then
    return
  end

  local clients = get_lsp_clients(bufnr or file_states[filepath] and file_states[filepath].bufnr)
  if #clients == 0 then
    return
  end

  local state = file_states[filepath]
  if not state or not state.opened then
    return
  end

  for _, client in ipairs(clients) do
    if client.server_capabilities.textDocumentSync then
      config.log_debug(string.format("Notifying LSP client %s that file closed: %s", client.name, filepath), "[LSP Interact]")

      client.notify('textDocument/didClose', {
        textDocument = {
          uri = state.uri
        }
      })
    end
  end

  file_states[filepath] = nil
end

function M.notify_lsp_file_changed(filepath, bufnr)
  local mode = config.get_lsp_notify_mode()
  if mode == "disabled" then
    return
  end

  local clients = get_lsp_clients(bufnr)
  if #clients == 0 then
    return
  end

  local state = file_states[filepath]
  if not state or not state.opened then
    -- File not registered as opened, do a full open
    notify_lsp_file_opened(filepath, bufnr)
    return
  end

  state.version = state.version + 1
  local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n')

  for _, client in ipairs(clients) do
    if client.server_capabilities.textDocumentSync then
      config.log_debug(string.format("Notifying LSP client %s that file changed: %s (v%d)", client.name, filepath, state.version), "[LSP Interact]")

      client.notify('textDocument/didChange', {
        textDocument = {
          uri = state.uri,
          version = state.version
        },
        contentChanges = {
          {
            text = content
          }
        }
      })
    end
  end
end

-- Clean buffer creation - no forced reloads
function M.ensure_file_loaded(filepath)
  config.log_debug(string.format("Ensuring file loaded: %s", filepath), "[LSP Interact]")

  -- Check if file exists
  if vim.fn.filereadable(filepath) ~= 1 then
    config.log_error(string.format("File not readable: %s", filepath), "[LSP Interact]")
    return nil, false, "File not readable"
  end

  local bufnr = vim.fn.bufnr(filepath)
  if bufnr == -1 then
    -- Buffer doesn't exist, create it
    bufnr = vim.fn.bufnr(filepath, true)
  else
    -- Check if buffer exists
  end

  -- Load buffer if not loaded (but don't force reload)
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    vim.fn.bufload(bufnr)

    -- Notify LSP of file opening
    vim.schedule(function()
      notify_lsp_file_opened(filepath, bufnr)
    end)
  end

  local loaded = vim.api.nvim_buf_is_loaded(bufnr)

  -- Set up file watcher if auto-reload is enabled
  if loaded and config.is_feature_enabled('auto_reload_files') then
    local file_watcher = require("mcp-diagnostics.shared.file_watcher")
    file_watcher.setup_watcher(filepath, bufnr, "[LSP Interact]")
  end

  return bufnr, loaded, nil
end

-- Batch file loading
function M.ensure_files_loaded(filepaths)
  local results = {}

  for _, filepath in ipairs(filepaths) do
    local bufnr, loaded, error_msg = M.ensure_file_loaded(filepath)
    table.insert(results, {
      filepath = filepath,
      bufnr = bufnr,
      loaded = loaded,
      error = error_msg
    })
  end

  return {
    results = results,
    total_files = #filepaths,
    successfully_loaded = vim.tbl_count(vim.tbl_filter(function(r) return r.loaded end, results))
  }
end

-- Handle file deletions - called by file watcher
function M.handle_file_deleted(filepath)
  config.log_info(string.format("Handling deleted file: %s", filepath), "[LSP Interact]")

  local bufnr = vim.fn.bufnr(filepath)
  if bufnr ~= -1 and vim.api.nvim_buf_is_valid(bufnr) then
    -- Notify LSP that file is closed
    M.notify_lsp_file_closed(filepath, bufnr)

    -- Optionally delete the buffer (based on config)
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        -- Could add config option for this behavior
        vim.notify(string.format("File deleted: %s", vim.fn.fnamemodify(filepath, ":t")), vim.log.levels.WARN)
        -- vim.api.nvim_buf_delete(bufnr, { force = true })
      end
    end)
  end

  -- Clean up our state
  file_states[filepath] = nil
end

-- Handle file changes - called by file watcher
function M.handle_file_changed(filepath, bufnr)
  config.log_debug(string.format("Handling file change: %s", filepath), "[LSP Interact]")

  -- Always notify LSP of changes (they can decide how to handle it)
  M.notify_lsp_file_changed(filepath, bufnr)

  -- Buffer reloading is handled by file watcher based on auto_reload_mode
  -- This separation keeps concerns clean
end

-- Get file states for debugging/monitoring
function M.get_file_states()
  return vim.tbl_map(function(state)
    return {
      uri = state.uri,
      version = state.version,
      opened = state.opened,
      bufnr = state.bufnr
    }
  end, file_states)
end

-- Clean up all LSP notifications (for shutdown)
function M.cleanup_all_lsp_notifications()
  for filepath, state in pairs(file_states) do
    if state.opened and state.bufnr then
      M.notify_lsp_file_closed(filepath, state.bufnr)
    end
  end
  file_states = {}
end

-- Get LSP client status for a buffer
function M.get_lsp_client_status(bufnr)
  local clients = get_lsp_clients(bufnr)
  local status = {}

  for _, client in ipairs(clients) do
    table.insert(status, {
      id = client.id,
      name = client.name,
      attached_buffers = #client.attached_buffers or 0,
      supports_hover = client.supports_method("textDocument/hover"),
      supports_definition = client.supports_method("textDocument/definition"),
      supports_references = client.supports_method("textDocument/references"),
      supports_document_symbols = client.supports_method("textDocument/documentSymbol"),
      supports_code_actions = client.supports_method("textDocument/codeAction"),
    })
  end

  return status
end

-- LSP notification that uses Neovim's actual version (no more sync issues!)
function M.notify_lsp_file_changed_with_version(filepath, bufnr, version)
  local mode = config.get_lsp_notify_mode()
  if mode == "disabled" then
    return
  end

  local clients = get_lsp_clients(bufnr)
  if #clients == 0 then
    return
  end

  local state = file_states[filepath]
  if not state or not state.opened then
    -- File not registered, do a full open
    notify_lsp_file_opened(filepath, bufnr)
    return
  end

  -- KEY: Use Neovim's actual version instead of our own counter
  state.version = version
  state.last_changedtick = version
  local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n')

  for _, client in ipairs(clients) do
    if client.server_capabilities.textDocumentSync then
      config.log_debug(string.format("Notifying LSP client %s: %s (v%d=changedtick)", client.name, filepath, version), "[LSP Interact]")

      client.notify('textDocument/didChange', {
        textDocument = {
          uri = state.uri,
          version = version
        },
        contentChanges = {
          {
            text = content
          }
        }
      })
    end
  end
end

return M
