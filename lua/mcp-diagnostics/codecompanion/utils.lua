-- Utility functions for CodeCompanion integration
-- Provides helpers for tool execution and data formatting

local M = {}

--- Format LSP locations for display
--- @param locations table List of LSP location objects
--- @return string Formatted string representation
function M.format_locations(locations)
    if not locations or #locations == 0 then
        return "No locations found"
    end

    local formatted = {}
    for i, location in ipairs(locations) do
        local file = location.uri and vim.uri_to_fname(location.uri) or location.filename or "unknown"
        local range = location.range or location
        local line = range.start and range.start.line or range.line or 0
        local col = range.start and range.start.character or range.column or 0

        table.insert(formatted, string.format("%d. %s:%d:%d", i, file, line + 1, col + 1))
    end

    return table.concat(formatted, "\n")
end

--- Format diagnostic hotspots for display
--- @param hotspots table List of problematic file objects
--- @return string Formatted string representation
function M.format_diagnostic_hotspots(hotspots)
    if not hotspots or #hotspots == 0 then
        return "No problematic files found"
    end

    local formatted = {}
    for i, file in ipairs(hotspots) do
        local filename = vim.fn.fnamemodify(file.filename, ":t")
        table.insert(formatted, string.format(
            "%d. %s - Score: %.1f (Errors: %d, Warnings: %d, Total: %d)",
            i, filename, file.score, file.errors, file.warnings, file.total
        ))
    end

    return table.concat(formatted, "\n")
end

--- Format diagnostic statistics for display
--- @param stats table Diagnostic statistics object
--- @return string Formatted string representation
function M.format_diagnostic_stats(stats)
    if not stats then
        return "No diagnostic statistics available"
    end

    local lines = {}

    -- Overall summary
    local s = stats.summary
    table.insert(lines, string.format("=== DIAGNOSTIC OVERVIEW ==="))
    table.insert(lines, string.format("Total: %d diagnostics across %d files", s.total, s.files))
    table.insert(lines, string.format("Errors: %d | Warnings: %d | Info: %d | Hints: %d",
        s.errors, s.warnings, s.info, s.hints))

    -- Top error patterns
    if stats.error_patterns then
        table.insert(lines, "\n=== TOP ERROR PATTERNS ===")
        local patterns = {}
        for pattern, count in pairs(stats.error_patterns) do
            table.insert(patterns, {pattern = pattern, count = count})
        end
        table.sort(patterns, function(a, b) return a.count > b.count end)

        for i, p in ipairs(vim.list_slice(patterns, 1, 10)) do
            table.insert(lines, string.format("%d. %s: %d occurrences", i, p.pattern, p.count))
        end
    end

    -- Source analysis
    if stats.source_analysis then
        table.insert(lines, "\n=== SOURCE ANALYSIS ===")
        for source, analysis in pairs(stats.source_analysis) do
            table.insert(lines, string.format("%s: %d total (%d errors, %d warnings)",
                source, analysis.total, analysis.errors, analysis.warnings))
        end
    end

    -- Top problematic files
    if stats.problematic_files and #stats.problematic_files > 0 then
        table.insert(lines, "\n=== MOST PROBLEMATIC FILES ===")
        table.insert(lines, M.format_diagnostic_hotspots(stats.problematic_files))
    end

    return table.concat(lines, "\n")
end

--- @param diagnostics table List of diagnostic objects
--- @return string Formatted string representation
function M.format_diagnostics(diagnostics)
    if not diagnostics or #diagnostics == 0 then
        return "No diagnostics found"
    end

    local severity_map = {
        [1] = "ERROR",
        [2] = "WARN",
        [3] = "INFO",
        [4] = "HINT"
    }

    local formatted = {}
    for i, diagnostic in ipairs(diagnostics) do
        local severity = severity_map[diagnostic.severity] or "UNKNOWN"
        local file = diagnostic.filename or "unknown"
        local line = (diagnostic.lnum or diagnostic.line or 0) + 1
        local col = (diagnostic.col or diagnostic.column or 0) + 1
        local message = diagnostic.message or "No message"
        local source = diagnostic.source and (" [" .. diagnostic.source .. "]") or ""

        table.insert(formatted, string.format(
            "%d. %s:%d:%d %s: %s%s",
            i, file, line, col, severity, message, source
        ))
    end

    return table.concat(formatted, "\n")
end

--- Format symbols for display
--- @param symbols table List of symbol objects
--- @return string Formatted string representation
function M.format_symbols(symbols)
    if not symbols or #symbols == 0 then
        return "No symbols found"
    end

    local kind_map = {
        [1] = "File", [2] = "Module", [3] = "Namespace", [4] = "Package",
        [5] = "Class", [6] = "Method", [7] = "Property", [8] = "Field",
        [9] = "Constructor", [10] = "Enum", [11] = "Interface", [12] = "Function",
        [13] = "Variable", [14] = "Constant", [15] = "String", [16] = "Number",
        [17] = "Boolean", [18] = "Array", [19] = "Object", [20] = "Key",
        [21] = "Null", [22] = "EnumMember", [23] = "Struct", [24] = "Event",
        [25] = "Operator", [26] = "TypeParameter"
    }

    local formatted = {}
    for i, symbol in ipairs(symbols) do
        local name = symbol.name or "unnamed"
        local kind = kind_map[symbol.kind] or "Unknown"
        local location = symbol.location
        local file = "unknown"
        local line = 0

        if location then
            if location.uri then
                file = vim.uri_to_fname(location.uri)
            elseif location.filename then
                file = location.filename
            end

            if location.range and location.range.start then
                line = location.range.start.line + 1
            elseif location.line then
                line = location.line + 1
            end
        end

        table.insert(formatted, string.format(
            "%d. %s (%s) - %s:%d",
            i, name, kind, file, line
        ))
    end

    return table.concat(formatted, "\n")
