-- File with missing 'end' statements for testing diagnostics

local M = {}

function M.test_function()
    local x = 10
    if x > 5 then
        print("x is greater than 5")
        -- Missing 'end' here for the if statement

function M.another_function()
    for i = 1, 10 do
        print(i)
        -- Missing 'end' here for the for loop
        
    local result = 0
    while result < 100 do
        result = result + 10
        -- Missing 'end' here for the while loop

return M