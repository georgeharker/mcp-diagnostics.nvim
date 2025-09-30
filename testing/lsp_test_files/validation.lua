-- Validation utilities for user data
-- This file provides validation functions used across the application

local M = {}

--- Email validation pattern
local EMAIL_PATTERN = "^[%w%._%+%-]+@[%w%.%-]+%.%w+$"

--- Name validation pattern (letters, spaces, hyphens, apostrophes)
local NAME_PATTERN = "^[%a%s%-']+$"

--- Validates email format
---@param email string Email to validate
---@return boolean valid
function M.is_valid_email(email)
    if not email or type(email) ~= "string" then
        return false
    end
    
    -- Check basic format
    if not string.match(email, EMAIL_PATTERN) then
        return false
    end
    
    -- Check length constraints
    if string.len(email) > 254 then
        return false
    end
    
    -- Check for consecutive dots
    if string.match(email, "%.%.") then
        return false
    end
    
    return true
end

--- Validates name format
---@param name string Name to validate
---@return boolean valid
function M.is_valid_name(name)
    if not name or type(name) ~= "string" then
        return false
    end
    
    -- Check basic format
    if not string.match(name, NAME_PATTERN) then
        return false
    end
    
    -- Check length constraints
    local trimmed = string.match(name, "^%s*(.-)%s*$")
    if string.len(trimmed) < 2 or string.len(trimmed) > 100 then
        return false
    end
    
    return true
end

--- Validates user ID
---@param id any Value to check as ID
---@return boolean valid
function M.is_valid_user_id(id)
    if type(id) ~= "number" then
        return false
    end
    
    return id > 0 and id == math.floor(id)
end

--- Sanitizes input string for safe processing
---@param input string Input to sanitize
---@return string sanitized
function M.sanitize_input(input)
    if type(input) ~= "string" then
        return ""
    end
    
    -- Remove control characters and excessive whitespace
    local sanitized = string.gsub(input, "[%c]", "")
    sanitized = string.gsub(sanitized, "%s+", " ")
    sanitized = string.match(sanitized, "^%s*(.-)%s*$") or ""
    
    return sanitized
end

--- Validates password strength
---@param password string Password to validate
---@return boolean valid
---@return string? error_message
function M.validate_password(password)
    if type(password) ~= "string" then
        return false, "Password must be a string"
    end
    
    if string.len(password) < 8 then
        return false, "Password must be at least 8 characters"
    end
    
    if string.len(password) > 128 then
        return false, "Password is too long"
    end
    
    -- Check for at least one letter and one number
    if not string.match(password, "%a") then
        return false, "Password must contain at least one letter"
    end
    
    if not string.match(password, "%d") then
        return false, "Password must contain at least one number"
    end
    
    return true
end

--- Validates phone number format (simple US format)
---@param phone string Phone number to validate
---@return boolean valid
function M.is_valid_phone(phone)
    if not phone or type(phone) ~= "string" then
        return false
    end
    
    -- Remove all non-digits
    local digits = string.gsub(phone, "[^%d]", "")
    
    -- Check for 10 or 11 digits (with or without country code)
    return string.len(digits) == 10 or string.len(digits) == 11
end

return M