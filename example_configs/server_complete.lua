-- Complete External Server Integration Example
-- For use with Claude Desktop, external MCP clients, or Node.js applications

return {
  {
    "georgeharker/mcp-diagnostics.nvim",
    config = function()
      require("mcp-diagnostics").setup({
        mode = "server",
        
        server = {
          -- 🌐 Server Connection
          server_address = '/tmp/nvim-mcp-diagnostics.sock', -- Socket path
          -- Alternative TCP configuration:
          -- server_host = '127.0.0.1',
          -- server_port = 6666,
          
          -- 🚀 Startup Behavior  
          auto_start_server = true,    -- Automatically start the server
          auto_build = false,          -- Auto-build Node.js server if needed
          auto_launch = false,         -- Auto-launch Node.js MCP server
          
          -- 📁 File Paths
          export_path = '/tmp/nvim_diagnostics.json', -- Export location
          node_server_path = nil,      -- Auto-detected if nil
          build_cwd = nil,            -- Auto-detected if nil
          
          -- 🔧 Build Configuration (for Node.js server)
          build_command = 'npm install && npm run build',
          node_args = {},             -- Additional Node.js arguments
          node_env = {},              -- Environment variables
          
          -- 🔄 Reliability  
          restart_on_crash = true,    -- Restart server if it crashes
          health_check_interval = 5000, -- Health check interval (ms)
          
          -- 📂 File Management
          auto_reload_files = true,   -- Auto-reload files changed externally
          auto_reload_mode = "auto",  -- "auto", "prompt", "off"
          file_deletion_mode = "prompt", -- "ignore", "prompt", "auto"
          
          -- 📊 Data Limits
          max_diagnostics = 100,      -- Higher limits for external consumption
          max_references = 50,
          max_symbols = 200,
          show_source = true,
        }
      })
      
      -- Optional: Manual server management commands
      vim.api.nvim_create_user_command('MCPServerStart', function()
        require("mcp-diagnostics.server").start_server()
      end, { desc = 'Start MCP diagnostics server' })
      
      vim.api.nvim_create_user_command('MCPServerStop', function()
        require("mcp-diagnostics.server").stop_all()
      end, { desc = 'Stop MCP diagnostics server' })
      
      vim.api.nvim_create_user_command('MCPServerStatus', function()
        require("mcp-diagnostics.server").status()
      end, { desc = 'Check MCP server status' })
      
      vim.api.nvim_create_user_command('MCPExportDiagnostics', function()
        local success = require("mcp-diagnostics.server").export_diagnostics()
        if success then
          vim.notify("Diagnostics exported successfully", vim.log.levels.INFO)
        else
          vim.notify("Failed to export diagnostics", vim.log.levels.ERROR)
        end
      end, { desc = 'Export diagnostics to JSON' })
    end
  }
}

--[[
## 🔌 Claude Desktop Configuration

Add this to your Claude Desktop config file (~/.claude_desktop_config.json):

```json
{
  "mcpServers": {
    "mcp-diagnostics": {
      "command": "node",
      "args": ["/path/to/your/plugin/server/mcp-diagnostics/dist/index.js"],
      "env": {
        "NVIM_SERVER_ADDRESS": "/tmp/nvim-mcp-diagnostics.sock"
      }
    }
  }
}
```

## 🛠️ Node.js Server Setup

1. **Build the server** (one-time setup):
```bash
cd ~/.local/share/nvim/lazy/mcp-diagnostics.nvim/server/mcp-diagnostics
npm install && npm run build
```

2. **Verify the build**:
```bash
ls -la dist/index.js  # Should exist
```

3. **Update Claude config** with the correct path to `dist/index.js`

## 🔧 Available Server Functions

The server exposes these functions for external MCP clients:

### 📊 Diagnostic Functions
- `diagnostic_summary()` - Overall diagnostic counts and breakdown
- `document_diagnostics(severity?, source?)` - Current file diagnostics  
- `workspace_diagnostics(files?, severity?, source?)` - Multi-file diagnostics
- `diagnostic_hotspots(limit?)` - Most problematic files ranked by severity
- `diagnostic_stats()` - Advanced analytics with error patterns
- `diagnostic_by_severity(severity)` - Filter by error/warn/info/hint

### 🔮 LSP Functions
- `lsp_hover(file, line, column)` - Symbol information and documentation
- `lsp_definition(file, line, column)` - Find symbol definitions
- `lsp_references(file, line, column)` - Find all symbol usages
- `lsp_document_symbols(file)` - Document structure overview
- `lsp_workspace_symbols(query?)` - Project-wide symbol search  
- `lsp_code_actions(file, line, column, end_line?, end_column?)` - Available fixes

### 📋 Buffer Management Functions
- `buffer_status()` - All loaded files with diagnostic counts
- `ensure_files_loaded(files)` - Load specific files for analysis
- `refresh_after_external_changes(files?)` - Sync after external edits

### 🔧 Server Management Functions  
- `start_server(address?)` - Start the Neovim server
- `start_socket(path?)` - Start socket server
- `start_tcp_server(host?, port?)` - Start TCP server
- `status()` - Get server status
- `stop_all()` - Stop all servers
- `export_diagnostics(filename?)` - Export diagnostics to JSON

## 🎮 Usage in External Clients

### Claude Desktop
"Analyze the error patterns in my Neovim project and suggest fixes"
→ Claude will call diagnostic_stats() and diagnostic_hotspots() automatically

"Show me the definition of the function under my cursor"  
→ Claude will call lsp_definition() with current position

### Custom MCP Applications
```javascript
// Example Node.js MCP client usage
const client = new MCPClient();
await client.connect('unix:///tmp/nvim-mcp-diagnostics.sock');

// Get diagnostic overview
const summary = await client.call('diagnostic_summary');

// Get most problematic files
const hotspots = await client.call('diagnostic_hotspots', { limit: 5 });

// Get symbol information
const hover = await client.call('lsp_hover', {
  file: '/path/to/file.lua',
  line: 42,
  column: 10
});
```

## 🚀 Advanced Configuration

### TCP Server (Alternative to Socket)
```lua
server = {
  server_host = '127.0.0.1',
  server_port = 6666,
  -- ... other options
}
```

### Environment Variables
```lua  
server = {
  node_env = {
    DEBUG = "mcp-diagnostics:*",  -- Enable debug logging
    NODE_ENV = "production",
  },
  -- ... other options
}
```

### Custom Build Process
```lua
server = {
  build_command = 'yarn install && yarn build',
  build_cwd = '/custom/server/path',
  -- ... other options  
}
```

## 🔍 Troubleshooting

1. **Server won't start**: Check that the socket path is writable
2. **Claude can't find server**: Verify the path in claude_desktop_config.json
3. **Build fails**: Ensure Node.js and npm are installed
4. **Connection issues**: Check firewall settings for TCP mode

Use `:MCPServerStatus` to check server health and connection status.

--]]