# MCP Diagnostics for Neovim

> **Share your Neovim diagnostics and LSP data with AI assistants via the Model Context Protocol (MCP)**

This plugin bridges Neovim's rich diagnostic and LSP information with AI coding assistants like Claude, ChatGPT, and others through MCP. Get intelligent code analysis, error investigation, and debugging assistance by giving AI direct access to your editor's state.

## 🚀 Quick Start Guide

**New to this plugin?** Choose one of these paths based on your needs:

### ✨ Path 1: Native Integration (Recommended for beginners)

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

### 🔧 Path 2: External Server (Advanced users)

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
- **Smart error triage** with prioritized fixing recommendations

### 🔮 LSP Integration  
- **Hover information** - Types, documentation, signatures
- **Go to definition** - Find symbol definitions
- **Find references** - See all symbol usages  
- **Document symbols** - Browse file structure
- **Workspace search** - Find symbols across project
- **Code actions** - Get automated fixes and refactoring

### 🧠 Smart AI Workflows
- **Buffer management** - Auto-load files for LSP operations
- **Investigation guides** - Step-by-step diagnostic workflows
- **Error prioritization** - Focus on most impactful issues first
- **Auto-approve mode** - Seamless AI interactions without constant prompts

## ⚙️ Configuration Options

### Simple Setup (Most Users)

```lua
-- Minimal mcphub setup (recommended)
require("mcp-diagnostics").setup({ mode = "mcphub" })

-- Or even simpler one-liner:
require("mcp-diagnostics").mcphub()
```

### Advanced Configuration

```lua
require("mcp-diagnostics").setup({
  mode = "mcphub", -- or "server" for external integration
  
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

### Quick Setup Functions

For common configurations, use these convenience functions:

```lua
-- Basic mcphub integration
require("mcp-diagnostics").mcphub()

-- Server mode for Claude Desktop
require("mcp-diagnostics").server()

-- Auto-approve mode (no confirmation prompts)
require("mcp-diagnostics").setup({
  mode = "mcphub",
  mcphub = { auto_approve = true }
})
```

### Migration from Older Versions

If you're upgrading from an older version of this plugin, the configuration format has been unified:

**Old format:**
```lua
-- Old mixed configuration (no longer supported)
require("mcp-diagnostics.config").setup({
  server_address = '/tmp/nvim.sock',
  auto_start_server = true
})

-- Or old mcphub setup
require("mcp-diagnostics.mcphub").quick_setup()
```

**New unified format:**
```lua
-- New unified configuration
require("mcp-diagnostics").setup({
  mode = "mcphub",  -- Choose: "mcphub" or "server"
  mcphub = {
    auto_register = true,
    auto_approve = false,  -- Optional: enable for seamless AI interaction
  }
})

-- Or for server mode:
require("mcp-diagnostics").setup({
  mode = "server",
  server = {
    server_address = '/tmp/nvim.sock',
    auto_start_server = true
  }
})
```

**Path changes for external server:**
- Old: `/path/to/mcp-diagnostics/dist/index.js`
- New: `/path/to/mcp-diagnostics/server/mcp-diagnostics/dist/index.js`

### 🔄 Auto-Reload Feature

This plugin automatically watches for file changes and reloads them in Neovim when they're modified externally. This ensures AI assistants always work with the latest file content.

**Configuration:**
```lua
require("mcp-diagnostics").setup({
  mode = "mcphub",
  mcphub = {
    auto_reload_files = true,  -- Default: enabled
  }
})

