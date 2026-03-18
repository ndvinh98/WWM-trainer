-- Scripts/tests/test_anticheat_bypass.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local mod = _G.Reg.module("actions.anticheat_bypass")

-- 1. Module registered
T.run("anticheat_bypass module registered", function()
	T.assert_not_nil(mod)
end)

-- 2. Is ActionBase subclass
T.run("module is ActionBase subclass", function()
	T.assert_not_nil(mod.state, "has state")
	T.assert_not_nil(mod.is_enabled, "has is_enabled method")
	T.assert_not_nil(mod.hook, "has hook method")
	T.assert_not_nil(mod.unhook, "has unhook method")
end)

-- 3. State keys correct types (persistent + transient)
T.run("has all state keys with correct types", function()
	-- persistent
	T.assert_type(mod.state.logging, "boolean", "logging is boolean")
	-- transient
	T.assert_type(mod.state.intercepted_logs, "table", "intercepted_logs is table")
	T.assert_type(mod.state.native_originals, "table", "native_originals is table")
	T.assert_type(mod.state.field_originals, "table", "field_originals is table")
	T.assert_type(mod.state.dynamic_hook_names, "table", "dynamic_hook_names is table")
end)

-- 4. Hook lifecycle (static hook from define_hooks)
T.run("hook lifecycle works for static hook", function()
	mod:hook("drpf_check_can_report")
	T.assert_true(mod:is_hooked("drpf_check_can_report"))
	mod:unhook("drpf_check_can_report")
	T.assert_false(mod:is_hooked("drpf_check_can_report"))
end)

-- 5. Enable/disable
T.run("enable and disable toggle correctly", function()
	T.assert_false(mod:is_enabled())
	mod:enable()
	T.assert_true(mod:is_enabled())
	mod:disable()
	T.assert_false(mod:is_enabled())
end)

-- 6. Public API methods exist
T.run("public API methods exist", function()
	T.assert_not_nil(mod.verify_patches, "verify_patches")
	T.assert_not_nil(mod.get_intercepted_logs, "get_intercepted_logs")
	T.assert_not_nil(mod.clear_intercepted_logs, "clear_intercepted_logs")
	T.assert_not_nil(mod.get_log_summary, "get_log_summary")
	T.assert_not_nil(mod.set_logging, "set_logging")
	T.assert_not_nil(mod.get_logging, "get_logging")
end)

-- 7. set_logging / get_logging round-trip
T.run("set_logging and get_logging round-trip", function()
	local original = mod:get_logging()
	mod:set_logging(true)
	T.assert_true(mod:get_logging())
	mod:set_logging(false)
	T.assert_false(mod:get_logging())
	mod:set_logging(original)
end)

-- 8. intercepted_logs API
T.run("intercepted_logs clear works", function()
	local logs = mod:get_intercepted_logs()
	T.assert_type(logs, "table", "logs is table")
	mod:clear_intercepted_logs()
	local cleared = mod:get_intercepted_logs()
	T.assert_eq(#cleared, 0, "cleared logs is empty")
end)

T.summary()
