-- ============================================================
-- AutoLoot.LUA - Auto AutoLoot (Qizhen) Interaction
-- ============================================================
-- Approach: Scan all AOI entities around the player, filter by
-- distance, resolve interact ways, trigger interaction.
-- Prerequisites: Bootstrap must be loaded first
--
-- Interaction modes:
--   "A" (default) - Routes by server_process from active_interact_way data:
--                   PROGRESS_NORMAL (0): START → wait start_back → RESULT_AND_END
--                   PROGRESS_CLIENT_FIRST (3): direct RESULT (no START, no wait back)
--                   PROGRESS_CALL_RESULT (2): direct RESULT (no START, wait back)
--                   PROGRESS_LOCAL (1): skipped (local-only processing)
--   "B" (debug)   - Calls G.main_player:trigger_active_interact() directly.
--                   Useful to confirm the game's own state machine can open the entity.

local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Utils = Reg.get("Utils")

-- Restore or create module state from registry (survives reload)
local REG_KEY = "AutoLoot"
local AutoLoot = Reg.get(REG_KEY) or {}
Reg.set(REG_KEY, AutoLoot)

-- Config (always re-apply on reload)
local _entity_radius = 20
local _scan_interval = 1.0
AutoLoot._enable_logging = true
AutoLoot._log_cache = {}
AutoLoot._done = {}
AutoLoot._pending = nil
-- Init state only if fresh (not reloaded)
if AutoLoot._enabled == nil then
	AutoLoot._enabled = false
	AutoLoot._timer_action = nil
	AutoLoot._cache = {}
end

-- New state: interaction state machine (init once)
if AutoLoot._interaction_mode == nil then
	AutoLoot._interaction_mode = "A" -- "A" = start handshake, "B" = trigger_active_interact
end

-- ============================================================
-- Logging
-- ============================================================

local function _log(msg)
	if AutoLoot._log_cache[msg] then
		return
	end
	AutoLoot._log_cache[msg] = true
	Logger.log("[AutoLoot] " .. msg)
end

local function _debug(msg)
	if not AutoLoot._enable_logging then
		return
	end
	if AutoLoot._log_cache[msg] then
		return
	end
	AutoLoot._log_cache[msg] = true
	Logger.log("[AutoLoot][DBG] " .. msg)
end

-- ============================================================
-- Lazy-loaded dependencies (require inside runtime only)
-- ============================================================

local function _get_event_consts()
	local ok, m = pcall(require, "hexm.client.consts.event_consts")
	if ok then
		return m
	end
	_debug("WARN: could not load event_consts: " .. tostring(m))
	return nil
end

-- ============================================================
-- server_process constants (from interact_component_consts)
-- ============================================================

local PROGRESS_NORMAL = 0 -- Full START → RESULT → END
local PROGRESS_LOCAL = 1 -- Local only, no server RPCs
local PROGRESS_CALL_RESULT = 2 -- Skip START, call RESULT, wait back
local PROGRESS_CLIENT_FIRST = 3 -- Skip START, call RESULT, no wait

-- ============================================================
-- Helpers
-- ============================================================

local function calc_distance(player_pos, target_pos)
	if not player_pos or not target_pos then
		return math.huge
	end
	local px, py, pz = player_pos.x or 0, player_pos.y or 0, player_pos.z or 0
	local ex, ey, ez
	if target_pos[1] then
		ex, ey, ez = target_pos[1], target_pos[2], target_pos[3]
	else
		ex, ey, ez = target_pos.x or 0, target_pos.y or 0, target_pos.z or 0
	end
	local dx, dy, dz = px - ex, py - ey, pz - ez
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Build a bd table suitable for both START and RESULT_AND_END RPCs.
-- Returns a plain Lua table; the network layer serialises it to the server.
local function _build_interact_bd(entity, way_no, comp_id)
	local entity_no = 0
	pcall(function()
		entity_no = entity:get_No() or entity.entity_no or 0
	end)

	local pos_list = nil
	pcall(function()
		local p = entity:get_position()
		pos_list = { p[1], p[2], p[3] }
	end)

	-- way_info mirrors what active_interact_get_cur_way_info() returns
	local way_info = { way_no = way_no, comp_id = comp_id }

	local bd = {
		way_info = Utils.init_dict(way_info),
		client_No = entity_no,
		target_eid = entity.entity_id,
		client_serial_id = entity.serial_id or 0,
		comp_position = Utils.init_dict(pos_list),
	}
	return Utils.init_dict(bd)
