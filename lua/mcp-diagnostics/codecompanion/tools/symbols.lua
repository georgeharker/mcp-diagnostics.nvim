
local lsp = require("mcp-diagnostics.shared.lsp")
local base = require("mcp-diagnostics.codecompanion.tools.base")
local BaseTool = base.BaseTool

local M = {}
M.lsp_document_symbols = setmetatable({
    name = "lsp_document_symbols",
    description = "Get document symbols for the current file or specified file",
    cmds = {
        function(self, args, _input)
            args = args or {}

           -- Validate arguments
           if args.file and type(args.file) ~= "string" then
               return self:error(nil, nil, "Invalid 'file' parameter: must be a string (file path)")
           end

            local file = args.file

            -- If no file specified, use current buffer
            if not file then
                file = vim.api.nvim_buf_get_name(0)
                if file == "" then
                    return self:error(nil, nil, "No file is currently open")
                end
            end

            local symbols = lsp.get_document_symbols(file)
            return self:success("symbols", symbols, "LSP Document Symbols")
        end,
    },
    schema = {
        type = "function",
        ["function"] = {
            name = "lsp_document_symbols",
            description = "Get document symbols for the current file or specified file",
            parameters = {
                type = "object",
                properties = {
                    file = {
                        type = "string",
                        description = "File path (uses current buffer if not specified)"
                    }
                },
                additionalProperties = false
            },
            strict = true
        }
    },
    output = BaseTool:create_output_handlers("LSP Document Symbols")
}, { __index = BaseTool })

-- LSP Workspace Symbols Tool
M.lsp_workspace_symbols = setmetatable({
    name = "lsp_workspace_symbols",
    description = "Get workspace symbols with optional query filter",
    cmds = {
        function(self, args, _input)
            args = args or {}

           -- Validate arguments
           if args.query and type(args.query) ~= "string" then
               return self:error(nil, nil, "Invalid 'query' parameter: must be a string (search query for symbols)")
           end

            local query = args.query

            local symbols = lsp.get_workspace_symbols(query)
            return self:success("symbols", symbols, "LSP Workspace Symbols")
        end,
    },
    schema = {
        type = "function",
        ["function"] = {
            name = "lsp_workspace_symbols",
            description = "Get workspace symbols with optional query filter",
            parameters = {
                type = "object",
                properties = {
                    query = {
                        type = "string",
                        description = "Search query for symbols (optional)"
                    }
                },
                additionalProperties = false
            },
            strict = true
        }
    },
    output = BaseTool:create_output_handlers("LSP Workspace Symbols")
}, { __index = BaseTool })

return M
