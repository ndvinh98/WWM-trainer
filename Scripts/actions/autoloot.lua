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

local ActionBase = _G.Reg.lib("ActionBase")
local AutoLoot = ActionBase:extend("actions.autoloot")

function AutoLoot:define_state()
	return {
		persistent = {
			enabled = false,
			interaction_mode = "A",
			enable_logging = true,
		},
		transient = {
			done = {},
			pending = nil,
			log_cache = {},
			timer_action = nil,
			cache = {},
			entity_radius = 20,
			scan_interval = 1.0,
		},
	}
end

function AutoLoot:define_hooks()
	return {}
end

local PROGRESS_NORMAL = 0
local PROGRESS_LOCAL = 1
local PROGRESS_CALL_RESULT = 2
local PROGRESS_CLIENT_FIRST = 3

-- ============================================================
-- Logging
-- ============================================================

function AutoLoot:_log(msg)
	if self.state.log_cache[msg] then return end
	self.state.log_cache[msg] = true
	self:log(msg)
end

function AutoLoot:_debug(msg)
	if not self.state.enable_logging then return end
	if self.state.log_cache[msg] then return end
	self.state.log_cache[msg] = true
	self:log("[DBG] " .. msg)
end

function AutoLoot:_get_event_consts()
	local ok, m = pcall(require, "hexm.client.consts.event_consts")
	if ok then return m end
	self:_debug("WARN: could not load event_consts: " .. tostring(m))
	return nil
end

function AutoLoot:_build_interact_bd(entity, way_no, comp_id)
	local entity_no = 0
	pcall(function() entity_no = entity:get_No() or entity.entity_no or 0 end)

	local pos_list = nil
	pcall(function()
		local p = entity:get_position()
		pos_list = { p[1], p[2], p[3] }
	end)

	local way_info = { way_no = way_no, comp_id = comp_id }
	local ClassUtils = require("common.classutils")
	
	local bd = {
		way_info = ClassUtils.CustomMapType(way_info):to_valid_dict(),
		client_No = entity_no,
		target_eid = entity.entity_id,
		client_serial_id = entity.serial_id or 0,
		comp_position = ClassUtils.CustomMapType(pos_list):to_valid_dict(),
	}
	return ClassUtils.CustomMapType(bd):to_valid_dict()
end

-- Cancel any in-flight pending interaction (clean up listener + timeout).
function AutoLoot:_cancel_pending()
	local p = self.state.pending
	if not p then return end
	if p.listener then
		pcall(function() HexPlugin.Dispatcher.listener_cancel(p.listener) end)
		p.listener = nil
	end
	if p.timeout_action then
		pcall(function()
			local scene = _G.Reg.lib("Cocos").get_running_scene()
			if scene then scene:stopAction(p.timeout_action) end
		end)
		p.timeout_action = nil
	end
	self.state.pending = nil
end

-- ============================================================
-- Option A: START handshake callbacks
-- ============================================================

-- Called when E_ACTIVE_INTERACT_REQUEST_START_BACK fires.
-- Event data: { err = <int>, back_data = <dict> }
function AutoLoot:_on_start_back(event, data)
	local p = self.state.pending
	if not p then
		self:_debug("start_back: no pending slot, ignoring")
		return
	end

	local entity_id = p.entity_id
	local way_no = p.way_no
	local comp_id = p.comp_id
	local entity = p.entity
	local err = (data and data.err) or -1

	self:_log(string.format("start_back | entity=%s way=%s err=%s", entity_id, way_no, err))
	self:_cancel_pending()
	self.state.done[entity_id] = true

	if err == 0 then
		local bd = self:_build_interact_bd(entity, way_no, comp_id)
		bd.client_result = true
		local Serialize = _G.Reg.lib("Serialize")
		self:_debug(string.format("  start_back OK → sending result_and_end | bd=%s", Serialize.dump_value(bd)))

		local ok, e = pcall(function()
			G.net:call_server("rpc_request_active_interact_result_and_end", entity_id, way_no, bd)
		end)
		if ok then self:_log("  result_and_end sent OK") else self:_log("  result_and_end call_server ERROR: " .. tostring(e)) end
	else
		local Serialize = _G.Reg.lib("Serialize")
		self:_log(string.format("  start_back FAILED err=%s data=%s — marking done, no retry", err, Serialize.dump_value(data)))
		if self.state.interaction_mode == "B" then
			self:_log("  Fallback-B: trigger_active_interact")
			pcall(function()
				G.main_player:trigger_active_interact(way_no, entity_id, nil, nil, comp_id)
			end)
		end
	end
