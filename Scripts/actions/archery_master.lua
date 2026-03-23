-- Scripts/actions/archery_master.lua
local ActionBase = _G.Reg.lib("ActionBase")

local ArcheryMaster = ActionBase:extend("actions.archery_master")
local TypeUtils = _G.Reg.lib("TypeUtils")
-- ── Constants ──
local DEFAULT_SCAN_RANGE = 100 -- meters

-- DataWrapper: minimal object with :get() method for on_arrow_hit event data.
-- The handler calls data:get("hit_info") which requires a :get() method.
-- TypeUtils.init_dict has :get() but can't nest dict-inside-dict.
local DataWrapper = {}
DataWrapper.__index = function(self, key)
	if key == "get" then
		return function(self2, k)
			return rawget(self2, "_data")[k]
		end
	end
	return rawget(self, "_data")[key]
end

local function make_event_data(tbl)
	local obj = {_data = tbl}
	setmetatable(obj, DataWrapper)
	return obj
end

function ArcheryMaster:define_state()
	return {
		persistent = { scan_range = DEFAULT_SCAN_RANGE, log_enabled = true },
		transient = {},
	}
end

function ArcheryMaster:define_hooks()
	return {}
end

-- ── Private: Core Logic ──

function ArcheryMaster:_get_archery_handler()
	local handlers = nil
	pcall(function() handlers = G.main_player._theater_game_handlers[2] end)
	if not handlers then
		return nil
	end
	-- Find active archery handler (any game_no under type 2)
	for game_no, handler in pairs(handlers) do
		local in_game = false
		pcall(function() in_game = handler._in_game end)
		if in_game then
			return handler, game_no
		end
	end
	return nil
end

function ArcheryMaster:_get_yaoyuan_targets(npcs)
	local targets = {}
	local seen = {} -- npc_no -> best entry (closest to player)
	local player_pos = G.main_player:get_position()

	for _, npc in pairs(npcs) do
		local npc_no = nil
		local ok_no, _ = pcall(function()
			npc_no = npc.No
		end)
		if not ok_no or not npc_no then
			goto continue
		end

		-- Look up blackboard data for this NPC No
		local ok_bb, bb_data = pcall(function()
			return G.datam.entity_blackboard:get(npc_no)
		end)
		if not ok_bb or not bb_data then
			goto continue
		end

		-- Check for yaoyuan_target
		local ok_target, target_no = pcall(function()
			return bb_data.yaoyuan_target
		end)

		if ok_target and target_no and target_no ~= npc_no then
			local npc_pos = npc:get_position()
			local dist = cc.pGetDistance(player_pos, npc_pos)

			if not seen[npc_no] or dist < seen[npc_no].dist then
				seen[npc_no] = { target_no = target_no, entity_id = npc.id, dist = dist }
			end
		end

		::continue::
	end

	for npc_no, info in pairs(seen) do
		table.insert(targets, { npc_no = npc_no, target_no = info.target_no, entity_id = info.entity_id })
	end

	return targets
end

function ArcheryMaster:_score_and_kill_targets(target_no, handler)
	local scored = 0

	local ok, err = pcall(function()
		local player_pos = G.main_player:get_position()
		local range = self.state.scan_range

		local entities = G.space:get_entities_in_range_for_npc(player_pos, range)
		if not entities then
			return
		end

		-- Collect unscored bird entity IDs
		local target_eids = {}
		for _, entity in pairs(entities) do
			local ent_no = nil
			pcall(function() ent_no = entity.No end)

			if ent_no and ent_no == target_no then
				-- Skip already-scored targets
				local already = false
				pcall(function()
					already = handler._scored_target_ids:contains(entity.id)
				end)
				if not already then
					table.insert(target_eids, entity.id)
				end
			end
		end

		if #target_eids == 0 then
			self:log("No unscored targets for No=" .. tostring(target_no))
			return
		end

		-- Score each bird via on_arrow_hit (credits _player_score)
		-- Then kill via process_calcpoint_to_eid with PLAYER as attacker
		-- (player attacker = damage only, no NPC score attribution)
		local attacker = G.main_player
		local calc_id = 8702110101

		for _, eid in ipairs(target_eids) do
			-- Step A: Score via on_arrow_hit
			local ok_score, err_score = pcall(function()
				local hit_info = TypeUtils.init_dict({
					["target_id"] = eid,
				})
				local event_data = make_event_data({
					hit_info = hit_info,
				})
				handler:on_arrow_hit("e_bullet_hit", event_data)
			end)

			if ok_score then
				scored = scored + 1
				self:log(string.format("Scored: No=%s eid=%s", tostring(target_no), tostring(eid)))
			else
				self:log(string.format("Score failed: eid=%s err=%s", tostring(eid), tostring(err_score)))
			end

			-- Step B: Kill via damage pipeline (player as attacker)
			pcall(function()
				local params = TypeUtils.init_dict({
					["arrow_dmg"] = true,
				})
				attacker:process_calcpoint_to_eid(calc_id, {eid}, 87021103, params)
			end)
		end
	end)

	if not ok then
		self:log("Score/kill error: " .. tostring(err))
	end

	return scored
end

-- ── Public API ──

function ArcheryMaster:execute()
	self:log("Executing scan (range=" .. self.state.scan_range .. "m)")

	local ok, err = pcall(function()
		-- Step 1: Find active archery handler
		local handler, game_no = self:_get_archery_handler()
		if not handler then
			self:log("No active archery game handler found")
			return
		end
		self:log(string.format("Active handler: game_no=%s player_score=%s npc_score=%s",
			tostring(game_no), tostring(handler._player_score), tostring(handler._npc_score)))

		-- Step 2: Find all NPCs within range
		local player_pos = G.main_player:get_position()
		local range = self.state.scan_range
		local npcs = G.space:get_entities_in_range_for_npc(player_pos, range)
		if not npcs or #npcs == 0 then
			self:log("No NPCs found in range")
			return
		end

		-- Step 3: Find archery targets from blackboard
		local targets = self:_get_yaoyuan_targets(npcs)
		if not targets or #targets == 0 then
			self:log("No archery targets found")
			return
		end

		-- Step 4: Score and kill each target group
		local total_scored = 0
		for _, target_info in ipairs(targets) do
			local n = self:_score_and_kill_targets(target_info.target_no, handler)
			total_scored = total_scored + n
		end

		self:log(string.format("Done: scored %d targets (player=%s npc=%s)",
			total_scored, tostring(handler._player_score), tostring(handler._npc_score)))
	end)

	if not ok then
		self:log("Execute error: " .. tostring(err))
	end
end

return ArcheryMaster:new()
