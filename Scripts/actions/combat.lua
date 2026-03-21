-- Scripts/actions/combat.lua
local ActionBase = _G.Reg.lib("ActionBase")

local Combat = ActionBase:extend("actions.combat")

-- ── Constants ──
local BUFF_GOD_MODE = 70063
local BUFF_INVISIBLE = 108010
local BUFF_RECOVER = { 30383, 30363 }
local NPC_BLIND_REASON = "combat_mod_npc_blind"
local NPC_BLIND_PRIORITY = 999
local STAMINA_RES_ID = 5

-- ── Buff helpers (non-hook) ──

local function _apply_buff(buff_id)
	local mp = G.main_player
	if not mp then
		return false
	end
	local ok = pcall(function()
		mp.fake_server.buff:add_buff(buff_id, mp.id)
	end)
	if ok then
		return true
	end
	if mp.add_buff then
		local ok2 = pcall(function()
			mp:add_buff(
				buff_id,
				mp.id,
				{ duration = -1, persistent = false, reason = "combat_mod", ignore_dead = true }
			)
		end)
		if ok2 then
			return true
		end
	end
	return false
end

local function _remove_buff(buff_id)
	local mp = G.main_player
	if not mp then
		return
	end
	pcall(function()
		mp.fake_server.buff:remove_buffs_by_No({ buff_id }, mp.id, "combat_mod")
	end)
end

function Combat:define_state()
	return {
		persistent = {
			god_mode = false,
			infinite_stamina = false,
			instant_charge = false,
			no_cooldown = false,
			npc_blind = false,
		},
		transient = {},
	}
end

function Combat:define_hooks()
	return {
		-- Infinite stamina hooks
		stamina_skill_cost = {
			spec = "hexm.common.actionline.nodes.logic_nodes:SkillRelease:do_cost",
			override_orig_function = true,
			post_exec = function(self, original, ...)
				return nil
			end,
		},
		stamina_charge_drain = {
			spec = "hexm.common.actionline.nodes.action_nodes:ChargeNode:_start_res_consume",
			override_orig_function = true,
			post_exec = function(self, original, ...)
				return nil
			end,
		},
		stamina_auto_consume = {
			spec = "hexm.common.base.combat_resource_base:CombatResourceBase:skill_auto_consume_res",
			override_orig_function = true,
			post_exec = function(self, original, ...)
				return nil
			end,
		},
		stamina_resource_consume = {
			spec = "hexm.client.fake_server.entities.player_avatar:FakePlayerAvatar:consume_resource",
			override_orig_function = true,
			post_exec = function(self, original, self_entity, res_id, ...)
				if res_id ~= STAMINA_RES_ID then
					return original(self_entity, res_id, ...)
				end
				return 0
			end,
		},
		-- No cooldown hooks
		no_cd_update = {
			spec = "hexm.client.fake_server.entities.player_avatar_members.imp_skill_cd:FakePlayerAvatarMember:update_skill_cd",
			override_orig_function = true,
			post_exec = function(self_action, original, self_entity, ...)
				return nil
			end,
		},
		no_cd_check = {
			spec = "hexm.client.entities.local.player_avatar_members.imp_skill_cd:PlayerAvatarMember:is_skill_in_cd",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return false
			end,
		},
		-- Instant charge hooks
		charge_start = {
			spec = "hexm.common.actionline.nodes.action_nodes:ChargeNode:start",
			override_orig_function = true,
			post_exec = function(self, original, self_node, graph, ...)
				if not self_node or not graph then
					return original(self_node, graph, ...)
				end
				local context = graph.context
				if not context or not context.entity then
					return original(self_node, graph, ...)
				end

				local DateTimeManager = portable.safe_import("hexm.common.datetime_manager")
				DateTimeManager = DateTimeManager and DateTimeManager.DateTimeManager or DateTimeManager
				local now = DateTimeManager and DateTimeManager.now and DateTimeManager:now()
				if not now then
					return original(self_node, graph, ...)
				end

				local charge_time = math.min(context.charge_time or self_node.max_time, self_node.max_time)
				if not charge_time or charge_time <= 0 then
					return original(self_node, graph, ...)
				end

				local speed = context.get and context:get("global_speed", 1.0) or 1.0
				charge_time = charge_time / speed
				context.charge_start_ts = now - charge_time
				context.charge_dur = charge_time

				pcall(function()
					graph:finish_node(self_node, {
						__out__ = 1,
						timeout = 1,
						charge_lv = 2,
					})
				end)
				return nil
			end,
		},
		filter_targets = {
			spec = "hexm.common.actionline.nodes.target_nodes:FilterTargetsInBattle:start",
			override_orig_function = true,
			post_exec = function(self, original, ...)
				return {}
			end,
		},
	}
