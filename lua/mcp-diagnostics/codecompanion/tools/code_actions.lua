
local lsp = require("mcp-diagnostics.shared.lsp")
local base = require("mcp-diagnostics.codecompanion.tools.base")
local BaseTool = base.BaseTool

local M = {}
M.lsp_code_actions = setmetatable({
    name = "lsp_code_actions",
    description = "Get available code actions for the cursor or specified position/range",
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
           if args.end_line and type(args.end_line) ~= "number" then
               return self:error(nil, nil, "Invalid 'end_line' parameter: must be a number (0-based line number)")
           end
           if args.end_column and type(args.end_column) ~= "number" then
               return self:error(nil, nil, "Invalid 'end_column' parameter: must be a number (0-based column number)")
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
           if args.end_line and args.end_line < 0 then
               return self:error(nil, nil, "Invalid 'end_line' parameter: must be >= 0 (0-based line number)")
           end
           if args.end_column and args.end_column < 0 then
               return self:error(nil, nil, "Invalid 'end_column' parameter: must be >= 0 (0-based column number)")
           end
           -- Validate range consistency
           if args.line and args.end_line and args.end_line < args.line then
               return self:error(nil, nil, "Invalid range: end_line must be >= line")
           end
           if args.line and args.end_line and args.line == args.end_line and args.column and args.end_column and args.end_column < args.column then
               return self:error(nil, nil, "Invalid range: end_column must be >= column when on same line")
           end

            local file = args.file
            local line = args.line
            local column = args.column
            local end_line = args.end_line
            local end_column = args.end_column

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

            local actions = lsp.get_code_actions(file, line, column, end_line, end_column)
            return self:success("llm", actions, "LSP Code Actions")
        end,
    },
    schema = {
        type = "function",
        ["function"] = {
            name = "lsp_code_actions",
            description = "Get available code actions for the cursor or specified position/range",
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
                    },
                    end_line = {
                        type = "number",
                        description = "End line number for range selection (0-based, optional)"
                    },
                    end_column = {
                        type = "number",
                        description = "End column number for range selection (0-based, optional)"
                    }
                },
                additionalProperties = false
            },
            strict = true
        }
    },
    output = BaseTool:create_output_handlers("LSP Code Actions")
}, { __index = BaseTool })

return M
