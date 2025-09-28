
## 📋 Context Summary

---

## 🔧 **ADDENDUM: External Edit Testing Strategy**

### **Critical Testing Focus**

In addition to standard MCP tool testing, we will **extensively test external file modifications** to ensure the enhanced file watcher system works reliably in real-world scenarios where files are changed outside of MCP/Neovim.

### **External Edit Methods to Test**

1. **Command Line Tools**:
   ```bash
   # sed for targeted replacements
   sed -i 's/UNUSED_CONSTANT/USED_CONSTANT/g' file_utils.py
   
   # patch application
   cat > fix.patch << EOF
   --- a/file_utils.py
   +++ b/file_utils.py
   @@ -10,1 +10,1 @@
   -import json
   +# import json  # Commented out unused import
   EOF
   patch < fix.patch
   
   # Direct file modifications
   echo "# Fixed linting issue" >> config_handler.py
   ```

2. **Git Operations**:
   ```bash
   git stash
   git checkout other_branch -- file.py
   git apply external_changes.patch
   git rebase --continue
   ```

3. **External Editor Simulation**:
   - Modify files directly via filesystem
   - Simulate IDE changes outside Neovim
   - Test concurrent editing scenarios

### **Testing Workflow**

**For Each Diagnostic Issue:**
1. **MCP Fix**: Apply fix using MCP file editing tools
2. **External Fix**: Apply same/different fix using sed/patch/direct edit
3. **Mixed Fix**: Combine MCP edits with external modifications
4. **Persistence Check**: Verify changes stick and are properly detected
5. **LSP Refresh**: Test that diagnostics update correctly
6. **File Watcher**: Verify new staleness detection works

### **Plugin Enhancement Goals**

Use real-world testing experience to **improve the mcp-diagnostics plugin**:

- **Timing Issues**: Identify and fix LSP refresh timing problems
- **External Change Detection**: Enhance file watcher reliability
- **Error Handling**: Improve robustness for edge cases
- **Performance**: Optimize for larger codebases
- **User Experience**: Better feedback for mixed edit scenarios
- **Documentation**: Create best practices guide

### **Success Validation**

**Must Demonstrate:**
- ✅ MCP edits persist and are detected
- ✅ External edits (sed/patch) are detected by file watcher
- ✅ Mixed workflows don't corrupt files or diagnostics
- ✅ LSP refresh timing is reliable and predictable
- ✅ Plugin improvements can be implemented during testing

**Expected Outcomes:**
1. **Robust System**: Handles all edit types reliably
2. **Enhanced Plugin**: Real improvements to mcp-diagnostics based on testing
3. **Documentation**: Best practices for mixed MCP + external workflows
4. **Confidence**: System ready for production use in complex scenarios

---

**🔥 Ready for Comprehensive Testing**: This strategy ensures we thoroughly test and improve the system using real-world scenarios with multiple edit methods!
We've just completed **Session 002** - a comprehensive code cleanup that achieved **zero diagnostics** and implemented enhanced file watcher functionality. The MCP diagnostics system is now production-ready with new capabilities for handling external file changes.

## 🎯 Testing Objectives for Next Session

### Primary Goals:
1. **Verify Edit Reflection**: Confirm that edits made through MCP tools properly reflect in actual files
2. **LSP Refresh Timing**: Develop reliable methods to wait for LSP diagnostic updates
3. **End-to-End Workflow**: Test complete diagnostic → fix → verify cycle
4. **Enhanced Features**: Test new file watcher and external change handling

5. **External Edit Integration**: Test how system handles changes made outside MCP
6. **Change Persistence**: Verify all edit methods create lasting file changes
7. **Plugin Enhancement**: Use real-world testing to improve mcp-diagnostics plugin

### Secondary Goals:
- Test MCP server restart stability
- Validate new enhanced file watcher functions
- Optimize diagnostic refresh timing
- Document best practices for reliable testing

- Identify and implement plugin improvements based on testing experience
- Create robust external change handling workflows
- Test mixed MCP + external edit scenarios

## 🛠️ Current System State

### ✅ Completed Features:
- **Zero Diagnostics**: All warnings, errors, and hints eliminated
- **Enhanced File Watcher**: New functions for external change detection
- **MCP Tool Integration**: Ready for external file management
- **Reload Mode Support**: Flexible handling of external changes

### 🔧 Files with New Functionality:
- `lua/mcp-diagnostics/shared/file_watcher.lua` - Enhanced staleness detection
- `lua/mcp-diagnostics/shared/lsp_extra.lua` - New refresh and checking functions  
- `lua/mcp-diagnostics/mcphub/tools_extra.lua` - Updated MCP tool implementations

### 🆕 New MCP Tools Available (after server restart):
- `refresh_after_external_changes` - Force refresh all watched files
- `check_file_staleness` - Check for externally modified files
- Enhanced `ensure_files_loaded` with `reload_mode` parameter

## 🧪 Recommended Testing Approach

### Phase 1: Basic Functionality Verification
1. **Load test codebase** with known diagnostic issues
2. **Verify diagnostic detection** using `diagnostics_get` and `diagnostics_summary`  
3. **Test file loading** with `ensure_files_loaded`
4. **Check LSP integration** with hover, definition, references tools

### Phase 2: Edit Cycle Testing
1. **Make targeted edits** using file editing tools
2. **Wait for LSP refresh** (develop reliable timing strategy)
3. **Verify diagnostic updates** reflect the changes
4. **Test external change detection** with new file watcher tools