end

--- Get current cursor position info for LSP calls
--- @return table|nil Cursor position with file, line, column
function M.get_cursor_position()
    local bufnr = vim.api.nvim_get_current_buf()
    local filename = vim.api.nvim_buf_get_name(bufnr)

    if filename == "" then
        return nil
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1] - 1  -- Convert to 0-based
    local col = cursor[2]       -- Already 0-based

    return {
        file = filename,
        line = line,
        column = col
    }
end

--- Execute an LSP tool with current cursor position
--- @param tool_name string Name of the tool to execute
--- @param extra_args table|nil Additional arguments
--- @return any Tool execution result
function M.execute_at_cursor(tool_name, extra_args)
    local tools = require("mcp-diagnostics.codecompanion.tools")
    local tool = tools[tool_name]

    if not tool then
        return { error = true, message = "Tool not found: " .. tool_name }
    end

    local position = M.get_cursor_position()
    if not position then
        return { error = true, message = "No file open or cursor position unavailable" }
    end

    local args = vim.tbl_extend("force", position, extra_args or {})
    return tool:execute(args)
end

--- Create a user command for quick tool access
--- @param tool_name string Name of the tool
--- @param command_name string Neovim command name
function M.create_user_command(tool_name, command_name)
    vim.api.nvim_create_user_command(command_name, function(opts)
        local result = M.execute_at_cursor(tool_name, opts.args and { query = opts.args } or {})

        if result.error then
            vim.notify("Error: " .. result.message, vim.log.levels.ERROR)
        else
            -- Display result in a new buffer or quickfix list
            M.display_result(result, tool_name)
        end
    end, {
        nargs = "?",
        desc = "Execute " .. tool_name .. " at cursor position"
    })
end

function M.display_result(result, tool_name)
    local content

    if tool_name == "lsp_document_diagnostics" or tool_name == "lsp_diagnostics_summary" then
        content = M.format_diagnostics(result)
    elseif tool_name == "lsp_definition" or tool_name == "lsp_references" then
        content = M.format_locations(result)
    elseif tool_name == "lsp_document_symbols" or tool_name == "lsp_workspace_symbols" then
        content = M.format_symbols(result)
    elseif tool_name == "lsp_hover" then
        content = result.contents or vim.inspect(result)
    else
        content = vim.inspect(result)
    end

    -- Create a scratch buffer to display the result
    local buf = vim.api.nvim_create_buf(false, true)
    local lines = vim.split(content, "\n")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("filetype", "text", { buf = buf })
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })

    -- Open in a split
    vim.cmd("split")
    vim.api.nvim_win_set_buf(0, buf)
end

--- @class McpDiagnosticsFormatResult
--- @field summary string human readable string
--- @field formatted string human readable string
--- @field llm_output any data from tool for llm

--- @class McpDiagnosticsOutputResult
--- @field status string "error"|"success" Indicates if there was an error
--- @field data McpDiagnosticsFormatResult Formatted result data

--- @param tool_name string name of tool
--- @param status string tool succcess "error"|"success"
--- @param datatype string? which datatype is data
--- @param data table Raw data from tool
--- @param summary string Human readable summary to be added to output
--- @return table McpDiagnosticsResult
function M.format_tool_output(tool_name, status, datatype, data, summary)
    local content
    local llm_content = nil
    -- Handle different data types appropriately
    if datatype ~= nil and type(data) == "table" then
        -- Check if it's a list of diagnostics
        if datatype == "diagnostics" then
            content = M.format_diagnostics(data)
        -- Check if it's diagnostic hotspots (problematic files)
        elseif datatype == "hotspots" then
            content = M.format_diagnostic_hotspots(data)
        -- Check if it's diagnostic statistics
        elseif datatype == "diagnostic_stats" then
            content = M.format_diagnostic_stats(data)
        -- Check if it's a list of locations
        elseif datatype == "location" then
            content = M.format_locations(data)
        -- Check if it's a list of symbols
        elseif datatype == "symbols" then
            content = M.format_symbols(data)
        -- Check if it's a references result with metadata
        elseif datatype == "references" then
            local ref_content = M.format_locations(data.references)
            if data.truncated then
                ref_content = ref_content .. string.format("\n\n(Showing %d of %d references)", #data.references, data.total_count)
            end
            content = ref_content
        -- Check if it's LLM-only data (don't show raw data to user)
        elseif datatype == "llm" then
            content = nil  -- Don't append raw data for LLM-only content
            llm_content = vim.fn.json_encode(data)
        else
            -- Fallback to vim.inspect for complex objects
            content = vim.inspect(data)
        end
    elseif type(data) == "string" then
        content = data
    else
        content = tostring(data)
    end

    -- for now nothing returns explicit llm only results
    return {
        data = {
            summary = summary or "",
            llm_output = llm_content,
            formatted = content,
        },
        status = "success"
    }
end

return M
