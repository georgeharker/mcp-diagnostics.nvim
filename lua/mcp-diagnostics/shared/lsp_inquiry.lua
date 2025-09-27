-- Pure LSP inquiry operations
-- Handles LSP requests without buffer management concerns
-- Assumes buffers are already loaded by lsp_interact.lua

local config = require("mcp-diagnostics.shared.config")
local M = {}

-- Helper function to get LSP clients for a buffer
local function get_lsp_clients(bufnr)
  if vim.lsp.get_clients then
    -- Neovim 0.10+
    return vim.lsp.get_clients({ bufnr = bufnr })
  else
    -- Neovim 0.9 and earlier
    return vim.lsp.get_active_clients({ bufnr = bufnr })
  end
end

-- Generic LSP request handler with timeout
local function lsp_request(method, params, bufnr, timeout)
  timeout = timeout or config.get_lsp_timeout()

  local clients = get_lsp_clients(bufnr)
  if #clients == 0 then
    return nil, "No LSP clients attached to buffer"
  end

  local results = {}
  local completed = 0
  local total_clients = #clients

  local function on_result(result, err, ctx)
    completed = completed + 1
    if err then
      config.log_debug(string.format("LSP error from client %s: %s", ctx.client_id or "unknown", err.message or "unknown"), "[LSP Inquiry]")
    else
      if result then
        table.insert(results, {
          client_id = ctx.client_id,
          client_name = ctx.client_name or "unknown",
          result = result
        })
      end
    end
  end

  -- Send requests to all clients
  for _, client in ipairs(clients) do
    if client.supports_method(method) then
      client.request(method, params, on_result, bufnr)
    else
      completed = completed + 1
      config.log_debug(string.format("Client %s doesn't support %s", client.name, method), "[LSP Inquiry]")
    end
  end

  -- Wait for responses with timeout
  local start_time = vim.loop.hrtime()
  local timeout_ns = timeout * 1000000 -- Convert to nanoseconds

  while completed < total_clients do
    vim.wait(10) -- Wait 10ms
    local elapsed = vim.loop.hrtime() - start_time
    if elapsed > timeout_ns then
      config.log_debug(string.format("LSP request timed out after %dms", timeout), "[LSP Inquiry]")
      break
    end
  end

  return results, nil
end

-- Get hover information for a position
function M.get_hover_info(bufnr, line, column)
  config.log_debug(string.format("Getting hover info for buffer %d:%d:%d", bufnr, line, column), "[LSP Inquiry]")

  local file = vim.api.nvim_buf_get_name(bufnr)
  local params = {
    textDocument = { uri = vim.uri_from_fname(file) },
    position = { line = line, character = column }
  }

  local results, err = lsp_request("textDocument/hover", params, bufnr)
  if err then
    return nil, err
  end

  if not results then
    return {}
  end

  -- Process results from all clients
  local hover_info = {}
  for _, result in ipairs(results) do
    if result.result and result.result.contents then
      local content = result.result.contents
      local text = ""

      if type(content) == "string" then
        text = content
      elseif type(content) == "table" then
        if content.value then
          text = content.value
        elseif content[1] then
          if type(content[1]) == "string" then
            text = content[1]
          elseif content[1].value then
            text = content[1].value
          end
        end
      end

      if text ~= "" then
        table.insert(hover_info, {
          client = result.client_name,
          content = text
        })
      end
    end
  end

  return hover_info
end

-- Get definitions for a symbol at a position
function M.get_definitions(bufnr, line, column)
  config.log_debug(string.format("Getting definitions for buffer %d:%d:%d", bufnr, line, column), "[LSP Inquiry]")

  local file = vim.api.nvim_buf_get_name(bufnr)
  local params = {
    textDocument = { uri = vim.uri_from_fname(file) },
    position = { line = line, character = column }
  }

  local results, err = lsp_request("textDocument/definition", params, bufnr)
  if err then
    return nil, err
  end

  if not results then
    return {}
  end

  -- Process results from all clients
  local definitions = {}
  for _, result in ipairs(results) do
    if result.result then
      local locations = result.result
      if not vim.tbl_islist(locations) then
        locations = { locations }
      end

      for _, location in ipairs(locations) do
        if location.uri then
          table.insert(definitions, {
            client = result.client_name,
            uri = location.uri,
            file = vim.uri_to_fname(location.uri),
            range = location.range
          })
        end
      end
    end
  end

  return definitions
