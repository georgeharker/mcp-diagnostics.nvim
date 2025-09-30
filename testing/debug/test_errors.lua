-- Test file with intentional errors for diagnostics testing

local M = {}

-- Error 1: Undefined variable usage
function M.test_undefined()
    print(undefined_variable) -- This should cause an undefined variable warning
    return unknown_function() -- This should also cause an error
end

-- Error 2: Syntax error (missing end)
function M.missing_end()
    if true then
        print("missing end statement")
    -- Missing 'end' here

-- Error 3: Type mismatch (attempt to call number)
function M.type_error()
    local number = 42
    number() -- Attempt to call a number
end

-- Error 4: Unused variable
function M.unused_var()
    local unused = "this variable is never used"
    print("something else")
end

-- Error 5: Invalid assignment
function M.invalid_assignment()
    local x = {1, 2, 3}
    x.invalid.nested = "error" -- Attempting to index nil
end

return M
