-- Debug CodeCompanion context vs direct execution
-- Run this: :source debug_codecompanion_context.lua

print("=== CodeCompanion Context Debug ===")

-- Test the diagnostic tool directly like CodeCompanion would
local tool_catalog = require("mcp-diagnostics.codecompanion.tools_catalog")
local diagnostic_tool = tool_catalog.lsp_document_diagnostics

if not diagnostic_tool then
    print("❌ Could not find lsp_document_diagnostics tool")
    return
end

print("✅ Found diagnostic tool")

-- Get current buffer info (what CodeCompanion sees)
local current_buf = vim.api.nvim_get_current_buf()
local buf_name = vim.api.nvim_buf_get_name(current_buf)
local buf_type = vim.api.nvim_buf_get_option(current_buf, "buftype")
local buf_filetype = vim.api.nvim_buf_get_option(current_buf, "filetype")

print("Current CodeCompanion context:")
print("  Buffer:", current_buf)
print("  Buffer name:", buf_name)
print("  Buffer type:", buf_type)
print("  File type:", buf_filetype)

-- Check if we're in a CodeCompanion buffer
if buf_filetype == "codecompanion" or buf_type == "nofile" then
    print("⚠️  We're in a CodeCompanion chat buffer!")
    print("The tool needs to find a file buffer to analyze...")
    
    -- List all buffers to see what's available
    local buffers = vim.api.nvim_list_bufs()
    print("\nAll available buffers:")
    for _, bufnr in ipairs(buffers) do
        if vim.api.nvim_buf_is_loaded(bufnr) then
            local name = vim.api.nvim_buf_get_name(bufnr)
            local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
            local bt = vim.api.nvim_buf_get_option(bufnr, "buftype")
            print(string.format("  Buffer %d: %s (ft:%s, bt:%s)", bufnr, name, ft, bt))
        end
    end
end

-- Now test the tool execution as CodeCompanion would
print("\n=== Testing Tool Execution ===")
local cmd_func = diagnostic_tool.cmds[1]
if cmd_func then
    print("Calling tool with empty args (like CodeCompanion)...")
    local ok, result = pcall(cmd_func, diagnostic_tool, {}, nil)
    
    if ok then
        print("✅ Tool executed successfully")
        print("Result type:", type(result))
        print("Result status:", result.status)
        
        if result.data then
            local data_preview = tostring(result.data):sub(1, 200)
            print("Result data preview:", data_preview)
            
            -- Check if data contains "No diagnostics" or actual diagnostic content
            local data_str = tostring(result.data)
            if data_str:match("No diagnostics found") then
                print("❌ Tool returned 'No diagnostics found' message")
            elseif data_str:match("LSP Document Diagnostics:") then
                print("✅ Tool returned formatted diagnostic output")
            else
                print("❓ Tool returned unexpected format")
            end
        else
            print("❌ Result has no data field")
        end
    else
        print("❌ Tool execution failed:", result)
    end
else
    print("❌ Tool has no command function")
end

print("\n=== Recommendations ===")
print("1. If in CodeCompanion buffer: Tool should auto-detect file buffers")
print("2. If no file buffers: Open a file with diagnostics first")
print("3. If tool finds wrong buffer: Buffer detection logic needs fixing")