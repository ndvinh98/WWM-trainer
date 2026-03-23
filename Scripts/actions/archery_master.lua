-- Scripts/actions/archery_master.lua
local ActionBase = _G.Reg.lib("ActionBase")

local ArcheryMaster = ActionBase:extend("actions.archery_master")

-- ── Constants ──
local DEFAULT_SCAN_RANGE = 100 -- meters

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

function ArcheryMaster:_get_yaoyuan_targets(npcs)
	local targets = {}
	local seen = {}

	for _, npc in pairs(npcs) do
		self:log(string.format("Found archery NPC No=%s Serial No=%s", tostring(npc.No), tostring(npc.serial_id)))
		local npc_no = nil
		local ok_no, _ = pcall(function()
			npc_no = npc.No
		end)
		if not ok_no or not npc_no then
			goto continue
		end

		-- Avoid re-checking the same No
		if seen[npc_no] then
			goto continue
		end
		seen[npc_no] = true

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
			table.insert(targets, { npc_no = npc_no, target_no = target_no, entity_id = npc.id })
			self:log(string.format("Found archery NPC No=%s -> target No=%s entity_id=%s", tostring(npc_no), tostring(target_no), tostring(npc.id)))
		end

		::continue::
	end

	return targets
end

function ArcheryMaster:_destroy_entities_by_no(target_no)
	local destroyed = 0

	local ok, err = pcall(function()
		local player_pos = G.main_player:get_position()
		local range = self.state.scan_range

		-- Find all entities in range
		local entities = G.space:get_entities_in_range_for_npc(player_pos, range)
		if not entities then
			return
		end

		for _, entity in pairs(entities) do
			local ent_no = nil
			pcall(function()
				ent_no = entity.No
			end)

			-- Only destroy entities matching the target No
			if ent_no and ent_no == target_no then
				local eid = entity.id
				local ok_remove, _ = pcall(function()
					G.space:remove_entity(eid, 0) -- ENT_DESTROY_FORCE_IMMEDIATE
				end)
				if ok_remove then
					destroyed = destroyed + 1
					self:log(string.format("Destroyed: No=%s eid=%s", tostring(target_no), tostring(eid)))
				end
			end
		end
	end)

	if not ok then
		self:log("Destroy error: " .. tostring(err))
	end

	return destroyed
end

-- ── Public API ──

function ArcheryMaster:execute()
	self:log("Executing scan (range=" .. self.state.scan_range .. "m)")

	local ok, err = pcall(function()
		local player_pos = G.main_player:get_position()
		local range = self.state.scan_range

		-- Step 1: Find all NPCs within range
		local npcs = G.space:get_entities_in_range_for_npc(player_pos, range)
		if not npcs or #npcs == 0 then
			self:log("No NPCs found in range")
			return
		end

		-- Step 2: For each NPC, check blackboard for yaoyuan_target
		local targets = self:_get_yaoyuan_targets(npcs)
		if not targets or #targets == 0 then
			self:log("No archery targets found")
			return
		end

		-- Step 3: For each target No, find and destroy matching entities
		local total_destroyed = 0
		for _, target_info in ipairs(targets) do
			local destroyed = self:_destroy_entities_by_no(target_info.target_no)
			total_destroyed = total_destroyed + destroyed
		end

		self:log(string.format("Done: destroyed %d targets from %d NPC(s)", total_destroyed, #targets))
	end)

	if not ok then
		self:log("Execute error: " .. tostring(err))
	end
end

return ArcheryMaster:new()
