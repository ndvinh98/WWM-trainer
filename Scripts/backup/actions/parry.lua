local Parry = {}
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Utils = Reg.get("Utils")
local HookInterceptor = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\lib\\hook_interceptor.lua", "HookInterceptor")
local cmsgpack = Utils.safe_import("cmsgpack")
local events = Utils.safe_import("hexm.client.consts.events")

-- ============================================================
-- REGISTRY: Restore or create module state (survives reload)
-- ============================================================

local REG_KEY = "Parry"
Parry = Reg.get(REG_KEY) or Parry
Reg.set(REG_KEY, Parry)

-- ============================================================
-- CONFIGURATION (always re-apply on reload)
-- ============================================================

Parry.CONFIG = {
	LOG_ENABLED = false,
}
Parry.SLOT_PARRY = 16
Parry.SLOT_DASH = 7

-- Init state only if fresh (not reloaded)
if Parry._enabled == nil then
	Parry._enabled = false
	Parry._interceptor = nil
end

-- ============================================================
-- STATE
-- ============================================================

local USEFUL_NPC_EVENTS = {
	E_SKILL_ANIM_BEGIN_CLIENT = true,
	E_GD_SIGNAL = true,
	E_BONE_COLLISION = true,
	E_BEHIT_BEGAN = true,
	E_DAMAGE_BEHIT_BEGAN = true,
	E_BE_PARRY = true,
	E_SKILL_START = true,
	E_SKILL_RELEASE = true,
	E_SKILL_END = true,
	E_PRE_HIT = true,
}

-- ============================================================
-- LOGGING
-- ============================================================

-- local function _log(msg)
-- 	if not Parry.CONFIG.LOG_ENABLED then
-- 		return
-- 	end
-- 	if Logger then
-- 		Logger.log("[SyncObs] " .. msg, Parry.CONFIG.LOG_FILE)
-- 	end
-- end

local function _log(fmt, ...)
	if not Parry.CONFIG.LOG_ENABLED then
		return
	end
	-- Format message if extra params exist
	local msg
	if select("#", ...) > 0 then
		msg = string.format(fmt, ...)
	else
		msg = fmt
	end

	Logger.log(string.format("%s", msg))
end

---------------------------------
-- Helper functions
---------------------------------

local function _get_key_by_value(tbl, value)
	for k, v in pairs(tbl) do
		if v == value then
			return k
		end
	end
	return nil
end

local function _safe_get(obj, key, default)
	if obj == nil then
		return default
	end
	local ok, value = pcall(function()
		return obj[key]
	end)
	if ok and value ~= nil then
		return value
	end
	local ok_getter, getter = pcall(function()
		return obj.get
	end)
	if ok_getter and type(getter) == "function" then
		local ok_get, value_get = pcall(function()
			return getter(obj, key, default)
		end)
		if ok_get then
			return value_get
		end
	end
	return default
end

---------------------------------
-- Interceptor functions
---------------------------------

local function _intercept_listenable(spec, args, results, traceback)
	local entity = args[1]
	local ins_str = tostring(entity)
	local channel = args[2]
	local event = args[3]
	local event_data = args[4]
	local event_str = tostring(event)
	local ev_name = _get_key_by_value(events, event) or "N/A"

	if ins_str:find("PlayerAvatar") and ev_name == "E_DAMAGE_BEHIT_BEGAN" then
		local ctx = _safe_get(event_data, "context", nil)
		local dmg = _safe_get(event_data, "damage", nil)
		local dmg_num = tonumber(dmg) or 0
		local calcpoint_id = _safe_get(event_data, "calcpoint_id", nil)
		local parry_tag = _safe_get(event_data, "parry_tag", nil)
		local defence_flag = _safe_get(event_data, "defence_flag", nil)
		local flag = _safe_get(event_data, "flag", nil)
		local fromer_id = _safe_get(event_data, "fromer_id", nil)
		local skill_id = _safe_get(event_data, "skill_id", nil)
		if not skill_id and ctx then
			skill_id = _safe_get(ctx, "skill_id", nil)
		end
		_log("================================================")
		local attacker = G.space:get_entity(fromer_id)
		local anim = attacker.skill_driver:get_ex_data("cur_anim")
		local anim_start_ts = attacker.skill_driver:get_ex_data("cur_anim_start_ts")
		local curr_segment = attacker.skill_driver.cur_skill_segment

		_log(
			"CLIENT_EVENT | >>>>>>>>> Player DAMAGE skill_ex=%s ex_anim=%s curr_segment=%s cp=%s dmg=%s from=%s data=%s",
			tostring(skill_id),
			tostring(anim),
			tostring(curr_segment),
			tostring(calcpoint_id),
			tostring(dmg),
			tostring(fromer_id),
			Utils.dump_value(event_data)
		)
		_log("================================================")
	end

	-- -- === NPC only ===
	if not ins_str:find("Npc") and not ins_str:find("CombativeAnimal") then
		return
	end

	if ev_name == "E_PRE_HIT" then
		local difficulty = G.main_player.skill_ctrl:get_difficulty()
		local skill_id = entity.skill_driver.cur_skill.skill_id
		local skill_d = G.datam.skills:get(tonumber(skill_id))
		local huajie = _safe_get(skill_d, "huajie", nil)
		local is_parriable = huajie ~= nil
		_log(
			"CLIENT_EVENT | >>>>>>>>> NPC Skill Start: %s is_parriable=%s difficulty=%s",
			tostring(skill_id),
			tostring(is_parriable),
			tostring(difficulty)
		)
		if is_parriable then
			G.main_player:try_use_parry()
		else
			local dash_skill_no = G.main_player:get_skill_no_by_slot(Parry.SLOT_DASH)
			G.main_player:use_skill(dash_skill_no)
		end
	end

	local should_log_npc_event = USEFUL_NPC_EVENTS[tostring(ev_name)] == true
	-- end
	if should_log_npc_event then
		_log("CLIENT_EVENT | >>>>>>>>> NPC Event: " .. ev_name .. " - Code: " .. event_str)
	end
end

-- ============================================================
-- INTERNAL: Hook management
-- ============================================================

local function _unhook()
	if Parry._interceptor then
		pcall(function()
			Parry._interceptor:unhook_all()
		end)
		Parry._interceptor = nil
	end
end

local function _hook()
	_unhook() -- clean up any stale hook from previous load
	Parry._interceptor = HookInterceptor.create({
		{
			spec = "hexm.client.util.listenable:Listenable:_notify_declared_additional_listens",
			post_exec = _intercept_listenable,
		},
	})
	if not Parry._interceptor or not Parry._interceptor:is_active() then
		_log("ERROR: Failed to hook sync methods")
		return false
	end
	return true
end

-- ============================================================
-- PUBLIC API
-- ============================================================

function Parry.enable()
	if Parry._enabled then
		_log("Already enabled")
		return true
	end

	if not _hook() then
		return false, "Hook failed"
	end

	Parry._enabled = true
	_log("Enabled")
	return true
end

function Parry.disable()
	if not Parry._enabled then
		return false, "Not enabled"
	end

	_unhook()

	Parry._enabled = false
	_log("Disabled")
	return true
end

function Parry.is_enabled()
	return Parry._enabled
end

-- ============================================================
-- RELOAD HANDLING: If was enabled, re-hook with fresh code
-- ============================================================
if Parry._enabled then
	_log("Reload detected while enabled, re-hooking with fresh code")
	_hook()
end

return Parry
