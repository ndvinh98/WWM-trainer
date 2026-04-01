-- Scripts/tests/test_reload.lua
-- Tests that bootstrap reload cleans up modules and hooks correctly

local pass, fail = 0, 0
local function assert_true(val, msg)
	if val then
		pass = pass + 1
		print("PASS: " .. msg)
	else
		fail = fail + 1
		print("FAIL: " .. msg .. " (expected truthy, got " .. tostring(val) .. ")")
	end
end

local function assert_false(val, msg)
	if not val then
		pass = pass + 1
		print("PASS: " .. msg)
	else
		fail = fail + 1
		print("FAIL: " .. msg .. " (expected falsy, got " .. tostring(val) .. ")")
	end
end

local function assert_eq(a, b, msg)
	if a == b then
		pass = pass + 1
		print("PASS: " .. msg)
	else
		fail = fail + 1
		print("FAIL: " .. msg .. " (expected " .. tostring(b) .. ", got " .. tostring(a) .. ")")
	end
end

-- ── Setup: verify preconditions ──

local Reg = _G.Reg
local HookManager = Reg.lib("HookManager")

assert_true(Reg, "Reg exists")
assert_true(Reg.reload_all, "Reg.reload_all exists")
assert_true(type(Reg.reload_all) == "function", "Reg.reload_all is a function")

-- ── Test: reload_all clears modules ──

-- Register a fake module
Reg.register_module("test.fake_module", { _name = "test.fake_module" })
Reg._ns("state")["test.fake_module"] = { is_enabled = true, some_setting = 42 }

assert_true(Reg.module("test.fake_module"), "fake module registered before reload")
assert_eq(Reg.state("test.fake_module").is_enabled, true, "is_enabled true before reload")

Reg.reload_all()

assert_false(Reg.module("test.fake_module"), "fake module cleared after reload")
assert_true(Reg._ns("state")["test.fake_module"], "state preserved after reload")
assert_eq(Reg.state("test.fake_module").is_enabled, false, "is_enabled reset to false after reload")
assert_eq(Reg.state("test.fake_module").some_setting, 42, "persistent setting preserved after reload")

-- ── Test: reload_all clears hooks but preserves restore intent ──

-- Register a fake hook
Reg._ns("hooks")["test.fake_hook"] = {
	module = "test.fake_module",
	hook_name = "fake_hook",
	active = true,
	was_active_before_reload = true,
	def = { stale = true },
	original = function() end,
	target = {},
	target_key = "old_target",
}

assert_true(Reg._ns("hooks")["test.fake_hook"], "fake hook registered before reload")

Reg.reload_all()

assert_false(Reg._ns("hooks")["test.fake_hook"], "fake hook cleared after reload")
assert_true(Reg._ns("reload_hooks"), "reload hook snapshot namespace exists")
assert_true(Reg._ns("reload_hooks")["test.fake_module"], "module restore intent preserved after reload")
assert_true(Reg._ns("reload_hooks")["test.fake_module"]["fake_hook"], "hook restore intent preserved after reload")

-- Old hook implementation details must not survive reload
assert_false(Reg._ns("reload_hooks")["test.fake_module"].def, "stale hook def not preserved in reload snapshot")
assert_false(Reg._ns("reload_hooks")["test.fake_module"].original, "stale original fn not preserved in reload snapshot")
assert_false(Reg._ns("reload_hooks")["test.fake_module"].target, "stale target not preserved in reload snapshot")

-- ── Test: ActionBase module survives reload cycle ──

local ActionBase = Reg.lib("ActionBase")
local TestMod = ActionBase:extend("test.reload_mod")

function TestMod:define_state()
	return {
		persistent = { counter = 0, is_enabled = false },
		transient = { temp_data = {} },
	}
end

function TestMod:define_hooks()
	return {}
end

-- First load
local inst1 = TestMod:new()
assert_true(Reg.module("test.reload_mod"), "module registered after new()")
inst1.state.counter = 5

-- Simulate reload
Reg.reload_all()
assert_false(Reg.module("test.reload_mod"), "module cleared after reload_all")
assert_eq(Reg.state("test.reload_mod").counter, 5, "persistent counter preserved")
assert_eq(Reg.state("test.reload_mod").is_enabled, false, "is_enabled reset")

