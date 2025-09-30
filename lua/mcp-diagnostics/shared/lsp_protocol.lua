-- Clean LSP interface using vim.lsp.protocol directly
-- Inspired by CodeCompanion's approach

local api = vim.api

---@class MCP.LSP.Protocol
local M = {}

-- LSP Methods from protocol
local METHODS = {
    hover = vim.lsp.protocol.Methods.textDocument_hover,
    definition = vim.lsp.protocol.Methods.textDocument_definition,
    references = vim.lsp.protocol.Methods.textDocument_references,
    document_symbols = vim.lsp.protocol.Methods.textDocument_documentSymbol,
    workspace_symbols = vim.lsp.protocol.Methods.workspace_symbol,
    code_actions = vim.lsp.protocol.Methods.textDocument_codeAction,
}

--- Ensure file is loaded in a buffer and return buffer number
---@param filepath string Path to the file
---@return number|nil bufnr Buffer number if successful
---@return string|nil error Error message if failed
function M.ensure_file_loaded(filepath)
    if not filepath or filepath == "" then
        return nil, "Invalid file path"
    end

    -- Check if file is already loaded
    local existing_bufnr = vim.fn.bufnr(filepath)
    if existing_bufnr ~= -1 and api.nvim_buf_is_loaded(existing_bufnr) then
        return existing_bufnr, nil
    end

    -- Load the file
    local ok, result = pcall(vim.fn.bufadd, filepath)
    if not ok then
        return nil, "Failed to add buffer: " .. tostring(result)
    end

    local bufnr = result
    if not api.nvim_buf_is_loaded(bufnr) then
        ok = pcall(vim.fn.bufload, bufnr)
        if not ok then
            return nil, "Failed to load buffer"
        end
    end

    return bufnr, nil
end

--- Get LSP clients that support a specific method for a buffer
---@param bufnr number Buffer number
---@param method string LSP method name
---@return table[] clients Array of LSP clients
local function get_clients_for_method(bufnr, method)
    -- Get all clients that support the method
    local all_clients = vim.lsp.get_clients({ method = method })
    local buffer_clients = {}

    for _, client in ipairs(all_clients) do
        -- Attach client to buffer if not already attached
        if not vim.lsp.buf_is_attached(bufnr, client.id) then
            vim.lsp.buf_attach_client(bufnr, client.id)
        end
        table.insert(buffer_clients, client)
    end

    return buffer_clients
end

--- Execute LSP request asynchronously across all capable clients
---@param bufnr number Buffer number
---@param method string LSP method
---@param params table|nil Request parameters
---@param callback function Callback function
local function execute_lsp_request_async(bufnr, method, params, callback)
    local clients = get_clients_for_method(bufnr, method)

    if #clients == 0 then
        callback(nil, "No LSP clients support " .. method)
        return
    end

    local results = {}
    local completed = 0
    local total = #clients

    for _, client in ipairs(clients) do
        client:request(method, params, function(_err, result, _ctx, _config)
            if result then
                table.insert(results, {
                    client_name = client.name,
                    result = result
                })
            end

            completed = completed + 1
            if completed == total then
                -- Combine results from all clients
                local combined_result = {}
                for _, client_result in ipairs(results) do
                    if type(client_result.result) == "table" then
                        if vim.islist(client_result.result) then
                            vim.list_extend(combined_result, client_result.result)
                        else
                            combined_result = client_result.result -- Take the first non-list result
                        end
                    end
                end
                callback(combined_result, nil)
            end
        end)
    end
end

function M.get_hover_info(filepath, line, column)
    local bufnr, err = M.ensure_file_loaded(filepath)
    if not bufnr then
        return nil, err
    end

    -- Create position params directly without switching buffers
    local position_params = {
        textDocument = vim.lsp.util.make_text_document_params(bufnr),
        position = { line = line, character = column }
    }

    local result = nil
    local error_msg = nil
    local completed = false

    execute_lsp_request_async(bufnr, METHODS.hover, position_params, function(lsp_result, lsp_error)
        result = lsp_result
        error_msg = lsp_error
        completed = true
    end)

    -- Wait for completion (sync wrapper)
    vim.wait(5000, function() return completed end)

    return result, error_msg
