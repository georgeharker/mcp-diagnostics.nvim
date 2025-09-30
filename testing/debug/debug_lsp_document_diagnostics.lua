-- Debug script to examine lsp_document_diagnostics tool output

print("=== Testing lsp_document_diagnostics tool output ===")

-- First, ensure we have diagnostics to work with
vim.cmd("edit test_errors.lua")

-- Wait for LSP to analyze the file
vim.wait(2000, function()
    local diagnostics = vim.diagnostic.get(vim.api.nvim_get_current_buf())
    return #diagnostics > 0
end)

-- Check if we have diagnostics
local current_buf = vim.api.nvim_get_current_buf()
local diagnostics = vim.diagnostic.get(current_buf)
print("Current buffer:", current_buf)
print("File:", vim.api.nvim_buf_get_name(current_buf))
print("Diagnostics found:", #diagnostics)

if #diagnostics > 0 then
    print("\n=== Raw vim.diagnostic.get() output ===")
    for i, diag in ipairs(diagnostics) do
        print(string.format("Diagnostic %d:", i))
        print("  Message:", diag.message)
        print("  Severity:", diag.severity)
        print("  Source:", diag.source or "unknown")
        print("  Line:", diag.lnum)
        print("  Col:", diag.col)
        print("  End Line:", diag.end_lnum)
        print("  End Col:", diag.end_col)
        print()
    end
else
    print("No diagnostics found - checking LSP status...")

    -- Check LSP clients
    local function get_lsp_clients(bufnr)
            return vim.lsp.get_clients({ bufnr = bufnr })
    end

    local clients = get_lsp_clients(current_buf)
    print("LSP clients attached:", #clients)

    for i, client in ipairs(clients) do
        print(string.format("  %d: %s (id: %d)", i, client.name, client.id))
    end
end

-- Now test the actual lsp_document_diagnostics tool
print("\n=== Testing lsp_document_diagnostics tool ===")

-- Load the tool
local ok, tool_module = pcall(require, "mcp-diagnostics.codecompanion.tools.diagnostics")
if not ok then
    print("Error loading tool module:", tool_module)
    return
end

-- Get the tool
local tool = tool_module.lsp_document_diagnostics
if not tool then
    print("lsp_document_diagnostics tool not found!")
    return
end

-- Test with no arguments
print("\n--- Test 1: No arguments ---")
local result1 = tool.cmds[1](tool, {})
print("Result type:", type(result1))
print("Result:", vim.inspect(result1))

-- Test with severity filter
print("\n--- Test 2: With severity='error' ---")
local result2 = tool.cmds[1](tool, { severity = "error" })
print("Result type:", type(result2))
print("Result:", vim.inspect(result2))

-- Test with specific file
print("\n--- Test 3: With specific file ---")
local result3 = tool.cmds[1](tool, { file = "test_errors.lua" })
print("Result type:", type(result3))
print("Result:", vim.inspect(result3))

-- Test the shared diagnostics module directly
print("\n=== Testing shared diagnostics module directly ===")
local shared_diagnostics = require("mcp-diagnostics.shared.diagnostics")

print("\n--- get_all_diagnostics() ---")
local all_diags = shared_diagnostics.get_all_diagnostics({"test_errors.lua"})
print("All diagnostics:", vim.inspect(all_diags))

print("\n--- get_diagnostic_summary() ---")
local summary = shared_diagnostics.get_diagnostic_summary()
print("Diagnostic summary:", vim.inspect(summary))

print("\n=== Test complete ===")
