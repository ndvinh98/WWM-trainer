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

-- Auto-detect Scripts path from this file's location
local function _detect_scripts_path()
	local info = debug.getinfo(1, "S")
	local src = info and info.source or ""
	if src:sub(1, 1) == "@" then
		src = src:sub(2)
	end
	src = src:gsub("/", "\\")
	-- Strip filename (e.g. \Test.lua) to get the directory
	return src:match("^(.+)\\") or "."
end
_G.SCRIPTS_PATH = _detect_scripts_path()
local SCRIPTS_PATH = _G.SCRIPTS_PATH .. "\\"

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
local director = cc.Director:getInstance()
local scene = director:getRunningScene()
-- ============================================================
-- 3) BYPASS ANTICHEAT
-- ============================================================
Logger.log("Bypassing Anticheat...")

local acb_existing = Reg.module("actions.anticheat_bypass")
if acb_existing and acb_existing:is_hooked("drpf_check_can_report") then
	Logger.log("Anticheat bypass already active, skipping reload")
else
	local ok, err = pcall(function()
		dofile(SCRIPTS_PATH .. "actions\\anticheat_bypass.lua")
		--Reg.module("actions.anticheat_bypass"):enable()
	end)

	if not ok then
		Logger.log("ERROR: Failed to bypass Anticheat: " .. tostring(err))
		return
	end
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

-- Logger.log("=== SCRIPT INITIALIZATION COMPLETE ===")
