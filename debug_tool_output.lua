-- Debug script to trace tool output
-- Add this to any tool to see what's happening

print("=== DEBUGGING TOOL OUTPUT ===")

-- Mock the tool execution
local utils = require("mcp-diagnostics.codecompanion.utils")
local base = require("mcp-diagnostics.codecompanion.tools.base")

-- Test case 1: Empty symbols result
print("Test 1: Empty symbols")
local empty_result = utils.format_tool_output("lsp_workspace_symbols", "success", "symbols", {}, "No symbols found")
print("  llm_output:", vim.inspect(empty_result.llm_output))
print("  formatted length:", #empty_result.formatted)

-- Test case 2: LLM datatype 
print("\nTest 2: LLM datatype")
local test_data = {message = "test", data = "some data"}
local llm_result = utils.format_tool_output("test_tool", "success", "llm", test_data, "Test completed")
print("  llm_output:", vim.inspect(llm_result.llm_output))
print("  formatted:", llm_result.formatted)

-- Test case 3: Simulate what output handler sees
print("\nTest 3: Simulate output handler")
local mock_stdout = { llm_result }

-- This mimics what the output handler does:
local raw_result = mock_stdout[#mock_stdout]
print("  raw_result has llm_output:", raw_result.llm_output ~= nil)
print("  raw_result has formatted:", raw_result.formatted ~= nil)

if raw_result.llm_output and raw_result.formatted then
    print("  ✅ Output handler should work correctly")
    print("  llm_output would be:", vim.inspect(raw_result.llm_output))
    print("  formatted would be:", raw_result.formatted:sub(1, 100))
else
    print("  ❌ Output handler would fail")
end

print("=== END DEBUG ===")