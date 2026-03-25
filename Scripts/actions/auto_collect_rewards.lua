-- ============================================================
-- AUTO_COLLECT_REWARDS.LUA - Auto-collect all pending rewards
-- ============================================================
-- Polls periodically for uncollected rewards across 11 systems:
--   1. Mail/Email rewards
--   2. Activity center tasks (season guide / daily tasks)
--   3. Battle pass level rewards
--   4. Battle pass task rewards
--   5. Equipment armory progress rewards
--   6. Attendance / sign-in rewards
--   7. Homeland gen-gold order rewards
--   8. Club dungeon rewards
--   9. Activity level-up rewards
--  10. PvP realm grade rewards (zhige realm)
--  11. Task/quest chapter completion rewards
--
-- Uses fire-and-forget RPCs — server handles response via
-- existing callback system. No UI feedback needed.
--
-- Prerequisites: Bootstrap must be loaded first

local ActionBase = _G.Reg.lib("ActionBase")
local AutoCollectRewards = ActionBase:extend("actions.auto_collect_rewards")

-- ============================================================
-- State & Hooks
-- ============================================================

function AutoCollectRewards:define_state()
	return {
		persistent = {
			enabled = false,
			log_enabled = true,
		},
		transient = {
			timer_action = nil,
			scan_interval = 30.0,
			log_cache = {},
		},
	}
end

function AutoCollectRewards:define_hooks()
	return {}
end

-- ============================================================
-- Utility
-- ============================================================

local function safe_import(mod_path)
	local ok, m = pcall(require, mod_path)
	if ok then
		return m
	end
	-- Try portable.safe_import if available
	local portable_ok, portable = pcall(require, "hexm.common.portable")
	if portable_ok and portable and portable.safe_import then
		local ok2, m2 = pcall(portable.safe_import, mod_path)
		if ok2 then
			return m2
		end
	end
	return nil
end

-- ============================================================
-- Collector 1: Mail Rewards
-- ============================================================

