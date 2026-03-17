-- ============================================================
-- AUTO_COMBO.LUA - Intelligent Skill Rotation System
-- ============================================================
-- Scans all equipped skill slots, checks cooldowns, and
-- automatically executes the optimal skill rotation for
-- maximum damage output.
--
-- Slot Layout (PC):
--   Q / ~ (Tilde) : Normal attack (light/heavy)
--   TAB           : Switch weapon/kongfu
--   1, 2, 3, 4   : Martial art skills
--   Sensor slot   : Conditional replacement skill (auto)
--
-- Rotation Logic:
--   1. Scan martial art slots (1-4) for off-cooldown skills
--   2. Prioritize by skill_breakdown_priority (damage proxy)
--   3. Fire highest priority off-CD skill
--   4. Follow up with combo chain if available
--   5. Fill gaps with normal attacks
--   6. Loop continuously while enabled
-- ============================================================

local AutoCombo = {}

local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Utils = Reg.get("Utils")
local HookInterceptor = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\lib\\hook_interceptor.lua", "HookInterceptor")
local events = Utils.safe_import("hexm.client.consts.events")
local event_consts = Utils.safe_import("hexm.client.consts.event_consts")
local skill_consts = Utils.safe_import("hexm.common.consts.skill_consts")

-- ============================================================
-- CONFIGURATION
-- ============================================================

AutoCombo.CONFIG = {
	LOG_ENABLED = true,

	-- Tick interval (seconds) — how often the rotation logic runs
	TICK_INTERVAL = 0.15,

	-- Delay before executing a combo follow-up
	COMBO_DELAY = 0.05,

	-- Skip charge/xuli skills (require hold, not tap)
	SKIP_XULI = true,

	-- Use normal attacks to fill gaps between skills
	USE_NORMAL_FILL = true,

	-- Minimum time between consecutive skill casts (anti-spam)
	GLOBAL_CD = 0.2,

	-- Slot indices for martial art skills (keys 1-4)
	-- These are the slot indices used by skill_panel_click / get_skill_no_by_slot
	MARTIAL_SLOTS = { 1, 2, 3, 4 },

	-- Slot index for normal attack (Q key / light attack)
	NORMAL_SLOT = 6,

	-- Slot index for sensor/special (auto-triggered conditional skill)
	SENSOR_SLOT = 10,

	-- Slot for kongfu special (slot 3 = kongfu skill)
	KONGFU_SLOT = 3,

	-- Slot for weapon skill
	WEAPON_SLOT = 5,
}

-- ============================================================
-- STATE
-- ============================================================

local _enabled = false
local _interceptor = nil
local _tick_timer = nil
local _last_cast_time = 0
local _combo_pending = false -- true when waiting to fire a combo follow-up

-- ============================================================
-- LOGGING
-- ============================================================

local function _log(fmt, ...)
	if not AutoCombo.CONFIG.LOG_ENABLED then
		return
	end
	local msg
	if select("#", ...) > 0 then
		msg = string.format(fmt, ...)
	else
		msg = fmt
	end
	Logger.log("[AutoCombo] " .. msg)
end

-- ============================================================
-- HELPERS
-- ============================================================

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

local function _get_key_by_value(tbl, value)
	for k, v in pairs(tbl) do
		if v == value then
			return k
		end
	end
	return nil
end

local function _now()
	local ok, ts = pcall(function()
		return G.DateTimeManager:now()
	end)
	return ok and ts or os.clock()
end

-- ============================================================
-- SKILL INSPECTION
-- ============================================================

--- Get skill data table from datam
local function _get_skill_data(skill_id)
	if not skill_id then
		return nil
	end
	local ok, data = pcall(function()
		return G.datam.skills:get(tonumber(skill_id))
	end)
	return ok and data or nil
end

--- Check if a skill is currently on cooldown
local function _is_on_cd(skill_id)
	local ok, result = pcall(function()
		return G.main_player:is_skill_in_cd(tonumber(skill_id))
	end)
	return ok and result
