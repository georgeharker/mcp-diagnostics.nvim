local M = {}

local default_opts = {
    enabled_tools = {
        -- Core LSP Tools (8 tools)
        "lsp_document_diagnostics",
        "lsp_diagnostics_summary",
        "diagnostic_hotspots",
        "diagnostic_stats",
        "diagnostic_by_severity",
        "lsp_hover",
        "lsp_definition",
        "lsp_references",
        "lsp_document_symbols",
        "lsp_workspace_symbols",
        "lsp_code_actions",

        -- File Management Tools (3 tools)
        "buffer_status",
        "ensure_files_loaded",
        "refresh_after_external_changes",
    },
    enabled_variables = {
        -- Context Variables (3 variables)
        "diagnostics",
        "symbols",
        "buffers",
        "diagnostic_summary",
    },
    max_diagnostics = 50,
    max_references = 20,
    show_source = true,
    auto_register = false,  -- Route 2: Enable automatic dynamic registration with CodeCompanion
    debug = false
}

--- Setup global CodeCompanion-related options without directly registering tools
--- This is for users who want to configure mcp-diagnostics before using the extension pattern
--- @param opts table|nil Configuration options
--- @return boolean success True if setup succeeded
function M.setup(opts)
    opts = vim.tbl_deep_extend("force", default_opts, opts or {})

    -- Store global options for extension use
    M._global_opts = opts

    -- Set flag for health checks
    vim.g.mcp_diagnostics_codecompanion_setup = true

    if opts.debug then
        vim.notify(
            string.format("[MCP Diagnostics] CodeCompanion mode setup completed (%d tools, %d variables). ",
                #opts.enabled_tools, #opts.enabled_variables) ..
            (opts.auto_register and "Auto-registration enabled." or
             "Remember to register the extension in CodeCompanion's config:\n" ..
             "extensions = { mcp_diagnostics = { callback = 'mcp-diagnostics.codecompanion.extension', opts = {} } }"),
            vim.log.levels.INFO
        )
    end

    -- Route 2: Dynamic registration if auto_register is enabled
    if opts.auto_register then
        local has_codecompanion, codecompanion = pcall(require, "codecompanion")
        if has_codecompanion and codecompanion.register_extension then
            -- Use dynamic registration
            codecompanion.register_extension("mcp_diagnostics", {
                callback = "mcp-diagnostics.codecompanion.extension",
                opts = opts
            })
            if opts.debug then
                vim.notify("[MCP Diagnostics] Dynamically registered extension with CodeCompanion", vim.log.levels.INFO)
            end
        else
            if opts.debug then
                vim.notify("[MCP Diagnostics] auto_register=true but CodeCompanion not available or doesn't support register_extension", vim.log.levels.ERROR)
            end
        end
    end

    return true
end

return M
