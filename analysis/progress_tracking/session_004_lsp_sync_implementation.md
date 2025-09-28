# Session 004: LSP Synchronization & Unified Refresh Implementation

**Date:** 2025-01-27  
**Status:** 🔄 IN PROGRESS - Ready for diagnostics cleanup  
**Type:** Architecture enhancement + Bug fixing

## 📊 **Session Overview**

**Original Problem:** Sleep delays needed for LSP updates after external file changes
**Root Cause Discovered:** LSP document version synchronization issues
**Solution Implemented:** Unified refresh system with proper LSP protocol compliance

## 🚨 **Critical Issue Fixed**

### **Startup Error Resolved:**
```
lua/mcp-diagnostics/mcphub/tools_extra.lua:220: attempt to index global 'mcphub' (a nil value)
```

**Root Cause:** Misplaced tool definition outside of function scope trying to access `mcphub` as global variable
**Fix Applied:** Removed problematic `wait_for_diagnostic_update` tool definition from lines 218-254

**Status:** ✅ **RESOLVED** - Server should start cleanly now

## 🎯 **Core Architecture Enhancement: Unified Refresh System**

### **The Problem We Solved:**
- **Sleep delays:** `sleep(2)` after external edits (sed, git, etc.)
- **Version mismatches:** Our LSP notifications used different versions than Neovim's internal tracking
- **Race conditions:** Buffer reload separate from LSP notification

### **The Solution:**

#### **1. Unified Configuration**
```lua
-- In config.lua (UPDATED)
auto_reload_mode = "auto" | "prompt" | "off"  -- Simplified from old "reload"/"none"/"ask"
```

#### **2. New Unified Refresh System**
**File:** `lua/mcp-diagnostics/shared/unified_refresh.lua` ✅ **CREATED**

**Key Functions:**
- `unified_external_refresh(filepath, mode)` - Atomic buffer + LSP refresh
- `unified_batch_refresh(filepaths, mode)` - Handle multiple files
- `wait_for_lsp_acknowledgment(filepath, expected_version, max_wait_ms)` - Real LSP confirmation
- `unified_refresh_and_wait(filepath, mode, max_wait_ms)` - Complete flow with confirmation

**Core Innovation:** Uses Neovim's natural `changedtick` as LSP version number

#### **3. Enhanced LSP Interaction**
**File:** `lua/mcp-diagnostics/shared/lsp_interact.lua` ✅ **ENHANCED**

**New Function Added:**
```lua
notify_lsp_file_changed_with_version(filepath, bufnr, version)
```
- **KEY:** Uses Neovim's actual `changedtick` instead of our own counter
- **Eliminates:** Version synchronization issues between Neovim LSP and our notifications

#### **4. File Watcher Integration**
**File:** `lua/mcp-diagnostics/shared/file_watcher.lua` ✅ **UPDATED**

**Change:** Replaced manual buffer reload with unified refresh system call

## 🔧 **Technical Implementation Details**

### **The Version Synchronization Fix:**

**Before (Broken):**
```lua
-- Our code: version counter
state.version = state.version + 1  -- Could be v6

-- Neovim's LSP: uses changedtick 
changedtick = 1000

-- LSP Server sees: Version jump from 1000 to 6 - INCONSISTENT!
```

**After (Perfect Sync):**
```lua
-- Let Neovim handle reload naturally
vim.cmd('edit!')  -- Increments changedtick naturally

-- Use Neovim's actual version
local neovim_version = vim.api.nvim_buf_get_changedtick(bufnr)
notify_lsp_with_version(filepath, neovim_version)  -- Perfect match!
```

### **The Unified Flow:**
```lua
function unified_external_refresh(filepath, mode)
  -- 1. Handle user preferences (auto/prompt/off)
  -- 2. Let Neovim reload buffer naturally (increments changedtick)
  -- 3. Send LSP notification with Neovim's exact version
  -- 4. Return detailed result with version info
end
```

## 📋 **Next Steps - CRITICAL**

### **1. Immediate: Diagnostics & Cleanup**
- **Restart Neovim** to verify startup error fix
- **Load MCP diagnostics server** to check implementation
- **Run diagnostics on new files:**
  - `lua/mcp-diagnostics/shared/unified_refresh.lua`
  - `lua/mcp-diagnostics/shared/lsp_interact.lua` (new function)
  - `lua/mcp-diagnostics/shared/file_watcher.lua` (updated)
  - `lua/mcp-diagnostics/shared/config.lua` (updated)

### **2. Code Cleanup Required**
- **Redundant code:** Old refresh functions in `lsp_interact.lua` may be obsolete
- **Import cycles:** New `unified_refresh.lua` requires `lsp_interact.lua` which may create circular deps
- **Config validation:** New mode values need validation
- **Error handling:** Edge cases in unified refresh flow

### **3. Integration & Testing**
- Update MCP tools to use unified refresh instead of old refresh methods
- Test external edit scenarios (sed, git, manual file changes)
- Verify LSP version synchronization actually works
- Test all three modes: auto/prompt/off

## 🎯 **Expected Benefits (To Validate)**

### **Eliminates Sleep Delays:**
```lua
-- OLD (crude):
sed_command()
sleep(2)  -- Hope it's enough time
check_diagnostics()

-- NEW (smart):
sed_command() 
unified_refresh_and_wait(files)  -- Real acknowledgment
// Proceeds immediately when LSP ready
```

### **Perfect LSP Protocol Compliance:**
- ✅ Uses proper `textDocument/didChange` notifications
- ✅ Version numbers match Neovim's internal tracking
- ✅ No race conditions between buffer and LSP updates
- ✅ Proper handling of user preferences

## 🔍 **Files Modified in This Session**

1. **lua/mcp-diagnostics/mcphub/tools_extra.lua** - ✅ Fixed startup error
2. **lua/mcp-diagnostics/shared/config.lua** - ✅ Updated auto_reload_mode values
3. **lua/mcp-diagnostics/shared/unified_refresh.lua** - ✅ Created new unified system
4. **lua/mcp-diagnostics/shared/lsp_interact.lua** - ✅ Added version-sync function
5. **lua/mcp-diagnostics/shared/file_watcher.lua** - ✅ Updated to use unified refresh

## 🚨 **Critical Commands for Resume**

```bash
# 1. Restart Neovim to test startup fix
# 2. Load diagnostics:
:lua require('mcp-diagnostics').setup_mcphub()

# 3. Run diagnostics on new implementation:
# Use MCP tools to check:
# - unified_refresh.lua (new file)  
# - lsp_interact.lua (circular import risk)
# - config.lua (mode validation)
# - file_watcher.lua (integration check)
```

## 💡 **Key Insights for Continuation**

1. **The core innovation:** Using Neovim's `changedtick` as LSP version eliminates sync issues
2. **The unified approach:** Single atomic operation for buffer + LSP refresh
3. **User-centric design:** Three clear modes for different workflows
4. **Protocol compliance:** Proper LSP `textDocument/didChange` notifications

## 🎯 **Success Criteria**

- [ ] Startup error completely resolved
- [ ] Zero diagnostics in new implementation files
- [ ] External edit workflow works without sleep delays
- [ ] All three modes (auto/prompt/off) work correctly
- [ ] LSP version synchronization verified
- [ ] No circular dependencies or redundant code

---

**Resume Point:** Use MCP diagnostics to validate implementation and clean up redundant code. The architecture is sound, now need to ensure clean implementation.