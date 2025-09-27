-- Core diagnostic and LSP functionality for MCP mcphub integration
-- This module provides backward compatibility by delegating to shared components

local M = {}
local config = require("mcp-diagnostics.shared.config")
local diagnostics = require("mcp-diagnostics.shared.diagnostics")
local lsp = require("mcp-diagnostics.shared.lsp")
local buffers = require("mcp-diagnostics.shared.buffers")
local file_watcher = require("mcp-diagnostics.shared.file_watcher")

-- Diagnostic functions - delegate to shared
function M.get_all_diagnostics(files, severity, source)
  return diagnostics.get_all_diagnostics(files, severity, source)
end

function M.get_diagnostic_summary()
  return diagnostics.get_diagnostic_summary()
end

function M.filter_diagnostics(diag_list, severity, source)
  return diagnostics.filter_diagnostics(diag_list, severity, source)
end

function M.get_diagnostics_by_severity(severity_text)
  return diagnostics.get_diagnostics_by_severity(severity_text)
end

function M.get_problematic_files(limit)
  return diagnostics.get_problematic_files(limit)
end

-- LSP functions - delegate to shared  
function M.get_hover_info(file, line, column)
  return lsp.get_hover_info(file, line, column)
end

function M.get_definitions(file, line, column)
  return lsp.get_definitions(file, line, column)
end

function M.get_references(file, line, column)
  return lsp.get_references(file, line, column)
end

function M.get_document_symbols(file)
  return lsp.get_document_symbols(file)
end

function M.get_workspace_symbols(query)
  return lsp.get_workspace_symbols(query)
end

function M.get_code_actions(file, line, column, end_line, end_column)
  return lsp.get_code_actions(file, line, column, end_line, end_column)
end

-- Buffer functions - delegate to shared
function M.get_buffer_status()
  return buffers.get_buffer_status()
end

function M.ensure_buffer_loaded(filepath, enable_auto_reload)
  return buffers.ensure_buffer_loaded(filepath, enable_auto_reload)
end

function M.get_buffer_statistics()
  return buffers.get_buffer_statistics()
end

function M.find_buffers(criteria)
  return buffers.find_buffers(criteria)
end

function M.get_loaded_files()
  return buffers.get_loaded_files()
end

function M.is_file_loaded(filepath)
  return buffers.is_file_loaded(filepath)
end

-- File watcher functions - delegate to shared
function M.cleanup_file_watcher(filepath)
  return file_watcher.cleanup_watcher(filepath)
end

function M.cleanup_all_watchers()
  return file_watcher.cleanup_all_watchers()
end

function M.get_watcher_status()
  return file_watcher.get_watcher_status()
end

function M.is_watching(filepath)
  return file_watcher.is_watching(filepath)
end

function M.get_watcher_count()
  return file_watcher.get_watcher_count()
end

-- Backward compatibility for old function names (if any tools still use them)
M.get_all_diagnostics_filtered = M.get_all_diagnostics
M.get_diagnostic_stats = diagnostics.get_diagnostic_stats

-- Utility functions using shared config
function M.log_debug(message)
  config.log_debug(message, "[MCP Diagnostics mcphub]")
end

function M.log_info(message)
  config.log_info(message, "[MCP Diagnostics mcphub]")
end

function M.log_error(message)
  config.log_error(message, "[MCP Diagnostics mcphub]")
end

return M