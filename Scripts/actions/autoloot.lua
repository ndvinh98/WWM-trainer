-- ============================================================
-- AutoLoot.LUA - Auto Entity Interaction
-- ============================================================
-- Two interaction systems:
--   1. Active Interact: entities with active_ways in their status
--      → RPC protocol routed by server_process (NORMAL/CLIENT_FIRST/CALL_RESULT)
--      → restricted to distance < active_interact_radius (20)
--   2. Status Transition: entities with interact_comp components
--      → force transit comp statuses != default via rpc_force_transit_comp_status
--      → restricted to distance < transit_radius (150)
--
-- Prerequisites: Bootstrap must be loaded first

local ActionBase = _G.Reg.lib("ActionBase")
local AutoLoot = ActionBase:extend("actions.autoloot")
local Serialize = _G.Reg.lib("Serialize")
local gmath = require("hexm.common.math.gmath")
-- ============================================================
-- Constants
-- ============================================================

local PROGRESS_NORMAL = 0
local PROGRESS_LOCAL = 1
local PROGRESS_CALL_RESULT = 2
local PROGRESS_CLIENT_FIRST = 3

-- ============================================================
-- State & Hooks
-- ============================================================

function AutoLoot:define_state()
	return {
		persistent = {
			enabled = false,
			log_enabled = true,
		},
		transient = {
			done = {},
			pending = nil,
			log_cache = {},
			timer_action = nil,
			cache = {},
			done_ttl = 5.0,
			entity_radius = 150,
			active_interact_radius = 20,
			transit_radius = 150,
			scan_interval = 1.0,
		},
	}
end

function AutoLoot:define_hooks()
	return {}
end

-- ============================================================
-- Logging
-- ============================================================

function AutoLoot:_log(msg)
	self:log(msg)
end

function AutoLoot:_debug(msg)
	self:log("[DBG] " .. msg)
end

-- Cached log: only emits once per (entity_id, msg) pair.
-- Prevents log spam from the repeating scan timer.
function AutoLoot:_log_entity(entity_id, msg)
	local cache = self.state.log_cache
	local key = tostring(entity_id)
	if not cache[key] then
		cache[key] = {}
	end
	if not cache[key][msg] then
		cache[key][msg] = true
		self:log(msg)
	end
end

function AutoLoot:_debug_entity(entity_id, msg)
	self:_log_entity(entity_id, "[DBG] " .. msg)
end

function AutoLoot:_now()
	return os.clock()
end

function AutoLoot:_mark_done(entity_id)
	self.state.done[entity_id] = self:_now() + (self.state.done_ttl or 5.0)
end

function AutoLoot:_is_done(entity_id)
	local expires_at = self.state.done[entity_id]
	if not expires_at then
		return false
	end
	if expires_at > self:_now() then
		return true
	end
	self.state.done[entity_id] = nil
	return false
end

function AutoLoot:_prune_done()
	local now = self:_now()
	for entity_id, expires_at in pairs(self.state.done) do
		if expires_at <= now then
			self.state.done[entity_id] = nil
		end
	end
end

-- ============================================================
-- Utility: Distance calculation
-- ============================================================

function AutoLoot:_calc_distance(entity)
	local dist = math.huge
	pcall(function()
		local pp = G.main_player:get_position()
		local ep = entity:get_position()
		local dx = pp.x - (ep[1] or ep.x or 0)
		local dy = pp.y - (ep[2] or ep.y or 0)
		local dz = pp.z - (ep[3] or ep.z or 0)
		dist = math.sqrt(dx * dx + dy * dy + dz * dz)
	end)
	return dist
end

-- ============================================================
-- Utility: Event consts loader
-- ============================================================

function AutoLoot:_get_event_consts()
	local ok, m = pcall(portable.safe_import, "hexm.client.consts.event_consts")
	if ok then
		return m
	end
	self:_debug("WARN: could not load event_consts: " .. tostring(m))
	return nil
end

-- ============================================================
-- Utility: Build interact bd dict for RPC calls
-- ============================================================

function AutoLoot:_build_interact_bd(entity, way_no, comp_id)
	local entity_no = 0
	pcall(function()
		entity_no = entity:get_No() or entity.entity_no or 0
	end)

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

-- ============================================================
-- Pending interaction management
-- ============================================================

