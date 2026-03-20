-- Scripts/tests/probe_no_cd.lua
-- Probe: Check current hook state and is_skill_in_cd behavior
-- Run: dofile('C:/temp/Where Winds Meet/Scripts/tests/probe_no_cd.lua')

pcall(function()
	local f = io.open("C:/temp/Where Winds Meet/Scripts/logs/probe_no_cd.txt", "w")
	if f then
		f:close()
	end
end)

_G.print_file = "probe_no_cd.txt"

local function log(msg)
	print("[PROBE_NO_CD] " .. msg)
end

local function safe(fn, fallback)
	local ok, val = pcall(fn)
	if ok then
		return val
	end
	return fallback
end

-- === TEST 1: Check if no_cd hooks are currently active ===
log(">>> TEST 1: Hook state")
local HookManager = safe(function()
	return _G.Reg.lib("HookManager")
end)
if HookManager then
	local combat_hooks = HookManager.get_module_hooks("actions.combat")
	for name, entry in pairs(combat_hooks) do
		if name:find("cd") or name:find("cooldown") then
			log(string.format("  hook=%s active=%s", tostring(name), tostring(entry.active)))
		end
	end
	local all_active = HookManager.get_all_active()
	local cd_active = 0
	for key, entry in pairs(all_active) do
		if key:find("cd") or key:find("cooldown") then
			cd_active = cd_active + 1
			log(string.format("  ACTIVE: %s", key))
		end
	end
	log(string.format("  Total CD-related active hooks: %d", cd_active))
else
	log("  HookManager not available")
end

-- === TEST 2: Check G.main_player.is_skill_in_cd ===
log("\n>>> TEST 2: is_skill_in_cd function state")
local mp = safe(function()
	return G.main_player
end)
if mp then
	log(string.format("  G.main_player exists: %s", tostring(mp ~= nil)))
	log(string.format("  type(mp.is_skill_in_cd): %s", type(mp.is_skill_in_cd)))

	-- Check if rawget finds it (rawset patch)
	local raw = rawget(mp, "is_skill_in_cd")
	log(string.format("  rawget(mp, 'is_skill_in_cd'): %s (type=%s)", tostring(raw ~= nil), type(raw)))

	-- Check skill_cds
	local skill_cds = safe(function()
		return mp.skill_cds
	end)
	if skill_cds then
		local count = 0
		pcall(function()
			for k, _ in pairs(skill_cds) do
				count = count + 1
				if count <= 5 then
					log(string.format("  skill_cd[%s] exists", tostring(k)))
				end
			end
		end)
		log(string.format("  Total skill_cds entries: %d", count))
	else
		log("  skill_cds: nil")
	end
else
	log("  G.main_player is nil")
end

-- === TEST 3: Check PlayerAvatarMember class method ===
log("\n>>> TEST 3: PlayerAvatarMember class state")
local ok_imp, imp_mod = pcall(function()
	return portable.safe_import("hexm.client.entities.local.player_avatar_members.imp_skill_cd")
end)
if ok_imp and imp_mod then
	local cls = rawget(imp_mod, "PlayerAvatarMember")
	if cls then
		local method = rawget(cls, "is_skill_in_cd")
		log(string.format("  PlayerAvatarMember.is_skill_in_cd type=%s", type(method)))
		-- Try to get debug info
		if type(method) == "function" then
			local info = debug.getinfo(method, "S")
			log(string.format("  source=%s linedefined=%s", tostring(info.source), tostring(info.linedefined)))
		end
	else
		log("  PlayerAvatarMember class not found in module")
	end
else
	log(string.format("  Failed to import imp_skill_cd: %s", tostring(imp_mod)))
end

-- === TEST 4: Check FakePlayerAvatarMember class method ===
log("\n>>> TEST 4: FakePlayerAvatarMember class state")
local ok_fs, fs_mod = pcall(function()
	return portable.safe_import("hexm.client.fake_server.entities.player_avatar_members.imp_skill_cd")
end)
if ok_fs and fs_mod then
	local cls = rawget(fs_mod, "FakePlayerAvatarMember")
	if cls then
		local method = rawget(cls, "update_skill_cd")
		log(string.format("  FakePlayerAvatarMember.update_skill_cd type=%s", type(method)))
		if type(method) == "function" then
			local info = debug.getinfo(method, "S")
			log(string.format("  source=%s linedefined=%s", tostring(info.source), tostring(info.linedefined)))
		end
	else
		log("  FakePlayerAvatarMember class not found in module")
	end
else
	log(string.format("  Failed to import fake imp_skill_cd: %s", tostring(fs_mod)))
end

-- === TEST 5: Check debug_consts ===
log("\n>>> TEST 5: debug_consts.SKILL_NO_CD")
local ok_dc, dc = pcall(function()
	return portable.safe_import("hexm.common.consts.debug_consts")
end)
if ok_dc and dc then
	log(string.format("  SKILL_NO_CD = %s", tostring(dc.SKILL_NO_CD)))
else
	log("  debug_consts not available")
end

log("\n========== PROBE COMPLETE ==========")
_G.print_file = nil
