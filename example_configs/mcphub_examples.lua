-- Example configurations for mcphub.nvim integration
-- Based on the original mcp-diagnostics/examples/mcphub_config.lua

return {
  -- Method 1: Simple setup using unified interface
  simple_setup = function()
    require("mcp-diagnostics").setup({
      mode = "mcphub"
    })
  end,

  -- Method 2: Custom configuration with specific options
  custom_setup = function()
    require("mcp-diagnostics").setup({
      mode = "mcphub",
      mcphub = {
        server_name = "my-diagnostics-server",
        displayName = "My Custom Diagnostics Server",
        debug = true,
        enable_lsp = true,
        enable_diagnostics = true,
        enable_prompts = true,
        lsp_timeout = 2000,
        auto_register = true
      }
    })
  end,

-- Auto-approve setup (automatically approves tool execution)
auto_approve_setup = function()
  require("mcp-diagnostics").setup({
    mode = "mcphub",
    mcphub = {
      auto_approve = true,  -- Automatically approve tool execution (mcphub autoApprove)
      debug = false
    }
  })
end,

-- Full auto setup with all features and auto-approve
full_auto_approve_setup = function()
  require("mcp-diagnostics").setup({
    mode = "mcphub",
    mcphub = {
      auto_approve = true,
      auto_register = true,
      debug = true,
      enable_diagnostics = true,
      enable_lsp = true,
      enable_prompts = true,
      server_name = "mcp-diagnostics-auto", 
      displayName = "Neovim Diagnostics (Auto-Approve)"
    }
  })
end,

  -- Method 3: Direct mcphub module usage
  direct_mcphub_setup = function()
  -- Using direct submodule access (different from main plugin module)
    local mcphub_module = require("mcp-diagnostics.mcphub")

    mcphub_module.setup({
      server_name = "neovim-diagnostics",
      displayName = "Neovim Diagnostics & LSP",
      debug = false,
      auto_register = true
    })
  end,

  -- Method 4: Quick setup shortcuts
  quick_setups = {
    -- Quick setup
    quick = function()
      require("mcp-diagnostics").mcphub()
    end,

    -- Development setup with debugging
    dev = function()
      local mcphub_module = require("mcp-diagnostics.mcphub.init")
      mcphub_module.dev_setup()
    end,

    -- Minimal setup (diagnostics only)
    minimal = function()
      local mcphub_module = require("mcp-diagnostics.mcphub.init")
      mcphub_module.minimal_setup()
    end,
  },

  -- Method 5: Manual registration for advanced users
  manual_setup = function()
    local has_mcphub, mcphub = pcall(require, "mcphub")
    if not has_mcphub then
      vim.notify("mcphub.nvim not found", vim.log.levels.ERROR)
      return
    end

    -- Load core functionality
    local core = require("mcp-diagnostics.mcphub.core")
    local tools = require("mcp-diagnostics.mcphub.tools")
    local resources = require("mcp-diagnostics.mcphub.resources")
    local prompts = require("mcp-diagnostics.mcphub.prompts")

    local server_name = "mcp-diagnostics"

    -- Register components manually
    tools.register_all(mcphub, server_name, core)
    resources.register_all(mcphub, server_name, core)
    prompts.register_all(mcphub, server_name, core)

    vim.notify("MCP Diagnostics registered manually with mcphub.nvim", vim.log.levels.INFO)
  end,

  -- Method 6: Lazy loading approach
  lazy_setup = function()
    -- Only load when mcphub is available
    vim.api.nvim_create_autocmd("User", {
      pattern = "McpHubReady", -- If mcphub.nvim provides this event
      callback = function()
        require("mcp-diagnostics").mcphub()
      end,
      once = true
    })

    -- Fallback timer-based approach
    vim.defer_fn(function()
      local has_mcphub = pcall(require, "mcphub")
      if has_mcphub then
        require("mcp-diagnostics").mcphub()
      end
    end, 1000)
  end,

  -- Method 7: Multiple server configurations
  multiple_servers = function()
    -- Register multiple diagnostic servers for different projects
    require("mcp-diagnostics").setup({
      mode = "mcphub",
      mcphub = {
        server_name = "project-diagnostics",
        displayName = "Project Diagnostics",
      }
    })

    -- Second server for test diagnostics
    local mcphub_module = require("mcp-diagnostics.mcphub.init")
    mcphub_module.setup({
      server_name = "test-diagnostics",
      displayName = "Test Suite Diagnostics",
      enable_lsp = false,  -- Only diagnostics for tests
    })
  end,

  -- Method 8: Integration with lazy.nvim
  lazy_nvim_config = {
    {
      "ravitemer/mcphub.nvim",
      config = function()
        require("mcphub").setup()
      end
    },
    {
      "your-username/mcp-diagnostics",
      dependencies = { "ravitemer/mcphub.nvim" },
      event = "VeryLazy",  -- Load after mcphub
      config = function()
        require("mcp-diagnostics").setup({
          mode = "mcphub",
          mcphub = {
            debug = false,
            auto_register = true
          }
        })
      end
    }
  },
}