-- Re-create (simulates dofile of the module)
local inst2 = TestMod:new()
assert_true(Reg.module("test.reload_mod"), "module re-registered after new()")
assert_eq(inst2.state.counter, 5, "persistent counter still 5 after re-load")
assert_eq(type(inst2.state.temp_data), "table", "transient data reset to default")
assert_false(inst2.state.is_enabled, "starts disabled after reload")

-- ── Test: reload snapshot actively reloads modules and restores hooks ──

HookManager.clear_module("tests.fixtures.reload_restore")
Reg._ns("modules")["tests.fixtures.reload_restore"] = nil
Reg._ns("state")["tests.fixtures.reload_restore"] = nil
Reg._ns("reload_hooks")["tests.fixtures.reload_restore"] = { test_hook = true }

assert_true(type(Reg.restore_reloaded_modules) == "function", "restore_reloaded_modules exists")

local restored_count = Reg.restore_reloaded_modules()
local restored_mod = Reg.module("tests.fixtures.reload_restore")

assert_true(restored_count >= 1, "restore_reloaded_modules reloads at least one module")
assert_true(restored_mod, "reload snapshot module reloaded")
assert_true(restored_mod:is_hooked("test_hook"), "previously active hook restored after module reload")
assert_false(Reg._ns("reload_hooks")["tests.fixtures.reload_restore"], "restore intent consumed after reload")

-- ── Test: reload snapshots enabled modules and re-enables them ──

-- Clean slate for this test
HookManager.clear_module("tests.fixtures.reload_enabled")
Reg._ns("modules")["tests.fixtures.reload_enabled"] = nil
Reg._ns("state")["tests.fixtures.reload_enabled"] = nil

-- Load the fixture (timer-based module with `enabled` flag, no hooks)
local enabled_fixture = dofile(_G.SCRIPTS_PATH .. "\\tests\\fixtures\\reload_enabled.lua")
assert_true(enabled_fixture, "reload_enabled fixture loaded")

-- Enable it (simulates user toggling ON)
enabled_fixture:enable()
assert_true(enabled_fixture:is_enabled(), "fixture enabled before reload")

-- Simulate reload: should snapshot enabled state
Reg.reload_all()

-- Verify snapshot was taken
assert_true(Reg._ns("reload_enabled")["tests.fixtures.reload_enabled"], "enabled module snapshotted in reload_enabled")

-- Verify state was disabled during reload
assert_false(Reg._ns("state")["tests.fixtures.reload_enabled"].enabled, "enabled flag reset during reload")

-- Module instance should be cleared
assert_false(Reg.module("tests.fixtures.reload_enabled"), "enabled module cleared after reload_all")

-- Restore: should re-load AND re-enable the module
local restore_count = Reg.restore_reloaded_modules()
assert_true(restore_count >= 1, "restore_reloaded_modules re-loads enabled module")

local restored_enabled_mod = Reg.module("tests.fixtures.reload_enabled")
assert_true(restored_enabled_mod, "enabled module re-loaded")
assert_true(restored_enabled_mod:is_enabled(), "enabled module re-enabled after reload")

-- reload_enabled should be consumed
local remaining = Reg._ns("reload_enabled")
local has_entries = false
for _ in pairs(remaining) do
	has_entries = true
	break
end
assert_false(has_entries, "reload_enabled consumed after restore")

-- ── Cleanup ──

HookManager.clear_module("tests.fixtures.reload_restore")
Reg._ns("modules")["tests.fixtures.reload_restore"] = nil
Reg._ns("state")["tests.fixtures.reload_restore"] = nil
HookManager.clear_module("tests.fixtures.reload_enabled")
Reg._ns("modules")["tests.fixtures.reload_enabled"] = nil
Reg._ns("state")["tests.fixtures.reload_enabled"] = nil
Reg._ns("modules")["test.reload_mod"] = nil
Reg._ns("state")["test.reload_mod"] = nil
Reg._ns("modules")["test.fake_module"] = nil
Reg._ns("state")["test.fake_module"] = nil

print(string.format("\n=== RESULTS: %d passed, %d failed ===", pass, fail))
