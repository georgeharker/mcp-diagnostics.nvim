-- Example configuration for External Node.js MCP Server integration
-- Based on the original mcp-diagnostics/config.lua

return {
  -- Basic setup with socket connection
  basic_socket = function()
    require("mcp-diagnostics").setup({
      mode = "server",
      server = {
        server_address = '/tmp/nvim.sock',
        auto_start_server = true,
      }
    })
  end,

  -- TCP connection setup
  tcp_setup = function()
    require("mcp-diagnostics").setup({
      mode = "server",
      server = {
        server_host = '127.0.0.1',
        server_port = 6666,
        server_address = '127.0.0.1:6666',
        auto_start_server = true,
      }
    })
  end,

  -- Custom configuration
  custom_setup = function()
    require("mcp-diagnostics").setup({
      mode = "server",
      server = {
        server_address = '/tmp/my_nvim.sock',
        auto_start_server = false,  -- Manual start
        export_path = '/home/user/diagnostics.json',
      }
    })

    -- Manual server start after delay
    vim.defer_fn(function()
      local server = require("mcp-diagnostics").server_module()
      server.start_server()
    end, 2000)
  end,

  -- Direct server module usage (advanced)
  direct_usage = function()
    local server_module = require("mcp-diagnostics.server")
    local server = server_module

    server.setup({
      server_address = '/tmp/nvim.sock',
      auto_start_server = true,
    })

    -- Export diagnostics periodically
    vim.api.nvim_create_autocmd({"DiagnosticChanged"}, {
      callback = function()
        server.export_diagnostics()
      end
    })
  end,

  -- Auto-build and launch Node.js server
  auto_build_launch = function()
    require("mcp-diagnostics").setup({
      mode = "server",
      server = {
        -- Neovim server
        server_address = '/tmp/nvim.sock',
        auto_start_server = true,

        -- Node.js MCP server
        auto_build = true,          -- Build Node.js server
        auto_launch = true,         -- Launch Node.js server
        restart_on_crash = true,    -- Restart if crashed
      }
    })
  end,

  -- Advanced auto-launch with custom config
  advanced_auto_launch = function()
    require("mcp-diagnostics").setup({
      mode = "server",
      server = {
        -- Neovim settings
        server_address = '127.0.0.1:6666',
        auto_start_server = true,

        -- Build settings
        auto_build = true,
        build_command = 'npm ci && npm run build',  -- Use npm ci for production

        -- Launch settings
        auto_launch = true,
        node_args = {'--launch-nvim', '--tcp-port', '6666'},  -- Auto-launch Neovim via Node.js
        node_env = {
          NVIM_SERVER_ADDRESS = '127.0.0.1:6666',
          NODE_ENV = 'production'
        },

        -- Monitoring
        restart_on_crash = true,
        health_check_interval = 3000,
      }
    })
  end,

  -- Manual Node.js server management
  manual_nodejs_management = function()
    require("mcp-diagnostics").setup({
      mode = "server",
      server = {
        server_address = '/tmp/nvim.sock',
        auto_start_server = true,
        auto_build = false,    -- Manual build
        auto_launch = false,   -- Manual launch
      }
    })

    -- Manual commands available:
    -- :MCPBuildServer
    -- :MCPLaunchServer
    -- :MCPStopServer
    -- :MCPServerStatus
    -- :MCPBuildAndLaunch
  end,

  -- Development setup with auto-rebuild
  development_setup = function()
    require("mcp-diagnostics").setup({
      mode = "server",
      server = {
        server_address = '/tmp/nvim_dev.sock',
        auto_start_server = true,

        -- Development build
        auto_build = true,
        build_command = 'npm install && npm run build',

        -- Development launch
        auto_launch = true,
        node_args = {'--launch-nvim'},
        restart_on_crash = true,
        health_check_interval = 1000,  -- More frequent checks
      }
    })

    -- Auto-rebuild on TypeScript changes
    vim.api.nvim_create_autocmd({"BufWritePost"}, {
      pattern = "*/mcp-diagnostics/server/mcp-diagnostics/src/*.ts",
      callback = function()
        local server_module = require("mcp-diagnostics.server")
        local server = server_module
        vim.notify("TypeScript file changed, rebuilding...", vim.log.levels.INFO)
        server.build_node_server()
      end
    })
  end,

  -- Claude Desktop ready configuration
  claude_desktop_ready = function()
    require("mcp-diagnostics").setup({
      mode = "server",
      server = {
        -- Use absolute socket path for reliability
        server_address = os.getenv("HOME") .. '/.nvim/mcp-diagnostics.sock',
        auto_start_server = true,

        -- Ensure server is built and ready
        auto_build = true,
        build_command = 'npm ci && npm run build',  -- Production build

        -- Don't auto-launch - let Claude Desktop manage it
        auto_launch = false,

        -- Export diagnostics for external access
        export_path = os.getenv("HOME") .. '/.nvim/diagnostics.json',
      }
    })

    -- Auto-export diagnostics when they change
    vim.api.nvim_create_autocmd({"DiagnosticChanged"}, {
      callback = function()
        vim.defer_fn(function()
          local server_module = require("mcp-diagnostics.server")
          local server = server_module
          server.export_diagnostics()
        end, 500)
      end
    })
  end,

  -- Full automation setup
  full_automation = function()
    require("mcp-diagnostics").setup({
      mode = "server",
      server = {
        -- Neovim server
        server_address = '/tmp/nvim.sock',
        auto_start_server = true,

        -- Node.js server automation
        auto_build = true,
        auto_launch = true,

        -- Auto-launch Neovim through Node.js server
        node_args = {'--launch-nvim'},
        node_env = {
          NVIM_SERVER_ADDRESS = '/tmp/nvim.sock'
        },

        -- Full monitoring and recovery
        restart_on_crash = true,
        health_check_interval = 5000,
      }
    })

    vim.notify("Full MCP Diagnostics automation enabled", vim.log.levels.INFO)
    vim.notify("Neovim server, Node.js build, and MCP server will all be managed automatically", vim.log.levels.INFO)
  end,
}