end

-- ── God Mode (buff-based) ──

function Combat:set_god_mode(enabled)
	if enabled then
		_apply_buff(BUFF_GOD_MODE)
	else
		_remove_buff(BUFF_GOD_MODE)
	end
	self.state.god_mode = enabled
	self:log("God Mode: " .. (enabled and "ON" or "OFF"))
end

-- ── Infinite Stamina (hook-based) ──

function Combat:set_infinite_stamina(enabled)
	if enabled then
		self:hook("stamina_skill_cost")
		self:hook("stamina_charge_drain")
		self:hook("stamina_auto_consume")
		self:hook("stamina_resource_consume")
	else
		self:unhook("stamina_skill_cost")
		self:unhook("stamina_charge_drain")
		self:unhook("stamina_auto_consume")
		self:unhook("stamina_resource_consume")
	end
	self.state.infinite_stamina = enabled
	self:log("Infinite Stamina: " .. (enabled and "ON" or "OFF"))
end

-- ── Instant Charge (hook-based) ──

function Combat:set_instant_charge(enabled)
	if enabled then
		self:hook("charge_start")
		self:hook("filter_targets")
	else
		self:unhook("charge_start")
		self:unhook("filter_targets")
	end
	self.state.instant_charge = enabled
	self:log("Instant Charge: " .. (enabled and "ON" or "OFF"))
end

-- ── No Cooldown (debug_consts flag) ──

function Combat:set_no_cooldown(enabled)
	if enabled then
		self:hook("no_cd_update")
		self:hook("no_cd_check")
		pcall(function()
			local mp = G.main_player
			if mp and mp.refresh_skill_cds then
				mp:refresh_skill_cds()
			end
		end)
	else
		self:unhook("no_cd_update")
		self:unhook("no_cd_check")
	end
	self.state.no_cooldown = enabled
	self:log("No Cooldown: " .. (enabled and "ON" or "OFF"))
end

-- ── NPC Blind (flag-stack based, non-hook) ──

function Combat:set_npc_blind(enabled)
	local mp = G.main_player
	if not mp then
		return false, "No main player"
	end
	local fs = mp.fake_server
	if not fs then
		return false, "No fake_server"
	end

	if enabled then
		pcall(function()
			mp:push_sight_reverse_enable(NPC_BLIND_REASON, nil, false, NPC_BLIND_PRIORITY)
		end)
		pcall(function()
			fs:get_aggro_reverse():push_aggro_reverse_enabled(NPC_BLIND_REASON, false, NPC_BLIND_PRIORITY)
		end)
		pcall(function()
			fs:clear_aggro_reverse(NPC_BLIND_REASON)
		end)
		pcall(function()
			fs:push_alert_reverse_enabled(NPC_BLIND_REASON, false, NPC_BLIND_PRIORITY)
		end)
		pcall(function()
			fs:clear_reverse_alert_table()
		end)
		pcall(function()
			fs.ignore_alert = true
		end)
	else
		pcall(function()
			mp:pop_sight_reverse_enable(NPC_BLIND_REASON)
		end)
		pcall(function()
			fs:get_aggro_reverse():pop_aggro_reverse_enabled(NPC_BLIND_REASON)
		end)
		pcall(function()
			fs:pop_alert_reverse_enabled(NPC_BLIND_REASON)
		end)
		pcall(function()
			mp:pop_alert_reverse_enabled(NPC_BLIND_REASON)
		end)
		pcall(function()
			fs.ignore_alert = false
		end)
	end

	self.state.npc_blind = enabled
	self:log("NPC Blind: " .. (enabled and "ON" or "OFF"))
	return true
end

-- ── Recover ──

function Combat:recover()
	for _, buff_id in ipairs(BUFF_RECOVER) do
		_apply_buff(buff_id)
	end
	return true
end

-- ── Reload: re-apply non-hook features ──

function Combat:on_reload()
	if self.state.god_mode then
		_apply_buff(BUFF_GOD_MODE)
	end
	if self.state.npc_blind then
		self:set_npc_blind(true)
	end
end

return Combat:new()