end

-- Get references for a symbol at a position
function M.get_references(bufnr, line, column)
  config.log_debug(string.format("Getting references for buffer %d:%d:%d", bufnr, line, column), "[LSP Inquiry]")

  local file = vim.api.nvim_buf_get_name(bufnr)
  local params = {
    textDocument = { uri = vim.uri_from_fname(file) },
    position = { line = line, character = column },
    context = { includeDeclaration = true }
  }

  local results, err = lsp_request("textDocument/references", params, bufnr)
  if err then
    return nil, err
  end

  if not results then
    return {}
  end

  -- Process results from all clients
  local references = {}
  for _, result in ipairs(results) do
    if result.result then
      for _, location in ipairs(result.result) do
        if location.uri then
          table.insert(references, {
            client = result.client_name,
            uri = location.uri,
            file = vim.uri_to_fname(location.uri),
            range = location.range
          })
        end
      end
    end
  end

  return references
end

-- Get document symbols for a buffer
function M.get_document_symbols(bufnr)
  config.log_debug(string.format("Getting document symbols for buffer %d", bufnr), "[LSP Inquiry]")

  local file = vim.api.nvim_buf_get_name(bufnr)
  local params = {
    textDocument = { uri = vim.uri_from_fname(file) }
  }

  local results, err = lsp_request("textDocument/documentSymbol", params, bufnr)
  if err then
    return nil, err
  end

  if not results then
    return {}
  end

  -- Process results from all clients
  local symbols = {}
  for _, result in ipairs(results) do
    if result.result then
      for _, symbol in ipairs(result.result) do
        table.insert(symbols, {
          client = result.client_name,
          name = symbol.name,
          kind = symbol.kind,
          range = symbol.range,
          selectionRange = symbol.selectionRange,
          children = symbol.children
        })
      end
    end
  end

  return symbols
end

-- Get workspace symbols with optional query
function M.get_workspace_symbols(query)
  config.log_debug(string.format("Getting workspace symbols with query: %s", query or "(none)"), "[LSP Inquiry]")

  local params = { query = query or "" }

  -- Use any available buffer for the request
  local bufnr = vim.api.nvim_get_current_buf()

  local results, err = lsp_request("workspace/symbol", params, bufnr)
  if err then
    return nil, err
  end

  if not results then
    return {}
  end

  -- Process results from all clients
  local symbols = {}
  for _, result in ipairs(results) do
    if result.result then
      for _, symbol in ipairs(result.result) do
        local location = symbol.location
        table.insert(symbols, {
          client = result.client_name,
          name = symbol.name,
          kind = symbol.kind,
          containerName = symbol.containerName,
          location = {
            uri = location.uri,
            file = vim.uri_to_fname(location.uri),
            range = location.range
          }
        })
      end
    end
  end

  return symbols
end

-- Get code actions for a position or range
function M.get_code_actions(bufnr, line, column, end_line, end_column)
  config.log_debug(string.format("Getting code actions for buffer %d:%d:%d", bufnr, line, column), "[LSP Inquiry]")

  local file = vim.api.nvim_buf_get_name(bufnr)
  local range = {
    start = { line = line, character = column },
    ["end"] = {
      line = end_line or line,
      character = end_column or column
    }
  }

  -- Get diagnostics for the range to provide context
  local diagnostics = vim.diagnostic.get(bufnr, {
    lnum = line,
    end_lnum = end_line or line
  })

  local params = {
    textDocument = { uri = vim.uri_from_fname(file) },
    range = range,
    context = {
      diagnostics = diagnostics
    }
  }

  local results, err = lsp_request("textDocument/codeAction", params, bufnr)
  if err then
    return nil, err
  end

  if not results then
    return {}
  end

  -- Process results from all clients
  local actions = {}
  for _, result in ipairs(results) do
    if result.result then
      for _, action in ipairs(result.result) do
        table.insert(actions, {
          client = result.client_name,
          title = action.title,
          kind = action.kind,
          isPreferred = action.isPreferred,
          disabled = action.disabled,
          edit = action.edit,
          command = action.command
        })
      end
    end
  end

  return actions
end

return M
