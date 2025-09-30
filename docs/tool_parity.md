# Tool Parity: MCP vs CodeCompanion

This document ensures complete feature parity between the MCP and CodeCompanion implementations of mcp-diagnostics tools.

## ✅ **Complete Tool List (18 Tools)**

| # | Tool Name | MCP | CodeCompanion | Description |
|---|-----------|-----|---------------|-------------|
| 1 | `diagnostics_get` | ✅ | ✅ | Get ALL diagnostics that must be addressed with filtering |
| 2 | `diagnostics_summary` | ✅ | ✅ | Get diagnostic overview to understand scope of issues |
| 3 | `lsp_hover` | ✅ | ✅ | Get comprehensive symbol information and documentation |
| 4 | `lsp_definition` | ✅ | ✅ | Jump to where symbols are defined |
| 5 | `lsp_references` | ✅ | ✅ | Find ALL locations where a symbol is used |
| 6 | `lsp_document_symbols` | ✅ | ✅ | Get overview of all symbols in a file |
| 7 | `lsp_workspace_symbols` | ✅ | ✅ | Search for symbols across the entire workspace |
| 8 | `lsp_code_actions` | ✅ | ✅ | Get available automated fixes and refactorings |
| 9 | `symbol_lookup` | ✅ | ✅ | **NEW**: Find symbols by name with optional context disambiguation |
| 10 | `ensure_files_loaded` | ✅ | ✅ | Load files into Neovim buffers for LSP analysis |
| 11 | `buffer_status` | ✅ | ✅ | Get status of all loaded buffers with LSP info |
| 12 | `analyze_symbol` | ✅ | ✅ | Comprehensive symbol analysis (hover + definition + references) |
| 13 | `analyze_diagnostics` | ✅ | ✅ | Analyze specific diagnostics with comprehensive context |
| 14 | `correlate_diagnostics` | ✅ | ✅ | Analyze relationships between diagnostics across files |
| 15 | `handle_file_deleted` | ✅ | ✅ | Properly handle deleted files with LSP cleanup |
| 16 | `refresh_after_external_changes` | ✅ | ✅ | Force refresh watched files after external changes |
| 17 | `check_file_staleness` | ✅ | ✅ | Check if files are out of sync with external changes |

## 🆕 **Recent Improvements (Based on Feedback)**

### **Removed Redundant Tools**
- ❌ `ensure_files_loaded_with_wait` - Functionality was redundant with `ensure_files_loaded`

### **Renamed for Clarity**
- `analyze_symbol` → `analyze_symbol_comprehensive` (more descriptive)
- `analyze_diagnostics` → `analyze_diagnostic_context` (matches actual function name)

### **Added Name-Based Symbol Lookup**
- ✨ **New**: `symbol_lookup` tool for finding symbols by name
- ✨ **Enhanced**: `lsp_hover` now supports both position-based AND name-based lookup

## 📊 **Feature Comparison**

### **Core LSP Tools (8 tools)**
Both implementations provide identical core LSP functionality:
- Diagnostics retrieval and analysis
- Symbol navigation (hover, definition, references)
- Workspace exploration (document/workspace symbols)
- Code action discovery

### **Advanced Analysis Tools (4 tools)**
Both implementations provide sophisticated analysis:
- Comprehensive symbol analysis combining multiple LSP operations
- Diagnostic context analysis with related information
- Cross-file diagnostic correlation for pattern recognition
- Buffer management and status monitoring

### **File Management Tools (3 tools)**  
Both implementations handle file lifecycle:
- Intelligent file loading with LSP synchronization
- File deletion handling with configurable modes
- External change detection and refresh management

## 🔄 **Implementation Differences**

| Aspect | MCP Implementation | CodeCompanion Implementation |
|--------|-------------------|----------------------------|
| **Transport** | JSON-RPC over stdio/socket | Direct Lua function calls |
| **Performance** | Network/IPC overhead | Native Lua performance |
| **Error Handling** | JSON-RPC error responses | Lua pcall with formatted errors |
| **Configuration** | MCP server config | CodeCompanion tool config |
| **Discovery** | MCP protocol negotiation | Tool registry + autocmd discovery |

## 🎯 **Usage Patterns**

### **MCP Version Usage**
```lua
-- Via mcphub.nvim
require("mcp-diagnostics").setup({ mode = "mcphub" })

-- Via external MCP client (Claude Desktop, etc.)
require("mcp-diagnostics").setup({ mode = "server" })
```

### **CodeCompanion Version Usage**
```lua
-- Native CodeCompanion integration
require("mcp-diagnostics").setup({ mode = "codecompanion" })

-- All 18 tools available immediately
{
  mode = "codecompanion", 
  codecompanion = {
    enabled_tools = {
      -- All 18 tools listed in default configuration
    }
  }
}
```

## ✨ **Benefits of Parity**

1. **Consistent Experience**: Same capabilities regardless of integration method
2. **Easy Migration**: Users can switch between MCP and CodeCompanion seamlessly  
3. **Full Feature Access**: No functionality loss when choosing CodeCompanion
4. **Comprehensive AI Assistance**: All diagnostic and LSP capabilities available

## 🧪 **Verification**

To verify parity, both implementations should:

1. **Return identical results** for the same tool calls
2. **Support identical parameters** for each tool
3. **Provide equivalent error handling** and messaging
4. **Offer similar configuration options** for customization

## 📝 **Configuration Examples**

### **Minimal Setup (Core Tools Only)**
```lua
{
  mode = "codecompanion",
  codecompanion = {
    enabled_tools = {
      "lsp_document_diagnostics", "lsp_hover", "lsp_definition", "lsp_references"
  }
}
```

### **Full Setup (All 18 Tools)**
```lua
{
  mode = "codecompanion",
  codecompanion = {
    enabled_tools = {
      -- Core diagnostic tools
      "lsp_document_diagnostics", "lsp_diagnostics_summary",
      -- Core LSP tools  
      "lsp_hover", "lsp_definition", "lsp_references",
      "lsp_document_symbols", "lsp_workspace_symbols", "lsp_code_actions",
      -- Advanced analysis tools
      "analyze_symbol_comprehensive", "analyze_diagnostic_context", 
      "correlate_diagnostics", "buffer_status",
      -- File management tools
      "ensure_files_loaded",
      "handle_file_deleted", "refresh_after_external_changes", 
      "check_file_staleness"
    }
  }
}
```

This complete parity ensures users get the full power of mcp-diagnostics regardless of their chosen integration method! 🚀