-- Scripts/tests/test_dump.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local dump = Reg.module("actions.dump")

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
	T.assert_eq(dump.state._core, nil, "_core is nil initially")
	T.assert_eq(dump.state._is_running, false, "_is_running is false")
end)

T.run("public API methods exist", function()
	T.assert_not_nil(dump.dump_all, "has dump_all")
	T.assert_not_nil(dump.dump_module, "has dump_module")
	T.assert_not_nil(dump.dump_gm, "has dump_gm")
	T.assert_not_nil(dump.dump_booleans, "has dump_booleans")
	T.assert_not_nil(dump.dump_by_prefix, "has dump_by_prefix")
	T.assert_not_nil(dump.dump_all_async, "has dump_all_async")
	T.assert_not_nil(dump.stop_async_dump, "has stop_async_dump")
	T.assert_not_nil(dump.is_async_running, "has is_async_running")
	T.assert_not_nil(dump.get_async_progress, "has get_async_progress")
	T.assert_not_nil(dump.is_running, "has is_running")
	T.assert_not_nil(dump.dump_all_bytecodes_async, "has dump_all_bytecodes_async")
	T.assert_not_nil(dump.stop_bytecode_dump, "has stop_bytecode_dump")
	T.assert_not_nil(dump.is_bytecode_dump_running, "has is_bytecode_dump_running")
	T.assert_not_nil(dump.get_core, "has get_core")
end)

T.run("get_output_dir returns string", function()
	local dir = dump:get_output_dir()
	T.assert_eq(type(dir), "string", "returns string")
	T.assert_true(#dir > 0, "non-empty")
end)

T.run("is_running returns false initially", function()
	T.assert_false(dump:is_running(), "not running")
end)

T.run("is_async_running returns false initially", function()
	T.assert_false(dump:is_async_running(), "not running")
end)

T.run("is_bytecode_dump_running returns false initially", function()
	T.assert_false(dump:is_bytecode_dump_running(), "not running")
end)

T.summary()
