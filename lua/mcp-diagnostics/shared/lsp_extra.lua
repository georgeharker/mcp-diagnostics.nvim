 -- Uses the new lsp_inquiry and lsp_interact architecture

local lsp_inquiry = require("mcp-diagnostics.shared.lsp_inquiry")
local lsp_interact = require("mcp-diagnostics.shared.lsp_interact")
local file_watcher = require("mcp-diagnostics.shared.file_watcher")
local unified_refresh = require("mcp-diagnostics.shared.unified_refresh")
local M = {}

function M.ensure_files_loaded(filepaths, options)
  options = options or {}

  -- Handle reload_mode if provided
  if options.reload_mode then
    -- For now, if reload_mode is "reload", force refresh files first
    if options.reload_mode == "reload" then
      -- Refresh any stale files before loading
      file_watcher.refresh_all_watched_files()
    end
    -- reload_mode "ask" and "none" are handled by the file watcher system automatically
  end

  return lsp_interact.ensure_files_loaded(filepaths)
end

function M.ensure_file_loaded(filepath)
  return lsp_interact.ensure_file_loaded(filepath)
end

-- Handle file deletions (delegates to lsp_interact)
function M.handle_file_deleted(filepath)
  return lsp_interact.handle_file_deleted(filepath)
end

function M.analyze_symbol_comprehensive(filepath, line, column)
  local bufnr, loaded, err = M.ensure_file_loaded(filepath)
  if not loaded then
    return { error = err or ("Could not load file: " .. filepath) }
  end

  local analysis = {
    filepath = filepath,
    line = line,
    column = column,
    hover_info = nil,
    definitions = nil,
    references = nil,
    document_symbols = nil
  }

  -- Chain LSP operations using lsp_inquiry
  analysis.hover_info = lsp_inquiry.get_hover_info(bufnr, line, column)
  analysis.definitions = lsp_inquiry.get_definitions(bufnr, line, column)
  analysis.references = lsp_inquiry.get_references(bufnr, line, column)
  analysis.document_symbols = lsp_inquiry.get_document_symbols(bufnr)

  return analysis
end

function M.analyze_diagnostic_context(filepath, diagnostic)
  local bufnr, loaded, err = M.ensure_file_loaded(filepath)
  if not loaded then
    return { error = err or ("Could not load file: " .. filepath) }
  end

  local analysis = {
    filepath = filepath,
    diagnostic = diagnostic,
    symbol_analysis = nil,
    code_actions = nil,
    related_diagnostics = nil
  }

  -- Analyze the symbol at diagnostic location
  if diagnostic.lnum and diagnostic.col then
    analysis.symbol_analysis = M.analyze_symbol_comprehensive(filepath, diagnostic.lnum, diagnostic.col)
  end

  -- Get code actions for the diagnostic
  if diagnostic.lnum and diagnostic.col then
    analysis.code_actions = lsp_inquiry.get_code_actions(bufnr, diagnostic.lnum, diagnostic.col)
  end

  -- Find related diagnostics (same symbol, same source, etc.)
  local diagnostics_mod = require("mcp-diagnostics.shared.diagnostics")
  local all_diags = diagnostics_mod.get_all_diagnostics({filepath})

  analysis.related_diagnostics = vim.tbl_filter(function(diag)
    return diag ~= diagnostic and (
      diag.source == diagnostic.source or
      diag.code == diagnostic.code or
      (math.abs(diag.lnum - diagnostic.lnum) <= 2) -- nearby lines
    )
  end, all_diags)

  return analysis
end

-- Correlation: Group related diagnostics across files
function M.correlate_diagnostics()
  local diagnostics_mod = require("mcp-diagnostics.shared.diagnostics")
  local all_diags = diagnostics_mod.get_all_diagnostics()

  local correlations = {
    by_symbol = {},
    by_message = {},
    by_code = {},
    cascading_potential = {}
  }

  -- Group by symbol name (extracted from messages)
  for _, diag in ipairs(all_diags) do
    -- Simple symbol extraction (this could be enhanced)
    local symbol = diag.message:match("'([^']+)'") or diag.message:match("`([^`]+)`")
    if symbol then
      correlations.by_symbol[symbol] = correlations.by_symbol[symbol] or {}
      table.insert(correlations.by_symbol[symbol], diag)
    end

    -- Group by exact message
    correlations.by_message[diag.message] = correlations.by_message[diag.message] or {}
    table.insert(correlations.by_message[diag.message], diag)

    -- Group by diagnostic code
    if diag.code then
      correlations.by_code[diag.code] = correlations.by_code[diag.code] or {}
      table.insert(correlations.by_code[diag.code], diag)
    end
  end

  -- Identify potential cascading fixes
  for symbol, diags in pairs(correlations.by_symbol) do
    if #diags > 1 then
      -- Check if any diagnostic has available code actions
      local actions -- Declare actions at proper scope
      for _, diag in ipairs(diags) do
        if diag.filename and diag.lnum and diag.col then
          -- Ensure file is loaded first
          local bufnr, loaded = M.ensure_file_loaded(diag.filename)
          if loaded then
            actions = lsp_inquiry.get_code_actions(bufnr, diag.lnum, diag.col)
          end
          if actions and #actions > 0 then
            correlations.cascading_potential[symbol] = {
              diagnostics = diags,
              fix_location = { file = diag.filename, line = diag.lnum, col = diag.col },
              available_actions = actions
            }
            break
          end
        end
      end
    end
  end

  return correlations