-- To disable auto-reload:
require("mcp-diagnostics").no_auto_reload()
```

**What it does:**
- Monitors files opened in buffers for external changes
- Automatically reloads buffers when files change on disk  
- Prevents stale data when working with AI assistants
- Smart change detection to avoid unnecessary reloads
- Automatic cleanup when files are closed

## 🤖 Auto-Approve Feature

**What is auto-approve?** When enabled, AI assistants can automatically execute diagnostic and LSP tools without showing you confirmation prompts each time. This creates a much smoother experience.

### Enable Auto-Approve

**Method 1: Plugin Configuration (Recommended)**
```lua
require("mcp-diagnostics").setup({
  mode = "mcphub",
  mcphub = {
    auto_approve = true,  -- Enable auto-approve
    debug = false         -- Set to true to see what tools AI is using
  }
})
```

**Method 2: Direct mcphub Configuration**
```lua
-- In your mcphub setup
require("mcphub").setup({
  servers = {
    ["mcp-diagnostics"] = {
      autoApprove = true  -- or specific tools: ["diagnostics_get", "lsp_hover"]
    }
  }
})
```

### Is Auto-Approve Safe?

**Yes!** All diagnostic tools are **read-only** and safe to auto-execute:
- ✅ `diagnostics_get` - Just reads diagnostic information  
- ✅ `lsp_hover` - Just gets type/documentation info
- ✅ `lsp_definition` - Just finds where symbols are defined
- ✅ `buffer_status` - Just shows what files are open
- ❌ No tools perform writes, deletions, or system modifications

### Control Auto-Approve
- **Toggle anytime**: In mcphub's UI, press `a` to toggle auto-approval
- **Monitor activity**: Enable `debug = true` to see what tools AI is using
- **Granular control**: Auto-approve only specific tools if desired

### mcphub.nvim Compatibility

This plugin leverages mcphub.nvim's native `autoApprove` system:
- `autoApprove: true` - All tools for this server are auto-approved
- `autoApprove: false` - User confirmation required for each tool execution  
- `autoApprove: ["tool1", "tool2"]` - Only specific tools are auto-approved

For native Lua servers like this plugin, auto-approve is controlled through mcphub.nvim's configuration. The plugin properly registers with mcphub's auto-approve system when `auto_approve = true` is set.

## 💡 Usage Examples

### "Help me fix these errors"
AI assistant can:
1. Get diagnostic summary to see error overview
2. Fetch detailed error information for specific files  
3. Use LSP to understand error context and find definitions
4. Suggest fixes based on code analysis
5. Find similar patterns across your codebase

### "Explain this function"
AI assistant can:
1. Get hover information for type signatures
2. Find the function definition
3. Locate all references to understand usage
4. Browse related symbols and documentation

### "Why is my build failing?"
AI assistant can:
1. Check diagnostic summary for error patterns
2. Analyze error sources (TypeScript, ESLint, etc.)
3. Investigate file-specific issues
4. Suggest systematic fixes prioritized by impact

## 🏗️ Architecture

This plugin offers two ways to share your Neovim data with AI:

```
┌─────────────────────────────────────────────────────────────────┐
│                    MCP Diagnostics Plugin                       │
├─────────────────────────┬───────────────────────────────────────┤
│   mcphub Integration    │     External Server Integration       │
│   (Recommended)         │     (Advanced Users)                  │
│                         │                                       │
│ ✅ Native Lua          │ ✅ Works with Claude Desktop          │
│ ✅ Simple setup        │ ✅ Standalone operation               │
│ ✅ No external deps    │ ✅ Network accessible                 │
│ ❌ Requires mcphub     │ ❌ Complex setup (Node.js required)   │
├─────────────────────────┼───────────────────────────────────────┤
│      mcphub.nvim        │     Claude Desktop, VSCode, etc.     │
│         ↕               │            ↕                          │
│    Any MCP Client       │    External MCP Clients              │
└─────────────────────────┴───────────────────────────────────────┘
```

## 📂 Directory Structure

```
mcp-diagnostics/
├── lua/
│   ├── init.lua                    # Main plugin entry point
│   └── mcp-diagnostics/
│       ├── mcphub/                 # mcphub.nvim integration
│       │   ├── init.lua           # mcphub setup and registration
│       │   ├── core.lua           # Diagnostic & LSP functions  
│       │   ├── tools.lua          # MCP tool definitions
│       │   ├── resources.lua      # MCP resource definitions
│       │   ├── prompts.lua        # Investigation prompts
│       │   └── example.lua        # Configuration examples
│       └── server/                 # External server integration
│           ├── init.lua           # Server setup and management
│           └── example.lua        # Configuration examples
├── server/
│   └── mcp-diagnostics/           # Node.js MCP server
│       ├── package.json          # Node.js dependencies
│       ├── src/                  # TypeScript source
│       └── dist/                 # Compiled JavaScript
└── README.md                      # This file
```

## 🛠️ Available Tools for AI Assistants

Both integration modes provide the same comprehensive set of tools:

### Core Diagnostic Tools
```lua
-- Get all error diagnostics
diagnostics_get({"severity": "error"})

-- Get diagnostic summary
diagnostics_summary()
```

### LSP Investigation Tools
```lua
-- Get type information at cursor
lsp_hover({"file": "path/file.lua", "line": 42, "column": 10})

-- Find where symbol is defined
lsp_definition({"file": "path/file.lua", "line": 42, "column": 10})

-- Find all references to symbol
lsp_references({"file": "path/file.lua", "line": 42, "column": 10})

-- Search for symbols across workspace
lsp_workspace_symbols({"query": "function_name"})

-- Get available code fixes
lsp_code_action({"file": "path/file.lua", "line": 42, "column": 10})
```

### Buffer Management
```lua  
-- Ensure files are loaded for LSP operations  
ensure_files_loaded({"files": ["path/file1.lua", "path/file2.py"]})

-- Get status of all buffers
buffer_status()
```

### Investigation Resources
- `diagnostics://current` - All current diagnostics formatted for AI
- `diagnostics://summary` - Diagnostic counts and breakdowns
- `diagnostics://errors` - Only error-level diagnostics

### Smart Investigation Guides
- **Diagnostic Investigation Guide** - Step-by-step workflow for AI assistants
- **Error Triage** - Prioritized error fixing recommendations  
- **LSP Workflow Guide** - Best practices for code exploration

## 🎓 How AI Uses These Tools

### Error Investigation Workflow

1. **Get overview**: `diagnostics_summary()`
2. **Focus on errors**: `diagnostics_get({"severity": "error"})`
3. **Load files**: `ensure_files_loaded({"files": [...]})`
4. **Investigate context**: `lsp_hover()` on error locations
5. **Find root cause**: `lsp_definition()` and `lsp_references()`
6. **Look for fixes**: `lsp_code_action()` for automated solutions