end

-- Cancel any in-flight pending interaction (clean up listener + timeout).
local function _cancel_pending()
	local p = AutoLoot._pending
	if not p then
		return
	end
	-- Cancel start_back listener
	if p.listener then
		pcall(function()
			HexPlugin.Dispatcher.listener_cancel(p.listener)
		end)
		p.listener = nil
	end
	-- Cancel timeout Cocos action
	if p.timeout_action then
		pcall(function()
			local scene = cc.Director:getInstance():getRunningScene()
			if scene then
				scene:stopAction(p.timeout_action)
			end
		end)
		p.timeout_action = nil
	end
	AutoLoot._pending = nil
end

-- ============================================================
-- Option A: START handshake callbacks
-- ============================================================

-- Called when E_ACTIVE_INTERACT_REQUEST_START_BACK fires.
-- Event data: { err = <int>, back_data = <dict> }
local function _on_start_back(event, data)
	local p = AutoLoot._pending
	if not p then
		_debug("start_back: no pending slot, ignoring")
		return
	end

	local entity_id = p.entity_id
	local way_no = p.way_no
	local comp_id = p.comp_id
	local entity = p.entity
	local err = (data and data.err) or -1

	_log(string.format("start_back | entity=%s way=%s err=%s", entity_id, way_no, err))

	-- Always clean up pending state before doing more work
	_cancel_pending()

	-- Mark done so re-scans skip this entity regardless of outcome
	AutoLoot._done[entity_id] = true

	if err == 0 then -- ERR_OK
		-- Server accepted the START; now send RESULT_AND_END.
		-- No _direct flag needed — the server already has an act_board from START.
		local bd = _build_interact_bd(entity, way_no, comp_id)
		bd.client_result = true
		_debug(string.format("  start_back OK → sending result_and_end | bd=%s", Utils.dump_value(bd)))

		local ok, e = pcall(function()
			G.net:call_server("rpc_request_active_interact_result_and_end", entity_id, way_no, bd)
		end)
		if ok then
			_log("  result_and_end sent OK")
		else
			_log("  result_and_end call_server ERROR: " .. tostring(e))
		end
	else
		_log(
			string.format("  start_back FAILED err=%s data=%s — marking done, no retry", err, Utils.dump_value(data))
		)
		-- Optional mode-B fallback if user enabled it
		if AutoLoot._interaction_mode == "B" then
			_log("  Fallback-B: trigger_active_interact")
			pcall(function()
				G.main_player:trigger_active_interact(way_no, entity_id, nil, nil, comp_id)
			end)
		end
	end
end

-- Send rpc_request_active_interact_start to the real server for one entity.
local function _start_interact_A(entity, way_no, comp_id)
	local entity_id = entity.entity_id

	if AutoLoot._pending then
		_debug(string.format("  A: pending occupied by %s, skip %s", AutoLoot._pending.entity_id, entity_id))
		return
	end

	_log(string.format("A: START → entity=%s way=%s comp=%s", entity_id, way_no, comp_id))

	-- Register one-shot listener on main_player dispatcher for start_back
	local event_consts = _get_event_consts()
	if not event_consts then
		_log("  A: ERROR cannot load event_consts, abort")
		return
	end

	local listener = nil
	local ok, e = pcall(function()
		listener = G.main_player.dispatcher:add(event_consts.E_ACTIVE_INTERACT_REQUEST_START_BACK, function(evt, d)
			_on_start_back(evt, d)
		end)
	end)
	if not ok or not listener then
		_log("  A: ERROR registering listener: " .. tostring(e))
		return
	end
	_debug("  A: listener registered")

	-- 5-second timeout
	local timeout_action = nil
	pcall(function()
		local scene = cc.Director:getInstance():getRunningScene()
		timeout_action = cc.Sequence:create({
			cc.DelayTime:create(5.0),
			cc.CallFunc:create(function()
				if AutoLoot._pending and AutoLoot._pending.entity_id == entity_id then
					_log(string.format("A: TIMEOUT entity=%s way=%s — marking done", entity_id, way_no))
					_cancel_pending()
					AutoLoot._done[entity_id] = true
				end
			end),
		})
		scene:runAction(timeout_action)
	end)

	-- Fill pending slot
	AutoLoot._pending = {
		entity_id = entity_id,
		way_no = way_no,
		comp_id = comp_id,
		entity = entity,
		listener = listener,
		timeout_action = timeout_action,
	}

	-- Fire START RPC at real server
	local bd = _build_interact_bd(entity, way_no, comp_id)
	_debug(string.format("  A: call_server rpc_request_active_interact_start | bd=%s", Utils.dump_value(bd)))

	local ok2, e2 = pcall(function()
		G.net:call_server("rpc_request_active_interact_start", entity_id, way_no, bd)
	end)
	if not ok2 then
		_log("  A: rpc_request_active_interact_start ERROR: " .. tostring(e2))
		_cancel_pending()
		return
	end
	_log("  A: START sent, waiting for start_back…")
