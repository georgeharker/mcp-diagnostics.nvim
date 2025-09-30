-- Debug test tool for troubleshooting CodeCompanion integration

local base = require("mcp-diagnostics.codecompanion.tools.base")
local BaseTool = base.BaseTool

local M = {}

-- Simple test tool that always returns consistent data
M.debug_test = setmetatable({
    name = "debug_test",
    description = "Simple debug tool to test CodeCompanion integration",
    cmds = {
        function(self, args, _input)
            local test_data = {
                message = "Debug tool executed successfully",
                timestamp = os.date("%Y-%m-%d %H:%M:%S"),
                args_received = args or {},
                vim_diagnostic_available = vim.diagnostic ~= nil,
                current_buf = vim.api.nvim_get_current_buf(),
                buf_name = vim.api.nvim_buf_get_name(0),
                lsp_client_count = #vim.lsp.get_clients(),
            }

            -- Test getting diagnostics
            local all_diags = vim.diagnostic.get()
            test_data.total_diagnostics = #all_diags

            -- Test current buffer diagnostics
            local current_diags = vim.diagnostic.get(0)
            test_data.current_buffer_diagnostics = #current_diags

            return self:success("llm", test_data, "Debug Test Results")
        end,
    },
    schema = {
        type = "function",
        ["function"] = {
            name = "debug_test",
            description = "Simple debug tool to test CodeCompanion integration",
            parameters = {
                type = "object",
                properties = {
                    test_param = {
                        type = "string",
                        description = "Optional test parameter",
                    },
                },
                additionalProperties = false
            },
            strict = true
        }
    },
    output = BaseTool:create_output_handlers("Debug Test")
}, { __index = BaseTool })

return M
