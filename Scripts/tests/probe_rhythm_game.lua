-- Scripts/tests/probe_rhythm_game.lua
-- Probe: Discover API shape for rhythm game scoring hooks
-- Run: dofile(_G.SCRIPTS_PATH .. '\\tests\\probe_rhythm_game.lua')

pcall(function()
	local f = io.open(_G.SCRIPTS_PATH .. "\\logs\\probe_rhythm_game.txt", "w")
	if f then
		f:close()
	end
end)

_G.print_file = "probe_rhythm_game.txt"

local function log(msg)
	print("[PROBE_RHYTHM] " .. msg)
end

local function safe(fn, fallback)
	local ok, val = pcall(fn)
	if ok then
		return val
	end
	return fallback
end

-- === PROBE TESTS ===

log(">>> TEST 1: rhythm_game_consts accessible via portable.safe_import")
local ok1, rgc = pcall(portable.safe_import, "hexm.client.consts.rhythm_game_consts")
log(string.format("  result: ok=%s type=%s", tostring(ok1), type(rgc)))

log(">>> TEST 2: note_result_by_time_with_column is a function")
local ok2, fn2 = pcall(function()
	return rgc.note_result_by_time_with_column
end)
log(string.format("  result: ok=%s type=%s val=%s", tostring(ok2), type(fn2), tostring(fn2)))

log(">>> TEST 3: note_result is a function")
local ok3, fn3 = pcall(function()
	return rgc.note_result
end)
log(string.format("  result: ok=%s type=%s val=%s", tostring(ok3), type(fn3), tostring(fn3)))

log(">>> TEST 4: note_result_by_time is a function")
local ok4, fn4 = pcall(function()
	return rgc.note_result_by_time
end)
log(string.format("  result: ok=%s type=%s val=%s", tostring(ok4), type(fn4), tostring(fn4)))

log(">>> TEST 5: NOTE_RESULTS.PERFECT value")
local ok5, val5 = pcall(function()
	return rgc.NOTE_RESULTS.PERFECT
end)
log(string.format("  result: ok=%s type=%s val=%s", tostring(ok5), type(val5), tostring(val5)))

log(">>> TEST 6: NOTE_RESULTS enum values")
local ok6 = pcall(function()
	log(
		string.format(
			"  INACTIVE=%s PASSED=%s MISS=%s NORMAL=%s GOOD=%s PERFECT=%s HOLD=%s",
			tostring(rgc.NOTE_RESULTS.INACTIVE),
			tostring(rgc.NOTE_RESULTS.PASSED),
			tostring(rgc.NOTE_RESULTS.MISS),
			tostring(rgc.NOTE_RESULTS.NORMAL),
			tostring(rgc.NOTE_RESULTS.GOOD),
			tostring(rgc.NOTE_RESULTS.PERFECT),
			tostring(rgc.NOTE_RESULTS.HOLD)
		)
	)
end)

log(">>> TEST 7: get_curr_rhythm_game method on main_player")
local ok7, val7 = pcall(function()
	return G.main_player.get_curr_rhythm_game
end)
log(string.format("  result: ok=%s type=%s val=%s", tostring(ok7), type(val7), tostring(val7)))

log(">>> TEST 8: get_curr_rhythm_game returns nil outside game")
local ok8, val8 = pcall(function()
	return G.main_player:get_curr_rhythm_game()
end)
log(string.format("  result: ok=%s type=%s val=%s", tostring(ok8), type(val8), tostring(val8)))

log(">>> TEST 9: common rhythm_game_consts accessible")
local ok9, rgc_common = pcall(portable.safe_import, "hexm.common.consts.rhythm_game_consts")
log(string.format("  result: ok=%s type=%s", tostring(ok9), type(rgc_common)))

log(">>> TEST 10: cal_result function exists")
local ok10, fn10 = pcall(function()
	return rgc_common.cal_result
end)
log(string.format("  result: ok=%s type=%s val=%s", tostring(ok10), type(fn10), tostring(fn10)))

log(">>> TEST 11: instrument_rhythm_game_data exists in datam")
local ok11, val11 = pcall(function()
	return type(G.datam.instrument_rhythm_game_data)
end)
log(string.format("  result: ok=%s val=%s", tostring(ok11), tostring(val11)))

log(">>> TEST 12: rhythm_game_consts metatable chain (client inherits common)")
local ok12 = pcall(function()
	log(
		string.format("  client.cal_result == common.cal_result: %s", tostring(rgc.cal_result == rgc_common.cal_result))
	)
	log(
		string.format(
			"  client has own note_result_by_time_with_column: %s",
			tostring(rawget(rgc, "note_result_by_time_with_column") ~= nil)
		)
	)
end)

log("\n========== PROBE COMPLETE ==========")
_G.print_file = nil