function AutoLoot:_cancel_pending()
	local p = self.state.pending
	if not p then
		return
	end
	if p.listener then
		pcall(function()
			HexPlugin.Dispatcher.listener_cancel(p.listener)
		end)
		p.listener = nil
	end
	if p.timeout_action then
		pcall(function()
			local scene = _G.Reg.lib("Cocos").get_running_scene()
			if scene then
				scene:stopAction(p.timeout_action)
			end
		end)
		p.timeout_action = nil
	end
	self.state.pending = nil
end

-- ============================================================
-- Active Interact: START handshake (PROGRESS_NORMAL)
-- Flow: START → wait start_back → RESULT_AND_END
-- ============================================================

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
	self:_mark_done(entity_id)

	if err == 0 then
		local bd = self:_build_interact_bd(entity, way_no, comp_id)
		bd.client_result = true
		self:_debug(string.format("  start_back OK → sending result_and_end | bd=%s", Serialize.dump_value(bd)))

		local ok, e = pcall(function()
			G.net:call_server("rpc_request_active_interact_result_and_end", entity_id, way_no, bd)
		end)
		if ok then
			self:_log("  result_and_end sent OK")
		else
			self:_log("  result_and_end call_server ERROR: " .. tostring(e))
		end
	else
		self:_log(string.format("  start_back FAILED err=%s data=%s — marking done", err, Serialize.dump_value(data)))
	end
end

