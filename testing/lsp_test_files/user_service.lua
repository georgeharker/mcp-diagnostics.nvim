-- User Service - Business logic layer for user operations
-- Demonstrates service patterns and cross-module dependencies

local UserModel = require('testing.lsp_test_files.user_model')
local database = require('testing.lsp_test_files.database')
local validation = require('testing.lsp_test_files.validation')

---@class UserService
local UserService = {}

--- Creates a new user with validation
---@param name string User's full name
---@param email string User's email address
---@return UserModel? user, string? error
function UserService.create_user(name, email)
    -- Sanitize inputs
    name = validation.sanitize_input(name)
    email = validation.sanitize_input(email)
    
    -- Create user instance
    local user = UserModel.new(0, name, email)  -- ID will be assigned by database
    
    -- Validate user data
    local valid, error_msg = user:validate()
    if not valid then
        return nil, error_msg
    end
    
    -- Save to database
    local success = user:save()
    if not success then
        return nil, "Failed to save user to database"
    end
    
    return user, nil
end

--- Retrieves user by ID with error handling
---@param user_id number User ID to retrieve
---@return UserModel? user, string? error
function UserService.get_user(user_id)
    if not validation.is_valid_user_id(user_id) then
        return nil, "Invalid user ID"
    end
    
    local user = UserModel.load(user_id)
    if not user then
        return nil, "User not found"
    end
    
    return user, nil
end

--- Updates user information with validation
---@param user_id number User ID to update
---@param updates table Table with name and/or email fields
---@return boolean success, string? error
function UserService.update_user(user_id, updates)
    local user, error_msg = UserService.get_user(user_id)
    if not user then
        return false, error_msg
    end
    
    -- Sanitize update inputs
    if updates.name then
        updates.name = validation.sanitize_input(updates.name)
    end
    if updates.email then
        updates.email = validation.sanitize_input(updates.email)
    end
    
    -- Apply updates
    local success = user:update(updates.name, updates.email)
    if not success then
        return false, "Failed to update user"
    end
    
    return true, nil
end

--- Deletes user with confirmation
---@param user_id number User ID to delete
---@return boolean success, string? error
function UserService.delete_user(user_id)
    local user, error_msg = UserService.get_user(user_id)
    if not user then
        return false, error_msg
    end
    
    local success = user:delete()
    if not success then
        return false, "Failed to delete user"
    end
    
    return true, nil
end

--- Lists all users with optional filtering
---@param email_filter string? Optional email pattern to filter by
---@return table users Array of user data
function UserService.list_users(email_filter)
    local users
    
    if email_filter then
        users = database.search_users_by_email(email_filter)
    else
        users = database.get_all_users()
    end
    
    -- Convert to UserModel instances
    local user_instances = {}
    for _, user_data in ipairs(users) do
        local user = UserModel.new(user_data.id, user_data.name, user_data.email)
        table.insert(user_instances, user)
    end
    
    return user_instances
end

--- Validates user credentials (simulate authentication)
---@param email string User email
---@param password string User password
---@return UserModel? user, string? error
function UserService.authenticate(email, password)
    email = validation.sanitize_input(email)
    
    if not validation.is_valid_email(email) then
        return nil, "Invalid email format"
    end
    
    local valid, error_msg = validation.validate_password(password)
    if not valid then
        return nil, error_msg
    end
    
    -- Search for user by email
    local users = database.search_users_by_email("^" .. email:gsub("[%-%^%$%(%)%%%.%[%]%*%+%?]", "%%%1") .. "$")
    
    if #users == 0 then
        return nil, "User not found"
    end
    
    local user_data = users[1]
    local user = UserModel.new(user_data.id, user_data.name, user_data.email)
    
    -- In a real system, you'd verify the password hash here
    -- For testing, we'll just return the user
    return user, nil
end

--- Gets user statistics
---@return table stats Service statistics
function UserService.get_statistics()
    local db_stats = database.get_stats()
    local all_users = UserService.list_users()
    
    local email_domains = {}
    for _, user in ipairs(all_users) do
        local domain = string.match(user.email, "@(.+)$")
        if domain then
            email_domains[domain] = (email_domains[domain] or 0) + 1
        end
    end
    
    return {
        total_users = db_stats.total_users,
        database_connected = db_stats.connected,
        email_domains = email_domains,
        next_id = db_stats.next_id
    }
end

--- Batch creates multiple users
---@param user_data_list table Array of user data tables
---@return table results Array of creation results
function UserService.create_users_batch(user_data_list)
    local results = {}
    
    for i, user_data in ipairs(user_data_list) do
        local user, error_msg = UserService.create_user(user_data.name, user_data.email)
        
        table.insert(results, {
            index = i,
            success = user ~= nil,
            user = user,
            error = error_msg
        })
    end
    
    return results
end

return UserService