-- Scripts/tests/probe_pitchpot.lua
-- Probe: Discover API shape for pitchpot minigame
-- Run: dofile('C:/temp/Where Winds Meet/Scripts/tests/probe_pitchpot.lua')

pcall(function()
	local f = io.open("C:/temp/Where Winds Meet/Scripts/logs/probe_pitchpot.txt", "w")
	if f then
		f:close()
	end
end)

_G.print_file = "probe_pitchpot.txt"

local function log(msg)
	print("[PROBE_PITCHPOT] " .. msg)
end

local function safe(fn, fallback)
	local ok, val = pcall(fn)
	if ok then
		return val
	end
	return fallback
end

-- === PROBE TESTS ===

log(">>> TEST 1: G.main_player exists")
local mp = safe(function()
	return G.main_player
end)
log(string.format("  result: type=%s val=%s", type(mp), tostring(mp)))

log(">>> TEST 2: is_in_pitchpot() method exists and returns false outside game")
local ok2, result2 = pcall(function()
	return G.main_player:is_in_pitchpot()
end)
log(string.format("  result: ok=%s type=%s val=%s", tostring(ok2), type(result2), tostring(result2)))

log(">>> TEST 3: pitchpot_add_score method exists")
local ok3, result3 = pcall(function()
	return G.main_player.pitchpot_add_score
end)
log(string.format("  result: ok=%s type=%s val=%s", tostring(ok3), type(result3), tostring(result3)))

log(">>> TEST 4: get_pitchpot_round_list method exists")
local ok4, result4 = pcall(function()
	return G.main_player.get_pitchpot_round_list
end)
log(string.format("  result: ok=%s type=%s val=%s", tostring(ok4), type(result4), tostring(result4)))

log(">>> TEST 5: pitch_pot property on server entity")
local ok5, result5 = pcall(function()
	local se = G.net:get_avatar()
	return se.pitch_pot
end)
log(string.format("  result: ok=%s type=%s val=%s", tostring(ok5), type(result5), tostring(result5)))

log(">>> TEST 6: pitch_pot.fight_info shape")
local ok6, result6 = pcall(function()
	local fi = G.net:get_avatar().pitch_pot.fight_info
	local shape = string.format(
		"stage_no=%s score=%s combo=%s max_combo=%s hit_times=%s target_type=%s",
		tostring(fi.stage_no),
		tostring(fi.score),
		tostring(fi.combo),
		tostring(fi.max_combo),
		tostring(fi.hit_times),
		tostring(fi.target_type)
	)
	return shape
end)
log(string.format("  result: ok=%s val=%s", tostring(ok6), tostring(result6)))

log(">>> TEST 7: pitch_pot.status value (should be 0=FREE when not in game)")
local ok7, result7 = pcall(function()
	return G.net:get_avatar().pitch_pot.status
end)
log(string.format("  result: ok=%s type=%s val=%s", tostring(ok7), type(result7), tostring(result7)))

log(">>> TEST 8: get_pitch_pot_stage_sysd method exists")
local ok8, result8 = pcall(function()
	return G.main_player.get_pitch_pot_stage_sysd
end)
log(string.format("  result: ok=%s type=%s val=%s", tostring(ok8), type(result8), tostring(result8)))

log(">>> TEST 9: enter_pitchpot method exists")
local ok9, result9 = pcall(function()
	return G.main_player.enter_pitchpot
end)
log(string.format("  result: ok=%s type=%s val=%s", tostring(ok9), type(result9), tostring(result9)))

log(">>> TEST 10: pitchpot_add_score call outside game (should be safe)")
local ok10, result10 = pcall(function()
	-- Don't actually call it outside game, just verify it's callable
	local fn = G.main_player.pitchpot_add_score
	return fn ~= nil
end)
log(string.format("  result: ok=%s type=%s val=%s", tostring(ok10), type(result10), tostring(result10)))

log("\n========== PROBE COMPLETE ==========")
_G.print_file = nil
