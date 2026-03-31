-- Scripts/tests/test_archery_master.lua
local T = dofile(_G.SCRIPTS_PATH .. "\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local mod = Reg.module("actions.archery_master")

-- 1. Module registered
T.run("module registered", function()
	T.assert_not_nil(mod, "module")
end)

-- 2. Is ActionBase subclass
T.run("is ActionBase subclass", function()
	T.assert_not_nil(mod.state, "has state")
	T.assert_not_nil(mod.is_enabled, "has is_enabled method")
end)

-- 3. State keys correct types
T.run("state initialized", function()
	T.assert_type(mod.state.scan_range, "number")
end)

-- 4. Has define_hooks (empty)
T.run("no hooks defined", function()
	T.assert_not_nil(mod.define_hooks, "has define_hooks")
end)

-- 5. Enable/disable lifecycle
T.run("enable disable", function()
	mod:enable()
	T.assert_true(mod:is_enabled())
	mod:disable()
	T.assert_false(mod:is_enabled())
end)

-- 6. execute method exists
T.run("execute method exists", function()
	T.assert_not_nil(mod.execute, "has execute method")
	T.assert_type(mod.execute, "function")
end)

-- 7. _get_yaoyuan_targets method exists
T.run("_get_yaoyuan_targets method exists", function()
	T.assert_not_nil(mod._get_yaoyuan_targets, "has _get_yaoyuan_targets")
	T.assert_type(mod._get_yaoyuan_targets, "function")
end)

-- 8. _destroy_entities_by_no method exists
T.run("_destroy_entities_by_no method exists", function()
	T.assert_not_nil(mod._destroy_entities_by_no, "has _destroy_entities_by_no")
	T.assert_type(mod._destroy_entities_by_no, "function")
end)

T.summary()
