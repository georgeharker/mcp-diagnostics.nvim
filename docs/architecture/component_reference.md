# Component Reference Guide

## 🧩 **Quick Component Lookup**

### **When to Use What:**

| **Need** | **Use Component** | **Function** |
|----------|------------------|--------------|
| 🔍 Watch a file for changes | `file_watcher.lua` | `watch_file(filepath)` |
| ⚡ Refresh single file | `unified_refresh.lua` | `unified_external_refresh(filepath, mode)` |  
| 📦 Refresh multiple files | `unified_refresh.lua` | `unified_batch_refresh(filepaths, mode)` |
| ⏰ Wait for LSP confirmation | `unified_refresh.lua` | `unified_refresh_and_wait(filepath, mode, timeout)` |
| 🔧 High-level MCP operations | `lsp_extra.lua` | `smart_refresh_and_wait(files, options)` |
| 📡 Direct LSP communication | `lsp_interact.lua` | `notify_lsp_file_changed_with_version()` |
| 🩺 Get diagnostic data | `diagnostics.lua` | `get_all_diagnostics(files, severity, source)` |
| 📊 Diagnostic analytics | `diagnostics.lua` | `get_diagnostic_stats()` |
| 🔥 Find problem files | `diagnostics.lua` | `get_problematic_files(limit)` |
| 🎯 Filter by severity | `diagnostics.lua` | `get_diagnostics_by_severity(severity)` |
| 🔮 LSP queries | `lsp.lua` | `get_hover_info()`, `get_definitions()`, etc. |
| 📋 Buffer management | `buffers.lua` | `get_buffer_status()`, `ensure_buffer_loaded()` |

---

## 🏗️ **Component Dependency Chain**

```
┌─────────────────┐
│   lsp_extra     │ ← MCP Tools call this
│  (Mission       │
│   Control)      │
└─────────┬───────┘
          │ requires
          ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ unified_refresh │    │  file_watcher   │    │  lsp_interact   │
│   (Response     │    │   (Detection    │    │   (Protocol     │
│    Team)        │    │    System)      │    │   Translator)   │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │ requires             │ requires             │ requires
          │              ┌───────▼───────┐              │
          └──────────────▶│    config     │◀─────────────┘
                         │  (Settings)   │
                         └───────┬───────┘
                                 │ required by
                ┌────────────────┼────────────────┐
                │                │                │
        ┌───────▼───────┐ ┌──────▼──────┐ ┌──────▼──────┐
        │  diagnostics  │ │     lsp     │ │   buffers   │
        │ (Error Data)  │ │(Queries)    │ │(Management) │
        └───────────────┘ └─────────────┘ └─────────────┘
```

**✅ Zero Circular Dependencies:** Clean hierarchy ensures maintainability

---

## 📋 **Component APIs**

### **🔍 file_watcher.lua (Detection Layer)**
```lua
-- Start watching a file
file_watcher.watch_file(filepath)

-- Check if file changed externally  
local is_stale = file_watcher.check_file_staleness(filepath, bufnr)

-- Refresh all watched files (uses unified_refresh internally)
local refreshed_files = file_watcher.refresh_all_watched_files()

-- Stop watching a file
file_watcher.stop_watching(filepath)

-- Cleanup all watchers (on exit)
file_watcher.cleanup_all_watchers()
```

### **⚡ unified_refresh.lua (Execution Layer)**
```lua
-- Single file refresh with mode handling
local result = unified_refresh.unified_external_refresh(filepath, mode)
-- Returns: { success, before_version, after_version, version_changed, filepath }

-- Multiple files efficiently  
local batch_result = unified_refresh.unified_batch_refresh(filepaths, mode)
-- Returns: { success, total_files, success_count, failed_count, results }

-- Wait for LSP to acknowledge version change
local ack_result = unified_refresh.wait_for_lsp_acknowledgment(filepath, expected_version, timeout)
-- Returns: { success, wait_time, final_version }

-- Complete refresh + wait flow
local full_result = unified_refresh.unified_refresh_and_wait(filepath, mode, timeout)  
-- Returns: { success, refresh_result, wait_result, total_time }
```

