-- ============================================================
-- AUTOLOOT.LUA - Auto Loot Actions
-- ============================================================
-- Prerequisites: Bootstrap must be loaded first

local AutoLoot = {}

-- Reference libs via Reg (loaded once by bootstrap)
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Utils = Reg.get("Utils")

local function _log(msg)
	Logger.log("[AutoLoot] " .. msg)
end

-- State
AutoLoot._enabled = false
AutoLoot._timer_action = nil

-- Name patterns to ignore (case-insensitive)
local IGNORE_NAME_PATTERNS = {
	"lockpick",
	"lock pick",
	"elevator",
	"elev",
	"mini",
	"minigame",
	"mini-game",
	"puzzle",
	"chess",
	"rhythm",
	"pitch",
	"pitch pot",
	"slot",
	"gacha",
	"lockpicking",
	"lever",
	"sign",
}

local IGNORE_STATUS_IDS = {}
local IGNORE_CONFIG_IDS = {}

local function name_matches_ignore(name)
	if not name then
		return false
	end
	local lname = string.lower(name)
	for _, pat in ipairs(IGNORE_NAME_PATTERNS) do
		if lname:find(pat, 1, true) then
			return true
		end
	end
	return false
end

-- Core loot function
function AutoLoot.do_loot()
	local mp_local = Utils.get_main_player()
	if not mp_local then
		_log("ERROR: main player not found")
		return false
	end

	local interact_misc = Utils.safe_import("hexm.common.misc.interact_misc")

	-- -- 1) Collections
	-- Utils.safe_call("collect", function()
	-- 	mp_local:ride_skill_collect_nearby_collections(5000)
	-- end)

	-- -- 2) Rewards
	-- Utils.safe_call("rewards", function()
	-- 	local rewards = mp_local:ride_skill_find_nearest_kill_reward(5000)
	-- 	if rewards then
	-- 		mp_local:ride_skill_get_kill_reward(rewards)
	-- 	end
	-- end)

	-- 3) Drops (silently skip if DropManager doesn't exist)
	pcall(function()
		if DropManager and DropManager.get_nearby_drop_entities then
			local drops = DropManager.get_nearby_drop_entities(5000)
			if drops then
				for _, eid in ipairs(drops) do
					pcall(function()
						mp_local:pick_drop_item(eid)
					end)
					pcall(function()
						mp_local:pick_reward_item(eid)
					end)
				end
			end
		end
	end)

	-- 4) Interactive entities
	local playerPos = Utils.safe_call("pos", function()
		return mp_local:get_position()
	end)
	if not playerPos then
		playerPos = { x = 0, y = 0, z = 0 }
	end

	local entities = Utils.safe_call("aoi", function()
		return MEntityManager:GetAOIEntities()
	end) or {}
	local targets = {}

	for i = 1, #entities do
		local ent = entities[i]
		local name = Utils.safe_call("name", function()
			return ent:GetName()
		end)
		if name and name:find("InteractComEntity") then
			if name_matches_ignore(name) then
				-- Skip ignored names silently
			else
				local eno = Utils.safe_call("eno", function()
					return ent:GetEntityNo()
				end)
				local eid = ent.entity_id
				if eno and eid and G.space then
					local luaEnt = G.space:get_entity(eid)
					if luaEnt then
						local comp = Utils.safe_call("comp", function()
							return luaEnt:get_interact_comp(eid)
						end)
						if comp and comp.position then
							_log("Found entity: " .. tostring(name))
							local skip = false

							if comp.status_no then
								if type(comp.status_no) == "table" then
									for _, sid in ipairs(comp.status_no) do
										if IGNORE_STATUS_IDS[sid] then
											skip = true
											break
										end
									end
								else
									if IGNORE_STATUS_IDS[comp.status_no] then
										skip = true
									end
								end
							end

							if not skip and comp.config_no then
								if type(comp.config_no) == "table" then
									for _, cid in ipairs(comp.config_no) do
										if IGNORE_CONFIG_IDS[cid] then
											skip = true
											break
										end
									end
								else
									if IGNORE_CONFIG_IDS[comp.config_no] then
										skip = true
									end
								end
							end

							if not skip then
								local dx = playerPos.x - comp.position[1]
								local dy = playerPos.y - comp.position[2]
								local dz = playerPos.z - comp.position[3]
								local dist = math.sqrt(dx * dx + dy * dy + dz * dz)

								local ent_name = name
								local priority = 1
								if ent_name and ent_name:find("ins_entity", 1, true) then
									priority = 0
								end

								if dist < 3 then
									table.insert(targets, {
										entity_no = eno,
										entity_id = eid,
										luaEnt = luaEnt,
										comp = comp,
										distance = dist,
										priority = priority,
									})
								end
							end
						end
					end
				end
			end
		end
	end

	table.sort(targets, function(a, b)
		if a.priority ~= b.priority then
			return a.priority < b.priority
		end
		return a.distance < b.distance
	end)

	for i = 1, #targets do
		local t = targets[i]
		local ways = {}
		local seen = {}

		if interact_misc then
			local possible = Utils.safe_call("ways", function()
				return interact_misc.get_all_possible_active_ways(t.entity_no)
			end)
			if possible then
				for _, w in ipairs(possible) do
					if not seen[w] then
						seen[w] = true
						table.insert(ways, w)
					end
				end
			end
			_log("  Entity " .. tostring(t.entity_id) .. " ways=" .. Utils.dump_value(ways))
		end

		local comp_id = nil
		if t.comp and t.comp.components then
			for cid, comp_data in pairs(t.comp.components) do
				comp_id = cid
				if comp_data.status_no and not seen[comp_data.status_no] then
					seen[comp_data.status_no] = true
					table.insert(ways, comp_data.status_no)
				end
				if comp_data.config_no and not seen[comp_data.config_no] then
					seen[comp_data.config_no] = true
					table.insert(ways, comp_data.config_no)
				end
			end
			_log("  Entity " .. Utils.dump_value(t) .. " ways=" .. Utils.dump_value(ways))
		end
		if #ways > 0 then
			pcall(function()
				mp_local:set_interact_target_id(t.entity_id)
			end)
			for _, way in ipairs(ways) do
				pcall(function()
					mp_local:trigger_active_interact(way, t.entity_id, nil, nil, comp_id)
				end)
			end
			pcall(function()
				mp_local:trigger_active_interact()
			end)
		end
	end

	return true