end

-- Send rpc_request_active_interact_start to the real server for one entity.
function AutoLoot:_start_interact_A(entity, way_no, comp_id)
	local entity_id = entity.entity_id
	if self.state.pending then
		self:_debug(string.format("  A: pending occupied by %s, skip %s", self.state.pending.entity_id, entity_id))
		return
	end

	self:_log(string.format("A: START → entity=%s way=%s comp=%s", entity_id, way_no, comp_id))
	local event_consts = self:_get_event_consts()
	if not event_consts then return end

	local listener = nil
	local ok, e = pcall(function()
		listener = G.main_player.dispatcher:add(event_consts.E_ACTIVE_INTERACT_REQUEST_START_BACK, function(evt, d)
			self:_on_start_back(evt, d)
		end)
	end)
	if not ok or not listener then
		self:_log("  A: ERROR registering listener: " .. tostring(e))
		return
	end

	local timeout_action = nil
	pcall(function()
		local scene = _G.Reg.lib("Cocos").get_running_scene()
		timeout_action = cc.Sequence:create({
			cc.DelayTime:create(5.0),
			cc.CallFunc:create(function()
				if self.state.pending and self.state.pending.entity_id == entity_id then
					self:_log(string.format("A: TIMEOUT entity=%s way=%s — marking done", entity_id, way_no))
					self:_cancel_pending()
					self.state.done[entity_id] = true
				end
			end),
		})
		scene:runAction(timeout_action)
	end)

	self.state.pending = {
		entity_id = entity_id,
		way_no = way_no,
		comp_id = comp_id,
		entity = entity,
		listener = listener,
		timeout_action = timeout_action,
	}

	local bd = self:_build_interact_bd(entity, way_no, comp_id)
	local Serialize = _G.Reg.lib("Serialize")
	self:_debug(string.format("  A: call_server rpc_request_active_interact_start | bd=%s", Serialize.dump_value(bd)))

	local ok2, e2 = pcall(function()
		G.net:call_server("rpc_request_active_interact_start", entity_id, way_no, bd)
	end)
	if not ok2 then
		self:_log("  A: rpc_request_active_interact_start ERROR: " .. tostring(e2))
		self:_cancel_pending()
		return
	end
	self:_log("  A: START sent, waiting for start_back…")
end

function AutoLoot:_start_interact_B(entity, way_no, comp_id)
	local entity_id = entity.entity_id
	self:_log(string.format("B: trigger_active_interact | entity=%s way=%s comp=%s", entity_id, way_no, comp_id))

	local ok, e = pcall(function()
		G.main_player:trigger_active_interact(way_no, entity_id, nil, nil, comp_id)
	end)
	if ok then self:_log("  B: trigger_active_interact called OK") else self:_log("  B: trigger_active_interact ERROR: " .. tostring(e)) end
	self.state.done[entity_id] = true
end

-- ============================================================
-- Option C: Direct RESULT (for non-NORMAL server_process)
-- ============================================================

