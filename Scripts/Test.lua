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
local Logger = dofile(SCRIPTS_PATH .. "lib\\logger.lua")
Logger.log("Loading bootstrap...")
ok, err = pcall(function()
	dofile(SCRIPTS_PATH .. "lib\\bootstrap.lua")
end)
if not ok then
	Logger.log("ERROR: Failed to load bootstrap: " .. tostring(err))
	return
end
local Reg = _G.Reg
local Utils = Reg.get("Utils")

-- ============================================================
-- 2) VALIDATE ENVIRONMENT
-- ============================================================
Logger.log("Checking environment...")

local function validate_environment()
	local checks = {
		{
			name = "G exists",
			test = function()
				return G ~= nil
			end,
		},
		{
			name = "G.main_player exists",
			test = function()
				return G and G.main_player ~= nil
			end,
		},
		{
			name = "cc exists",
			test = function()
				return cc ~= nil
			end,
		},
		{
			name = "cc.Director exists",
			test = function()
				return cc and cc.Director ~= nil
			end,
		},
		{
			name = "Director instance",
			test = function()
				return cc.Director:getInstance() ~= nil
			end,
		},
		{
			name = "Running scene",
			test = function()
				return cc.Director:getInstance():getRunningScene() ~= nil
			end,
		},
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

Logger.log("Bypassing Anticheat...")
local acb = Utils.safe_dofile(SCRIPTS_PATH .. "lib\\anticheat_bypass.lua")
acb.enable()

Logger.log("Script started successfully")
Logger.log("=== SCRIPT INITIALIZATION STARTED ===")

Logger.log("Scene valid for UI creation")
local size = director:getVisibleSize()
Logger.log("Screen size: " .. size.width .. "x" .. size.height)

-- ============================================================
-- 4) REMOVE OLD MENU (if exists)
-- ============================================================
local function remove_old_menu()
	-- Try to use Menu.hide() if Menu is loaded (proper cleanup)
	if Reg and Reg.has("Menu") then
		local Menu = Reg.get("Menu")
		if Menu and Menu.hide then
			pcall(Menu.hide)
			Logger.log("Removed existing menu (via Menu.hide)")
			return
		end
	end

	-- Fallback: direct removal
	if _G.GM_MENU then
		pcall(function()
			_G.GM_MENU:removeFromParent()
		end)
		_G.GM_MENU = nil
		Logger.log("Removed existing menu (direct removal)")
	end
end

remove_old_menu()

-- ============================================================
-- 5) LOAD REFACTORED UI DEPENDENCIES
-- ============================================================
Logger.log("Loading UI module...")

-- Load and register Theme (required by all UI components)
Logger.log("Loading Theme...")
local Theme = Utils.safe_dofile(SCRIPTS_PATH .. "ui\\lib\\theme.lua", "Theme")
if Theme then
	Reg.set("Theme", Theme)
	Logger.log("✓ Theme loaded and registered")
else
	Logger.log("ERROR: Failed to load Theme")
end

-- Load and register UIUtils (required by menu and dialogs)
Logger.log("Loading UIUtils...")
local UIUtils = Utils.safe_dofile(SCRIPTS_PATH .. "ui\\lib\\ui_utils.lua", "UIUtils")
if UIUtils then
	Reg.set("UIUtils", UIUtils)
	Logger.log("✓ UIUtils loaded and registered")
else
	Logger.log("ERROR: Failed to load UIUtils")
end

-- ============================================================
-- 6) LOAD NEW MENU SYSTEM
-- ============================================================
Logger.log("Creating tab-based menu...")

local Menu = Utils.safe_dofile(SCRIPTS_PATH .. "ui\\menu.lua", "Menu")

if Menu then
	-- Register Menu in Reg for cleanup
	Reg.set("Menu", Menu)
	-- Menu.clear_log()
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

-- print(Utils.dump_value(G.datam.guise_suit_config:items()))
-- print(G.locale_manager:get_locale_text_by_tid(-3877992997924375028))
-- local events = require("hexm.client.consts.event_consts")
--print(Utils.dump_value(events, { pretty = true }))
Logger.log("=== SCRIPT INITIALIZATION COMPLETE ===")
