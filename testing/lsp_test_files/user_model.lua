-- User Model - Main user data structure and operations
-- This file demonstrates classes, methods, and cross-file references

local validation = require('testing.lsp_test_files.validation')
local database = require('testing.lsp_test_files.database')

---@class UserModel
---@field id number
---@field name string
---@field email string
---@field created_at number
local UserModel = {}
UserModel.__index = UserModel

--- Creates a new user instance
---@param id number User ID
---@param name string User's full name
---@param email string User's email address
---@return UserModel
function UserModel.new(id, name, email)
    local self = setmetatable({}, UserModel)
    self.id = id
    self.name = name
    self.email = email
    self.created_at = os.time()
    return self
end

--- Validates user data using validation module
---@return boolean, string?
function UserModel:validate()
    if not validation.is_valid_email(self.email) then
        return false, "Invalid email format"
    end
    
    if not validation.is_valid_name(self.name) then
        return false, "Invalid name format"
    end
    
    return true
end

--- Saves user to database
---@return boolean success
function UserModel:save()
    local valid, error_msg = self:validate()
    if not valid then
        error("Cannot save invalid user: " .. error_msg)
    end
    
    return database.insert_user(self)
end

--- Loads user from database by ID
---@param user_id number
---@return UserModel?
function UserModel.load(user_id)
    local user_data = database.get_user(user_id)
    if not user_data then
        return nil
    end
    
    return UserModel.new(user_data.id, user_data.name, user_data.email)
end

--- Updates user information
---@param name string? New name
---@param email string? New email
---@return boolean success
function UserModel:update(name, email)
    if name then
        self.name = name
    end
    if email then
        self.email = email
    end
    
    return database.update_user(self.id, self)
end

--- Deletes user from database
---@return boolean success
function UserModel:delete()
    return database.delete_user(self.id)
end

--- Gets user's display name
---@return string
function UserModel:get_display_name()
    return string.format("%s <%s>", self.name, self.email)
end

--- Converts user to table representation
---@return table
function UserModel:to_table()
    return {
        id = self.id,
        name = self.name,
        email = self.email,
        created_at = self.created_at,
        display_name = self:get_display_name()
    }
end

return UserModel