end

--- Check if a skill is a charge/xuli type (needs hold)
local function _is_xuli_skill(skill_id)
	local data = _get_skill_data(skill_id)
	if not data then
		return false
	end
	local touch_type = _safe_get(data, "skill_touch_type", 0)
	-- skill_consts.SKILL_TOUCH_TYPE_XULI
	return touch_type == 2
end

--- Get the skill class (101=normal, 102=heavy, 103=break, 104=charge, etc.)
local function _get_skill_class(skill_id)
	local data = _get_skill_data(skill_id)
	if not data then
		return nil
	end
	return _safe_get(data, "skill_class", nil)
end

--- Get breakdown priority (higher = more damage/importance)
local function _get_priority(skill_id)
	local data = _get_skill_data(skill_id)
	if not data then
		return 0
	end
	return _safe_get(data, "skill_breakdown_priority", 0)
end

--- Check if skill has combo follow-ups
local function _has_combo(skill_id)
	local data = _get_skill_data(skill_id)
	if not data then
		return false
	end
	local combo_ids = _safe_get(data, "skill_combo_ids", nil)
	return combo_ids ~= nil
end

--- Check if player is currently in a skill animation
local function _is_in_skill()
	local ok, result = pcall(function()
		local driver = G.main_player.skill_driver
		return driver and driver.cur_skill ~= nil
	end)
	return ok and result
end

--- Check if a combo is currently active (waiting for follow-up)
local function _is_combo_active()
	local ok, result = pcall(function()
		local combo_map = G.main_player:get_combo_skills_map()
		if not combo_map then
			return false
		end
		-- Check if there's any entry in the map
		for _ in pairs(combo_map) do
			return true
		end
		return false
	end)
	return ok and result
end

--- Get the current skill being executed
local function _get_current_skill_id()
	local ok, result = pcall(function()
		local driver = G.main_player.skill_driver
		if driver and driver.cur_skill then
			return driver.cur_skill.skill_id
		end
		return nil
	end)
	return ok and result or nil
end

-- ============================================================
-- SLOT SCANNING
-- ============================================================

--- Scan a list of slot indices and return sorted candidates
--- Returns: array of {slot, skill_id, priority, has_combo, on_cd}
local function _scan_slots(slot_list)
	local candidates = {}
	local mp = G.main_player
	if not mp then
		return candidates
	end

	for _, slot_idx in ipairs(slot_list) do
		local ok, info = pcall(function()
			local skill_id = mp:get_skill_no_by_slot(slot_idx)
			if not skill_id then
				return nil
			end

			local data = _get_skill_data(skill_id)
			if not data then
				return nil
			end

			local on_cd = _is_on_cd(skill_id)
			local priority = _safe_get(data, "skill_breakdown_priority", 0)
			local skill_class = _safe_get(data, "skill_class", 0)
			local is_xuli = _is_xuli_skill(skill_id)

			return {
				slot = slot_idx,
				skill_id = skill_id,
				priority = priority,
				skill_class = skill_class,
				has_combo = _has_combo(skill_id),
				on_cd = on_cd,
				is_xuli = is_xuli,
			}
		end)

		if ok and info then
			table.insert(candidates, info)
		end
	end

	-- Sort by priority descending (highest priority first)
	table.sort(candidates, function(a, b)
		return a.priority > b.priority
	end)

	return candidates
end

-- ============================================================
-- ROTATION ENGINE
-- ============================================================

