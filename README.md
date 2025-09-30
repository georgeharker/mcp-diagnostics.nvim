# MCP Diagnostics for Neovim

> **Share your Neovim diagnostics and LSP data with AI assistants via the Model Context Protocol (MCP)**

This plugin bridges Neovim's rich diagnostic and LSP information with AI coding assistants like Claude, ChatGPT, and others through MCP. Get intelligent code analysis, error investigation, and debugging assistance by giving AI direct access to your editor's state.

## 🚀 Quick Start Guide

**New to this plugin?** Choose one of these paths based on your needs:

### 🎨 Path 1: CodeCompanion Integration (Best experience)

Seamlessly integrate with [CodeCompanion.nvim](https://github.com/olimorris/codecompanion.nvim):

```lua
-- 1. Install both plugins
{
  "olimorris/codecompanion.nvim",
  config = function()
    require("codecompanion").setup({
      strategies = {
        chat = {
          variables = {
            -- mcp-diagnostics variables will be auto-registered
          }
        }
      }
    })
  end
},
{
  "georgeharker/mcp-diagnostics.nvim", 
  config = function()
    require("mcp-diagnostics.codecompanion").setup({
      auto_register = true -- Auto-register with CodeCompanion
    })
  end
}

-- 2. Use in CodeCompanion chat with natural language
-- "Help me fix #{diagnostics}"
-- "I have #{diagnostic_summary}, where should I start?"
-- "Explain #{symbols} structure"
```

### ✨ Path 2: Native Integration (MCPHub)

Use [mcphub.nvim](https://ravitemer.github.io/mcphub.nvim/) for seamless, native Lua integration:

```lua
-- 1. Install both plugins (using lazy.nvim)
{
  "ravitemer/mcphub.nvim",
  config = function() 
    require("mcphub").setup() 
  end
},
{
  "georgeharker/mcp-diagnostics.nvim",
  dependencies = { "ravitemer/mcphub.nvim" },
  config = function()
    require("mcp-diagnostics").setup({ mode = "mcphub" })
  end
}

-- 2. That's it! Start chatting with AI assistants in mcphub
```

### 🔧 Path 3: External Server (Advanced users)

For Claude Desktop or other external MCP clients:

```lua
-- 1. Setup the plugin
{
  "georgeharker/mcp-diagnostics.nvim",
  config = function()
    require("mcp-diagnostics").setup({
      mode = "server",
      server = { auto_start_server = true }
    })
  end
}
```

```bash
# 2. Build the Node.js server
cd server/mcp-diagnostics && npm install && npm run build
```

```json
// 3. Configure Claude Desktop (~/.claude_desktop_config.json)
{
  "mcpServers": {
    "mcp-diagnostics": {
      "command": "node", 
      "args": ["/path/to/your/plugin/server/mcp-diagnostics/dist/index.js"],
      "env": { "NVIM_SERVER_ADDRESS": "/tmp/nvim-mcp-diagnostics.sock" }
    }
  }
}
```

## 🎯 What Does This Plugin Do?

**For AI assistants**: Provides direct access to your Neovim session's:
- **Diagnostics** - All errors, warnings, and hints from LSP servers and linters
- **LSP Information** - Type definitions, references, hover info, symbols, and more
- **Code Analysis** - Smart investigation workflows and error prioritization
- **Buffer State** - What files are open and their current status

**For you**: Get intelligent help with:
- 🐛 **Bug Investigation** - AI can analyze error patterns and suggest fixes
- 🔍 **Code Exploration** - AI understands your codebase structure via LSP
- 📊 **Error Prioritization** - Focus on the most important issues first
- 🚀 **Automated Fixes** - AI can suggest and apply code actions

## 📋 Features

### 🩺 Diagnostic Tools
- **Get diagnostics** with filtering by severity, source, or files
- **Diagnostic summary** with counts and file breakdown
- **🔥 Diagnostic hotspots** - Find most problematic files ranked by severity
- **📊 Advanced statistics** - Error patterns, source analysis, comprehensive metrics  
- **🎯 Severity filtering** - Focus on errors, warnings, info, or hints specifically
- **Smart error triage** with prioritized fixing recommendations

### 🔮 LSP Integration  
- **Hover information** - Types, documentation, signatures
- **Go to definition** - Find symbol definitions
- **Find references** - See all symbol usages  
- **Document symbols** - Browse file structure
- **Workspace search** - Find symbols across project
- **Code actions** - Get automated fixes and refactoring

### 💬 CodeCompanion Variables (Context Injection)
- **#{diagnostics}** - Inject current file diagnostics with code context
- **#{diagnostic_summary}** - Inject overall diagnostic overview  
- **#{symbols}** - Inject document structure and symbols
- **#{buffers}** - Inject loaded buffer status

### 🧠 Smart AI Workflows
- **Buffer management** - Auto-load files for LSP operations
- **Investigation guides** - Step-by-step diagnostic workflows
- **Error prioritization** - Focus on most impactful issues first
- **Auto-approve mode** - Seamless AI interactions without constant prompts

## ⚙️ Configuration Options

### CodeCompanion Setup

```lua
-- Basic setup (recommended)
require("mcp-diagnostics.codecompanion").setup({
  auto_register = true, -- Auto-register with CodeCompanion
  enabled_tools = {
    -- Diagnostic Tools
    "lsp_document_diagnostics",
    "lsp_diagnostics_summary", 
    "diagnostic_hotspots",
    "diagnostic_stats",
    "diagnostic_by_severity",
    
    -- LSP Tools
    "lsp_hover",
    "lsp_definition", 
    "lsp_references",
    "lsp_document_symbols",
    "lsp_workspace_symbols",
    "lsp_code_actions",
    
    -- Buffer Management
    "buffer_status",
    "ensure_files_loaded",
    "refresh_after_external_changes",
  },
  enabled_variables = {
    "diagnostics",
    "diagnostic_summary", 
    "symbols",
    "buffers",
  },
  max_diagnostics = 50,
  max_references = 20,
  show_source = true,
})
```

### MCPHub Setup

```lua
-- Minimal mcphub setup (recommended)
require("mcp-diagnostics").setup({ mode = "mcphub" })

-- Or even simpler one-liner:
require("mcp-diagnostics").mcphub()

-- Advanced mcphub configuration
require("mcp-diagnostics").setup({
  mode = "mcphub",
  
  mcphub = {
    -- Server identification
    server_name = "mcp-diagnostics",
    display_name = "Neovim Diagnostics & LSP", 
    
    -- Auto-approve: Let AI run diagnostic tools without asking
    auto_approve = false, -- Set to true for seamless experience
    
    -- Feature toggles
    enable_diagnostics = true, -- Diagnostic tools
    enable_lsp = true,         -- LSP tools
    enable_prompts = true,     -- Investigation guides
    
    -- Other options
    debug = false,           -- Show detailed logs
    lsp_timeout = 1000,      -- LSP operation timeout (ms)
    auto_register = true,    -- Auto-register with mcphub
    auto_reload_files = true, -- Automatically reload changed files
  }
})
```

### Server Setup

```lua
-- External server configuration
require("mcp-diagnostics").setup({
  mode = "server",
  
  server = {
    server_address = '/tmp/nvim-mcp-diagnostics.sock',
    auto_start_server = true,
    export_path = '/tmp/nvim_diagnostics.json',
    auto_reload_files = true,
  }
})
```

### Quick Setup Functions

For common configurations, use these convenience functions:

```lua
-- CodeCompanion integration
require("mcp-diagnostics").codecompanion()

-- Basic mcphub integration
require("mcp-diagnostics").mcphub()

-- External server mode
require("mcp-diagnostics").server()

-- Auto-approve mcphub (no prompts)
require("mcp-diagnostics").mcphub_auto()
```

## 🎮 Usage Examples

### CodeCompanion Variables

Use natural language with context injection:

```lua
-- In CodeCompanion chat:
"Help me fix #{diagnostics}"                    -- Current file errors with code context
"I have #{diagnostic_summary}, prioritize for me" -- Overall diagnostic overview  
"Explain #{symbols} architecture"                -- Document structure
"With #{buffers} loaded, which file needs attention?" -- Buffer status context
```

### Tool Commands

All interfaces provide these diagnostic and LSP tools:

**Diagnostic Analysis:**
- `diagnostic_hotspots` - Most problematic files by severity score
- `diagnostic_stats` - Comprehensive error pattern analysis
- `diagnostic_by_severity` - Filter by error/warn/info/hint
- `diagnostics_summary` - Overall counts and breakdown

**LSP Navigation:**  
- `lsp_hover` - Symbol information and documentation
- `lsp_definition` - Jump to symbol definitions
- `lsp_references` - Find all symbol usages
- `lsp_document_symbols` - File structure overview
- `lsp_workspace_symbols` - Project-wide symbol search
- `lsp_code_actions` - Available fixes and refactoring

**Buffer Management:**
- `buffer_status` - All loaded files and their diagnostic counts
- `ensure_files_loaded` - Load specific files for analysis
- `refresh_after_external_changes` - Sync after external edits

## 📚 Documentation

- [📖 CodeCompanion Integration Guide](docs/codecompanion_integration.md)
- [🏗️ Architecture Overview](docs/architecture/component_reference.md)
- [🔧 Configuration Examples](example_configs/README.md)
- [🏥 Health Check Guide](lua/mcp-diagnostics/health.lua)
- [📊 Feature Parity Matrix](PARITY_CHECK.md)

## 🤝 Contributing

This plugin is actively developed! Contributions welcome:

1. 🐛 **Bug reports** - File issues with reproduction steps
2. 💡 **Feature requests** - Suggest new diagnostic or LSP capabilities
3. 📖 **Documentation** - Help improve setup guides and examples
4. 🧪 **Testing** - Try with different LSP servers and AI assistants

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

**Happy coding with AI assistance! 🚀**