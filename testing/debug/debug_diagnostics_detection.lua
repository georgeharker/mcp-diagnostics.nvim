-- Debug script to check diagnostic detection
-- Run this while on the file that has diagnostic errors
-- :source debug_diagnostics_detection.lua

print("=== Diagnostic Detection Debug ===")

-- Get current buffer info
local current_buf = vim.api.nvim_get_current_buf()
local buf_name = vim.api.nvim_buf_get_name(current_buf)
local buf_ft = vim.bo[current_buf].filetype

print("Current buffer:", current_buf)
print("Buffer name:", buf_name)
print("File type:", buf_ft)
print("Buffer loaded:", vim.api.nvim_buf_is_loaded(current_buf))

-- Check LSP clients
local clients = vim.lsp.get_clients({bufnr = current_buf})
print("\nLSP Clients attached to current buffer:")
if #clients > 0 then
    for _, client in ipairs(clients) do
        print("  - " .. client.name .. " (ID: " .. client.id .. ")")
    end
else
    print("  No LSP clients attached to current buffer")
end

-- Check all active LSP clients
local all_clients = vim.lsp.get_clients()
print("\nAll active LSP clients:")
if #all_clients > 0 then
    for _, client in ipairs(all_clients) do
        print("  - " .. client.name .. " (ID: " .. client.id .. ")")
    end
else
    print("  No LSP clients running")
end

-- Check diagnostics for current buffer
print("\n=== Diagnostic Check ===")
local current_diags = vim.diagnostic.get(current_buf)
print("Diagnostics in current buffer:", #current_diags)

if #current_diags > 0 then
    print("Found diagnostics:")
    for i, diag in ipairs(current_diags) do
        print(string.format("  %d. Line %d, Col %d: %s [%s] (%s)", 
            i, diag.lnum + 1, diag.col + 1, diag.message, 
            diag.source or "unknown", 
            vim.diagnostic.severity[diag.severity] or diag.severity))
    end
else
    print("No diagnostics found in current buffer")
end

-- Check all diagnostics
local all_diags = vim.diagnostic.get()
print("\nTotal diagnostics across all buffers:", #all_diags)

-- Test the diagnostic function directly
print("\n=== Testing Diagnostic Function ===")
local diagnostics = require("mcp-diagnostics.shared.diagnostics")
local files = { buf_name }
local result = diagnostics.get_all_diagnostics(files, nil, nil)
print("get_all_diagnostics result:", #result, "diagnostics")

if #result > 0 then
    print("Diagnostics from function:")
    for i, diag in ipairs(result) do
        print(string.format("  %d. %s:%d:%d - %s", 
            i, diag.filename, diag.lnum + 1, diag.col + 1, diag.message))
    end
else
    print("Function returned no diagnostics")
end

-- Check if buffer is found by filename
print("\n=== Buffer Detection Check ===")
local bufnr_by_name = vim.fn.bufnr(buf_name)
print("Buffer number by name lookup:", bufnr_by_name)
print("Is same as current buffer:", bufnr_by_name == current_buf)

print("\n=== Recommendations ===")
print("1. If no LSP clients: Start LSP server (:LspStart or :LspRestart)")
print("2. If no diagnostics but you see errors: Wait for LSP analysis to complete")
print("3. If buffer detection fails: Try saving the file first")
print("4. Manual diagnostic check: :lua =vim.diagnostic.get(0)")