function AutoCollectRewards:_collect_mail_rewards()
	local avatar = G.net:get_avatar()
	if not avatar or not avatar.emails then
		return 0
	end

	local mails = avatar.emails._mails
	if not mails then
		return 0
	end

	local eids = {}
	for eid, item in pairs(mails) do
		local ok, should_collect = pcall(function()
			return not item:is_destroyed()
				and item:has_reward()
				and not item:has_receive_reward()
				and item:can_receive_reward()
		end)
		if ok and should_collect then
			eids[#eids + 1] = eid
		end
	end

	if #eids == 0 then
		return 0
	end

	self:log(string.format("Mail: collecting %d reward(s)", #eids))
	local ok, err = pcall(function()
		local grouped = avatar.emails:regroup_eids(eids)
		avatar:email_request_receive_multi_emails_reward(grouped)
	end)
	if not ok then
		self:log("Mail: RPC error: " .. tostring(err))
		return 0
	end
	return #eids
end

-- ============================================================
-- Collector 2: Activity Center Tasks (Season Guide)
-- ============================================================

function AutoCollectRewards:_collect_activity_tasks()
	local season_guide_utils = safe_import("hexm.client.util.season_guide_utils")
	if not season_guide_utils then
		return 0
	end

	local acti_ids = nil
	pcall(function()
		acti_ids = season_guide_utils.get_open_activity_ids()
	end)
	if not acti_ids or #acti_ids == 0 then
		return 0
	end

	local all_task_ids = {}
	for _, acti_id in pairs(acti_ids) do
		pcall(function()
			local task_group_id = G.datam.activity_center_table_data:get(acti_id, {}):get("task_group_id")
			if not task_group_id then
				return
			end
			for _, group_id in pairs(task_group_id) do
				local group_config = G.datam.activity_center_task_group_data:get(group_id, {})
				local taskg_list = group_config:get("taskg_list")
				if taskg_list then
					local _, task_ids = season_guide_utils.claim_reward_by_task_nos(taskg_list, true)
					if task_ids then
						for _, tid in pairs(task_ids) do
							all_task_ids[#all_task_ids + 1] = tid
						end
					end
				end
			end
		end)
	end

	if #all_task_ids == 0 then
		return 0
	end

	self:log(string.format("Activity: collecting %d task reward(s)", #all_task_ids))
	local ok, err = pcall(function()
		G.net:call_server("activity_center_target_reward_receive_batch", all_task_ids)
	end)
	if not ok then
		self:log("Activity: RPC error: " .. tostring(err))
		return 0
	end
	return #all_task_ids
end

-- ============================================================
-- Collector 3: Battle Pass Level Rewards
-- ============================================================

function AutoCollectRewards:_collect_bp_level_rewards()
	local mp = G.main_player
	if not mp then
		return 0
	end

	local has_rewards = false
	pcall(function()
		has_rewards = mp:bp_battle_pass_is_reward_new()
	end)
	if not has_rewards then
		return 0
	end

	self:log("BP Level: collecting all unclaimed level rewards")
	local ok, err = pcall(function()
		G.net:call_server("rpc_bp_battle_pass_reward_all")
	end)
	if not ok then
		self:log("BP Level: RPC error: " .. tostring(err))
		return 0
	end
	return 1
end

-- ============================================================
-- Collector 4: Battle Pass Task Rewards
-- ============================================================

function AutoCollectRewards:_collect_bp_task_rewards()
	local mp = G.main_player
	if not mp then
		return 0
	end

	local claimable_types = {}
	pcall(function()
		claimable_types = mp:bp_battle_pass_any_task_can_draw_reward() or {}
	end)
	if #claimable_types == 0 then
		return 0
	end

	self:log(string.format("BP Tasks: collecting %d task type(s)", #claimable_types))
	local count = 0
	for _, task_type in pairs(claimable_types) do
		local ok, err = pcall(function()
			G.net:call_server("rpc_bp_task_reward_all_type", task_type)
		end)
		if ok then
			count = count + 1
		else
			self:log("BP Tasks: RPC error for type " .. tostring(task_type) .. ": " .. tostring(err))
		end
	end
	return count
end

-- ============================================================
-- Collector 5: Equipment Armory Progress Rewards
-- ============================================================

function AutoCollectRewards:_collect_equip_rewards()
	local ok, err = pcall(function()
		G.net:call_server("equip_box_claim_progress_rewards")
	end)
	if not ok then
		self:log("Equipment: RPC error: " .. tostring(err))
		return 0
	end
	return 1
end

-- ============================================================
-- Collector 6: Attendance / Sign-in Rewards
-- ============================================================

function AutoCollectRewards:_collect_attendance_rewards()
	local mp = G.main_player
	if not mp then
		return 0
	end

	local se = nil
	pcall(function()
		se = mp:get_server_entity()
	end)
	if not se or not se.attendance then
		return 0
	end

	local total_collected = 0
	-- Iterate all attendance batches
	for batch_id, _ in pairs(G.datam.attendance_activity_data or {}) do
		pcall(function()
			local cur_reward_data = se.attendance.day_map:get(batch_id, {}):get("day_state", {})
			local day_ids = {}
			for index, state in pairs(cur_reward_data) do
				if 0 == state then
					day_ids[#day_ids + 1] = index
				end
			end
			if #day_ids > 0 then
				self:log(string.format("Attendance: collecting %d day(s) for batch %s", #day_ids, tostring(batch_id)))
				G.net:call_server("rpc_attendance_reward_batch_by_days", batch_id, day_ids)
				total_collected = total_collected + #day_ids
			end
		end)
	end

	return total_collected
end

-- ============================================================
-- Collector 7: Homeland Gen-Gold Order Rewards
-- ============================================================

function AutoCollectRewards:_collect_homeland_gen_gold()
	local homeland_misc = safe_import("hexm.common.misc.homeland_misc")
	if not homeland_misc or not homeland_misc.gen_gold_has_reward_to_get then
		return 0
	end

	local has_reward = false
	pcall(function()
		has_reward = homeland_misc.gen_gold_has_reward_to_get()
	end)
	if not has_reward then
		return 0
	end

	self:log("Homeland: collecting gen-gold order rewards")
	local ok, err = pcall(function()
		G.net:call_server("rpc_get_homeland_box_gen_gold_reward_all")
	end)
	if not ok then
		self:log("Homeland: RPC error: " .. tostring(err))
		return 0
	end
	return 1
end

-- ============================================================
-- Collector 8: Club Dungeon Rewards
-- ============================================================

function AutoCollectRewards:_collect_club_dungeon_rewards()
	local avatar = G.net:get_avatar()
	if not avatar or not avatar.dungeon then
		return 0
	end

	local has_reward = false
	pcall(function()
		local unclaimed = avatar.dungeon.multi_guard_club_not_claimed_reward
		if unclaimed then
			for _, flag in pairs(unclaimed) do
				if flag > 0 then
					has_reward = true
					break
				end
			end
		end
	end)
	if not has_reward then
		return 0
	end

	self:log("Club Dungeon: collecting unclaimed rewards")
	local ok, err = pcall(function()
		G.net:call_server("rpc_dungeon_claim_all_club_reward")
	end)
	if not ok then
		self:log("Club Dungeon: RPC error: " .. tostring(err))
		return 0
	end
	return 1
end

-- ============================================================
-- Collector 9: Activity Level-up Rewards
-- ============================================================

function AutoCollectRewards:_collect_activity_level_rewards()
	local mp = G.main_player
	if not mp or not mp.check_level_activity_reward then
		return 0
	end

	local task_ids = {}
	pcall(function()
		task_ids = mp:check_level_activity_reward() or {}
	end)
	if #task_ids == 0 then
		return 0
	end

	self:log(string.format("Activity Level: collecting %d level reward(s)", #task_ids))
	local ok, err = pcall(function()
		G.net:call_server("rpc_activity_level_reward", task_ids)
	end)
	if not ok then
		self:log("Activity Level: RPC error: " .. tostring(err))
		return 0
	end
	return #task_ids
end

-- ============================================================
-- Collector 10: PvP Realm Grade Rewards (Zhige Realm)
-- ============================================================

function AutoCollectRewards:_collect_pvp_realm_rewards()
	local zhige_realm_misc = safe_import("hexm.common.misc.zhige_realm_misc")
	if not zhige_realm_misc then
		return 0
	end

	local has_reward = false
	pcall(function()
		has_reward = zhige_realm_misc.zhige_realm_check_is_reward()
	end)
	if not has_reward then
		return 0
	end

	-- Iterate all grades and claim uncollected ones
	local count = 0
	pcall(function()
		local sys = G.datam.zhige_realm_sid_grade
		local avatar = G.net:get_avatar()
		local score = avatar.zhige_realm_prop and avatar.zhige_realm_prop.score or 0
		for i = 1, len(sys) do
			if score >= sys[i].score and sys[i].score > 0 then
				local level = sys[i].stage * 10 + sys[i].lv
				local state = zhige_realm_misc.zhige_realm_get_level_state(level)
				if state == zhige_realm_misc.zhige_realm_level_state_achieve then
					self:log(string.format("PvP Realm: claiming grade reward for level %d", level))
					G.net:call_server("rpc_zhige_realm_get_grade_reward", level)
					count = count + 1
				end
			end
		end
	end)
	return count
end

-- ============================================================
-- Collector 11: Task/Quest Chapter Completion Rewards
-- ============================================================

function AutoCollectRewards:_collect_task_chapter_rewards()
	local avatar = G.net:get_avatar()
	if not avatar or not avatar.tasks_data then
		return 0
	end

	local count = 0
	pcall(function()
		local recv_rewards = avatar.tasks_data.recv_chapter_rewards
		if not recv_rewards then
			return
		end
		local received_list = recv_rewards:all_bits()
		-- Iterate all task groups and find completed but uncollected chapters
		for group_no, group_data in pairs(G.datam.task_group_info or {}) do
			pcall(function()
				-- Only chapters with reward_no can give rewards
				local reward_no = group_data:get("reward_text")
				if not reward_no then
					return
				end
				-- Check if already received
				if received_list:contains(group_no) then
					return
				end
				-- Check if all tasks in this chapter group are finished
				local tasks = group_data:get("task_nos", {})
				if #tasks == 0 then
					return
				end
				local all_done = true
				for _, task_no in pairs(tasks) do
					if not avatar:task_check_finished(task_no) then
						all_done = false
						break
					end
				end
				if all_done then
					self:log(string.format("Task Chapter: claiming reward for group %s", tostring(group_no)))
					G.net:call_server("rpc_receive_finish_chapter_reward", group_no)
					count = count + 1
				end
			end)
		end
	end)
	return count
end

-- ============================================================
-- Core collect loop
-- ============================================================

function AutoCollectRewards:do_collect()
	local mp = G.main_player
	if not mp then
		return
	end

	local collectors = {
		{ name = "mail", fn = self._collect_mail_rewards },
		{ name = "activity", fn = self._collect_activity_tasks },
		{ name = "bp_level", fn = self._collect_bp_level_rewards },
		{ name = "bp_task", fn = self._collect_bp_task_rewards },
		{ name = "equip", fn = self._collect_equip_rewards },
		{ name = "attendance", fn = self._collect_attendance_rewards },
		{ name = "homeland", fn = self._collect_homeland_gen_gold },
		{ name = "club_dungeon", fn = self._collect_club_dungeon_rewards },
		{ name = "activity_level", fn = self._collect_activity_level_rewards },
		{ name = "pvp_realm", fn = self._collect_pvp_realm_rewards },
		{ name = "task_chapter", fn = self._collect_task_chapter_rewards },
	}

	local total = 0
	for _, c in ipairs(collectors) do
		local ok, count = pcall(c.fn, self)
		if ok and count and count > 0 then
			total = total + count
		elseif not ok then
			self:log(string.format("Collector '%s' error: %s", c.name, tostring(count)))
		end
	end

	if total > 0 then
		self:log(string.format("Collected from %d source(s) this cycle", total))
	end
end

-- ============================================================
-- Timer management (same pattern as autoloot.lua)
-- ============================================================

function AutoCollectRewards:stop_timer()
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

function AutoCollectRewards:start_timer()
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
					self:do_collect()
				end
			end),
		}))
		scene:runAction(self.state.timer_action)
	else
		self:log("WARN: No scene found for timer")
	end
end

-- ============================================================
-- Public API
-- ============================================================

function AutoCollectRewards:enable()
	if self.state.enabled then
		self:log("Already enabled")
		return true
	end
	self.state.enabled = true
	self:log(string.format("Enabled — polling every %ss", self.state.scan_interval))
	-- Run one immediate collection, then start the repeating timer
	self:do_collect()
	self:start_timer()
	return true
end

function AutoCollectRewards:disable()
	if not self.state.enabled then
		self:log("Already disabled")
		return true
	end
	self.state.enabled = false
	self:stop_timer()
	self:log("Disabled")
	return true
end

function AutoCollectRewards:is_enabled()
	return self.state.enabled
end

function AutoCollectRewards:collect_now()
	self:do_collect()
end

-- ============================================================
-- Reload guard
-- ============================================================

_G.Reg.lib("Cocos").delay_call(0.5, function()
	local instance = _G.Reg.module("actions.auto_collect_rewards")
	if instance and instance.state.enabled then
		instance:log("Reload detected while enabled — restarting timer")
		instance:start_timer()
	end
end)

return AutoCollectRewards:new()