--- Find the best skill to cast right now
local function _find_best_skill()
	local now = _now()

	-- Respect global CD
	if now - _last_cast_time < AutoCombo.CONFIG.GLOBAL_CD then
		return nil
	end

	-- Don't interrupt ongoing skills (unless combo is ready)
	if _is_in_skill() and not _is_combo_active() then
		return nil
	end

	-- If a combo follow-up is available, fire it first
	if _is_combo_active() then
		local ok, combo_info = pcall(function()
			local combo_map = G.main_player:get_combo_skills_map()
			for skill_id, config in pairs(combo_map) do
				local combo_skill = _safe_get(config, "combo_skill_no", nil)
				local slot_no = _safe_get(config, "slot_no", nil)
				if combo_skill and slot_no then
					-- Skip xuli combo skills
					if AutoCombo.CONFIG.SKIP_XULI and _is_xuli_skill(combo_skill) then
						return nil
					end
					return { slot = slot_no, skill_id = combo_skill, reason = "combo" }
				end
			end
			return nil
		end)
		if ok and combo_info then
			return combo_info
		end
	end

	-- Scan martial art slots (1-4) for off-CD skills
	local candidates = _scan_slots(AutoCombo.CONFIG.MARTIAL_SLOTS)

	for _, c in ipairs(candidates) do
		if not c.on_cd and not c.is_xuli then
			return { slot = c.slot, skill_id = c.skill_id, priority = c.priority, reason = "martial" }
		end
	end

	-- Also check kongfu slot and weapon slot
	local extra_slots = { AutoCombo.CONFIG.KONGFU_SLOT, AutoCombo.CONFIG.WEAPON_SLOT }
	local extra = _scan_slots(extra_slots)
	for _, c in ipairs(extra) do
		if not c.on_cd and not c.is_xuli then
			return { slot = c.slot, skill_id = c.skill_id, priority = c.priority, reason = "extra" }
		end
	end

	-- Fill with normal attack if everything is on CD
	if AutoCombo.CONFIG.USE_NORMAL_FILL then
		local normal_slot = AutoCombo.CONFIG.NORMAL_SLOT
		local ok, skill_id = pcall(function()
			return G.main_player:get_skill_no_by_slot(normal_slot)
		end)
		if ok and skill_id and not _is_on_cd(skill_id) then
			return { slot = normal_slot, skill_id = skill_id, reason = "normal_fill" }
		end
	end

	return nil
end

--- Execute one rotation tick
local function _rotation_tick()
	if not _enabled then
		return
	end

	local mp = G.main_player
	if not mp then
		return
	end

	-- Don't act if player is dead or in special state
	local ok_state, should_skip = pcall(function()
		local state = mp:get_curr_state_name()
		if state == "dead" or state == "revive" then
			return true
		end
		return false
	end)
	if ok_state and should_skip then
		return
	end

	local best = _find_best_skill()
	if not best then
		return
	end

	local ok, err = pcall(function()
		_log("%s: slot=%s skill=%s", best.reason, tostring(best.slot), tostring(best.skill_id))
		mp:skill_panel_click(best.slot)
		_last_cast_time = _now()
	end)

	if not ok then
		_log("Cast error: %s", tostring(err))
	end
end

-- ============================================================
-- COMBO FOLLOW-UP HOOK
-- ============================================================

local function _intercept_listenable(spec, args, results, traceback)
	if not _enabled then
		return
	end

	local entity = args[1]
	local ins_str = tostring(entity)

	if not ins_str:find("PlayerAvatar") then
		return
	end

	local event = args[3]
	local ev_name = _get_key_by_value(events, event)

	-- On COMBO_START: the game populated the combo map, fire quickly
	if ev_name == "E_SKILL_COMBO_START" then
		_combo_pending = true
		-- Fire combo faster than the normal tick
		pcall(function()
			G.main_player:add_timer(AutoCombo.CONFIG.COMBO_DELAY, function()
				_combo_pending = false
				_rotation_tick()
			end)
		end)
		return
	end

	-- On SKILL_END: ready for next rotation pick
	if ev_name == "E_SKILL_END" then
		_combo_pending = false
		-- Small delay then pick next skill
		pcall(function()
			G.main_player:add_timer(0.05, function()
				_rotation_tick()
			end)
		end)
		return
	end

	-- On SKILL_START with time combo: schedule follow-up
	if ev_name == "E_SKILL_START" then
		local event_data = args[4]
		local skill_id = _safe_get(event_data, "skill_id", nil)
		if not skill_id then
			return
		end

		local ok, has_time_combo = pcall(function()
			local skill_tb = G.datam.skills:get(tonumber(skill_id))
			if not skill_tb then
				return false
			end
			local combo_mode = _safe_get(skill_tb, "skill_combo_mode", 0)
			return combo_mode and combo_mode > 0
		end)

		if ok and has_time_combo then
			pcall(function()
				G.main_player:add_timer(0.1, function()
					if _is_combo_active() then
						_log("TIME COMBO for skill %s", tostring(skill_id))
						_rotation_tick()
					end
				end)
			end)
		end
	end
