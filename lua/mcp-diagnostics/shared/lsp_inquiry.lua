-- Pure LSP inquiry operations
-- Handles LSP requests without buffer management concerns
-- Assumes buffers are already loaded by lsp_interact.lua

local config = require("mcp-diagnostics.shared.config")
local M = {}

-- Helper to get client name from client_id
local function get_client_name(client_id)
    local client_name = "unknown"
    if vim.lsp.get_clients then
        local clients = vim.lsp.get_clients()
        for _, client in ipairs(clients) do
            if client.id == client_id then
                client_name = client.name
                break
            end
        end
    end
    return client_name
end

-- Get hover information for a position
function M.get_hover_info(bufnr, line, column)
    config.log_debug(string.format("Getting hover info for buffer %d:%d:%d", bufnr, line, column), "[LSP Inquiry]")

    local params = vim.lsp.util.make_position_params()
    local lsp_response = vim.lsp.buf_request_sync(bufnr, "textDocument/hover", params)

    local hover_info = {}
    for client_id, response in pairs(lsp_response or {}) do
        local result = response.result
        local client_name = get_client_name(client_id)

        if result and result.contents then
            local content = result.contents
            local text = ""

            if type(content) == "string" then
                text = content
            elseif type(content) == "table" then
                if content.value then
                    text = content.value
                elseif content[1] then
                    if type(content[1]) == "string" then
                        text = content[1]
                    elseif content[1].value then
                        text = content[1].value
                    end
                end
            end

            if text and text ~= "" then
                table.insert(hover_info, {
                    client = client_name,
                    content = text
                })
            end
        end
    end

    return hover_info
end

-- Get definitions for a symbol at a position
function M.get_definitions(bufnr, line, column)
    config.log_debug(string.format("Getting definitions for buffer %d:%d:%d", bufnr, line, column), "[LSP Inquiry]")

    local params = vim.lsp.util.make_position_params()
    local lsp_response = vim.lsp.buf_request_sync(bufnr, "textDocument/definition", params)

    local definitions = {}
    for client_id, response in pairs(lsp_response or {}) do
        local result = response.result
        local client_name = get_client_name(client_id)

        for _, definition in pairs(result or {}) do
            if definition.uri then
                table.insert(definitions, {
                    client = client_name,
                    uri = definition.uri,
                    file = vim.uri_to_fname(definition.uri),
                    range = definition.range
                })
            end
        end
    end

    return definitions
end

-- Get references for a symbol at a position
function M.get_references(bufnr, line, column)
    config.log_debug(string.format("Getting references for buffer %d:%d:%d", bufnr, line, column), "[LSP Inquiry]")

    local params = vim.lsp.util.make_position_params()
    params.context = { includeDeclaration = true }
    local lsp_response = vim.lsp.buf_request_sync(bufnr, "textDocument/references", params)

    local references = {}
    for client_id, response in pairs(lsp_response or {}) do
        local result = response.result
        local client_name = get_client_name(client_id)

        for _, reference in pairs(result or {}) do
            if reference.uri then
                table.insert(references, {
                    client = client_name,
                    uri = reference.uri,
                    file = vim.uri_to_fname(reference.uri),
                    range = reference.range
                })
            end
        end
    end

    return references
end

-- Get document symbols for a buffer
function M.get_document_symbols(bufnr)
    config.log_debug(string.format("Getting document symbols for buffer %d", bufnr), "[LSP Inquiry]")

    local file = vim.api.nvim_buf_get_name(bufnr)
    local params = {
        textDocument = { uri = vim.uri_from_fname(file) }
    }
    local lsp_response = vim.lsp.buf_request_sync(bufnr, "textDocument/documentSymbol", params)

    local symbols = {}
    for client_id, response in pairs(lsp_response or {}) do
        local result = response.result
        local client_name = get_client_name(client_id)

        if result then
            for _, symbol in ipairs(result) do
                table.insert(symbols, {
                    client = client_name,
                    name = symbol.name,
                    kind = symbol.kind,
                    range = symbol.range,
                    selectionRange = symbol.selectionRange,
                    children = symbol.children
                })
            end
        end
    end

    return symbols
end

-- Get workspace symbols with optional query
function M.get_workspace_symbols(query)
    config.log_debug(string.format("Getting workspace symbols with query: %s", query or "(none)"), "[LSP Inquiry]")

    local params = { query = query or "" }
    local bufnr = vim.api.nvim_get_current_buf()
    local lsp_response = vim.lsp.buf_request_sync(bufnr, "workspace/symbol", params)

    local symbols = {}
    for client_id, response in pairs(lsp_response or {}) do
        local result = response.result
        local client_name = get_client_name(client_id)

        if result then
            for _, symbol in ipairs(result) do
                local location = symbol.location
                table.insert(symbols, {
                    client = client_name,
                    name = symbol.name,
                    kind = symbol.kind,
                    containerName = symbol.containerName,
                    location = {
                        uri = location.uri,
                        file = vim.uri_to_fname(location.uri),
                        range = location.range
                    }
                })
            end
        end
    end

    return symbols
end

-- Get code actions for a range
function M.get_code_actions(bufnr, line, column, end_line, end_column)
    config.log_debug(string.format("Getting code actions for buffer %d:%d:%d", bufnr, line, column), "[LSP Inquiry]")

    local file = vim.api.nvim_buf_get_name(bufnr)
    local range = {
        start = { line = line, character = column },
        ["end"] = {
            line = end_line or line,
            character = end_column or column
        }
    }

    local diagnostics = vim.diagnostic.get(bufnr, {
        lnum = line,
        end_lnum = end_line or line
    })

    local params = {
        textDocument = { uri = vim.uri_from_fname(file) },
        range = range,
        context = {
            diagnostics = diagnostics
        }
    }

    local lsp_response = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params)

    local actions = {}
    for client_id, response in pairs(lsp_response or {}) do
        local result = response.result
        local client_name = get_client_name(client_id)

        if result then
            for _, action in ipairs(result) do
                table.insert(actions, {
                    client = client_name,
                    title = action.title,
                    kind = action.kind,
                    isPreferred = action.isPreferred,
                    disabled = action.disabled,
                    edit = action.edit,
                    command = action.command
                })
            end
        end
    end

    return actions
end

return M
