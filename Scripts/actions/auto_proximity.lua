-- ============================================================
-- AUTO_PROXIMITY.LUA - Auto AI Proximity Trigger
-- ============================================================
-- Scans nearby NPC entities on a timer, fires AI proximity
-- callbacks for entities that have behavior-tree-driven
-- proximity sensors (entries in proximity_rb_map with AI_ prefix).
--
-- Prerequisites: Bootstrap must be loaded first

local ActionBase = _G.Reg.lib("ActionBase")
local AutoProximity = ActionBase:extend("actions.auto_proximity")

-- ============================================================
-- State & Hooks
-- ============================================================

function AutoProximity:define_state()
	return {
		persistent = {
			enabled = false,
		},
		transient = {
			done = {},
			scan_radius = 200,
			scan_interval = 2.0,
			timer_action = nil,
		},
	}
end

function AutoProximity:define_hooks()
	return {}
end

-- ============================================================
-- Logging
-- ============================================================

function AutoProximity:_log(msg)
	self:log(msg)
end

function AutoProximity:_debug(msg)
	self:log("[DBG] " .. msg)
end

-- ============================================================
-- Core: Extract AI proximity callbacks from an entity
-- ============================================================

function AutoProximity:_get_ai_proximity_callbacks(entity)
	local results = {}
	if not entity then
		return results
	end

	local ok, _ = pcall(function()
		local prox_map = entity.proximity_rb_map
		if not prox_map then
			return
		end
		for pid, config in pairs(prox_map) do
			if type(pid) == "string" and pid:sub(1, 3) == "AI_" then
				local cb = nil
				pcall(function()
					if config.get then
						cb = config:get("callback")
					else
						cb = config.callback
					end
				end)
				if cb and type(cb) == "function" then
					results[#results + 1] = {
						proximity_id = pid,
						callback = cb,
					}
				end
			end
		end
	end)

	return results
end

-- ============================================================
-- Core: Fire AI proximity callbacks for a single entity
-- ============================================================

function AutoProximity:_fire_proximity(entity)
	if not entity then
		return false
	end

	local entity_id = entity.entity_id or entity.id or "unknown"
	local cbs = self:_get_ai_proximity_callbacks(entity)
	if #cbs == 0 then
		return false
	end

	local player_id = G and G.main_player_id or nil
	local fired = 0
	for _, entry in ipairs(cbs) do
		local ok, err = pcall(function()
			entry.callback(player_id, "enter")
		end)
		if ok then
			fired = fired + 1
			self:_log(string.format("Fired %s on entity=%s", entry.proximity_id, tostring(entity_id)))
		else
			self:_debug(
				string.format(
					"Error firing %s on entity=%s: %s",
					entry.proximity_id,
					tostring(entity_id),
					tostring(err)
				)
			)
		end
	end

	self.state.done[tostring(entity_id)] = true
	return fired > 0
end

-- ============================================================
-- Scan: Find and trigger nearby entities
-- ============================================================

function AutoProximity:do_scan()
	if not G then
		return false
	end
	local mp = G.main_player
	if not mp then
		return false
	end

	local function filter_ent(ent_id, ent)
		if self.state.done[tostring(ent_id)] then
			return false
		end
		local ok, is_npc = pcall(function()
			return ent.tag and ent.tag:is_npc()
		end)
		if not ok or not is_npc then
			return false
		end
		local has_prox = false
		pcall(function()
			if ent.proximity_rb_map then
				for pid, _ in pairs(ent.proximity_rb_map) do
					if type(pid) == "string" and pid:sub(1, 3) == "AI_" then
						has_prox = true
						break
					end
				end
			end
		end)
		return has_prox
	end

	local targets = G.space:get_entities_in_range(mp:get_position(), self.state.scan_radius, nil, filter_ent, true)

	local count = 0
	for _, ent in pairs(targets) do
		local ok, err = pcall(function()
			if self:_fire_proximity(ent) then
				count = count + 1
			end
		end)
		if not ok then
			self:_debug("scan error: " .. tostring(err))
		end
	end

	if count > 0 then
		self:_log(string.format("Scan triggered %d entities", count))
	end
	return true
end

-- ============================================================
-- Timer management
-- ============================================================

function AutoProximity:stop_timer()
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

function AutoProximity:start_timer()
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

function AutoProximity:enable()
	if self.state.enabled then
		self:_log("Already enabled")
		return true
	end
	self.state.enabled = true
	self:_log(
		string.format("Enabled — scanning every %ss, radius=%s", self.state.scan_interval, self.state.scan_radius)
	)
	self:do_scan()
	self:start_timer()
	return true
end

function AutoProximity:disable()
	if not self.state.enabled then
		self:_log("Already disabled")
		return true
	end
	self.state.enabled = false
	self:stop_timer()
	self:_log("Disabled")
	return true
end

function AutoProximity:is_enabled()
	return self.state.enabled
end

function AutoProximity:reset()
	self.state.done = {}
	self:_log("State reset — done cache cleared")
end

-- ============================================================
-- Reload guard
-- ============================================================

_G.Reg.lib("Cocos").delay_call(0.5, function()
	local instance = _G.Reg.module("actions.auto_proximity")
	if instance and instance.state.enabled then
		instance:_log("Reload detected while enabled — restarting timer")
		instance:start_timer()
	end
end)

return AutoProximity:new()
