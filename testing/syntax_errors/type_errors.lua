-- File with type-related errors for testing diagnostics

local M = {}

function M.type_mismatches()
    -- Attempting to call a number as a function
    local number = 42
    local result = number()  -- Error: attempt to call a number value
    
    -- Attempting to index a string as a table
    local text = "Hello"
    local char = text[1]  -- Should use string.sub(text, 1, 1)
    
    -- Attempting arithmetic on string
    local str_num = "10"
    local calculation = str_num + 5  -- Should convert to number first
    
    return result, char, calculation
end

function M.nil_operations()
    local nil_value = nil
    
    -- Attempting to index nil
    local indexed = nil_value.property
    
    -- Attempting to call nil
    local called = nil_value()
    
    -- Attempting arithmetic with nil
    local arithmetic = nil_value + 10
    
    return indexed, called, arithmetic
end

function M.table_errors()
    local empty_table = {}
    
    -- Calling table as function
    local result = empty_table()
    
    -- Using wrong table methods
    local length = #empty_table.non_existent
    
    -- Incorrect table operations
    local value = empty_table + 5
    
    return result, length, value
end

function M.string_operations()
    local number = 123
    
    -- Using string methods on number without conversion
    local length = string.len(number)  -- Should convert to string first
    local upper = string.upper(number)
    local sub = string.sub(number, 1, 2)
    
    -- Concatenating incompatible types
    local concat = number .. true  -- Should convert boolean to string
    
    return length, upper, sub, concat
end

function M.function_call_errors()
    -- Wrong number of arguments
    local max_result = math.max()  -- Requires at least 1 argument
    local min_result = math.min(10)  -- Requires at least 2 arguments for meaningful comparison
    
    -- Passing wrong type of arguments
    local sqrt_result = math.sqrt("not a number")
    local abs_result = math.abs(nil)
    
    return max_result, min_result, sqrt_result, abs_result
end

function M.loop_variable_errors()
    -- Using wrong variable type in numeric for
    for i = "start", "end" do  -- Should be numbers
        print(i)
    end
    
    -- Using undefined variable in loop condition
    for i = 1, undefined_limit do
        print(i)
    end
    
    -- Generic for with wrong iterator
    for key, value in "not a table" do  -- Should be ipairs or pairs
        print(key, value)
    end
end

return M