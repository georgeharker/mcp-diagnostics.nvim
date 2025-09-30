-- Test script to verify extension loading
-- Run this in Neovim with :source test_extension_loading.lua

print("=== Testing MCP-Diagnostics Extension Loading ===")

-- Test 1: Can we require the extension?
local extension_ok, extension = pcall(require, "mcp-diagnostics.codecompanion.extension")
if not extension_ok then
    print("❌ FAILED: Cannot load extension module")
    print("Error:", extension)
    return
end
print("✅ Extension module loaded successfully")

-- Test 2: Can we require the tools catalog?
local catalog_ok, catalog = pcall(require, "mcp-diagnostics.codecompanion.tools_catalog")
if not catalog_ok then
    print("❌ FAILED: Cannot load tools catalog")
    print("Error:", catalog)
    return
end
print("✅ Tools catalog loaded successfully")

-- Test 3: Is debug_test tool in the catalog?
if catalog.debug_test then
    print("✅ debug_test tool found in catalog")
    print("   Description:", catalog.debug_test.description)
else
    print("❌ FAILED: debug_test tool NOT found in catalog")
    print("   Available tools:", vim.inspect(vim.tbl_keys(catalog)))
    return
end

-- Test 4: Can we call the extension setup?
print("\n--- Testing Extension Setup ---")
local setup_ok, setup_err = pcall(extension.setup, {})
if not setup_ok then
    print("❌ FAILED: Extension setup failed")
    print("Error:", setup_err)
    return
end
print("✅ Extension setup completed")

-- Test 5: Check CodeCompanion config
local cc_ok, cc_config = pcall(require, "codecompanion.config")
if not cc_ok then
    print("❌ WARNING: CodeCompanion not available - this is expected in testing")
    print("In real Neovim with CodeCompanion, this should work")
else
    print("✅ CodeCompanion config accessible")
    
    -- Check if our tools are registered
    if cc_config.strategies and cc_config.strategies.chat and cc_config.strategies.chat.tools then
        local tools = cc_config.strategies.chat.tools
        local our_tools = {}
        for name, tool in pairs(tools) do
            if tool.id and tool.id:find("mcp_diagnostics:") then
                table.insert(our_tools, name)
            end
        end
        
        if #our_tools > 0 then
            print("✅ Found registered MCP diagnostic tools:", vim.inspect(our_tools))
        else
            print("❌ No MCP diagnostic tools found in CodeCompanion config")
        end
        
        -- Check for our group
        if tools.groups and tools.groups.mcp_diagnostics then
            print("✅ MCP diagnostics tool group found")
            print("   Group tools:", vim.inspect(tools.groups.mcp_diagnostics.tools))
        else
            print("❌ MCP diagnostics tool group NOT found")
        end
    end
end

print("\n=== Test Complete ===")
print("If all tests pass, the extension should work in CodeCompanion")
print("If tests fail, check the error messages above")