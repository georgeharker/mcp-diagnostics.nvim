-- External Node.js MCP Server Integration for MCP Diagnostics
-- Provides setup and management for Node.js MCP server communication

local M = {}

-- File watching state for auto-reloading (server variant)
local server_file_watchers = {}
local server_buffer_file_times = {}

M.config = {
  server_address = '/tmp/nvim.sock',  -- Can be socket path or TCP address
  server_host = '127.0.0.1',
  server_port = 6666,
  auto_start_server = false,  -- Set to true to auto-start server
  export_path = '/tmp/nvim_diagnostics.json',
  -- Node.js MCP server auto-build and launch
  auto_build = false,         -- Auto-build Node.js server
  auto_launch = false,        -- Auto-launch Node.js MCP server
  node_server_path = nil,     -- Path to Node.js server (auto-detected)
  build_command = 'npm install && npm run build',
  build_cwd = nil,            -- Build directory (auto-detected)
  node_args = {},             -- Additional Node.js server arguments
  node_env = {},              -- Environment variables for Node.js server
  restart_on_crash = true,    -- Restart Node.js server if it crashes
  health_check_interval = 5000, -- Health check interval in ms
  auto_reload_files = true,   -- Automatically reload files when they change on disk
}

-- File auto-reload functionality for server variant
local function get_file_mtime(filepath)
  local stat = vim.loop.fs_stat(filepath)
  return stat and stat.mtime.sec or 0
end

local function setup_server_file_watcher(filepath, bufnr)
  if server_file_watchers[filepath] then
    return -- Already watching this file
  end

  print("[MCP Diagnostics Server] Setting up file watcher for: " .. filepath)

  -- Store initial modification time
  server_buffer_file_times[filepath] = get_file_mtime(filepath)

  -- Create file watcher using vim.loop (libuv)
  local watcher = vim.loop.new_fs_event()
  if not watcher then
    print("[MCP Diagnostics Server] Failed to create file watcher for: " .. filepath)
    return
  end

  server_file_watchers[filepath] = watcher

  local function on_file_change(err, _filename, _events)
    if err then
      print("[MCP Diagnostics Server] File watcher error for " .. filepath .. ": " .. err)
      return
    end

    -- Check if file actually changed (avoid duplicate events)
    local current_mtime = get_file_mtime(filepath)
    local last_mtime = server_buffer_file_times[filepath] or 0

    if current_mtime > last_mtime then
      server_buffer_file_times[filepath] = current_mtime
      print("[MCP Diagnostics Server] File changed, reloading buffer: " .. filepath)

      vim.schedule(function()
        -- Check if buffer is still valid and loaded
        if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
          -- Reload the buffer content
          local ok, err_msg = pcall(function()
            vim.api.nvim_buf_call(bufnr, function()
              vim.cmd('edit!')
            end)
          end)

          if ok then
            print("[MCP Diagnostics Server] Successfully reloaded buffer: " .. filepath)
            vim.notify("Auto-reloaded: " .. vim.fn.fnamemodify(filepath, ":t"), vim.log.levels.INFO)
          else
            print("[MCP Diagnostics Server] Failed to reload buffer " .. filepath .. ": " .. tostring(err_msg))
          end
        else
          -- Buffer is no longer valid, clean up watcher
          M.cleanup_server_file_watcher(filepath)
        end
      end)
    end
  end

  -- Start watching the file
  local ok, watch_err = pcall(function()
    watcher:start(filepath, {}, on_file_change)
  end)

  if not ok then
    print("[MCP Diagnostics Server] Failed to start file watcher for " .. filepath .. ": " .. tostring(watch_err))
    server_file_watchers[filepath] = nil
    watcher:close()
  else
    print("[MCP Diagnostics Server] File watcher started for: " .. filepath)
  end
end

function M.cleanup_server_file_watcher(filepath)
  local watcher = server_file_watchers[filepath]
  if watcher then
    watcher:stop()
    watcher:close()
    server_file_watchers[filepath] = nil
    server_buffer_file_times[filepath] = nil
    print("[MCP Diagnostics Server] Cleaned up file watcher for: " .. filepath)
  end
end

function M.cleanup_all_server_watchers()
  for _filepath, watcher in pairs(server_file_watchers) do
    watcher:stop()
    watcher:close()
  end
  server_file_watchers = {}
  server_buffer_file_times = {}
  print("[MCP Diagnostics Server] Cleaned up all file watchers")
