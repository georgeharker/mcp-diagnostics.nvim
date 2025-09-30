
-- Test file for diagnostics
local function test_function()
    local unused_variable = "hello"  -- Should trigger unused variable warning
    undefined_function()             -- Should trigger undefined function error

    local x = nil
    print(x.field)  -- Should trigger attempt to index nil
end

-- Another function with issues
function bad_function()
    local result = "something"  -- Unused variable
    -- Missing return statement
end