-- C1: CLIENT_FIRST (3) — fire RESULT, no wait, mark done immediately.
function AutoLoot:_direct_result_client_first(entity, way_no, comp_id)
	local entity_id = entity.entity_id
	self:_log(string.format("C1: CLIENT_FIRST RESULT → entity=%s way=%s comp=%s", entity_id, way_no, comp_id))

	local bd = self:_build_interact_bd(entity, way_no, comp_id)
	bd.client_result = true
	bd.need_result_back = false

	local Serialize = _G.Reg.lib("Serialize")
	self:_debug(string.format("  C1: call_server rpc_request_active_interact_result | bd=%s", Serialize.dump_value(bd)))

	local ok, e = pcall(function()
		G.net:call_server("rpc_request_active_interact_result", entity_id, way_no, bd)
	end)
	if ok then self:_log("  C1: RESULT sent OK (no wait)") else self:_log("  C1: RESULT ERROR: " .. tostring(e)) end

	self.state.done[entity_id] = true
end

function AutoLoot:_on_result_back(event, data)
	local p = self.state.pending
	if not p then
		self:_debug("result_back: no pending slot, ignoring")
		return
	end

	local entity_id = p.entity_id
	local way_no = p.way_no
	local result = data and data.result

	self:_log(string.format("result_back | entity=%s way=%s result=%s", entity_id, way_no, tostring(result)))
	self:_cancel_pending()
	self.state.done[entity_id] = true

	if not result then
		local Serialize = _G.Reg.lib("Serialize")
		self:_log(string.format("  result_back FAILED data=%s — marking done, no retry", Serialize.dump_value(data)))
	end
end

-- C2: CALL_RESULT (2) — send RESULT, wait for result_back via listener.
-- Uses the same pending-slot mechanism as _start_interact_A.
function AutoLoot:_direct_result_call_result(entity, way_no, comp_id)
	local entity_id = entity.entity_id
	if self.state.pending then
		self:_debug(string.format("  C2: pending occupied by %s, skip %s", self.state.pending.entity_id, entity_id))
		return
	end

	self:_log(string.format("C2: CALL_RESULT RESULT → entity=%s way=%s comp=%s", entity_id, way_no, comp_id))
	local event_consts = self:_get_event_consts()
	if not event_consts then return end

	local listener = nil
	local ok, e = pcall(function()
		listener = G.main_player.dispatcher:add(event_consts.E_ACTIVE_INTERACT_REQUEST_RESULT_BACK, function(evt, d)
			self:_on_result_back(evt, d)
		end)
	end)
	if not ok or not listener then
		self:_log("  C2: ERROR registering result_back listener: " .. tostring(e))
		return
	end

	local timeout_action = nil
	pcall(function()
		local scene = _G.Reg.lib("Cocos").get_running_scene()
		timeout_action = cc.Sequence:create({
			cc.DelayTime:create(5.0),
			cc.CallFunc:create(function()
				if self.state.pending and self.state.pending.entity_id == entity_id then
					self:_log(string.format("C2: TIMEOUT entity=%s way=%s — marking done", entity_id, way_no))
					self:_cancel_pending()
					self.state.done[entity_id] = true
				end
			end),
		})
		scene:runAction(timeout_action)
	end)

	self.state.pending = {
		entity_id = entity_id,
		way_no = way_no,
		comp_id = comp_id,
		entity = entity,
		listener = listener,
		timeout_action = timeout_action,
	}

	local bd = self:_build_interact_bd(entity, way_no, comp_id)
	bd.client_result = true
	local Serialize = _G.Reg.lib("Serialize")
	self:_debug(string.format("  C2: call_server rpc_request_active_interact_result | bd=%s", Serialize.dump_value(bd)))

	local ok2, e2 = pcall(function()
		G.net:call_server("rpc_request_active_interact_result", entity_id, way_no, bd)
	end)
	if not ok2 then
		self:_log("  C2: rpc_request_active_interact_result ERROR: " .. tostring(e2))
		self:_cancel_pending()
		return
	end
	self:_log("  C2: RESULT sent, waiting for result_back…")
end

-- ============================================================
-- Option D: Break Entity (for breakable entities with TAG_GENERAL_STROKE)
-- These entities have no active_interact data and empty components.
-- They are destroyed by transitioning to a status with enter_broken_state=1.
-- ============================================================