end

-- Enhanced buffer loading with auto-reload support
function M.ensure_buffer_loaded_with_reload(filepath, enable_auto_reload)
  print("[MCP Diagnostics Server] Ensuring buffer loaded: " .. filepath)

  -- Default to auto-reload enabled unless explicitly disabled
  if enable_auto_reload == nil then
    enable_auto_reload = M.config.auto_reload_files ~= false
  end

  local bufnr = vim.fn.bufnr(filepath)
  if bufnr == -1 then
    -- Buffer doesn't exist, create it
    bufnr = vim.fn.bufnr(filepath, true)
  end

  if not vim.api.nvim_buf_is_loaded(bufnr) then
    -- Load the buffer
    vim.fn.bufload(bufnr)
  end

  -- Set up auto-reload watcher if enabled and file exists
  if enable_auto_reload and vim.fn.filereadable(filepath) == 1 then
    setup_server_file_watcher(filepath, bufnr)

    -- Set up buffer cleanup when buffer is deleted
    vim.api.nvim_create_autocmd("BufDelete", {
      buffer = bufnr,
      callback = function()
        M.cleanup_server_file_watcher(filepath)
      end,
      once = true
    })
  end

  local loaded = vim.api.nvim_buf_is_loaded(bufnr)
  print("[MCP Diagnostics Server] Buffer " .. filepath .. " loaded: " .. tostring(loaded) ..
        ", auto-reload: " .. tostring(enable_auto_reload))
  return bufnr, loaded
end

-- Start server (socket or TCP based on address format)
function M.start_server(address)
  address = address or M.config.server_address
  local success = vim.fn.serverstart(address)
  if success then
    local actual_address = success == 1 and address or success
    vim.notify('[MCP Diagnostics] Server started at ' .. actual_address, vim.log.levels.INFO)
    return actual_address
  else
    vim.notify('[MCP Diagnostics] Failed to start server at ' .. address, vim.log.levels.ERROR)
    return nil
  end
end

-- Start socket server
function M.start_socket(path)
  path = path or '/tmp/nvim.sock'
  local success = vim.fn.serverstart(path)
  if success then
    local actual_address = success == 1 and path or success
    vim.notify('[MCP Diagnostics] Socket server started at ' .. actual_address, vim.log.levels.INFO)
    return actual_address
  else
    vim.notify('[MCP Diagnostics] Failed to start socket server at ' .. path, vim.log.levels.ERROR)
    return nil
  end
end

-- Start TCP server
function M.start_tcp_server(host, port)
  host = host or M.config.server_host
  port = port or M.config.server_port
  local address = host .. ':' .. port
  local success = vim.fn.serverstart(address)
  if success then
    local actual_address = success == 1 and address or success
    vim.notify('[MCP Diagnostics] TCP server started at ' .. actual_address, vim.log.levels.INFO)
    return actual_address
  else
    vim.notify('[MCP Diagnostics] Failed to start TCP server at ' .. address, vim.log.levels.ERROR)
    return nil
  end
end

-- Get current server status
function M.status()
  local servers = vim.fn.serverlist()
  if #servers > 0 then
    vim.notify('[MCP Diagnostics] Active servers:', vim.log.levels.INFO)
    for _, server in ipairs(servers) do
      print('  - ' .. server)
    end
  else
    vim.notify('[MCP Diagnostics] No active servers', vim.log.levels.WARN)
  end
  return servers
end

-- Stop all servers
function M.stop_all()
  local servers = vim.fn.serverlist()
  for _, server in ipairs(servers) do
    vim.fn.serverstop(server)
    vim.notify('[MCP Diagnostics] Stopped server ' .. server, vim.log.levels.INFO)
  end
end

-- Get diagnostic summary
function M.diagnostic_summary()
  local diagnostics = vim.diagnostic.get()
  local summary = { error = 0, warn = 0, info = 0, hint = 0 }

  for _, diag in ipairs(diagnostics) do
    if diag.severity == vim.diagnostic.severity.ERROR then
      summary.error = summary.error + 1
    elseif diag.severity == vim.diagnostic.severity.WARN then
      summary.warn = summary.warn + 1
    elseif diag.severity == vim.diagnostic.severity.INFO then
      summary.info = summary.info + 1
    elseif diag.severity == vim.diagnostic.severity.HINT then
      summary.hint = summary.hint + 1
    end
  end

  vim.notify(string.format('[MCP Diagnostics] %d errors, %d warnings, %d info, %d hints',
    summary.error, summary.warn, summary.info, summary.hint), vim.log.levels.INFO)

  return summary
