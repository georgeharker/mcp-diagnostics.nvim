-- CodeCompanion Variable: Document Symbols
-- Usage: #{symbols}
-- Provides LSP document symbols context for the current buffer

local base = require("mcp-diagnostics.codecompanion.variables.base")
local lsp = require("mcp-diagnostics.shared.lsp")

local BaseVariable = base.BaseVariable

---@class MCP.Variable.Symbols : MCP.Variable.Base
local Variable = setmetatable({}, { __index = BaseVariable })
Variable.__index = Variable

---@param args table
---@return MCP.Variable.Symbols
function Variable.new(args)
    return BaseVariable.new(Variable, args)
end

---Add document symbols context to the chat message
---@return nil
function Variable:output()
    local filepath, _ = self:get_current_buffer()

    if filepath == "" then
        self:add_no_data_message("No file is currently open for symbol analysis")
        return
    end

    -- Get document symbols
    local symbols_data = lsp.get_document_symbols(filepath)

    if not symbols_data or #symbols_data == 0 then
        self:add_no_data_message(string.format("No document symbols found for %s",
            self:get_short_filename(filepath)))
        return
    end

    -- Format symbols hierarchically
    local kind_map = {
        [1] = "File", [2] = "Module", [3] = "Namespace", [4] = "Package",
        [5] = "Class", [6] = "Method", [7] = "Property", [8] = "Field",
        [9] = "Constructor", [10] = "Enum", [11] = "Interface", [12] = "Function",
        [13] = "Variable", [14] = "Constant", [15] = "String", [16] = "Number",
        [17] = "Boolean", [18] = "Array", [19] = "Object", [20] = "Key",
        [21] = "Null", [22] = "EnumMember", [23] = "Struct", [24] = "Event",
        [25] = "Operator", [26] = "TypeParameter"
    }

    local function format_symbol(symbol, indent)
        indent = indent or ""
        local name = symbol.name or "unnamed"
        local kind = kind_map[symbol.kind] or "Unknown"
        local line = 0

        if symbol.range and symbol.range.start then
            line = symbol.range.start.line + 1
        elseif symbol.selectionRange and symbol.selectionRange.start then
            line = symbol.selectionRange.start.line + 1
        end

        local result = string.format("%s- %s (%s) at line %d\n", indent, name, kind, line)

        -- Process children recursively
        if symbol.children then
            for _, child in ipairs(symbol.children) do
                result = result .. format_symbol(child, indent .. "  ")
            end
        end

        return result
    end

    local formatted_symbols = {}
    for _, symbol in ipairs(symbols_data) do
        table.insert(formatted_symbols, format_symbol(symbol))
    end

    -- Add the formatted symbols as invisible context
    local content = string.format([[Document structure for %s:

%s

This shows the hierarchical structure of symbols (functions, classes, variables, etc.) in the current file.]],
        self:get_short_filename(filepath),
        table.concat(formatted_symbols, "")
    )

    self:add_context(content)
end

---Replace variable mentions in text
---@param prefix string The variable prefix (usually "#")
---@param message string The message content
---@param bufnr number The current buffer number
---@return string The message with variable references replaced
function Variable.replace(prefix, message, bufnr)
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    local filename = vim.fn.fnamemodify(bufname, ":t")

    message = message:gsub(prefix .. "{symbols}", string.format("document symbols for `%s`", filename))

    return message
end

return Variable