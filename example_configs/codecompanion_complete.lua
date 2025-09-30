-- Complete CodeCompanion Integration Example
-- This shows all available tools, variables, and configuration options

return {
  -- Install both plugins
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-telescope/telescope.nvim", -- Optional
    },
    config = function()
      require("codecompanion").setup({
        -- Your CodeCompanion configuration here
        strategies = {
          chat = {
            variables = {
              -- mcp-diagnostics variables will be auto-registered here
            }
          }
        }
      })
    end
  },
  {
    "georgeharker/mcp-diagnostics.nvim",
    dependencies = { "olimorris/codecompanion.nvim" },
    config = function()
      require("mcp-diagnostics.codecompanion").setup({
        -- Auto-register with CodeCompanion
        auto_register = true,
        
        -- All available diagnostic tools
        enabled_tools = {
          -- 📊 Diagnostic Analysis Tools
          "lsp_document_diagnostics",     -- Current file diagnostics with filtering
          "lsp_diagnostics_summary",     -- Overall diagnostic counts and breakdown
          "diagnostic_hotspots",          -- Most problematic files ranked by severity
          "diagnostic_stats",             -- Advanced analytics with error patterns
          "diagnostic_by_severity",       -- Filter diagnostics by error/warn/info/hint
          
          -- 🔮 LSP Navigation Tools  
          "lsp_hover",                    -- Symbol information and documentation
          "lsp_definition",               -- Jump to symbol definitions
          "lsp_references",               -- Find all symbol usages
          "lsp_document_symbols",         -- File structure and symbol overview
          "lsp_workspace_symbols",        -- Project-wide symbol search
          "lsp_code_actions",             -- Available fixes and refactoring options
          
          -- 📋 Buffer Management Tools
          "buffer_status",                -- All loaded files with diagnostic counts
          "ensure_files_loaded",          -- Load specific files for analysis
          "refresh_after_external_changes", -- Sync state after external edits
        },
        
        -- 💬 Context injection variables (use with #{variable_name})
        enabled_variables = {
          "diagnostics",           -- #{diagnostics} - Current file errors with code context
          "diagnostic_summary",    -- #{diagnostic_summary} - Overall stats and overview
          "symbols",              -- #{symbols} - Document structure and symbols  
          "buffers",              -- #{buffers} - Loaded buffer status and file list
        },
        
        -- 🎛️ Behavior Configuration
        max_diagnostics = 50,    -- Limit diagnostic results to prevent overwhelming output
        max_references = 20,     -- Limit reference results for performance
        show_source = true,      -- Include LSP source info (e.g., "lua_ls", "pylsp")
      })
      
      -- Optional: Create user commands for quick access
      vim.api.nvim_create_user_command('DiagnosticsChat', function()
        vim.cmd('CodeCompanionChat')
        vim.defer_fn(function()
          local chat = require('codecompanion').last_chat()
          if chat then
            chat:add_message({
              role = 'user',
              content = 'I have #{diagnostic_summary} in my codebase. Help me prioritize and fix the most important issues.'
            })
          end
        end, 100)
      end, { desc = 'Start CodeCompanion chat with diagnostic context' })
      
      vim.api.nvim_create_user_command('ExplainSymbols', function()
        vim.cmd('CodeCompanionChat')
        vim.defer_fn(function()
          local chat = require('codecompanion').last_chat()
          if chat then
            chat:add_message({
              role = 'user', 
              content = 'Explain the architecture and structure of #{symbols} in this file.'
            })
          end
        end, 100)
      end, { desc = 'Explain current file symbols' })
    end
  }
}

--[[
## 🎮 Usage Examples

### Variables (Context Injection)
Use these in CodeCompanion chat for automatic context:

#{diagnostics} 
- "Help me fix #{diagnostics}"
- "The #{diagnostics} are confusing, explain what's wrong"
- "I have #{diagnostics}, suggest a step-by-step fix plan"

#{diagnostic_summary}
- "I have #{diagnostic_summary}, which files should I prioritize?"  
- "Based on #{diagnostic_summary}, create a cleanup plan"
- "My codebase shows #{diagnostic_summary}, help me focus"

#{symbols}
- "Explain the #{symbols} architecture"
- "How can I refactor #{symbols} to be cleaner?"
- "The #{symbols} structure is complex, help me understand it"

#{buffers}
- "I have #{buffers} open, which file needs attention first?"
- "With #{buffers} loaded, help me navigate the codebase"

### Tool Usage  
CodeCompanion will automatically use these tools when appropriate:

🔥 diagnostic_hotspots() - When you ask about "worst files" or "biggest problems"
📊 diagnostic_stats() - When you want comprehensive analysis or patterns
🎯 diagnostic_by_severity() - When focusing on specific error types
🔮 lsp_hover() - When asking about symbol meaning or documentation
📍 lsp_definition() - When asking "where is this defined" or "show me the source"
🔍 lsp_references() - When asking "where is this used" or "find all usages"

## 🚀 Advanced Tips

1. **Combine Variables**: "I have #{diagnostic_summary} and #{symbols}, suggest architectural improvements"

2. **Natural Language**: Don't think about tools - just describe what you want:
   - "Fix my errors" → Uses #{diagnostics} variable automatically
   - "Find the worst files" → Calls diagnostic_hotspots() tool automatically  
   - "Where is this function used?" → Calls lsp_references() tool automatically

3. **File-specific Context**: Variables automatically work with current file context

4. **Cross-file Analysis**: Tools can load and analyze multiple files as needed

--]]