function AutoLoot:_find_broken_status(comp_no)
	local status_list = nil
	pcall(function() status_list = G.datam.interact_comp_index:get(comp_no, {}):get("status", {}) end)
	if not status_list then return nil end
	local Serialize = _G.Reg.lib("Serialize")
	self:_debug(string.format("  D: comp_no=%s status_list=%s", tostring(comp_no), Serialize.dump_value(status_list)))
	local broken = nil
	pcall(function()
		for i = 1, #status_list do
			local sno = status_list[i]
			local sd = G.datam.interact_comp_status:get(sno, nil)
			if sd and sd:get("enter_broken_state", 0) ~= 0 then
				broken = sno
				return
			end
		end
	end)
	return broken
end

function AutoLoot:_break_entity(entity, interact_comp)
	local entity_id = entity.entity_id
	local ent_no = entity.No
	self:_log(string.format("D: BREAK → entity=%s no=%s", entity_id, tostring(ent_no)))

	local broken_status = nil
	local ic_no = nil
	pcall(function() ic_no = interact_comp and interact_comp.No end)
	if ic_no then broken_status = self:_find_broken_status(ic_no) end
	if not broken_status and ent_no then broken_status = self:_find_broken_status(ent_no) end

	if broken_status then
		self:_log(string.format("  D: broken_status=%s → rpc_force_transit_comp_status", tostring(broken_status)))
		local ts = nil
		pcall(function() ts = DateTimeManager:now() end)
		ts = ts or os.time()
		local ok, e = pcall(function()
			G.net:call_server("rpc_force_transit_comp_status", entity_id, broken_status, ts)
		end)
		if ok then self:_log("  D: rpc_force_transit_comp_status sent") else self:_log("  D: rpc_force_transit_comp_status ERROR: " .. tostring(e)) end
		self.state.done[entity_id] = true
		return
	end

	self:_log("  D: no broken_status, trying wanfa resource damage")
	local lookup_no = ic_no or ent_no
	if not lookup_no then
		self.state.done[entity_id] = true
		return
	end

	local posui_resource_id = nil
	pcall(function()
		local entity_data = G.datam.entity:get(lookup_no, {})
		local value_id = entity_data:get("value_id", 0)
		local value_data = G.datam.entity_value:get(value_id, {})
		posui_resource_id = value_data:get("posui_resource_id")
	end)

	if not posui_resource_id then
		self.state.done[entity_id] = true
		return
	end

	self:_debug(string.format("  D: posui_resource_id=%s", tostring(posui_resource_id)))
	local ClassUtils = require("common.classutils")
	local res2dmg = ClassUtils.CustomMapType({ [posui_resource_id] = -99999 }):to_valid_dict()

	local ok1, e1 = pcall(function()
		local InteractDataManager = require("hexm.common.base.interact_comp.interact_data_manager").InteractDataManager
		local mgr = InteractDataManager()
		mgr:change_client_interact_wanfa_resource(
			interact_comp,
			res2dmg,
			ClassUtils.CustomMapType({ creator_id = G.main_player_id }):to_valid_dict()
		)
	end)
	if ok1 then self:_log("  D: wanfa resource damage applied") else self:_log("  D: wanfa resource damage ERROR: " .. tostring(e1)) end
	self.state.done[entity_id] = true
end

-- ============================================================
-- Option C3: Force Transit (for battle_state / raycast entities)
-- These entities use the interact-comp transit system instead of
-- active_interact RPCs.  Flow: force_transit → send_identifier → upload_drop_result
-- ============================================================

