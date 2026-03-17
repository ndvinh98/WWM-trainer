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

-- ── Test: reload_all clears hooks ──

-- Register a fake hook
Reg._ns("hooks")["test.fake_hook"] = {
	module = "test.fake_module",
	hook_name = "fake_hook",
	active = false,
	was_active_before_reload = true,
}

assert_true(Reg._ns("hooks")["test.fake_hook"], "fake hook registered before reload")

Reg.reload_all()

assert_false(Reg._ns("hooks")["test.fake_hook"], "fake hook cleared after reload")

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

-- ── Cleanup ──

Reg._ns("modules")["test.reload_mod"] = nil
Reg._ns("state")["test.reload_mod"] = nil
Reg._ns("modules")["test.fake_module"] = nil
Reg._ns("state")["test.fake_module"] = nil

print(string.format("\n=== RESULTS: %d passed, %d failed ===", pass, fail))
