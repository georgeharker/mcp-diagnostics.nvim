-- CodeCompanion Variable: Buffer Status
-- Usage: #{buffers}
-- Provides context about all loaded buffers and their diagnostic counts

local base = require("mcp-diagnostics.codecompanion.variables.base")
local buffers = require("mcp-diagnostics.shared.buffers")

local BaseVariable = base.BaseVariable

---@class MCP.Variable.Buffers : MCP.Variable.Base
local Variable = setmetatable({}, { __index = BaseVariable })
Variable.__index = Variable

---@param args table
---@return MCP.Variable.Buffers
function Variable.new(args)
    return BaseVariable.new(Variable, args)
end

---Add buffer status context to the chat message
---@return nil
function Variable:output()
    -- Get buffer status information
    local buffer_status = buffers.get_buffer_status()

    if not buffer_status or #buffer_status == 0 then
        self:add_no_data_message("No buffers are currently loaded")
        return
    end

    -- Format buffer information
    local formatted_buffers = {}
    local total_diagnostics = 0

    for _, buf_info in ipairs(buffer_status) do
        local filename = self:get_short_filename(buf_info.filepath)
        local diagnostic_count = buf_info.diagnostic_count or 0
        total_diagnostics = total_diagnostics + diagnostic_count

        local status_line = string.format("- %s", filename)
        if diagnostic_count > 0 then
            status_line = status_line .. string.format(" (%d diagnostics)", diagnostic_count)
        end
        if buf_info.modified then
            status_line = status_line .. " [modified]"
        end
        if not buf_info.exists then
            status_line = status_line .. " [not saved]"
        end

        table.insert(formatted_buffers, status_line)
    end

    -- Create summary
    local summary = string.format("Currently have %d loaded buffers", #buffer_status)
    if total_diagnostics > 0 then
        summary = summary .. string.format(" with %d total diagnostics", total_diagnostics)
    end

    -- Add the formatted buffer status as invisible context
    local content = string.format([[%s:

%s

This shows all files currently loaded in the editor with their diagnostic status.]],
        summary,
        table.concat(formatted_buffers, "\n")
    )

    self:add_context(content)
end

---Replace variable mentions in text
---@param prefix string The variable prefix (usually "#")
---@param message string The message content
---@param _bufnr number The current buffer number (unused for this variable)
---@return string The message with variable references replaced
function Variable.replace(prefix, message, _bufnr)
    message = message:gsub(prefix .. "{buffers}", "currently loaded buffers")
    return message
end

return Variable