end

function M.export_diagnostics(filename)
  filename = filename or M.config.export_path
  local diagnostics = vim.diagnostic.get()
  local data = {}

  for _, diag in ipairs(diagnostics) do
    local bufnr = diag.bufnr
    local filepath = bufnr and vim.api.nvim_buf_get_name(bufnr) or ''
    local lnum = diag.lnum and tonumber(diag.lnum) or 0
    local col = diag.col and tonumber(diag.col) or 0

    -- Auto-reload file if configured
    if M.config.auto_reload_files and filepath ~= '' then
      M.ensure_buffer_loaded_with_reload(filepath, true)
    end

    table.insert(data, {
      bufnr = bufnr,
      filename = filepath,
      lnum = lnum,
      col = col,
      end_lnum = diag.end_lnum and tonumber(diag.end_lnum) or lnum,
      end_col = diag.end_col and tonumber(diag.end_col) or col,
      severity = diag.severity,
      message = diag.message,
      source = diag.source or '',
      code = diag.code or ''
    })
  end

  local json = vim.json.encode(data)
  local file = io.open(filename, 'w')
  if file then
    file:write(json)
    file:close()
    vim.notify('[MCP Diagnostics] Exported diagnostics to ' .. filename, vim.log.levels.INFO)
    return true
  else
    vim.notify('[MCP Diagnostics] Failed to export diagnostics to ' .. filename, vim.log.levels.ERROR)
    return false
  end
end

-- Node.js server management
local node_server_job = nil
local health_check_timer = nil

-- Auto-detect paths
local function detect_paths()
  local plugin_root = vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ':h:h:h:h')
  local server_dir = plugin_root .. '/server/mcp-diagnostics'
  local server_script = server_dir .. '/dist/index.js'

  return {
    plugin_root = plugin_root,
    server_dir = server_dir,
    server_script = server_script,
    package_json = server_dir .. '/package.json'
  }
end

-- Build Node.js server
function M.build_node_server()
  local paths = detect_paths()
  local build_cwd = M.config.build_cwd or paths.server_dir

  -- Check if package.json exists
  if vim.fn.filereadable(paths.package_json) == 0 then
    vim.notify('[MCP Diagnostics] Node.js server not found at ' .. paths.server_dir, vim.log.levels.ERROR)
    return false
  end

  vim.notify('[MCP Diagnostics] Building Node.js server...', vim.log.levels.INFO)

  -- Use shell to properly handle && operators and other shell features
  local cmd = vim.fn.has('win32') == 1
    and {'cmd', '/c', M.config.build_command}
    or {'sh', '-c', M.config.build_command}
  local job = vim.fn.jobstart(cmd, {
    cwd = build_cwd,
    on_exit = function(_, code)
      if code == 0 then
        vim.notify('[MCP Diagnostics] Node.js server built successfully', vim.log.levels.INFO)
      else
        vim.notify('[MCP Diagnostics] Failed to build Node.js server (exit code: ' .. code .. ')\n' ..
                   'Try running: npm install && npm run build\n' ..
                   'In directory: ' .. build_cwd, vim.log.levels.ERROR)
      end
    end,
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line and line ~= '' then
          print('[Build] ' .. line)
        end
      end
    end,
    on_stderr = function(_, data)
      for _, line in ipairs(data) do
        if line and line ~= '' then
          print('[Build Error] ' .. line)
        end
      end
    end
  })

  if job == 0 then
    vim.notify('[MCP Diagnostics] Failed to start build process', vim.log.levels.ERROR)
    return false
  end

  return true
end

