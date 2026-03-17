-- ============================================================
-- UI_REFACTORED/CONTROLLERS/MENU_CONTROLLER.LUA - Menu Action Coordination
-- ============================================================
-- Controller layer that decouples UI from Actions module
-- Handles complex workflows and action coordination
-- Prerequisites: Bootstrap must be loaded first

local MenuController = {}

-- Reference libs via Reg
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Utils = Reg.get("Utils")

local function _log(msg)
	if Logger then
		Logger.log("[MenuController] " .. msg)
	end
end

-- Load action modules (lazy-loaded on demand)
local _actions = {}

local function get_action(name)
	if not _actions[name] then
		local path = Constants.SCRIPTS_ROOT .. "\\actions\\" .. name .. ".lua"
		_actions[name] = Utils.safe_dofile(path, name:gsub("^%l", string.upper))
	end
	return _actions[name]
end

-- Load UI components (lazy-loaded)
local _ui_components = {}

local function get_ui_component(name)
	if not _ui_components[name] then
		local path = Constants.SCRIPTS_ROOT .. "\\ui\\components\\" .. name .. ".lua"
		_ui_components[name] = Utils.safe_dofile(path, name:gsub("^%l", string.upper):gsub("_(%l)", string.upper))
	end
	return _ui_components[name]
end

-- ============================================================
-- COMBAT TAB HANDLERS
-- ============================================================

function MenuController.handle_god_mode(enabled)
	local Combat = get_action("combat")
	if not Combat then
		_log("ERROR: Combat module not loaded")
		return
	end

	if enabled then
		Combat.enable_god_mode()
		_log("God Mode enabled")
	else
		Combat.disable_god_mode()
		_log("God Mode disabled")
	end
end

function MenuController.handle_no_cooldown(enabled)
	local Combat = get_action("combat")
	if not Combat then
		return
	end

	if enabled then
		Combat.enable_no_cooldown()
	else
		Combat.disable_no_cooldown()
	end
end

function MenuController.handle_invisible(enabled)
	local Combat = get_action("combat")
	if not Combat then
		return
	end

	if enabled then
		Combat.enable_invisible()
	else
		Combat.disable_invisible()
	end
end

function MenuController.handle_one_hit(enabled)
	local Combat = get_action("combat")
	if not Combat then
		return
	end

	if enabled then
		Combat.enable_one_hit()
	else
		Combat.disable_one_hit()
	end
end

function MenuController.handle_infinite_stamina(enabled)
	local Combat = get_action("combat")
	if not Combat then
		return
	end

	if enabled then
		Combat.enable_infinite_stamina()
	else
		Combat.disable_infinite_stamina()
	end
end

function MenuController.handle_auto_parry(enabled)
	local Parry = get_action("parry")
	if not Parry then
		return
	end

	if enabled then
		Parry.enable()
	else
		Parry.disable()
	end
end

function MenuController.handle_auto_combo(enabled)
	local AutoCombo = get_action("auto_combo")
	if not AutoCombo then
		return
	end

	if enabled then
		AutoCombo.enable()
	else
		AutoCombo.disable()
	end
end

function MenuController.handle_recover()
	local Combat = get_action("combat")
	if Combat and Combat.recover then
		Combat.recover()
	end
end

-- ============================================================
-- WORLD TAB HANDLERS
-- ============================================================

function MenuController.handle_npc_dumb(enabled)
	local World = get_action("world")
	if not World then
		return
	end

	if enabled then
		World.enable_npc_dumb()
	else
		World.disable_npc_dumb()
	end
end

function MenuController.handle_auto_loot(enabled)
	local AutoLoot = get_action("autoloot")
	if not AutoLoot then
		return
	end

	if enabled then
		AutoLoot.enable()
	else
		AutoLoot.disable()
	end
end

function MenuController.handle_auto_loot_v2(enabled)
	local AutoLootV2 = get_action("autoloot_v2")
	if not AutoLootV2 then
		return
	end

	if enabled then
		AutoLootV2.enable()
	else
		AutoLootV2.disable()
	end
end

