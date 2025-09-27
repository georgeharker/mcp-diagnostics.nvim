# LSP Architecture Refactoring

## Overview

The LSP functionality has been refactored into a clean, modular architecture with proper separation of concerns.

## Architecture Components

### 1. **`lsp_inquiry.lua`** - Pure LSP Queries
- **Purpose**: Handles LSP requests without buffer management concerns
- **Responsibility**: Makes LSP calls and processes responses
- **Functions**: 
  - `get_hover_info(bufnr, line, column)`
  - `get_definitions(bufnr, line, column)`
  - `get_references(bufnr, line, column)`
  - `get_document_symbols(bufnr)`
  - `get_workspace_symbols(query)`
  - `get_code_actions(bufnr, line, column, end_line, end_column)`

**Key principle**: Assumes buffers are already loaded, focuses only on LSP communication.

### 2. **`lsp_interact.lua`** - Buffer Management & LSP Notifications
- **Purpose**: Manages file loading, LSP protocol notifications, and buffer lifecycle
- **Responsibility**: File system interactions, LSP state management
- **Functions**:
  - `ensure_file_loaded(filepath)` - Clean buffer creation (no forced reloads)
  - `ensure_files_loaded(filepaths)` - Batch file loading
  - `notify_lsp_file_opened(filepath, bufnr)` - LSP didOpen notifications
  - `notify_lsp_file_closed(filepath, bufnr)` - LSP didClose notifications
  - `notify_lsp_file_changed(filepath, bufnr)` - LSP didChange notifications
  - `handle_file_deleted(filepath)` - Clean up deleted files
  - `handle_file_changed(filepath, bufnr)` - Coordinate file change responses

**Key principles**: 
- No forced reloads in `ensure_file_loaded` - let file watcher handle changes
- Proper LSP protocol notifications based on config options
- Clean separation from query operations

### 3. **`lsp.lua`** - Main Interface (Coordination Layer)
- **Purpose**: Provides the main API that coordinates inquiry and interaction
- **Responsibility**: Maintains backward compatibility, delegates to specialized modules
- **Functions**: Same external API as before, but delegates internally

**Key principle**: Maintains existing API while using new architecture internally.

### 4. **`lsp_extra.lua`** - Enhanced Features
- **Purpose**: Advanced functionality like tool chaining and correlation analysis
- **Responsibility**: Higher-level operations that combine multiple LSP calls
- **Functions**:
  - `analyze_symbol_comprehensive()` - Multi-operation symbol analysis
  - `analyze_diagnostic_context()` - Deep diagnostic investigation
  - `correlate_diagnostics()` - Cross-file diagnostic relationships

### 5. **File Watcher Integration**
- **Purpose**: Coordinates file system change detection with LSP notifications
- **Behavior**:
  - Detects external file changes
  - Handles buffer reloading based on `auto_reload_mode` config
  - Notifies LSP via `lsp_interact.handle_file_changed()`
  - Handles deletions via `lsp_interact.handle_file_deleted()`

## Configuration Options

### `auto_reload_mode`
- `"reload"` - Automatically reload changed files
- `"ask"` - Prompt user for each changed file  
- `"none"` - Don't reload, just warn about stale data

### `lsp_notify_mode`  
- `"auto"` - Automatically notify LSP of file open/close/change
- `"manual"` - Only notify when explicitly requested
- `"disabled"` - Never notify LSP (may cause stale diagnostics)

## Key Architectural Decisions

### 1. **Clean Buffer Management**
- `ensure_file_loaded()` only ensures buffer exists, doesn't force reloads
- File watcher handles external changes based on configuration
- LSP notifications happen automatically based on `lsp_notify_mode`

### 2. **Separation of Concerns**
- **Inquiry**: Pure LSP queries, no side effects
- **Interaction**: Buffer management, LSP protocol compliance
- **Coordination**: Main API layer for backward compatibility
- **Enhancement**: Advanced features built on top

### 3. **File Change Handling**
- File watcher detects changes
- Buffer reloading is separate from LSP notification
- LSP gets notified even if buffer isn't reloaded (configurable)
- Deleted files properly cleaned up in both buffer and LSP state

### 4. **Protocol Compliance**
- Proper LSP `textDocument/didOpen` when files are loaded
- `textDocument/didChange` when files are modified
- `textDocument/didClose` when files are deleted/removed
- Version tracking for change notifications

## Benefits

1. **Clear Responsibilities**: Each module has a single, well-defined purpose
2. **No Duplication**: Eliminates the overlapping `ensure_file_loaded` functions
3. **Configurable Behavior**: User can control reload and notification behavior
4. **Protocol Compliance**: Proper LSP notifications keep language servers in sync
5. **Maintainable**: Clean separation makes testing and debugging easier
6. **Backward Compatible**: Existing code continues to work

## Usage Examples

```lua
-- Simple file loading (no forced reloads)
local bufnr, loaded, err = require("mcp-diagnostics.shared.lsp").ensure_file_loaded(filepath)

-- Pure LSP query (assumes buffer loaded)
local hover = require("mcp-diagnostics.shared.lsp_inquiry").get_hover_info(bufnr, line, col)

-- Advanced symbol analysis
local analysis = require("mcp-diagnostics.shared.lsp_extra").analyze_symbol_comprehensive(filepath, line, col)

-- Handle file deletion properly
require("mcp-diagnostics.shared.lsp_interact").handle_file_deleted(deleted_filepath)
```

This architecture provides a solid foundation for both current functionality and future enhancements while maintaining clean separation of concerns.