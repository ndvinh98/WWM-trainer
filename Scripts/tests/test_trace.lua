-- Scripts/tests/test_trace.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local trace = Reg.module("actions.trace")

T.run("module registered", function()
	T.assert_not_nil(trace)
end)

T.run("is ActionBase subclass", function()
	T.assert_not_nil(trace.enable)
	T.assert_not_nil(trace.disable)
	T.assert_not_nil(trace.hook)
	T.assert_not_nil(trace.unhook)
	T.assert_not_nil(trace.log)
end)

T.run("state has correct defaults", function()
	T.assert_eq(trace.state._core, nil, "_core is nil initially")
end)

T.run("public API methods exist", function()
	T.assert_not_nil(trace.start_trace, "has start_trace")
	T.assert_not_nil(trace.stop_trace, "has stop_trace")
	T.assert_not_nil(trace.is_tracing, "has is_tracing")
	T.assert_not_nil(trace.get_output_path, "has get_output_path")
end)

T.run("get_output_path returns string", function()
	local path = trace:get_output_path()
	T.assert_eq(type(path), "string", "returns string")
	T.assert_true(#path > 0, "non-empty")
end)

T.run("is_tracing returns false initially", function()
	T.assert_false(trace:is_tracing(), "not tracing")
end)

T.summary()