-- Launch Node.js MCP server
function M.launch_node_server()
  if node_server_job and vim.fn.jobwait({node_server_job}, 0)[1] == -1 then
    vim.notify('[MCP Diagnostics] Node.js server is already running', vim.log.levels.WARN)
    return true
  end

  local paths = detect_paths()
  local server_script = M.config.node_server_path or paths.server_script

  -- Check if server script exists
  if vim.fn.filereadable(server_script) == 0 then
    vim.notify('[MCP Diagnostics] Node.js server script not found: ' .. server_script, vim.log.levels.ERROR)
    vim.notify('[MCP Diagnostics] Try building first with :MCPBuildServer', vim.log.levels.INFO)
    return false
  end

  -- Prepare command and environment
  local cmd = {'node', server_script}
  vim.list_extend(cmd, M.config.node_args or {})

  local env = vim.tbl_extend('force', vim.fn.environ(), M.config.node_env or {})
  if not env.NVIM_SERVER_ADDRESS then
    env.NVIM_SERVER_ADDRESS = M.config.server_address
  end

  vim.notify('[MCP Diagnostics] Launching Node.js server: ' .. table.concat(cmd, ' '), vim.log.levels.INFO)

  node_server_job = vim.fn.jobstart(cmd, {
    env = env,
    on_exit = function(_, code)
      node_server_job = nil
      if code == 0 then
        vim.notify('[MCP Diagnostics] Node.js server exited normally', vim.log.levels.INFO)
      else
        vim.notify('[MCP Diagnostics] Node.js server crashed (exit code: ' .. code .. ')', vim.log.levels.ERROR)

        if M.config.restart_on_crash then
          vim.notify('[MCP Diagnostics] Restarting Node.js server in 3 seconds...', vim.log.levels.INFO)
          vim.defer_fn(function()
            M.launch_node_server()
          end, 3000)
        end
      end
    end,
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line and line ~= '' then
          print('[Node Server] ' .. line)
        end
      end
    end,
    on_stderr = function(_, data)
      for _, line in ipairs(data) do
        if line and line ~= '' then
          print('[Node Server Error] ' .. line)
        end
      end
    end
  })

  if node_server_job == 0 then
    vim.notify('[MCP Diagnostics] Failed to start Node.js server', vim.log.levels.ERROR)
    return false
  end

  -- Start health check if configured
  if M.config.health_check_interval > 0 then
    M.start_health_check()
  end

  return true
end

-- Stop Node.js server
function M.stop_node_server()
  if health_check_timer then
    health_check_timer:stop()
    health_check_timer = nil
  end

  if node_server_job then
    vim.fn.jobstop(node_server_job)
    node_server_job = nil
    vim.notify('[MCP Diagnostics] Node.js server stopped', vim.log.levels.INFO)
    return true
  else
    vim.notify('[MCP Diagnostics] No Node.js server running', vim.log.levels.WARN)
    return false
  end
end

-- Health check
function M.start_health_check()
  if health_check_timer then
    health_check_timer:stop()
  end

  ---@diagnostic disable-next-line: undefined-field
  health_check_timer = (vim.uv or vim.loop).new_timer()
  if health_check_timer then
    health_check_timer:start(M.config.health_check_interval, M.config.health_check_interval, function()
      vim.schedule(function()
        if node_server_job and vim.fn.jobwait({node_server_job}, 0)[1] ~= -1 then
          -- Job finished unexpectedly
          vim.notify('[MCP Diagnostics] Node.js server health check failed - server not running', vim.log.levels.ERROR)
          if M.config.restart_on_crash then
            M.launch_node_server()
          end
        end
      end)
    end)
  end
end

-- Get Node.js server status
function M.node_server_status()
  if node_server_job and vim.fn.jobwait({node_server_job}, 0)[1] == -1 then
    vim.notify('[MCP Diagnostics] Node.js server is running (job: ' .. node_server_job .. ')', vim.log.levels.INFO)
    return true
  else
    vim.notify('[MCP Diagnostics] Node.js server is not running', vim.log.levels.WARN)
    return false
  end
end