end

-- ============================================================
-- Option B: trigger_active_interact (debug fallback)
-- ============================================================

local function _start_interact_B(entity, way_no, comp_id)
	local entity_id = entity.entity_id
	_log(string.format("B: trigger_active_interact | entity=%s way=%s comp=%s", entity_id, way_no, comp_id))

	local ok, e = pcall(function()
		G.main_player:trigger_active_interact(way_no, entity_id, nil, nil, comp_id)
	end)
	if ok then
		_log("  B: trigger_active_interact called OK")
	else
		_log("  B: trigger_active_interact ERROR: " .. tostring(e))
	end
	-- Mark done to prevent repeat attempts during the same session
	AutoLoot._done[entity_id] = true
end

-- ============================================================
-- Option C: Direct RESULT (for non-NORMAL server_process)
-- ============================================================

-- C1: CLIENT_FIRST (3) — fire RESULT, no wait, mark done immediately.
local function _direct_result_client_first(entity, way_no, comp_id)
	local entity_id = entity.entity_id
	_log(string.format("C1: CLIENT_FIRST RESULT → entity=%s way=%s comp=%s", entity_id, way_no, comp_id))

	local bd = _build_interact_bd(entity, way_no, comp_id)
	bd.client_result = true
	bd.need_result_back = false

	_debug(string.format("  C1: call_server rpc_request_active_interact_result | bd=%s", Utils.dump_value(bd)))

	local ok, e = pcall(function()
		G.net:call_server("rpc_request_active_interact_result", entity_id, way_no, bd)
	end)
	if ok then
		_log("  C1: RESULT sent OK (no wait)")
	else
		_log("  C1: RESULT ERROR: " .. tostring(e))
	end

	AutoLoot._done[entity_id] = true
end

-- Called when E_ACTIVE_INTERACT_REQUEST_RESULT_BACK fires for a CALL_RESULT entity.
-- Event data: { result = <bool>, comp_eid = <str>, way_no = <int> }
local function _on_result_back(event, data)
	local p = AutoLoot._pending
	if not p then
		_debug("result_back: no pending slot, ignoring")
		return
	end

	local entity_id = p.entity_id
	local way_no = p.way_no
	local result = data and data.result

	_log(string.format("result_back | entity=%s way=%s result=%s", entity_id, way_no, tostring(result)))

	_cancel_pending()
	AutoLoot._done[entity_id] = true

	if result then
		_log("  result_back OK — interaction complete")
	else
		_log(string.format("  result_back FAILED data=%s — marking done, no retry", Utils.dump_value(data)))
	end
end

