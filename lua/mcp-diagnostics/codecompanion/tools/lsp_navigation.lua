
local lsp = require("mcp-diagnostics.shared.lsp")
local base = require("mcp-diagnostics.codecompanion.tools.base")
local BaseTool = base.BaseTool

local M = {}
M.lsp_hover = setmetatable({
    name = "lsp_hover",
    description = "Get LSP hover information for a symbol at the cursor or specified position",
    cmds = {
        function(self, args, _input)
            args = args or {}

           -- Validate arguments
           if args.line and type(args.line) ~= "number" then
               return self:error(nil, nil, "Invalid 'line' parameter: must be a number (0-based line number)")
           end
           if args.column and type(args.column) ~= "number" then
               return self:error(nil, nil, "Invalid 'column' parameter: must be a number (0-based column number)")
           end
           if args.file and type(args.file) ~= "string" then
               return self:error(nil, nil, "Invalid 'file' parameter: must be a string (file path)")
           end
           if args.line and args.line < 0 then
               return self:error(nil, nil, "Invalid 'line' parameter: must be >= 0 (0-based line number)")
           end
           if args.column and args.column < 0 then
               return self:error(nil, nil, "Invalid 'column' parameter: must be >= 0 (0-based column number)")
           end

            local file = args.file
            local line = args.line
            local column = args.column

            -- If no file specified, use current buffer
            if not file then
                file = vim.api.nvim_buf_get_name(0)
                if file == "" then
                    return self:error(nil, nil, "No file is currently open")
                end
            end

            -- If no position specified, use cursor position
            if not line or not column then
                local cursor = vim.api.nvim_win_get_cursor(0)
                line = cursor[1] - 1  -- Convert to 0-based
                column = cursor[2]
            end

            local hover_info = lsp.get_hover_info(file, line, column)
            return self:success("llm", hover_info, "LSP Hover Information")
        end,
    },
    schema = {
        type = "function",
        ["function"] = {
            name = "lsp_hover",
            description = "Get LSP hover information for a symbol at the cursor or specified position",
            parameters = {
                type = "object",
                properties = {
                    file = {
                        type = "string",
                        description = "File path (uses current buffer if not specified)"
                    },
                    line = {
                        type = "number",
                        description = "Line number (0-based, uses cursor if not specified)"
                    },
                    column = {
                        type = "number",
                        description = "Column number (0-based, uses cursor if not specified)"
                    }
                },
                additionalProperties = false
            },
            strict = true
        }
    },
    output = BaseTool:create_output_handlers("LSP Hover Information")
}, { __index = BaseTool })

-- LSP Definition Tool
M.lsp_definition = setmetatable({
    name = "lsp_definition",
    description = "Get LSP definition for a symbol at the cursor or specified position",
    cmds = {
        function(self, args, _input)
            args = args or {}

           -- Validate arguments
           if args.line and type(args.line) ~= "number" then
               return self:error(nil, nil, "Invalid 'line' parameter: must be a number (0-based line number)")
           end
           if args.column and type(args.column) ~= "number" then
               return self:error(nil, nil, "Invalid 'column' parameter: must be a number (0-based column number)")
           end
           if args.file and type(args.file) ~= "string" then
               return self:error(nil, nil, "Invalid 'file' parameter: must be a string (file path)")
           end
           if args.line and args.line < 0 then
               return self:error(nil, nil, "Invalid 'line' parameter: must be >= 0 (0-based line number)")
           end
           if args.column and args.column < 0 then
               return self:error(nil, nil, "Invalid 'column' parameter: must be >= 0 (0-based column number)")
           end

            local file = args.file
            local line = args.line
            local column = args.column

            -- If no file specified, use current buffer
            if not file then
                file = vim.api.nvim_buf_get_name(0)
                if file == "" then
                    return self:error(nil, nil, "No file is currently open")
                end
            end

            -- If no position specified, use cursor position
            if not line or not column then
                local cursor = vim.api.nvim_win_get_cursor(0)
                line = cursor[1] - 1  -- Convert to 0-based
                column = cursor[2]
            end

            local definitions = lsp.get_definitions(file, line, column)
            return self:success("location", definitions, "LSP Definitions")
        end,
    },
    schema = {
        type = "function",
        ["function"] = {
            name = "lsp_definition",
            description = "Get LSP definition for a symbol at the cursor or specified position",
            parameters = {
                type = "object",
                properties = {
                    file = {
                        type = "string",
                        description = "File path (uses current buffer if not specified)"
                    },
                    line = {
                        type = "number",
                        description = "Line number (0-based, uses cursor if not specified)"
                    },
                    column = {
                        type = "number",
                        description = "Column number (0-based, uses cursor if not specified)"
                    }
                },
                additionalProperties = false
            },
            strict = true
        }
    },
    output = BaseTool:create_output_handlers("LSP Definitions")
}, BaseTool)

-- LSP References Tool
M.lsp_references = setmetatable({
    name = "lsp_references",
    description = "Get LSP references for a symbol at the cursor or specified position",
    cmds = {
         function(self, args, _input)
            args = args or {}

           -- Validate arguments
           if args.line and type(args.line) ~= "number" then
               return self:error(nil, nil, "Invalid 'line' parameter: must be a number (0-based line number)")
           end
           if args.column and type(args.column) ~= "number" then
               return self:error(nil, nil, "Invalid 'column' parameter: must be a number (0-based column number)")
           end
           if args.file and type(args.file) ~= "string" then
               return self:error(nil, nil, "Invalid 'file' parameter: must be a string (file path)")
           end
           if args.line and args.line < 0 then
               return self:error(nil, nil, "Invalid 'line' parameter: must be >= 0 (0-based line number)")
           end
           if args.column and args.column < 0 then
               return self:error(nil, nil, "Invalid 'column' parameter: must be >= 0 (0-based column number)")
           end

            local file = args.file
            local line = args.line
            local column = args.column

            -- If no file specified, use current buffer
            if not file then
                file = vim.api.nvim_buf_get_name(0)
                if file == "" then
                    return self:error(nil, nil, "No file is currently open")
                end
            end

            -- If no position specified, use cursor position
            if not line or not column then
                local cursor = vim.api.nvim_win_get_cursor(0)
                line = cursor[1] - 1  -- Convert to 0-based
                column = cursor[2]
            end

            local references = lsp.get_references(file, line, column)
            return self:success("references", references, "LSP References")
        end,
    },
    schema = {
        type = "function",
        ["function"] = {
            name = "lsp_references",
            description = "Get LSP references for a symbol at the cursor or specified position",
            parameters = {
                type = "object",
                properties = {
                    file = {
                        type = "string",
                        description = "File path (uses current buffer if not specified)"
                    },
                    line = {
                        type = "number",
                        description = "Line number (0-based, uses cursor if not specified)"
                    },
                    column = {
                        type = "number",
                        description = "Column number (0-based, uses cursor if not specified)"
                    }
                },
                additionalProperties = false
            },
            strict = true
        }
    },
    output = BaseTool:create_output_handlers("LSP References")
}, BaseTool)

return M
