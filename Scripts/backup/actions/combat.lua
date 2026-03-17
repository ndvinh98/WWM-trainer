-- ============================================================
-- COMBAT.LUA - Combat Actions
-- ============================================================
-- Prerequisites: Bootstrap must be loaded first

local Combat = {}
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Utils = Reg.get("Utils")
local HookInterceptor = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\lib\\hook_interceptor.lua", "HookInterceptor")

-- ============================================================
-- REGISTRY: Restore or create module state (survives reload)
-- ============================================================

local REG_KEY = "Combat"
Combat = Reg.get(REG_KEY) or Combat
Reg.set(REG_KEY, Combat)

-- ============================================================
-- CONFIGURATION (always re-apply on reload)
-- ============================================================

Combat.PARRY_SLOT_ID = 16
Combat.DASH_SLOT_ID = 7
Combat.BUFF_GOD_MODE = 70063
Combat.BUFF_INVISIBLE = 108010
Combat.BUFF_NPC_DUMB = 380013
Combat.BUFF_RECOVER = { 30383, 30363 }

local STAMINA_RES_ID = 5 -- attr_consts.COMBAT_RES_NAILI

-- Reason string for push/pop flag stacks
local NPC_BLIND_REASON = "combat_mod_npc_blind"
-- Priority: high enough to override gameplay, below engine max
local NPC_BLIND_PRIORITY = 999

-- Init state only if fresh (not reloaded)
if Combat._inf_stamina_interceptor == nil then
	Combat._inf_stamina_interceptor = nil
end
if Combat._instant_full_charge_interceptor == nil then
	Combat._instant_full_charge_interceptor = nil
end
if Combat._npc_blind_active == nil then
	Combat._npc_blind_active = false
end

-- ============================================================
-- LOGGING
-- ============================================================

local function _log(msg)
	Logger.log("[Combat] " .. msg)
end

-- ============================================================
-- HELPERS
-- ============================================================

local function apply_buff(buff_id)
	local mp = G.main_player
	if not mp then
		_log("apply_buff: no main player")
		return false
	end

	local ok, err = pcall(function()
		mp.fake_server.buff:add_buff(buff_id, mp.id)
	end)
	if ok then
		_log("apply_buff " .. buff_id .. " via fake_server")
		return true
	end
	_log("fake_server.buff failed for " .. buff_id .. ": " .. tostring(err))

	-- Fallback: player add_buff (routes through RPC internally)
	if mp.add_buff then
		local ok2, err2 = pcall(function()
			mp:add_buff(buff_id, mp.id, {
				["duration"] = -1,
				["persistent"] = false,
				["reason"] = "combat_mod",
				["ignore_dead"] = true,
			})
		end)
		if ok2 then
			_log("apply_buff " .. buff_id .. " via add_buff")
			return true
		end
		_log("add_buff failed for " .. buff_id .. ": " .. tostring(err2))
	end
	_log("apply_buff " .. buff_id .. " via add_buff FAILED: no method worked")
	return false
end

local function remove_buff(buff_id)
	local mp = G.main_player
	if not mp then
		return
	end

	-- Primary: fake_server removal
	if mp.fake_server and mp.fake_server.buff then
		local ok = pcall(function()
			mp.fake_server.buff:remove_buffs_by_No({ buff_id }, mp.id, "combat_mod")
		end)
		if ok then
			return
		end
	end

	-- Fallback: player removal
	if mp.remove_buffs_by_No then
		pcall(function()
			mp:remove_buffs_by_No({ buff_id }, mp.id, "combat_mod")
		end)
	end
end

local function _now_ts()
	local DateTimeManager = Utils.safe_import("hexm.common.datetime_manager")
	DateTimeManager = DateTimeManager and DateTimeManager.DateTimeManager or DateTimeManager
	if DateTimeManager and DateTimeManager.now then
		local ok, ts = pcall(DateTimeManager.now, DateTimeManager)
		if ok and ts then
			return ts
		end
	end
	return nil
end

-- ============================================================
-- INTERNAL: Hook cleanup helpers
-- ============================================================

local function _cleanup_infinite_stamina()
	if Combat._inf_stamina_interceptor then
		Combat._inf_stamina_interceptor:unhook_all()
		Combat._inf_stamina_interceptor = nil
	end
end

local function _cleanup_instant_full_charge()
	if Combat._instant_full_charge_interceptor then
		Combat._instant_full_charge_interceptor:unhook_all()
		Combat._instant_full_charge_interceptor = nil
	end
end

-- ============================================================
-- HOOK CALLBACKS
-- ============================================================

local function _noop_override(spec, args, results, traceback, orig_function)
	return nil
