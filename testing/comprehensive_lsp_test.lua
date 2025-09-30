-- Comprehensive LSP Tool Test Suite
-- Tests all mcp-diagnostics tools with the new test files

local M = {}

--- Test configuration
M.config = {
    remote_socket = '/tmp/nvim-test-sock',
    test_files = {
        'testing/lsp_test_files/user_model.lua',
        'testing/lsp_test_files/validation.lua', 
        'testing/lsp_test_files/database.lua',
        'testing/lsp_test_files/user_service.lua',
        'testing/lsp_test_files/app.lua',
        'testing/syntax_errors/missing_end.lua',
        'testing/syntax_errors/undefined_variables.lua',
        'testing/syntax_errors/type_errors.lua',
        'testing/syntax_errors/malformed_syntax.lua'
    }
}

--- Test results storage
M.results = {
    tests_run = 0,
    tests_passed = 0,
    tests_failed = 0,
    details = {}
}

--- Connects to remote Neovim instance
---@return number handle, string? error
function M.connect_remote()
    local handle = vim.fn.sockconnect('pipe', M.config.remote_socket, {rpc = true})
    if handle <= 0 then
        return 0, 'Failed to connect to remote Neovim'
    end
    
    -- Test connection
    local success, result = pcall(function()
        return vim.fn.rpcrequest(handle, 'nvim_exec_lua', 'return "connected"', {})
    end)
    
    if not success then
        vim.fn.chanclose(handle)
        return 0, 'Connection test failed: ' .. tostring(result)
    end
    
    return handle, nil
end

--- Loads test files into remote Neovim
---@param handle number Remote connection handle
---@return boolean success, table loaded_files
function M.load_test_files(handle)
    local loaded_files = {}
    
    for _, file_path in ipairs(M.config.test_files) do
        local success, result = pcall(function()
            return vim.fn.rpcrequest(handle, 'nvim_command', 'edit ' .. file_path)
        end)
        
        if success then
            table.insert(loaded_files, file_path)
        else
            print(string.format("Failed to load %s: %s", file_path, result))
        end
    end
    
    -- Wait for LSP analysis
    vim.fn.rpcrequest(handle, 'nvim_exec_lua', 'vim.wait(3000)', {})
    
    return #loaded_files > 0, loaded_files
end

--- Tests lsp_document_diagnostics tool
---@param handle number Remote connection handle
---@param file_path string File to analyze
---@return boolean success, table result
function M.test_document_diagnostics(handle, file_path)
    local test_result = {
        tool = 'lsp_document_diagnostics',
        file = file_path,
        success = false,
        diagnostics_found = 0,
        error = nil
    }
    
    local success, result = pcall(function()
        return vim.fn.rpcrequest(handle, 'nvim_exec_lua', string.format([[
            -- Load the file
            vim.cmd('edit %s')
            vim.wait(2000)  -- Wait for LSP analysis
            
            -- Execute the tool
            local tool_module = require('mcp-diagnostics.codecompanion.tools.diagnostics')
            local tool = tool_module.lsp_document_diagnostics
            
            local tool_result = tool.cmds[1](tool, { file = '%s' })
            
            -- Parse the result
            if tool_result and tool_result.content then
                local json_ok, json_data = pcall(vim.json.decode, tool_result.content)
                if json_ok then
                    return {
                        success = true,
                        diagnostic_count = json_data.diagnostics and #json_data.diagnostics or 0,
                        summary = json_data.summary,
                        files = json_data.files
                    }
                else
                    return { success = false, error = 'JSON parse failed' }
                end
            else
                return { success = false, error = 'No content returned' }
            end
        ]], file_path, file_path), {})
    end)
    
    if success and result.success then
        test_result.success = true
        test_result.diagnostics_found = result.diagnostic_count
        test_result.summary = result.summary
        test_result.files = result.files
    else
        test_result.error = result.error or tostring(result)
    end
    
    return test_result.success, test_result
end

--- Tests lsp_hover tool
---@param handle number Remote connection handle
---@param file_path string File to analyze
---@param line number Line number (0-based)
---@param column number Column number (0-based)
---@return boolean success, table result
function M.test_lsp_hover(handle, file_path, line, column)
    local test_result = {
        tool = 'lsp_hover',
        file = file_path,
        position = {line = line, column = column},
        success = false,
        hover_info = nil,
        error = nil
    }
    
    local success, result = pcall(function()
        return vim.fn.rpcrequest(handle, 'nvim_exec_lua', string.format([[
            -- Load the file
            vim.cmd('edit %s')
            vim.wait(1000)
            
            -- Test the LSP hover functionality
            local lsp = require('mcp-diagnostics.shared.lsp')
            local hover_result = lsp.get_hover_info('%s', %d, %d)
            
            return {
                success = hover_result ~= nil,
                hover_info = hover_result
            }
        ]], file_path, file_path, line, column), {})
    end)
    
    if success and result.success then
        test_result.success = true
        test_result.hover_info = result.hover_info
    else
        test_result.error = tostring(result)
    end
    
    return test_result.success, test_result
end

--- Tests lsp_definition tool
---@param handle number Remote connection handle  
---@param file_path string File to analyze
---@param line number Line number (0-based)
---@param column number Column number (0-based)
---@return boolean success, table result
function M.test_lsp_definition(handle, file_path, line, column)
    local test_result = {
        tool = 'lsp_definition',
        file = file_path,
        position = {line = line, column = column},
        success = false,
        definitions = nil,
        error = nil
    }
    
    local success, result = pcall(function()
        return vim.fn.rpcrequest(handle, 'nvim_exec_lua', string.format([[
            -- Load the file
            vim.cmd('edit %s')
            vim.wait(1000)
            
            -- Test the LSP definition functionality
            local lsp = require('mcp-diagnostics.shared.lsp')
            local definitions = lsp.get_definitions('%s', %d, %d)
            
            return {
                success = definitions ~= nil,
                definitions = definitions,
                definition_count = definitions and #definitions or 0
            }
        ]], file_path, file_path, line, column), {})
    end)
    
    if success then
        test_result.success = result.success
        test_result.definitions = result.definitions
        test_result.definition_count = result.definition_count
    else
        test_result.error = tostring(result)
    end
    
    return test_result.success, test_result
