-- Scripts/tests/test_autoloot.lua
local T = dofile(_G.SCRIPTS_PATH .. "\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local autoloot = Reg.module("actions.autoloot")

T.run("module registered", function()
	T.assert_not_nil(autoloot)
end)

T.run("is ActionBase subclass", function()
	T.assert_not_nil(autoloot.state, "has state")
	T.assert_not_nil(autoloot.enable, "has enable")
	T.assert_not_nil(autoloot.disable, "has disable")
end)

T.run("state keys have correct types", function()
	T.assert_eq(type(autoloot.state.enabled), "boolean", "enabled is boolean")
	T.assert_eq(type(autoloot.state.done), "table", "done is table")
	T.assert_eq(type(autoloot.state.pending), "nil", "pending starts nil")
	T.assert_eq(type(autoloot.state.entity_radius), "number", "entity_radius is number")
	T.assert_eq(type(autoloot.state.active_interact_radius), "number", "active_interact_radius is number")
	T.assert_eq(type(autoloot.state.transit_radius), "number", "transit_radius is number")
end)

T.run("state defaults are correct", function()
	T.assert_eq(autoloot.state.entity_radius, 150, "entity_radius=150")
	T.assert_eq(autoloot.state.active_interact_radius, 20, "active_interact_radius=20")
	T.assert_eq(autoloot.state.transit_radius, 150, "transit_radius=150")
	T.assert_eq(autoloot.state.done_ttl, 5.0, "done_ttl=5.0")
end)

T.run("enable/disable lifecycle", function()
	autoloot:disable()
	T.assert_false(autoloot.state.enabled)

	autoloot:enable()
	T.assert_true(autoloot.state.enabled)
	T.assert_not_nil(autoloot.state.timer_action, "timer started")

	autoloot:disable()
	T.assert_false(autoloot.state.enabled)
	T.assert_nil(autoloot.state.timer_action, "timer stopped")
end)

T.run("is_enabled returns state", function()
	autoloot:enable()
	T.assert_true(autoloot:is_enabled())
	autoloot:disable()
	T.assert_false(autoloot:is_enabled())
end)

T.run("reset clears state", function()
	autoloot.state.done["test"] = true
	autoloot:reset()
	T.assert_nil(autoloot.state.done["test"])
	T.assert_eq(next(autoloot.state.done), nil, "done is empty")
end)

T.run("done cache expires after ttl", function()
	local orig_now = autoloot._now
	local ok, err = pcall(function()
		autoloot:reset()
		autoloot._now = function()
			return 100
		end
		autoloot:_mark_done("ttl_test")
		T.assert_true(autoloot:_is_done("ttl_test"), "entry is live before ttl")
		T.assert_eq(autoloot.state.done["ttl_test"], 105, "stores expiry timestamp")

		autoloot._now = function()
			return 104.9
		end
		T.assert_true(autoloot:_is_done("ttl_test"), "entry is still live before expiry")

		autoloot._now = function()
			return 105
		end
		T.assert_false(autoloot:_is_done("ttl_test"), "entry expires at ttl")
		T.assert_nil(autoloot.state.done["ttl_test"], "expired entry is pruned on read")
	end)
	autoloot._now = orig_now
	if not ok then
		error(err)
	end
end)

T.run("no set_mode method (removed)", function()
	T.assert_nil(autoloot.set_mode, "set_mode should not exist")
end)

T.run("has required methods", function()
	T.assert_not_nil(autoloot._start_interact, "has _start_interact")
	T.assert_not_nil(autoloot._direct_result, "has _direct_result")
	T.assert_not_nil(autoloot._direct_result_await, "has _direct_result_await")
	T.assert_not_nil(autoloot._force_transit_comp_status, "has _force_transit_comp_status")
	T.assert_not_nil(autoloot.try_interact_entity, "has try_interact_entity")
	T.assert_not_nil(autoloot.do_scan, "has do_scan")
end)

T.summary()
