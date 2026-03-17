-- ============================================================
-- MAIN.LUA - New Entry Point (uses modular menu system)
-- ============================================================
-- This is the main script that loads all modules and initializes
-- the new config-driven debug menu.
--
-- Structure:
--   lib/bootstrap.lua  - Core utilities (Constants, Logger, Utils)
--   ui/menu.lua        - Config-driven tab menu UI
--   ui/menu_config.lua - All tabs, items, and action wiring
--   actions/*.lua      - All gameplay functionality
--
-- To extend:
--   1. Add new actions to actions/*.lua
--   2. Add new tabs/items to ui/menu_config.lua
-- ============================================================

local SCRIPTS_PATH = "C:\\temp\\Where Winds Meet\\Scripts\\"

-- ============================================================
-- 1) LOAD BOOTSTRAP (Foundation)
-- ============================================================
dofile(SCRIPTS_PATH .. "lib\\bootstrap.lua")

local Constants = _G.KURO_Constants
local Logger = _G.KURO_Logger
local Utils = _G.KURO_Utils

Logger.log("Script started successfully")
Logger.log("=== SCRIPT INITIALIZATION STARTED ===")

-- ============================================================
-- 2) VALIDATE ENVIRONMENT
-- ============================================================
Logger.log("Checking environment...")

local function validate_environment()
    local checks = {
        {name = "G exists", test = function()
                return G ~= nil
            end},
        {name = "G.main_player exists", test = function()
                return G and G.main_player ~= nil
            end},
        {name = "cc exists", test = function()
                return cc ~= nil
            end},
        {name = "cc.Director exists", test = function()
                return cc and cc.Director ~= nil
            end},
        {name = "Director instance", test = function()
                return cc.Director:getInstance() ~= nil
            end},
        {name = "Running scene", test = function()
                return cc.Director:getInstance():getRunningScene() ~= nil
            end}
    }

    for _, check in ipairs(checks) do
        local ok, result = pcall(check.test)
        local passed = ok and result
        Logger.log(check.name .. ": " .. tostring(passed))
        if not passed then
            return false, nil, nil
        end
    end

    local director = cc.Director:getInstance()
    local scene = director:getRunningScene()
    return true, director, scene
end

local valid, director, scene = validate_environment()
if not valid then
    Logger.log("ERROR: Environment validation failed")
    return
end

Logger.log("Scene valid for UI creation")
local size = director:getVisibleSize()
Logger.log("Screen size: " .. size.width .. "x" .. size.height)

-- ============================================================
-- 3) APPLY DEBUG FLAGS
-- ============================================================
Logger.log("Applying debug flags...")

local DEBUG_FLAGS = {
    {path = "hexm.client.game_setup.G", key = "GM_IS_OPEN_GUIDE", value = false},
    {path = "hexm.client.game_setup.G", key = "ENABLE_DEBUG_PRINT", value = false},
    {path = "hexm.client.game_setup.G", key = "DISABLE_ACSDK", value = true},
    {path = "hexm.client.game_setup.G", key = "DEBUG", value = false},
    {path = "hexm.client.game_setup.G", key = "FORCE_OPEN_DEBUG_SHORTCUT", value = false},
    {path = "patch.sa_log_comp.base_log", key = "acsdk_info_has_inited", value = false},
    {path = "_G.DebugMenu.Core.FLAGS_TO_SET", key = "acsdk_info_has_inited", value = false},
    {path = "_G.DebugMenu.Core.FLAGS_TO_SET", key = "GM_USE_PUBLISH", value = false},
    {path = "_G.DebugMenu.Core.FLAGS_TO_SET", key = "DEBUG", value = false},
    {path = "_G.DebugMenu.Core.FLAGS_TO_SET", key = "ENABLE_DEBUG_PRINT", value = false},
    {path = "_G.DebugMenu.Core.FLAGS_TO_SET", key = "GM_IS_OPEN_GUIDE", value = false},
    {path = "_G.DebugMenu.Core.FLAGS_TO_SET", key = "FORCE_OPEN_DEBUG_SHORTCUT", value = false},
    {path = "_G.DebugMenu.Core.FLAGS_TO_SET", key = "ENABLE_FORCE_SHOW_GM", value = false},
    {path = "_G.DebugMenu.Core.FLAGS_TO_SET", key = "DISABLE_ACSDK", value = true},
    {path = "mobilelog.LogManager", key = "DEBUG", value = false}
}

local function resolve_path(path)
    local parts = {}
    for part in path:gmatch("[^%.]+") do
        parts[#parts + 1] = part
    end

    local current = _G
    for i, part in ipairs(parts) do
        if part == "_G" then
            current = _G
        elseif current and type(current) == "table" then
            current = current[part]
        else
            return nil
        end
    end
    return current
end

for _, flag in ipairs(DEBUG_FLAGS) do
    pcall(
        function()
            local target = resolve_path(flag.path)
            Logger.log("Checking target ..." .. tostring(target))
            if target and type(target) == "table" then
                target[flag.key] = flag.value
                Logger.log("[✔] ROOT." .. flag.path .. "." .. flag.key .. " set to " .. tostring(flag.value))
            end
        end
    )
end

-- ============================================================
-- 4) REMOVE OLD MENU (if exists)
-- ============================================================
local function remove_old_menu()
    if _G.GM_MENU then
        pcall(
            function()
                _G.GM_MENU:removeFromParent()
            end
        )
        _G.GM_MENU = nil
        Logger.log("Removed existing menu")
    end
end

remove_old_menu()

-- ============================================================
-- 5) LOAD NEW MENU SYSTEM
-- ============================================================
Logger.log("Loading UI module...")
Logger.log("Creating tab-based menu...")

local Menu = Utils.safe_dofile(SCRIPTS_PATH .. "ui\\menu.lua", "Menu")

if Menu then
    local menuPanel = Menu.create(scene)

    if menuPanel then
        _G.GM_MENU = menuPanel
        Logger.log("=== UI INITIALIZATION COMPLETE ===")
    else
        Logger.log("ERROR: Failed to create menu panel")
    end
else
    Logger.log("ERROR: Failed to load Menu module")
end

-- ============================================================
-- UTILITY FUNCTIONS (exported to _G for console use)
-- ============================================================

Logger.log("=== SCRIPT INITIALIZATION COMPLETE ===")
