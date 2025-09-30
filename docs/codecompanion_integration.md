# CodeCompanion Integration

This document explains how to integrate `mcp-diagnostics.nvim` with `codecompanion.nvim` to provide AI assistants with direct access to LSP diagnostics and code analysis tools.

## Two Integration Routes

There are **two dependency patterns** for integrating mcp-diagnostics with CodeCompanion:

### Route 1: Extension Pattern (Recommended)
CodeCompanion depends on mcp-diagnostics and configures it via extensions.

### Route 2: Dynamic Registration  
mcp-diagnostics depends on CodeCompanion and registers itself dynamically.

## Overview

The CodeCompanion integration provides 17 LSP-powered tools that give AI assistants deep insight into your codebase through Neovim's LSP ecosystem. Unlike the MCP server approach, this integration works directly within Neovim with zero external dependencies.

## Route 1: Extension Pattern (Recommended)

In this pattern, **CodeCompanion depends on mcp-diagnostics** and configures the integration via CodeCompanion's extensions system.

### Benefits
- Cleaner dependency direction (CodeCompanion owns the integration)
- Extension options clearly visible in CodeCompanion config  
- Follows CodeCompanion's standard extension pattern
- No automatic registration needed

### Basic Setup

```lua
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
                            "lsp_document_diagnostics",
                            "lsp_hover",
                            "lsp_definition", 
                            "lsp_references"
                        }
                    }
                }
            }
        })
    end
}
```

## Route 2: Dynamic Registration

In this pattern, **mcp-diagnostics depends on CodeCompanion** and registers itself dynamically when `auto_register = true` is set.

### Benefits  
- mcp-diagnostics "injects itself" into CodeCompanion
- Conditional registration based on mcp-diagnostics config
- mcp-diagnostics owns the integration decision
- Good for complex conditional setups

### Basic Setup

```lua
{
    "georgeharker/mcp-diagnostics.nvim",
    dependencies = { "olimorris/codecompanion.nvim" },
    config = function()
        require("mcp-diagnostics").setup({
            mode = "codecompanion",
            codecompanion = {
                auto_register = true,
                max_diagnostics = 30,
                enabled_tools = {
                    "lsp_document_diagnostics",
                    "lsp_hover",
                    "lsp_definition",
                    "lsp_references"
                }
            }
        })
    end
}
```

## Choosing Between Routes

### Use Route 1 (Extension Pattern) when:
- You want standard CodeCompanion extension behavior
- You prefer CodeCompanion to own the integration config
- You want the simplest, most standard approach
- **Recommended for most users**

### Use Route 2 (Dynamic Registration) when:
- You want mcp-diagnostics to control its own integration
- You need conditional registration logic
- You prefer dependency direction: mcp-diagnostics → CodeCompanion
- You want mcp-diagnostics setup to be self-contained

## Configuration Options

Both routes support the same configuration options:

```lua
opts = {
    -- Limit diagnostic results to avoid overwhelming AI
    max_diagnostics = 50,        -- default: 50
    max_references = 20,         -- default: 20
    show_source = true,          -- default: true
    
    -- Control which tools are available  
    enabled_tools = {            -- default: all 12 tools
        "lsp_document_diagnostics",
        "lsp_diagnostics_summary",
        "lsp_hover",
        "lsp_definition",
        "lsp_references",
        "lsp_document_symbols",
        "lsp_workspace_symbols", 
        "lsp_code_actions",
        "buffer_status",
        "ensure_files_loaded",
        "handle_file_deleted",
        "refresh_after_external_changes",
        "check_file_staleness"
    },
    
    -- Route 2 only: Enable automatic registration
    auto_register = false        -- default: false
}
```

## Available Tools

After setup, CodeCompanion AI assistants have access to 17 LSP tools:

### Core Diagnostic Tools (2)
- `lsp_document_diagnostics` - Get filtered diagnostics with severity/source filtering

### Core LSP Tools (6)
- `lsp_hover` - Symbol information and documentation
- `lsp_definition` - Jump to symbol definitions  
- `lsp_references` - Find all symbol references
- `lsp_document_symbols` - File outline/structure
- `lsp_workspace_symbols` - Search symbols across workspace
- `lsp_code_actions` - Available fixes and refactorings

### File Management Tools (6)
- `buffer_status` - Buffer and LSP client status
- `ensure_files_loaded` - Load files for LSP analysis
- `handle_file_deleted` - Proper file deletion handling
- `refresh_after_external_changes` - Smart external change refresh
- `check_file_staleness` - Detect external file changes

## Verification

After setup, verify the integration:

```vim
:checkhealth mcp-diagnostics
```

This should show CodeCompanion integration status and confirm all tools are available.

## Troubleshooting

### Extension Not Loading
- Ensure CodeCompanion is installed and working
- Check that callback path `"mcp-diagnostics.codecompanion.extension"` is correct
- Verify no syntax errors: `:checkhealth mcp-diagnostics`

### Dynamic Registration Not Working  
- Ensure `auto_register = true` is set
- Check CodeCompanion supports `register_extension` API
- Verify CodeCompanion loads before mcp-diagnostics setup

### Tools Not Available in Chat
- Check `:checkhealth codecompanion` for extension status
- Verify LSP is active for the file types you're testing
- Ensure enabled_tools includes the tools you expect