function AutoLoot:_force_transit_interact(entity, way_no, comp_id)
	local entity_id = entity.entity_id
	self:_log(string.format("C3: FORCE_TRANSIT → entity=%s way=%s comp=%s", entity_id, way_no, comp_id))

	local interact_comp = nil
	pcall(function() interact_comp = G.space:get_interact_comp(entity_id) or entity:get_interact_comp() end)

	local target_status = nil
	local identifier = "rb_contact_terrain"
	local current_status = nil

	local function _find_destroy_status(comp_no, skip_status)
		local status_list = nil
		pcall(function() status_list = G.datam.interact_comp_index:get(comp_no, {}):get("status", {}) end)
		if not status_list then return nil end
		local Serialize = _G.Reg.lib("Serialize")
		self:_debug(string.format("  C3: comp_no=%s status_list=%s", tostring(comp_no), Serialize.dump_value(status_list)))
		pcall(function()
			for i = 1, #status_list do
				local sno = status_list[i]
				if sno ~= skip_status then
					local sd = G.datam.interact_comp_status:get(sno, nil)
					if sd and sd:get("destroy_status", nil) == 1 then
						target_status = sno
						identifier = sd:get("entity_stop_send_identifier", identifier)
					end
				end
			end
		end)
		return target_status
	end

	if interact_comp and interact_comp.components then
		for cid, comp_data in pairs(interact_comp.components) do
			current_status = comp_data.status_no
			self:_debug(string.format("  C3: comp cid=%s comp_no=%s status=%s", cid, tostring(comp_data.comp_no), tostring(current_status)))
			_find_destroy_status(comp_data.comp_no, current_status)
			break
		end
	end

	if not target_status and interact_comp then _find_destroy_status(interact_comp.No, current_status) end
	if not target_status then _find_destroy_status(entity.No, current_status) end

	if not target_status then
		self.state.done[entity_id] = true
		return
	end

	self:_log(string.format("  C3: target_status=%s identifier=%s", tostring(target_status), identifier))
	local ok1, e1 = pcall(function() G.main_player:interact_trans_force_transit_comp_status(entity_id, target_status) end)
	if not ok1 then
		self:_log("  C3: rpc_force_transit_comp_status ERROR: " .. tostring(e1))
		self.state.done[entity_id] = true
		return
	end

	pcall(function() G.net:call_server("rpc_interact_trans_send_identifier", entity_id, identifier) end)
	local pos_tuple = nil
	local yaw = 0
	pcall(function()
		local p = entity:get_position()
		pos_tuple = { p[1], p[2], p[3] }
		yaw = entity:get_yaw() or 0
	end)

	if pos_tuple then
		local ClassUtils = require("common.classutils")
		local drop_result = ClassUtils.CustomMapType({ pos = ClassUtils.CustomMapType(pos_tuple):to_valid_dict(), yaw = yaw }):to_valid_dict()
		pcall(function() G.net:call_server("rpc_upload_drop_result", entity_id, drop_result) end)
	end
	self.state.done[entity_id] = true
end

-- ============================================================
-- Main per-entity interaction entry point
-- ============================================================