### **🔧 lsp_extra.lua (Integration Layer)**  
```lua
-- High-level refresh with LSP coordination
local result = lsp_extra.smart_refresh_and_wait(files, { max_wait_ms = 5000 })
-- Returns: { refresh_result, lsp_ready_result, diagnostic_update_result, success, total_wait_time_ms }

-- Ensure files are loaded in Neovim buffers
local load_result = lsp_extra.ensure_files_loaded(filepaths, { reload_mode = "auto" })

-- Wait for LSP clients to be ready
local lsp_result = lsp_extra.wait_for_lsp_ready(files, timeout_ms)
```

### **📡 lsp_interact.lua (Protocol Layer)**
```lua
-- Send LSP notification with perfect version sync (used by unified_refresh)
lsp_interact.notify_lsp_file_changed_with_version(filepath, bufnr, version)

-- Traditional LSP file lifecycle (when needed)
lsp_interact.notify_lsp_file_opened(filepath, bufnr)
lsp_interact.notify_lsp_file_closed(filepath, bufnr)
```

---

## ⚙️ **Configuration Modes**

### **auto_reload_mode Settings:**
```lua
"auto"   -- Automatically refresh when external changes detected (development)  
"prompt" -- Ask user before refreshing (collaborative workflows)
"off"    -- Never auto-refresh, manual only (read-only scenarios)
```

### **Usage Examples:**
```lua
-- Force auto mode for testing
local result = unified_refresh.unified_external_refresh("test.lua", "auto")

-- Respect user preference
local result = unified_refresh.unified_external_refresh("test.lua")  -- Uses config setting

-- Batch with custom mode
local result = unified_refresh.unified_batch_refresh({"file1.lua", "file2.lua"}, "prompt")
```

---

## 🎯 **Common Usage Patterns**

### **Pattern 1: External Tool Integration**
```lua  
-- After sed/git/external modification:
os.execute("sed -i 's/old/new/' myfile.lua")  
local result = unified_refresh.unified_refresh_and_wait("myfile.lua", "auto", 3000)
if result.success then
  print("File refreshed and LSP synced!")
end
```

### **Pattern 2: Batch File Processing**
```lua
-- After git pull or mass changes:
local changed_files = {"src/mod1.lua", "src/mod2.lua", "tests/test1.lua"}
local result = unified_refresh.unified_batch_refresh(changed_files, "auto")
print(string.format("Refreshed %d/%d files", result.success_count, result.total_files))
```

### **Pattern 3: MCP Tool Development**
```lua
-- In MCP tool handler:
function tool_handler(req, res)
  local files = req.params.files
  local result = lsp_extra.smart_refresh_and_wait(files, { max_wait_ms = 5000 })
  
  return res:json({
    success = result.success,
    timing = result.total_wait_time_ms,
    message = string.format("Processed %d files", #files)
  })
end
```

### **Pattern 4: File Watcher Setup**
```lua
-- Watch project files automatically:
local project_files = vim.fn.glob("src/**/*.lua", false, true)
for _, filepath in ipairs(project_files) do
  file_watcher.watch_file(filepath)
end

-- Files will auto-refresh when changed externally
-- (uses unified_refresh internally for perfect LSP sync)
```

---

## 🚨 **Error Handling Patterns**

### **Check Results:**
```lua
local result = unified_refresh.unified_external_refresh(filepath, "auto")

if not result.success then
  if result.reason == "not_loaded" then
    -- File not in buffer, load it first
    vim.cmd("edit " .. filepath)
  elseif result.reason == "user_declined" then  
    -- User said no to refresh prompt
    vim.notify("Refresh cancelled by user")
  elseif result.reason == "reload_failed" then
    -- Buffer reload failed  
    vim.notify("Failed to reload: " .. result.error, vim.log.levels.ERROR)
  end
end
```

### **Timeout Handling:**
```lua
local result = unified_refresh.unified_refresh_and_wait(filepath, "auto", 2000)

if not result.success and result.wait_result and result.wait_result.reason == "timeout" then
  vim.notify("LSP took too long to respond, but file was refreshed", vim.log.levels.WARN)
end
```

---

**Reference Status:** ✅ Complete for current architecture  
**Usage:** Import any component and use its API directly  
**Integration:** All components work together seamlessly via unified_refresh