end

--- Tests lsp_document_symbols tool
---@param handle number Remote connection handle
---@param file_path string File to analyze
---@return boolean success, table result
function M.test_document_symbols(handle, file_path)
    local test_result = {
        tool = 'lsp_document_symbols',
        file = file_path,
        success = false,
        symbols = nil,
        symbol_count = 0,
        error = nil
    }
    
    local success, result = pcall(function()
        return vim.fn.rpcrequest(handle, 'nvim_exec_lua', string.format([[
            -- Load the file
            vim.cmd('edit %s')
            vim.wait(1000)
            
            -- Test document symbols
            local lsp = require('mcp-diagnostics.shared.lsp')
            local symbols = lsp.get_document_symbols('%s')
            
            return {
                success = symbols ~= nil,
                symbols = symbols,
                symbol_count = symbols and #symbols or 0
            }
        ]], file_path, file_path), {})
    end)
    
    if success then
        test_result.success = result.success
        test_result.symbols = result.symbols
        test_result.symbol_count = result.symbol_count
    else
        test_result.error = tostring(result)
    end
    
    return test_result.success, test_result
end

--- Runs all tests on a specific file
---@param handle number Remote connection handle
---@param file_path string File to test
---@return table results
function M.test_file(handle, file_path)
    print(string.format("\n📁 Testing file: %s", file_path))
    
    local file_results = {
        file = file_path,
        tests = {}
    }
    
    -- Test 1: Document Diagnostics
    print("  🔍 Testing lsp_document_diagnostics...")
    local diag_success, diag_result = M.test_document_diagnostics(handle, file_path)
    table.insert(file_results.tests, diag_result)
    M.results.tests_run = M.results.tests_run + 1
    
    if diag_success then
        M.results.tests_passed = M.results.tests_passed + 1
        print(string.format("    ✅ Found %d diagnostics", diag_result.diagnostics_found))
    else
        M.results.tests_failed = M.results.tests_failed + 1
        print(string.format("    ❌ Failed: %s", diag_result.error))
    end
    
    -- Test 2: Document Symbols
    print("  📋 Testing lsp_document_symbols...")
    local symbols_success, symbols_result = M.test_document_symbols(handle, file_path)
    table.insert(file_results.tests, symbols_result)
    M.results.tests_run = M.results.tests_run + 1
    
    if symbols_success then
        M.results.tests_passed = M.results.tests_passed + 1
        print(string.format("    ✅ Found %d symbols", symbols_result.symbol_count))
    else
        M.results.tests_failed = M.results.tests_failed + 1
        print(string.format("    ❌ Failed: %s", symbols_result.error))
    end
    
    -- Test 3: LSP Hover (on function names)
    print("  💬 Testing lsp_hover...")
    local hover_success, hover_result = M.test_lsp_hover(handle, file_path, 10, 10)  -- Test position
    table.insert(file_results.tests, hover_result)
    M.results.tests_run = M.results.tests_run + 1
    
    if hover_success then
        M.results.tests_passed = M.results.tests_passed + 1
        print("    ✅ Hover info retrieved")
    else
        M.results.tests_failed = M.results.tests_failed + 1
        print(string.format("    ❌ Failed: %s", hover_result.error))
    end
    
    -- Test 4: LSP Definition 
    print("  🎯 Testing lsp_definition...")
    local def_success, def_result = M.test_lsp_definition(handle, file_path, 5, 15)  -- Test position
    table.insert(file_results.tests, def_result)
    M.results.tests_run = M.results.tests_run + 1
    
    if def_success then
        M.results.tests_passed = M.results.tests_passed + 1
        print(string.format("    ✅ Found %d definitions", def_result.definition_count))
    else
        M.results.tests_failed = M.results.tests_failed + 1
        print(string.format("    ❌ Failed: %s", def_result.error))
    end
    
    return file_results
end

--- Runs the complete test suite
---@return boolean success
function M.run_comprehensive_test()
    print("🚀 Starting Comprehensive LSP Tool Test Suite")
    print(string.format("📊 Testing %d files with %d tools each", #M.config.test_files, 4))
    
    -- Connect to remote Neovim
    local handle, connect_error = M.connect_remote()
    if not handle then
        print("❌ " .. connect_error)
        return false
    end
    
    print("✅ Connected to remote Neovim")
    
    -- Load test files
    local load_success, loaded_files = M.load_test_files(handle)
    if not load_success then
        print("❌ Failed to load test files")
        vim.fn.chanclose(handle)
        return false
    end
    
    print(string.format("✅ Loaded %d test files", #loaded_files))
    
    -- Run tests on each file
    for _, file_path in ipairs(loaded_files) do
        local file_results = M.test_file(handle, file_path)
        table.insert(M.results.details, file_results)
    end
    
    -- Cleanup
    vim.fn.chanclose(handle)
    
    -- Print summary
    print("\n📈 Test Suite Summary:")
    print(string.format("  Total tests: %d", M.results.tests_run))
    print(string.format("  Passed: %d", M.results.tests_passed))
    print(string.format("  Failed: %d", M.results.tests_failed))
    print(string.format("  Success rate: %.1f%%", (M.results.tests_passed / M.results.tests_run) * 100))
    
    return M.results.tests_failed == 0
end

return M