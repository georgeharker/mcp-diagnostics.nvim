-- CodeCompanion Variable: Diagnostic Summary
-- Usage: #{diagnostic_summary}
-- Provides overall diagnostic statistics and overview context

local base = require("mcp-diagnostics.codecompanion.variables.base")
local diagnostics = require("mcp-diagnostics.shared.diagnostics")

local BaseVariable = base.BaseVariable

---@class MCP.Variable.DiagnosticSummary : MCP.Variable.Base
local Variable = setmetatable({}, { __index = BaseVariable })
Variable.__index = Variable

---@param args table
---@return MCP.Variable.DiagnosticSummary
function Variable.new(args)
    return BaseVariable.new(Variable, args)
end

---Add diagnostic summary context to the chat message
---@return nil
function Variable:output()
    -- Get comprehensive diagnostic summary
    local summary = diagnostics.get_diagnostic_summary()

    if summary.total == 0 then
        self:add_no_data_message("No LSP diagnostics found in any open buffers")
        return
    end

    -- Format the summary
    local content = string.format([[Current diagnostic overview:

Total diagnostics: %d
- Errors: %d
- Warnings: %d
- Information: %d
- Hints: %d

Affected files: %d

Files with issues:]],
        summary.total,
        summary.errors,
        summary.warnings,
        summary.info,
        summary.hints,
        summary.files
    )

    -- Add file breakdown
    local file_lines = {}
    for filename, counts in pairs(summary.byFile) do
        local file_total = counts.errors + counts.warnings + counts.info + counts.hints
        local short_name = self:get_short_filename(filename)
        table.insert(file_lines, string.format("- %s: %d total (%d errors, %d warnings)",
            short_name, file_total, counts.errors, counts.warnings))
    end

    if #file_lines > 0 then
        content = content .. "\n" .. table.concat(file_lines, "\n")
    end

    -- Add source breakdown if multiple sources
    if vim.tbl_count(summary.bySource) > 1 then
        content = content .. "\n\nDiagnostic sources:"
        local source_lines = {}
        for source, count in pairs(summary.bySource) do
            table.insert(source_lines, string.format("- %s: %d", source, count))
        end
        content = content .. "\n" .. table.concat(source_lines, "\n")
    end

    self:add_context(content)
end

---Replace variable mentions in text
---@param prefix string The variable prefix (usually "#")
---@param message string The message content
---@param _bufnr number The current buffer number (unused for this variable)
---@return string The message with variable references replaced
function Variable.replace(prefix, message, _bufnr)
    message = message:gsub(prefix .. "{diagnostic_summary}", "diagnostic overview")
    return message
end

return Variable