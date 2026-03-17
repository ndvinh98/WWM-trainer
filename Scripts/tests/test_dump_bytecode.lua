local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local Constants = Reg.get("Constants")
local dump = Reg.module("actions.dump_bytecode")

T.run("module registered", function()
	T.assert_not_nil(dump)
end)

T.run("is ActionBase subclass", function()
	T.assert_not_nil(dump.enable)
	T.assert_not_nil(dump.disable)
	T.assert_not_nil(dump.hook)
	T.assert_not_nil(dump.unhook)
	T.assert_not_nil(dump.log)
end)

T.run("state has correct defaults", function()
	T.assert_eq(dump.state._is_running, false, "_is_running is false")
end)

T.run("public API methods exist", function()
	T.assert_not_nil(dump.dump_all_async, "has dump_all_async")
	T.assert_not_nil(dump.stop_dump, "has stop_dump")
	T.assert_not_nil(dump.is_running, "has is_running")
	T.assert_not_nil(dump.get_progress, "has get_progress")
	T.assert_not_nil(dump.get_output_dir, "has get_output_dir")
end)

T.run("get_output_dir points at dumped bytecodes directory", function()
	local dir = dump:get_output_dir()
	T.assert_eq(type(dir), "string", "returns string")
	T.assert_true(dir:find("Scripts\\dumped") ~= nil, "uses dumped root")
	T.assert_true(dir:find("bytecodes") ~= nil, "uses bytecodes leaf")
end)

T.run("sample decompiled module path maps to bytecode output path", function()
	local path = dump:get_output_path_for_module("hexm.client.ui.windows.gm.gm_combat.combat_train_action")
	local expected = Constants.LUA_DEBUGGING_ROOT
		.. "\\bytecodes\\hexm\\client\\ui\\windows\\gm\\gm_combat\\combat_train_action.luac"
	T.assert_eq(path, expected, "real module path output")
end)

T.run("is_running returns false initially", function()
	T.assert_false(dump:is_running(), "not running")
end)

T.run("get_progress returns nil initially", function()
	T.assert_nil(dump:get_progress(), "no progress before start")
end)

T.summary()
