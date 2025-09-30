-- Main application entry point
-- Demonstrates application structure and cross-module usage

local UserService = require('testing.lsp_test_files.user_service')
local database = require('testing.lsp_test_files.database')

---@class Application
local App = {}

--- Application configuration
App.config = {
    database_url = "memory://test_db",
    debug_mode = true,
    max_users = 1000
}

--- Initializes the application
---@return boolean success
function App.initialize()
    print("Initializing application...")
    
    -- Connect to database
    local success = database.connect()
    if not success then
        print("Failed to connect to database")
        return false
    end
    
    print("Application initialized successfully")
    return true
end

--- Shuts down the application
function App.shutdown()
    print("Shutting down application...")
    database.disconnect()
    print("Application shutdown complete")
end

--- Runs the application demo
function App.run_demo()
    print("\n=== User Management Demo ===")
    
    -- Create some test users
    local users_to_create = {
        {name = "Alice Johnson", email = "alice@example.com"},
        {name = "Bob Smith", email = "bob@test.org"},
        {name = "Carol Davis", email = "carol@demo.net"}
    }
    
    print("\nCreating users...")
    local creation_results = UserService.create_users_batch(users_to_create)
    
    for _, result in ipairs(creation_results) do
        if result.success then
            print(string.format("✓ Created user: %s", result.user:get_display_name()))
        else
            print(string.format("✗ Failed to create user %d: %s", result.index, result.error))
        end
    end
    
    -- List all users
    print("\nListing all users...")
    local all_users = UserService.list_users()
    for _, user in ipairs(all_users) do
        print(string.format("  - %s", user:get_display_name()))
    end
    
    -- Update a user
    print("\nUpdating user...")
    if #all_users > 0 then
        local user_to_update = all_users[1]
        local success, error_msg = UserService.update_user(user_to_update.id, {
            name = "Alice Johnson-Smith"
        })
        
        if success then
            print("✓ User updated successfully")
        else
            print("✗ Failed to update user: " .. error_msg)
        end
    end
    
    -- Search users by domain
    print("\nSearching users by domain...")
    local example_users = UserService.list_users("@example%.com")
    print(string.format("Found %d users with @example.com domain", #example_users))
    
    -- Show statistics
    print("\nApplication statistics:")
    local stats = UserService.get_statistics()
    print(string.format("  Total users: %d", stats.total_users))
    print(string.format("  Database connected: %s", stats.database_connected))
    print("  Email domains:")
    for domain, count in pairs(stats.email_domains) do
        print(string.format("    %s: %d users", domain, count))
    end
    
    -- Test authentication
    print("\nTesting authentication...")
    if #all_users > 0 then
        local test_user = all_users[1]
        local auth_user, auth_error = UserService.authenticate(test_user.email, "testpassword123")
        
        if auth_user then
            print(string.format("✓ Authentication successful for %s", auth_user:get_display_name()))
        else
            print("✗ Authentication failed: " .. auth_error)
        end
    end
end

--- Handles application errors
---@param error_msg string Error message
---@param context string? Additional context
function App.handle_error(error_msg, context)
    local full_message = string.format("Application Error: %s", error_msg)
    if context then
        full_message = full_message .. string.format(" (Context: %s)", context)
    end
    
    if App.config.debug_mode then
        print(full_message)
        print(debug.traceback())
    else
        print("An error occurred. Please contact support.")
    end
end

--- Main application entry point
function App.main()
    -- Initialize application
    local success = App.initialize()
    if not success then
        App.handle_error("Failed to initialize application")
        return 1
    end
    
    -- Run demo in protected mode
    local demo_success, demo_error = pcall(App.run_demo)
    if not demo_success then
        App.handle_error(tostring(demo_error), "demo execution")
    end
    
    -- Cleanup
    App.shutdown()
    
    return demo_success and 0 or 1
end

-- Export the module
return App