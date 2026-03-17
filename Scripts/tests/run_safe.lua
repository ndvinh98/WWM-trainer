-- run_safe.lua: pcall wrapper that writes all output to a log file
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

-- Phase 1: Bootstrap
_log("=== PHASE 1: Bootstrap ===")
local ok, err = pcall(dofile, "C:\\temp\\Where Winds Meet\\Scripts\\lib\\bootstrap.lua")
if not ok then
    _log("BOOTSTRAP FAILED: " .. tostring(err))
    _flush()
    print = _orig_print
    return
end
_log("Bootstrap: OK")

-- Re-override print (bootstrap redirects it to Logger)
print = _log

-- Phase 2: Load action modules
_log("\n=== PHASE 2: Load Modules ===")
local actions = { "buffs", "world", "combat", "xinfa_buffs", "weapon_skins", "spy", "gm_panel" }
local load_ok, load_fail = 0, 0
for _, name in ipairs(actions) do
    local path = "C:\\temp\\Where Winds Meet\\Scripts\\actions\\" .. name .. ".lua"
    local aok, aerr = pcall(dofile, path)
    if aok then
        load_ok = load_ok + 1
        _log("  LOADED: " .. name)
    else
        load_fail = load_fail + 1
        _log("  FAIL: " .. name .. " -> " .. tostring(aerr))
    end
end
_log(string.format("Modules: %d ok, %d fail", load_ok, load_fail))

-- Phase 3: Run test suites
_log("\n=== PHASE 3: Tests ===")
local suites = { "test_bootstrap", "test_hook_manager", "test_action_base", "test_buffs", "test_world", "test_combat", "test_gm_panel" }
local s_ok, s_fail = 0, 0
for _, name in ipairs(suites) do
    _log("\n--- " .. name .. " ---")
    local tok, terr = pcall(dofile, "C:/temp/Where Winds Meet/Scripts/tests/" .. name .. ".lua")
    if tok then
        s_ok = s_ok + 1
    else
        s_fail = s_fail + 1
        _log("SUITE ERROR: " .. name .. " -> " .. tostring(terr))
    end
end

_log("\n=== FINAL ===")
_log(string.format("Suites: %d ok, %d fail | Modules: %d ok, %d fail", s_ok, s_fail, load_ok, load_fail))
if s_fail == 0 and load_fail == 0 then
    _log("ALL GREEN")
else
    _log("ISSUES FOUND")
end

-- Restore print and flush
print = _orig_print
_flush()
