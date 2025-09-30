-- Example CodeCompanion configuration with MCP Diagnostics tool groups
-- Copy and adapt this configuration for your CodeCompanion setup

require("codecompanion").setup({
  strategies = {
    chat = {
      tools = {
        groups = {
          -- === MCP DIAGNOSTICS TOOL GROUPS ===

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
              "refresh_after_external_changes",
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
              "refresh_after_external_changes",
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
      opts = {
        max_diagnostics = 50,
        max_references = 20,
        show_source = true
      }
    }
  }
})

--[[
USAGE EXAMPLES:

In CodeCompanion chat, use:
  /tools diagnostics              - Enable diagnostic analysis tools
  /tools lsp_navigation          - Enable code exploration tools
  /tools code_actions            - Enable fix/improvement tools
  /tools file_management         - Enable file state tools
  /tools comprehensive_analysis  - Enable all 15 tools

Example workflows:
1. Finding issues: "/tools diagnostics" then "What errors are in my project?"
2. Code exploration: "/tools lsp_navigation" then "Explain this function"
3. Getting fixes: "/tools code_actions" then "How can I fix this error?"
4. File problems: "/tools file_management" then "Why isn't LSP working?"
--]]
