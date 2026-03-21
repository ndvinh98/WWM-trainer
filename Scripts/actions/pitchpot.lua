-- Scripts/actions/pitchpot.lua
local ActionBase = _G.Reg.lib("ActionBase")

local Pitchpot = ActionBase:extend("actions.pitchpot")

-- ── Constants ──
local POLL_INTERVAL = 0.5 -- seconds between is_in_pitchpot() checks
local DEFAULT_HIT_INTERVAL = 0.5 -- seconds between auto-hit calls

function Pitchpot:define_state()
	return {
		persistent = { auto_play = false, hit_interval = DEFAULT_HIT_INTERVAL },
		transient = { _poll_timer = nil, _fire_timer = nil, _is_firing = false },
	}
end

function Pitchpot:define_hooks()
	return {}
end

-- ── Lifecycle ──

function Pitchpot:on_enable()
	if self.state.auto_play then
		self:_start_polling()
	end
end

function Pitchpot:on_disable()
	self:_stop_firing()
	self:_stop_polling()
	self.state.auto_play = false
end

function Pitchpot:on_reload()
	if self.state.auto_play then
		self:_start_polling()
	end
end

-- ── Private: Polling ──

function Pitchpot:_start_polling()
	self:_stop_polling()
	self:log("Polling started (interval=" .. POLL_INTERVAL .. "s)")

	local function poll_tick()
		if not self.state.auto_play then
			self:_stop_polling()
			return
		end

		local in_game = self:_check_in_pitchpot()
		if in_game and not self.state._is_firing then
			self:_start_firing()
		elseif not in_game and self.state._is_firing then
			self:_stop_firing()
		end
	end

	self.state._poll_timer = self:_schedule_repeating(POLL_INTERVAL, poll_tick)
end

function Pitchpot:_stop_polling()
	if self.state._poll_timer then
		self:_cancel_timer(self.state._poll_timer)
		self.state._poll_timer = nil
		self:log("Polling stopped")
	end
end

-- ── Private: Firing ──

function Pitchpot:_start_firing()
	self:_stop_firing()
	self.state._is_firing = true
	self:log("Auto-fire started (interval=" .. self.state.hit_interval .. "s)")

	local function fire_tick()
		if not self.state.auto_play or not self.state._is_firing then
			self:_stop_firing()
			return
		end

		if not self:_check_in_pitchpot() then
			self:_stop_firing()
			self:log("Pitchpot ended, reverting to polling")
			return
		end

		self:_fire_hit()
	end

	self.state._fire_timer = self:_schedule_repeating(self.state.hit_interval, fire_tick)
end

function Pitchpot:_stop_firing()
	if self.state._fire_timer then
		self:_cancel_timer(self.state._fire_timer)
		self.state._fire_timer = nil
	end
	self.state._is_firing = false
end

-- ── Private: Game Interaction ──

function Pitchpot:_check_in_pitchpot()
	local ok, result = pcall(function()
		return G.main_player:is_in_pitchpot()
	end)
	return ok and result == true
end

function Pitchpot:_fire_hit()
	local ok, err = pcall(function()
		local mp = G.main_player
		local fi = G.net:get_avatar().pitch_pot.fight_info
		local config_id = fi.stage_no
		mp:pitchpot_add_score(true, config_id)
		self:log(
			string.format(
				"Hit fired (config=%s score=%s combo=%s)",
				tostring(config_id),
				tostring(fi.score),
				tostring(fi.combo)
			)
		)
	end)
	if not ok then
		self:log("Hit fire error: " .. tostring(err))
	end
end

-- ── Private: Timer Helpers ──

function Pitchpot:_schedule_repeating(interval, callback)
	local timer_id = {}
	local function tick()
		if not timer_id.cancelled then
			local ok, err = pcall(callback)
			if not ok then
				self:log("Timer error: " .. tostring(err))
			end
			if not timer_id.cancelled then
				timer_id.handle = self:_schedule_once(interval, tick)
			end
		end
	end
	timer_id.handle = self:_schedule_once(interval, tick)
	return timer_id
end

function Pitchpot:_cancel_timer(timer_id)
	if timer_id then
		timer_id.cancelled = true
		if timer_id.handle then
			pcall(function()
				if timer_id.handle.cancel then
					timer_id.handle:cancel()
				end
			end)
		end
	end
end

function Pitchpot:_schedule_once(delay, callback)
	local ok, result = pcall(function()
		if G.main_player and G.main_player.add_timer then
			return G.main_player:add_timer(delay, callback)
		end
	end)
	if ok then
		return result
	end
	return nil
end

-- ── Public API ──

function Pitchpot:set_auto_play(enabled)
	self.state.auto_play = enabled
	if enabled then
		self:_start_polling()
	else
		self:_stop_firing()
		self:_stop_polling()
	end
	self:log("Auto-Play: " .. (enabled and "ON" or "OFF"))
end

return Pitchpot:new()
