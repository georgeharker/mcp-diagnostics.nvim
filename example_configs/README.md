# Configuration Examples

This directory contains complete configuration examples for all integration modes.

## 🎨 **CodeCompanion Integration** (Recommended)

**File**: [`codecompanion_complete.lua`](codecompanion_complete.lua)

Complete CodeCompanion integration with:
- ✅ All 14 diagnostic and LSP tools
- ✅ 4 context injection variables (`#{diagnostics}`, `#{symbols}`, etc.)
- ✅ Natural language usage examples
- ✅ User command shortcuts

**Best for**: Users who want the most natural AI integration experience.

## 🔧 **MCPHub Integration**

**File**: [`mcphub_complete.lua`](mcphub_complete.lua)

Complete MCPHub integration with:
- ✅ All diagnostic analysis tools
- ✅ All LSP navigation tools  
- ✅ Buffer management tools
- ✅ Auto-approve and debug configurations

**Best for**: Users who want native Lua integration with comprehensive tool access.

## 🌐 **External Server Integration**

**File**: [`server_complete.lua`](server_complete.lua)

Complete external server setup with:
- ✅ Socket and TCP server options
- ✅ Node.js server auto-build
- ✅ Claude Desktop configuration
- ✅ External MCP client examples

**Best for**: Advanced users integrating with Claude Desktop or custom MCP clients.

## 🚀 Quick Setup Examples

### CodeCompanion (Natural Variables)

```lua
-- Install both plugins
{
  "olimorris/codecompanion.nvim",
  config = function() require("codecompanion").setup() end
},
{
  "georgeharker/mcp-diagnostics.nvim",
  config = function()
    require("mcp-diagnostics.codecompanion").setup({ auto_register = true })
  end
}

-- Usage in CodeCompanion chat:
-- "Help me fix #{diagnostics}"
-- "I have #{diagnostic_summary}, prioritize for me"
```

### MCPHub (Tool Access)

```lua
-- Install both plugins
{
  "ravitemer/mcphub.nvim",
  config = function() require("mcphub").setup() end
},
{
  "georgeharker/mcp-diagnostics.nvim", 
  dependencies = { "ravitemer/mcphub.nvim" },
  config = function()
    require("mcp-diagnostics").setup({ mode = "mcphub" })
  end
}

-- AI can use: diagnostic_hotspots, diagnostic_stats, lsp_hover, etc.
```

### External Server (Claude Desktop)

```lua
-- Neovim setup
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

```json
// Claude Desktop config (~/.claude_desktop_config.json)
{
  "mcpServers": {
    "mcp-diagnostics": {
      "command": "node",
      "args": ["/path/to/plugin/server/mcp-diagnostics/dist/index.js"],
      "env": { "NVIM_SERVER_ADDRESS": "/tmp/nvim-mcp-diagnostics.sock" }
    }
  }
}
```

## 📊 Feature Comparison

| Feature | CodeCompanion | MCPHub | Server |
|---------|---------------|--------|--------|
| **Context Variables** | ✅ `#{diagnostics}`, `#{symbols}` | ❌ | ❌ |
| **Natural Language** | ✅ Most intuitive | ✅ Good | ✅ Good |  
| **Tool Count** | 14 tools + 4 variables | 14 tools | 14 functions |
| **Setup Complexity** | Simple | Simple | Advanced |
| **External Clients** | ❌ | ❌ | ✅ Claude Desktop, etc. |

## 🎯 Which Should You Choose?

### Choose **CodeCompanion** if:
- You want the most natural experience  
- You like context injection (`#{diagnostics}`)
- You prefer conversational AI interaction
- You want minimal setup complexity

### Choose **MCPHub** if:  
- You want comprehensive tool access
- You prefer native Lua integration
- You like the mcphub ecosystem
- You want auto-approve capabilities

### Choose **Server** if:
- You use Claude Desktop
- You want external MCP client integration  
- You need JSON export capabilities
- You're building custom MCP applications

## 📖 Usage Guides

### CodeCompanion Variables
```lua
-- Natural language with automatic context:
"Help me fix #{diagnostics}"                    -- Current file errors
"I have #{diagnostic_summary}, where to start?" -- Project overview
"Explain #{symbols} structure"                  -- File architecture  
"With #{buffers} open, what needs attention?"   -- Multi-file context
```

### Tool Commands (MCPHub/Server)
```lua
-- AI can automatically use these tools:
diagnostic_hotspots()      -- Find worst files
diagnostic_stats()         -- Comprehensive analysis
lsp_hover(file, line, col) -- Symbol information
lsp_references(...)        -- Find usages
buffer_status()           -- File status
```

## 🔧 Path Updates Required

When using these examples, update these paths:

- **Plugin path**: `/path/to/plugin/` → Your actual installation path
- **Socket path**: `/tmp/nvim-mcp-diagnostics.sock` → Your preferred location  
- **Server names**: Customize as needed for your setup

## 💡 Pro Tips

1. **Start Simple**: Use the basic setup first, then add advanced features
2. **Health Check**: Always run `:checkhealth mcp-diagnostics` after setup
3. **Debug Mode**: Enable `debug = true` during initial configuration
4. **Test Variables**: Try `#{diagnostic_summary}` in CodeCompanion to verify setup
5. **Auto-approve**: Consider enabling for seamless AI interactions

## 🆘 Troubleshooting

- **CodeCompanion variables not working**: Check `auto_register = true`
- **MCPHub tools not appearing**: Verify mcphub.nvim is loaded first  
- **Server connection issues**: Check socket permissions and paths
- **Build failures**: Ensure Node.js and npm are installed

See the main [README.md](../README.md) for detailed troubleshooting guides.