function MenuController.handle_auto_oddity(enabled)
	local Oddity = get_action("oddity")
	if not Oddity then
		return
	end

	if enabled then
		Oddity.enable()
	else
		Oddity.disable()
	end
end

function MenuController.handle_speed(value)
	local World = get_action("world")
	if World and World.set_speed then
		World.set_speed(value)
	end
end

function MenuController.handle_kill_npc()
	local World = get_action("world")
	if World and World.kill_npc then
		World.kill_npc()
	end
end

function MenuController.handle_reset_crime()
	local World = get_action("world")
	if World and World.reset_crime then
		World.reset_crime()
	end
end

-- ============================================================
-- SKIN TAB HANDLERS
-- ============================================================

function MenuController.handle_suit_changer()
	local SuitSkins = get_action("suit_skins")
	local SuitSelector = get_ui_component("suit_selector")

	if not SuitSelector then
		_log("ERROR: SuitSelector not loaded")
		return
	end

	-- Disable old skin if active
	if SuitSkins then
		_log("Disabling old suit skin (if any)")
		local ok, err = pcall(function()
			SuitSkins.disable()
		end)
		if not ok then
			_log("ERROR: Could not disable old suit skin: " .. tostring(err))
		end
	end

	-- Show selector
	SuitSelector.show({
		on_select = function(suit, success, data_module)
			if success and data_module then
				-- Enable persistent mode for selected suit
				data_module.enable(suit.suit_no)
				_log("Applied suit (persistent): " .. (suit.name or suit.suit_no))
			end
		end,
	})
end

function MenuController.handle_dual_weapon_skin()
	local WeaponSkins = get_action("weapon_skins")
	local DualWeaponSelector = get_ui_component("dual_weapon_selector")

	if not DualWeaponSelector then
		_log("ERROR: DualWeaponSelector not loaded")
		return
	end
	WeaponSkins.disable()
	DualWeaponSelector.show()
end

function MenuController.handle_dual_effect()
	local Effects = get_action("effects")
	local DualEffectSelector = get_ui_component("dual_effect_selector")

	if not DualEffectSelector then
		_log("ERROR: DualEffectSelector not loaded")
		return
	end

	-- Disable old effects if active
	if Effects then
		Effects.disable()
	end

	DualEffectSelector.show()
end

function MenuController.handle_bow_skin()
	local WeaponSkins = get_action("weapon_skins")
	local BowSelector = get_ui_component("bow_selector")

	if not BowSelector then
		_log("ERROR: BowSelector not loaded")
		return
	end

	-- Disable old weapon skin if active
	if WeaponSkins then
		_log("Disabling old weapon skin (if any)")
		pcall(function()
			WeaponSkins.disable()
		end)
	end

	BowSelector.show({
		on_select = function(bow, success, data_module)
			if success and data_module then
				-- ALWAYS disable first to allow switching between weapons
				_log("Disabling current weapon skin to allow switching...")
				pcall(function()
					data_module.disable()
				end)

				-- Then enable the new one
				data_module.enable(bow.item_no or bow.id)
				_log("Applied bow skin: " .. (bow.name or bow.item_no))
			end
		end,
	})
end

-- ============================================================
-- BUFFS TAB HANDLERS
-- ============================================================

function MenuController.handle_buff_preset(preset_name)
	local Buffs = get_action("buffs")
	if Buffs and Buffs.apply_preset then
		Buffs.apply_preset(preset_name)
	end
end

function MenuController.handle_xinfa_buffs()
	local XinfaBuffs = get_action("xinfa_buffs")
	local XinfaSelector = get_ui_component("xinfa_selector")

	if not XinfaSelector then
		_log("ERROR: XinfaSelector not loaded")
		return
	end

	-- Remove previously applied xinfa buffs
	if XinfaBuffs and XinfaBuffs.is_applied() then
		XinfaBuffs.remove_applied()
	end

	XinfaSelector.show({
		on_select = function(xinfa, success, data_module)
			if success then
				_log("Applied xinfa buffs: " .. (xinfa.name or xinfa.xinfa_id))
			end
		end,
	})
end

