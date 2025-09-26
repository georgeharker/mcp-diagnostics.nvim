# Server Configuration Guide

This guide covers all the ways to configure and run the MCP Diagnostics Node.js server.

## 🚀 Quick Start Options

### Option 1: Connect to Existing Neovim
If you already have Neovim running with a server:

```bash
# Start Neovim with server first
nvim --listen /tmp/nvim.sock

# Then run MCP server
cd server/mcp-diagnostics
npm run build
npm start
```

### Option 2: Auto-Launch Neovim (Recommended)
Let the MCP server launch and manage Neovim:

```bash
cd server/mcp-diagnostics
npm run build
npm run start:nvim-server  # Launches Neovim automatically
```

### Option 3: Full Auto-Setup with Plugin
Use the Neovim plugin to build and run everything:

```lua
require("mcp-diagnostics").setup({
  mode = "server",
  server = {
    auto_build = true,      -- Build Node.js server automatically
    auto_launch = true,     -- Launch Node.js server automatically  
    server_address = '/tmp/nvim.sock',
    auto_start_server = true,
  }
})
```

## 📋 Configuration Options

### Claude Desktop Configuration

#### Basic Connection (Existing Neovim)
```json
{
  "mcpServers": {
    "neovim-diagnostics": {
      "command": "node",
      "args": ["/absolute/path/to/mcp-diagnostics/server/mcp-diagnostics/dist/index.js"],
      "env": {
        "NVIM_SERVER_ADDRESS": "/tmp/nvim.sock"
      }
    }
  }
}
```

#### Auto-Launch Neovim (Socket)
```json
{
  "mcpServers": {
    "neovim-auto-launch": {
      "command": "node",
      "args": [
        "/absolute/path/to/mcp-diagnostics/server/mcp-diagnostics/dist/index.js", 
        "--launch-nvim"
      ],
      "env": {
        "NVIM_SERVER_ADDRESS": "/tmp/nvim.sock"
      }
    }
  }
}
```

#### Auto-Launch Neovim (TCP)
```json
{
  "mcpServers": {
    "neovim-auto-launch-tcp": {
      "command": "node",
      "args": [
        "/absolute/path/to/mcp-diagnostics/server/mcp-diagnostics/dist/index.js",
        "--launch-nvim",
        "--tcp-port", "6666"
      ],
      "env": {
        "NVIM_SERVER_ADDRESS": "127.0.0.1:6666"
      }
    }
  }
}
```

#### Advanced Configuration with Custom Neovim Config
```json
{
  "mcpServers": {
    "neovim-custom": {
      "command": "node",
      "args": [
        "/absolute/path/to/mcp-diagnostics/server/mcp-diagnostics/dist/index.js",
        "--launch-nvim",
        "--nvim-config", "/path/to/custom/init.lua"
      ],
      "env": {
        "NVIM_SERVER_ADDRESS": "/tmp/nvim.sock"
      }
    }
  }
}
```

### Neovim Plugin Configuration

#### Basic Server Mode
```lua
require("mcp-diagnostics").setup({
  mode = "server",
  server = {
    server_address = '/tmp/nvim.sock',
    auto_start_server = true,
  }
})
```

#### Auto-Build and Launch Node.js Server
```lua
require("mcp-diagnostics").setup({
  mode = "server", 
  server = {
    -- Neovim server settings
    server_address = '/tmp/nvim.sock',
    auto_start_server = true,
    
    -- Node.js MCP server settings
    auto_build = true,          -- Run npm install && npm run build
    auto_launch = true,         -- Launch the Node.js MCP server
    node_server_path = nil,     -- Auto-detect: server/mcp-diagnostics
    node_args = {},             -- Additional args for Node.js server
    build_on_change = true,     -- Rebuild when TypeScript files change
  }
})
```

#### Advanced Auto-Launch Configuration
```lua
require("mcp-diagnostics").setup({
  mode = "server",
  server = {
    -- Neovim settings
    server_address = '127.0.0.1:6666',  -- TCP connection
    auto_start_server = true,
    
    -- Auto-build settings
    auto_build = true,
    build_command = "npm install && npm run build",  -- Custom build command
    build_cwd = "server/mcp-diagnostics",           -- Build directory
    
    -- Auto-launch settings  
    auto_launch = true,
    node_server_path = "server/mcp-diagnostics/dist/index.js",
    node_args = {"--launch-nvim", "--tcp-port", "6666"},  -- Launch Neovim via Node.js
    node_env = {                                          -- Environment variables
      NVIM_SERVER_ADDRESS = "127.0.0.1:6666"
    },
    
    -- Monitoring
    restart_on_crash = true,     -- Restart Node.js server if it crashes
    health_check_interval = 5000, -- Check server health every 5s
  }
})
```

