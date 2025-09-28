-- Debug script to test LSP functionality directly

local function get_lsp_clients(bufnr)
  if vim.lsp.get_clients then
    return vim.lsp.get_clients({ bufnr = bufnr })
  else
    return vim.lsp.get_active_clients({ bufnr = bufnr })
  end
end

-- Get current buffer info
local bufnr = vim.api.nvim_get_current_buf()
local filepath = vim.api.nvim_buf_get_name(bufnr)

print("Buffer:", bufnr)
print("File:", filepath)

-- Check LSP clients
local clients = get_lsp_clients(bufnr)
print("LSP Clients:", #clients)

for i, client in ipairs(clients) do
    print(string.format("  %d: %s (id: %d)", i, client.name, client.id))
    print("    Supports hover:", client.supports_method("textDocument/hover"))
    print("    Supports definition:", client.supports_method("textDocument/definition"))
    print("    Supports references:", client.supports_method("textDocument/references"))
end

-- Test a simple LSP request
if #clients > 0 then
    local client = clients[1]
    local params = {
        textDocument = { uri = vim.uri_from_fname(filepath) },
        position = { line = 10, character = 5 }
    }
    
    print("\nSending hover request to", client.name)
    
    client.request("textDocument/hover", params, function(err, result)
        if err then
            print("Error:", vim.inspect(err))
        else
            print("Result:", vim.inspect(result))
        end
    end, bufnr)
    
    -- Wait a bit for response
    vim.wait(2000)
end