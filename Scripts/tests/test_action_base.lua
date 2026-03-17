-- Scripts/tests/test_action_base.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local ActionBase = Reg.lib("ActionBase")
local HookManager = Reg.lib("HookManager")

-- Define a test subclass
local TestAction = ActionBase:extend("test.action_base_test")

function TestAction:define_state()
	return {
		persistent = { my_flag = false, counter = 0, text = "default" },
		transient = { _cache = {}, _log_lines = {} },
	}
end

function TestAction:define_hooks()
	return {
		test_hook = {
			spec = "hexm.client.ui.base.text:Text:set_text",
			post_exec = function(self, args, results, tb)
				self.state._log_lines[#self.state._log_lines + 1] = "called"
			end,
		},
		test_hook_2 = {
			spec = "hexm.client.ui.base.label:Label:set_string",
			post_exec = function(self, args, results, tb)
				self.state._cache.last_call = "hook_2"
			end,
		},
	}
end

function TestAction:on_enable()
	self:hook_all()
end

-- Create instance
local mod = TestAction:new()

T.run("module registered in KURO_modules", function()
	T.assert_not_nil(Reg.module("test.action_base_test"))
end)

T.run("state initialized with defaults", function()
	T.assert_false(mod.state.my_flag, "my_flag default")
	T.assert_eq(mod.state.counter, 0, "counter default")
	T.assert_eq(mod.state.text, "default", "text default")
	T.assert_type(mod.state._cache, "table", "_cache type")
end)

T.run("starts disabled", function()
	T.assert_false(mod:is_enabled())
end)

T.run("enable sets is_enabled", function()
	mod:enable()
	T.assert_true(mod:is_enabled())
end)

T.run("disable unhooks and sets is_enabled false", function()
	mod:disable()
	T.assert_false(mod:is_enabled())
	T.assert_false(mod:is_hooked("test_hook"))
end)

T.run("individual hook control", function()
	mod:hook("test_hook")
	T.assert_true(mod:is_hooked("test_hook"))
	mod:unhook("test_hook")
	T.assert_false(mod:is_hooked("test_hook"))
end)

T.run("toggle works", function()
	mod:toggle()
	T.assert_true(mod:is_enabled())
	mod:toggle()
	T.assert_false(mod:is_enabled())
end)

T.run("toggle multiple times", function()
	T.assert_false(mod:is_enabled())
	for i = 1, 5 do
		mod:toggle()
	end
	T.assert_true(mod:is_enabled())
	mod:toggle()
	T.assert_false(mod:is_enabled())
end)

T.run("persistent state survives reload simulation", function()
	mod.state.my_flag = true
	mod.state.counter = 42
	mod.state.text = "modified"
	mod.state._cache = { "dirty" }

	-- Simulate reload
	mod:_init_state()

	T.assert_true(mod.state.my_flag, "persistent: my_flag kept")
	T.assert_eq(mod.state.counter, 42, "persistent: counter kept")
	T.assert_eq(mod.state.text, "modified", "persistent: text kept")
	T.assert_eq(#mod.state._cache, 0, "transient: _cache reset")
end)

T.run("transient state resets to empty tables", function()
	mod.state._log_lines = { "line1", "line2" }
	mod.state._cache = { key = "value" }
	
	-- Simulate reload
	mod:_init_state()
	
	T.assert_eq(#mod.state._log_lines, 0, "_log_lines reset")
	T.assert_eq(#mod.state._cache, 0, "_cache reset")
end)

T.run("state values are mutable", function()
	mod.state.counter = 0
	T.assert_eq(mod.state.counter, 0)
	
	mod.state.counter = 10
	T.assert_eq(mod.state.counter, 10)
	
	mod.state.counter = mod.state.counter + 5
	T.assert_eq(mod.state.counter, 15)
end)

T.run("log method exists and works", function()
	T.assert_not_nil(mod.log, "log method exists")
	T.assert_type(mod.log, "function", "log is function")
	-- Should not error
	mod:log("test message")
end)

T.run("ActionBase subclass can be extended", function()
	local TestAction2 = ActionBase:extend("test.action_base_test_2")
	T.assert_not_nil(TestAction2)
	T.assert_not_nil(TestAction2:new())
	HookManager.clear_module("test.action_base_test_2")
	Reg._ns("modules")["test.action_base_test_2"] = nil
	Reg._ns("state")["test.action_base_test_2"] = nil
end)

-- Cleanup
HookManager.clear_module("test.action_base_test")
Reg._ns("modules")["test.action_base_test"] = nil
Reg._ns("state")["test.action_base_test"] = nil

T.summary()
