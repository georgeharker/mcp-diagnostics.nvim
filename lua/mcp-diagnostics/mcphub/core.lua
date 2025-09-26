-- Core diagnostic and LSP functionality for MCP mcphub integration

local M = {}

-- File watching state for auto-reloading
local file_watchers = {}
local buffer_file_times = {}

-- Utility functions
local function log_debug(msg)
  local config = _G._mcp_diagnostics_mcphub_config or {}
  if config.debug then
    vim.notify("[MCP Diagnostics mcphub] " .. tostring(msg), vim.log.levels.DEBUG)
  end
end

local function severity_to_text(severity)
  local map = {
    [vim.diagnostic.severity.ERROR] = "error",
    [vim.diagnostic.severity.WARN] = "warn",
    [vim.diagnostic.severity.INFO] = "info",
    [vim.diagnostic.severity.HINT] = "hint"
  }
  return map[severity] or "unknown"
end

local function get_buffer_name(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return "[No Name]"
  end
  return name
end

-- File auto-reload functionality
local function get_file_mtime(filepath)
  local stat = vim.loop.fs_stat(filepath)
  return stat and stat.mtime.sec or 0
end

local function setup_file_watcher(filepath, bufnr)
  if file_watchers[filepath] then
    return -- Already watching this file
  end

  log_debug("Setting up file watcher for: " .. filepath)

  -- Store initial modification time
  buffer_file_times[filepath] = get_file_mtime(filepath)

  -- Create file watcher using vim.loop (libuv)
  local watcher = vim.loop.new_fs_event()
  if not watcher then
    log_debug("Failed to create file watcher for: " .. filepath)
    return
  end

  file_watchers[filepath] = watcher

  local function on_file_change(err, _filename, _events)
    if err then
      log_debug("File watcher error for " .. filepath .. ": " .. err)
      return
    end

    -- Check if file actually changed (avoid duplicate events)
    local current_mtime = get_file_mtime(filepath)
    local last_mtime = buffer_file_times[filepath] or 0

    if current_mtime > last_mtime then
      buffer_file_times[filepath] = current_mtime
      log_debug("File changed, reloading buffer: " .. filepath)

      vim.schedule(function()
        -- Check if buffer is still valid and loaded
        if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
          -- Reload the buffer content
          local ok, err_msg = pcall(function()
            vim.api.nvim_buf_call(bufnr, function()
              vim.cmd('edit!')
            end)
          end)

          if ok then
            log_debug("Successfully reloaded buffer: " .. filepath)
            vim.notify("Auto-reloaded: " .. vim.fn.fnamemodify(filepath, ":t"), vim.log.levels.INFO)
          else
            log_debug("Failed to reload buffer " .. filepath .. ": " .. tostring(err_msg))
          end
        else
          -- Buffer is no longer valid, clean up watcher
          M.cleanup_file_watcher(filepath)
        end
      end)
    end
  end

  -- Start watching the file
  local ok, watch_err = pcall(function()
    watcher:start(filepath, {}, on_file_change)
  end)

  if not ok then
    log_debug("Failed to start file watcher for " .. filepath .. ": " .. tostring(watch_err))
    file_watchers[filepath] = nil
    watcher:close()
  else
    log_debug("File watcher started for: " .. filepath)
  end
end

function M.cleanup_file_watcher(filepath)
  local watcher = file_watchers[filepath]
  if watcher then
    watcher:stop()
    watcher:close()
    file_watchers[filepath] = nil
    buffer_file_times[filepath] = nil
    log_debug("Cleaned up file watcher for: " .. filepath)
  end
end

function M.cleanup_all_watchers()
  for _filepath, watcher in pairs(file_watchers) do
    watcher:stop()
    watcher:close()
  end
  file_watchers = {}
  buffer_file_times = {}
  log_debug("Cleaned up all file watchers")
end

-- Core diagnostic functions
function M.get_all_diagnostics(files, severity_filter, source_filter)
  log_debug("Getting diagnostics with filters - files: " .. vim.inspect(files) ..
           ", severity: " .. tostring(severity_filter) .. ", source: " .. tostring(source_filter))

  local all_diagnostics = {}
  local buffers_to_check = {}

  if files and #files > 0 then
    -- Get specific files
    for _, filepath in ipairs(files) do
      local bufnr = vim.fn.bufnr(filepath)
      if bufnr ~= -1 then
        table.insert(buffers_to_check, bufnr)
      end
    end
  else
    -- Get all loaded buffers
    buffers_to_check = vim.api.nvim_list_bufs()
  end

  for _, bufnr in ipairs(buffers_to_check) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local diagnostics = vim.diagnostic.get(bufnr)
      local filename = get_buffer_name(bufnr)

      for _, diag in ipairs(diagnostics) do
        -- Apply filters
        local include = true

        if severity_filter then
          local severity_text = severity_to_text(diag.severity)
          if severity_text ~= severity_filter then
            include = false
          end
        end

        if source_filter and diag.source then
          if not string.find(diag.source, source_filter, 1, true) then
            include = false
          end
        end

        if include then
          table.insert(all_diagnostics, {
            bufnr = bufnr,
            filename = filename,
            lnum = diag.lnum,
            col = diag.col,
            end_lnum = diag.end_lnum,
            end_col = diag.end_col,
            severity = diag.severity,
            severityText = severity_to_text(diag.severity),
            message = diag.message,
            source = diag.source or "",
            code = diag.code or ""
          })
        end
      end
    end
  end

  log_debug("Found " .. #all_diagnostics .. " diagnostics")
  return all_diagnostics
end

function M.get_diagnostic_summary()
  log_debug("Getting diagnostic summary")

  local summary = {
    total = 0,
    errors = 0,
    warnings = 0,
    info = 0,
    hints = 0,
    files = 0,
    byFile = {},
    bySource = {}
  }

  local file_set = {}
  local all_diagnostics = M.get_all_diagnostics()

  for _, diag in ipairs(all_diagnostics) do
    summary.total = summary.total + 1

    -- Count by severity
    if diag.severity == vim.diagnostic.severity.ERROR then
      summary.errors = summary.errors + 1
    elseif diag.severity == vim.diagnostic.severity.WARN then
      summary.warnings = summary.warnings + 1
    elseif diag.severity == vim.diagnostic.severity.INFO then
      summary.info = summary.info + 1
    elseif diag.severity == vim.diagnostic.severity.HINT then
      summary.hints = summary.hints + 1
    end

    -- Count by file
    if not summary.byFile[diag.filename] then
      summary.byFile[diag.filename] = { errors = 0, warnings = 0, info = 0, hints = 0 }
    end

    local file_counts = summary.byFile[diag.filename]
    if diag.severity == vim.diagnostic.severity.ERROR then
      file_counts.errors = file_counts.errors + 1
    elseif diag.severity == vim.diagnostic.severity.WARN then
      file_counts.warnings = file_counts.warnings + 1
    elseif diag.severity == vim.diagnostic.severity.INFO then
      file_counts.info = file_counts.info + 1
    elseif diag.severity == vim.diagnostic.severity.HINT then
      file_counts.hints = file_counts.hints + 1
    end

    -- Count by source
    if diag.source and diag.source ~= "" then
      summary.bySource[diag.source] = (summary.bySource[diag.source] or 0) + 1
    end

    -- Track unique files
    file_set[diag.filename] = true
  end

  summary.files = vim.tbl_count(file_set)
  log_debug("Summary: " .. summary.total .. " total diagnostics across " .. summary.files .. " files")
  return summary
end

-- LSP helper functions
function M.get_lsp_clients_for_buffer(bufnr)
  return vim.lsp.get_clients({ bufnr = bufnr })
end

function M.ensure_buffer_loaded(filepath, enable_auto_reload)
  log_debug("Ensuring buffer loaded: " .. filepath)

  -- Default to auto-reload enabled unless explicitly disabled
  if enable_auto_reload == nil then
    local config = _G._mcp_diagnostics_mcphub_config or {}
    enable_auto_reload = config.auto_reload_files ~= false
  end

  local bufnr = vim.fn.bufnr(filepath)
  if bufnr == -1 then
    -- Buffer doesn't exist, create it
    bufnr = vim.fn.bufnr(filepath, true)
  end

  if not vim.api.nvim_buf_is_loaded(bufnr) then
    -- Load the buffer
    vim.fn.bufload(bufnr)
  end

  -- Set up auto-reload watcher if enabled and file exists
  if enable_auto_reload and vim.fn.filereadable(filepath) == 1 then
    setup_file_watcher(filepath, bufnr)

    -- Set up buffer cleanup when buffer is deleted
    vim.api.nvim_create_autocmd("BufDelete", {
      buffer = bufnr,
      callback = function()
        M.cleanup_file_watcher(filepath)
      end,
      once = true
    })
  end

  local loaded = vim.api.nvim_buf_is_loaded(bufnr)
  log_debug("Buffer " .. filepath .. " loaded: " .. tostring(loaded) ..
           ", auto-reload: " .. tostring(enable_auto_reload))
  return bufnr, loaded
end

function M.get_buffer_status()
  log_debug("Getting buffer status")

  local status = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local name = get_buffer_name(bufnr)
    local is_loaded = vim.api.nvim_buf_is_loaded(bufnr)
    local is_modified = vim.bo[bufnr].modified
    local has_watcher = file_watchers[name] ~= nil

    status[name] = {
      bufnr = bufnr,
      loaded = is_loaded,
      modified = is_modified,
      auto_reload = has_watcher
    }
  end

  return status
end

-- LSP operation functions
function M.get_hover_info(filepath, line, col)
  log_debug(string.format("Getting hover info for %s at %d:%d", filepath, line, col))

  local bufnr, loaded = M.ensure_buffer_loaded(filepath)
  if not loaded then
    return { error = "Could not load buffer: " .. filepath }
  end

  local clients = M.get_lsp_clients_for_buffer(bufnr)
  if #clients == 0 then
    return { error = "No LSP clients attached to buffer" }
  end

  local config = _G._mcp_diagnostics_mcphub_config or {}
  local timeout = config.lsp_timeout or 1000

  local params = vim.lsp.util.make_position_params(0, 'utf-8')
  params.textDocument.uri = vim.uri_from_bufnr(bufnr)
  params.position = { line = line, character = col }

  local results = vim.lsp.buf_request_sync(bufnr, 'textDocument/hover', params, timeout)

  local hover_info = {}
  if results then
    for client_id, result in pairs(results) do
      if result.result and result.result.contents then
        local client = vim.lsp.get_client_by_id(client_id)
        local client_name = client and client.name or "unknown"

        table.insert(hover_info, {
          client = client_name,
          contents = result.result.contents
        })
      end
    end
  end

  log_debug("Found " .. #hover_info .. " hover results")
  return hover_info
end

function M.get_definitions(filepath, line, col)
  log_debug(string.format("Getting definitions for %s at %d:%d", filepath, line, col))

  local bufnr, loaded = M.ensure_buffer_loaded(filepath)
  if not loaded then
    return { error = "Could not load buffer: " .. filepath }
  end

  local clients = M.get_lsp_clients_for_buffer(bufnr)
  if #clients == 0 then
    return { error = "No LSP clients attached to buffer" }
  end

  local config = _G._mcp_diagnostics_mcphub_config or {}
  local timeout = config.lsp_timeout or 1000

  local params = vim.lsp.util.make_position_params(0, 'utf-8')
  params.textDocument.uri = vim.uri_from_bufnr(bufnr)
  params.position = { line = line, character = col }

  local results = vim.lsp.buf_request_sync(bufnr, 'textDocument/definition', params, timeout)

  local definitions = {}
  if results then
    for client_id, result in pairs(results) do
      if result.result then
        local client = vim.lsp.get_client_by_id(client_id)
        local client_name = client and client.name or "unknown"

        local locations = {}
        if vim.islist(result.result) then
          locations = result.result
        else
          locations = { result.result }
        end

        for _, location in ipairs(locations) do
          table.insert(definitions, {
            client = client_name,
            uri = location.uri,
            range = location.range
          })
        end
      end
    end
  end

  log_debug("Found " .. #definitions .. " definitions")
  return definitions
end

function M.get_references(filepath, line, col)
  log_debug(string.format("Getting references for %s at %d:%d", filepath, line, col))

  local bufnr, loaded = M.ensure_buffer_loaded(filepath)
  if not loaded then
    return { error = "Could not load buffer: " .. filepath }
  end

  local clients = M.get_lsp_clients_for_buffer(bufnr)
  if #clients == 0 then
    return { error = "No LSP clients attached to buffer" }
  end

  local config = _G._mcp_diagnostics_mcphub_config or {}
  local timeout = config.lsp_timeout or 1000

  local params = vim.lsp.util.make_position_params(0, 'utf-8')
  params.textDocument.uri = vim.uri_from_bufnr(bufnr)
  params.position = { line = line, character = col }
  ---@class vim.lsp.ReferenceParams
  local reference_params = vim.tbl_extend('force', params, {
    context = { includeDeclaration = true }
  })

  local results = vim.lsp.buf_request_sync(bufnr, 'textDocument/references', reference_params, timeout)

  local references = {}
  if results then
    for client_id, result in pairs(results) do
      if result.result then
        local client = vim.lsp.get_client_by_id(client_id)
        local client_name = client and client.name or "unknown"

        for _, location in ipairs(result.result) do
          table.insert(references, {
            client = client_name,
            uri = location.uri,
            range = location.range
          })
        end
      end
    end
  end

  log_debug("Found " .. #references .. " references")
  return references
end

function M.get_document_symbols(filepath)
  log_debug("Getting document symbols for " .. filepath)

  local bufnr, loaded = M.ensure_buffer_loaded(filepath)
  if not loaded then
    return { error = "Could not load buffer: " .. filepath }
  end

  local clients = M.get_lsp_clients_for_buffer(bufnr)
  if #clients == 0 then
    return { error = "No LSP clients attached to buffer" }
  end

  local config = _G._mcp_diagnostics_mcphub_config or {}
  local timeout = config.lsp_timeout or 1000

  local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
  local results = vim.lsp.buf_request_sync(bufnr, 'textDocument/documentSymbol', params, timeout)

  local symbols = {}
  if results then
    for client_id, result in pairs(results) do
      if result.result then
        local client = vim.lsp.get_client_by_id(client_id)
        local client_name = client and client.name or "unknown"

        table.insert(symbols, {
          client = client_name,
          symbols = result.result
        })
      end
    end
  end

  log_debug("Found symbols from " .. #symbols .. " clients")
  return symbols
end

function M.get_workspace_symbols(query)
  log_debug("Getting workspace symbols with query: " .. (query or ""))

  local params = { query = query or "" }

  -- Get all active LSP clients
  local clients = vim.lsp.get_clients()
  if #clients == 0 then
    return { error = "No LSP clients active" }
  end

  local config = _G._mcp_diagnostics_mcphub_config or {}
  local timeout = config.lsp_timeout or 1000

  local symbols = {}
  for _, client in ipairs(clients) do
    if client.server_capabilities.workspaceSymbolProvider then
      local success, results = pcall(vim.lsp.buf_request_sync, 0, 'workspace/symbol', params, timeout)
      if success and results and results[client.id] and results[client.id].result then
        table.insert(symbols, {
          client = client.name,
          symbols = results[client.id].result
        })
      end
    end
  end

  log_debug("Found workspace symbols from " .. #symbols .. " clients")
  return symbols
end

function M.get_code_actions(filepath, line, col, end_line, end_col)
  log_debug(string.format("Getting code actions for %s at %d:%d", filepath, line, col))

  local bufnr, loaded = M.ensure_buffer_loaded(filepath)
  if not loaded then
    return { error = "Could not load buffer: " .. filepath }
  end

  local clients = M.get_lsp_clients_for_buffer(bufnr)
  if #clients == 0 then
    return { error = "No LSP clients attached to buffer" }
  end

  local config = _G._mcp_diagnostics_mcphub_config or {}
  local timeout = config.lsp_timeout or 1000

  local range = {
    start = { line = line, character = col },
    ["end"] = { line = end_line or line, character = end_col or col }
  }

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    range = range,
    context = {
      diagnostics = vim.diagnostic.get(bufnr, { lnum = line })
    }
  }

  local results = vim.lsp.buf_request_sync(bufnr, 'textDocument/codeAction', params, timeout)

  local actions = {}
  if results then
    for client_id, result in pairs(results) do
      if result.result then
        local client = vim.lsp.get_client_by_id(client_id)
        local client_name = client and client.name or "unknown"

        for _, action in ipairs(result.result) do
          table.insert(actions, {
            client = client_name,
            title = action.title,
            kind = action.kind,
            isPreferred = action.isPreferred,
            edit = action.edit,
            command = action.command
          })
        end
      end
    end
  end

  log_debug("Found " .. #actions .. " code actions")
  return actions
end

return M