-- C2: CALL_RESULT (2) — send RESULT, wait for result_back via listener.
-- Uses the same pending-slot mechanism as _start_interact_A.
local function _direct_result_call_result(entity, way_no, comp_id)
	local entity_id = entity.entity_id

	if AutoLoot._pending then
		_debug(string.format("  C2: pending occupied by %s, skip %s", AutoLoot._pending.entity_id, entity_id))
		return
	end

	_log(string.format("C2: CALL_RESULT RESULT → entity=%s way=%s comp=%s", entity_id, way_no, comp_id))

	-- Register listener for result_back
	local event_consts = _get_event_consts()
	if not event_consts then
		_log("  C2: ERROR cannot load event_consts, abort")
		return
	end

	local listener = nil
	local ok, e = pcall(function()
		listener = G.main_player.dispatcher:add(event_consts.E_ACTIVE_INTERACT_REQUEST_RESULT_BACK, function(evt, d)
			_on_result_back(evt, d)
		end)
	end)
	if not ok or not listener then
		_log("  C2: ERROR registering result_back listener: " .. tostring(e))
		return
	end
	_debug("  C2: result_back listener registered")

	-- 5-second timeout
	local timeout_action = nil
	pcall(function()
		local scene = cc.Director:getInstance():getRunningScene()
		timeout_action = cc.Sequence:create({
			cc.DelayTime:create(5.0),
			cc.CallFunc:create(function()
				if AutoLoot._pending and AutoLoot._pending.entity_id == entity_id then
					_log(string.format("C2: TIMEOUT entity=%s way=%s — marking done", entity_id, way_no))
					_cancel_pending()
					AutoLoot._done[entity_id] = true
				end
			end),
		})
		scene:runAction(timeout_action)
	end)

	-- Fill pending slot
	AutoLoot._pending = {
		entity_id = entity_id,
		way_no = way_no,
		comp_id = comp_id,
		entity = entity,
		listener = listener,
		timeout_action = timeout_action,
	}

	-- Fire RESULT RPC
	local bd = _build_interact_bd(entity, way_no, comp_id)
	bd.client_result = true

	_debug(string.format("  C2: call_server rpc_request_active_interact_result | bd=%s", Utils.dump_value(bd)))

	local ok2, e2 = pcall(function()
		G.net:call_server("rpc_request_active_interact_result", entity_id, way_no, bd)
	end)
	if not ok2 then
		_log("  C2: rpc_request_active_interact_result ERROR: " .. tostring(e2))
		_cancel_pending()
		return
	end
	_log("  C2: RESULT sent, waiting for result_back…")
end

-- ============================================================
-- Option D: Break Entity (for breakable entities with TAG_GENERAL_STROKE)
-- These entities have no active_interact data and empty components.
-- They are destroyed by transitioning to a status with enter_broken_state=1.
-- ============================================================

local function _find_broken_status(comp_no)
	local status_list = nil
	pcall(function()
		status_list = G.datam.interact_comp_index:get(comp_no, {}):get("status", {})
	end)
	if not status_list then
		return nil
	end
	_debug(string.format("  D: comp_no=%s status_list=%s", tostring(comp_no), Utils.dump_value(status_list)))
	local broken = nil
	pcall(function()
		for i = 1, #status_list do
			local sno = status_list[i]
			local sd = G.datam.interact_comp_status:get(sno, nil)
			if sd then
				local ebs = sd:get("enter_broken_state", 0)
				if ebs ~= 0 then
					broken = sno
					return
				end
			end
		end
	end)
	return broken
end

