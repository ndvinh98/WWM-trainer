-- ============================================================
-- MAIN.LUA - Entry Point (uses modular menu system)
-- ============================================================
-- This is the main script that loads all modules and initializes
-- the config-driven debug menu.
--
-- Structure:
--   lib/bootstrap.lua  - Core (Constants, Logger, HookManager, etc.)
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
local ok, err = pcall(function()
	dofile(SCRIPTS_PATH .. "lib\\bootstrap.lua")
end)
if not ok then
	Logger.log("ERROR: Failed to load bootstrap: " .. tostring(err))
	return
end
local Reg = _G.Reg
Logger = Reg.lib("Logger")

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

-- ============================================================
-- 3) BYPASS ANTICHEAT
-- ============================================================
Logger.log("Bypassing Anticheat...")

local ok, err = pcall(function()
	local acb = dofile(SCRIPTS_PATH .. "lib\\anticheat_bypass.lua")
	acb.enable()
end)

if not ok then
	Logger.log("ERROR: Failed to bypass Anticheat: " .. tostring(err))
	return
end

Logger.log("Script started successfully")
Logger.log("=== SCRIPT INITIALIZATION STARTED ===")

Logger.log("Scene valid for UI creation")
local size = director:getVisibleSize()
Logger.log("Screen size: " .. size.width .. "x" .. size.height)

-- ============================================================
-- 4) REMOVE OLD MENU (if exists)
-- ============================================================
local function remove_old_menu()
	local MENU_STATE = Reg.state("ui.menu")
	if MENU_STATE and MENU_STATE.api and MENU_STATE.api.hide then
		pcall(MENU_STATE.api.hide)
		Logger.log("Removed existing menu (via Menu.hide)")
		return
	end
end

remove_old_menu()

-- ============================================================
-- 5) LOAD AND SHOW MENU
-- ============================================================
Logger.log("Loading menu system...")

local ok_theme, Theme = pcall(dofile, SCRIPTS_PATH .. "ui\\lib\\theme.lua")
if ok_theme and Theme then
	Reg.set_lib("Theme", Theme)
	Logger.log("Theme loaded")
else
	Logger.log("ERROR: Failed to load Theme")
end

local ok_ui, UIUtils = pcall(dofile, SCRIPTS_PATH .. "ui\\lib\\ui_utils.lua")
if ok_ui and UIUtils then
	Reg.set_lib("UIUtils", UIUtils)
	Logger.log("UIUtils loaded")
else
	Logger.log("ERROR: Failed to load UIUtils")
end

local ok_menu, Menu = pcall(dofile, SCRIPTS_PATH .. "ui\\menu.lua")

if ok_menu and Menu then
	Menu.show(scene)
	Logger.log("=== UI INITIALIZATION COMPLETE ===")
else
	Logger.log("ERROR: Failed to load Menu module: " .. tostring(Menu))
end

Logger.log("=== SCRIPT INITIALIZATION COMPLETE ===")
