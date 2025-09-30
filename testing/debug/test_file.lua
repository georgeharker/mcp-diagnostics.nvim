-- Test file for diagnostic testing
local function test_function()
    local unused_variable = "hello"  -- This should trigger a warning
    local another_unused = 42        -- Another unused variable
    
    -- Missing return statement but function expects one
    if true then
        print("test")
    end
    
    -- Some other potential issues
    local x = nil
    print(x.field)  -- Attempting to index nil
    
    -- Trailing spaces at the end of this line    
    local y = "test"   
end

-- Call undefined function
undefined_function()

-- Missing return
function bad_function()
    local result = "something"
end