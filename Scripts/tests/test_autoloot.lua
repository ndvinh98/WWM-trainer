-- Scripts/tests/test_autoloot.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local autoloot = Reg.module("actions.autoloot")

T.run("module registered", function()
	T.assert_not_nil(autoloot)
end)

T.run("is ActionBase subclass", function()
	T.assert_not_nil(autoloot.state, "has state")
	T.assert_not_nil(autoloot.enable, "has enable")
	T.assert_not_nil(autoloot.disable, "has disable")
end)

T.run("state keys have correct types", function()
	T.assert_eq(type(autoloot.state.enabled), "boolean", "enabled is boolean")
	T.assert_eq(type(autoloot.state.interaction_mode), "string", "interaction_mode is string")
	T.assert_eq(type(autoloot.state.done), "table", "done is table")
	T.assert_eq(type(autoloot.state.pending), "nil", "pending starts nil")
end)

T.run("enable/disable lifecycle", function()
	autoloot:disable()
	T.assert_false(autoloot.state.enabled)
	
	autoloot:enable()
	T.assert_true(autoloot.state.enabled)
	T.assert_not_nil(autoloot.state.timer_action, "timer started")
	
	autoloot:disable()
	T.assert_false(autoloot.state.enabled)
	T.assert_nil(autoloot.state.timer_action, "timer stopped")
end)

T.run("is_enabled returns state", function()
	autoloot:enable()
	T.assert_true(autoloot:is_enabled())
	autoloot:disable()
	T.assert_false(autoloot:is_enabled())
end)

T.run("set_mode changes mode", function()
	autoloot:set_mode("B")
	T.assert_eq(autoloot.state.interaction_mode, "B")
	autoloot:set_mode("A")
	T.assert_eq(autoloot.state.interaction_mode, "A")
end)

T.run("reset clears state", function()
	autoloot.state.done["test"] = true
	autoloot:reset()
	T.assert_nil(autoloot.state.done["test"])
	T.assert_eq(next(autoloot.state.done), nil, "done is empty")
end)

T.summary()
