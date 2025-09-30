-- CodeCompanion Variables Catalog for mcp-diagnostics
-- These variables provide contextual data injection into chat messages

local M = {}

-- Available variables with their configurations
M.diagnostics = {
    callback = "mcp-diagnostics.codecompanion.variables.diagnostics",
    description = "Add LSP diagnostics context for current buffer or specified file",
    opts = {
        contains_code = true,
        has_params = false,
    },
}

M.symbols = {
    callback = "mcp-diagnostics.codecompanion.variables.symbols",
    description = "Add document symbols context for current buffer",
    opts = {
        contains_code = true,
        has_params = false,
    },
}

M.buffers = {
    callback = "mcp-diagnostics.codecompanion.variables.buffers",
    description = "Add buffer status and loaded files context",
    opts = {
        contains_code = false,
        has_params = false,
    },
}

M.diagnostic_summary = {
    callback = "mcp-diagnostics.codecompanion.variables.diagnostic_summary",
    description = "Add overall diagnostic statistics and overview context",
    opts = {
        contains_code = false,
        has_params = false,
    },
}

function M.get_variables()
    return {
        diagnostics = M.diagnostics,
        symbols = M.symbols,
        buffers = M.buffers,
        diagnostic_summary = M.diagnostic_summary,
    }
end

return M