local function create_commands()
  -- Single unified command with subcommands
  vim.api.nvim_create_user_command('McpDiagnostics', function(args)
    local subcmd_args = vim.split(args.args, '%s+')
    local subcmd = subcmd_args[1]
    local remaining_args = table.concat(vim.list_slice(subcmd_args, 2), ' ')

    if subcmd == 'status' then
      M.status()
    elseif subcmd == 'summary' then
      M.diagnostic_summary()
    elseif subcmd == 'export' then
      local filename = remaining_args ~= '' and remaining_args or nil
      M.export_diagnostics(filename)
    elseif subcmd == 'server' then
      local server_subcmd = subcmd_args[2]
      local server_args = table.concat(vim.list_slice(subcmd_args, 3), ' ')

      if server_subcmd == 'start' then
        local address = server_args ~= '' and server_args or nil
        M.start_server(address)
      elseif server_subcmd == 'start-socket' then
        local path = server_args ~= '' and server_args or nil
        M.start_socket(path)
      elseif server_subcmd == 'start-tcp' then
        local parts = vim.split(server_args, ':')
        local host = parts[1] ~= '' and parts[1] or nil
        local port = parts[2] and tonumber(parts[2]) or nil
        M.start_tcp_server(host, port)
      elseif server_subcmd == 'stop' then
        M.stop_all()
      elseif server_subcmd == 'build' then
        M.build_node_server()
      elseif server_subcmd == 'launch' then
        M.launch_node_server()
      elseif server_subcmd == 'launch-neovim' then
        vim.notify('[MCP Diagnostics] Building and launching Node.js server...', vim.log.levels.INFO)
        M.build_node_server()
        vim.defer_fn(function()
          M.launch_node_server()
        end, 2000)  -- Wait 2 seconds for build to complete
      elseif server_subcmd == 'status' then
        M.node_server_status()
      else
        vim.notify('[MCP Diagnostics] Unknown server subcommand: ' .. (server_subcmd or 'none') ..
          '\nAvailable: start, start-socket, start-tcp, stop, build, launch, launch-neovim, status', vim.log.levels.ERROR)
      end
    else
      vim.notify('[MCP Diagnostics] Available commands:\n' ..
        '  McpDiagnostics status - Show server status\n' ..
        '  McpDiagnostics summary - Show diagnostic summary\n' ..
        '  McpDiagnostics export [file] - Export diagnostics to JSON\n' ..
        '  McpDiagnostics server start [address] - Start Neovim server\n' ..
        '  McpDiagnostics server start-socket [path] - Start socket server\n' ..
        '  McpDiagnostics server start-tcp [host:port] - Start TCP server\n' ..
        '  McpDiagnostics server stop - Stop all servers\n' ..
        '  McpDiagnostics server build - Build Node.js server\n' ..
        '  McpDiagnostics server launch - Launch Node.js server\n' ..
        '  McpDiagnostics server launch-neovim - Build and launch Node.js server\n' ..
        '  McpDiagnostics server status - Show Node.js server status', vim.log.levels.INFO)
    end
  end, {
    nargs = '*',
    desc = 'MCP Diagnostics unified command interface',
    complete = function(arg_lead, cmd_line, _cursor_pos)
      local args = vim.split(cmd_line, '%s+')
      local num_args = #args - 1  -- Subtract 1 for the command itself

      if num_args == 1 then
        -- First level completions
        local completions = {'status', 'summary', 'export', 'server'}
        return vim.tbl_filter(function(item)
          return vim.startswith(item, arg_lead)
        end, completions)
      elseif num_args == 2 and args[2] == 'server' then
        -- Server subcommand completions
        local server_completions = {'start', 'start-socket', 'start-tcp', 'stop', 'build', 'launch', 'launch-neovim', 'status'}
        return vim.tbl_filter(function(item)
          return vim.startswith(item, arg_lead)
        end, server_completions)
      end
      return {}
    end
  })
end

function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_extend('force', M.config, opts)

  -- Create commands
  create_commands()

  -- Set up cleanup autocmd for file watchers
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      M.cleanup_all_server_watchers()
    end,
    desc = "Cleanup MCP diagnostics server file watchers on exit"
  })

  -- Auto-start server if configured
  if M.config.auto_start_server then
    vim.defer_fn(function()
      M.start_server()
    end, 100)
  end

  -- Auto-build and launch Node.js server if configured
  if M.config.auto_build or M.config.auto_launch then
    vim.defer_fn(function()
      local function launch_after_build()
        if M.config.auto_launch then
          vim.defer_fn(function()
            M.launch_node_server()
          end, 3000)  -- Wait for build to complete
        end
      end

      if M.config.auto_build then
        vim.notify('[MCP Diagnostics] Auto-building Node.js server...', vim.log.levels.INFO)
        M.build_node_server()
        launch_after_build()
      elseif M.config.auto_launch then
        M.launch_node_server()
      end
    end, 500)
  end

  local reload_msg = M.config.auto_reload_files and " (auto-reload enabled)" or ""
  vim.notify('[MCP Diagnostics] Server integration loaded' .. reload_msg, vim.log.levels.INFO)
  return true
end

return M
