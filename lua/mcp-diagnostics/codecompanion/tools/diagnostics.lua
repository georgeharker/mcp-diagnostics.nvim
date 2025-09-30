local diagnostics = require("mcp-diagnostics.shared.diagnostics")
local base = require("mcp-diagnostics.codecompanion.tools.base")
local BaseTool = base.BaseTool

local M = {}
M.lsp_document_diagnostics = setmetatable({
    name = "lsp_document_diagnostics",
    description = "Get LSP diagnostics for the current document/buffer with enhanced error handling",
    cmds = {
        function(self, args, _input)
            args = args or {}

           -- Validate arguments
           if args.severity and type(args.severity) ~= "string" then
               return self:error(nil, nil, "Invalid 'severity' parameter: must be a string")
           end
           if args.severity and not vim.tbl_contains({ "error", "warn", "info", "hint" }, args.severity) then
               return self:error(nil, nil, "Invalid 'severity' parameter: must be one of 'error', 'warn', 'info', 'hint'")
           end
           if args.source and type(args.source) ~= "string" then
               return self:error(nil, nil, "Invalid 'source' parameter: must be a string (LSP server name)")
           end
           if args.file and type(args.file) ~= "string" then
               return self:error(nil, nil, "Invalid 'file' parameter: must be a string (file path)")
           end

            -- Optional parameters for filtering diagnostics
            local severity = args.severity
            local source = args.source
            local target_file = args.file

            local current_file

            -- If a specific file is requested, use that
            if target_file and target_file ~= "" then
                current_file = target_file
            else
                -- Get current buffer file
                current_file = vim.api.nvim_buf_get_name(0)
            end

            -- If we're in a CodeCompanion chat buffer, try to find a better buffer
            local current_buf = vim.api.nvim_get_current_buf()
            local current_buftype = vim.api.nvim_buf_get_option(current_buf, "buftype")
            local current_filetype = vim.api.nvim_buf_get_option(current_buf, "filetype")

            -- If current buffer is a chat buffer or has no file, find the most recent file buffer
            if
                current_file == ""
                or current_buftype ~= ""
                or current_filetype == "codecompanion"
            then
                -- Look for the most recently used buffer with a real file
                local _best_buf = nil
                local best_file = nil

                for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
                        local buf_name = vim.api.nvim_buf_get_name(buf)
                        local buf_type = vim.api.nvim_buf_get_option(buf, "buftype")
                        local buf_ft = vim.api.nvim_buf_get_option(buf, "filetype")

                        -- Skip special buffers (chat, help, etc.)
                        if
                            buf_name ~= ""
                            and buf_type == ""
                            and buf_ft ~= "codecompanion"
                            and buf_ft ~= "help"
                            and not buf_name:match("^%s*$")
                        then
                            -- This looks like a real file buffer
                            _best_buf = buf
                            best_file = buf_name
                            break -- Take the first valid one we find
                        end
                    end
                end

                if best_file then
                    current_file = best_file
                else
                    return self:error(nil, nil, "No file is currently open or available for analysis")
                end
            end

            if current_file == "" then
                return self:error(nil, nil, "No file is currently open or available for analysis")
            end

            -- ENHANCED: Validate file loading and LSP availability
            local lsp = require("mcp-diagnostics.shared.lsp")
            local bufnr, loaded, err = lsp.ensure_file_loaded(current_file)

            if not loaded then
                return self:error(nil, nil, string.format("Failed to load file: %s - %s", current_file, err or "Unknown error"))
            end

            -- ENHANCED: Check LSP availability and provide helpful error if none
            local lsp_available, lsp_error = self:validate_lsp_available(bufnr, current_file)
            if not lsp_available then
                -- Still try to get diagnostics, but warn about LSP
                local files = { current_file }
                local diagnostics_data = diagnostics.get_all_diagnostics(files, severity, source)

                -- If no diagnostics and no LSP, show helpful error
                if #diagnostics_data == 0 then
                    return self:format_lsp_error(bufnr, current_file, "No diagnostics available - this may be because no LSP server is running.")
                else
                    -- We have some diagnostics, show them with a warning
                    local warning_msg = string.format("⚠️ Limited diagnostics (LSP not available)\n📊 Found %d diagnostics from other sources\n\n", #diagnostics_data)
                    return self:success("diagnostics", diagnostics_data, warning_msg .. "Document Diagnostics")
                end
            end

            local files = { current_file }
            local diagnostics_data = diagnostics.get_all_diagnostics(files, severity, source)

            -- ENHANCED: Better success message with context
            local success_msg = string.format("LSP Document Diagnostics (%d found)", #diagnostics_data)
            return self:success("diagnostics", diagnostics_data, success_msg)
        end,
    },
    schema = {
        type = "function",
        ["function"] = {
            name = "lsp_document_diagnostics",
            description = "Get LSP diagnostics for the current document with enhanced error handling",
            parameters = {
                type = "object",
                properties = {
                    severity = {
                        type = "string",
                        enum = { "error", "warn", "info", "hint" },
                        description = "Filter by diagnostic severity level"
                    },
                    source = {
                        type = "string",
                        description = "Filter by LSP server name (e.g., 'pylsp', 'rust-analyzer')"
                    },
                    file = {
                        type = "string",
                        description = "Specific file to analyze (uses current buffer if not specified)"
                    }
                },
                additionalProperties = false
            },
            strict = true
        }
    },
    output = BaseTool:create_output_handlers("LSP Document Diagnostics Enhanced")
}, BaseTool)

return M