### Phase 3: External Edit Testing (Critical)
1. **Direct MCP edits** using standard file editing tools
2. **External edits** using patch, sed, and direct file system modifications
3. **Mixed workflow testing** - combine MCP edits with external changes
4. **Persistence verification** - ensure all changes stick and are detected
5. **File watcher validation** - test new enhanced detection capabilities

**External Edit Methods to Test:**
- `sed` commands for targeted line replacements
- `patch` application for structured changes
- Direct file editing outside of Neovim/MCP
- Git operations (checkout, merge, rebase)
- External IDE modifications

### Phase 3: Advanced Workflow Testing
1. **Test reload modes** (reload/ask/none) for all change types
2. **Verify file staleness detection** works correctly
3. **Test comprehensive analysis tools** for complex diagnostics
4. **Validate MCP tool chaining** for efficient workflows
5. **Plugin enhancement opportunities** - identify improvements based on real usage

## ⚡ Key Testing Strategies

### For LSP Refresh Timing:
```lua
-- Strategy 1: Polling approach
local function wait_for_diagnostic_refresh(max_wait_seconds)
  local start_time = vim.loop.now()
  while (vim.loop.now() - start_time) < (max_wait_seconds * 1000) do
    -- Check if diagnostics have updated
    vim.wait(100)  -- Wait 100ms between checks
  end
end

-- Strategy 2: Event-based approach  
local function on_diagnostic_change(callback)
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    callback = callback
  })
end
```

### For Edit Verification:
1. **Before State**: Capture initial diagnostic count and specific issues
2. **Make Changes**: Apply targeted fixes through MCP tools
3. **Refresh Check**: Use new file watcher tools to ensure freshness
4. **After State**: Verify diagnostic improvements
5. **File Integrity**: Confirm actual file contents match expectations

### For External Change Testing:
1. Use `check_file_staleness` to detect out-of-sync files
2. Test `refresh_after_external_changes` for bulk refresh
3. Verify `reload_mode` parameter behavior in `ensure_files_loaded`

### For External Edit Integration:
```bash
# Method 1: sed for targeted line changes
sed -i 's/old_pattern/new_pattern/g' file.py

# Method 2: patch application
echo "patch content" | patch file.py

# Method 3: Direct file system edits
echo "new content" >> file.py

# Method 4: Git operations
git checkout other_branch -- file.py
git apply changes.patch

# Method 5: External editor simulation
vim file.py  # or code file.py, etc.
```

**Testing Sequence:**
1. **Baseline**: Capture initial diagnostic state
2. **MCP Edit**: Make change via MCP tools, verify detection
3. **External Edit**: Make change via sed/patch, test detection
4. **Mixed Edit**: Combine MCP + external changes
5. **Verification**: Ensure all changes persist and are detected
6. **Plugin Feedback**: Document issues found for plugin improvements

## 🎯 Success Criteria

### Must Have:
- [ ] Edits made via MCP reflect in actual files immediately
- [ ] LSP diagnostics refresh reliably after changes  
- [ ] New file watcher functions work correctly
- [ ] No regression in existing functionality

### Should Have:
- [ ] Reliable timing mechanism for LSP refresh waits
- [ ] Efficient diagnostic update detection
- [ ] External change handling works smoothly
- [ ] MCP tool chaining works efficiently  

### Nice to Have:
- [ ] Automated test suite for common workflows
- [ ] Performance optimization for large codebases
- [ ] Advanced diagnostic correlation features
- [ ] Integration with external editors

## 🚀 Session Kickoff Commands

```bash
# 1. Start with a codebase that has known issues
# (You'll provide this)

# 2. Load the MCP diagnostics system
# Restart MCP server to activate new features

# 3. Run initial diagnostic scan
use_mcp_tool("mcp-diagnostics", "diagnostics_summary", {})

# 4. Load problematic files  
use_mcp_tool("mcp-diagnostics", "ensure_files_loaded", {
  "files": [/* your files */]
})

# 5. Begin systematic testing
```

## 📚 Background Context

This system represents a sophisticated bridge between Neovim's LSP diagnostics and AI coding assistants. We've built:

- **Comprehensive LSP Integration**: Full access to hover, definitions, references, symbols
- **Advanced File Management**: Smart loading, staleness detection, external change handling  
- **MCP Protocol Bridge**: Clean API for AI tools to interact with editor state
- **Diagnostic Correlation**: Pattern recognition across multiple files and issues
- **Production-Ready Codebase**: Zero diagnostics, enhanced error handling

The enhanced file watcher system (completed in Session 002) adds crucial capabilities for handling external changes - a common pain point when AI tools modify files outside of the editor's direct control.

## 💡 Key Questions to Answer

1. **Edit Reliability**: Do file changes via MCP tools consistently reflect in the filesystem?
2. **LSP Timing**: What's the most reliable way to wait for LSP diagnostic updates?
3. **Change Detection**: How well do the new file watcher tools detect external modifications?
4. **Workflow Efficiency**: Can we create smooth, automated diagnostic → fix → verify cycles?
5. **Scale Testing**: How does the system perform with larger codebases?

---

**🎯 Ready to Resume**: Load this context, restart the MCP diagnostics server, and let's make this system incredibly useful for real-world development workflows!