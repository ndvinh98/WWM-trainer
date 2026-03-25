-- Scripts/tests/test_fishing_master.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local mod = Reg.module("actions.fishing_master")

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
T.run("state initialized with correct types", function()
	T.assert_type(mod.state.auto_play, "boolean", "auto_play is boolean")
	T.assert_type(mod.state.log_enabled, "boolean", "log_enabled is boolean")
end)

-- 4. Enable/disable lifecycle
T.run("enable disable lifecycle", function()
	mod:enable()
	T.assert_true(mod:is_enabled(), "enabled after enable()")
	mod:disable()
	T.assert_false(mod:is_enabled(), "disabled after disable()")
end)

-- 5. Toggle works
T.run("toggle works", function()
	T.assert_false(mod:is_enabled(), "starts disabled")
	mod:toggle()
	T.assert_true(mod:is_enabled(), "enabled after toggle")
	mod:toggle()
	T.assert_false(mod:is_enabled(), "disabled after second toggle")
end)

-- 6. set_auto_play method exists
T.run("set_auto_play method exists", function()
	T.assert_not_nil(mod.set_auto_play, "method exists")
	T.assert_type(mod.set_auto_play, "function", "is function")
end)

-- 7. set_auto_play updates state
T.run("set_auto_play updates state", function()
	mod:set_auto_play(true)
	T.assert_true(mod.state.auto_play, "auto_play is true after set(true)")
	mod:set_auto_play(false)
	T.assert_false(mod.state.auto_play, "auto_play is false after set(false)")
end)

-- 8. Polling methods exist
T.run("polling methods exist", function()
	T.assert_not_nil(mod._start_polling, "_start_polling exists")
	T.assert_type(mod._start_polling, "function", "_start_polling is function")
	T.assert_not_nil(mod._stop_polling, "_stop_polling exists")
	T.assert_type(mod._stop_polling, "function", "_stop_polling is function")
end)

-- 9. Hooks defined (qte_del and qte_add)
T.run("hooks defined for QTE override", function()
	local hooks = mod:define_hooks()
	local count = 0
	for _ in pairs(hooks) do
		count = count + 1
	end
	T.assert_eq(count, 2, "2 hooks defined (qte_del, qte_add)")
	T.assert_not_nil(hooks.qte_del, "qte_del hook exists")
	T.assert_not_nil(hooks.qte_add, "qte_add hook exists")
end)

-- 10. Event registration methods exist
T.run("event registration methods exist", function()
	T.assert_not_nil(mod._register_events, "_register_events exists")
	T.assert_type(mod._register_events, "function", "_register_events is function")
	T.assert_not_nil(mod._unregister_events, "_unregister_events exists")
	T.assert_type(mod._unregister_events, "function", "_unregister_events is function")
end)

-- 11. Persistent state survives reload simulation
T.run("persistent state survives reload", function()
	mod.state.auto_play = true
	mod:_init_state()
	T.assert_true(mod.state.auto_play, "auto_play survived reload")
	mod.state.auto_play = false
end)

T.summary()
