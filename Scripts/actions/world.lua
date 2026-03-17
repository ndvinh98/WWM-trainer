-- Scripts/actions/world.lua
local ActionBase = _G.Reg.lib("ActionBase")

local World = ActionBase:extend("actions.world")

-- ── Constants ──
local SPEED_PRESETS = {
	{ speed = 1.0, label = "Speed: OFF" },
	{ speed = 1.5, label = "Speed: 1.5x" },
	{ speed = 5.0, label = "Speed: 5x" },
	{ speed = 20.0, label = "Speed: 20x" },
}

function World:define_state()
	return {
		persistent = { current_speed = 1.0 },
		transient = {},
	}
end

function World:define_hooks()
	return {}
end

-- ── Helpers ──

function World:_get_combat_action()
	local ok, mod = pcall(portable.safe_import, "hexm.client.ui.windows.gm.gm_combat.combat_train_action")
	if ok and mod then
		return mod
	end
	return nil
end

-- ── Public API ──

function World:set_speed(speed)
	local target = speed or 1.0
	local action = self:_get_combat_action()

	if action and action.set_game_speed then
		pcall(action.set_game_speed, target)
		self:log("Speed set via GM API: x" .. target)
		self.state.current_speed = target
		return true
	end

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
				pcall(space.dialog_set_global_time_scale, space, target)
			end
		end
		local mp = G.main_player
		if mp and mp.dialog_set_time_speed_scale then
			pcall(mp.dialog_set_time_speed_scale, mp, target > 1, target)
		end
	end

	self.state.current_speed = target
	self:log("Speed set via legacy: x" .. target)
	return true
end

function World:kill_npc()
	self:log("Kill NPC triggered")
	local count = 0
	local mp = G.main_player
	local action = self:_get_combat_action()

	if action then
		if action.set_npc_mortal then
			pcall(action.set_npc_mortal, true)
		end
		if action.kill_all_npc then
			pcall(action.kill_all_npc)
		end
	end

	if mp then
		local ok, target_id = pcall(function()
			return mp:get_lock_target_id()
		end)
		if ok and target_id and G.space then
			local target = G.space:get_entity(target_id)
			if target then
				pcall(target.do_direct_damage, target, 999999999, mp.entity_id, 0, 0, 0, 0)
				count = count + 1
			end
		end
	end

	local ok, entities = pcall(function()
		return MEntityManager:GetAOIEntities()
	end)
	if ok and entities and mp then
		for i = 1, #entities do
			local ent = entities[i]
			local ok_n, name = pcall(function()
				return ent:GetName()
			end)
			if ok_n and name and (name:find("AiAvatar") or name:find("Npc") or name:find("Boss")) then
				local eid = ent.entity_id
				if eid and G.space then
					local target = G.space:get_entity(eid)
					if target and target ~= mp then
						pcall(target.do_direct_damage, target, 999999999, mp.entity_id, 0, 0, 0, 0)
						count = count + 1
					end
				end
			end
		end
	end

	self:log("Killed: " .. count)
	return count
end

function World:reset_crime()
	local ok, dec = pcall(portable.safe_import, "hexm.client.debug.gm.gm_decorator")
	if ok and dec and dec.gm_command_short_cuts and dec.gm_command_short_cuts.game then
		local cmds = dec.gm_command_short_cuts.game
		if cmds["$forbid_witness_wanfa"] then
			pcall(cmds["$forbid_witness_wanfa"], 1)
		end
		if cmds["$forbid_police_wanfa"] then
			pcall(cmds["$forbid_police_wanfa"], 1)
		end
	end
	self:log("Reset crime executed")
	return true
end

function World:disable_logs()
	local count = 0
	local ok, gm_combat = pcall(portable.safe_import, "hexm.client.debug.gm.gm_commands.gm_combat")
	if ok and gm_combat then
		if gm_combat.gm_forbid_behit_highlight then
			pcall(gm_combat.gm_forbid_behit_highlight, 1)
			count = count + 1
		end
		if gm_combat.gm_enable_stopframe_debug then
			pcall(gm_combat.gm_enable_stopframe_debug, 0)
			count = count + 1
		end
	end

	local ok2, gm_cutscene = pcall(portable.safe_import, "hexm.client.debug.gm.gm_commands.gm_cutscene")
	if ok2 and gm_cutscene and gm_cutscene.gm_cutscene_clear_log then
		pcall(gm_cutscene.gm_cutscene_clear_log)
		count = count + 1
	end

	self:log("Logging disabled (" .. count .. " items)")
	return true
end

function World:get_speed_presets()
	return SPEED_PRESETS
end

return World:new()
