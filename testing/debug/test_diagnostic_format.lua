-- Test diagnostic formatting
-- Run this on the file with diagnostics: :source test_diagnostic_format.lua

print("=== Testing Diagnostic Formatting ===")

-- Get diagnostics using our function
local diagnostics = require("mcp-diagnostics.shared.diagnostics")
local current_file = vim.api.nvim_buf_get_name(0)
local result = diagnostics.get_all_diagnostics({current_file}, nil, nil)

print("Number of diagnostics:", #result)

if #result > 0 then
    print("\nFirst diagnostic structure:")
    print(vim.inspect(result[1]))
    
    print("\nChecking format_tool_output logic...")
    local utils = require("mcp-diagnostics.codecompanion.utils")
    
    -- Test the detection logic
    local data = result
    print("Type of data:", type(data))
    print("data[1] exists:", data[1] ~= nil)
    if data[1] then
        print("data[1].message exists:", data[1].message ~= nil)
        print("data[1].filename exists:", data[1].filename ~= nil)
        print("data[1].uri exists:", data[1].uri ~= nil)
        print("data[1].score exists:", data[1].score ~= nil)
    end
    
    -- Test format_diagnostics directly
    print("\nTesting format_diagnostics directly:")
    local formatted = utils.format_diagnostics(result)
    print("Formatted result preview:")
    print(formatted:sub(1, 200) .. "...")
    
    -- Test format_tool_output
    print("\nTesting format_tool_output:")
    local tool_output = utils.format_tool_output(result, "Test Diagnostics")
    print("Tool output preview:")
    print(tool_output:sub(1, 300) .. "...")
else
    print("No diagnostics to test with")
end