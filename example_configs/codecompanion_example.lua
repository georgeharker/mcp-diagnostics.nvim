-- CodeCompanion Integration Examples
-- Two correct ways to integrate mcp-diagnostics with CodeCompanion

-- =============================================================================
-- ROUTE 1: Extension Pattern (RECOMMENDED)
-- =============================================================================
-- CodeCompanion depends on mcp-diagnostics and configures via extensions

local extension_pattern = {
    {
        "olimorris/codecompanion.nvim",
        dependencies = { "georgeharker/mcp-diagnostics.nvim" },
        config = function()
            require("codecompanion").setup({
                extensions = {
                    mcp_diagnostics = {
                        callback = "mcp-diagnostics.codecompanion.extension",
                        opts = {
                            max_diagnostics = 30,
                            enabled_tools = {
                                -- Core LSP Tools (8 tools)
                                "lsp_document_diagnostics",
                                "lsp_diagnostics_summary",
                                "lsp_hover",
                                "lsp_definition",
                                "lsp_references",
                                "lsp_document_symbols",
                                "lsp_workspace_symbols",
                                "lsp_code_actions",

                                -- Advanced Analysis Tools (3 tools)
                                "analyze_symbol_comprehensive",
                                "analyze_diagnostic_context",
                                "correlate_diagnostics",

                                -- File Management Tools (3 tools)
                                "buffer_status",
                                "ensure_files_loaded",
                                "refresh_after_external_changes",
                            }
                        }
                    }
                }
            })
        end
    }
}

-- =============================================================================
-- ROUTE 2: Auto-Register Pattern (Alternative)
-- =============================================================================
-- mcp-diagnostics depends on CodeCompanion and registers itself

local auto_register_pattern = {
    {
        "georgeharker/mcp-diagnostics.nvim",
        dependencies = { "olimorris/codecompanion.nvim" },
        config = function()
            require("mcp-diagnostics").setup({
                mode = "codecompanion",
                codecompanion = {
                    auto_register = true,  -- Enables dynamic registration
                    max_diagnostics = 30,
                    enabled_tools = {
                        -- Core LSP Tools (8 tools)
                        "lsp_document_diagnostics",
                        "lsp_diagnostics_summary",
                        "lsp_hover",
                        "lsp_definition",
                        "lsp_references",
                        "lsp_document_symbols",
                        "lsp_workspace_symbols",
                        "lsp_code_actions",

                        -- Advanced Analysis Tools (3 tools)
                        "analyze_symbol_comprehensive",
                        "analyze_diagnostic_context",
                        "correlate_diagnostics",

                        -- File Management Tools (3 tools)
                        "buffer_status",
                        "ensure_files_loaded",
                        "refresh_after_external_changes",
                    }
                }
            })
        end
    }
}

-- =============================================================================
-- Usage Guide
-- =============================================================================

-- Extension Pattern (RECOMMENDED):
-- - Standard CodeCompanion extension approach
-- - Clear configuration visible in CodeCompanion setup
-- - Follows CodeCompanion's documented patterns

-- Auto-Register Pattern (Alternative):
-- - mcp-diagnostics controls its own integration
-- - Self-contained mcp-diagnostics setup
-- - Good for conditional registration logic

-- Both provide identical functionality: 17 LSP tools for CodeCompanion

-- =============================================================================
-- Tool Categories & Descriptions
-- =============================================================================
--
-- CORE LSP TOOLS (8):
-- • lsp_document_diagnostics - Get filtered LSP diagnostics with severity/source filters
-- • lsp_diagnostics_summary - Get diagnostic counts and summary by severity
-- • lsp_hover - Get hover information for symbol under cursor
-- • lsp_definition - Go to definition of symbol
-- • lsp_references - Find all references to symbol
-- • lsp_document_symbols - Get document outline/symbols
-- • lsp_workspace_symbols - Search workspace for symbols
-- • lsp_code_actions - Get available code actions
--
-- ADVANCED ANALYSIS (3):
-- • analyze_symbol_comprehensive - Deep analysis of symbol usage and context
-- • analyze_diagnostic_context - Context analysis for diagnostics
-- • correlate_diagnostics - Find related diagnostic patterns
--
-- FILE MANAGEMENT (6):
-- • buffer_status - Get buffer and LSP client status
-- • ensure_files_loaded - Load files into LSP workspace
-- • refresh_after_external_changes - Refresh LSP after external changes (now handles deletions too)

-- =============================================================================
-- Choose Your Pattern
-- =============================================================================

-- Use extension pattern (recommended):
return extension_pattern

-- Or use auto-register pattern:
-- return auto_register_pattern