end

-- ============================================================
-- TICK LOOP
-- ============================================================

local function _start_tick_loop()
	if _tick_timer then
		return
	end

	local function tick()
		if not _enabled then
			return
		end
		-- Only run rotation tick if not waiting for combo
		if not _combo_pending then
			_rotation_tick()
		end
		-- Re-schedule
		pcall(function()
			_tick_timer = G.main_player:add_timer(AutoCombo.CONFIG.TICK_INTERVAL, tick)
		end)
	end

	pcall(function()
		_tick_timer = G.main_player:add_timer(AutoCombo.CONFIG.TICK_INTERVAL, tick)
	end)
end

local function _stop_tick_loop()
	if _tick_timer then
		pcall(function()
			_tick_timer:cancel()
		end)
		_tick_timer = nil
	end
end

-- ============================================================
-- PUBLIC API
-- ============================================================

function AutoCombo.enable()
	if _enabled then
		_log("Already enabled")
		return true
	end

	-- Hook listenable for combo/skill events
	_interceptor = HookInterceptor.create({
		{
			spec = "hexm.client.util.listenable:Listenable:_notify_declared_additional_listens",
			post_exec = _intercept_listenable,
		},
	})

	if not _interceptor or not _interceptor:is_active() then
		_log("ERROR: Failed to hook listenable")
		return false, "Hook failed"
	end

	_enabled = true
	_last_cast_time = 0
	_combo_pending = false

	-- Start the rotation tick loop
	_start_tick_loop()

	-- Log current loadout
	pcall(function()
		local kongfu = G.main_player:get_now_active_kongfu()
		_log("Enabled — kongfu=%s tick=%.2fs gcd=%.2fs", tostring(kongfu), AutoCombo.CONFIG.TICK_INTERVAL, AutoCombo.CONFIG.GLOBAL_CD)

		local slots = _scan_slots(AutoCombo.CONFIG.MARTIAL_SLOTS)
		for _, s in ipairs(slots) do
			_log("  Slot %d: skill=%s prio=%d cd=%s combo=%s xuli=%s", s.slot, tostring(s.skill_id), s.priority, tostring(s.on_cd), tostring(s.has_combo), tostring(s.is_xuli))
		end
	end)

	return true
end

function AutoCombo.disable()
	if not _enabled then
		return true
	end

	_stop_tick_loop()

	if _interceptor then
		_interceptor:unhook_all()
		_interceptor = nil
	end

	_enabled = false
	_combo_pending = false
	_log("Disabled")
	return true
end

function AutoCombo.is_enabled()
	return _enabled
end

function AutoCombo.status()
	local info = {
		enabled = _enabled,
		config = AutoCombo.CONFIG,
		combo_pending = _combo_pending,
	}

	if _enabled then
		pcall(function()
			info.combo_state = G.main_player.skill_ctrl.combo_state
			info.active_kongfu = G.main_player:get_now_active_kongfu()
			info.in_skill = _is_in_skill()
			info.current_skill = _get_current_skill_id()
			info.combo_active = _is_combo_active()

			-- Scan all slots
			info.martial_slots = _scan_slots(AutoCombo.CONFIG.MARTIAL_SLOTS)
			info.extra_slots = _scan_slots({ AutoCombo.CONFIG.KONGFU_SLOT, AutoCombo.CONFIG.WEAPON_SLOT })
		end)
	end

	return info
end

return AutoCombo
