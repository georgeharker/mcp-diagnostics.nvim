 -- This is the main interface that coordinates lsp_inquiry and lsp_interact

local config = require("mcp-diagnostics.shared.config")
local lsp_inquiry = require("mcp-diagnostics.shared.lsp_inquiry")
local lsp_interact = require("mcp-diagnostics.shared.lsp_interact")
local M = {}

-- Ensure file is loaded in a buffer and return buffer number
-- Clean implementation - no forced reloads, delegates to lsp_interact
function M.ensure_file_loaded(filepath)
  return lsp_interact.ensure_file_loaded(filepath)
end

-- Batch file loading (delegate to lsp_interact)
function M.ensure_files_loaded(filepaths)
  return lsp_interact.ensure_files_loaded(filepaths)
end

-- LSP notification functions (expose from lsp_interact)
M.notify_lsp_file_closed = lsp_interact.notify_lsp_file_closed
M.notify_lsp_file_changed = lsp_interact.notify_lsp_file_changed
-- For backward compatibility, also expose the versioned interface
M.notify_lsp_file_changed_with_version = lsp_interact.notify_lsp_file_changed_with_version
M.handle_file_deleted = lsp_interact.handle_file_deleted
M.handle_file_changed = lsp_interact.handle_file_changed
M.get_lsp_client_status = lsp_interact.get_lsp_client_status

function M.get_hover_info(file, line, column)
  config.log_debug(string.format("Getting hover info for %s:%d:%d", file, line, column), "[Shared LSP]")

  local bufnr, loaded, err = M.ensure_file_loaded(file)
  if not loaded then
    return nil, err or ("Failed to load file: " .. file)
  end

  return lsp_inquiry.get_hover_info(bufnr, line, column)
end

function M.get_definitions(file, line, column)
  config.log_debug(string.format("Getting definitions for %s:%d:%d", file, line, column), "[Shared LSP]")

  local bufnr, loaded, err = M.ensure_file_loaded(file)
  if not loaded then
    return nil, err or ("Failed to load file: " .. file)
  end

  return lsp_inquiry.get_definitions(bufnr, line, column)
end

function M.get_references(file, line, column)
  config.log_debug(string.format("Getting references for %s:%d:%d", file, line, column), "[Shared LSP]")

  local bufnr, loaded, err = M.ensure_file_loaded(file)
  if not loaded then
    return nil, err or ("Failed to load file: " .. file)
  end

  return lsp_inquiry.get_references(bufnr, line, column)
end

function M.get_document_symbols(file)
  config.log_debug(string.format("Getting document symbols for %s", file), "[Shared LSP]")

  local bufnr, loaded, err = M.ensure_file_loaded(file)
  if not loaded then
    return nil, err or ("Failed to load file: " .. file)
  end

  return lsp_inquiry.get_document_symbols(bufnr)
end

function M.get_workspace_symbols(query)
  return lsp_inquiry.get_workspace_symbols(query)
end

function M.get_code_actions(file, line, column, end_line, end_column)
  config.log_debug(string.format("Getting code actions for %s:%d:%d", file, line, column), "[Shared LSP]")

  local bufnr, loaded, err = M.ensure_file_loaded(file)
  if not loaded then
    return nil, err or ("Failed to load file: " .. file)
  end

  return lsp_inquiry.get_code_actions(bufnr, line, column, end_line, end_column)
end

return M