function MenuController.handle_xinfa_buffs_current(enabled)
	local XinfaBuffs = get_action("xinfa_buffs")
	if not XinfaBuffs then
		_log("ERROR: XinfaBuffs not loaded")
		return
	end

	if enabled then
		local ok, applied, total = XinfaBuffs.apply_current()
		if ok then
			_log(string.format("Applied current equipped xinfa buffs: %d/%d", applied or 0, total or 0))
		else
			_log("Failed to apply current xinfa buffs: " .. tostring(applied))
		end
	else
		XinfaBuffs.remove_applied()
		_log("Cleared xinfa buffs")
	end
end

function MenuController.handle_xinfa_buffs_clear()
	local XinfaBuffs = get_action("xinfa_buffs")
	if XinfaBuffs and XinfaBuffs.is_applied() then
		XinfaBuffs.remove_applied()
		_log("Cleared xinfa buffs")
	else
		_log("No xinfa buffs to clear")
	end
end

-- ============================================================
-- DEBUG TAB HANDLERS
-- ============================================================

function MenuController.handle_anticheat_bypass(enabled, btn)
	local AntiCheatBypass = get_action("anticheat_bypass")
	if not AntiCheatBypass then
		return
	end

	if enabled then
		AntiCheatBypass.enable()

		-- Update button label with stats (if available)
		if btn and AntiCheatBypass.get_stats then
			local stats = AntiCheatBypass.get_stats()
			if stats and stats.stats then
				pcall(function()
					btn:setTitleText(string.format("● AntiCheat: ON [%d RPC]", stats.stats.rpc_calls or 0))
				end)
			end
		end
	else
		AntiCheatBypass.disable()
	end
end

function MenuController.handle_trace_call(enabled)
	local Trace = get_action("trace")
	if not Trace then
		return
	end

	if enabled then
		Trace.start()
	else
		Trace.stop()
	end
end

function MenuController.handle_spy_function(input, status_cb)
	local Spy = get_action("spy")
	if not Spy then
		return
	end

	-- Parse input: "source, func" or just "func"
	local source, func_name = "", ""
	local comma_pos = input:find(",")
	if comma_pos then
		source = input:sub(1, comma_pos - 1):match("^%s*(.-)%s*$")
		func_name = input:sub(comma_pos + 1):match("^%s*(.-)%s*$")
	else
		func_name = input:match("^%s*(.-)%s*$")
	end

	_log("Starting Spy on " .. (source ~= "" and (source .. ", ") or "") .. func_name)
	Spy.set_target(source, func_name)
	Spy.start()

	if status_cb then
		status_cb("Hooking: " .. (func_name or "all"))
	end
end

function MenuController.handle_spy_close()
	local Spy = get_action("spy")
	if Spy then
		Spy.stop()
	end
end

function MenuController.handle_gm_panel(enabled)
	local GMPanel = get_action("gm_panel")
	if not GMPanel then
		return
	end

	if enabled then
		GMPanel.open()
	else
		GMPanel.close()
	end
end

function MenuController.handle_save_bytecode(enabled)
	local MenuConfig = Reg.get("MenuConfig")
	if MenuConfig then
		MenuConfig.SAVE_BYTECODE = enabled and true or false
		_log("Save Bytecode: " .. (MenuConfig.SAVE_BYTECODE and "ON" or "OFF"))
	end
end

function MenuController.handle_search_module(path)
	local Dump = get_action("dump")
	if Dump and Dump.find_related then
		Dump.find_related(path, 9999)
	end
end

function MenuController.handle_dump_module(path)
	local Dump = get_action("dump")
	if not Dump or not Dump.dump_module then
		_log("ERROR: Dump module not loaded")
		return
	end

	local MenuConfig = Reg.get("MenuConfig")
	local format = (MenuConfig and MenuConfig.DUMP_FORMAT) or "json"
	Dump.dump_module(path, { format = format })
end

function MenuController.handle_dump_by_path(path_prefix)
	local Dump = get_action("dump")
	if not Dump or not Dump.dump_by_prefix then
		_log("ERROR: Dump module not loaded")
		return
	end

	local MenuConfig = Reg.get("MenuConfig")
	local format = (MenuConfig and MenuConfig.DUMP_FORMAT) or "json"
	Dump.dump_by_prefix(path_prefix, { format = format })
