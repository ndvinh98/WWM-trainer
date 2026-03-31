-- Scripts/tests/test_auto_proximity.lua
local T = dofile(_G.SCRIPTS_PATH .. "\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local mod = Reg.module("actions.auto_proximity")

T.run("module registered", function()
	T.assert_not_nil(mod, "module exists")
end)

T.run("is ActionBase subclass", function()
	T.assert_not_nil(mod.state, "has state")
	T.assert_not_nil(mod.enable, "has enable")
	T.assert_not_nil(mod.disable, "has disable")
	T.assert_not_nil(mod.is_enabled, "has is_enabled")
end)

T.run("state keys have correct types", function()
	T.assert_type(mod.state.enabled, "boolean", "enabled is boolean")
	T.assert_type(mod.state.done, "table", "done is table")
	T.assert_type(mod.state.scan_radius, "number", "scan_radius is number")
	T.assert_type(mod.state.scan_interval, "number", "scan_interval is number")
end)

T.run("state defaults", function()
	T.assert_eq(mod.state.scan_radius, 200, "scan_radius=200")
	T.assert_eq(mod.state.scan_interval, 2.0, "scan_interval=2.0")
end)

T.run("enable/disable lifecycle", function()
	mod:disable()
	T.assert_false(mod.state.enabled)

	mod:enable()
	T.assert_true(mod.state.enabled)
	T.assert_not_nil(mod.state.timer_action, "timer started")

	mod:disable()
	T.assert_false(mod.state.enabled)
	T.assert_nil(mod.state.timer_action, "timer stopped")
end)

T.run("is_enabled returns state", function()
	mod:enable()
	T.assert_true(mod:is_enabled())
	mod:disable()
	T.assert_false(mod:is_enabled())
end)

T.run("reset clears done set", function()
	mod.state.done["test_id"] = true
	mod:reset()
	T.assert_nil(mod.state.done["test_id"], "done cleared")
	T.assert_eq(next(mod.state.done), nil, "done is empty")
end)

T.run("has required methods", function()
	T.assert_not_nil(mod._get_ai_proximity_callbacks, "has _get_ai_proximity_callbacks")
	T.assert_not_nil(mod._fire_proximity, "has _fire_proximity")
	T.assert_not_nil(mod.do_scan, "has do_scan")
end)

T.run("_get_ai_proximity_callbacks returns table", function()
	-- With a nil entity, should return empty
	local result = mod:_get_ai_proximity_callbacks(nil)
	T.assert_not_nil(result, "returns a table")
	T.assert_eq(#result, 0, "empty for nil entity")
end)

T.summary()
