-- Database operations module
-- Simulates database operations for testing LSP functionality

local validation = require('testing.lsp_test_files.validation')

---@class DatabaseModule
local M = {}

-- Simulated in-memory database
local users_table = {}
local next_id = 1

--- Connection status
M.connected = false

--- Initializes the database connection
---@return boolean success
function M.connect()
    -- Simulate connection logic
    M.connected = true
    print("Database connected")
    return true
end

--- Closes database connection
function M.disconnect()
    M.connected = false
    print("Database disconnected")
end

--- Checks if database is connected
---@return boolean connected
function M.is_connected()
    return M.connected
end

--- Inserts a new user into the database
---@param user table User data to insert
---@return boolean success
---@return number? user_id
function M.insert_user(user)
    if not M.connected then
        error("Database not connected")
    end
    
    if not validation.is_valid_email(user.email) then
        return false, nil
    end
    
    if not validation.is_valid_name(user.name) then
        return false, nil
    end
    
    -- Check for duplicate email
    for _, existing_user in pairs(users_table) do
        if existing_user.email == user.email then
            return false, nil  -- Email already exists
        end
    end
    
    local user_id = next_id
    next_id = next_id + 1
    
    users_table[user_id] = {
        id = user_id,
        name = user.name,
        email = user.email,
        created_at = user.created_at or os.time()
    }
    
    return true, user_id
end

--- Retrieves user by ID
---@param user_id number ID of user to retrieve
---@return table? user_data
function M.get_user(user_id)
    if not M.connected then
        error("Database not connected")
    end
    
    if not validation.is_valid_user_id(user_id) then
        return nil
    end
    
    return users_table[user_id]
end

--- Updates existing user
---@param user_id number ID of user to update
---@param user_data table Updated user data
---@return boolean success
function M.update_user(user_id, user_data)
    if not M.connected then
        error("Database not connected")
    end
    
    if not users_table[user_id] then
        return false  -- User doesn't exist
    end
    
    if user_data.name and not validation.is_valid_name(user_data.name) then
        return false
    end
    
    if user_data.email and not validation.is_valid_email(user_data.email) then
        return false
    end
    
    -- Check for duplicate email (excluding current user)
    if user_data.email then
        for id, existing_user in pairs(users_table) do
            if id ~= user_id and existing_user.email == user_data.email then
                return false  -- Email already exists
            end
        end
    end
    
    -- Update fields
    local user = users_table[user_id]
    if user_data.name then
        user.name = user_data.name
    end
    if user_data.email then
        user.email = user_data.email
    end
    
    return true
end

--- Deletes user by ID
---@param user_id number ID of user to delete
---@return boolean success
function M.delete_user(user_id)
    if not M.connected then
        error("Database not connected")
    end
    
    if not users_table[user_id] then
        return false  -- User doesn't exist
    end
    
    users_table[user_id] = nil
    return true
end

--- Gets all users
---@return table users Array of all users
function M.get_all_users()
    if not M.connected then
        error("Database not connected")
    end
    
    local users = {}
    for _, user in pairs(users_table) do
        table.insert(users, user)
    end
    
    return users
end

--- Searches users by email pattern
---@param email_pattern string Email pattern to search
---@return table users Matching users
function M.search_users_by_email(email_pattern)
    if not M.connected then
        error("Database not connected")
    end
    
    local matches = {}
    for _, user in pairs(users_table) do
        if string.match(user.email, email_pattern) then
            table.insert(matches, user)
        end
    end
    
    return matches
end

--- Gets database statistics
---@return table stats Database statistics
function M.get_stats()
    if not M.connected then
        error("Database not connected")
    end
    
    return {
        total_users = #M.get_all_users(),
        next_id = next_id,
        connected = M.connected
    }
end

--- Clears all data (for testing)
function M.clear_all()
    if not M.connected then
        error("Database not connected")
    end
    
    users_table = {}
    next_id = 1
end

return M