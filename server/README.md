# MCP Diagnostics Server

This directory contains the **Node.js MCP Server** implementation that provides diagnostic and LSP capabilities to external MCP clients like Claude Desktop.

## Directory Structure

```
server/
├── mcp-diagnostics/          # Node.js MCP server implementation
│   ├── package.json         # Dependencies and build scripts
│   ├── tsconfig.json        # TypeScript configuration
│   ├── src/                 # TypeScript source code
│   │   ├── index.ts         # Main MCP server entry point
│   │   ├── neovim-manager.ts # Neovim connection management
│   │   └── tcp-transport.ts  # TCP transport implementation
│   ├── dist/                # Compiled JavaScript output
│   │   └── index.js         # Main compiled entry point
│   └── test_*.js           # Connection test utilities
└── README.md               # This file
```

## Setup

### 1. Install Dependencies
```bash
cd server/mcp-diagnostics
npm install
```

### 2. Build TypeScript
```bash
npm run build
```

### 3. Configure Neovim Plugin
Use the server mode in your Neovim configuration:

```lua
require("mcp-diagnostics").setup({
  mode = "server",
  server = {
    server_address = '/tmp/nvim.sock',  -- or TCP address
    auto_start_server = true,
  }
})
```

### 4. Configure MCP Client

#### Claude Desktop
Add to `~/.claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "neovim-diagnostics": {
      "command": "node",
      "args": ["/absolute/path/to/server/mcp-diagnostics/dist/index.js"],
      "env": {
        "NVIM_SERVER_ADDRESS": "/tmp/nvim.sock"
      }
    }
  }
}
```

#### TCP Configuration
For TCP connections:

```json
{
  "mcpServers": {
    "neovim-diagnostics": {
      "command": "node",
      "args": ["/absolute/path/to/server/mcp-diagnostics/dist/index.js"],
      "env": {
        "NVIM_SERVER_ADDRESS": "127.0.0.1:6666"
      }
    }
  }
}
```

## Usage

### Available MCP Tools

The server provides these MCP tools to external clients:

#### Diagnostic Tools
- `diagnostics_get` - Get diagnostics with filtering
- `diagnostics_summary` - Get diagnostic counts and summary

#### LSP Tools
- `lsp_hover` - Get hover information at cursor position
- `lsp_definition` - Find symbol definitions
- `lsp_references` - Find symbol references
- `lsp_symbols` - Get document symbols
- `lsp_workspace_symbols` - Search workspace symbols
- `lsp_code_action` - Get available code actions

#### Buffer Management
- `ensure_files_loaded` - Load files into Neovim buffers
- `buffer_status` - Get buffer status information

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `NVIM_SERVER_ADDRESS` | `/tmp/nvim.sock` | Socket path or TCP address for Neovim connection |
| `MCP_SERVER_NAME` | `neovim-diagnostics` | MCP server identifier |

### Testing Connection

Test the connection to Neovim:

```bash
# Test socket connection
node test_connection.js

# Test TCP connection  
node test_tcp_connection.js
```

## Development

### Build and Run
```bash
# Development build and run
npm run dev

# Build for production
npm run build

# Start server
npm start

# Start with TCP
npm run start:tcp
```

### Scripts

| Script | Description |
|--------|-------------|
| `npm run build` | Compile TypeScript to JavaScript |
| `npm start` | Run the compiled server |
| `npm run dev` | Build and run in development mode |
| `npm run start:tcp` | Run with TCP on port 3000 |
| `npm run watch` | Watch for changes and rebuild |

## Architecture

The server acts as a bridge between MCP clients (like Claude Desktop) and Neovim:

```
MCP Client (Claude Desktop) 
         ↕ MCP Protocol
Node.js Server (this directory)
         ↕ RPC/Socket/TCP  
Neovim Instance (with mcp-diagnostics plugin)
         ↕ LSP/Diagnostics
Language Servers & Files
```

## Troubleshooting

### Server Won't Start
- Check Node.js version (requires Node.js 16+)
- Verify all dependencies installed (`npm install`)
- Ensure TypeScript compiled (`npm run build`)

### Can't Connect to Neovim
- Verify Neovim server is running (check `:MCPStatus` in Neovim)
- Check `NVIM_SERVER_ADDRESS` matches Neovim server address
- Test connection manually with test scripts

### No Tools Available in Claude Desktop
- Restart Claude Desktop after configuration changes
- Verify absolute paths in Claude Desktop config
- Check Claude Desktop logs for connection errors

### LSP Operations Fail
- Ensure LSP servers are running in Neovim (`:LspInfo`)
- Use `ensure_files_loaded` tool to load files first
- Check that files have appropriate LSP servers configured

## Comparison with mcphub Integration

| Feature | Node.js Server (this) | mcphub Integration |
|---------|----------------------|-------------------|
| **Setup** | Complex (Node.js + build) | Simple |
| **External Access** | ✅ Any MCP client | ❌ mcphub.nvim only |
| **Performance** | Network overhead | In-process |
| **Dependencies** | Node.js ecosystem | Pure Lua |
| **Maintenance** | Separate process | Self-contained |

Choose this Node.js server if you need external MCP client access (like Claude Desktop) or want a standalone server that can work with multiple tools.