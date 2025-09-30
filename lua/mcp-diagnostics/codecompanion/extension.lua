-- CodeCompanion Extension Callback Module for mcp-diagnostics
-- This module is called by CodeCompanion when the extension is loaded
-- Following the pattern: callback = "mcp-diagnostics.codecompanion.extension"

local default_opts = {
    enabled_tools = {
        -- Debug Tools (for troubleshooting)
        "debug_test",

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
}

local Extension = {}

--- Create tool handler for mcp-diagnostics tools
---@param tool_def table The tool definition from tools_catalog
---@param tool_name string The tool name
---@param opts table Extension options
---@return function Handler function for CodeCompanion
local function create_tool_handler(tool_def, tool_name, opts)
    return function(agent, args, input)
        -- Add debug notification for tool execution
        vim.notify(
            string.format(
                "[MCP Debug] Executing tool: %s with args: %s",
                tool_name,
                vim.inspect(args)
            ),
            vim.log.levels.INFO
        )

        -- Set up the tool instance with options
        if tool_def.setup then
            tool_def:setup(opts)
        end

        -- Execute the first command (tools typically have one command)
        local cmd_func = tool_def.cmds and tool_def.cmds[1]
        if not cmd_func then
            local error_msg = "Error: Tool " .. tool_name .. " has no command function"
            vim.notify(error_msg, vim.log.levels.ERROR)
            return error_msg
        end

        -- Call the command with the tool as self
        local result = cmd_func(agent, args, input)
        --local ok, result = pcall(cmd_func, tool_def, args, nil)

        if result == nil or result.status ~= "success" then
            local error_msg = "Error executing " .. tool_name .. ": " .. tostring(result)
            vim.notify(error_msg, vim.log.levels.ERROR)
            return error_msg
        end

        -- Debug logging for result
        vim.notify(
            string.format(
                "[MCP Debug] Tool %s result %s - type: %s, status: %s",
                tool_name,
                vim.inspect(result),
                type(result),
                type(result) == "table" and result.status or "N/A"
            ),
            vim.log.levels.DEBUG
        )

        -- Handle result formatting
        if type(result) == "table" then
            if result.status == "success" then
                local data = result.data
                if data == nil or type(data) ~= "string" or data == "" then
                    local fallback_msg = string.format(
                        "Tool '%s' executed successfully but found no data.\n\n"
                            .. "This could mean:\n"
                            .. "• No LSP servers are currently running\n"
                            .. "• No diagnostics or issues found (clean code!)\n"
                            .. "• File may not be loaded in a buffer\n"
                            .. "• LSP server hasn't finished analyzing the file\n\n"
                            .. "Try:\n"
                            .. "• Opening a file with some syntax errors\n"
                            .. "• Checking if LSP is active with :LspInfo\n"
                            .. "• Running :lua vim.diagnostic.get() to see raw diagnostics",
                        tool_name
                    )
                    vim.notify(
                        "[MCP Debug] Returning fallback message (no data)",
                        vim.log.levels.WARN
                    )
                    return fallback_msg
                end
            elseif result.status == "error" then
                return result
            else
                return result
            end
        else
            return result
        end
    end
end

--- Create static MCP diagnostics tools group
---@param opts table Extension options
---@return table Tools structure with groups
function Extension.create_diagnostic_tools_group(opts)
    -- Get tool definitions
    local tool_definitions = require("mcp-diagnostics.codecompanion.tools_catalog")

    local tools = {
        groups = {
            mcp_diagnostics = {
                id = "mcp_diagnostics:group",
                description = " LSP and Diagnostics tools for analyzing code:\n\n" .. table.concat(
                    vim.tbl_map(function(name)
                        return " - `" .. name .. "`"
                    end, opts.enabled_tools),
                    "\n"
                ),
                hide_in_help_window = false,
                system_prompt = function(_)
                    return "You have access to LSP and diagnostics tools for analyzing code. "
                        .. "Use these tools to inspect code health, find issues, and navigate symbols."
                end,
                tools = {},
                opts = {
                    -- collapse_tools = true,
                },
            },
        },
    }

    -- Add tools to CodeCompanion's config.strategies.chat.tools
    for _, tool_name in ipairs(opts.enabled_tools) do
        local tool_def = tool_definitions[tool_name]
        if tool_def then
            -- Add to group's tool list
            table.insert(tools.groups.mcp_diagnostics.tools, tool_name)

            -- Add individual tool
            tools[tool_name] = {
                id = "mcp_diagnostics:" .. tool_name,
                description = tool_def.description or ("LSP tool: " .. tool_name),
                hide_in_help_window = false,
                visible = true,
                callback = {
                    name = tool_name,
                    cmds = { create_tool_handler(tool_def, tool_name, opts) },
                    system_prompt = function()
                        return string.format(
                            "You can use the %s tool to %s\n",
                            tool_name,
                            tool_def.description or "perform LSP operations"
                        )
                    end,
                    schema = tool_def.schema
                        or {
                            type = "function",
                            ["function"] = {
                                name = tool_name,
                                description = tool_def.description or ("LSP tool: " .. tool_name),
                                parameters = {
                                    type = "object",
                                    properties = {},
                                    additionalProperties = true,
                                },
                            },
                        },
                },
            }
        else
            vim.notify(
                string.format(
                    "[MCP Diagnostics] Warning: Tool definition not found for '%s'",
                    tool_name
                ),
                vim.log.levels.WARN
            )
        end
    end

    return tools
end

--- Setup function called by CodeCompanion when extension is loaded
--- @param extension_opts table Options from CodeCompanion extension config
function Extension.setup(extension_opts)
    extension_opts = extension_opts or {}

    -- Get global options if setup was called
    local codecompanion_module = require("mcp-diagnostics.codecompanion")
    local global_opts = codecompanion_module._global_opts or {}

    -- Merge: default_opts <- global_opts <- extension_opts (in priority order)
    local opts = vim.tbl_deep_extend("force", default_opts, global_opts, extension_opts)

    -- Set flag for health checks
    vim.g.mcp_diagnostics_codecompanion_setup = true

    vim.notify(
        string.format(
            "[MCP Diagnostics] Extension setup initiated with %d tools including debug_test",
            #opts.enabled_tools
        ),
        vim.log.levels.INFO
    )

    -- Get CodeCompanion config
    local ok, config = pcall(require, "codecompanion.config")
    if not ok then
        vim.notify(
            "[MCP Diagnostics] Error: Could not load CodeCompanion config",
            vim.log.levels.ERROR
        )
        return
    end

    -- Ensure tools structure exists
    if not config.strategies or not config.strategies.chat or not config.strategies.chat.tools then
        vim.notify(
            "[MCP Diagnostics] Warning: Could not access CodeCompanion tools config",
            vim.log.levels.WARN
        )
        return
    end

    local tool_definitions = require("mcp-diagnostics.codecompanion.tools_catalog")

    -- Add tools to CodeCompanion's config.strategies.chat.tools
    if config.strategies and config.strategies.chat and config.strategies.chat.tools then
        for _, tool_name in ipairs(opts.enabled_tools) do
            local tool_def = tool_definitions[tool_name]
            if tool_def then
                -- Register tool with CodeCompanion's format: callback + description + opts
                -- Create a copy that preserves metatable inheritance
                local tool_copy = {}
                for k, v in pairs(tool_def) do
                    tool_copy[k] = v
                end
                -- Preserve the metatable to keep BaseTool inheritance
                setmetatable(tool_copy, getmetatable(tool_def))
                -- Set the options
                tool_copy.opts = opts

                -- Bind functions to self since CodeCompanion calls them without self parameter
                if tool_copy.cmds then
                    local bound_cmds = {}
                    for i, cmd in ipairs(tool_copy.cmds) do
                        bound_cmds[i] = function(args, input)
                            return cmd(tool_copy, args, input)
                        end
                    end
                    tool_copy.cmds = bound_cmds
                end

                -- Register tool with direct callback object like MCPHub
                config.strategies.chat.tools[tool_name] = {
                    id = "mcp_diagnostics:" .. tool_name,
                    visible = true,
                    hide_in_help_window = false,
                    callback = tool_copy, -- Direct object, not function
                    description = tool_def.description,
                    opts = {},
                }
            end
        end

        vim.notify(
            string.format(
                "[MCP Diagnostics] Extension setup completed - %d tools registered",
                #opts.enabled_tools
            ),
            vim.log.levels.INFO
        )
    else
        vim.notify(
            "[MCP Diagnostics] Warning: Could not access CodeCompanion tools config",
            vim.log.levels.WARN
        )
    end

    vim.notify(
        string.format(
            "[MCP Diagnostics] Extension setup completed - %d tools registered in group (including debug_test)",
            #opts.enabled_tools
        ),
        vim.log.levels.INFO
    )

    -- Register variables if they exist
    local variable_definitions_ok, variable_definitions =
        pcall(require, "mcp-diagnostics.codecompanion.variables_catalog")
    if variable_definitions_ok and variable_definitions.get_variables then
        local variables = variable_definitions.get_variables()
        local registered_variables = 0

        for variable_name, variable_def in pairs(variables) do
            if vim.tbl_contains(opts.enabled_variables, variable_name) then
                -- Update the callback path to point to our variables
                local updated_def = vim.deepcopy(variable_def)
                updated_def.callback = "mcp-diagnostics.codecompanion.variables." .. variable_name

                -- Register variable
                config.strategies.chat.variables[variable_name] = updated_def
                registered_variables = registered_variables + 1
            end
        end

        if registered_variables > 0 then
            vim.notify(
                string.format(
                    "[MCP Diagnostics] %d variables registered: %s",
                    registered_variables,
                    table.concat(opts.enabled_variables, ", ")
                ),
                vim.log.levels.INFO
            )
        end
    end
end

Extension.exports = {
    get_tool_count = function()
        local codecompanion_module = require("mcp-diagnostics.codecompanion")
        local opts = codecompanion_module._global_opts or default_opts
        return #opts.enabled_tools
    end,
    get_enabled_tools = function()
        local codecompanion_module = require("mcp-diagnostics.codecompanion")
        local opts = codecompanion_module._global_opts or default_opts
        return opts.enabled_tools
    end,
    get_variable_count = function()
        local codecompanion_module = require("mcp-diagnostics.codecompanion")
        local opts = codecompanion_module._global_opts or default_opts
        return #(opts.enabled_variables or {})
    end,
    get_enabled_variables = function()
        local codecompanion_module = require("mcp-diagnostics.codecompanion")
        local opts = codecompanion_module._global_opts or default_opts
        return opts.enabled_variables or {}
    end,
}

return Extension

