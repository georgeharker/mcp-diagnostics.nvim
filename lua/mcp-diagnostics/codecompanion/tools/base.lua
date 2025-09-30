-- Base Tool Class for CodeCompanion Tools
-- Shared functionality for all mcp-diagnostics tools
-- ENHANCED VERSION: Added LSP validation helpers

local utils = require("mcp-diagnostics.codecompanion.utils")

local M = {}

--- @class McpDiagnosticsResult
--- @field datatype string structured data type
--- @field data any data from tool

local BaseTool = {}
BaseTool.__index = BaseTool

function BaseTool:new()
    local obj = setmetatable({}, self)
    obj.opts = {}
    return obj
end

function BaseTool:setup(opts)
    self.opts = opts or {}
end

function BaseTool:format_error(message)
    return {
        status = "error",
        data = message,
    }
end

-- NEW: LSP validation helper
function BaseTool:validate_lsp_available(bufnr, filepath)
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    if #clients == 0 then
        local error_msg = string.format(
            "❌ LSP Analysis Failed for: %s\n"
                .. "📄 Buffer: %d\n"
                .. "🔌 LSP Clients: 0\n\n"
                .. "💡 Suggestion: Ensure LSP server is installed and running for this file type.\n"
                .. "   For Python files, try installing: pip install python-lsp-server\n"
                .. "   Then restart Neovim or use :LspStart command.",
            filepath or "[unknown file]",
            bufnr or -1
        )
        return false, error_msg
    end
    return true, clients
end

-- NEW: Enhanced error formatting for LSP issues
function BaseTool:format_lsp_error(bufnr, filepath, extra_info)
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    local client_names = {}
    for _, client in ipairs(clients) do
        table.insert(client_names, client.name)
    end

    local error_msg = string.format(
        "❌ LSP Analysis Failed\n"
            .. "📄 File: %s\n"
            .. "📋 Buffer: %d\n"
            .. "🔌 LSP Clients: %d (%s)\n"
            .. "%s\n"
            .. "💡 Troubleshooting:\n"
            .. "   • Check if LSP server is installed for this file type\n"
            .. "   • Use :LspInfo to verify server status\n"
            .. "   • Try :LspStart to manually start the server\n"
            .. "   • Ensure file extension is supported by LSP server",
        filepath or "[unknown]",
        bufnr or -1,
        #clients,
        #client_names > 0 and table.concat(client_names, ", ") or "none",
        extra_info or ""
    )
    return self:error(nil, error_msg)
end

function BaseTool:validate_required_params(args, required_params, param_descriptions)
    args = args or {}
    local missing = {}

    for _, param in ipairs(required_params) do
        if not args[param] then
            local desc = param_descriptions and param_descriptions[param] or param
            table.insert(missing, string.format("- %s: %s", param, desc))
        end
    end

    if #missing > 0 then
        local error_msg = string.format(
            "Missing required parameters for %s:\n%s\n\nPlease provide these parameters and try again.",
            self.name,
            table.concat(missing, "\n")
        )
        return self:format_error(error_msg)
    end

    return nil
end

-- Helper to create standard output handlers for tools
function BaseTool:create_output_handlers(display_name)
    return {
        success = function(self_, tools, _cmd, stdout)
            local chat = tools.chat
            --- @type McpDiagnosticsFormatResult
            local raw_result = stdout[#stdout]

            local user_output, llm_output
            local summary = ""
            -- Handle the structure returned by utils.format_tool_output
            if type(raw_result) == "table" then
                if raw_result.summary then
                    summary = raw_result.summary
                end
                if raw_result.llm_output and raw_result.formatted then
                    user_output = raw_result.formatted
                    llm_output = raw_result.llm_output
                elseif raw_result.llm_output then
                    user_output = nil
                    llm_output = raw_result.llm_output
                elseif raw_result.formatted then
                    user_output = raw_result.formatted
                    llm_output = user_output
                else
                    user_output = "Unexpected tool result format"
                    llm_output = nil
                end
            else
                user_output = tostring(raw_result)
                llm_output = raw_result
            end

            -- Ensure we have content to display
            --"Encountered an error:"
            local fmt
            if summary and summary ~= "" then
                fmt = string.format([[**`%%s` **: Returned the following:

````
%%s
````

---
%s
]],
                    summary)
            else
                fmt = [[**`%s` **: Returned the following:

````
%s
````
]]
            end

            local formatted
            if user_output then
                formatted = string.format(
                    fmt,
                    self_.name,
                    user_output
                )
            else
                -- Handle case where no user output but we have summary
                if summary and summary ~= "" then
                    formatted = string.format([[**`%s` Tool**: %s]],
                        self_.name, summary)
                else
                    formatted = string.format([[**`%s` Tool**: Completed successfully but returned no output]],
                        self_.name)
                end
            end

            chat:add_tool_output(self_, llm_output, formatted)
        end,
        error = function(self_, tools, _cmd, stderr)
            local chat = tools.chat

            --- @type McpDiagnosticsFormatResult|string
            local raw_result = stderr[#stderr] or "Unknown error"

            -- Handle the structure returned by utils.format_tool_output for errors
            local user_output, llm_output
            local summary = ""
            -- Handle the structure returned by utils.format_tool_output
            if type(raw_result) == "table" then
                if raw_result.summary then
                    summary = raw_result.summary
                end
                if raw_result.llm_output and raw_result.formatted then
                    user_output = raw_result.formatted
                    llm_output = raw_result.llm_output
                elseif raw_result.llm_output then
                    user_output = nil
                    llm_output = raw_result.llm_output
                elseif raw_result.formatted then
                    user_output = raw_result.formatted
                    llm_output = user_output
                else
                    user_output = "Unexpected tool result format"
                    llm_output = nil
                end
            else
                user_output = tostring(raw_result)
                llm_output = raw_result
            end

            -- Ensure we have content to display
            --"Encountered an error:"
            local fmt
            if summary and summary ~= "" then
                fmt = string.format([[**`%%s` **: Failed with the following error:

````
%%s
````

---
%s
]],
                    summary)
            else
                fmt = [[**`%s` **: Failed with the following error:

````
%s
````
]]
            end

            local formatted
            if user_output then
                formatted = string.format(
                    fmt,
                    self_.name,
                    user_output
                )
            else
                -- Handle case where no user output but we have summary
                if summary and summary ~= "" then
                    formatted = string.format([[**`%s` Tool**: Failed - %s]],
                        self_.name, summary)
                else
                    formatted = string.format([[**`%s` Tool**: Failed with unknown error]],
                        self_.name)
                end
            end

            chat:add_tool_output(self_, llm_output, formatted)
        end,
    }
end

--- @param datatype string? structured data type
--- @param data any data from tool
--- @param summary string? short summary of data
function BaseTool:success(datatype, data, summary)
    return utils.format_tool_output(self.name, "success", datatype, data, summary or self.name)
end

--- @param datatype string? structured data type
--- @param data? any data from tool
--- @param summary string? short summary of data
function BaseTool:error(datatype, data, summary)
    return utils.format_tool_output(self.name, "error", datatype, data, summary or self.name)
end

M.BaseTool = BaseTool

return M