end

function M.get_definitions(filepath, line, column)
    local bufnr, err = M.ensure_file_loaded(filepath)
    if not bufnr then
        return nil, err
    end

    local position_params = {
        textDocument = vim.lsp.util.make_text_document_params(bufnr),
        position = { line = line, character = column }
    }

    local result = nil
    local error_msg = nil
    local completed = false

    execute_lsp_request_async(bufnr, METHODS.definition, position_params, function(lsp_result, lsp_error)
        result = lsp_result
        error_msg = lsp_error
        completed = true
    end)

    vim.wait(5000, function() return completed end)


    return result, error_msg
end

function M.get_references(filepath, line, column)
    local bufnr, err = M.ensure_file_loaded(filepath)
    if not bufnr then
        return nil, err
    end

    local position_params = {
        textDocument = vim.lsp.util.make_text_document_params(bufnr),
        position = { line = line, character = column },
        context = { includeDeclaration = false }
    }

    local result = nil
    local error_msg = nil
    local completed = false

    execute_lsp_request_async(bufnr, METHODS.references, position_params, function(lsp_result, lsp_error)
        result = lsp_result
        error_msg = lsp_error
        completed = true
    end)

    vim.wait(5000, function() return completed end)


    return result, error_msg
end

--- Get document symbols
---@param filepath string File path
---@return table|nil result Document symbols
---@return string|nil error Error message
function M.get_document_symbols(filepath)
    local bufnr, err = M.ensure_file_loaded(filepath)
    if not bufnr then
        return nil, err
    end

    local result = nil
    local error_msg = nil
    local completed = false

    local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }

    execute_lsp_request_async(bufnr, METHODS.document_symbols, params, function(lsp_result, lsp_error)
        result = lsp_result
        error_msg = lsp_error
        completed = true
    end)

    vim.wait(5000, function() return completed end)

    return result, error_msg
end

--- Get workspace symbols
---@param query string|nil Search query
---@return table|nil result Workspace symbols
---@return string|nil error Error message
function M.get_workspace_symbols(query)
    local result = nil
    local error_msg = nil
    local completed = false

    local params = { query = query or "" }

    -- Use current buffer for client context
    local bufnr = api.nvim_get_current_buf()

    execute_lsp_request_async(bufnr, METHODS.workspace_symbols, params, function(lsp_result, lsp_error)
        result = lsp_result
        error_msg = lsp_error
        completed = true
    end)

    vim.wait(5000, function() return completed end)

    return result, error_msg
end

--- Get code actions for a position/range
---@param filepath string File path
---@param line number Line number (0-based)
---@param column number Column number (0-based)
---@param end_line number|nil End line number (0-based)
---@param end_column number|nil End column number (0-based)
---@return table|nil result Available code actions
---@return string|nil error Error message
function M.get_code_actions(filepath, line, column, end_line, end_column)
    local bufnr, err = M.ensure_file_loaded(filepath)
    if not bufnr then
        return nil, err
    end

    -- Create range for code actions
    local range = {
        start = { line = line, character = column },
        ["end"] = {
            line = end_line or line,
            character = end_column or column
        }
    }

    local params = {
        textDocument = vim.lsp.util.make_text_document_params(bufnr),
        range = range,
        context = { diagnostics = vim.diagnostic.get(bufnr, { lnum = line }) }
    }

    local result = nil
    local error_msg = nil
    local completed = false

    execute_lsp_request_async(bufnr, METHODS.code_actions, params, function(lsp_result, lsp_error)
        result = lsp_result
        error_msg = lsp_error
        completed = true
    end)

    vim.wait(5000, function() return completed end)


    return result, error_msg
end

return M
