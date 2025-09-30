-- Complete MCPHub Integration Example  
-- This shows all available tools and configuration options for mcphub.nvim

return {
  -- Install both plugins
  {
    "ravitemer/mcphub.nvim",
    config = function()
      require("mcphub").setup({
        -- Your mcphub configuration here
      })
    end
  },
  {
    "georgeharker/mcp-diagnostics.nvim",
    dependencies = { "ravitemer/mcphub.nvim" },
    config = function()
      require("mcp-diagnostics").setup({
        mode = "mcphub",
        
        mcphub = {
          -- 🏷️ Server Identification
          server_name = "mcp-diagnostics",
          display_name = "Neovim Diagnostics & LSP",
          
          -- 🤖 Auto-approve: Let AI run tools without constant prompts
          auto_approve = false, -- Set to true for seamless experience
          -- When true: AI can run diagnostic and LSP tools automatically
          -- When false: You'll be prompted before each tool execution
          
          -- 🎛️ Feature Toggles
          enable_diagnostics = true,    -- Diagnostic analysis tools
          enable_lsp = true,           -- LSP navigation and info tools  
          enable_prompts = true,       -- Investigation guides and workflows
          enable_buffer_management = true, -- File loading and status tools
          
          -- 🔧 Operational Settings
          debug = false,               -- Show detailed debug logs
          lsp_timeout = 1000,         -- LSP operation timeout (ms)
          auto_register = true,       -- Auto-register with mcphub on startup
          auto_reload_files = true,   -- Automatically reload files changed externally
          auto_reload_mode = "auto",  -- "auto", "prompt", "off"
          
          -- 📊 Output Limits (prevent overwhelming responses)
          max_diagnostics = 50,       -- Limit diagnostic results  
          max_references = 20,        -- Limit reference results
          max_symbols = 100,          -- Limit symbol search results
          show_source = true,         -- Include LSP source info
          
          -- 🔍 LSP Configuration
          lsp_notify_mode = "auto",   -- "auto", "manual", "disabled"
          file_deletion_mode = "prompt", -- "ignore", "prompt", "auto"
        }
      })
      
      -- Optional: Quick setup convenience functions
      -- Uncomment ONE of these instead of the above for simpler configuration:
      
      -- require("mcp-diagnostics").mcphub()           -- Basic setup
      -- require("mcp-diagnostics").mcphub_auto()      -- Auto-approve enabled
      -- require("mcp-diagnostics").mcphub_debug()     -- Debug mode enabled
    end
  }
}

--[[
## 🔧 Available Tools in MCPHub

When chatting with AI assistants in mcphub, these tools are available:

### 📊 Diagnostic Analysis Tools
- `diagnostics_get` - Get diagnostics with filtering by severity/source/files
- `diagnostics_summary` - Overall diagnostic counts and file breakdown  
- `diagnostic_hotspots` - Most problematic files ranked by severity score
- `diagnostic_stats` - Advanced analytics with error patterns and source analysis
- `diagnostic_by_severity` - Filter diagnostics by error/warn/info/hint

### 🔮 LSP Navigation Tools
- `lsp_hover` - Get symbol information, documentation, and signatures
- `lsp_definition` - Find where symbols are defined
- `lsp_references` - Find all usages of a symbol
- `lsp_document_symbols` - Get document structure and symbol overview
- `lsp_workspace_symbols` - Search for symbols across the entire project
- `lsp_code_actions` - Get available fixes and refactoring options

### 📋 Buffer Management Tools  
- `buffer_status` - List all loaded files with diagnostic counts
- `ensure_files_loaded` - Load specific files into buffers for analysis
- `refresh_after_external_changes` - Sync state after external file modifications

## 🎮 Usage Examples

### Natural AI Conversations
"Find the files with the most errors in my project"
→ AI automatically uses `diagnostic_hotspots` tool

"What are all the errors in my current file?"  
→ AI uses `diagnostics_get` tool with current file context

"Show me where this function is used throughout the codebase"
→ AI uses `lsp_references` tool at cursor position

"What functions are available in this file?"
→ AI uses `lsp_document_symbols` tool

### Advanced Workflows
"Analyze my codebase for error patterns and suggest a cleanup plan"
→ AI combines `diagnostic_stats` + `diagnostic_hotspots` for comprehensive analysis

"Help me understand the architecture of this file"  
→ AI uses `lsp_document_symbols` + `lsp_hover` for detailed explanations

## 🚀 Pro Tips

1. **Auto-approve Mode**: Set `auto_approve = true` for seamless experience where AI can run diagnostic tools without asking permission

2. **File Context**: Tools automatically work with your current cursor position and file context

3. **Comprehensive Analysis**: AI can combine multiple tools for thorough investigation

4. **Performance**: Adjust `max_diagnostics` and `max_references` based on your project size

5. **Debug Mode**: Enable `debug = true` to see detailed tool execution logs

## ⚡ Quick Setup Variants

```lua
-- Minimal setup (most users)
require("mcp-diagnostics").mcphub()

-- Auto-approve (power users - no prompts) 
require("mcp-diagnostics").mcphub_auto()

-- Debug mode (troubleshooting)
require("mcp-diagnostics").mcphub_debug()

-- Server mode (external MCP clients)
require("mcp-diagnostics").server()
```

--]]