end

function M.get_file_states()
  return lsp_interact.get_file_states()
end

function M.cleanup_all_lsp_notifications()
  return lsp_interact.cleanup_all_lsp_notifications()
end

-- Enhanced file watcher functions (added based on session analysis)
function M.refresh_after_external_changes()
  return file_watcher.refresh_all_watched_files()
end

-- Wait for diagnostic changes after file modifications
function M.wait_for_diagnostic_update(files, max_wait_ms, poll_interval_ms)
  max_wait_ms = max_wait_ms or 5000  -- 5 second default
  poll_interval_ms = poll_interval_ms or 100  -- 100ms polling
  files = files or {}

  local start_time = vim.loop.now()
  local initial_diagnostics = {}

  -- Capture initial diagnostic state
  for _, file in ipairs(files) do
    local bufnr = vim.fn.bufnr(file)
    if bufnr ~= -1 then
      initial_diagnostics[file] = vim.diagnostic.get(bufnr)
    end
  end

  -- Poll for changes
  while (vim.loop.now() - start_time) < max_wait_ms do
    local has_changed = false

    for _, file in ipairs(files) do
      local bufnr = vim.fn.bufnr(file)
      if bufnr ~= -1 then
        local current_diagnostics = vim.diagnostic.get(bufnr)
        local initial = initial_diagnostics[file] or {}

        -- Compare diagnostic counts as a simple change indicator
        if #current_diagnostics ~= #initial then
          has_changed = true
          break
        end
      end
    end

    if has_changed then
      return {
        success = true,
        wait_time_ms = vim.loop.now() - start_time,
        message = "Diagnostics updated"
      }
    end

    vim.wait(poll_interval_ms)
  end

  return {
    success = false,
    wait_time_ms = max_wait_ms,
    message = "Timeout waiting for diagnostic update"
  }
end

-- Enhanced refresh with diagnostic monitoring
function M.refresh_and_wait_for_update(files, max_wait_ms)
  local refresh_result = M.refresh_after_external_changes()
  local wait_result = M.wait_for_diagnostic_update(files, max_wait_ms)

  return {
    refresh_result = refresh_result,
    wait_result = wait_result,
    success = refresh_result.success and wait_result.success
  }
end

-- Wait for LSP clients to be ready after file operations
function M.wait_for_lsp_ready(files, max_wait_ms)
  max_wait_ms = max_wait_ms or 3000  -- 3 second default
  local start_time = vim.loop.now()

  while (vim.loop.now() - start_time) < max_wait_ms do
    local all_ready = true

    for _, file in ipairs(files or {}) do
      local bufnr = vim.fn.bufnr(file)
      if bufnr ~= -1 then
        local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
        local has_active_client = false

        for _, client in ipairs(clients) do
          if client.server_capabilities and client.server_capabilities.diagnosticProvider then
            has_active_client = true
            break
          end
        end

        if not has_active_client then
          all_ready = false
          break
        end
      end
    end

    if all_ready then
      return {
        success = true,
        wait_time_ms = vim.loop.now() - start_time,
        message = "LSP clients ready"
      }
    end

    vim.wait(50)  -- Short poll interval for LSP readiness
  end

  return {
    success = false,
    wait_time_ms = max_wait_ms,
    message = "Timeout waiting for LSP clients"
  }
end

function M.smart_refresh_and_wait(files, options)
  options = options or {}
  local max_wait_ms = options.max_wait_ms or 5000

  -- Step 1: Use unified refresh system for perfect LSP sync
  local refresh_result
  if files and #files > 0 then
    refresh_result = unified_refresh.unified_batch_refresh(files)
  else
    -- Fallback to old file watcher method if no specific files provided
    refresh_result = { success = true, results = M.refresh_after_external_changes() }
  end

  -- Step 2: Wait for LSP clients to be ready
  local lsp_ready_result = M.wait_for_lsp_ready(files, max_wait_ms / 2)

  -- Step 3: Wait for diagnostic updates
  local diagnostic_update_result = M.wait_for_diagnostic_update(files, max_wait_ms / 2)

  return {
    refresh_result = refresh_result,
    lsp_ready_result = lsp_ready_result,
    diagnostic_update_result = diagnostic_update_result,
    success = refresh_result.success and lsp_ready_result.success,
    total_wait_time_ms = (lsp_ready_result.wait_time_ms or 0) + (diagnostic_update_result.wait_time_ms or 0)
  }
end
function M.check_all_files_staleness()
  return file_watcher.check_all_files_staleness()
end

return M
