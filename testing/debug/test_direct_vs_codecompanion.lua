-- Test direct tool execution vs CodeCompanion execution
-- Run this: :source test_direct_vs_codecompanion.lua

print("=== Direct vs CodeCompanion Tool Execution Test ===")

-- Get the tool from catalog
local tool_catalog = require("mcp-diagnostics.codecompanion.tools_catalog")
local diagnostic_tool = tool_catalog.lsp_document_diagnostics

-- Test 1: Direct tool execution (what we know works)
print("\n--- Test 1: Direct Tool Execution ---")
local cmd_func = diagnostic_tool.cmds[1]
local direct_result = cmd_func(diagnostic_tool, {}, nil)

print("Direct execution result:")
print("  Type:", type(direct_result))
print("  Status:", direct_result.status)
print("  Data length:", direct_result.data and #direct_result.data or "nil")
if direct_result.data then
    print("  Preview:", direct_result.data:sub(1, 100) .. "...")
end

-- Test 2: Through extension handler (what CodeCompanion uses)
print("\n--- Test 2: Extension Handler Execution ---")

-- Get CodeCompanion config to see the registered handler
local cc_config = require("codecompanion.config")
local registered_tool = cc_config.strategies.chat.tools.lsp_document_diagnostics

if registered_tool and registered_tool.callback and registered_tool.callback.cmds then
    local handler_func = registered_tool.callback.cmds[1]
    
    -- Call the handler like CodeCompanion would
    local handler_result = handler_func(nil, {}, nil, nil)
    
    print("Handler execution result:")
    print("  Type:", type(handler_result))
    print("  Length:", type(handler_result) == "string" and #handler_result or "N/A")
    if type(handler_result) == "string" then
        print("  Preview:", handler_result:sub(1, 100) .. "...")
        
        -- Check if it contains the actual diagnostics
        if handler_result:match("LSP Document Diagnostics:") then
            print("  ✅ Contains diagnostic output")
        else
            print("  ❌ Does NOT contain diagnostic output")
        end
    end
else
    print("❌ Could not find registered tool handler")
end

-- Test 3: Check CodeCompanion version/compatibility
print("\n--- Test 3: CodeCompanion Info ---")
local codecompanion_ok, codecompanion = pcall(require, "codecompanion")
if codecompanion_ok then
    print("CodeCompanion loaded successfully")
    if codecompanion.version then
        print("  Version:", codecompanion.version)
    end
    if codecompanion.has then
        print("  Has function-calling:", codecompanion.has("function-calling"))
    end
else
    print("CodeCompanion not loaded:", codecompanion)
end

print("\n--- Conclusion ---")
print("If handler returns diagnostics but CodeCompanion shows help:")
print("1. CodeCompanion might be treating the response as an error")
print("2. UI issue in displaying long formatted responses")  
print("3. Schema/response format incompatibility")
print("4. CodeCompanion version compatibility issue")