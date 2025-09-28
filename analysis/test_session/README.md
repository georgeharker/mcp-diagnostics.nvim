# Dotfile Manager Test Suite

This directory contains a complete Python application for testing the MCP diagnostics system. The application is a functional dotfile manager with intentional linting issues.

## 🎯 Purpose

1. **Functional Application**: A real TUI dotfile manager that can actually be used
2. **Testing Platform**: Contains various Python linting issues for MCP diagnostics testing
3. **Workflow Validation**: Tests the complete diagnostic → fix → verify cycle

## 📁 Files

- **`dotfile_manager.py`**: Main TUI application using Textual and Rich
- **`file_utils.py`**: File operations and utilities (with linting issues)
- **`config_handler.py`**: Configuration management (with linting issues)
- **`requirements.txt`**: Python dependencies

## 🛠️ Functionality

### Import Mode (Ctrl+I)
- Scans home directory for dotfiles
- Interactive file selection
- Imports selected files to `~/.dotfiles`

### Diff Mode (Ctrl+D)
- Shows managed dotfiles
- Compares with home directory versions
- Displays diff preview

### CLI Mode
```bash
python dotfile_manager.py -i  # CLI import mode
```

## 🐛 Intentional Linting Issues

### file_utils.py
- Unused imports (`json`)
- Unused variables (`UNUSED_CONSTANT`)
- Line too long (function signature)
- Missing docstring
- Undefined variable reference

### config_handler.py
- Unused imports (`datetime`, `logging`)
- Unused variables (`config_cache`)
- Function too complex (overly_complex_function)
- Line too long (string literal)
- Inconsistent naming conventions
- Duplicate code
- Missing type hints
- Unreachable code

### dotfile_manager.py
- Generally clean, but may have some minor issues

## 🧪 Testing Strategy

1. **Load all files** with MCP diagnostics system
2. **Scan for issues** using `diagnostics_get`
3. **Apply targeted fixes** for each issue type
4. **Verify changes** reflect in actual files
5. **Test external change handling** with new file watcher tools

## 📊 Expected Diagnostic Count

Approximately **15-20 linting issues** across the three files, covering:
- Import/variable usage issues
- Code complexity warnings
- Style violations (line length, naming)
- Type annotation issues
- Dead code detection

## 🚀 Usage

1. Install dependencies: `pip install -r requirements.txt`
2. Run the application: `python dotfile_manager.py`
3. Use for MCP diagnostics testing and real dotfile management

This creates an ideal testing environment for validating the MCP diagnostics system improvements!