end

-- Enable auto loot (starts 1s interval loop)
function AutoLoot.enable()
	if AutoLoot._enabled then
		_log("Already enabled")
		return true
	end

	AutoLoot._enabled = true
	_log("Enabled - looting every 1s")

	-- Run once immediately
	AutoLoot.do_loot()

	-- Create repeating action
	local scene = nil
	pcall(function()
		scene = cc.Director:getInstance():getRunningScene()
	end)

	if scene then
		AutoLoot._timer_action = cc.RepeatForever:create(cc.Sequence:create({
			cc.DelayTime:create(1.0),
			cc.CallFunc:create(function()
				if AutoLoot._enabled then
					AutoLoot.do_loot()
				end
			end),
		}))
		scene:runAction(AutoLoot._timer_action)
	else
		_log("WARN: No scene for timer, using fallback")
	end

	return true
end

-- Disable auto loot (stops the loop)
function AutoLoot.disable()
	if not AutoLoot._enabled then
		_log("Already disabled")
		return true
	end

	AutoLoot._enabled = false

	-- Stop the timer action
	if AutoLoot._timer_action then
		pcall(function()
			local scene = cc.Director:getInstance():getRunningScene()
			if scene then
				scene:stopAction(AutoLoot._timer_action)
			end
		end)
		AutoLoot._timer_action = nil
	end

	_log("Disabled")
	return true
end

-- Check if enabled
function AutoLoot.is_enabled()
	return AutoLoot._enabled
end

return AutoLoot
