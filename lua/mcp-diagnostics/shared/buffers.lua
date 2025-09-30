
local config = require("mcp-diagnostics.shared.config")
local M = {}

-- ============================================================================
-- Low-level Buffer Utilities (consolidated from buffer_utils.lua)
-- ============================================================================

-- Modern API compatibility layer
-- Centralizes all buffer option access for easy maintenance
local function get_buffer_option(bufnr, option)
    return vim.api.nvim_get_option_value(option, { buf = bufnr })
end

local function set_buffer_option(bufnr, option, value)
    vim.api.nvim_set_option_value(option, value, { buf = bufnr })
end

-- Centralized user edit detection setup
-- Previously duplicated in buffers.lua and lsp_interact.lua
function M.setup_user_edit_detection(bufnr, filepath, source_name)
    source_name = source_name or "[Buffer Utils]"

    -- Set up autocmd to detect when buffer becomes visible due to user action
    vim.api.nvim_create_autocmd({"BufWinEnter", "BufEnter"}, {
        buffer = bufnr,
        once = true, -- Only trigger once
        callback = function()
            -- Check if buffer is now listed (indicating user action)
            local is_listed = get_buffer_option(bufnr, 'buflisted')
            local is_hidden = get_buffer_option(bufnr, 'bufhidden')

            if is_listed and is_hidden == 'hide' then
                -- User has made buffer listed (via :edit or similar), make it fully visible
                set_buffer_option(bufnr, 'bufhidden', '')
                config.log_debug(
                    string.format("Buffer %d (%s) made fully visible by user action", bufnr, filepath),
                    source_name
                )
            end
        end,
        desc = "Make hidden buffer fully visible when user edits it"
    })
end

-- Centralized hidden buffer creation and setup
-- Eliminates duplication between buffers.lua and lsp_interact.lua
function M.create_hidden_buffer(filepath, source_name)
    source_name = source_name or "[Buffer Utils]"

    -- Create unlisted/hidden buffer
    local bufnr = vim.fn.bufnr(filepath, true)

    -- Configure as hidden buffer
    set_buffer_option(bufnr, 'buflisted', false)
    set_buffer_option(bufnr, 'bufhidden', 'hide')

    -- Set up user edit detection
    vim.schedule(function()
        M.setup_user_edit_detection(bufnr, filepath, source_name)
    end)

    config.log_debug(
        string.format("Created unlisted buffer %d for file: %s", bufnr, filepath),
        source_name
    )

    return bufnr
end

 function M.get_buffer_info(bufnr_or_filepath)
     local bufnr

     -- Handle both bufnr and filepath inputs
     if type(bufnr_or_filepath) == "string" then
         bufnr = vim.fn.bufnr(bufnr_or_filepath)
         if bufnr == -1 then
             return nil
         end
     elseif type(bufnr_or_filepath) == "number" then
         bufnr = bufnr_or_filepath
     else
        return nil
    end

    if not vim.api.nvim_buf_is_valid(bufnr) then
        return nil
    end

    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == "" then
        name = "[No Name]"
    end

    local is_loaded = vim.api.nvim_buf_is_loaded(bufnr)
    if not is_loaded then
        return {
            bufnr = bufnr,
            name = name,
            loaded = false
        }
    end

    -- Get buffer metadata using modern API
    local info = {
        bufnr = bufnr,
        name = name,
        loaded = true,
        filetype = get_buffer_option(bufnr, 'filetype'),
        buftype = get_buffer_option(bufnr, 'buftype'),
        modified = get_buffer_option(bufnr, 'modified'),
        readonly = get_buffer_option(bufnr, 'readonly'),
        buflisted = get_buffer_option(bufnr, 'buflisted'),
        bufhidden = get_buffer_option(bufnr, 'bufhidden'),
        line_count = vim.api.nvim_buf_line_count(bufnr)
    }

    -- Get LSP client info
    info.lsp_clients = {}
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    for _, client in ipairs(clients) do
        table.insert(info.lsp_clients, client.name)
    end
    info.has_lsp = #info.lsp_clients > 0

    -- Get file stats if it's a real file
    if info.buftype == '' and info.name ~= '[No Name]' then
        local file_exists = vim.fn.filereadable(info.name) == 1
        info.file_exists = file_exists
        info.file_size = file_exists and vim.fn.getfsize(info.name) or 0
        info.is_real_file = true
    else
        info.file_exists = false
        info.file_size = 0
        info.is_real_file = false
    end

    return info
end

-- Find buffer for specific criteria
-- Centralized logic for buffer discovery
function M.find_file_buffer(criteria)
    criteria = criteria or {}

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        local info = M.get_buffer_info(bufnr)
        if info and info.loaded then
            -- Apply criteria filters
            local match = true

            if criteria.must_be_real_file and not info.is_real_file then
                match = false
            end

            if criteria.exclude_filetypes then
                for _, ft in ipairs(criteria.exclude_filetypes) do
                    if info.filetype == ft then
                        match = false
                        break
                    end
                end
            end

            if criteria.exclude_buftypes then
                for _, bt in ipairs(criteria.exclude_buftypes) do
                    if info.buftype == bt then
                        match = false
                        break
                    end
                end
            end

            if criteria.must_have_lsp and not info.has_lsp then
                match = false
            end

            if match then
                return bufnr, info
            end
        end
    end

    return nil, nil
