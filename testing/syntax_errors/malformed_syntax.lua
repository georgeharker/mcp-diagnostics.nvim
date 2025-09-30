-- File with various syntax errors for testing diagnostics

local M = {}

-- Missing 'then' keyword
function M.missing_then()
    local x = 10
    if x > 5  -- Missing 'then'
        print("Greater than 5")
    end
end

-- Unbalanced parentheses
function M.unbalanced_parens()
    local result = math.max(10, 20, 30  -- Missing closing parenthesis
    print(result
end

-- Invalid string literals
function M.invalid_strings()
    local bad_string = "This string is not closed
    local another_bad = 'Mixed quotes"
    local escaped_wrong = "This has wrong \q escape"
    return bad_string, another_bad, escaped_wrong
end

-- Malformed table literals
function M.bad_tables()
    local bad_table = {
        key1 = "value1"
        key2 = "value2"  -- Missing comma
        key3 = "value3",
        key4 =   -- Missing value
    }
    
    local another_bad = {1, 2, 3,}  -- Trailing comma (this is actually valid in Lua, but some linters flag it)
    
    return bad_table, another_bad
end

-- Incorrect operators
function M.operator_errors()
    local x = 10
    local y = 20
    
    -- Invalid comparison operator
    if x === y then  -- Should be == or ~=
        print("Equal")
    end
    
    -- Invalid assignment operator
    x += 5  -- Lua doesn't have compound assignment operators
    y -= 3
    
    -- Invalid logical operator
    if x && y then  -- Should be 'and'
        print("Both truthy")
    end
    
    if x || y then  -- Should be 'or'
        print("At least one truthy")
    end
end

-- Malformed function definitions
function M.bad_functions
    -- Missing parentheses in function definition
    print("This function is malformed")
end

function M.another_bad_function(param1, param2,)  -- Trailing comma in parameters
    -- Extra comma in parameter list
    return param1 + param2
end

-- Invalid variable names
function M.bad_variable_names()
    local 123invalid = "starts with number"  -- Invalid identifier
    local my-variable = "contains hyphen"    -- Invalid character
    local my.variable = "contains dot"       -- Invalid character
    local function = "reserved keyword"     -- Using reserved word
    
    return 123invalid, my-variable, my.variable, function
end

-- Misplaced keywords
function M.misplaced_keywords()
    local x = 10
    
    -- 'else' without 'if'
    else
        print("Orphaned else")
    end
    
    -- 'elseif' without 'if'
    elseif x > 5 then
        print("Orphaned elseif")
    end
    
    -- 'end' without matching block
    end
end

-- Invalid escape sequences in comments and strings
function M.escape_issues()
    local path = "C:\new\folder"  -- Unescaped backslashes
    local regex = "\d+"           -- Invalid escape sequence \d
    local unicode = "\u1234"      -- Invalid escape sequence \u
    
    return path, regex, unicode
end

return M