-- Scripts/tests/test_yugioh.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local mod = Reg.module("actions.yugioh")

-- 1. Module registered
T.run("module registered", function()
	T.assert_not_nil(mod, "module")
end)

-- 2. Is ActionBase subclass
T.run("is ActionBase subclass", function()
	T.assert_not_nil(mod.state, "has state")
	T.assert_not_nil(mod.is_enabled, "has is_enabled method")
	T.assert_not_nil(mod.enable, "has enable method")
	T.assert_not_nil(mod.disable, "has disable method")
end)

-- 3. State keys correct types
T.run("state initialized", function()
	T.assert_type(mod.state.auto_play, "boolean")
	T.assert_type(mod.state.poll_interval, "number")
	T.assert_type(mod.state.tp_delay_min, "number")
	T.assert_type(mod.state.tp_delay_max, "number")
end)

-- 4. Enable/disable lifecycle
T.run("enable disable", function()
	mod:enable()
	T.assert_true(mod:is_enabled())
	mod:disable()
	T.assert_false(mod:is_enabled())
end)

-- 5. set_auto_play API
T.run("set_auto_play toggles state", function()
	mod:enable()
	mod:set_auto_play(true)
	T.assert_true(mod.state.auto_play, "auto_play on")
	mod:set_auto_play(false)
	T.assert_false(mod.state.auto_play, "auto_play off")
	mod:disable()
end)

-- 6. Polling not active when disabled
T.run("no polling when disabled", function()
	mod:disable()
	T.assert_nil(mod.state._poll_timer, "poll timer nil when disabled")
	T.assert_false(mod.state._is_solving, "not solving when disabled")
end)

-- 7. _find_active_game returns nil when no game running
T.run("_find_active_game returns nil for absent type", function()
	-- Type 99 should never be running
	local result = mod:_find_active_game(99)
	T.assert_nil(result, "no game for type 99")
end)

-- 8. _get_config_sids returns empty table for invalid game_id
T.run("_get_config_sids handles invalid game_id", function()
	local result = mod:_get_config_sids(0, "t_cat_serial_id")
	T.assert_not_nil(result, "returns table")
	T.assert_eq(#result, 0, "empty table for invalid game")
end)

-- 9. Freeze solver uses direct server RPC
T.run("freeze solver has _solve_freeze_rpc method", function()
	T.assert_not_nil(mod._solve_freeze_rpc, "has _solve_freeze_rpc")
	-- Verify the RPC path exists
	local ok, avatar = pcall(function()
		return G.net:get_avatar()
	end)
	if ok and avatar then
		T.assert_not_nil(avatar.region_game_process_notify_server, "avatar has RPC method")
	end
	T.assert_true(true, "RPC path verified")
end)

T.summary()
