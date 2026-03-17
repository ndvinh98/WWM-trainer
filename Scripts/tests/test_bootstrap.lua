-- Scripts/tests/test_bootstrap.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg

T.run("Reg exists", function()
	T.assert_not_nil(Reg, "Reg")
end)

T.run("Reg is a table", function()
	T.assert_type(Reg, "table", "Reg type")
end)

T.run("KURO_lib namespace exists", function()
	T.assert_type(Reg._ns("lib"), "table", "KURO_lib")
end)

T.run("KURO_modules namespace exists", function()
	T.assert_type(Reg._ns("modules"), "table", "KURO_modules")
end)

T.run("KURO_state namespace exists", function()
	T.assert_type(Reg._ns("state"), "table", "KURO_state")
end)

T.run("KURO_hooks namespace exists", function()
	T.assert_type(Reg._ns("hooks"), "table", "KURO_hooks")
end)

T.run("Reg.lib returns Logger", function()
	T.assert_not_nil(Reg.lib("Logger"), "Logger")
end)

T.run("Reg.lib returns Constants", function()
	T.assert_not_nil(Reg.lib("Constants"), "Constants")
end)

T.run("Reg.lib returns HookManager", function()
	T.assert_not_nil(Reg.lib("HookManager"), "HookManager")
end)

T.run("Reg.lib returns ActionBase", function()
	T.assert_not_nil(Reg.lib("ActionBase"), "ActionBase")
end)

T.run("Reg.lib returns Serialize", function()
	T.assert_not_nil(Reg.lib("Serialize"), "Serialize")
end)

T.run("Reg.lib returns Cocos", function()
	T.assert_not_nil(Reg.lib("Cocos"), "Cocos")
end)

T.run("Reg.lib is consistent", function()
	local logger1 = Reg.lib("Logger")
	local logger2 = Reg.lib("Logger")
	T.assert_eq(logger1, logger2, "same instance")
end)

T.run("Reg.state creates empty table", function()
	local s = Reg.state("_test_state")
	T.assert_type(s, "table", "state")
	Reg._ns("state")["_test_state"] = nil -- cleanup
end)

T.run("Reg.state returns same table on second call", function()
	local s1 = Reg.state("_test_state_2")
	local s2 = Reg.state("_test_state_2")
	T.assert_eq(s1, s2, "same state")
	Reg._ns("state")["_test_state_2"] = nil -- cleanup
end)

T.run("Reg.legacy get/set still works", function()
	Reg.set("_test_legacy", 42)
	T.assert_eq(Reg.get("_test_legacy"), 42, "legacy value")
	Reg.del("_test_legacy")
end)

T.run("Reg.legacy get returns nil for missing key", function()
	Reg.del("_nonexistent_key_test")
	local val = Reg.get("_nonexistent_key_test")
	T.assert_nil(val, "missing key returns nil")
end)

T.run("Reg.module returns action module", function()
	local combat = Reg.module("actions.combat")
	T.assert_not_nil(combat, "combat module")
end)

T.summary()
