-- Example extra configuration for MCP Diagnostics

return {
  -- MCPHub mode configuration
  mcphub = {
    server_name = "mcp-diagnostics-extra",
    displayName = "Extra Neovim Diagnostics & LSP",
    debug = true, -- Enable for development

    -- File reload behavior when external changes detected
    auto_reload_mode = "ask", -- Options: "reload", "ask", "none"
    -- "reload" - Automatically reload changed files
    -- "ask" - Prompt user for each changed file
    -- "none" - Don't reload, just warn about stale data

    -- LSP notification behavior for file operations
    lsp_notify_mode = "auto", -- Options: "auto", "manual", "disabled"
    -- "auto" - Automatically notify LSP of file open/close/change
    -- "manual" - Only notify when explicitly requested
    -- "disabled" - Never notify LSP (may cause stale diagnostics)

    -- File deletion handling behavior
    file_deletion_mode = "prompt", -- Options: "ignore", "prompt", "auto"
    -- "ignore" - Only disconnect LSP, don't touch buffer
    -- "prompt" - Ask user whether to close buffer when file deleted
    -- "auto" - Automatically close buffer when file deleted

    -- Other extra features
    enable_diagnostics = true,
    enable_lsp = true,
    enable_prompts = true,
    auto_register = true,
    auto_reload_files = true, -- Master switch for file watching
    lsp_timeout = 2000, -- Longer timeout for complex operations
  },

  -- Server mode configuration (for standalone MCP server)
  server = {
    auto_reload_mode = "reload", -- Automatically reload in server mode
    lsp_notify_mode = "auto", -- Full LSP integration in server mode
    auto_reload_files = true,
    debug = false, -- Disable debug in production server mode
  }
}
