-- Debug Diagnostics Function
-- Paste this into Neovim and run :lua debug_diagnostics()

function debug_diagnostics()
    print("=== MCP Diagnostics Debug ===")
    
    local buf = vim.api.nvim_get_current_buf()
    local file = vim.api.nvim_buf_get_name(buf)
    local diags = vim.diagnostic.get(buf)
    local clients = vim.lsp.get_clients({bufnr = buf})
    
    print("Buffer Info:")
    print("  Buffer: " .. buf)
    print("  File: " .. (file ~= "" and file or "No file"))
    print("  File exists: " .. (vim.fn.filereadable(file) == 1 and "Yes" or "No"))
    
    print("\nLSP Info:")
    print("  LSP clients attached: " .. #clients)
    for _, client in ipairs(clients) do
        print("    - " .. client.name)
    end
    
    print("\nDiagnostics Info:")
    print("  Total diagnostics: " .. #diags)
    
    if #diags > 0 then
        local counts = {error = 0, warn = 0, info = 0, hint = 0}
        for _, diag in ipairs(diags) do
            local sev = diag.severity or 4
            if sev == 1 then counts.error = counts.error + 1
            elseif sev == 2 then counts.warn = counts.warn + 1
            elseif sev == 3 then counts.info = counts.info + 1
            else counts.hint = counts.hint + 1 end
        end
        
        print(string.format("  Breakdown: %d errors, %d warnings, %d info, %d hints", 
            counts.error, counts.warn, counts.info, counts.hint))
        
        print("\n  Sample diagnostics:")
        for i = 1, math.min(3, #diags) do
            local diag = diags[i]
            local sev_names = {"ERROR", "WARN", "INFO", "HINT"}
            print(string.format("    Line %d: [%s] %s", 
                diag.lnum + 1, 
                sev_names[diag.severity] or "UNKNOWN",
                diag.message:sub(1, 60) .. (diag.message:len() > 60 and "..." or "")))
        end
    else
        print("  ✓ File is clean - no diagnostics found")
    end
    
    print("\n=== End Debug ===")
end

-- Auto-run the function
debug_diagnostics()