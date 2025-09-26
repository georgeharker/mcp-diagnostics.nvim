# Example Configurations

This directory contains example configurations and setup files for the MCP Diagnostics plugin.

## 📁 Files Overview

### Neovim Configuration Examples

- **`mcphub_examples.lua`** - Complete mcphub.nvim integration examples
  - Basic setup with auto-approve
  - Manual registration examples
  - Advanced configuration options
  
- **`server_examples.lua`** - External server mode examples  
  - Basic server setup
  - Auto-build and launch configurations
  - Development and production setups

### External Client Configurations

- **`claude_desktop_config_example.json`** - Ready-to-use Claude Desktop configurations
  - Socket and TCP connection examples
  - Auto-launch configurations
  - Headless and custom config examples

- **`mcpServers.json`** - Alternative MCP server configuration format
  - Same examples as Claude Desktop config
  - Can be used with other MCP clients

## 🚀 Quick Setup Examples

### For mcphub.nvim Users (Recommended)

```lua
-- Minimal setup - just add to your Neovim config
require("mcp-diagnostics").setup({ mode = "mcphub" })

-- Or with auto-approve for seamless AI interactions
require("mcp-diagnostics").setup({
  mode = "mcphub",
  mcphub = { auto_approve = true }
})
```

### For Claude Desktop Users

1. **Copy** `claude_desktop_config_example.json` content to `~/.claude_desktop_config.json`
2. **Update** the file paths to match your plugin installation
3. **Build** the server: `cd server/mcp-diagnostics && npm install && npm run build`

### For Development

See the individual example files for:
- Debug configurations
- Custom server names and ports
- Development vs production setups
- Troubleshooting configurations

## 📖 Usage

1. **Browse** the relevant example file for your setup
2. **Copy** the configuration that matches your needs
3. **Modify** paths and settings as needed
4. **Test** with `:checkhealth mcp-diagnostics`

## 🔧 Path Updates Required

When using these examples, update these paths to match your installation:

- `/absolute/path/to/mcp-diagnostics/` → Your actual plugin path
- `/tmp/nvim.sock` → Your preferred socket path (optional)
- Server names → Customize as needed

## 💡 Tips

- Start with the simplest configuration that works
- Use `:checkhealth mcp-diagnostics` to verify setup
- Enable debug mode during initial setup
- Check the main README.md for troubleshooting help