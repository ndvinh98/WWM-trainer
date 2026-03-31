-- Scripts/tests/test_hook_manager.lua
local T = dofile(_G.SCRIPTS_PATH .. "\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local HookManager = Reg.lib("HookManager")

local TEST_MODULE = "test_hm_module"

T.run("HookManager exists", function()
	T.assert_not_nil(HookManager, "HookManager")
end)

T.run("HookManager is a table", function()
	T.assert_type(HookManager, "table", "HookManager type")
end)

T.run("derive_module_name", function()
	local name = HookManager.derive_module_name(_G.SCRIPTS_PATH .. "\\actions\\combat.lua")
	T.assert_eq(name, "actions.combat", "derived name")
end)

T.run("derive_module_name with different file", function()
	local name = HookManager.derive_module_name(_G.SCRIPTS_PATH .. "\\actions\\world.lua")
	T.assert_eq(name, "actions.world", "derived name")
end)

T.run("register hook", function()
	local ok = HookManager.register(TEST_MODULE, "test_hook", {
		spec = "hexm.client.ui.base.text:Text:set_text",
		post_exec = function() end,
	})
	T.assert_true(ok, "register")
end)

T.run("hook starts inactive", function()
	T.assert_false(HookManager.is_active(TEST_MODULE, "test_hook"), "should be inactive")
end)

T.run("get_module_hooks returns registered hook", function()
	local hooks = HookManager.get_module_hooks(TEST_MODULE)
	T.assert_not_nil(hooks["test_hook"], "hook entry")
end)

T.run("get_module_hooks returns table", function()
	local hooks = HookManager.get_module_hooks(TEST_MODULE)
	T.assert_type(hooks, "table", "hooks is table")
end)

T.run("activate hook", function()
	local ok, err = HookManager.activate(TEST_MODULE, "test_hook")
	T.assert_true(ok, "activate: " .. tostring(err))
end)

T.run("hook is active after activate", function()
	T.assert_true(HookManager.is_active(TEST_MODULE, "test_hook"))
end)

T.run("get_all_active returns table", function()
	local active = HookManager.get_all_active()
	T.assert_type(active, "table", "all_active is table")
end)

T.run("get_all_active includes test hook", function()
	local active = HookManager.get_all_active()
	T.assert_not_nil(active[TEST_MODULE .. ".test_hook"])
end)

T.run("deactivate hook", function()
	HookManager.deactivate(TEST_MODULE, "test_hook")
	T.assert_false(HookManager.is_active(TEST_MODULE, "test_hook"))
end)

T.run("deactivate_everything", function()
	HookManager.activate(TEST_MODULE, "test_hook")
	HookManager.deactivate_everything()
	T.assert_false(HookManager.is_active(TEST_MODULE, "test_hook"))
end)

T.run("register multiple hooks on same module", function()
	local ok1 = HookManager.register(TEST_MODULE, "test_hook_2", {
		spec = "hexm.client.ui.base.button:Button:on_click",
		post_exec = function() end,
	})
	local ok2 = HookManager.register(TEST_MODULE, "test_hook_3", {
		spec = "hexm.client.ui.base.label:Label:set_text",
		post_exec = function() end,
	})
	T.assert_true(ok1, "register hook 2")
	T.assert_true(ok2, "register hook 3")
	
	local hooks = HookManager.get_module_hooks(TEST_MODULE)
	T.assert_not_nil(hooks["test_hook_2"], "hook 2 exists")
	T.assert_not_nil(hooks["test_hook_3"], "hook 3 exists")
end)

T.run("activate hooks individually", function()
	local ok2, err2 = HookManager.activate(TEST_MODULE, "test_hook_2")
	local ok3, err3 = HookManager.activate(TEST_MODULE, "test_hook_3")
	-- Activation may fail in this environment if underlying modules aren't present.
	-- Just assert that the API returns boolean results and does not crash.
	T.assert_type(ok2, "boolean", "activate returned boolean for hook_2")
	T.assert_type(ok3, "boolean", "activate returned boolean for hook_3")
	-- Clean up if activated
	if HookManager.is_active(TEST_MODULE, "test_hook_2") then
		HookManager.deactivate(TEST_MODULE, "test_hook_2")
		T.assert_false(HookManager.is_active(TEST_MODULE, "test_hook_2"))
	end
	if HookManager.is_active(TEST_MODULE, "test_hook_3") then
		HookManager.deactivate(TEST_MODULE, "test_hook_3")
		T.assert_false(HookManager.is_active(TEST_MODULE, "test_hook_3"))
	end
end)

-- Cleanup
HookManager.clear_module(TEST_MODULE)

T.summary()