end

function MenuController.handle_dump_all_async(enabled, btn)
	local Dump = get_action("dump")
	if not Dump then
		return
	end

	if enabled then
		if not Dump.dump_all_async then
			_log("ERROR: Async dump not available")
			return
		end

		local MenuConfig = Reg.get("MenuConfig")
		local format = (MenuConfig and MenuConfig.DUMP_FORMAT) or "json"

		local save_bytecode = (MenuConfig and MenuConfig.SAVE_BYTECODE) or false

		Dump.dump_all_async({
			format = format,
			save_bytecode = save_bytecode,
			batch_size = 3,
			delay_ms = 50,
			on_progress = function(current, total, name)
				-- Update button label with progress
				if btn and btn.setTitleText then
					pcall(function()
						btn:setTitleText(string.format("● Dump Async: %d/%d", current, total))
					end)
				end
			end,
			on_complete = function(count, errors)
				-- Reset button label when done
				if btn and btn.setTitleText then
					pcall(function()
						btn:setTitleText("○ Dump All (Async)")
					end)
				end
				_log(string.format("Async complete: %d dumped, %d errors", count, errors))
			end,
		})
	else
		if Dump.stop_async_dump then
			Dump.stop_async_dump()
			-- Reset button label
			if btn and btn.setTitleText then
				pcall(function()
					btn:setTitleText("○ Dump All (Async)")
				end)
			end
			_log("Async dump stopped")
		end
	end
end

function MenuController.handle_dump_all_bytecodes(enabled, btn)
	local Dump = get_action("dump")
	if not Dump then
		return
	end

	if enabled then
		if not Dump.dump_all_bytecodes_async then
			_log("ERROR: Bytecode dump not available")
			return
		end

		Dump.dump_all_bytecodes_async({
			batch_size = 5,
			delay_ms = 50,
			on_progress = function(current, total, name)
				if btn and btn.setTitleText then
					pcall(function()
						btn:setTitleText(string.format("● Dump BC: %d/%d", current, total))
					end)
				end
			end,
			on_complete = function(count, errors)
				if btn and btn.setTitleText then
					pcall(function()
						btn:setTitleText("○ Dump All Bytecodes")
					end)
				end
				_log(string.format("Bytecode dump complete: %d dumped, %d errors", count, errors))
			end,
		})
	else
		if Dump.stop_bytecode_dump then
			Dump.stop_bytecode_dump()
			if btn and btn.setTitleText then
				pcall(function()
					btn:setTitleText("○ Dump All Bytecodes")
				end)
			end
			_log("Bytecode dump stopped")
		end
	end
end

function MenuController.handle_dump_grey_table()
	local Dump = get_action("dump")
	if Dump and Dump.dump_grey_table then
		Dump.dump_grey_table()
	end
end

function MenuController.handle_dump_dir_object_cache()
	local Dump = get_action("dump")
	if Dump and Dump.dump_dir_object_cache then
		Dump.dump_dir_object_cache()
	end
end

function MenuController.handle_dump_dir_object_weak_cache()
	local Dump = get_action("dump")
	if Dump and Dump.dump_dir_object_weak_cache then
		Dump.dump_dir_object_weak_cache()
	end
end

function MenuController.handle_regenerate_suit_data()
	local SuitSkins = get_action("suit_skins")
	if SuitSkins and SuitSkins.load_suit_data then
		local data, suit_list = SuitSkins.load_suit_data()
		if data then
			_log("Loaded suit data: " .. (suit_list and #suit_list or 0) .. " suits")
		else
			_log("Error: Failed to load suit data")
		end
	end
end

function MenuController.handle_sync_observer(enabled)
	local SyncObserver = get_action("sync_observer")
	if not SyncObserver then
		_log("SyncObserver module not found")
		return
	end
	if enabled then
		local ok, err = SyncObserver.enable()
		if ok then
			_log("Sync Observer enabled")
		else
			_log("Sync Observer error: " .. tostring(err))
		end
	else
		SyncObserver.disable()
		_log("Sync Observer disabled")
	end
end

return MenuController
