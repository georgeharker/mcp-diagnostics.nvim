-- mcphub.nvim Integration for MCP Diagnostics
-- Native Lua MCP server integration with mcphub.nvim

local M = {}

local default_config = {
    server_name = "mcp-diagnostics",
    displayName = "Neovim Diagnostics & LSP",
    debug = false,
    auto_approve = false, -- Automatically approve tool execution requests (mcphub.nvim autoApprove)
    lsp_timeout = 1000,
    enable_diagnostics = true,
    enable_lsp = true,
    enable_prompts = true,
    auto_register = true,
    auto_reload_files = true, -- Automatically reload files when they change on disk
}

function M.get_config()
    return rawget(_G, "_mcp_diagnostics_mcphub_config")
end

-- Main setup function with unified configuration options
function M.setup(user_config)
    user_config = user_config or {}
    local config = vim.tbl_deep_extend("force", default_config, user_config)

    -- Store config globally for other modules
    _G._mcp_diagnostics_mcphub_config = config

    -- Validate mcphub availability
    local has_mcphub, mcphub = pcall(require, "mcphub")
    if not has_mcphub then
        local msg =
            "[MCP Diagnostics] mcphub.nvim is required but not found. Please install it first."
        vim.notify(msg, vim.log.levels.ERROR)
        return false
    end

    if config.debug then
        vim.notify(
            "[MCP Diagnostics] Starting mcphub setup with config: " .. vim.inspect(config),
            vim.log.levels.DEBUG
        )
    end

    -- Load core functionality
    local core = require("mcp-diagnostics.mcphub.core")

    -- Set up cleanup autocmd for file watchers
    vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
            core.cleanup_all_watchers()
        end,
        desc = "Cleanup MCP diagnostics file watchers on exit",
    })

    -- Auto-register with mcphub if requested
    if config.auto_register then
        M.register_with_mcphub(mcphub, config)
    end

    if config.debug then
        vim.notify("[MCP Diagnostics] mcphub setup complete", vim.log.levels.DEBUG)
    end

    return true
end

-- Convenience setup functions with preset configurations
function M.quick()
    return M.setup()
end

function M.auto_approve()
    return M.setup({ auto_approve = true })
end

function M.debug()
    return M.setup({ debug = true })
end

function M.minimal()
    return M.setup({
        enable_lsp = false,
        enable_prompts = false,
    })
end

function M.no_auto_reload()
    return M.setup({ auto_reload_files = false })
end

-- Check plugin status and configuration
function M.check_status()
    vim.notify(
        "Use :checkhealth mcp-diagnostics for comprehensive status information",
        vim.log.levels.INFO
    )
    vim.cmd("checkhealth mcp-diagnostics")
end

function M.register_with_mcphub(mcphub, config)
    local tools = require("mcp-diagnostics.mcphub.tools")
    local resources = require("mcp-diagnostics.mcphub.resources")
    local prompts = require("mcp-diagnostics.mcphub.prompts")

    local success, result = pcall(function()
        -- Register tools (this will create the server automatically)
        if config.enable_diagnostics or config.enable_lsp then
            tools.register_all(mcphub, config.server_name, config)
        end

        -- Register resources
        if config.enable_diagnostics then
            resources.register_all(mcphub, config.server_name, config)
        end

        -- Register prompts
        if config.enable_prompts then
            prompts.register_all(mcphub, config.server_name, config)
        end

        return true
    end)

    if not success then
        vim.notify(
            string.format("[MCP Diagnostics] Failed to register server: %s", tostring(result)),
            vim.log.levels.ERROR,
            { title = "MCPHub" }
        )
        return false
    end

    local approve_msg = config.auto_approve and " (auto-approve enabled)" or ""
    local reload_msg = config.auto_reload_files and " (auto-reload enabled)" or ""
    if config.debug then
        vim.notify(
            string.format(
                "[MCP Diagnostics] Registered '%s' with mcphub.nvim%s%s",
                config.displayName,
                approve_msg,
                reload_msg
            ),
            vim.log.levels.INFO
        )
    end

    return true
end

return M
