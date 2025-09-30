-- Base Variable Class for CodeCompanion Variables
-- Shared functionality for all mcp-diagnostics variables

local config = require("codecompanion.config")

local M = {}

---@class MCP.Variable.Base
local BaseVariable = {}
BaseVariable.__index = BaseVariable

---Create new variable instance
---@param args table Arguments passed from CodeCompanion
---@return table Variable instance
function BaseVariable.new(class, args)
    args = args or {}
    local obj = setmetatable({
        Chat = args.Chat,
        config = args.config,
        params = args.params,
        target = args.target,
    }, class)

    return obj
end

function BaseVariable:add_context(content)
    -- Only add context if Chat is available
    if self.Chat and self.Chat.add_message then
        -- Get USER_ROLE from CodeCompanion or fallback to 'user'
        local user_role = 'user'
        local cc_success, codecompanion = pcall(require, 'codecompanion')
        if cc_success and codecompanion.constants and codecompanion.constants.USER_ROLE then
            user_role = codecompanion.constants.USER_ROLE
        end

        self.Chat:add_message({
            role = user_role,
            content = content,
        }, { tag = "variable", visible = false })
    end
end

---Add an error message when no data is found
---@param message string The error message to display
function BaseVariable:add_no_data_message(message)
    self:add_context(message)
end

---Get the current buffer filepath
function BaseVariable:get_current_buffer()
    -- Safe access to Chat object with fallback
    local bufnr
    if self.Chat and self.Chat.buffer_context and self.Chat.buffer_context.bufnr then
        bufnr = self.Chat.buffer_context.bufnr
    else
        -- Fallback to current buffer when Chat context is not available
        bufnr = vim.api.nvim_get_current_buf()
    end
    local filepath = vim.api.nvim_buf_get_name(bufnr)
    return filepath, bufnr
end

---Get filepath for target (if specified) or current buffer
---@return string filepath The target file path
---@return number bufnr The buffer number
function BaseVariable:get_target_buffer()
    local filepath, bufnr = self:get_current_buffer()

    -- If a specific file target is provided, use that instead
    if self.target then
        local target_bufnr = vim.fn.bufnr(self.target)
        if target_bufnr ~= -1 then
            bufnr = target_bufnr
            filepath = self.target
        else
            -- Try to find by filename pattern
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_valid(buf) then
                    local buf_name = vim.api.nvim_buf_get_name(buf)
                    if buf_name:match(self.target .. "$") then
                        bufnr = buf
                        filepath = buf_name
                        break
                    end
                end
            end
        end
    end

    return filepath, bufnr
end

---Get short filename from path
---@param filepath string Full file path
---@return string Short filename
function BaseVariable:get_short_filename(filepath)
    return vim.fn.fnamemodify(filepath, ":t")
end

---Standard replace function for simple variable names
---@param prefix string The variable prefix (usually "#")
---@param message string The message content
---@param bufnr number The current buffer number
---@param variable_name string Name of the variable (e.g., "symbols")
---@param description string Human readable description
---@return string The message with variable references replaced
function BaseVariable:standard_replace(prefix, message, bufnr, variable_name, description)
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    local filename = self:get_short_filename(bufname)

    local pattern = prefix .. "{" .. variable_name .. "}"
    message = message:gsub(pattern, string.format("%s for `%s`", description, filename))

    return message
end

---Must be implemented by subclasses
---@abstract
function BaseVariable:output()
    error("BaseVariable:output() must be implemented by subclass")
end

 ---@param _prefix string The variable prefix
 ---@param _message string The message content
 ---@param _bufnr number The current buffer number
function BaseVariable.replace(_prefix, _message, _bufnr)
    error("BaseVariable.replace() must be implemented by subclass")
end

M.BaseVariable = BaseVariable

return M
