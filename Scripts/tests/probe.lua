-- Scripts/tests/probe.lua
-- Probe: Discover archery target entity API shape for remote damage
-- Run: & ".venv\Scripts\python.exe" Scripts/inject/run.py probe
-- Read: Scripts/logs/probe.txt
local function log(msg)
	print("[PROBE_ARCHERY] " .. msg)
end

local function safe(fn, fallback)
	local ok, val = pcall(fn)
	if ok then
		return val
	end
	return fallback
end

local function dump_keys(obj, max_depth, prefix, depth)
	max_depth = max_depth or 1
	prefix = prefix or ""
	depth = depth or 0
	if depth >= max_depth then return end
	local count = 0
	for k, v in pairs(obj) do
		count = count + 1
		if count > 30 then
			log(prefix .. "  ... (truncated)")
			break
		end
		log(prefix .. "  [" .. tostring(k) .. "] = " .. type(v) .. " " .. tostring(v))
	end
end

-- === TEST 1: Find target entities near player ===
log(">>> TEST 1: Find NPC entities in range")
local npcs = safe(function()
	local pos = G.main_player:get_position()
	return G.space:get_entities_in_range_for_npc(pos, 100)
end, {})
log(string.format("  Found %d entities", #(npcs or {})))

-- === TEST 2: For each NPC, check blackboard for yaoyuan_target ===
log(">>> TEST 2: Check blackboard for yaoyuan_target")
local target_nos = {}
local npc_list = {}
for _, npc in pairs(npcs or {}) do
	local npc_no = safe(function() return npc.No end)
	if npc_no then
		local bb = safe(function() return G.datam.entity_blackboard:get(npc_no) end)
		local yt = bb and safe(function() return bb.yaoyuan_target end)
		if yt then
			log(string.format("  NPC No=%s -> yaoyuan_target=%s (id=%s)", tostring(npc_no), tostring(yt), tostring(npc.id)))
			target_nos[yt] = npc.id
			table.insert(npc_list, {npc_no=npc_no, target_no=yt, npc_id=npc.id})
		end
	end
end

-- === TEST 3: Find and inspect target entities ===
log(">>> TEST 3: Find target entities and inspect their API")
local all_ents = safe(function()
	return G.space:get_entities_in_range_for_npc(G.main_player:get_position(), 100)
end, {})

for _, ent in pairs(all_ents or {}) do
	local ent_no = safe(function() return ent.No end)
	if ent_no and target_nos[ent_no] then
		log(string.format("  Found target entity No=%s id=%s", tostring(ent_no), tostring(ent.id)))

		-- Check key methods
		local checks = {
			"fake_server",
			"do_direct_damage",
			"behit",
			"attr_get_HP",
			"attr_get",
			"is_dead",
			"tag",
			"dispatcher",
			"skill_ctrl",
		}
		for _, mname in ipairs(checks) do
			local val = safe(function() return ent[mname] end)
			log(string.format("    ent.%s = %s (%s)", mname, tostring(val), type(val)))
		end

		-- Check fake_server
		local fs = safe(function() return ent.fake_server end)
		if fs then
			log("    -- fake_server found, checking methods:")
			local fs_checks = {
				"do_direct_damage",
				"behit",
				"attr_get_HP",
				"attr_get",
				"is_dead",
				"id",
				"tag",
				"dispatcher",
				"skill_ctrl",
				"space",
			}
			for _, mname in ipairs(fs_checks) do
				local val = safe(function() return fs[mname] end)
				log(string.format("      fs.%s = %s (%s)", mname, tostring(val), type(val)))
			end

			-- Try to get HP
			local hp = safe(function() return fs:attr_get_HP() end)
			log(string.format("      fs:attr_get_HP() = %s", tostring(hp)))
			local hp_max = safe(function() return fs:attr_get("HP_MAX") end)
			log(string.format("      fs:attr_get('HP_MAX') = %s", tostring(hp_max)))
		end

		-- Also check entity directly
		local hp_direct = safe(function() return ent:attr_get_HP() end)
		log(string.format("    ent:attr_get_HP() = %s", tostring(hp_direct)))

		-- Check tag info
		local is_npc = safe(function() return ent.tag:is_npc() end)
		local is_player = safe(function() return ent.tag:is_player() end)
		local is_view_npc = safe(function() return ent.tag:is_view_as_npc() end)
		log(string.format("    tag: is_npc=%s is_player=%s is_view_as_npc=%s",
			tostring(is_npc), tostring(is_player), tostring(is_view_npc)))

		-- Check if entity type suggests it is a combat entity
		local has_buff = safe(function() return ent.buff end)
		log(string.format("    ent.buff = %s (%s)", tostring(has_buff), type(has_buff)))

		-- Only inspect first target
		break
	end
end

-- === TEST 4: Check if DamageManager singleton exists ===
log(">>> TEST 4: DamageManager access")
local dm_ok, dm = pcall(function()
	return require("hexm.common.combat.damage_manager").DamageManager
end)
log(string.format("  DamageManager require: ok=%s type=%s", tostring(dm_ok), type(dm)))
if dm_ok and dm then
	local inst_ok, inst = pcall(function() return dm() end)
	log(string.format("  DamageManager(): ok=%s type=%s", tostring(inst_ok), type(inst)))
end

-- === TEST 5: Check if player has fake_server ===
log(">>> TEST 5: main_player.fake_server")
local mp_fs = safe(function() return G.main_player.fake_server end)
log(string.format("  main_player.fake_server = %s (%s)", tostring(mp_fs), type(mp_fs)))
if mp_fs then
	local mp_fs_id = safe(function() return mp_fs.id end)
	log(string.format("  fake_server.id = %s", tostring(mp_fs_id)))
end

log("\n========== PROBE COMPLETE ==========")