local function _break_entity(entity, interact_comp)
	local entity_id = entity.entity_id
	local ent_no = entity.No

	_log(string.format("D: BREAK → entity=%s no=%s", entity_id, tostring(ent_no)))

	-- Try to find a broken status via interact_comp_index
	local broken_status = nil
	local ic_no = nil
	pcall(function()
		ic_no = interact_comp and interact_comp.No
	end)
	if ic_no then
		broken_status = _find_broken_status(ic_no)
	end
	if not broken_status and ent_no then
		broken_status = _find_broken_status(ent_no)
	end

	if broken_status then
		-- Has interact comp broken status → force transit
		_log(string.format("  D: broken_status=%s → rpc_force_transit_comp_status", tostring(broken_status)))
		local ts = nil
		pcall(function()
			ts = DateTimeManager:now()
		end)
		if not ts then
			ts = os.time()
		end
		local ok, e = pcall(function()
			G.net:call_server("rpc_force_transit_comp_status", entity_id, broken_status, ts)
		end)
		if ok then
			_log("  D: rpc_force_transit_comp_status sent")
		else
			_log("  D: rpc_force_transit_comp_status ERROR: " .. tostring(e))
		end
		AutoLoot._done[entity_id] = true
		return
	end

	-- No broken status → pure destructible (posui/HP entity).
	-- Use InteractDataManager wanfa resource damage to deplete HP → triggers
	-- DynamicAttr events → destruct_break() visual + remove_interact_comp cleanup.
	_log("  D: no broken_status, trying wanfa resource damage")

	-- Resolve entity No for data lookup
	local lookup_no = ic_no or ent_no
	if not lookup_no then
		_log("  D: SKIP — no No for data lookup")
		AutoLoot._done[entity_id] = true
		return
	end

	-- Look up posui_resource_id from entity_value config
	local posui_resource_id = nil
	pcall(function()
		local entity_data = G.datam.entity:get(lookup_no, {})
		local value_id = entity_data:get("value_id", 0)
		local value_data = G.datam.entity_value:get(value_id, {})
		posui_resource_id = value_data:get("posui_resource_id")
	end)

	if not posui_resource_id then
		_log("  D: SKIP — no posui_resource_id for No=" .. tostring(lookup_no))
		AutoLoot._done[entity_id] = true
		return
	end

	_debug(string.format("  D: posui_resource_id=%s", tostring(posui_resource_id)))

	-- Build lethal damage: large negative value to deplete HP to resource_min
	local res2dmg = Utils.init_dict({ [posui_resource_id] = -99999 })

	-- Use InteractDataManager to process the damage pipeline
	local ok1, e1 = pcall(function()
		local InteractDataManager = require("hexm.common.base.interact_comp.interact_data_manager").InteractDataManager
		local mgr = InteractDataManager()
		mgr:change_client_interact_wanfa_resource(
			interact_comp,
			res2dmg,
			Utils.init_dict({ creator_id = G.main_player_id })
		)
	end)
	if ok1 then
		_log("  D: wanfa resource damage applied")
	else
		_log("  D: wanfa resource damage ERROR: " .. tostring(e1))
	end

	AutoLoot._done[entity_id] = true
end

-- ============================================================
-- Option C3: Force Transit (for battle_state / raycast entities)
-- These entities use the interact-comp transit system instead of
-- active_interact RPCs.  Flow: force_transit → send_identifier → upload_drop_result
-- ============================================================

