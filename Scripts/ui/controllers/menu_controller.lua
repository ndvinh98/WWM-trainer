-- ============================================================
-- MENU_CONTROLLER.LUA - Menu Action Coordination
-- ============================================================
-- Controller layer that decouples UI from Actions module.
-- Uses Reg.module() for ActionBase modules, falls back to dofile.

local MenuController = {}

local Reg = _G.Reg
local Constants = Reg.lib("Constants")
local Logger = Reg.lib("Logger")
local Serialize = Reg.lib("Serialize")
local MENU_STATE = Reg.state("ui.menu")
local function _log(msg)
	if Logger then
		Logger.log("[MenuController] " .. msg)
	end
end

-- Load action modules: check KURO_modules first, lazy dofile if needed
local function get_action(name)
	-- local mod = Reg.module("actions." .. name)
	-- if mod then
	-- 	return mod
	-- end

	-- Lazy-load: dofile the script, which auto-registers via ActionBase:new()
	local path = Constants.SCRIPTS_ROOT .. "\\actions\\" .. name .. ".lua"
	local ok, result = pcall(dofile, path)
	if ok then
		-- Check if it registered itself
		mod = Reg.module("actions." .. name)
		if mod then
			return mod
		end
		return result -- fallback for non-ActionBase modules
	end
	_log("Failed to load action: " .. name .. " - " .. tostring(result))
	return nil
end

-- Load SelectorFactory for declarative selector UI
local _selector_factory = nil
local function get_selector_factory()
	if not _selector_factory then
		local path = Constants.SCRIPTS_ROOT .. "\\ui\\lib\\selector_factory.lua"
		local ok, result = pcall(dofile, path)
		if ok then
			_selector_factory = result
		end
	end
	return _selector_factory
end

-- ============================================================
-- COMBAT TAB HANDLERS
-- ============================================================

function MenuController.handle_god_mode(enabled)
	local Combat = get_action("combat")
	if not Combat then
		return
	end
	Combat:set_god_mode(enabled)
end

function MenuController.handle_no_cooldown(enabled)
	local Combat = get_action("combat")
	if not Combat then
		return
	end
	Combat:set_instant_charge(enabled)
	Combat:set_no_cooldown(enabled)
end

function MenuController.handle_invisible(enabled)
	local Combat = get_action("combat")
	if not Combat then
		return
	end
	Combat:set_npc_blind(enabled)
end

function MenuController.handle_one_hit(enabled)
	local Combat = get_action("combat")
	if not Combat then
		return
	end
	Combat:set_instant_charge(enabled)
end

function MenuController.handle_infinite_stamina(enabled)
	local Combat = get_action("combat")
	if not Combat then
		return
	end
	Combat:set_infinite_stamina(enabled)
end

function MenuController.handle_auto_parry(enabled)
	local Parry = get_action("parry")
	if not Parry then
		return
	end
	if enabled then
		if Parry.enable then
			Parry:enable()
		end
	else
		if Parry.disable then
			Parry:disable()
		end
	end
end

function MenuController.handle_auto_combo(enabled)
	local AutoCombo = get_action("auto_combo")
	if not AutoCombo then
		return
	end
	if enabled then
		if AutoCombo.enable then
			pcall(AutoCombo.enable, AutoCombo)
		end
	else
		if AutoCombo.disable then
			pcall(AutoCombo.disable, AutoCombo)
		end
	end
end

function MenuController.handle_recover()
	local Combat = get_action("combat")
	if Combat and Combat.recover then
		Combat:recover()
	end
end

function MenuController.handle_unrestrict_skills(enabled)
	local SkillUnrestrict = get_action("skill_unrestrict")
	if not SkillUnrestrict then
		return
	end
	SkillUnrestrict:set_unrestrict_skills(enabled)
end

-- ============================================================
-- WORLD TAB HANDLERS
-- ============================================================

function MenuController.handle_npc_dumb(enabled)
	local Combat = get_action("combat")
	if not Combat then
		return
	end
	Combat:set_npc_blind(enabled)
