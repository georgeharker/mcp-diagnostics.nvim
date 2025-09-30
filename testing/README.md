# MCP-Diagnostics Testing Suite

This directory contains comprehensive testing files for the mcp-diagnostics plugin's LSP tools and CodeCompanion integration.

## Directory Structure

```
testing/
├── README.md                     # This file
├── comprehensive_lsp_test.lua    # Main test suite runner
├── debug/                        # Debug scripts (moved from root)
│   ├── debug_*.lua              # Various debug utilities
│   └── test_*.lua               # Legacy test files
├── lsp_test_files/              # Clean Lua files for LSP testing
│   ├── app.lua                  # Main application entry point
│   ├── user_model.lua           # User data model with methods
│   ├── user_service.lua         # Business logic layer
│   ├── database.lua             # Database operations module
│   └── validation.lua           # Input validation utilities
└── syntax_errors/               # Files with intentional errors
    ├── missing_end.lua          # Missing end statements
    ├── undefined_variables.lua  # Undefined variable usage
    ├── type_errors.lua          # Type mismatch errors
    └── malformed_syntax.lua     # Various syntax errors
```

## Test File Categories

### 1. LSP Test Files (`lsp_test_files/`)

These files contain **clean, well-structured Lua code** designed to test LSP functionality:

#### **Cross-References and Dependencies**
- `user_model.lua` → requires `validation.lua` and `database.lua`
- `user_service.lua` → requires all other modules
- `app.lua` → main entry point that uses `user_service.lua`

#### **LSP Features to Test**
- **Hover Info**: Function definitions, class documentation, parameter info
- **Go to Definition**: Following `require()` statements, function calls
- **Document Symbols**: Classes, functions, variables, exports
- **References**: Usage of functions across files
- **Workspace Symbols**: Finding symbols by name across project

#### **Key Symbols for Testing**
- `UserModel` class with methods (`new`, `save`, `load`, `validate`)
- `validation` module functions (`is_valid_email`, `is_valid_name`)
- `database` operations (`insert_user`, `get_user`, `update_user`)
- `UserService` business logic functions
- `App` application lifecycle methods

### 2. Syntax Error Files (`syntax_errors/`)

These files contain **intentional errors** for diagnostic testing:

#### **Error Categories**
- **Syntax Errors**: Missing `end`, unbalanced parentheses, malformed strings
- **Undefined Variables**: Usage of undeclared variables, typos in names
- **Type Errors**: Calling numbers as functions, indexing nil values
- **Semantic Errors**: Wrong function arguments, invalid operations

#### **Expected Diagnostics**
Each file should generate multiple diagnostics of varying severities:
- **Errors**: Blocking syntax issues, undefined variables
- **Warnings**: Deprecated functions, unused variables  
- **Info**: Style suggestions, optimization hints
- **Hints**: Code improvements, best practices

## Tool Testing Matrix

| Tool | Clean Files | Error Files | Expected Results |
|------|------------|-------------|------------------|
| `lsp_document_diagnostics` | ✅ No issues | ✅ Multiple errors | JSON with diagnostics |
| `lsp_hover` | ✅ Rich info | ⚠️ Limited info | Hover documentation |
| `lsp_definition` | ✅ Cross-file jumps | ❌ May fail | Definition locations |
| `lsp_references` | ✅ Usage patterns | ❌ May fail | Reference lists |
| `lsp_document_symbols` | ✅ Full structure | ⚠️ Partial structure | Symbol hierarchy |
| `lsp_workspace_symbols` | ✅ Project-wide | ❌ May fail | Symbol search |

## Running Tests

### 1. Manual Testing via CodeCompanion

Start remote Neovim:
```bash
nvim --listen /tmp/nvim-test-sock
```

Load a test file:
```
:edit testing/lsp_test_files/user_model.lua
```

Open CodeCompanion chat:
```
:CodeCompanionChat
```

Test tools:
```
Analyze @lsp_document_diagnostics for current file
Show me @lsp_hover info at line 15, column 10  
Find @lsp_definition for UserModel.new
List @lsp_document_symbols in this file
```

### 2. Automated Testing

Run the comprehensive test suite:
```lua
-- From Neovim connected to remote instance
:luafile testing/comprehensive_lsp_test.lua
local tester = require('testing.comprehensive_lsp_test')
tester.run_comprehensive_test()
```

### 3. Individual Tool Testing

Test specific tools on specific files:
```lua
-- Load test runner
local tester = require('testing.comprehensive_lsp_test')
local handle, _ = tester.connect_remote()

-- Test diagnostics on error file
local success, result = tester.test_document_diagnostics(handle, 'testing/syntax_errors/missing_end.lua')

-- Test symbols on clean file  
local success, result = tester.test_document_symbols(handle, 'testing/lsp_test_files/user_model.lua')

-- Test hover on specific position
local success, result = tester.test_lsp_hover(handle, 'testing/lsp_test_files/validation.lua', 20, 10)
```

## Expected Test Results

### Clean Files (lsp_test_files/)
- **Diagnostics**: 0-2 minor style issues
- **Symbols**: 5-15 functions, classes, variables per file
- **Hover**: Rich documentation with type information
- **Definitions**: Successful cross-file navigation
- **References**: Usage tracking across modules

### Error Files (syntax_errors/)
- **Diagnostics**: 3-10 errors/warnings per file
- **Symbols**: Partial symbol detection despite errors
- **Hover**: Limited or no information
- **Definitions**: May fail due to syntax issues
- **References**: May fail due to parsing problems

## Integration Points

### CodeCompanion Variables
Test the `#{diagnostics}` variable with these files:
```
Please analyze #{diagnostics} in the user management system
```

### MCP Hub Tools
Use these files to test MCP hub diagnostic tools:
- `diagnostics_get`
- `diagnostic_hotspots`
- `diagnostic_stats`

### LSP Integration
Verify LSP server attachment:
- Lua Language Server (lua-language-server)
- EmmyLua annotations support
- Cross-file analysis capabilities

## Troubleshooting

### No Diagnostics Found
1. Ensure LSP server is running: `:LspInfo`
2. Wait for analysis: Files may need 2-3 seconds after loading
3. Check file paths: Use absolute paths for reliability

### No Hover Information
1. Position cursor on symbol names, not whitespace
2. Ensure LSP server supports hover for Lua
3. Check if file is properly loaded and parsed

### No Definitions Found
1. Test on `require()` statements first
2. Ensure all files are in Neovim's working directory
3. Check LSP workspace configuration

### Tool Execution Failures
1. Verify mcp-diagnostics plugin is loaded
2. Check CodeCompanion tool registration
3. Ensure remote Neovim connection is stable

---

**Status**: Comprehensive testing structure ready for full LSP tool validation