function AutoLoot:_start_interact(entity, way_no, comp_id)
	local entity_id = entity.entity_id
	if self.state.pending then
		self:_debug(
			string.format("  start_interact: pending occupied by %s, skip %s", self.state.pending.entity_id, entity_id)
		)
		return
	end

	self:_log(string.format("START_INTERACT → entity=%s way=%s comp=%s", entity_id, way_no, comp_id))
	local event_consts = self:_get_event_consts()
	if not event_consts then
		return
	end

	local listener = nil
	local ok, e = pcall(function()
		listener = G.main_player.dispatcher:add(event_consts.E_ACTIVE_INTERACT_REQUEST_START_BACK, function(evt, d)
			self:_on_start_back(evt, d)
		end)
	end)
	if not ok or not listener then
		self:_log("  start_interact: ERROR registering listener: " .. tostring(e))
		return
	end

	local timeout_action = nil
	pcall(function()
		local scene = _G.Reg.lib("Cocos").get_running_scene()
		timeout_action = cc.Sequence:create({
			cc.DelayTime:create(5.0),
			cc.CallFunc:create(function()
				if self.state.pending and self.state.pending.entity_id == entity_id then
					self:_log(string.format("TIMEOUT entity=%s way=%s — marking done", entity_id, way_no))
					self:_cancel_pending()
					self:_mark_done(entity_id)
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
	self:_debug(string.format("  call_server rpc_request_active_interact_start | bd=%s", Serialize.dump_value(bd)))

	local ok2, e2 = pcall(function()
		G.net:call_server("rpc_request_active_interact_start", entity_id, way_no, bd)
	end)
	if not ok2 then
		self:_log("  rpc_request_active_interact_start ERROR: " .. tostring(e2))
		self:_cancel_pending()
		return
	end
	self:_log("  START sent, waiting for start_back…")
end

-- ============================================================
-- Active Interact: Direct RESULT (PROGRESS_CLIENT_FIRST)
-- Fire and forget — no wait for back.
-- ============================================================

function AutoLoot:_direct_result(entity, way_no, comp_id)
	local entity_id = entity.entity_id
	self:_log(string.format("DIRECT_RESULT → entity=%s way=%s comp=%s", entity_id, way_no, comp_id))

	local bd = self:_build_interact_bd(entity, way_no, comp_id)
	bd.client_result = true
	bd.need_result_back = false

	self:_debug(string.format("  call_server rpc_request_active_interact_result | bd=%s", Serialize.dump_value(bd)))

	local ok, e = pcall(function()
		G.net:call_server("rpc_request_active_interact_result", entity_id, way_no, bd)
	end)
	if ok then
		self:_log("  RESULT sent OK (no wait)")
	else
		self:_log("  RESULT ERROR: " .. tostring(e))
	end

	self:_mark_done(entity_id)
end

-- ============================================================
-- Active Interact: RESULT with await (PROGRESS_CALL_RESULT)
-- Send RESULT, wait for result_back via listener.
-- ============================================================

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
	self:_mark_done(entity_id)

	if not result then
		self:_log(string.format("  result_back FAILED data=%s — marking done", Serialize.dump_value(data)))
	end
end

function AutoLoot:_direct_result_await(entity, way_no, comp_id)
	local entity_id = entity.entity_id
	if self.state.pending then
		self:_debug(
			string.format(
				"  direct_result_await: pending occupied by %s, skip %s",
				self.state.pending.entity_id,
				entity_id
			)
		)
		return
	end

	self:_log(string.format("DIRECT_RESULT_AWAIT → entity=%s way=%s comp=%s", entity_id, way_no, comp_id))
	local event_consts = self:_get_event_consts()
	if not event_consts then
		return
	end

	local listener = nil
	local ok, e = pcall(function()
		listener = G.main_player.dispatcher:add(event_consts.E_ACTIVE_INTERACT_REQUEST_RESULT_BACK, function(evt, d)
			self:_on_result_back(evt, d)
		end)
	end)
	if not ok or not listener then
		self:_log("  direct_result_await: ERROR registering result_back listener: " .. tostring(e))
		return
	end

	local timeout_action = nil
	pcall(function()
		local scene = _G.Reg.lib("Cocos").get_running_scene()
		timeout_action = cc.Sequence:create({
			cc.DelayTime:create(5.0),
			cc.CallFunc:create(function()
				if self.state.pending and self.state.pending.entity_id == entity_id then
					self:_log(string.format("TIMEOUT entity=%s way=%s — marking done", entity_id, way_no))
					self:_cancel_pending()
					self:_mark_done(entity_id)
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
	self:_debug(string.format("  call_server rpc_request_active_interact_result | bd=%s", Serialize.dump_value(bd)))

	local ok2, e2 = pcall(function()
		G.net:call_server("rpc_request_active_interact_result", entity_id, way_no, bd)
	end)
	if not ok2 then
		self:_log("  rpc_request_active_interact_result ERROR: " .. tostring(e2))
		self:_cancel_pending()
		return
	end
	self:_log("  RESULT sent, waiting for result_back…")
end

-- ============================================================
-- Status Transition: Force transit comp status
-- For entities without active_ways but with interact components.
-- Follows probe_minigame_nearby.lua pattern:
--   interact_comp.No → entity:get(npc_no) → interact_config
--   → interact_comp_index → loop statuses != default_status_no
--   → rpc_force_transit_comp_status with random ts
-- ============================================================

function AutoLoot:_force_transit_comp_status(entity)
	local entity_id = entity.entity_id
	self:_log_entity(entity_id, string.format("FORCE_TRANSIT → entity=%s", entity_id))

	local interact_comp = nil
	pcall(function()
		interact_comp = G.space:get_interact_comp(entity_id)
	end)
	if not interact_comp then
		self:_debug_entity(entity_id, "  skip: no interact_comp")
		self:_mark_done(entity_id)
		return
	end

	local npc_no = nil
	pcall(function()
		npc_no = interact_comp.No
	end)
	if not npc_no then
		self:_debug_entity(entity_id, "  skip: interact_comp has no No")
		self:_mark_done(entity_id)
		return
	end

	local data = nil
	local interact_config_key = nil
	pcall(function()
		data = G.datam.entity:get(npc_no)
		if data then
			interact_config_key = data:get("interact_config")
		end
	end)
	if not data or not interact_config_key then
		self:_debug_entity(
			entity_id,
			string.format("  skip: no entity data or interact_config for No=%s", tostring(npc_no))
		)
		self:_mark_done(entity_id)
		return
	end

	local interact_config = nil
	local status_list = nil
	pcall(function()
		interact_config = G.datam.interact_comp_index:get(interact_config_key[1])
		if interact_config then
			status_list = interact_config:get("status")
		end
	end)
	if not interact_config or not status_list then
		self:_debug_entity(entity_id, "  skip: no interact_config or status list")
		self:_mark_done(entity_id)
		return
	end

	local default_status = nil
	pcall(function()
		default_status = interact_config:get("default_status_no")
	end)

	self:_log_entity(
		entity_id,
		string.format(
			"  comp_no=%s statuses=%s default=%s",
			tostring(npc_no),
			Serialize.dump_value(status_list),
			tostring(default_status)
		)
	)

	local transited = false
	for _, status_no in pairs(status_list) do
		if status_no ~= default_status then
			local ts = math.random() * 0.4 + 0.1
			self:_log_entity(entity_id, string.format("  → transit to status=%s ts=%.3f", tostring(status_no), ts))
			local ok, e = pcall(function()
				G.net:call_server("rpc_force_transit_comp_status", entity_id, status_no, ts)
			end)
			if ok then
				transited = true
			else
				self:_log_entity(entity_id, "  → rpc ERROR: " .. tostring(e))
			end
		end
	end

	if not transited then
		self:_debug_entity(entity_id, "  no non-default statuses to transit to")
	end
	self:_mark_done(entity_id)
end

-- ============================================================
-- Main per-entity interaction entry point
-- ============================================================

function AutoLoot:try_interact_entity(entity)
	local entity_id = entity.entity_id
	if self:_is_done(entity_id) then
		return
	end

	local comp_id = nil
	local cur_status_no = nil
	local interact_comp = nil
	pcall(function()
		interact_comp = entity:get_interact_comp() or G.space:get_interact_comp(entity_id)
	end)

	if interact_comp and interact_comp.components then
		for cid, comp_data in pairs(interact_comp.components) do
			comp_id = cid
			cur_status_no = comp_data.status_no
			break
		end
	end
	comp_id = comp_id or entity_id
	local dist = gmath.distance(entity:get_position(), G.main_player:get_position())
	self:_debug_entity(
		entity_id,
		string.format(
			"\t[%.1f] try_interact | entity=%s comp=%s status=%s tag=%s",
			dist,
			tostring(entity_id),
			tostring(comp_id),
			tostring(cur_status_no),
			Serialize.dump_value(entity.tag)
		)
	)

	-- Resolve active_ways from status data
	local active_ways = nil
	if cur_status_no then
		pcall(function()
			local status_data = G.datam.interact_comp_status:get(cur_status_no, nil)
			if status_data then
				active_ways = status_data:get("active_ways")
				-- Check if it's already a destroy status — skip
				local destroy_status = status_data:get("destroy_status")
				if destroy_status == 1 then
					self:_debug_entity(
						entity_id,
						string.format("  skip: destroy_status=1 for status=%s", cur_status_no)
					)
					self:_mark_done(entity_id)
					active_ways = nil
					return
				end
			end
		end)
		if self:_is_done(entity_id) then
			return
		end
	end

	-- Also check entity_interact for active_ways if status didn't have them
	if not active_ways or (pcall(function()
		return #active_ways
	end) and #active_ways == 0) then
		if not cur_status_no then
			pcall(function()
				local interact_data = G.datam.entity_interact:get(entity.No, {})
				if next(interact_data) ~= nil then
					local interaction_reward = interact_data:get("interaction_reward", {})
					if interaction_reward and #interaction_reward > 0 then
						for _, reward in pairs(interaction_reward[1]) do
							if G.datam.active_interact_way:get(reward) then
								cur_status_no = reward
								active_ways = { reward }
								break
							end
						end
					end
				end
			end)
		end
	end

	-- Check if we actually have valid active_ways
	local has_active_ways = false
	if active_ways then
		pcall(function()
			has_active_ways = (#active_ways > 0)
		end)
	end

	-- ── BRANCH 1: Active Interact (has active_ways) ──
	if has_active_ways then
		-- Distance gate: must be within active_interact_radius
		local dist = self:_calc_distance(entity)
		if dist > self.state.active_interact_radius then
			-- self:_debug_entity(
			-- 	entity_id,
			-- 	string.format(
			-- 		"  skip: distance=%.1f > active_interact_radius=%s",
			-- 		dist,
			-- 		self.state.active_interact_radius
			-- 	)
			-- )
			return
		end

		-- Resolve way_data
		local way_no = cur_status_no
		local way_data = nil
		pcall(function()
			way_data = G.datam.active_interact_way:get(cur_status_no)
			if not way_data then
				for _, wn in pairs(active_ways) do
					way_data = G.datam.active_interact_way:get(wn)
					if way_data then
						way_no = wn
						break
					end
				end
			end
		end)
		if not way_data then
			self:_debug_entity(entity_id, string.format("  skip: no active_interact_way for status=%s", cur_status_no))
			return
		end

		local server_process = PROGRESS_NORMAL
		pcall(function()
			server_process = way_data:get("server_process", PROGRESS_NORMAL)
		end)

		self:_log_entity(
			entity_id,
			string.format("  ACTIVE_INTERACT entity=%s way=%s server_process=%s", entity_id, way_no, server_process)
		)

		if server_process == PROGRESS_LOCAL then
			self:_debug_entity(entity_id, "  skip: server_process=LOCAL")
			return
		elseif server_process == PROGRESS_CLIENT_FIRST then
			self:_direct_result(entity, way_no, comp_id)
			return
		elseif server_process == PROGRESS_CALL_RESULT then
			self:_direct_result_await(entity, way_no, comp_id)
			return
		else
			-- PROGRESS_NORMAL
			if self.state.pending then
				self:_debug_entity(
					entity_id,
					string.format("  skip: pending occupied by %s", self.state.pending.entity_id)
				)
				return
			end
			self:_start_interact(entity, way_no, comp_id)
			return
		end
	end

	-- ── BRANCH 2: Status Transition (has components, no active_ways) ──
	if interact_comp and interact_comp.components then
		self:_force_transit_comp_status(entity)
		return
	end

	self:_debug_entity(entity_id, "  skip: no active_ways and no components")
end

-- ============================================================
-- Core scan
-- ============================================================

function AutoLoot:do_scan()
	local mp = G.main_player
	if not mp then
		return false
	end
	self:_prune_done()

	-- Pre-filter: use game's own collection APIs
	mp:ride_skill_collect_nearby_collections(self.state.entity_radius)
	local rewards = mp:ride_skill_find_nearest_kill_reward(self.state.entity_radius)
	if rewards then
		mp:ride_skill_get_kill_reward(rewards)
	end

	local function filter_ent(ent_id, ent)
		local ent_tag = ent.tag
		local dist = gmath.distance(ent:get_position(), mp:get_position())

		-- Blacklist: skip entities we never want to auto-interact with
		if
			ent_tag:is_elevator()
			or ent_tag:is_ladder()
			or ent_tag:is_portal()
			or ent_tag:is_task_entity()
			or ent_tag:is_task_npc()
			or ent_tag:is_main_quest_npc()
			or ent_tag:is_scene_entity()
			or ent_tag:is_thruster()
			or ent_tag:is_crane()
			or ent_tag:is_composition_item()
			or ent_tag:is_player()
		then
			self:_debug_entity(
				ent_id,
				string.format("  [%.1f] skip: blacklist %s %s", dist, tostring(ent_tag), tostring(ent))
			)
			return false
		end

		-- Whitelist: collect-type entities
		if
			ent_tag:is_collect()
			or ent_tag:is_collect_tree()
			or ent_tag:is_collect_grass()
			or ent_tag:is_collect_mine()
			or ent_tag:is_collect_animal()
			or ent_tag:is_rare_collect()
			or ent_tag:is_treasure_box()
			or ent_tag:is_chiji_dead_box()
			or ent_tag:is_destruct()
			or (ent.if_kill_reward and ent:if_kill_reward())
		then
			return true
		end

		-- -- custom check
		local ok, err = pcall(function()
			if ent.no then
				local ent_int = G.datam.entity_interact:get(ent.no, {})
				if ent_int and ent_int.interaction_reward then
					return true
				end
			end
		end)
		if ok then
			return true
		end
		self:_debug_entity(
			ent_id,
			string.format("  [%.1f] skip: blacklist %s %s", dist, tostring(ent_tag), tostring(ent))
		)
		return false
	end

	local targets =
		G.space:get_entities_in_range(G.main_player:get_position(), self.state.entity_radius, nil, filter_ent, true)

	for _, t in pairs(targets) do
		local ok, err = pcall(function()
			self:try_interact_entity(t)
		end)
		if not ok then
			local eid = t and t.entity_id or "unknown"
			self:_debug_entity(eid, "  pcall error: " .. tostring(err))
		end
	end
	return true
end

-- ============================================================
-- Timer management
-- ============================================================

function AutoLoot:stop_timer()
	if self.state.timer_action then
		pcall(function()
			local scene = _G.Reg.lib("Cocos").get_running_scene()
			if scene then
				scene:stopAction(self.state.timer_action)
			end
		end)
		self.state.timer_action = nil
	end
end

function AutoLoot:start_timer()
	self:stop_timer()
	local scene = nil
	pcall(function()
		scene = _G.Reg.lib("Cocos").get_running_scene()
	end)
	if scene then
		self.state.timer_action = cc.RepeatForever:create(cc.Sequence:create({
			cc.DelayTime:create(self.state.scan_interval),
			cc.CallFunc:create(function()
				if self.state.enabled then
					self:do_scan()
				end
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
	self:_log(
		string.format(
			"Enabled — scanning every %ss, entity_radius=%s, active_interact_radius=%s, transit_radius=%s",
			self.state.scan_interval,
			self.state.entity_radius,
			self.state.active_interact_radius,
			self.state.transit_radius
		)
	)
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