end

function MenuController.handle_auto_loot(enabled)
	local AutoLoot = get_action("autoloot")
	if not AutoLoot then
		return
	end
	if enabled then
		if AutoLoot.enable then
			pcall(AutoLoot.enable, AutoLoot)
		end
	else
		if AutoLoot.disable then
			pcall(AutoLoot.disable, AutoLoot)
		end
	end
end

function MenuController.handle_auto_loot_v2(enabled)
	local AutoLootV2 = get_action("autoloot_v2")
	if not AutoLootV2 then
		return
	end
	if enabled then
		if AutoLootV2.enable then
			pcall(AutoLootV2.enable, AutoLootV2)
		end
	else
		if AutoLootV2.disable then
			pcall(AutoLootV2.disable, AutoLootV2)
		end
	end
end

function MenuController.handle_auto_oddity(enabled)
	local Oddity = get_action("oddity")
	if not Oddity then
		return
	end
	if enabled then
		if Oddity.enable then
			pcall(Oddity.enable, Oddity)
		end
	else
		if Oddity.disable then
			pcall(Oddity.disable, Oddity)
		end
	end
end

function MenuController.handle_speed(value)
	local World = get_action("world")
	if World and World.set_speed then
		World:set_speed(value)
	end
end

function MenuController.handle_kill_npc()
	local World = get_action("world")
	if World and World.kill_npc then
		World:kill_npc()
	end
end

function MenuController.handle_reset_crime()
	local World = get_action("world")
	if World and World.reset_crime then
		World:reset_crime()
	end
end

function MenuController.handle_pitchpot_auto(enabled)
	local Pitchpot = get_action("pitchpot")
	if not Pitchpot then
		return
	end
	Pitchpot:set_auto_play(enabled)
end

function MenuController.handle_rhythm_auto_perfect(enabled)
	local RhythmGame = get_action("rhythm_game")
	if not RhythmGame then
		return
	end
	RhythmGame:set_auto_perfect(enabled)
end

-- ============================================================
-- SKIN TAB HANDLERS
-- ============================================================

function MenuController.handle_suit_changer()
	local SuitSkins = get_action("suit_skins")
	local SF = get_selector_factory()
	if not SF then
		_log("ERROR: SelectorFactory not loaded")
		return
	end

	if SuitSkins and SuitSkins.disable then
		pcall(SuitSkins.disable, SuitSkins)
	end

	SF.show({
		type = "single",
		action = "suit_skins",
		data_fn = "get_suit_list",
		apply_fn = "enable",
		id_fn = function(item)
			return item.suit_no
		end,
		title = "Suit Selector",
		memory_key = "SUIT_SELECTOR",
		empty_message = "No suits available",
	}, {
		on_select = function(suit, success, data_module)
			if success then
				_log("Applied suit (persistent): " .. (suit.name or suit.suit_no))
			else
				_log("Failed to apply suit: " .. suit)
			end
		end,
	})
end

function MenuController.handle_dual_weapon_skin()
	local WeaponSkins = get_action("weapon_skins")
	local SF = get_selector_factory()
	if not SF or not WeaponSkins then
		_log("ERROR: SelectorFactory or WeaponSkins not loaded")
		return
	end
	if WeaponSkins.disable then
		pcall(WeaponSkins.disable, WeaponSkins)
	end
	SF.show({
		type = "dual",
		action = "weapon_skins",
		left = { data_fn = "get_primary_weapon_list", title = "Main Weapon Skins", display_fn = "get_display_name" },
		right = {
			data_fn = "get_secondary_weapon_list",
			title = "Secondary Weapon Skins",
			display_fn = "get_display_name",
		},
		apply_fn = "apply_dual",
		title = "Dual Weapon Skin Selector",
		memory_key = "DUAL_WEAPON_SELECTOR",
	})
end