end

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
	local now = _now_ts()
	if not now then
		return orig_function(Utils.unpack(args))
	end

	local charge_time = math.min(context.charge_time or self_node.max_time, self_node.max_time)
	if not charge_time or charge_time <= 0 then
		return orig_function(Utils.unpack(args))
	end

	local speed = context.get and context:get("global_speed", 1.0) or 1.0
	charge_time = charge_time / speed
	context.charge_start_ts = now - charge_time
	context.charge_dur = charge_time

	local es_id = self_node.sync_id and self_node:sync_id(graph)

	local ok, err = pcall(function()
		graph:finish_node(self_node, {
			__out__ = 1,
			timeout = 1,
			charge_lv = 2,
		})
	end)
	if not ok then
		_log("Instant Full Charge: reboot failed: " .. tostring(err))
		return nil
	end

	return nil
end

local function _filter_targets_in_battle_override(spec, args, results, traceback, orig_function)
	return {}
end

-- ============================================================
-- GOD MODE
-- ============================================================

function Combat.enable_god_mode()
	apply_buff(Combat.BUFF_GOD_MODE)
	_log("God Mode: ON")
	return true
end

function Combat.disable_god_mode()
	remove_buff(Combat.BUFF_GOD_MODE)
	_log("God Mode: OFF")
	return true
end

-- ============================================================
-- INFINITE STAMINA
-- ============================================================

function Combat.enable_infinite_stamina()
	_cleanup_infinite_stamina()

	Combat._inf_stamina_interceptor = HookInterceptor.create({
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
				return 0
			end,
			override_orig_function = true,
		},
	})

	if not Combat._inf_stamina_interceptor or not Combat._inf_stamina_interceptor:is_active() then
		_log("Infinite Stamina: FAILED to hook")
		return false, "Failed to hook stamina methods"
	end

	_log("Infinite Stamina: ON")
	return true
end

function Combat.disable_infinite_stamina()
	_cleanup_infinite_stamina()
	_log("Infinite Stamina: OFF")
	return true
end

function Combat.is_infinite_stamina_enabled()
	return Combat._inf_stamina_interceptor ~= nil and Combat._inf_stamina_interceptor:is_active()
end

-- ============================================================
-- INSTANT FULL CHARGE
-- ============================================================

function Combat.enable_instant_full_charge()
	_cleanup_instant_full_charge()

	Combat._instant_full_charge_interceptor = HookInterceptor.create({
		{
			spec = "hexm.common.actionline.nodes.action_nodes:ChargeNode:start",
			post_exec = _instant_full_charge_override,
			override_orig_function = true,
		},
		{
			spec = "hexm.common.actionline.nodes.target_nodes:FilterTargetsInBattle:start",
			post_exec = _filter_targets_in_battle_override,
			override_orig_function = true,
		},
	})

	if not Combat._instant_full_charge_interceptor or not Combat._instant_full_charge_interceptor:is_active() then
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

function Combat.is_instant_full_charge_enabled()
	return Combat._instant_full_charge_interceptor ~= nil and Combat._instant_full_charge_interceptor:is_active()
end

function Combat.disable_charge_instant()
	_cleanup_instant_full_charge()
	_cleanup_infinite_stamina()
	_log("Charge instant: OFF")
	return true
end

-- ============================================================
-- NO COOLDOWN
-- ============================================================

function Combat.enable_no_cooldown()
	Combat.enable_instant_full_charge()
	_log("No Cooldown: ON")
	return true
end

function Combat.disable_no_cooldown()
	Combat.disable_instant_full_charge()
	_log("No Cooldown: OFF")
	return true
end

-- ============================================================
-- INVISIBLE
-- ============================================================

function Combat.enable_invisible()
	Combat.enable_npc_blind()
	-- apply_buff(Combat.BUFF_INVISIBLE)
	_log("Invisible: ON")
	return true
end

function Combat.disable_invisible()
	Combat.disable_npc_blind()
	-- remove_buff(Combat.BUFF_INVISIBLE)
	_log("Invisible: OFF")
	return true
end

-- ============================================================
-- ONE HIT KILL
-- ============================================================

function Combat.enable_one_hit()
	Combat.enable_instant_full_charge()
	_log("One Hit Kill: ON")
	return true
end

function Combat.disable_one_hit()
	Combat.disable_instant_full_charge()
	_log("One Hit Kill: OFF")
	return true
end

-- ============================================================
-- RECOVER
-- ============================================================

function Combat.recover()
	for _, buff_id in pairs(Combat.BUFF_RECOVER) do
		apply_buff(buff_id)
	end
	return true
end

-- ============================================================
-- NPC BLIND / NO TARGET
-- ============================================================
-- Makes NPCs unable to see, target, or engage the player.
-- Uses the engine's own aggro-reverse, sight-reverse, and
-- alert-reverse flag-stack systems (see npc-blind-no-target-analysis.md).

