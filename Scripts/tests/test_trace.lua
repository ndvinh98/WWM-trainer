-- Scripts/tests/test_trace.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local trace = Reg.module("actions.trace")

-- 1. Module registered
T.run("module registered", function()
	T.assert_not_nil(trace)
end)

-- 2. Is ActionBase subclass
T.run("is ActionBase subclass", function()
	T.assert_not_nil(trace.enable, "has enable")
	T.assert_not_nil(trace.disable, "has disable")
	T.assert_not_nil(trace.hook, "has hook")
	T.assert_not_nil(trace.unhook, "has unhook")
	T.assert_not_nil(trace.log, "has log")
end)

-- 3. State keys correct types
T.run("state has correct types", function()
	T.assert_type(trace.state.output_format, "string", "output_format is string")
	T.assert_type(trace.state.is_tracing, "boolean", "is_tracing is boolean")
	T.assert_type(trace.state.call_sequence, "number", "call_sequence is number")
	T.assert_type(trace.state.file_count, "number", "file_count is number")
end)

-- 4. Public API methods exist
T.run("public API methods exist", function()
	T.assert_not_nil(trace.start, "has start")
	T.assert_not_nil(trace.stop, "has stop")
	T.assert_not_nil(trace.start_trace, "has start_trace")
	T.assert_not_nil(trace.stop_trace, "has stop_trace")
	T.assert_not_nil(trace.toggle, "has toggle")
	T.assert_not_nil(trace.is_tracing, "has is_tracing")
	T.assert_not_nil(trace.get_output_path, "has get_output_path")
	T.assert_not_nil(trace.get_stats, "has get_stats")
	T.assert_not_nil(trace.set_format, "has set_format")
	T.assert_not_nil(trace.get_format, "has get_format")
end)

-- 5. is_tracing returns false initially
T.run("is_tracing returns false initially", function()
	T.assert_false(trace:is_tracing(), "not tracing")
end)

-- 6. get_output_path returns non-empty string
T.run("get_output_path returns string", function()
	local path = trace:get_output_path()
	T.assert_eq(type(path), "string", "returns string")
	T.assert_true(#path > 0, "non-empty")
	T.assert_true(path:find("traces") ~= nil, "contains traces dir")
end)

-- 7. set_format / get_format round-trip
T.run("set_format round-trip", function()
	local ok1, msg1 = trace:set_format("readable")
	T.assert_true(ok1, "set readable ok")
	T.assert_eq(trace:get_format(), "readable", "format is readable")

	local ok2, msg2 = trace:set_format("json")
	T.assert_true(ok2, "set json ok")
	T.assert_eq(trace:get_format(), "json", "format is json")

	local ok3, msg3 = trace:set_format("invalid")
	T.assert_false(ok3, "invalid format rejected")
end)

-- 8. get_stats returns correct shape
T.run("get_stats returns table", function()
	local stats = trace:get_stats()
	T.assert_not_nil(stats, "stats not nil")
	T.assert_type(stats.is_enabled, "boolean", "has is_enabled")
	T.assert_type(stats.call_sequence, "number", "has call_sequence")
	T.assert_type(stats.file_count, "number", "has file_count")
	T.assert_type(stats.format, "string", "has format")
end)

-- 9. UI integration: simulate menu_controller pattern (pcall-based toggle)
T.run("UI toggle pattern (pcall start/stop)", function()
	-- This simulates exactly what menu_controller.handle_trace_call does
	local ok_start, err_start = pcall(trace.start_trace, trace)
	T.assert_true(ok_start, "pcall start_trace no error: " .. tostring(err_start))

	-- After start, should be tracing
	T.assert_true(trace:is_tracing(), "tracing after start")

	-- Stop
	local ok_stop, err_stop = pcall(trace.stop_trace, trace)
	T.assert_true(ok_stop, "pcall stop_trace no error: " .. tostring(err_stop))

	-- After stop, should not be tracing
	T.assert_false(trace:is_tracing(), "not tracing after stop")
end)

-- 10. Emergency stop ref exists
T.run("emergency stop ref", function()
	local trace_state = _G.Reg.state("actions.trace")
	T.assert_not_nil(trace_state, "trace state exists")
	T.assert_type(trace_state.stop, "function", "stop ref is function")
end)

T.summary()