function MenuController.handle_dual_effect()
	local Effects = get_action("effects")
	local SF = get_selector_factory()
	if not SF then
		_log("ERROR: SelectorFactory not loaded")
		return
	end

	if Effects and Effects.disable then
		pcall(Effects.disable, Effects)
	end

	SF.show({
		type = "dual",
		action = "effects",
		left = { data_fn = "get_primary_effect_list", title = "Main Weapon Effects", display_fn = "get_display_name" },
		right = {
			data_fn = "get_secondary_effect_list",
			title = "Secondary Weapon Effects",
			display_fn = "get_display_name",
		},
		apply_fn = "apply_dual_items",
		title = "Dual Effect Selector",
		memory_key = "DUAL_EFFECT_SELECTOR",
	})
end

function MenuController.handle_bow_skin()
	local WeaponSkins = get_action("weapon_skins")
	local SF = get_selector_factory()
	if not SF then
		_log("ERROR: SelectorFactory not loaded")
		return
	end

	if WeaponSkins and WeaponSkins.disable then
		pcall(WeaponSkins.disable, WeaponSkins)
	end

	SF.show({
		type = "single",
		action = "weapon_skins",
		data_fn = "get_bow_list",
		apply_fn = "apply_bow",
		id_fn = function(item)
			return item.item_no
		end,
		title = "Bow Selector",
		memory_key = "BOW_SELECTOR",
		empty_message = "No bows available",
	}, {
		on_select = function(bow, success, data_module)
			if success and data_module then
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
		Buffs:apply_preset(preset_name)
	end
end

function MenuController.handle_xinfa_buffs()
	local XinfaBuffs = get_action("xinfa_buffs")
	local SF = get_selector_factory()

	if not SF then
		_log("ERROR: SelectorFactory not loaded")
		return
	end

	if XinfaBuffs and XinfaBuffs.is_applied then
		local applied = pcall(XinfaBuffs.is_applied, XinfaBuffs)
		if applied and XinfaBuffs.remove_applied then
			pcall(XinfaBuffs.remove_applied, XinfaBuffs)
		end
	end

	SF.show({
		type = "single",
		action = "xinfa_buffs",
		data_fn = "get_xinfa_list",
		apply_fn = "apply_xinfa",
		title = "Xinfa Selector",
		memory_key = "XINFA_SELECTOR",
		empty_message = "No xinfa available",
	}, {
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
		return
	end

	if enabled then
		if XinfaBuffs.apply_current then
			local ok, applied, total = pcall(XinfaBuffs.apply_current, XinfaBuffs)
			if ok then
				_log(string.format("Applied current xinfa buffs: %s/%s", tostring(applied), tostring(total)))
			end
		end
	else
		if XinfaBuffs.remove_applied then
			pcall(XinfaBuffs.remove_applied, XinfaBuffs)
		end
		_log("Cleared xinfa buffs")
	end
end

function MenuController.handle_xinfa_buffs_clear()
	local XinfaBuffs = get_action("xinfa_buffs")
	if XinfaBuffs and XinfaBuffs.remove_applied then
		pcall(XinfaBuffs.remove_applied, XinfaBuffs)
		_log("Cleared xinfa buffs")
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
		pcall(AntiCheatBypass.enable, AntiCheatBypass)
	else
		pcall(AntiCheatBypass.disable, AntiCheatBypass)
	end
end

function MenuController.handle_trace_call(enabled)
	local Trace = get_action("trace")
	if not Trace then
		return
	end

	if enabled then
		if Trace.start_trace then
			pcall(Trace.start_trace, Trace)
		end
	else
		if Trace.stop_trace then
			pcall(Trace.stop_trace, Trace)
		end
	end
end

function MenuController.handle_spy_function(input, status_cb)
	local Spy = get_action("spy")
	if not Spy then
		return
	end

	local source, func_name = "", ""
	local comma_pos = input:find(",")
	if comma_pos then
		source = input:sub(1, comma_pos - 1):match("^%s*(.-)%s*$")
		func_name = input:sub(comma_pos + 1):match("^%s*(.-)%s*$")
	else
		func_name = input:match("^%s*(.-)%s*$")
	end

	_log("Starting Spy on " .. (source ~= "" and (source .. ", ") or "") .. func_name)
	if Spy.set_target then
		pcall(Spy.set_target, Spy, source, func_name)
	end
	if Spy.start then
		local ok, err = pcall(Spy.start, Spy)
		if not ok then
			_log("Failed to start Spy: " .. tostring(err))
		else
			_log("Spy started successfully")
		end
	end

	if status_cb then
		status_cb("Hooking: " .. (func_name or "all"))
	end
end

function MenuController.handle_spy_close()
	local Spy = get_action("spy")
	if Spy and Spy.stop then
		pcall(Spy.stop, Spy)
	end
end

function MenuController.handle_gm_panel(enabled)
	local GMPanel = get_action("gm_panel")
	if not GMPanel then
		return
	end

	if enabled then
		if GMPanel.open then
			pcall(GMPanel.open, GMPanel)
		end
	else
		if GMPanel.close then
			pcall(GMPanel.close, GMPanel)
		end
	end
end

function MenuController.handle_save_bytecode(enabled)
	local MenuConfig = MENU_STATE.config
	if MenuConfig then
		MenuConfig.SAVE_BYTECODE = enabled and true or false
		_log("Save Bytecode: " .. (MenuConfig.SAVE_BYTECODE and "ON" or "OFF"))
	end
end

function MenuController.handle_search_module(path)
	local Dump = get_action("dump")
	if Dump and Dump.find_related then
		pcall(Dump.find_related, Dump, path, 9999)
	end
end

function MenuController.handle_dump_all_bytecodes(enabled, btn)
	local Dump = get_action("dump_bytecode")
	if not Dump then
		return
	end

	if enabled then
		if not Dump.dump_all_async then
			return
		end

		pcall(Dump.dump_all_async, Dump, {
			batch_size = 5,
			delay_ms = 50,
			on_progress = function(current, total, name)
				if btn and btn.setTitleText then
					pcall(btn.setTitleText, btn, string.format("● Dump BC: %d/%d", current, total))
				end
			end,
			on_complete = function(count, errors)
				if btn and btn.setTitleText then
					pcall(btn.setTitleText, btn, "○ Dump All Bytecodes")
				end
				_log(string.format("Bytecode dump complete: %d dumped, %d errors", count, errors))
			end,
		})
	else
		if Dump.stop_dump then
			pcall(Dump.stop_dump, Dump)
			if btn and btn.setTitleText then
				pcall(btn.setTitleText, btn, "○ Dump All Bytecodes")
			end
		end
	end
end

function MenuController.handle_dump_grey_table()
	local Dump = get_action("dump_static_data")
	if Dump and Dump.dump_grey_table then
		pcall(Dump.dump_grey_table, Dump)
	end
end

function MenuController.handle_dump_dir_object_cache()
	local Dump = get_action("dump_static_data")
	if Dump and Dump.dump_dir_object_cache then
		pcall(Dump.dump_dir_object_cache, Dump)
	end
end

function MenuController.handle_dump_dir_object_weak_cache()
	local Dump = get_action("dump_static_data")
	if Dump and Dump.dump_dir_object_weak_cache then
		pcall(Dump.dump_dir_object_weak_cache, Dump)
	end
end

function MenuController.handle_regenerate_suit_data()
	local SuitSkins = get_action("suit_skins")
	if SuitSkins and SuitSkins.load_suit_data then
		pcall(SuitSkins.load_suit_data, SuitSkins)
	end
end

function MenuController.handle_sync_observer(enabled)
	local SyncObserver = get_action("sync_observer")
	if not SyncObserver then
		return
	end
	if enabled then
		if SyncObserver.enable then
			pcall(SyncObserver.enable, SyncObserver)
		end
	else
		if SyncObserver.disable then
			pcall(SyncObserver.disable, SyncObserver)
		end
	end
end

return MenuController