local function _npc_blind_enable()
	local mp = G.main_player
	if not mp then
		return false, "No main player"
	end
	local fs = mp.fake_server
	if not fs then
		return false, "No fake_server"
	end

	local reason = NPC_BLIND_REASON
	local priority = NPC_BLIND_PRIORITY

	-- 1. Disable player sight reverse (all sight types)
	--    player local: push_sight_reverse_enable(reason, nil, false, priority)
	local ok1, err1 = pcall(function()
		mp:push_sight_reverse_enable(reason, nil, false, priority)
	end)
	if not ok1 then
		_log("NPC Blind: push_sight_reverse_enable failed: " .. tostring(err1))
	end

	-- 2. Disable player aggro reverse + clear current aggro
	--    fake_server: get_aggro_reverse():push_aggro_reverse_enabled(reason, false, priority)
	--    fake_server: clear_aggro_reverse(reason)
	local ok2, err2 = pcall(function()
		fs:get_aggro_reverse():push_aggro_reverse_enabled(reason, false, priority)
	end)
	if not ok2 then
		_log("NPC Blind: push_aggro_reverse_enabled failed: " .. tostring(err2))
	end

	local ok3, err3 = pcall(function()
		fs:clear_aggro_reverse(reason)
	end)
	if not ok3 then
		_log("NPC Blind: clear_aggro_reverse failed: " .. tostring(err3))
	end

	-- 3. Disable player alert reverse + clear current alert table
	--    fake_server: push_alert_reverse_enabled(reason, false, priority)
	--    fake_server: clear_reverse_alert_table()
	local ok4, err4 = pcall(function()
		fs:push_alert_reverse_enabled(reason, false, priority)
	end)
	if not ok4 then
		-- Fallback: try on local player (ownership split unclear from analysis)
		local ok4b, err4b = pcall(function()
			mp:push_alert_reverse_enabled(reason, false, priority)
		end)
		if not ok4b then
			_log(
				"NPC Blind: push_alert_reverse_enabled failed on both fs and mp: "
					.. tostring(err4)
					.. " / "
					.. tostring(err4b)
			)
		end
	end

	local ok5, err5 = pcall(function()
		fs:clear_reverse_alert_table()
	end)
	if not ok5 then
		local ok5b, err5b = pcall(function()
			mp:clear_reverse_alert_table()
		end)
		if not ok5b then
			_log(
				"NPC Blind: clear_reverse_alert_table failed on both fs and mp: "
					.. tostring(err5)
					.. " / "
					.. tostring(err5b)
			)
		end
	end

	-- 4. Suppress ignore_alert flag (GM path pattern)
	local ok6, err6 = pcall(function()
		fs.ignore_alert = true
	end)
	if not ok6 then
		_log("NPC Blind: set ignore_alert failed: " .. tostring(err6))
	end

	_log("NPC Blind: applied all flag-stack suppressors")
	return true
end

local function _npc_blind_disable()
	local mp = G.main_player
	if not mp then
		return false, "No main player"
	end
	local fs = mp.fake_server
	if not fs then
		return false, "No fake_server"
	end

	local reason = NPC_BLIND_REASON

	-- Undo sight reverse
	pcall(function()
		mp:pop_sight_reverse_enable(reason)
	end)

	-- Undo aggro reverse
	pcall(function()
		fs:get_aggro_reverse():pop_aggro_reverse_enabled(reason)
	end)

	-- Undo alert reverse
	pcall(function()
		fs:pop_alert_reverse_enabled(reason)
	end)
	pcall(function()
		mp:pop_alert_reverse_enabled(reason)
	end)

	-- Undo ignore_alert
	pcall(function()
		fs.ignore_alert = false
	end)

	_log("NPC Blind: popped all flag-stack suppressors")
	return true
end

function Combat.enable_npc_blind()
	if Combat._npc_blind_active then
		_log("NPC Blind: already active")
		return true
	end

	local ok, err = _npc_blind_enable()
	if not ok then
		return false, err
	end

	Combat._npc_blind_active = true
	_log("NPC Blind: ON")
	return true
end

function Combat.disable_npc_blind()
	if not Combat._npc_blind_active then
		return false, "Not enabled"
	end

	_npc_blind_disable()

	Combat._npc_blind_active = false
	_log("NPC Blind: OFF")
	return true
end

function Combat.is_npc_blind_enabled()
	return Combat._npc_blind_active == true
end

-- ============================================================
-- RELOAD HANDLING: If features were enabled, re-apply on reload
-- ============================================================

if Combat._inf_stamina_interceptor then
	_log("Reload detected: re-hooking infinite stamina")
	Combat._inf_stamina_interceptor = nil -- stale ref, re-create
	Combat.enable_infinite_stamina()
end

if Combat._instant_full_charge_interceptor then
	_log("Reload detected: re-hooking instant full charge")
	Combat._instant_full_charge_interceptor = nil -- stale ref, re-create
	Combat.enable_instant_full_charge()
end

if Combat._npc_blind_active then
	_log("Reload detected: re-applying NPC blind")
	_npc_blind_enable()
end

return Combat
