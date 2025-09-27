-- Shared diagnostic operations for MCP Diagnostics
-- Provides unified diagnostic processing for both mcphub and server modes

local config = require("mcp-diagnostics.shared.config")
local M = {}

-- Convert severity number to text
local function severity_to_text(severity)
  local map = {
    [vim.diagnostic.severity.ERROR] = "error",
    [vim.diagnostic.severity.WARN] = "warn",
    [vim.diagnostic.severity.INFO] = "info",
    [vim.diagnostic.severity.HINT] = "hint"
  }
  return map[severity] or "unknown"
end

-- Convert severity text to number
local function text_to_severity(severity_text)
  local map = {
    error = vim.diagnostic.severity.ERROR,
    warn = vim.diagnostic.severity.WARN,
    info = vim.diagnostic.severity.INFO,
    hint = vim.diagnostic.severity.HINT
  }
  return map[severity_text]
end

-- Get buffer name safely
local function get_buffer_name(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return "[No Name]"
  end
  return name
end

-- Filter diagnostics by criteria
function M.filter_diagnostics(diagnostics, severity_filter, source_filter)
  if not severity_filter and not source_filter then
    return diagnostics
  end

  local filtered = {}
  local severity_num = severity_filter and text_to_severity(severity_filter)

  for _, diag in ipairs(diagnostics) do
    local include = true

    -- Filter by severity
    if severity_num and diag.severity ~= severity_num then
      include = false
    end

    -- Filter by source
    if include and source_filter and diag.source ~= source_filter then
      include = false
    end

    if include then
      table.insert(filtered, diag)
    end
  end

  return filtered
end

-- Format diagnostic for output
function M.format_diagnostic(diag)
  local bufnr = diag.bufnr
  local filename = bufnr and get_buffer_name(bufnr) or ""

  return {
    filename = filename,
    bufnr = bufnr,
    lnum = diag.lnum,
    col = diag.col,
    end_lnum = diag.end_lnum,
    end_col = diag.end_col,
    severity = diag.severity,
    severityText = severity_to_text(diag.severity),
    message = diag.message,
    source = diag.source or "",
    code = diag.code or ""
  }
end

-- Get all diagnostics with optional filtering
function M.get_all_diagnostics(files, severity_filter, source_filter)
  config.log_debug("Getting diagnostics", "[Shared Diagnostics]")

  local all_diagnostics

  if files and #files > 0 then
    -- Get diagnostics for specific files
    all_diagnostics = {}
    for _, file in ipairs(files) do
      local bufnr = vim.fn.bufnr(file)
      if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        local file_diagnostics = vim.diagnostic.get(bufnr)
        vim.list_extend(all_diagnostics, file_diagnostics)
      else
        config.log_debug(string.format("File not loaded in buffer: %s", file), "[Shared Diagnostics]")
      end
    end
  else
    -- Get all diagnostics from all buffers
    all_diagnostics = vim.diagnostic.get()
  end

  -- Filter diagnostics
  local filtered = M.filter_diagnostics(all_diagnostics, severity_filter, source_filter)

  -- Format for output
  local formatted = {}
  for _, diag in ipairs(filtered) do
    table.insert(formatted, M.format_diagnostic(diag))
  end

  config.log_debug(string.format("Found %d diagnostics", #formatted), "[Shared Diagnostics]")
  return formatted
end

-- Get diagnostic summary by severity and file
function M.get_diagnostic_summary()
  local all_diagnostics = vim.diagnostic.get()

  local summary = {
    total = #all_diagnostics,
    errors = 0,
    warnings = 0,
    info = 0,
    hints = 0,
    files = 0,
    byFile = {},
    bySource = {}
  }

  local unique_files = {}

  for _, diag in ipairs(all_diagnostics) do
    -- Count by severity
    if diag.severity == vim.diagnostic.severity.ERROR then
      summary.errors = summary.errors + 1
    elseif diag.severity == vim.diagnostic.severity.WARN then
      summary.warnings = summary.warnings + 1
    elseif diag.severity == vim.diagnostic.severity.INFO then
      summary.info = summary.info + 1
    elseif diag.severity == vim.diagnostic.severity.HINT then
      summary.hints = summary.hints + 1
    end

    -- Count by file
    local filename = get_buffer_name(diag.bufnr or 0)
    if filename ~= "[No Name]" then
      unique_files[filename] = true

      if not summary.byFile[filename] then
        summary.byFile[filename] = {
          errors = 0,
          warnings = 0,
          info = 0,
          hints = 0
        }
      end

      if diag.severity == vim.diagnostic.severity.ERROR then
        summary.byFile[filename].errors = summary.byFile[filename].errors + 1
      elseif diag.severity == vim.diagnostic.severity.WARN then
        summary.byFile[filename].warnings = summary.byFile[filename].warnings + 1
      elseif diag.severity == vim.diagnostic.severity.INFO then
        summary.byFile[filename].info = summary.byFile[filename].info + 1
      elseif diag.severity == vim.diagnostic.severity.HINT then
        summary.byFile[filename].hints = summary.byFile[filename].hints + 1
      end
    end

    -- Count by source
    local source = diag.source or "Unknown"
    if not summary.bySource[source] then
      summary.bySource[source] = 0
    end
    summary.bySource[source] = summary.bySource[source] + 1
  end

  summary.files = vim.tbl_count(unique_files)

  config.log_debug(string.format("Diagnostic summary: %d total (%d errors, %d warnings)",
    summary.total, summary.errors, summary.warnings), "[Shared Diagnostics]")

  return summary
end

-- Get diagnostics for a specific severity level
function M.get_diagnostics_by_severity(severity_text)
  return M.get_all_diagnostics(nil, severity_text, nil)
end

-- Check if there are any diagnostics of a specific severity
function M.has_diagnostics(severity_filter)
  local diagnostics = M.get_all_diagnostics(nil, severity_filter, nil)
  return #diagnostics > 0
end

-- Get the most problematic files (by error count)
function M.get_problematic_files(limit)
  limit = limit or 10
  local summary = M.get_diagnostic_summary()

  local files = {}
  for filename, counts in pairs(summary.byFile) do
    table.insert(files, {
      filename = filename,
      errors = counts.errors,
      warnings = counts.warnings,
      total = counts.errors + counts.warnings + counts.info + counts.hints,
      score = counts.errors * 3 + counts.warnings * 2 + counts.info + counts.hints * 0.5
    })
  end

  -- Sort by score (most problematic first)
  table.sort(files, function(a, b)
    return a.score > b.score
  end)

  -- Return top N files
  local result = {}
  for i = 1, math.min(limit, #files) do
    table.insert(result, files[i])
  end

  return result
end

-- Get diagnostic statistics for analysis
function M.get_diagnostic_stats()
  local summary = M.get_diagnostic_summary()
  local all_diagnostics = vim.diagnostic.get()

  -- Analyze error patterns
  local error_patterns = {}
  local source_analysis = {}

  for _, diag in ipairs(all_diagnostics) do
    -- Count error patterns by code or message prefix
    local pattern = diag.code or (diag.message and diag.message:match("^[^:]+")) or "unknown"
    pattern = tostring(pattern)
    error_patterns[pattern] = (error_patterns[pattern] or 0) + 1

    -- Analyze by source
    local source = diag.source or "Unknown"
    if not source_analysis[source] then
      source_analysis[source] = {
        errors = 0,
        warnings = 0,
        info = 0,
        hints = 0,
        total = 0
      }
    end

    source_analysis[source].total = source_analysis[source].total + 1
    if diag.severity == vim.diagnostic.severity.ERROR then
      source_analysis[source].errors = source_analysis[source].errors + 1
    elseif diag.severity == vim.diagnostic.severity.WARN then
      source_analysis[source].warnings = source_analysis[source].warnings + 1
    elseif diag.severity == vim.diagnostic.severity.INFO then
      source_analysis[source].info = source_analysis[source].info + 1
    elseif diag.severity == vim.diagnostic.severity.HINT then
      source_analysis[source].hints = source_analysis[source].hints + 1
    end
  end

  return {
    summary = summary,
    error_patterns = error_patterns,
    source_analysis = source_analysis,
    problematic_files = M.get_problematic_files(10)
  }
end

return M
