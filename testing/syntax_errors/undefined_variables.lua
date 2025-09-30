-- File with undefined variable usage for testing diagnostics

local M = {}

function M.undefined_usage()
    -- Using undefined variable 'unknown_var'
    print(unknown_var)
    
    -- Using undefined variable in calculation
    local result = undefined_number * 2
    
    -- Calling undefined function
    local value = undefined_function()
    
    return result + value
end

function M.typos_and_mistakes()
    -- Typo in string method name
    local text = "Hello World"
    local length = string.lenght(text)  -- Should be 'length'
    
    -- Typo in table method
    local tbl = {1, 2, 3}
    local count = table.maxn(tbl)  -- Deprecated function
    
    -- Using wrong variable name
    local my_variable = 42
    print(my_varible)  -- Typo: should be 'my_variable'
    
    return length + count
end

function M.scope_errors()
    do
        local local_var = "I'm local"
    end
    
    -- Trying to use local_var outside its scope
    print(local_var)  -- This should be undefined
    
    -- Using variable before declaration
    print(future_var)
    local future_var = "Defined later"
end

function M.module_errors()
    -- Trying to use non-existent module
    local fake_module = require('non_existent_module')
    
    -- Using undefined method on real module
    local result = math.invalid_function(10)
    
    -- Wrong module reference
    local str_result = string.invalid_method("test")
    
    return fake_module, result, str_result
end

return M