## 🛠️ Manual Server Commands

### Available npm Scripts

```bash
cd server/mcp-diagnostics

# Build TypeScript
npm run build

# Start server (connect to existing Neovim)
npm start

# Start with auto-launched Neovim (socket)
npm run start:nvim-server

# Start with auto-launched Neovim (TCP)
npm run start:nvim-server:tcp

# Development mode (rebuild and restart)
npm run dev

# Development with TCP
npm run dev:tcp

# Watch for changes
npm run watch
```

### Direct Node.js Invocation

```bash
cd server/mcp-diagnostics

# Basic connection to existing Neovim
node dist/index.js

# Auto-launch Neovim with socket
node dist/index.js --launch-nvim

# Auto-launch Neovim with TCP
node dist/index.js --launch-nvim --tcp-port 6666

# Auto-launch with custom config
node dist/index.js --launch-nvim --nvim-config /path/to/init.lua

# TCP server mode (for external Neovim)
node dist/index.js --tcp-port 3000 --tcp-host 0.0.0.0
```

## 🔧 Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `NVIM_SERVER_ADDRESS` | `/tmp/nvim.sock` | Socket path or TCP address for Neovim |
| `MCP_SERVER_NAME` | `mcp-neovim-diagnostics` | MCP server identifier |
| `NVIM_LAUNCH_TIMEOUT` | `10000` | Timeout for Neovim launch (ms) |
| `NVIM_CONFIG_PATH` | | Custom Neovim config file path |

## 🚦 Server Launch Modes

### Mode 1: External Neovim (Manual)
You manage Neovim separately:

1. Start Neovim: `nvim --listen /tmp/nvim.sock`
2. Configure plugins, LSP, open files
3. Start MCP server: `npm start`
4. MCP server connects to existing Neovim

**Pros:** Full control, can use existing Neovim session
**Cons:** Manual setup, need to coordinate addresses

### Mode 2: Auto-Launch Neovim (Recommended)
MCP server launches and manages Neovim:

1. Start MCP server: `npm run start:nvim-server`
2. MCP server launches Neovim with `--listen` flag
3. MCP server waits for Neovim to be ready
4. Both run together, MCP server manages lifecycle

**Pros:** Automatic setup, guaranteed coordination
**Cons:** Less control over Neovim session

### Mode 3: Plugin Auto-Build (Full Automation)
Neovim plugin builds and launches everything:

1. Configure plugin with `auto_build = true, auto_launch = true`
2. Load Neovim with plugin
3. Plugin runs `npm install && npm run build`
4. Plugin launches Node.js MCP server
5. Node.js server optionally launches second Neovim instance

**Pros:** Zero manual setup, everything automated
**Cons:** Complex setup, resource intensive

## 🔍 Troubleshooting

### Build Issues
```bash
# Clean rebuild
cd server/mcp-diagnostics
rm -rf node_modules dist
npm install
npm run build
```

### Connection Issues
```bash
# Test Neovim connection
node test_connection.js

# Test TCP connection
node test_tcp_connection.js

# Check what's listening
lsof -i :6666  # For TCP
lsof /tmp/nvim.sock  # For socket
```

### Auto-Launch Issues
- Check Neovim is in PATH: `which nvim`
- Verify socket/port not in use
- Check file permissions for socket path
- Review MCP server logs for launch errors

### Plugin Auto-Build Issues
- Ensure Node.js installed: `node --version`
- Check npm permissions
- Verify TypeScript compiles: `cd server/mcp-diagnostics && npm run build`
- Check Neovim has access to filesystem for npm commands

## 💡 Best Practices

### For Development
- Use auto-launch mode for consistent environment
- Enable `watch` mode for TypeScript development
- Use TCP for better performance and debugging
- Set up health checks and auto-restart

### For Production/Daily Use  
- Use plugin auto-build for simplicity
- Configure appropriate timeouts
- Use socket connections for security
- Enable crash recovery and logging

### For External Tools (Claude Desktop)
- Use auto-launch mode for reliability
- Set absolute paths in configs
- Test configuration with manual launch first
- Monitor logs for connection issues