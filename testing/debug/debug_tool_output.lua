-- Debug script to test tool output
local diagnostics = require("mcp-diagnostics.shared.diagnostics")
local utils = require("mcp-diagnostics.codecompanion.utils")

print("=== Testing Diagnostic Functions ===")

-- Test get_diagnostics_by_severity
print("\n1. Testing get_diagnostics_by_severity('error'):")
local error_diagnostics = diagnostics.get_diagnostics_by_severity("error")
print("  Raw result type:", type(error_diagnostics))
print("  Count:", #error_diagnostics)
if #error_diagnostics > 0 then
    print("  First diagnostic:", vim.inspect(error_diagnostics[1]))
end

-- Test format_tool_output with the same data
print("\n2. Testing format_tool_output with error diagnostics:")
local formatted = utils.format_tool_output(error_diagnostics, "Test Diagnostics")
print("  Formatted result type:", type(formatted))
print("  Length:", #formatted)
print("  Preview:", string.sub(formatted, 1, 200))

-- Test get_diagnostic_stats
print("\n3. Testing get_diagnostic_stats:")
local stats = diagnostics.get_diagnostic_stats()
print("  Stats type:", type(stats))
if stats then
    print("  Stats keys:", vim.tbl_keys(stats))
    if stats.summary then
        print("  Total diagnostics:", stats.summary.total)
    end
end

-- Test format_tool_output with stats
print("\n4. Testing format_tool_output with stats:")
local stats_formatted = utils.format_tool_output(stats, "Diagnostic Statistics")
print("  Formatted stats type:", type(stats_formatted))
print("  Length:", #stats_formatted)
print("  Preview:", string.sub(stats_formatted, 1, 200))

print("\n=== Test Complete ===")