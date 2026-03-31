-- Scripts/tests/test_parry.lua
local T = dofile(_G.SCRIPTS_PATH .. "\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local parry = Reg.module("actions.parry")

T.run("module registered", function()
	T.assert_not_nil(parry)
end)

T.run("is ActionBase subclass", function()
	T.assert_not_nil(parry.state, "has state")
	T.assert_not_nil(parry.enable, "has enable")
	T.assert_not_nil(parry.disable, "has disable")
	T.assert_not_nil(parry.is_enabled, "has is_enabled")
end)

T.run("state keys have correct types", function()
	T.assert_eq(type(parry.state.log_enabled), "boolean", "log_enabled is boolean")
	T.assert_eq(type(parry.state.useful_npc_events), "table", "useful_npc_events is table")
end)

T.run("hook lifecycle", function()
	parry:disable()
	T.assert_false(parry:is_hooked("listenable"), "listenable starts unhooked")

	parry:hook("listenable")
	T.assert_true(parry:is_hooked("listenable"), "listenable hooked after hook()")

	parry:unhook("listenable")
	T.assert_false(parry:is_hooked("listenable"), "listenable unhooked after unhook()")
end)

T.run("enable/disable lifecycle", function()
	parry:disable()
	T.assert_false(parry:is_enabled())

	parry:enable()
	T.assert_true(parry:is_enabled())
	T.assert_true(parry:is_hooked("listenable"), "hook active after enable")

	parry:disable()
	T.assert_false(parry:is_enabled())
	T.assert_false(parry:is_hooked("listenable"), "hook inactive after disable")
end)

T.run("private helpers exist", function()
	T.assert_not_nil(parry._get_key_by_value, "has _get_key_by_value")
	T.assert_not_nil(parry._safe_get, "has _safe_get")
	T.assert_not_nil(parry._intercept_listenable, "has _intercept_listenable")
end)

T.run("_get_key_by_value works", function()
	local tbl = { a = 1, b = 2, c = 3 }
	T.assert_eq(parry:_get_key_by_value(tbl, 2), "b", "finds correct key")
	T.assert_nil(parry:_get_key_by_value(tbl, 99), "returns nil for missing")
end)

T.run("_safe_get returns default for nil", function()
	T.assert_eq(parry:_safe_get(nil, "key", "default"), "default", "nil obj returns default")
	T.assert_eq(parry:_safe_get({x = 5}, "x", 0), 5, "valid key returns value")
	T.assert_eq(parry:_safe_get({}, "missing", 42), 42, "missing key returns default")
end)

T.summary()