function AutoLoot:try_interact_entity(entity, interact_misc)
	local entity_id = entity.entity_id
	if self.state.done[entity_id] then
		self:_debug("  skip(done): " .. tostring(entity_id))
		return
	end

	local comp_id = nil
	local cur_status_no = nil
	local interact_comp = nil
	pcall(function() interact_comp = entity:get_interact_comp() or G.space:get_interact_comp(entity_id) end)

	if interact_comp and interact_comp.components then
		for cid, comp_data in pairs(interact_comp.components) do
			comp_id = cid
			cur_status_no = comp_data.status_no
			break
		end
	end
	comp_id = comp_id or entity_id

	local Serialize = _G.Reg.lib("Serialize")
	self:_log(string.format("try_interact | entity=%s comp=%s status=%s tag=%s", tostring(entity_id), tostring(comp_id), tostring(cur_status_no), Serialize.dump_value(entity.tag)))
	self:_debug("  interact_comp=" .. Serialize.dump_value(interact_comp))

	if not cur_status_no then
		local interact_data = G.datam.entity_interact:get(entity.No, {})
		if next(interact_data) ~= nil then
			self:_debug("  entity_interact=" .. Serialize.dump_value(interact_data) .. " type=" .. type(interact_data))
			local interaction_reward = interact_data:get("interaction_reward", {})
			if interaction_reward and #interaction_reward > 0 then
				for _, reward in pairs(interaction_reward[1]) do
					if G.datam.active_interact_way:get(reward) then
						cur_status_no = reward
						break
					end
				end
			end
		end
		if not cur_status_no then
			local tag_str = tostring(entity.tag or "")
			if interact_comp and tag_str:find("TAG_GENERAL_STROKE") then
				self:_break_entity(entity, interact_comp)
				return
			end
			self:_debug("  skip: no cur_status_no")
			return
		end
	end

	local ok_status, status_data = pcall(function() return G.datam.interact_comp_status:get(cur_status_no, nil) end)
	local active_ways = nil
	if ok_status and status_data then
		local destroy_status = nil
		pcall(function() destroy_status = status_data:get("destroy_status") end)
		if destroy_status == 1 then
			self:_debug(string.format("  skip: destroy_status=1 for status=%s", cur_status_no))
			self.state.done[entity_id] = true
			return
		end

		active_ways = status_data:get("active_ways")
		local has_ways = false
		if active_ways then pcall(function() has_ways = (#active_ways > 0) end) end
		if not has_ways then
			self:_debug(string.format("  skip: no active_ways for status=%s", cur_status_no))
			return
		end
		self:_debug(string.format("  status=%s active_ways=%s destroy=%s", cur_status_no, Serialize.dump_value(active_ways), tostring(destroy_status)))
	else
		self:_debug(string.format("  WARN: interact_comp_status lookup failed for status=%s", cur_status_no))
	end

	local way_data = nil
	pcall(function()
		way_data = G.datam.active_interact_way:get(cur_status_no)
		if way_data then
			self:_debug(string.format("  way_data=%s", Serialize.dump_value(way_data)))
		else
			self:_debug("active_ways: " .. Serialize.dump_value(active_ways) .. " type" .. type(active_ways))
			for _, way_no in pairs(active_ways) do
				self:_debug(" way_no: " .. tostring(way_no))
				way_data = G.datam.active_interact_way:get(way_no)
				if way_data then
					self:_debug(string.format("  way_data=%s", Serialize.dump_value(way_data)))
					cur_status_no = way_no
					break
				end
			end
		end
	end)
	if not way_data then
		self:_debug(string.format("  skip: no active_interact_way for status=%s", cur_status_no))
		return
	end

	local server_process = PROGRESS_NORMAL
	pcall(function() server_process = way_data:get("server_process", PROGRESS_NORMAL) end)

	local enable_battle_state = false
	pcall(function() enable_battle_state = way_data:get("enable_battle_state", 0) == 1 end)
	local is_client = false
	pcall(function() is_client = interact_comp and interact_comp.is_client end)

	if enable_battle_state and not is_client then
		self:_force_transit_interact(entity, cur_status_no, comp_id)
		return
	end

	if server_process == PROGRESS_LOCAL then
		self:_debug(string.format("  skip: server_process=LOCAL (1) for way=%s", cur_status_no))
		return
	elseif server_process == PROGRESS_CLIENT_FIRST then
		self:_debug("server_process == PROGRESS_CLIENT_FIRST")
		self:_direct_result_client_first(entity, cur_status_no, comp_id)
		return
	elseif server_process == PROGRESS_CALL_RESULT then
		self:_debug("server_process == PROGRESS_CALL_RESULT")
		self:_direct_result_call_result(entity, cur_status_no, comp_id)
		return
	end

	if self.state.pending then
		self:_debug(string.format("  skip: pending occupied by %s", self.state.pending.entity_id))
		return
	end
	self:_start_interact_A(entity, cur_status_no, comp_id)
end

-- ============================================================
-- Core scan
-- ============================================================

function AutoLoot:do_scan()
	local mp = G.main_player
	if not mp then return false end
	mp:ride_skill_collect_nearby_collections(self.state.entity_radius)
	local rewards = mp:ride_skill_find_nearest_kill_reward(self.state.entity_radius)
	if rewards then mp:ride_skill_get_kill_reward(rewards) end

	self:_debug("Scanning nearby entities")
	local function filter_ent(ent_id, ent)
		local ent_tag = ent.tag
		if ent_tag:is_collect() or ent_tag:has_stroke_tag() or (ent.if_kill_reward and ent:if_kill_reward()) then return true end
		local Serialize = _G.Reg.lib("Serialize")
		self:_log(string.format("Skipping Entity | id=%s no=%s tag=%s", ent_id, ent.entity_no, Serialize.dump_value(ent_tag)))
		return false
	end
	local targets = G.space:get_entities_in_range(G.main_player:get_position(), self.state.entity_radius, nil, filter_ent, true)
	self:_debug("Total entities in range: " .. tostring(#targets))

	local interact_misc = require("hexm.common.misc.interact_misc")
	for _, t in pairs(targets) do
		local Serialize = _G.Reg.lib("Serialize")
		self:_debug(string.format("Entity | id=%s no=%s tag=%s", t.entity_id, t.entity_no, Serialize.dump_value(t.tag)))
		local ok, err = pcall(function() self:try_interact_entity(t, interact_misc) end)
		if not ok then self:_debug("  pcall error: " .. tostring(err)) end
	end
	return true
end

function AutoLoot:stop_timer()
	if self.state.timer_action then
		pcall(function()
			local scene = _G.Reg.lib("Cocos").get_running_scene()
			if scene then scene:stopAction(self.state.timer_action) end
		end)
		self.state.timer_action = nil
	end
end

function AutoLoot:start_timer()
	self:stop_timer()
	local scene = nil
	pcall(function() scene = _G.Reg.lib("Cocos").get_running_scene() end)
	if scene then
		self.state.timer_action = cc.RepeatForever:create(cc.Sequence:create({
			cc.DelayTime:create(self.state.scan_interval),
			cc.CallFunc:create(function()
				if self.state.enabled then self:do_scan() end
			end),
		}))
		scene:runAction(self.state.timer_action)
	else
		self:_log("WARN: No scene found for timer")
	end
end

-- ============================================================
-- Public API
-- ============================================================

function AutoLoot:enable()
	if self.state.enabled then
		self:_log("Already enabled")
		return true
	end
	self.state.enabled = true
	self:_log(string.format("Enabled (mode=%s) — scanning every %ss, radius=%s", self.state.interaction_mode, self.state.scan_interval, self.state.entity_radius))
	self:do_scan()
	self:start_timer()
	return true
end

function AutoLoot:disable()
	if not self.state.enabled then
		self:_log("Already disabled")
		return true
	end
	self.state.enabled = false
	self:stop_timer()
	self:_cancel_pending()
	self:_log("Disabled")
	return true
end

function AutoLoot:is_enabled()
	return self.state.enabled
end

function AutoLoot:set_mode(mode)
	if mode ~= "A" and mode ~= "B" then
		self:_log("set_mode: invalid mode '" .. tostring(mode) .. "' — use 'A' or 'B'")
		return
	end
	self:_cancel_pending()
	self.state.interaction_mode = mode
	self:_log("Interaction mode → " .. mode)
end

function AutoLoot:reset()
	self:_cancel_pending()
	self.state.done = {}
	self.state.cache = {}
	self:_log("State reset — done cache cleared")
end

-- ============================================================
-- Reload guard
-- ============================================================

_G.Reg.lib("Cocos").delay_call(0.5, function()
	local instance = _G.Reg.module("actions.autoloot")
	if instance and instance.state.enabled then
		instance:_log("Reload detected while enabled — restarting timer")
		instance:start_timer()
	end
end)

return AutoLoot:new()
