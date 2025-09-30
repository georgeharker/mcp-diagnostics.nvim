# CodeCompanion Tool Groups for MCP Diagnostics

This guide shows how to organize the MCP Diagnostics tools into logical groups within CodeCompanion, making it easy to enable specific sets of tools for different workflows.

## Overview

CodeCompanion supports **tool groups** that allow you to enable multiple related tools with a single command. Instead of manually enabling individual tools, you can use commands like:

- `/tools diagnostics` - Enable diagnostic analysis tools
- `/tools lsp_navigation` - Enable code navigation tools  
- `/tools comprehensive_analysis` - Enable all diagnostic tools

## Setup

Add the following groups to your CodeCompanion configuration:

```lua
require("codecompanion").setup({
  strategies = {
    chat = {
      tools = {
        groups = {
          -- Core diagnostic analysis
          ["diagnostics"] = {
            description = "LSP Diagnostics - Analyze code issues, errors, and warnings",
            prompt = "I'm an expert at analyzing code diagnostics and issues. I have access to ${tools} to help you understand and fix problems in your code.",
            tools = {
              "lsp_document_diagnostics",
              "lsp_diagnostics_summary", 
              "analyze_diagnostic_context",
              "correlate_diagnostics",
            },
            opts = {
              collapse_tools = true,
            },
          },

          -- Code navigation and understanding
          ["lsp_navigation"] = {
            description = "LSP Navigation - Navigate code, understand symbols and structure",
            prompt = "I'm an expert at code navigation and understanding. I have access to ${tools} to help you explore and understand your codebase.",
            tools = {
              "lsp_hover",
              "lsp_definition", 
              "lsp_references",
              "lsp_document_symbols",
              "lsp_workspace_symbols",
            },
            opts = {
              collapse_tools = true,
            },
          },

          -- Code fixes and improvements
          ["code_actions"] = {
            description = "LSP Code Actions - Apply fixes and improvements to your code",
            prompt = "I'm an expert at suggesting and applying code fixes. I have access to ${tools} to help improve your code quality.",
            tools = {
              "lsp_code_actions",
            },
            opts = {
              collapse_tools = true,
            },
          },

          -- Buffer and file management
          ["file_management"] = {
            description = "File Management - Manage buffer states and file loading",
            prompt = "I'm an expert at managing file states and buffers. I have access to ${tools} to help ensure your files are properly loaded and managed.",
            tools = {
              "buffer_status",
              "ensure_files_loaded",
              "handle_file_deleted",
              "refresh_after_external_changes",
              "check_file_staleness",
            },
            opts = {
              collapse_tools = true,
            },
          },

          -- All diagnostic tools (comprehensive)
          ["comprehensive_analysis"] = {
            description = "Comprehensive Code Analysis - Full diagnostic and LSP capabilities", 
            prompt = "I'm an expert software engineer with comprehensive code analysis capabilities. I have access to ${tools} for complete diagnostic analysis, code navigation, and file management.",
            tools = {
              -- Core LSP Tools
              "lsp_document_diagnostics",
              "lsp_diagnostics_summary", 
              "lsp_hover",
              "lsp_definition",
              "lsp_references", 
              "lsp_document_symbols",
              "lsp_workspace_symbols",
              "lsp_code_actions",
              
              -- File Management Tools
              "buffer_status",
              "ensure_files_loaded",
              "handle_file_deleted", 
              "refresh_after_external_changes",
              "check_file_staleness"
            },
            opts = {
              collapse_tools = true,
            },
          },
        },
      },
    },
  },
  
  -- Don't forget to register the mcp-diagnostics extension
  extensions = {
    mcp_diagnostics = {
      callback = "mcp-diagnostics.codecompanion.extension",
      opts = {}
    }
  }
})
```

## Usage

Once configured, you can use these groups in CodeCompanion chat:

### Enable a specific group
```
/tools diagnostics
```
This enables only the diagnostic analysis tools.

### Switch between groups
```
/tools lsp_navigation
```
This disables the current tools and enables the navigation tools.

### Enable comprehensive analysis
```
/tools comprehensive_analysis  
```
This enables all 17 diagnostic tools for complete analysis.

## Group Descriptions

### `diagnostics`
**Best for:** Finding and understanding code issues
- Get diagnostics from current buffer or workspace
- Summarize diagnostic issues
- Analyze diagnostic context
- Find related/correlated issues

**Example use cases:**
- "What errors are in my current file?"
- "Summarize all the warnings in my project"
- "Why am I getting this error and what's causing it?"

### `lsp_navigation`
**Best for:** Exploring and understanding code structure
- Get symbol information and documentation
- Navigate to definitions and find references
- Explore document and workspace symbols
- Comprehensive symbol analysis

**Example use cases:**
- "Explain what this function does"
- "Show me where this variable is used"
- "What are all the classes in this file?"

### `code_actions`
**Best for:** Fixing issues and improving code
- Get available code actions/fixes
- Analyze diagnostic context for solutions
- Find correlated issues that might need fixing

**Example use cases:**
- "How can I fix this error?"
- "What code actions are available here?"
- "Are there any quick fixes for these warnings?"

### `file_management`
**Best for:** Managing file states and loading issues
- Check buffer status and loading state
- Ensure files are properly loaded
- Handle file deletion and external changes
- Check for stale file states

**Example use cases:**
- "Is this file properly loaded by LSP?"
- "Why isn't my LSP working for this file?"
- "Refresh the file state after external changes"

### `comprehensive_analysis`
**Best for:** Complete code analysis with all available tools
- Full diagnostic and LSP capabilities
- When you need maximum analysis power
- Complex debugging scenarios

**Example use cases:**
- Complex debugging sessions
- Code review and analysis
- Architecture exploration
- Performance investigation

## Tips

1. **Start specific:** Use focused groups like `diagnostics` or `lsp_navigation` for specific tasks
2. **Escalate when needed:** Switch to `comprehensive_analysis` for complex issues
3. **Tool collapse:** The `collapse_tools = true` option keeps the chat cleaner by folding tool output
4. **Custom prompts:** Each group has a specialized system prompt that helps the AI understand the context

## Troubleshooting

### Tools not appearing
1. Ensure mcp-diagnostics extension is registered in CodeCompanion config
2. Check that LSP servers are running for your file types
3. Verify the extension callback path: `"mcp-diagnostics.codecompanion.extension"`

### Groups not working
1. Verify the groups are added under `strategies.chat.tools.groups`
2. Check for syntax errors in the configuration
3. Restart Neovim after configuration changes

### Individual tools not working
See the main [README.md](../README.md) for tool-specific troubleshooting.