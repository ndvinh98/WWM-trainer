-- Scripts/tests/run_all.lua
-- Bootstrap + load action modules + run all test suites
-- Usage: dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_all.lua")
-- Logs output to: C:\temp\Where Winds Meet\Scripts\logs\test_results.txt

local _ROOT = "C:\\temp\\Where Winds Meet\\Scripts"
local LOG_PATH = "C:\\temp\\Where Winds Meet\\Scripts\\logs\\test_results.txt"

-- Capture all print output
local _output = {}
local _orig_print = print

local function _log(...)
	local parts = {}
	for i = 1, select("#", ...) do
		parts[#parts + 1] = tostring(select(i, ...))
	end
	local line = table.concat(parts, "\t")
	_output[#_output + 1] = line
	_orig_print(line)
end

-- Override print temporarily
print = _log

local function _flush()
	local f = io.open(LOG_PATH, "w")
	if f then
		f:write(table.concat(_output, "\n") .. "\n")
		f:close()
	end
end

-- ── Phase 1: Bootstrap ──
_log("\n========================================")
_log("PHASE 1: Bootstrap")
_log("========================================")
local ok, err = pcall(dofile, _ROOT .. "\\lib\\bootstrap.lua")
if not ok then
	_log("BOOTSTRAP FAILED: " .. tostring(err))
	_flush()
	print = _orig_print
	return
end
_log("Bootstrap complete")

-- Re-override print (bootstrap redirects it to Logger)
print = _log

-- ── Phase 2: Load action modules (they self-register via ActionBase:new()) ──
_log("\n========================================")
_log("PHASE 2: Load action modules")
_log("========================================")

local action_files = {
	"buffs",
	"world",
	"combat",
	"xinfa_buffs",
	"weapon_skins",
	"suit_skins",
	"spy",
	"gm_panel",
	"effects",
	"autoloot",
	"parry",
	"sync_observer",
	"parry_online",
	"trace",
	"dump_bytecode",
	"dump_static_data",
	"anticheat_bypass",
	"skill_unrestrict",
	"pitchpot",
	"rhythm_game",
	"archery_master",
	"fishing_master",
}

local function load_action_modules()
	local ok_count, fail_count = 0, 0
	for _, name in ipairs(action_files) do
		local path = _ROOT .. "\\actions\\" .. name .. ".lua"
		local aok, aerr = pcall(dofile, path)
		if aok then
			ok_count = ok_count + 1
			_log("  LOADED: " .. name)
		else
			fail_count = fail_count + 1
			_log("  FAIL:   " .. name .. " -- " .. tostring(aerr))
		end
	end
	return ok_count, fail_count
end

local load_ok, load_fail = load_action_modules()
_log(string.format("Modules: %d loaded, %d failed", load_ok, load_fail))

-- ── Phase 3: Run test suites ──
_log("\n========================================")
_log("PHASE 3: Run tests")
_log("========================================")

local test_suites = {
	"test_bootstrap",
	"test_hook_manager",
	"test_action_base",
	"test_buffs",
	"test_world",
	"test_combat",
	"test_gm_panel",
	"test_effects",
	"test_autoloot",
	"test_parry",
	"test_sync_observer",
	"test_menu_config",
	"test_ui_components",
	"test_parry_online",
	"test_ui_apply",
	"test_reload",
	"test_suit_skins",
	"test_weapon_skins",
	"test_xinfa_buffs",
	"test_spy",
	"test_dump_bytecode",
	"test_dump_static_data",
	"test_trace",
	"test_anticheat_bypass",
	"test_skill_unrestrict",
	"test_pitchpot",
	"test_rhythm_game",
	"test_target_shoot",
	"test_archery_master",
	"test_fishing_master",
}

local suite_ok, suite_fail = 0, 0
for _, name in ipairs(test_suites) do
	_log("\n--- " .. name .. " ---")
	local start_index = #_output + 1
	local tok, terr = pcall(dofile, _ROOT .. "\\tests\\" .. name .. ".lua")
	local suite_failed_count = nil
	local fail_line_count = 0
	for i = #_output, start_index, -1 do
		if _output[i]:match("^FAIL: ") then
			fail_line_count = fail_line_count + 1
		end
		local passed, failed = _output[i]:match("^=== RESULTS: (%d+) passed, (%d+) failed ===$")
		if passed and failed then
			suite_failed_count = tonumber(failed)
		end
	end
	suite_failed_count = math.max(suite_failed_count or 0, fail_line_count)

	if tok and suite_failed_count == 0 then
		suite_ok = suite_ok + 1
	else
		suite_fail = suite_fail + 1
		if not tok then
			_log("SUITE ERROR: " .. name .. " -- " .. tostring(terr))
		else
			_log("SUITE FAILED: " .. name .. " -- " .. tostring(suite_failed_count) .. " test(s) failed")
		end
	end

	if name == "test_reload" then
		_log("  RELOADING: action modules after test_reload")
		local reload_ok, reload_fail = load_action_modules()
		load_ok = reload_ok
		load_fail = reload_fail
	end
end

-- ── Final Summary ──
_log("\n========================================")
_log(string.format("FINAL: %d suites passed, %d suites failed", suite_ok, suite_fail))
_log(string.format("       %d modules loaded, %d modules failed", load_ok, load_fail))
if suite_fail == 0 and load_fail == 0 then
	_log("ALL GREEN")
else
	_log("ISSUES FOUND - see above")
end
_log("========================================")

-- Restore print and flush
print = _orig_print
_flush()
