-- CodeCompanion Variable: Diagnostics
-- Usage: #{diagnostics} or #{diagnostics:filename}
-- Provides LSP diagnostics context for the current buffer or specified file

local base = require("mcp-diagnostics.codecompanion.variables.base")
local diagnostics = require("mcp-diagnostics.shared.diagnostics")

local BaseVariable = base.BaseVariable

---@class MCP.Variable.Diagnostics : MCP.Variable.Base
local Variable = setmetatable({}, { __index = BaseVariable })
Variable.__index = Variable

---@param args table
---@return MCP.Variable.Diagnostics
function Variable.new(args)
    return BaseVariable.new(Variable, args)
end

---Add diagnostics context to the chat message
---@return nil
function Variable:output()
    local filepath, bufnr = self:get_target_buffer()

    -- Get diagnostics for the target file
    local files = { filepath }
    local diagnostics_data = diagnostics.get_all_diagnostics(files)

    if not diagnostics_data or #diagnostics_data == 0 then
        self:add_no_data_message(string.format("No LSP diagnostics found for %s",
            self:get_short_filename(filepath)))
        return
    end

    -- Format diagnostics with code context
    local severity_map = {
        [1] = "ERROR",
        [2] = "WARNING",
        [3] = "INFORMATION",
        [4] = "HINT"
    }

    local formatted = {}
    for _, diagnostic in ipairs(diagnostics_data) do
        -- Get code context around the diagnostic
        local lines = {}
        local start_line = math.max(0, diagnostic.lnum - 1) -- 1 line before
        local end_line = math.min(vim.api.nvim_buf_line_count(bufnr) - 1, diagnostic.lnum + 1) -- 1 line after

        for i = start_line, end_line do
            local line_content = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1] or ""
            local marker = (i == diagnostic.lnum) and ">>> " or "    "
            table.insert(lines, string.format("%s%d: %s", marker, i + 1, line_content))
        end

        table.insert(formatted, string.format([[
File: %s
Line: %d, Column: %d
Severity: %s
Message: %s
Source: %s

Code Context:
```%s
%s
```]],
            self:get_short_filename(diagnostic.filename),
            diagnostic.lnum + 1,
            diagnostic.col + 1,
            severity_map[diagnostic.severity] or "UNKNOWN",
            diagnostic.message,
            diagnostic.source or "unknown",
            (self.Chat and self.Chat.buffer_context and self.Chat.buffer_context.filetype) or "text",
            table.concat(lines, "\n")
        ))
    end

    -- Add the formatted diagnostics as invisible context
    local content = string.format("Current LSP diagnostics for analysis:\n\n%s",
        table.concat(formatted, "\n" .. string.rep("-", 50) .. "\n"))

    self:add_context(content)
end

---Replace variable mentions in text (for when variable is referenced but not expanded)
---@param prefix string The variable prefix (usually "#")
---@param message string The message content
---@param bufnr number The current buffer number
---@return string The message with variable references replaced
function Variable.replace(prefix, message, bufnr)
    local short_filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")

    -- Handle #{diagnostics:filename}
    local pattern = prefix .. "{diagnostics:([^}]*)}"
    message = message:gsub(pattern, function(target)
        return string.format("LSP diagnostics for `%s`", target)
    end)

    -- Handle #{diagnostics}
    message = message:gsub(prefix .. "{diagnostics}", string.format("LSP diagnostics for `%s`", short_filename))

    return message
end

return Variable
