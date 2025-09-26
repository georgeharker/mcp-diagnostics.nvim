-- MCP Resources registration for mcphub.nvim integration

local M = {}

function M.register_all(mcphub, server_name, core, server_config)
  server_config = server_config or {}

  -- Current diagnostics resource
  mcphub.add_resource(server_name, {
    name = "current_diagnostics",
    uri = "diagnostics://current",
    description = "All current diagnostics from Neovim buffers",
    handler = function(_req, res)
      local diagnostics = core.get_all_diagnostics()
      return res:text(vim.json.encode(diagnostics), "application/json"):send()
    end
  })

  -- Diagnostic summary resource
  mcphub.add_resource(server_name, {
    name = "diagnostic_summary",
    uri = "diagnostics://summary",
    description = "Summary of diagnostic counts by severity",
    handler = function(_req, res)
      local summary = core.get_diagnostic_summary()
      return res:text(vim.json.encode(summary), "application/json"):send()
    end
  })

  -- Diagnostic errors resource
  mcphub.add_resource(server_name, {
    name = "diagnostic_errors",
    uri = "diagnostics://errors",
    description = "All error-level diagnostics",
    handler = function(_req, res)
      local errors = core.get_all_diagnostics(nil, "error")
      return res:text(vim.json.encode(errors), "application/json"):send()
    end
  })

  -- Diagnostic warnings resource
  mcphub.add_resource(server_name, {
    name = "diagnostic_warnings",
    uri = "diagnostics://warnings",
    description = "All warning-level diagnostics",
    handler = function(_req, res)
      local warnings = core.get_all_diagnostics(nil, "warn")
      return res:text(vim.json.encode(warnings), "application/json"):send()
    end
  })
end

return M