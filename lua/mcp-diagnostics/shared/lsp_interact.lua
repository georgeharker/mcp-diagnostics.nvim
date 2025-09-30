-- LSP interaction and buffer management
-- Handles file loading, LSP notifications, and buffer lifecycle
-- Coordinates with file watcher for change detection

local config = require("mcp-diagnostics.shared.config")

-- LSP Methods and Notifications from protocol
local LSP_METHODS = {
    hover = vim.lsp.protocol.Methods.textDocument_hover,
    definition = vim.lsp.protocol.Methods.textDocument_definition,
    references = vim.lsp.protocol.Methods.textDocument_references,
    document_symbols = vim.lsp.protocol.Methods.textDocument_documentSymbol,
    code_actions = vim.lsp.protocol.Methods.textDocument_codeAction,
    did_open = vim.lsp.protocol.Methods.textDocument_didOpen,
    did_close = vim.lsp.protocol.Methods.textDocument_didClose,
    did_change = vim.lsp.protocol.Methods.textDocument_didChange,
}

local M = {}

local file_states = {}

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
         config.log_debug(string.format("Buffer %d (%s) made fully visible by user action", bufnr, filepath), "[LSP Interact]")
       end
     end,
     desc = "Make hidden buffer fully visible when user edits it"
   })
 end

local function get_lsp_clients(bufnr)
    return vim.lsp.get_clients({ bufnr = bufnr })
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

      client.notify(LSP_METHODS.did_open, {
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

      client.notify(LSP_METHODS.did_close, {
        textDocument = {
          uri = state.uri
        }
      })
    end
  end

  file_states[filepath] = nil
end

function M.notify_lsp_file_changed(filepath, bufnr)
  -- Modern implementation: automatically gets changedtick for proper LSP version sync
  local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)
  return M.notify_lsp_file_changed_with_version(filepath, bufnr, changedtick)
end

-- Internal implementation with explicit version - used by notify_lsp_file_changed and unified_refresh
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

      client.notify(LSP_METHODS.did_change, {
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

function M.ensure_file_loaded(filepath)
  config.log_debug(string.format("Ensuring file loaded: %s", filepath), "[LSP Interact]")

  -- Check if file exists
  if vim.fn.filereadable(filepath) ~= 1 then
    config.log_error(string.format("File not readable: %s", filepath), "[LSP Interact]")
    return nil, false, "File not readable"
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

    config.log_debug(string.format("Created unlisted buffer %d for file: %s", bufnr, filepath), "[LSP Interact]")
  else
    -- Buffer exists - reuse it
    config.log_debug(string.format("Reusing existing buffer %d for file: %s", bufnr, filepath), "[LSP Interact]")
  end

  -- Load buffer if not loaded (but don't force reload)
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    vim.fn.bufload(bufnr)

    -- Notify LSP of file opening (only for newly loaded buffers)
    vim.schedule(function()
      notify_lsp_file_opened(filepath, bufnr)
    end)
  elseif buffer_created then
    -- Even if buffer was loaded, notify LSP if we just created it
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

  local deletion_mode = config.get_file_deletion_mode()
  local bufnr = vim.fn.bufnr(filepath)

  if bufnr ~= -1 and vim.api.nvim_buf_is_valid(bufnr) then
    -- Notify LSP that file is closed
    M.notify_lsp_file_closed(filepath, bufnr)

    -- Handle buffer deletion based on configured mode
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        local filename = vim.fn.fnamemodify(filepath, ":t")

        if deletion_mode == "ignore" then
          -- Do nothing, just disconnect LSP
          config.log_debug(string.format("File deleted (ignored): %s", filename), "[LSP Interact]")

        elseif deletion_mode == "prompt" then
          -- Prompt user for action
          vim.notify(string.format("File deleted: %s", filename), vim.log.levels.WARN)
          local choice = vim.fn.confirm(
            string.format("File '%s' was deleted. Close the buffer?", filename),
            "&Yes\n&No\n&Keep for now",
            2 -- Default to No
          )

          if choice == 1 then -- Yes
            vim.api.nvim_buf_delete(bufnr, { force = false })
            config.log_info(string.format("Buffer closed for deleted file: %s", filename), "[LSP Interact]")
          elseif choice == 3 then -- Keep for now
            vim.notify(string.format("Keeping buffer for deleted file: %s", filename), vim.log.levels.INFO)
          end

        elseif deletion_mode == "auto" then
          -- Automatically close buffer
          vim.notify(string.format("File deleted, closing buffer: %s", filename), vim.log.levels.WARN)
          vim.api.nvim_buf_delete(bufnr, { force = false })
          config.log_info(string.format("Auto-closed buffer for deleted file: %s", filename), "[LSP Interact]")
        end
      end
    end)
  else
    config.log_debug(string.format("No buffer found for deleted file: %s", filepath), "[LSP Interact]")
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
      supports_hover = client.supports_method(LSP_METHODS.hover),
      supports_definition = client.supports_method(LSP_METHODS.definition),
      supports_references = client.supports_method(LSP_METHODS.references),
      supports_document_symbols = client.supports_method(LSP_METHODS.document_symbols),
      supports_code_actions = client.supports_method(LSP_METHODS.code_actions),
    })
  end

  return status
end

return M
