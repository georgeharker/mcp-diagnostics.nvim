-- Check tool visibility in CodeCompanion
-- Run this in Neovim: :source check_tool_visibility.lua

print("=== Checking Tool Visibility ===")

local cc_config = require("codecompanion.config")
local tools = cc_config.strategies.chat.tools

print("Checking debug_test tool configuration:")
local debug_tool = tools.debug_test
if debug_tool then
    print("✅ debug_test tool found")
    print("  ID:", debug_tool.id)
    print("  Description:", debug_tool.description)
    print("  Hide in help:", debug_tool.hide_in_help_window)
    print("  Visible:", debug_tool.visible)
    print("  Has callback:", debug_tool.callback ~= nil)
    if debug_tool.callback then
        print("  Callback name:", debug_tool.callback.name)
        print("  Has cmds:", debug_tool.callback.cmds and #debug_tool.callback.cmds > 0)
        print("  Has schema:", debug_tool.callback.schema ~= nil)
    end
else
    print("❌ debug_test tool NOT found")
end

print("\nChecking mcp_diagnostics group:")
local group = tools.groups and tools.groups.mcp_diagnostics
if group then
    print("✅ mcp_diagnostics group found")
    print("  ID:", group.id)
    print("  Hide in help:", group.hide_in_help_window)
    print("  Tools count:", #group.tools)
    print("  Tools:", vim.inspect(group.tools))
else
    print("❌ mcp_diagnostics group NOT found")
    if tools.groups then
        print("Available groups:", vim.inspect(vim.tbl_keys(tools.groups)))
    else
        print("No groups structure found")
    end
end

-- Try to manually call the debug tool
print("\n=== Testing Manual Tool Execution ===")
if debug_tool and debug_tool.callback and debug_tool.callback.cmds then
    local cmd_func = debug_tool.callback.cmds[1]
    if cmd_func then
        print("Attempting to call debug_test manually...")
        local ok, result = pcall(cmd_func, nil, {message = "manual test"}, nil, nil)
        if ok then
            print("✅ Manual execution successful")
            print("Result preview:", tostring(result):sub(1, 100) .. "...")
        else
            print("❌ Manual execution failed:", result)
        end
    end
end

print("\n=== CodeCompanion Tool Access Commands ===")
print("Try these in CodeCompanion chat:")
print("1. Type '@' to see available tools")
print("2. Look for 'mcp_diagnostics' group")
print("3. Try typing '@debug_test' directly")
print("4. Check if tools are in a collapsed group")