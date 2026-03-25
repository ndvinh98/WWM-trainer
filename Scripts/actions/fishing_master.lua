-- Scripts/actions/fishing_master.lua
local ActionBase = _G.Reg.lib("ActionBase")

local FishingMaster = ActionBase:extend("actions.fishing_master")

-- ── Constants ──
local POLL_INTERVAL = 0.5
local THROW_HOLD_TIME = 1.0 -- (max_press=1.6, mid-range)
local RE_THROW_DELAY = 5.0
local GET_FISH_DELAY = 1.0
local GET_FISH_INTERVAL = 0.5

-- Phases
local PHASE_IDLE = "idle"
local PHASE_STARTING = "starting"
local PHASE_THROWING = "throwing"
local PHASE_WAITING_HOOK = "waiting_hook"
local PHASE_GETTING_FISH = "getting_fish"
local PHASE_WAITING_RESULT = "waiting_result"

function FishingMaster:define_state()
	return {
		persistent = { auto_play = false, log_enabled = true },
		transient = {
			log_cache = {},
			_poll_timer = nil,
			_action_timer = nil,
			_phase = PHASE_IDLE,
			_listeners = {}, -- event listener handles
		},
	}
end

function FishingMaster:define_hooks()
	return {
		-- Hook the QTE delete value to always return 0 → progress never decreases
		qte_del = {
			spec = "hexm.client.ui.windows.fish.fish_game_progress_window:FishGameProgressController:get_fish_qte_del_value",
			override_orig_function = true,
			post_exec = function(self_action, original, self_target)
				-- Return 0 so progress never decreases even when outside green zone
				return 0
			end,
		},
		-- Hook the QTE add value to return a large number → progress fills fast
		qte_add = {
			spec = "hexm.client.ui.windows.fish.fish_game_progress_window:FishGameProgressController:get_fish_qte_add_value",
			override_orig_function = true,
			post_exec = function(self_action, original, self_target)
				-- Return large value so progress fills in ~1 tick
				return 100
			end,
		},
	}
end

-- ── Debug Logging ──

function FishingMaster:_dbg(msg)
	if self.state.log_enabled then
		self:log(msg)
	end
end

-- ── Lifecycle ──

function FishingMaster:on_enable()
	self:_dbg("on_enable, auto_play=" .. tostring(self.state.auto_play))
	if self.state.auto_play then
		self:_start_polling()
		self:_register_events()
		self:_activate_hooks()
	end
end

function FishingMaster:on_disable()
	self:_dbg("on_disable")
	self:_cancel_action()
	self:_stop_polling()
	self:_unregister_events()
	self:_deactivate_hooks()
	self.state.auto_play = false
	self.state._phase = PHASE_IDLE
end

function FishingMaster:on_reload()
	self:_dbg("on_reload, auto_play=" .. tostring(self.state.auto_play))
	if self.state.auto_play then
		self:_start_polling()
		self:_register_events()
		self:_activate_hooks()
	end
end

-- ── Private: Hook Management ──

function FishingMaster:_activate_hooks()
	self:_dbg("Activating hooks...")
	local count = 0
	for _, name in ipairs({ "qte_del", "qte_add" }) do
		if not self:is_hooked(name) then
			local ok, err = pcall(self.hook, self, name)
			if ok then
				count = count + 1
				self:_dbg("  " .. name .. " → OK")
			else
				self:_dbg("  " .. name .. " → FAIL: " .. tostring(err))
			end
		else
			count = count + 1
		end
	end
	self:_dbg("Hooks: " .. count .. "/2")
end

function FishingMaster:_deactivate_hooks()
	for _, name in ipairs({ "qte_del", "qte_add" }) do
		if self:is_hooked(name) then
			pcall(self.unhook, self, name)
		end
	end
end

