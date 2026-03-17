-- ============================================================
-- UI_REFACTORED/LOG_CONFIG.LUA - Centralized Logging Configuration
-- ============================================================
-- Controls logging for all UI refactored components
--
-- Usage:
--   local LogConfig = dofile("ui/log_config.lua")
--   LogConfig.log("ComponentName", "message")

local LogConfig = {}

-- ============================================================
-- CONFIGURATION
-- ============================================================

-- Master switch: set to false to disable ALL ui logging
LogConfig.ENABLED = false

-- Component-specific log levels (for fine-grained control)
LogConfig.COMPONENTS = {
    -- Core components
    ItemSelector = true,
    DualSelector = true,
    -- Specific selectors
    BowSelector = true,
    DualEffectSelector = true,
    DualWeaponSelector = true,
    SkillSelector = true,
    SuitSelector = true,
    -- Other UI components
    Menu = true
}

-- ============================================================
-- LOGGING FUNCTION
-- ============================================================

--[[
    Log a message if logging is enabled for the component

    @param component_name - Name of the component (e.g., "DualSelector")
    @param message - The message to log
]]
function LogConfig.log(component_name, message)
    -- Check master switch
    if not LogConfig.ENABLED then
        return
    end

    -- Check component-specific setting (default to true if not specified)
    local component_enabled = LogConfig.COMPONENTS[component_name]
    if component_enabled == false then
        return
    end

    -- Get Logger from Reg
    local Reg = _G.Reg
    if not Reg then
        return
    end

    local Logger = Reg.get("Logger")
    if Logger and Logger.log then
        Logger.log("[" .. component_name .. "] " .. message)
    end
end

--[[
    Check if logging is enabled for a component

    @param component_name - Name of the component
    @return boolean - true if logging is enabled
]]
function LogConfig.is_enabled(component_name)
    if not LogConfig.ENABLED then
        return false
    end

    local component_enabled = LogConfig.COMPONENTS[component_name]
    return component_enabled ~= false
end

return LogConfig
