-- ============================================================
-- COMBAT.LUA - Combat Actions
-- ============================================================
-- Prerequisites: Bootstrap must be loaded first

local Combat = {}

-- Reference libs via Reg (loaded once by bootstrap)
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Utils = Reg.get("Utils")
local Hooks = Reg.get("Hooks")

local function _log(msg)
	Logger.log("[Combat] " .. msg)
end

-- Constants
Combat.PARRY_SLOT_ID = 16
Combat.DASH_SLOT_ID = 7
Combat.BUFF_GOD_MODE = 70063
Combat.BUFF_INVISIBLE = 108010
Combat.BUFF_NPC_DUMB = 380013
Combat.BUFF_RECOVER = { 30383, 30363 }

local function _instant_full_charge_override(spec, args, results, traceback, orig_function)
	local self_node = args[1]
	local graph = args[2]
	if not self_node or not graph then
		return orig_function(Utils.unpack(args))
	end

	local context = graph.context
	local entity = context and context.entity
	if not context or not entity then
		return orig_function(Utils.unpack(args))
	end

	local now = DateTimeManager and DateTimeManager:now()
	if not now then
		_log("Instant Full Charge: failed to resolve current time")
		return orig_function(Utils.unpack(args))
	end

	local charge_time = math.min(context.charge_time or self_node.max_time, self_node.max_time)
	if not charge_time or charge_time <= 0 then
		_log("Instant Full Charge: invalid charge time=" .. tostring(charge_time))
		return orig_function(Utils.unpack(args))
	end

	local speed = context.get and context:get("global_speed", 1.0) or 1.0
	charge_time = charge_time / speed

	if self_node.is_archer_charge and entity.get_server_entity then
		local server_entity = entity:get_server_entity()
		if server_entity and server_entity.attr_get then
			local ok_archer, archer_loop_time = pcall(server_entity.attr_get, server_entity, "ARCHER_LOOP_TIME")
			if ok_archer and archer_loop_time and archer_loop_time > 0 then
				charge_time = archer_loop_time
			end
		end
	end

	context.charge_start_ts = now - charge_time
	context.charge_dur = charge_time

	local es_id = self_node.sync_id and self_node:sync_id(graph)
	_log("Instant Full Charge: es_id=" .. tostring(es_id) .. ", charge_time=" .. tostring(charge_time))

	local ok, err = pcall(function()
		G.main_player.al_driver:add_reboot(
			es_id,
			Utils.init_dict({ ["timeout"] = 1, ["charge_time"] = charge_time })
		)
		graph:finish_node(self_node, {
			__out__ = 1,
			timeout = 1,
		})
	end)
	if not ok then
		_log("Instant Full Charge: reboot failed: " .. tostring(err))
		return nil
	end

	_log("Instant Full Charge: rebooted with full charge time=" .. tostring(charge_time))
	return nil
end

function Combat.enable_infinite_stamina()
	_cleanup_infinite_stamina()

	_inf_stamina_interceptor = HookInterceptor.create({
		-- Hook 1: one-time cost on skill release
		{
			spec = "hexm.common.actionline.nodes.logic_nodes:SkillRelease:do_cost",
			post_exec = _noop_override,
			override_orig_function = true,
		},
		-- Hook 2: continuous drain during charge skills
		{
			spec = "hexm.common.actionline.nodes.action_nodes:ChargeNode:_start_res_consume",
			post_exec = _noop_override,
			override_orig_function = true,
		},
		-- Hook 3: segment-based auto-consume (resource_consume_mode 2/3)
		{
			spec = "hexm.common.base.combat_resource_base:CombatResourceBase:skill_auto_consume_res",
			post_exec = _noop_override,
			override_orig_function = true,
		},
		-- Hook 4: runtime-proven path for post-charge stamina drain
		{
			spec = "hexm.client.fake_server.entities.player_avatar:FakePlayerAvatar:consume_resource",
			post_exec = function(spec, args, results, traceback, orig_function)
				local res_id = args[2]
				if res_id ~= STAMINA_RES_ID then
					return orig_function(Utils.unpack(args))
				end
				_log("Patched consume_resource")
				return 0
			end,
			override_orig_function = true,
		},
	})

	if not _inf_stamina_interceptor or not _inf_stamina_interceptor:is_active() then
		_log("Infinite Stamina: FAILED to hook")
		return false, "Failed to hook stamina methods"
	end

	_log("Infinite Stamina: ON")
	return true
end

function Combat.enable_instant_full_charge()
	_cleanup_instant_full_charge()

	_instant_full_charge_interceptor = HookInterceptor.create({
		{
			spec = "hexm.common.actionline.nodes.action_nodes:ChargeNode:start",
			post_exec = _instant_full_charge_override,
			override_orig_function = true,
		},
	})

	if not _instant_full_charge_interceptor or not _instant_full_charge_interceptor:is_active() then
		_log("Instant Full Charge: FAILED to hook")
		return false, "Failed to hook ChargeNode:start"
	end

	_log("Instant Full Charge: ON")
	return true
end

function Combat.disable_instant_full_charge()
	_cleanup_instant_full_charge()
	_log("Instant Full Charge: OFF")
	return true
end

return Combat