local function _force_transit_interact(entity, way_no, comp_id)
	local entity_id = entity.entity_id

	_log(string.format("C3: FORCE_TRANSIT → entity=%s way=%s comp=%s", entity_id, way_no, comp_id))

	-- Resolve interact_comp to find comp_no and determine the target (destroy) status
	local interact_comp = nil
	pcall(function()
		interact_comp = G.space:get_interact_comp(entity_id)
	end)
	if not interact_comp then
		pcall(function()
			interact_comp = entity:get_interact_comp()
		end)
	end

	local target_status = nil
	local identifier = "rb_contact_terrain" -- default identifier from decompiled code
	local current_status = nil

	-- Helper: scan a status list from interact_comp_index for a destroy target
	local function _find_destroy_status(comp_no, skip_status)
		local status_list = nil
		pcall(function()
			status_list = G.datam.interact_comp_index:get(comp_no, {}):get("status", {})
		end)
		if not status_list then
			return nil
		end
		_debug(string.format("  C3: comp_no=%s status_list=%s", tostring(comp_no), Utils.dump_value(status_list)))
		pcall(function()
			for i = 1, #status_list do
				local sno = status_list[i]
				if sno ~= skip_status then
					local sd = G.datam.interact_comp_status:get(sno, nil)
					if sd then
						local ds = sd:get("destroy_status", nil)
						if ds == 1 then
							target_status = sno
							local id_val = sd:get("entity_stop_send_identifier", nil)
							if id_val then
								identifier = id_val
							end
						end
					end
				end
			end
		end)
		return target_status
	end

	-- Strategy 1: iterate interact_comp.components for comp_no
	if interact_comp and interact_comp.components then
		for cid, comp_data in pairs(interact_comp.components) do
			local comp_no = comp_data.comp_no
			current_status = comp_data.status_no
			_debug(
				string.format(
					"  C3: comp cid=%s comp_no=%s status=%s",
					cid,
					tostring(comp_no),
					tostring(current_status)
				)
			)
			_find_destroy_status(comp_no, current_status)
			break -- only need the first component
		end
	end

	-- Strategy 2: if components was empty, use interact_comp.No as comp_no
	if not target_status and interact_comp then
		local ic_no = nil
		pcall(function()
			ic_no = interact_comp.No
		end)
		if ic_no then
			_debug(string.format("  C3: components empty, trying interact_comp.No=%s", tostring(ic_no)))
			_find_destroy_status(ic_no, current_status)
		end
	end

	-- Strategy 3: try entity.No as comp_no
	if not target_status then
		local ent_no = nil
		pcall(function()
			ent_no = entity.No
		end)
		if ent_no then
			_debug(string.format("  C3: trying entity.No=%s", tostring(ent_no)))
			_find_destroy_status(ent_no, current_status)
		end
	end

	if not target_status then
		_log(string.format("  C3: SKIP — no destroy target status found for entity=%s", entity_id))
		AutoLoot._done[entity_id] = true
		return
	end

	_log(string.format("  C3: target_status=%s identifier=%s", tostring(target_status), identifier))

	-- Step 1: Force transit comp status
	local ok1, e1 = pcall(function()
		G.main_player:interact_trans_force_transit_comp_status(entity_id, target_status)
	end)
	if not ok1 then
		_log("  C3: rpc_force_transit_comp_status ERROR: " .. tostring(e1))
		AutoLoot._done[entity_id] = true
		return
	end
	_log("  C3: rpc_force_transit_comp_status sent")

	-- Step 2: Send identifier (signals the drop/interaction completed)
	local ok2, e2 = pcall(function()
		G.net:call_server("rpc_interact_trans_send_identifier", entity_id, identifier)
	end)
	if ok2 then
		_log("  C3: rpc_interact_trans_send_identifier sent")
	else
		_debug("  C3: rpc_interact_trans_send_identifier ERROR: " .. tostring(e2))
	end

	-- Step 3: Upload drop result (entity's current position + yaw)
	local pos_tuple = nil
	local yaw = 0
	pcall(function()
		local p = entity:get_position()
		pos_tuple = { p[1], p[2], p[3] }
	end)
	pcall(function()
		yaw = entity:get_yaw() or 0
	end)

	if pos_tuple then
		local drop_result = Utils.init_dict({ pos = Utils.init_dict(pos_tuple), yaw = yaw })
		local ok3, e3 = pcall(function()
			G.net:call_server("rpc_upload_drop_result", entity_id, drop_result)
		end)
		if ok3 then
			_log("  C3: rpc_upload_drop_result sent")
		else
			_debug("  C3: rpc_upload_drop_result ERROR: " .. tostring(e3))
		end
	end

	AutoLoot._done[entity_id] = true
end

-- ============================================================
-- Main per-entity interaction entry point
-- ============================================================

local function try_interact_entity(entity, interact_misc)
	local entity_id = entity.entity_id

	-- Skip entities already handled this session
	if AutoLoot._done and AutoLoot._done[entity_id] then
		_debug("  skip(done): " .. tostring(entity_id))
		return
	end

	-- Extract current live status + comp_id from interact_comp.components
	-- Try entity method first, then G.space registry as fallback
	local comp_id = nil
	local cur_status_no = nil
	local interact_comp = nil
	pcall(function()
		interact_comp = entity:get_interact_comp()
	end)
	if not interact_comp then
		pcall(function()
			interact_comp = G.space:get_interact_comp(entity_id)
		end)
	end
	if interact_comp and interact_comp.components then
		for cid, comp_data in pairs(interact_comp.components) do
			comp_id = cid
			cur_status_no = comp_data.status_no
			break
		end
	end
	if not comp_id then
		_log("  No comp_id found, using entity_id: " .. tostring(entity_id))
		comp_id = entity_id
	end

	_log(
		string.format(
			"try_interact | entity=%s comp=%s status=%s tag=%s",
			tostring(entity_id),
			tostring(comp_id),
			tostring(cur_status_no),
			Utils.dump_value(entity.tag)
		)
	)
	_debug("  interact_comp=" .. Utils.dump_value(interact_comp))

	if not cur_status_no then
		local interact_data = G.datam.entity_interact:get(entity.No, {})
		if next(interact_data) ~= nil then
			_debug("  entity_interact=" .. Utils.dump_value(interact_data) .. " type=" .. type(interact_data))
			local interaction_reward = interact_data:get("interaction_reward", {})
			_debug("  interaction_reward=" .. Utils.dump_value(interaction_reward))
			if interaction_reward and #interaction_reward > 0 then
				for _, reward in pairs(interaction_reward[1]) do
					_debug("  reward=" .. tostring(reward))
					if G.datam.active_interact_way:get(reward) then
						cur_status_no = reward
						break
					end
				end
			end
		end
		if not cur_status_no then
			-- Check if entity is breakable (TAG_GENERAL_STROKE with no interact data)
			local tag_str = tostring(entity.tag or "")
			if interact_comp and tag_str:find("TAG_GENERAL_STROKE") then
				_break_entity(entity, interact_comp)
				return
			end
			_debug("  skip: no cur_status_no")
			return
		end
	end

	-- Guard: check destroy_status and active_ways from static data
	local ok_status, status_data = pcall(function()
		return G.datam.interact_comp_status:get(cur_status_no, nil)
	end)
	local active_ways = nil
	if ok_status and status_data then
		local destroy_status = nil
		pcall(function()
			destroy_status = status_data:get("destroy_status")
		end)
		if destroy_status == 1 then
			_debug(string.format("  skip: destroy_status=1 for status=%s", cur_status_no))
			AutoLoot._done[entity_id] = true -- remember, stop retrying
			return
		end

		active_ways = status_data:get("active_ways")
		local has_ways = false
		if active_ways then
			pcall(function()
				has_ways = (#active_ways > 0)
			end)
		end
		if not has_ways then
			_debug(string.format("  skip: no active_ways for status=%s", cur_status_no))
			return
		end
		_debug(
			string.format(
				"  status=%s active_ways=%s destroy=%s",
				cur_status_no,
				Utils.dump_value(active_ways),
				tostring(destroy_status)
			)
		)
	else
		_debug(string.format("  WARN: interact_comp_status lookup failed for status=%s", cur_status_no))
	end

	-- Check that active_interact_way data exists for this status
	local way_data = nil
	pcall(function()
		way_data = G.datam.active_interact_way:get(cur_status_no)
		if way_data then
			_debug(string.format("  way_data=%s", Utils.dump_value(way_data)))
		else
			_debug("active_ways: " .. Utils.dump_value(active_ways) .. " type" .. type(active_ways))
			for _, way_no in pairs(active_ways) do
				_debug(" way_no: " .. tostring(way_no))
				way_data = G.datam.active_interact_way:get(way_no)
				if way_data then
					_debug(string.format("  way_data=%s", Utils.dump_value(way_data)))
					cur_status_no = way_no
					break
				end
			end
		end
	end)
	if not way_data then
		_debug(string.format("  skip: no active_interact_way for status=%s", cur_status_no))
		return
	end

	-- Read server_process to determine the correct interaction flow
	local server_process = PROGRESS_NORMAL
	pcall(function()
		server_process = way_data:get("server_process", PROGRESS_NORMAL)
	end)

	-- Battle-state server entities use force-transit instead of active_interact.
	-- Client entities (is_client=true, e.g. treasure boxes) stay on active_interact.
	local enable_battle_state = false
	pcall(function()
		enable_battle_state = way_data:get("enable_battle_state", 0) == 1
	end)
	local is_client = false
	pcall(function()
		is_client = interact_comp and interact_comp.is_client
	end)

	if enable_battle_state and not is_client then
		_force_transit_interact(entity, cur_status_no, comp_id)
		return
	end

	-- Route based on server_process type
	if server_process == PROGRESS_LOCAL then
		_debug(string.format("  skip: server_process=LOCAL (1) for way=%s", cur_status_no))
		return
	elseif server_process == PROGRESS_CLIENT_FIRST then
		-- CLIENT_FIRST (3): send RESULT directly, no START, no wait
		_debug("server_process == PROGRESS_CLIENT_FIRST")
		_direct_result_client_first(entity, cur_status_no, comp_id)
		return
	elseif server_process == PROGRESS_CALL_RESULT then
		_debug("server_process == PROGRESS_CALL_RESULT")

		-- CALL_RESULT (2): send RESULT directly, no START, wait for result_back
		_direct_result_call_result(entity, cur_status_no, comp_id)
		return
	end

	-- PROGRESS_NORMAL (0): full START → RESULT_AND_END handshake
	if AutoLoot._pending then
		_debug(string.format("  skip: pending occupied by %s", AutoLoot._pending.entity_id))
		return
	end
	_start_interact_A(entity, cur_status_no, comp_id)
end

-- ============================================================
-- Core scan
-- ============================================================

function AutoLoot.do_scan()
	local mp = Utils.get_main_player()
	if not mp then
		return false
	end
	mp:ride_skill_collect_nearby_collections(_entity_radius)
	local rewards = mp:ride_skill_find_nearest_kill_reward(_entity_radius)
	if rewards then
		mp:ride_skill_get_kill_reward(rewards)
	end

	_debug("Scanning nearby entities")
	local function filter_ent(ent_id, ent)
		local ent_tag = ent.tag
		if ent_tag:is_collect() or ent_tag:has_stroke_tag() or (ent.if_kill_reward and ent:if_kill_reward()) then
			return true
		end
		_log(string.format("Skipping Entity | id=%s no=%s tag=%s", ent_id, ent.entity_no, Utils.dump_value(ent_tag)))
		return false
	end
	local targets = G.space:get_entities_in_range(G.main_player:get_position(), _entity_radius, nil, filter_ent, true)
	_debug("Total entities in range: " .. tostring(#targets))

	local interact_misc = require("hexm.common.misc.interact_misc")
	for _, t in pairs(targets) do
		_debug(string.format("Entity | id=%s no=%s tag=%s", t.entity_id, t.entity_no, Utils.dump_value(t.tag)))
		local ok, err = pcall(function()
			try_interact_entity(t, interact_misc)
		end)
		if not ok then
			_debug("  pcall error: " .. tostring(err))
		end
	end

	return true
end

-- ============================================================
-- Timer management
-- ============================================================

local function stop_timer()
	if AutoLoot._timer_action then
		pcall(function()
			local scene = cc.Director:getInstance():getRunningScene()
			if scene then
				scene:stopAction(AutoLoot._timer_action)
			end
		end)
		AutoLoot._timer_action = nil
	end
end

local function start_timer()
	stop_timer()
	local scene = nil
	pcall(function()
		scene = cc.Director:getInstance():getRunningScene()
	end)
	if scene then
		AutoLoot._timer_action = cc.RepeatForever:create(cc.Sequence:create({
			cc.DelayTime:create(_scan_interval),
			cc.CallFunc:create(function()
				if AutoLoot._enabled then
					AutoLoot.do_scan()
				end
			end),
		}))
		scene:runAction(AutoLoot._timer_action)
	else
		_log("WARN: No scene found for timer")
	end
end

-- ============================================================
-- Public API
-- ============================================================

function AutoLoot.enable()
	if AutoLoot._enabled then
		_log("Already enabled")
		return true
	end
	AutoLoot._enabled = true
	_log(
		"Enabled (mode="
			.. AutoLoot._interaction_mode
			.. ") — scanning every "
			.. _scan_interval
			.. "s, radius="
			.. _entity_radius
	)
	AutoLoot.do_scan()
	start_timer()
	return true
end

function AutoLoot.disable()
	if not AutoLoot._enabled then
		_log("Already disabled")
		return true
	end
	AutoLoot._enabled = false
	stop_timer()
	_cancel_pending()
	_log("Disabled")
	return true
end

function AutoLoot.is_enabled()
	return AutoLoot._enabled
end

--- Switch interaction mode.
-- mode: "A" (start handshake, default) | "B" (trigger_active_interact, debug)
function AutoLoot.set_mode(mode)
	if mode ~= "A" and mode ~= "B" then
		_log("set_mode: invalid mode '" .. tostring(mode) .. "' — use 'A' or 'B'")
		return
	end
	_cancel_pending()
	AutoLoot._interaction_mode = mode
	_log("Interaction mode → " .. mode)
end

--- Clear the done-cache and any pending state.
-- Use this to retry previously attempted entities in the same game session.
function AutoLoot.reset()
	_cancel_pending()
	AutoLoot._done = {}
	AutoLoot._cache = {}
	_log("State reset — done cache cleared")
end

-- ============================================================
-- Reload guard
-- ============================================================

if AutoLoot._enabled then
	_log("Reload detected while enabled — restarting timer")
	start_timer()
end

return AutoLoot