### Code Understanding Workflow

1. **Get structure**: `lsp_symbols({"file": "path/to/file"})` 
2. **Understand symbols**: `lsp_hover()` on key functions/classes
3. **Trace connections**: `lsp_definition()` and `lsp_references()`
4. **Search broadly**: `lsp_workspace_symbols()` for related code

## 🔧 Neovim Commands 

### Server Mode Commands

| Command | Description |
|---------|-------------|
| `:McpDiagnostics status` | Show connection status |
| `:McpDiagnostics summary` | Show diagnostic summary in Neovim |
| `:McpDiagnostics export [file]` | Export diagnostics to JSON |
| `:McpDiagnostics server start` | Start Neovim MCP server |
| `:McpDiagnostics server stop` | Stop all servers |
| `:McpDiagnostics server build` | Build Node.js MCP server |
| `:McpDiagnostics server launch` | Launch Node.js MCP server |

### Debugging Commands

| Command | Description |
|---------|-------------|
| `:lua require("mcp-diagnostics").debug()` | Show configuration and status |
| `:lua require("mcp-diagnostics.mcphub").debug()` | Debug mcphub registration |

## 🐛 Troubleshooting

### First-Time Setup Issues

**"Plugin not working"**
1. Check you installed the right plugin path: `georgeharker/mcp-diagnostics.nvim`
2. Ensure dependencies are met (mcphub.nvim if using mcphub mode)
3. Restart Neovim after installation

**"No AI responses"**  
1. Verify your AI assistant supports MCP (Claude Desktop, mcphub clients)
2. Check the server is registered: `:lua require("mcp-diagnostics").debug()`
3. Enable debug mode to see tool execution

**"Auto-approve not working"**
1. Make sure you set `auto_approve = true` in your config
2. For mcphub mode, check mcphub's UI shows auto-approve enabled
3. Try toggling with `a` key in mcphub interface

### Diagnostic Issues

**"No diagnostics found"**
1. Ensure LSP servers are running: `:LspInfo`
2. Check files have errors/warnings visible in Neovim
3. Open files in buffers - diagnostics come from loaded buffers

**"LSP tools not working"**
1. Confirm LSP server is attached to the file: `:LspInfo` 
2. Use `ensure_files_loaded` tool first to load files
3. Check the file type has LSP support configured

### Common Issues

**"mcphub.nvim not found"** (mcphub mode)
- Install mcphub.nvim before this plugin
- Ensure mcphub.nvim loads first

**"No LSP clients attached"** (both modes)
- Verify LSP servers are running: `:LspInfo`
- Use `ensure_files_loaded` to load files first
- Ensure files have proper LSP configuration

**External server connection issues** (server mode)
- Check Node.js server is built: `npm run build`
- Verify `NVIM_SERVER_ADDRESS` matches Neovim server
- Test connection with server test scripts

### Debug Mode

Enable detailed logging:

```lua
-- mcphub mode
require("mcp-diagnostics").setup({
  mode = "mcphub", 
  mcphub = { debug = true }
})

-- Check Neovim messages for debug output
:messages
```

## 📚 Additional Documentation & Examples

- 📖 **Server Guide**: [`server/README.md`](server/README.md) - External server setup
- 🔧 **Configuration Examples**: [`example_configs/`](example_configs/) - Complete setup examples
  - [`mcphub_examples.lua`](example_configs/mcphub_examples.lua) - mcphub.nvim integration examples
  - [`server_examples.lua`](example_configs/server_examples.lua) - External server examples
  - [`claude_desktop_config_example.json`](example_configs/claude_desktop_config_example.json) - Claude Desktop configs

## 🎯 Recommended AI Assistant Prompts

Try these prompts with your AI assistant once the plugin is set up:

- *"Check my current Neovim errors and help me prioritize which ones to fix first"*
- *"Investigate why I'm getting TypeScript errors in this file"* 
- *"Explain what this function does and show me everywhere it's used"*
- *"Help me understand the structure of this codebase using LSP information"*
- *"Find all the TODO comments and warnings across my project"*
- *"What code actions are available to fix this specific error?"*

## 🤝 Contributing

This plugin improves upon the original diagnostic sharing approach by:

1. **Two integration paths** - Native mcphub.nvim integration + external server support
2. **Beginner friendly** - Simple setup with clear documentation
3. **Auto-approve feature** - Seamless AI interactions
4. **Comprehensive toolset** - Full diagnostic + LSP integration
5. **Better organization** - Clean, modular code structure

## 📄 License

MIT License - see the original mcp-diagnostics project for details.

## 📁 Configuration Files

- **Claude Desktop Config**: [`claude_desktop_config_example.json`](claude_desktop_config_example.json) - Ready-to-use examples
- **MCP Servers Config**: [`.mcpServers.json`](.mcpServers.json) - Alternative configuration format
- **Server Configuration**: [`server/CONFIGURATION.md`](server/CONFIGURATION.md) - Complete server setup guide