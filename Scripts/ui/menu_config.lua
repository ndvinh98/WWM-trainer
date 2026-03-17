-- ============================================================
-- UI_REFACTORED/MENU_CONFIG.LUA - Menu Configuration
-- ============================================================
-- Refactored configuration using controller layer for decoupling
-- All actions coordinated via MenuController
--
-- Item types:
--   toggle: On/off toggle with on_action/off_action
--   action: Single-click action (no state)
--   input: Opens modal input dialog
--   input_persistent: Opens persistent input dialog
--   cycle: Cycles through values
--   custom: Custom handler function

local MenuConfig = {}

-- ============================================================
-- DEPENDENCIES
-- ============================================================

local Reg = _G.Reg
local Logger = Reg.lib("Logger")
local Constants = Reg.lib("Constants")
local _SCRIPTS_ROOT = Constants.SCRIPTS_ROOT

local function _log(msg)
	Logger.log("[MenuConfig] " .. msg)
end

local _ok_ctrl, MenuController = pcall(dofile, _SCRIPTS_ROOT .. "\\ui\\controllers\\menu_controller.lua")
if not _ok_ctrl then
	_log("WARN: MenuController failed to load: " .. tostring(MenuController))
	MenuController = nil
end

-- ============================================================
-- STATE (for persisting settings between uses)
-- ============================================================
MenuConfig.DUMP_FORMAT = "json" -- "readable" or "json"
MenuConfig.AUTO_SPLIT = true -- Auto-split massive tables (500+ keys)
MenuConfig.SPLIT_THRESHOLD = 500 -- Key count threshold for auto-split
MenuConfig.SPLIT_VERBOSE = true -- Enable verbose logging during split
MenuConfig.SAVE_BYTECODE = true -- Save bytecodes to disk during dump (default off)

-- ============================================================
-- TAB DEFINITIONS (with controller references)
-- ============================================================
-- To add a new feature:
-- 1. Add handler in controllers/menu_controller.lua
-- 2. Add item entry below with controller reference

