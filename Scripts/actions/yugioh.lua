-- Scripts/actions/yugioh.lua
local ActionBase = _G.Reg.lib("ActionBase")

local Yugioh = ActionBase:extend("actions.yugioh")

-- ── Constants ──
local REGION_GAME_TYPE_GUIHUO = 8
local DEFAULT_POLL_INTERVAL = 0.5
local DEFAULT_TP_DELAY_MIN = 1
local DEFAULT_TP_DELAY_MAX = 3

function Yugioh:define_state()
	return {
		persistent = {
			auto_play = false,
			log_enabled = true,
			poll_interval = DEFAULT_POLL_INTERVAL,
			tp_delay_min = DEFAULT_TP_DELAY_MIN,
			tp_delay_max = DEFAULT_TP_DELAY_MAX,
		},
		transient = {
			log_cache = {},
			_poll_timer = nil,
			_solve_timer = nil,
			_is_solving = false,
			_current_game_id = nil,
			_saved_pos = nil,
		},
	}
end

function Yugioh:define_hooks()
	return {}
end

-- ── Lifecycle ──

function Yugioh:on_enable()
	if self.state.auto_play then
		self:_start_polling()
	end
end

function Yugioh:on_disable()
	self:_stop_solving()
	self:_stop_polling()
	self.state.auto_play = false
end

function Yugioh:on_reload()
	if self.state.auto_play then
		self:_start_polling()
	end
end

-- ── Private: Polling ──

function Yugioh:_start_polling()
	self:_stop_polling()
	self:log("Polling started (interval=" .. self.state.poll_interval .. "s)")

	local function poll_tick()
		if not self.state.auto_play then
			self:_stop_polling()
			return
		end

		local game_id = self:_find_active_guihuo_game()
		if game_id and not self.state._is_solving then
			self:log("Found active GUIHUO game: " .. tostring(game_id))
			self.state._current_game_id = game_id
			self:_start_solving(game_id)
		elseif not game_id and self.state._is_solving then
			self:log("GUIHUO game ended, stopping solver")
			self:_stop_solving()
		end
	end

	self.state._poll_timer = self:_schedule_repeating(self.state.poll_interval, poll_tick)
end

function Yugioh:_stop_polling()
	if self.state._poll_timer then
		self:_cancel_timer(self.state._poll_timer)
		self.state._poll_timer = nil
		self:log("Polling stopped")
	end
end

-- ── Private: Game Detection ──

function Yugioh:_find_active_guihuo_game()
	local ok, game_id = pcall(function()
		local mp = G.main_player
		if not mp then
			return nil
		end

		-- Use the engine API to find running type-8 games
		local game_ids = mp:get_all_running_region_game_id_by_type(REGION_GAME_TYPE_GUIHUO)
		if game_ids and #game_ids > 0 then
			return game_ids[1]
		end

		return nil
	end)

	if ok and game_id then
		return game_id
	end
	return nil
end

-- ── Private: Solving ──

function Yugioh:_start_solving(game_id)
	self:_stop_solving()
	self.state._is_solving = true

	-- Save player position before teleporting
	local ok_pos, saved = pcall(function()
		return G.main_player:get_position()
	end)
	if ok_pos then
		self.state._saved_pos = saved
	end

	-- Get ghost fire serial IDs
	local ghost_sids = self:_get_ghost_fire_sids(game_id)
	if not ghost_sids or #ghost_sids == 0 then
		self:log("No ghost fire serial IDs found, will retry on next poll")
		self.state._is_solving = false
		return
	end

	self:log("Found " .. #ghost_sids .. " ghost fires, starting teleport sequence")

	-- Start teleporting to each ghost fire sequentially
	self:_teleport_to_next(ghost_sids, 1)
end

function Yugioh:_get_ghost_fire_sids(game_id)
	local ok, sids = pcall(function()
		-- Use player's method to get custom config for this game
		local custom_cfg = G.main_player:get_region_game_custom_config(game_id)
		if not custom_cfg then
			return {}
		end
		local sid_list = custom_cfg:get("t_ghostfire_no_list")
		if not sid_list then
			return {}
		end
		-- Convert engine list to plain Lua table
		local result = {}
		for _, sid in pairs(sid_list) do
			result[#result + 1] = sid
		end
		return result
	end)
	if ok then
		return sids
	end
	self:log("Error getting ghost fire SIDs: " .. tostring(sids))
	return {}
end

function Yugioh:_teleport_to_next(ghost_sids, index)
	if not self.state._is_solving or not self.state.auto_play then
		self:_stop_solving()
		return
	end

	if index > #ghost_sids then
		self:log("All ghost fires visited (" .. #ghost_sids .. "/" .. #ghost_sids .. "), continuing poll")
		-- Don't stop solving yet — let the poll detect game end
		-- Restart from first to keep collecting
		local delay = self:_random_delay()
		self.state._solve_timer = self:_schedule_once(delay, function()
			self:_teleport_to_next(ghost_sids, 1)
		end)
		return
	end

	local sid = ghost_sids[index]
	local ok, err = pcall(function()
		local entity = G.space:get_entity_by_serial_no(sid)
		if entity then
			local pos = entity:get_position()
			if pos then
				G.main_player:set_position(pos)
				self:log(string.format("TP to ghost fire %d/%d (sid=%s)", index, #ghost_sids, tostring(sid)))
			else
				self:log(string.format("Ghost fire %d has no position (sid=%s)", index, tostring(sid)))
			end
		else
			self:log(string.format("Ghost fire entity not found (sid=%s)", tostring(sid)))
		end
	end)
	if not ok then
		self:log("TP error: " .. tostring(err))
	end

	-- Schedule next teleport with random delay
	local delay = self:_random_delay()
	self.state._solve_timer = self:_schedule_once(delay, function()
		self:_teleport_to_next(ghost_sids, index + 1)
	end)
end

function Yugioh:_stop_solving()
	if self.state._solve_timer then
		self:_cancel_timer(self.state._solve_timer)
		self.state._solve_timer = nil
	end
	self.state._is_solving = false
	self.state._current_game_id = nil
end

function Yugioh:_random_delay()
	local min = self.state.tp_delay_min
	local max = self.state.tp_delay_max
	return min + math.random() * (max - min)
end

-- ── Private: Timer Helpers ──

function Yugioh:_schedule_repeating(interval, callback)
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

function Yugioh:_cancel_timer(timer_id)
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

function Yugioh:_schedule_once(delay, callback)
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

function Yugioh:set_auto_play(enabled)
	self.state.auto_play = enabled
	if enabled then
		self:_start_polling()
	else
		self:_stop_solving()
		self:_stop_polling()
	end
	self:log("Auto-Play: " .. (enabled and "ON" or "OFF"))
end

return Yugioh:new()
