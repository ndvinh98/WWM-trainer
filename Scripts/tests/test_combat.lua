-- Scripts/tests/test_combat.lua
local T = dofile(_G.SCRIPTS_PATH .. "\\tests\\run_test.lua")
T.reset()

local mod = _G.Reg.module("actions.combat")

T.run("combat module registered", function()
	T.assert_not_nil(mod)
end)

T.run("module is ActionBase subclass", function()
	T.assert_not_nil(mod.state, "has state")
	T.assert_not_nil(mod.is_enabled, "has is_enabled method")
end)

T.run("has all state keys", function()
	T.assert_not_nil(mod.state.god_mode ~= nil, "god_mode exists")
	T.assert_type(mod.state.god_mode, "boolean", "god_mode is bool")
	T.assert_type(mod.state.infinite_stamina, "boolean", "infinite_stamina is bool")
	T.assert_type(mod.state.instant_charge, "boolean", "instant_charge is bool")
	T.assert_type(mod.state.no_cooldown, "boolean", "no_cooldown is bool")
	T.assert_type(mod.state.npc_blind, "boolean", "npc_blind is bool")
end)

T.run("set_infinite_stamina hooks correctly", function()
	mod:set_infinite_stamina(true)
	T.assert_true(mod:is_hooked("stamina_skill_cost"))
	T.assert_true(mod:is_hooked("stamina_charge_drain"))
	T.assert_true(mod.state.infinite_stamina)

	mod:set_infinite_stamina(false)
	T.assert_false(mod:is_hooked("stamina_skill_cost"))
	T.assert_false(mod.state.infinite_stamina)
end)

T.run("set_instant_charge hooks correctly", function()
	mod:set_instant_charge(true)
	T.assert_true(mod:is_hooked("charge_start"))
	T.assert_true(mod:is_hooked("filter_targets"))

	mod:set_instant_charge(false)
	T.assert_false(mod:is_hooked("charge_start"))
end)

T.run("set_no_cooldown hooks correctly", function()
	mod:set_no_cooldown(true)
	T.assert_true(mod:is_hooked("no_cd_check"), "no_cd_check hooked")
	T.assert_true(mod:is_hooked("no_cd_update"), "no_cd_update hooked")
	T.assert_true(mod.state.no_cooldown, "state is true")

	mod:set_no_cooldown(false)
	T.assert_false(mod:is_hooked("no_cd_check"), "no_cd_check unhooked")
	T.assert_false(mod:is_hooked("no_cd_update"), "no_cd_update unhooked")
	T.assert_false(mod.state.no_cooldown, "state is false")
end)

T.run("set_no_cooldown no stale rawset state", function()
	T.assert_nil(mod.state._no_cd_original, "no _no_cd_original in state")
end)

T.run("set_god_mode sets state correctly", function()
	mod:set_god_mode(true)
	T.assert_true(mod.state.god_mode)

	mod:set_god_mode(false)
	T.assert_false(mod.state.god_mode)
end)

T.run("set_npc_blind sets state correctly", function()
	mod:set_npc_blind(true)
	T.assert_true(mod.state.npc_blind)

	mod:set_npc_blind(false)
	T.assert_false(mod.state.npc_blind)
end)

T.run("multiple features can be enabled together", function()
	mod:set_god_mode(true)
	mod:set_infinite_stamina(true)
	mod:set_instant_charge(true)
	mod:set_no_cooldown(true)

	T.assert_true(mod.state.god_mode)
	T.assert_true(mod.state.infinite_stamina)
	T.assert_true(mod.state.instant_charge)
	T.assert_true(mod.state.no_cooldown)

	mod:set_god_mode(false)
	mod:set_infinite_stamina(false)
	mod:set_instant_charge(false)
	mod:set_no_cooldown(false)
end)

T.run("disable unhooks all", function()
	mod:set_infinite_stamina(true)
	mod:set_instant_charge(true)
	mod:set_no_cooldown(true)
	mod:disable()
	T.assert_false(mod:is_hooked("stamina_skill_cost"))
	T.assert_false(mod:is_hooked("charge_start"))
	T.assert_false(mod:is_hooked("no_cd_check"), "no_cd_check cleaned up")
	T.assert_false(mod:is_hooked("no_cd_update"), "no_cd_update cleaned up")
	T.assert_false(mod:is_enabled())
end)

T.run("enable and disable toggle correctly", function()
	T.assert_false(mod:is_enabled())
	mod:enable()
	T.assert_true(mod:is_enabled())
	mod:disable()
	T.assert_false(mod:is_enabled())
end)

T.summary()