-- ── Private: Event Listeners ──
-- Listen to game events directly on G.main_player.dispatcher
-- This works because server RPCs dispatch events here:
--   rpc_fishing_throw  → E_FISH_THROW_POLE_BACK
--   rpc_fishing_hooked → E_FISH_HOOK_BACK
--   rpc_fishing_send_reward → E_FISH_GAME_RESULT
--   rpc_fishing_back(timeout) → E_FISH_GAME_RESULT / E_FISH_GAME_THROW_FAIL
--   rpc_fishing_finish → E_FISH_GAME_GIVE_UP_BACK

function FishingMaster:_register_events()
	self:_unregister_events()
	self:_dbg("Registering event listeners...")

	local ok, ec = pcall(portable.safe_import, "hexm.client.consts.event_consts")
	if not ok then
		self:_dbg("Failed to import event_consts: " .. tostring(ec))
		return
	end

	local mp = G.main_player
	if not mp or not mp.dispatcher then
		self:_dbg("No main_player dispatcher!")
		return
	end

	local listeners = {}
	local self_ref = self

	-- E_FISH_THROW_POLE_BACK: line is in water, waiting for fish to bite
	local l1 = mp.dispatcher:add(ec.E_FISH_THROW_POLE_BACK, function(event, data)
		self_ref:_dbg("EVENT: E_FISH_THROW_POLE_BACK — line in water")
	end)
	if l1 then
		listeners[#listeners + 1] = l1
	end

	-- E_FISH_HOOK_BACK: fish on hook → start auto-get
	local l2 = mp.dispatcher:add(ec.E_FISH_HOOK_BACK, function(event, data)
		self_ref:_dbg("EVENT: E_FISH_HOOK_BACK — fish hooked!")
		if self_ref.state.auto_play then
			self_ref.state._phase = PHASE_GETTING_FISH
			self_ref:_schedule_get_fish()
		end
	end)
	if l2 then
		listeners[#listeners + 1] = l2
	end

	-- E_FISH_GAME_RESULT: game completed (success or fail)
	local l3 = mp.dispatcher:add(ec.E_FISH_GAME_RESULT, function(event, data)
		local success = "unknown"
		pcall(function()
			if data then
				success = tostring(data.is_success or data:get("is_success"))
			end
		end)
		self_ref:_dbg("EVENT: E_FISH_GAME_RESULT — success=" .. success)
		self_ref:_auto_select_bait()
		if self_ref.state.auto_play then
			self_ref:_cancel_action()
			self_ref.state._phase = PHASE_WAITING_RESULT

			self_ref:_dbg("Scheduling re-throw in " .. RE_THROW_DELAY .. "s")
			self_ref:_schedule_action(RE_THROW_DELAY, function()
				self_ref.state._phase = PHASE_IDLE
				self_ref:_dbg("Re-throw timer: reset to IDLE")
			end)
		end
	end)
	if l3 then
		listeners[#listeners + 1] = l3
	end

	-- E_FISH_GAME_THROW_FAIL: throw failed
	local l4 = mp.dispatcher:add(ec.E_FISH_GAME_THROW_FAIL, function(event, data)
		self_ref:_dbg("EVENT: E_FISH_GAME_THROW_FAIL")
		if self_ref.state.auto_play then
			self_ref:_cancel_action()
			self_ref.state._phase = PHASE_IDLE
		end
	end)
	if l4 then
		listeners[#listeners + 1] = l4
	end

	-- E_FISH_GAME_GIVE_UP_BACK: gave up (but ignore if we already got a result)
	local l5 = mp.dispatcher:add(ec.E_FISH_GAME_GIVE_UP_BACK, function(event, data)
		local phase = self_ref.state._phase
		self_ref:_dbg("EVENT: E_FISH_GAME_GIVE_UP_BACK (phase=" .. phase .. ")")
		if self_ref.state.auto_play and phase ~= PHASE_WAITING_RESULT then
			self_ref:_cancel_action()
			self_ref.state._phase = PHASE_IDLE
		end
	end)
	if l5 then
		listeners[#listeners + 1] = l5
	end

	self.state._listeners = listeners
	self:_dbg("Registered " .. #listeners .. " event listeners")
end

function FishingMaster:_unregister_events()
	local listeners = self.state._listeners
	if listeners and #listeners > 0 then
		for _, handle in ipairs(listeners) do
			pcall(function()
				if handle and handle.cancel then
					handle:cancel()
				elseif handle then
					-- Try alternate removal via dispatcher
					G.main_player.dispatcher:remove(handle)
				end
			end)
		end
		self:_dbg("Unregistered " .. #listeners .. " event listeners")
	end
	self.state._listeners = {}
end

-- ── Private: Polling ──

function FishingMaster:_start_polling()
	self:_stop_polling()
	self:_dbg("Polling ON")

	local poll_count = 0
	local function poll_tick()
		if not self.state.auto_play then
			self:_stop_polling()
			return
		end

		poll_count = poll_count + 1
		local in_fish = self:_check_in_fish_state()
		local phase = self.state._phase

		if poll_count % 10 == 1 then
			self:_dbg(string.format("Poll #%d: fish=%s phase=%s", poll_count, tostring(in_fish), phase))
		end

		if not in_fish then
			if phase ~= PHASE_IDLE then
				self:_dbg("Left fish state, resetting to IDLE")
				self:_cancel_action()
				self.state._phase = PHASE_IDLE
			end
			return
		end

		-- Select bait before every new throw (runs in poll context which is reliable)
		if phase == PHASE_IDLE then
			self:_auto_select_bait()
		end

		-- Drive the state machine
		if phase == PHASE_IDLE then
			self:_do_start_game()
		elseif phase == PHASE_STARTING then
			self:_do_throw()
		end
	end

	self.state._poll_timer = self:_schedule_repeating(POLL_INTERVAL, poll_tick)
end

function FishingMaster:_stop_polling()
	if self.state._poll_timer then
		self:_cancel_timer(self.state._poll_timer)
		self.state._poll_timer = nil
	end
end

-- ── Private: State Machine Actions ──

-- Auto-select the best bait for the current fishing situation.
-- In CONTEST mode: selects bait for the specific current target fish.
-- In NORMAL mode: scores each bait against all fish in the farm.
function FishingMaster:_auto_select_bait()
	local ok, err = pcall(function()
		local se = G.net:get_avatar()
		if not se then
			self:_dbg("Auto-bait: no avatar")
			return
		end

		local mp = G.main_player
		if not mp then
			self:_dbg("Auto-bait: no main_player")
			return
		end

		-- Detect contest mode and get target fish food_habit
		local target_food_habit = nil
		local is_contest = false
		pcall(function()
			if mp.is_in_fishing_contest_game and mp:is_in_fishing_contest_game() then
				is_contest = true
				local handler = mp:get_fish_contest_handler()
				if handler and handler.fishing_contest_sys_d then
					local game_fish_list = handler.fishing_contest_sys_d:get("game_fish_list")
					local process = se.fishing.contest_process or 0
					if process == 0 then
						process = 1
					end
					if game_fish_list and process <= #game_fish_list then
						local target_fish_id = game_fish_list[process]
						local species = G.datam.fishing_species:get(target_fish_id)
						if species then
							target_food_habit = tonumber(tostring(species:get("food_habit")))
							self:_dbg(
								string.format(
									"Contest target: fish=%d step=%d/%d food_habit=%s",
									target_fish_id,
									process,
									#game_fish_list,
									tostring(target_food_habit)
								)
							)
						end
					end
				end
			end
		end)

		-- Build food_habits map
		local food_habits = {}

		if is_contest and target_food_habit then
			-- Contest mode: only score for the specific target fish's food_habit
			food_habits[target_food_habit] = 1
		else
			-- Normal mode: score across all fish in the farm
			local farm_id = mp:get_curr_fish_farm_id()
			if not farm_id then
				self:_dbg("Auto-bait: no farm_id")
				return
			end

			local farm = G.datam.fishing_farm:get(farm_id)
			if not farm then
				self:_dbg("Auto-bait: farm not found id=" .. tostring(farm_id))
				return
			end

			local fish_bank = farm:get("fish_bank")
			if not fish_bank or #fish_bank == 0 then
				self:_dbg("Auto-bait: empty fish_bank farm=" .. tostring(farm_id))
				return
			end

			for i = 1, #fish_bank do
				local bank_id = fish_bank[i][1]
				pcall(function()
					local species_data = G.datam.fishing_species:get(bank_id)
					if species_data then
						local fh = species_data:get("food_habit")
						local fh_num = tonumber(tostring(fh))
						if fh_num then
							food_habits[fh_num] = (food_habits[fh_num] or 0) + 1
						end
					end
				end)
			end
		end

		-- Score each available bait against the food_habits
		local stuff_misc = portable.safe_import("hexm.common.misc.stuff_misc")
		local bait_ids = { 102022, 102023, 102024, 102025, 102026, 102027, 102028 }
		local best_bait = nil
		local best_score = -1

		for _, bait_id in ipairs(bait_ids) do
			local count = stuff_misc.get_stuff_count_by_No(se, bait_id)
			if count and count > 0 then
				local bait_data = G.datam.fishing_bait:get(bait_id)
				if bait_data then
					local fhw = bait_data:get("food_habit_weight")
					if fhw then
						local score = 0
						for j = 1, #fhw do
							local habit_id = fhw[j][1]
							local weight = fhw[j][2]
							if food_habits[habit_id] then
								score = score + weight * food_habits[habit_id]
							end
						end
						if score > best_score then
							best_score = score
							best_bait = bait_id
						end
					end
				end
			end
		end

		-- Apply best bait
		local curr_bait = se:get_fish_choose_bait_no()
		if best_bait then
			if curr_bait ~= best_bait then
				local ec = portable.safe_import("hexm.client.consts.event_consts")
				G.gui_dispatcher:dispatch(ec.E_FISH_CHOOSE_FISH_BAIT, {
					["stuff_no"] = best_bait,
				})
				local label = is_contest and "Contest" or "Farm"
				self:_dbg(
					string.format("Auto-bait (%s): %d → %d (score=%d)", label, curr_bait or 0, best_bait, best_score)
				)
				se._curr_fish_bait_no = best_bait
				se:notify_fish_bait_changed(true)
			else
				self:_dbg(string.format("Auto-bait: already optimal %d", best_bait))
			end
		else
			self:_dbg("Auto-bait: no bait available (curr=" .. tostring(curr_bait) .. ")")
		end
	end)
	if not ok then
		self:_dbg("Auto-bait ERROR: " .. tostring(err))
	end
end

function FishingMaster:_do_start_game()
	local ok, err = pcall(function()
		local mp = G.main_player

		-- Check if already in fishing_core (e.g. after result animation)
		local sub = self:_get_sub_state()
		if sub == "fishing_core" then
			self:_dbg("Already in fishing_core, skip to throw")
			self.state._phase = PHASE_STARTING
			return
		end

		if not mp:check_fish_pole_is_in_hand() then
			self:_dbg("Pole not ready, triggering anim")
			pcall(function()
				mp:try_start_fishing_game()
			end)
			return
		end

		if not mp:check_fish_game_bait_state() then
			self:_dbg("No bait!")
			return
		end

		self:_dbg("try_start_fishing_game()")
		local result = mp:try_start_fishing_game()
		if result then
			self:_dbg("Entered FISHING_CORE → ready to throw")
			self.state._phase = PHASE_STARTING
		end
	end)
	if not ok then
		self:_dbg("_do_start_game ERROR: " .. tostring(err))
	end
end

function FishingMaster:_do_throw()
	local ok, err = pcall(function()
		local sub = self:_get_sub_state()
		if sub ~= "fishing_core" then
			self:_dbg("Not in fishing_core (sub=" .. tostring(sub) .. ")")
			return
		end

		G.main_player:start_fishing_game_btn_end(THROW_HOLD_TIME)
		self.state._phase = PHASE_WAITING_HOOK
		self:_dbg("Throw SENT, waiting for hook event...")
	end)
	if not ok then
		self:_dbg("_do_throw ERROR: " .. tostring(err))
	end
end

function FishingMaster:_schedule_get_fish()
	self:_cancel_action()
	self:_dbg("Auto-get fish starting in " .. GET_FISH_DELAY .. "s")

	local attempt = 0
	local function try_get()
		if self.state._phase ~= PHASE_GETTING_FISH then
			return
		end
		attempt = attempt + 1
		local sub = self:_get_sub_state()
		self:_dbg("get_fish attempt #" .. attempt .. " sub=" .. sub)

		-- Call server RPCs to report max drag progress and request fish
		pcall(function()
			local se = G.net:get_avatar()
			if se and se.server then
				-- Report max drag progress to server
				se.server:rpc_fishing_drag(100)
				-- Request fish catch
				se.server:cli_fishing_get_fish()
			end
		end)

		-- Also try mobile API
		pcall(function()
			G.main_player:mobile_fishing_try_get_final_fish()
		end)

		if attempt < 20 and self.state._phase == PHASE_GETTING_FISH then
			self:_schedule_action(GET_FISH_INTERVAL, try_get)
		else
			self:_dbg("get_fish gave up after " .. attempt .. " attempts")
			self.state._phase = PHASE_IDLE
		end
	end

	self:_schedule_action(GET_FISH_DELAY, try_get)
end

-- ── Private: Helpers ──

function FishingMaster:_get_sub_state()
	local ok, result = pcall(function()
		local curr = G.main_player:get_curr_state()
		if curr and curr.state_game_play and curr.state_game_play.curr_sub_state then
			return curr.state_game_play:curr_sub_state().name
		end
		return "unknown"
	end)
	return ok and result or "error"
end

function FishingMaster:_check_in_fish_state()
	local ok, result = pcall(function()
		return G.main_player:is_in_fish_state()
	end)
	return ok and result == true
end

-- ── Private: Timer Helpers ──

function FishingMaster:_schedule_action(delay, callback)
	self:_cancel_action()
	self.state._action_timer = self:_schedule_once(delay, callback)
end

function FishingMaster:_cancel_action()
	if self.state._action_timer then
		self:_cancel_timer(self.state._action_timer)
		self.state._action_timer = nil
	end
end

function FishingMaster:_schedule_repeating(interval, callback)
	local timer_id = {}
	local function tick()
		if not timer_id.cancelled then
			local ok, err = pcall(callback)
			if not ok then
				self:_dbg("Timer error: " .. tostring(err))
			end
			if not timer_id.cancelled then
				timer_id.handle = self:_schedule_once(interval, tick)
			end
		end
	end
	timer_id.handle = self:_schedule_once(interval, tick)
	return timer_id
end

function FishingMaster:_cancel_timer(timer_id)
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

function FishingMaster:_schedule_once(delay, callback)
	local ok, result = pcall(function()
		if G.main_player and G.main_player.add_timer then
			return G.main_player:add_timer(delay, callback)
		end
	end)
	if ok then
		return result
	end
	self:_dbg("_schedule_once FAILED: " .. tostring(result))
	return nil
end

-- ── Public API ──

function FishingMaster:set_auto_play(enabled)
	self:log("set_auto_play(" .. tostring(enabled) .. ")")
	self.state.auto_play = enabled
	self.state._phase = PHASE_IDLE
	if enabled then
		self:_start_polling()
		self:_register_events()
		self:_activate_hooks()
	else
		self:_cancel_action()
		self:_stop_polling()
		self:_unregister_events()
		self:_deactivate_hooks()
	end
	self:log("Auto-Play: " .. (enabled and "ON" or "OFF"))
end

return FishingMaster:new()
