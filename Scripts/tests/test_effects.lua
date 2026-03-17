-- Scripts/tests/test_effects.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local effects = Reg.module("actions.effects")

T.run("module registered", function()
	T.assert_not_nil(effects)
end)

T.run("is ActionBase subclass", function()
	T.assert_not_nil(effects.state, "has state")
	T.assert_not_nil(effects.is_enabled, "has is_enabled")
	T.assert_not_nil(effects.enable_discovery, "has enable_discovery")
end)

T.run("state keys have correct types", function()
	T.assert_eq(type(effects.state.is_enabled), "boolean", "is_enabled is boolean")
	T.assert_eq(type(effects.state.kungfu_to_effect), "table", "kungfu_to_effect is table")
	T.assert_eq(type(effects.state.discovery_mode), "boolean", "discovery_mode is boolean")
	T.assert_eq(type(effects.state.logged_count), "number", "logged_count is number")
end)

T.run("hook lifecycle", function()
	effects:disable()
	T.assert_false(effects:is_hooked("get_kongfu_fx"), "get_kongfu_fx starts unhooked")
	
	effects:enable_single(101, 5)
	T.assert_true(effects:is_hooked("get_kongfu_fx"), "get_kongfu_fx hooked after enable_single")
	
	effects:disable()
	T.assert_false(effects:is_enabled(), "is_enabled false after disable")
	T.assert_false(effects:is_hooked("get_kongfu_fx"), "get_kongfu_fx unhooked after disable")
end)

T.run("enable/disable lifecycle", function()
	effects:disable()
	T.assert_false(effects:is_enabled())
	
	effects:enable_single(101, 5)
	T.assert_true(effects:is_enabled())
	
	effects:disable()
	T.assert_false(effects:is_enabled())
end)

T.run("discovery mode toggle", function()
	effects:disable_discovery()
	T.assert_false(effects:is_discovery_active())
	
	effects:enable_discovery()
	T.assert_true(effects:is_discovery_active())
	T.assert_true(effects:is_hooked("discovery"), "discovery hook active")
	
	effects:disable_discovery()
	T.assert_false(effects:is_discovery_active())
	T.assert_false(effects:is_hooked("discovery"), "discovery hook inactive")
end)

T.run("log count increments", function()
	effects.state.logged_count = 0
	local before = effects:get_log_count()
	effects.state.logged_count = before + 1
	local after = effects:get_log_count()
	T.assert_eq(after, before + 1, "logged_count increments")
end)

T.run("get_effect_list returns table", function()
	local result = effects:get_effect_list(nil)
	T.assert_eq(type(result), "table", "returns table")
end)

T.run("get_effect_data returns nil or table", function()
	local data = effects:get_effect_data(999999)
	local is_valid = data == nil or type(data) == "table"
	T.assert_true(is_valid, "returns nil or table")
end)

T.run("enable_single sets mapping", function()
	effects:disable()
	effects:enable_single(101, 5)
	local mapping = effects:get_dual_mappings()
	T.assert_eq(mapping[5], 101, "mapping set correctly")
end)

T.run("enable_dual sets dual mappings", function()
	effects:disable()
	effects:enable_dual(101, 102, 5, 6)
	local mapping = effects:get_dual_mappings()
	T.assert_eq(mapping[5], 101, "main mapping set")
	T.assert_eq(mapping[6], 102, "secondary mapping set")
end)

T.run("apply returns boolean", function()
	local result = effects:apply(101)
	local is_bool = result == true or result == false
	T.assert_true(is_bool, "apply returns boolean")
end)

T.run("info method exists", function()
	T.assert_not_nil(effects.info, "info method exists")
	effects:info()
	T.assert_true(true, "info does not error")
end)

T.summary()
