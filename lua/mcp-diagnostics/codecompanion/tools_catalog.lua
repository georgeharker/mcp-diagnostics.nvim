-- LSP Tools Catalog for CodeCompanion Integration
-- These tools provide direct LSP access following CodeCompanion's tool format

-- Import tool modules from subdirectories
local diagnostics_tools = require("mcp-diagnostics.codecompanion.tools.diagnostics")
local lsp_navigation_tools = require("mcp-diagnostics.codecompanion.tools.lsp_navigation")
local symbols_tools = require("mcp-diagnostics.codecompanion.tools.symbols")
local code_actions_tools = require("mcp-diagnostics.codecompanion.tools.code_actions")
local buffers_tools = require("mcp-diagnostics.codecompanion.tools.buffers")

local M = {}

-- Diagnostic Tools
M.lsp_document_diagnostics = diagnostics_tools.lsp_document_diagnostics
M.lsp_workspace_diagnostics = diagnostics_tools.lsp_workspace_diagnostics
M.lsp_diagnostics_summary = diagnostics_tools.lsp_diagnostics_summary
M.diagnostic_hotspots = diagnostics_tools.diagnostic_hotspots
M.diagnostic_stats = diagnostics_tools.diagnostic_stats
M.diagnostic_by_severity = diagnostics_tools.diagnostic_by_severity

-- LSP Navigation Tools
M.lsp_hover = lsp_navigation_tools.lsp_hover
M.lsp_definition = lsp_navigation_tools.lsp_definition
M.lsp_references = lsp_navigation_tools.lsp_references

-- Symbol Tools
M.lsp_document_symbols = symbols_tools.lsp_document_symbols
M.lsp_workspace_symbols = symbols_tools.lsp_workspace_symbols

-- Code Actions Tools
M.lsp_code_actions = code_actions_tools.lsp_code_actions

-- Buffer Management Tools
M.buffer_status = buffers_tools.buffer_status
M.ensure_files_loaded = buffers_tools.ensure_files_loaded
M.refresh_after_external_changes = buffers_tools.refresh_after_external_changes

-- Debug Tools (for troubleshooting)
local debug_tools = require("mcp-diagnostics.codecompanion.tools.debug_test")
M.debug_test = debug_tools.debug_test

return M