MenuConfig.TABS = {
	-- ========================================
	-- Tab 1: Combat
	-- ========================================
	{
		name = "Combat",
		items = {
			{
				id = "xinfa_buffs_current",
				type = "toggle",
				label = "Maximize Current Innerways",
				on_action = function()
					if MenuController then
						MenuController.handle_xinfa_buffs_current(true)
					end
				end,
				off_action = function()
					if MenuController then
						MenuController.handle_xinfa_buffs_current(false)
					end
				end,
			},
			{
				id = "god_mode",
				type = "toggle",
				label = "God Mode",
				on_action = MenuController and MenuController.handle_god_mode,
				off_action = function()
					if MenuController then
						MenuController.handle_god_mode(false)
					end
				end,
			},
			{
				id = "inf_stamina",
				type = "toggle",
				label = "Inf Stamina",
				on_action = function()
					if MenuController then
						MenuController.handle_infinite_stamina(true)
					end
				end,
				off_action = function()
					if MenuController then
						MenuController.handle_infinite_stamina(false)
					end
				end,
			},
			{
				id = "invisible",
				type = "toggle",
				label = "Invisible",
				on_action = function()
					if MenuController then
						MenuController.handle_invisible(true)
					end
				end,
				off_action = function()
					if MenuController then
						MenuController.handle_invisible(false)
					end
				end,
			},
			{
				id = "one_hit",
				type = "toggle",
				label = "One Hit Kill",
				on_action = function()
					if MenuController then
						MenuController.handle_one_hit(true)
					end
				end,
				off_action = function()
					if MenuController then
						MenuController.handle_one_hit(false)
					end
				end,
			},
			{
				id = "auto_parry",
				type = "toggle",
				label = "Auto Parry",
				on_action = function()
					if MenuController then
						MenuController.handle_auto_parry(true)
					end
				end,
				off_action = function()
					if MenuController then
						MenuController.handle_auto_parry(false)
					end
				end,
			},
			{
				id = "recover",
				type = "action",
				label = "Recover",
				action = MenuController and MenuController.handle_recover,
			},
		},
	},
	-- ========================================
	-- Tab 2: World
	-- ========================================
	{
		name = "World",
		items = {
			{
				id = "auto_loot",
				type = "toggle",
				label = "Auto Loot",
				on_action = function()
					if MenuController then
						MenuController.handle_auto_loot(true)
					end
				end,
				off_action = function()
					if MenuController then
						MenuController.handle_auto_loot(false)
					end
				end,
			},
			{
				id = "speed",
				type = "cycle",
				label = "Speed",
				values = { 1.0, 1.5, 5.0, 20.0 },
				labels = { "Speed: OFF", "Speed: 1.5x", "Speed: 5x", "Speed: 20x" },
				action = MenuController and MenuController.handle_speed,
			},
			{
				id = "kill_npc",
				type = "action",
				label = "Kill NPC",
				action = MenuController and MenuController.handle_kill_npc,
			},
			{
				id = "reset_crime",
				type = "action",
				label = "Reset Crime",
				action = MenuController and MenuController.handle_reset_crime,
			},
		},
	},
	-- ========================================
	-- Tab 3: Skin
	-- ========================================
	{
		name = "Skin",
		items = {
			{
				id = "skin_changer",
				type = "action",
				label = "Suit Changer",
				action = MenuController and MenuController.handle_suit_changer,
			},
			{
				id = "weapon_skin_changer",
				type = "action",
				label = "Dual Weapon Skin Changer",
				action = MenuController and MenuController.handle_dual_weapon_skin,
			},
			{
				id = "dual_effect_changer",
				type = "action",
				label = "Dual Effect Changer",
				action = MenuController and MenuController.handle_dual_effect,
			},
			{
				id = "bow_skin_changer",
				type = "action",
				label = "Bow Skin Changer",
				action = MenuController and MenuController.handle_bow_skin,
			},
		},
	},
	-- ========================================
	-- Tab 4: Buffs
	-- ========================================
	{
		name = "Buffs",
		items = {
			{
				id = "pve",
				type = "action",
				label = "PVE Combat",
				action = function()
					if MenuController then
						MenuController.handle_buff_preset("combat")
					end
				end,
			},
			{
				id = "gathering",
				type = "action",
				label = "Gathering",
				action = function()
					if MenuController then
						MenuController.handle_buff_preset("hunting")
					end
				end,
			},
			{
				id = "fishing",
				type = "action",
				label = "Fishing",
				action = function()
					if MenuController then
						MenuController.handle_buff_preset("fishing")
					end
				end,
			},
			{
				id = "crafting",
				type = "action",
				label = "Crafting",
				action = function()
					if MenuController then
						MenuController.handle_buff_preset("crafting")
					end
				end,
			},
			-- {
			--     id = "xinfa_buffs",
			--     type = "action",
			--     label = "Browse All Xinfa",
			--     action = MenuController and MenuController.handle_xinfa_buffs
			-- },
			-- {
			--     id = "xinfa_buffs_clear",
			--     type = "action",
			--     label = "Clear Xinfa Buffs",
			--     action = MenuController and MenuController.handle_xinfa_buffs_clear
			-- }
		},
	},
	-- ========================================
	-- Tab 5: Debug
	-- ========================================
	{
		name = "Debug",
		items = {
			{
				id = "trace",
				type = "toggle",
				label = "Trace Call",
				on_action = function()
					if MenuController then
						MenuController.handle_trace_call(true)
					end
				end,
				off_action = function()
					if MenuController then
						MenuController.handle_trace_call(false)
					end
				end,
			},
			{
				id = "spy",
				type = "input_persistent",
				label = "Spy Function",
				placeholder = "source, func_name OR func_name",
				default_value = "hexm/client/net/network.lua:Network, call_server_with_token",
				button_label = "Start",
				blocking = false,
				action = MenuController and MenuController.handle_spy_function,
				on_close = MenuController and MenuController.handle_spy_close,
			},
			{
				id = "search_module",
				type = "input",
				label = "Search Specific Module",
				placeholder = "hexm.client.debug.hex.gm_init",
				default_value = "gm_init",
				action = MenuController and MenuController.handle_search_module,
			},
			{
				id = "dump_all_bytecodes",
				type = "toggle",
				label = "Dump All Bytecodes",
				on_action = MenuController and MenuController.handle_dump_all_bytecodes,
				off_action = function(btn)
					if MenuController then
						MenuController.handle_dump_all_bytecodes(false, btn)
					end
				end,
			},
			{
				id = "sync_observer",
				type = "toggle",
				label = "Sync Observer",
				on_action = function()
					if MenuController then
						MenuController.handle_sync_observer(true)
					end
				end,
				off_action = function()
					if MenuController then
						MenuController.handle_sync_observer(false)
					end
				end,
			},
			{
				id = "dump_grey_table",
				type = "action",
				label = "Dump Grey Table",
				action = MenuController and MenuController.handle_dump_grey_table,
			},
			{
				id = "dump_dir_object_cache",
				type = "action",
				label = "Dump DirObject Cache",
				action = MenuController and MenuController.handle_dump_dir_object_cache,
			},
			{
				id = "dump_dir_object_weak_cache",
				type = "action",
				label = "Dump DirObject WeakCache",
				action = MenuController and MenuController.handle_dump_dir_object_weak_cache,
			},
			{
				id = "regenerate_suit_data",
				type = "action",
				label = "Reload Suit Data",
				action = MenuController and MenuController.handle_regenerate_suit_data,
			},
		},
	},
}

return MenuConfig
