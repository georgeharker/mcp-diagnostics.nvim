
local buffers = require("mcp-diagnostics.shared.buffers")
local unified_refresh = require("mcp-diagnostics.shared.unified_refresh")
local base = require("mcp-diagnostics.codecompanion.tools.base")
local BaseTool = base.BaseTool

local M = {}
M.buffer_status = setmetatable({
    name = "buffer_status",
    description = "Get status of all loaded buffers including file paths and diagnostic counts",
    cmds = {
        function(self, args, _input)
            args = args or {}

            local status = buffers.get_buffer_status()
            return self:success("llm", status, "Buffer Status")
        end,
    },
    schema = {
        type = "function",
        ["function"] = {
            name = "buffer_status",
            description = "Get status of all loaded buffers including file paths and diagnostic counts",
            -- parameters = {
            --     type = "object",
            --     properties = {},
            --     additionalProperties = false
            -- },
            strict = true
        }
    },
    output = BaseTool:create_output_handlers("Buffer Status")
}, BaseTool)

-- Ensure Files Loaded Tool
M.ensure_files_loaded = setmetatable({
    name = "ensure_files_loaded",
    description = "Ensure specified files are loaded in buffers for analysis",
    cmds = {
        function(self, args, _input)
            args = args or {}

           -- Validate required arguments
           local validation_error = self:validate_required_params(args, { "files" }, {
               files = "array of file paths to load into buffers"
           })
           if validation_error then
               return validation_error
           end

           -- Validate argument types
           if type(args.files) ~= "table" then
               return self:error(nil, nil, "Invalid 'files' parameter: must be an array of file paths")
           end
           if #args.files == 0 then
               return self:error(nil, nil, "Empty 'files' array: must specify at least one file path")
           end
           for i, file in ipairs(args.files) do
               if type(file) ~= "string" then
                   return self:error(nil, nil, string.format("Invalid 'files[%d]' parameter: must be a string (file path)", i))
               end
               if file == "" then
                   return self:error(nil, nil, string.format("Invalid 'files[%d]' parameter: file path cannot be empty", i))
               end
           end

            local files = args.files

            local results = {}
            for _, file in ipairs(files) do
                local result = buffers.ensure_buffer_loaded(file, false)
                table.insert(results, result)
            end

            return self:success("llm", results, "File Loading Results")
        end,
    },
    schema = {
        type = "function",
        ["function"] = {
            name = "ensure_files_loaded",
            description = "Ensure specified files are loaded in buffers for analysis",
            parameters = {
                type = "object",
                properties = {
                    files = {
                        type = "array",
                        items = { type = "string" },
                        description = "List of file paths to load"
                    }
                },
                required = { "files" },
                additionalProperties = false
            },
            strict = true
        }
    },
    output = BaseTool:create_output_handlers("File Loading Results")
}, BaseTool)

-- Refresh After External Changes Tool
M.refresh_after_external_changes = setmetatable({
    name = "refresh_after_external_changes",
    description = "Refresh diagnostics and LSP state after external file changes",
    cmds = {
        function(self, args, _input)
            args = args or {}

           -- Validate arguments
           if args.files and type(args.files) ~= "table" then
               return self:error(nil, nil, "Invalid 'files' parameter: must be an array of file paths")
           end
           if args.files then
               for i, file in ipairs(args.files) do
                   if type(file) ~= "string" then
                       return self:error(nil, nil, string.format("Invalid 'files[%d]' parameter: must be a string (file path)", i))
                   end
                   if file == "" then
                       return self:error(nil, nil, string.format("Invalid 'files[%d]' parameter: file path cannot be empty", i))
                   end
               end
           end

            local files = args.files

            local result = unified_refresh.refresh_after_external_changes(files)
            return self:success("llm", result, "Refresh Results")
        end,
    },
    schema = {
        type = "function",
        ["function"] = {
            name = "refresh_after_external_changes",
            description = "Refresh diagnostics and LSP state after external file changes",
            parameters = {
                type = "object",
                properties = {
                    files = {
                        type = "array",
                        items = { type = "string" },
                        description = "List of files that changed (all loaded files if not specified)"
                    }
                },
                additionalProperties = false
            },
            strict = true
        }
    },
    output = BaseTool:create_output_handlers("Refresh Results")
}, BaseTool)

return M