end

 function M.ensure_buffer_loaded(filepath, enable_file_watcher_or_auto_reload, source_name)
     -- Handle backward compatibility: two-parameter (filepath, enable_auto_reload)
     -- and three-parameter (filepath, enable_file_watcher, source_name) signatures
     local enable_file_watcher, actual_source_name

     if type(enable_file_watcher_or_auto_reload) == "boolean" and source_name == nil then
         -- Two-parameter signature: (filepath, enable_auto_reload)
         enable_file_watcher = enable_file_watcher_or_auto_reload
         actual_source_name = "[Shared Buffers]"
     else
         -- Three-parameter signature: (filepath, enable_file_watcher, source_name)
         enable_file_watcher = enable_file_watcher_or_auto_reload
         actual_source_name = source_name or "[Shared Buffers]"
     end

     -- Default file watcher based on configuration if not explicitly specified
     if enable_file_watcher == nil then
         enable_file_watcher = config.is_feature_enabled('auto_reload_files')
     end

    config.log_debug(string.format("Ensuring buffer loaded: %s", filepath), actual_source_name)

    -- Check if buffer already exists
    local existing_bufnr = vim.fn.bufnr(filepath)
    local buffer_created = false
    local bufnr

    if existing_bufnr == -1 then
        -- Create new hidden buffer
        bufnr = M.create_hidden_buffer(filepath, actual_source_name)
        buffer_created = true
    else
        -- Reuse existing buffer
        bufnr = existing_bufnr
        config.log_debug(
            string.format("Reusing existing buffer %d for file: %s", bufnr, filepath),
            actual_source_name
        )
    end

    -- Ensure buffer content is loaded
    if not vim.api.nvim_buf_is_loaded(bufnr) then
        vim.fn.bufload(bufnr)
    end

    -- Set up file watcher if requested
    if enable_file_watcher and vim.fn.filereadable(filepath) == 1 then
        local file_watcher = require("mcp-diagnostics.shared.file_watcher")
        file_watcher.setup_watcher(filepath, bufnr, actual_source_name)
    end

    local loaded = vim.api.nvim_buf_is_loaded(bufnr)
    config.log_debug(
        string.format("Buffer %s loaded: %s, watcher: %s",
            filepath, tostring(loaded), tostring(enable_file_watcher)),
        actual_source_name
    )

    return bufnr, loaded, buffer_created
end

-- Get comprehensive buffer status for all loaded buffers
-- Centralized replacement for the duplicated get_buffer_status logic
function M.get_all_buffer_status()
    config.log_debug("Getting comprehensive buffer status", "[Shared Buffers]")

    local status = {}
    local buffers = vim.api.nvim_list_bufs()

    for _, bufnr in ipairs(buffers) do
        local info = M.get_buffer_info(bufnr)
        if info and info.loaded and info.is_real_file then
            status[info.name] = info
        end
    end

    config.log_debug(
        string.format("Found %d loaded file buffers", vim.tbl_count(status)),
        "[Shared Buffers]"
    )

    return status
end

-- ============================================================================
-- High-level Buffer Interface (maintained for backward compatibility)
-- ============================================================================

function M.get_buffer_status()
    -- Use centralized buffer status implementation
    local status = M.get_all_buffer_status()

    -- Add backward compatibility field
    for _, info in pairs(status) do
        info.auto_reload = config.is_feature_enabled('auto_reload_files')
    end

    return status
end

function M.get_buffer_statistics()
    local status = M.get_buffer_status()

    local stats = {
        total_buffers = vim.tbl_count(status),
        with_lsp = 0,
        by_filetype = {},
        by_lsp_client = {},
        total_lines = 0,
        total_size = 0,
        modified_files = 0,
        readonly_files = 0
    }

    for _, info in pairs(status) do
        -- Count LSP-enabled buffers
        if info.has_lsp then
            stats.with_lsp = stats.with_lsp + 1
        end

        -- Count by filetype
        local ft = info.filetype or 'none'
        stats.by_filetype[ft] = (stats.by_filetype[ft] or 0) + 1

        -- Count by LSP client
        for _, client in ipairs(info.lsp_clients) do
            stats.by_lsp_client[client] = (stats.by_lsp_client[client] or 0) + 1
        end

        -- Accumulate stats
        stats.total_lines = stats.total_lines + info.line_count
        stats.total_size = stats.total_size + info.file_size

        if info.modified then
            stats.modified_files = stats.modified_files + 1
        end

        if info.readonly then
            stats.readonly_files = stats.readonly_files + 1
        end
    end

    return stats
end

function M.find_buffers(criteria)
    local status = M.get_buffer_status()
    local matches = {}

    for filepath, info in pairs(status) do
        local match = true

        -- Filter by filetype
        if criteria.filetype and info.filetype ~= criteria.filetype then
            match = false
        end

        -- Filter by LSP client
        if criteria.lsp_client then
            local has_client = false
            for _, client in ipairs(info.lsp_clients) do
                if client == criteria.lsp_client then
                    has_client = true
                    break
                end
            end
            if not has_client then
                match = false
            end
        end

        -- Filter by modified status
        if criteria.modified ~= nil and info.modified ~= criteria.modified then
            match = false
        end

        -- Filter by file existence
        if criteria.file_exists ~= nil and info.file_exists ~= criteria.file_exists then
            match = false
        end

        -- Filter by LSP availability
        if criteria.has_lsp ~= nil and info.has_lsp ~= criteria.has_lsp then
            match = false
        end
        if match then
            matches[filepath] = info
        end
    end

    return matches
end

function M.get_loaded_files()
    local status = M.get_buffer_status()
    local files = {}

    for filepath, _ in pairs(status) do
        table.insert(files, filepath)
    end

    return files
end

function M.is_file_loaded(filepath)
    local bufnr = vim.fn.bufnr(filepath)
    return bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr)
end


return M
