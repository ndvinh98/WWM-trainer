-- ============================================================
-- WORLD.LUA - World Actions
-- ============================================================
-- Prerequisites: Bootstrap must be loaded first

local World = {}

-- Reference libs via Reg (loaded once by bootstrap)
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Utils = Reg.get("Utils")

local function _log(msg)
	Logger.log("[World] " .. msg)
end

-- Speed presets
World.SPEED_PRESETS = {
	{ speed = 1.0, label = "Speed: OFF" },
	{ speed = 1.5, label = "Speed: 1.5x" },
	{ speed = 5.0, label = "Speed: 5x" },
	{ speed = 20.0, label = "Speed: 20x" },
}

-- Cache combat action
local _combat_action = nil
local function get_action()
	if not _combat_action then
		_combat_action = Utils.safe_import("hexm.client.ui.windows.gm.gm_combat.combat_train_action")
	end
	return _combat_action
end

function World.set_speed(speed)
	local target = speed or 1.0
	local action = get_action()

	-- Try GM API
	if action and action.set_game_speed then
		Utils.safe_call("set_game_speed", action.set_game_speed, target)
		_log("Speed set via GM API: x" .. target)
		return true
	end

	-- Legacy fallbacks
	if G then
		if G.dialog_global_time_scale ~= nil then
			G.dialog_global_time_scale = target
		end
		if G.space then
			local space = G.space
			if space.dialog_global_time_scale ~= nil then
				space.dialog_global_time_scale = target
			end
			if space.dialog_set_global_time_scale then
				Utils.safe_call("set_scale", space.dialog_set_global_time_scale, space, target)
			end
		end
		local mp = Utils.get_main_player()
		if mp and mp.dialog_set_time_speed_scale then
			Utils.safe_call("player_scale", mp.dialog_set_time_speed_scale, mp, target > 1, target)
		end
	end

	_log("Speed set via legacy: x" .. target)
	return true
end

function World.kill_npc()
	_log("Kill NPC triggered")
	local count = 0
	local mp = Utils.get_main_player()
	local action = get_action()

	-- Try combat action
	if action then
		if action.set_npc_mortal then
			Utils.safe_call("mortal", action.set_npc_mortal, true)
		end
		if action.kill_all_npc then
			Utils.safe_call("kill_all", action.kill_all_npc)
		end
	end

	-- Kill locked target
	if mp then
		local target_id = Utils.safe_call("get_lock", function()
			return mp:get_lock_target_id()
		end)
		if target_id and G.space then
			local target = G.space:get_entity(target_id)
			if target then
				Utils.safe_call("damage", target.do_direct_damage, target, 999999999, mp.entity_id, 0, 0, 0, 0)
				count = count + 1
			end
		end
	end

	-- Area cleanup
	local entities = Utils.safe_call("aoi", function()
		return MEntityManager:GetAOIEntities()
	end)
	if entities and mp then
		for i = 1, #entities do
			local ent = entities[i]
			local name = Utils.safe_call("name", function()
				return ent:GetName()
			end)
			if name and (name:find("AiAvatar") or name:find("Npc") or name:find("Boss")) then
				local eid = ent.entity_id
				if eid and G.space then
					local target = G.space:get_entity(eid)
					if target and target ~= mp then
						Utils.safe_call("kill", target.do_direct_damage, target, 999999999, mp.entity_id, 0, 0, 0, 0)
						count = count + 1
					end
				end
			end
		end
	end

	_log("Killed: " .. count)
	return count
end

function World.reset_crime()
	local dec = Utils.safe_import("hexm.client.debug.gm.gm_decorator")
	if dec and dec.gm_command_short_cuts and dec.gm_command_short_cuts.game then
		local cmds = dec.gm_command_short_cuts.game
		if cmds["$forbid_witness_wanfa"] then
			Utils.safe_call("witness", cmds["$forbid_witness_wanfa"], 1)
		end
		if cmds["$forbid_police_wanfa"] then
			Utils.safe_call("police", cmds["$forbid_police_wanfa"], 1)
		end
	end
	_log("Reset crime executed")
	return true
end

function World.disable_logs()
	local count = 0

	local gm_combat = Utils.safe_import("hexm.client.debug.gm.gm_commands.gm_combat")
	if gm_combat then
		if gm_combat.gm_forbid_behit_highlight then
			Utils.safe_call("highlight", gm_combat.gm_forbid_behit_highlight, 1)
			count = count + 1
		end
		if gm_combat.gm_enable_stopframe_debug then
			Utils.safe_call("stopframe", gm_combat.gm_enable_stopframe_debug, 0)
			count = count + 1
		end
	end

	local gm_cutscene = Utils.safe_import("hexm.client.debug.gm.gm_commands.gm_cutscene")
	if gm_cutscene then
		if gm_cutscene.gm_cutscene_clear_log then
			Utils.safe_call("clear", gm_cutscene.gm_cutscene_clear_log)
			count = count + 1
		end
	end

	_log("Logging disabled (" .. count .. " items)")
	return true
end

return World
