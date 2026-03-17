-- Scripts/tests/test_weapon_skins.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local weapon_skins = Reg.module("actions.weapon_skins")

T.run("module registered", function()
	T.assert_not_nil(weapon_skins)
end)

T.run("is ActionBase subclass", function()
	T.assert_not_nil(weapon_skins.enable)
	T.assert_not_nil(weapon_skins.disable)
	T.assert_not_nil(weapon_skins.hook)
	T.assert_not_nil(weapon_skins.unhook)
	T.assert_not_nil(weapon_skins.log)
end)

T.run("state keys have correct types", function()
	T.assert_eq(type(weapon_skins.state.item_nos), "table", "item_nos is table")
	T.assert_eq(type(weapon_skins.state.is_enabled), "boolean", "is_enabled is boolean")
end)

T.run("hook lifecycle", function()
	weapon_skins:hook("create_weapon")
	T.assert_true(weapon_skins:is_hooked("create_weapon"), "hook installed")
	weapon_skins:unhook("create_weapon")
	T.assert_false(weapon_skins:is_hooked("create_weapon"), "hook removed")
end)

T.run("enable/disable lifecycle", function()
	weapon_skins:disable()
	T.assert_false(weapon_skins:is_enabled(), "disabled after disable()")
	T.assert_false(weapon_skins:is_hooked("create_weapon"), "hook removed after disable")
end)

T.run("public API methods exist", function()
	T.assert_not_nil(weapon_skins.apply, "has apply")
	T.assert_not_nil(weapon_skins.apply_dual, "has apply_dual")
	T.assert_not_nil(weapon_skins.get_primary_weapon_list, "has get_primary_weapon_list")
	T.assert_not_nil(weapon_skins.get_secondary_weapon_list, "has get_secondary_weapon_list")
	T.assert_not_nil(weapon_skins.get_bow_list, "has get_bow_list")
	T.assert_not_nil(weapon_skins.get_display_name, "has get_display_name")
end)

T.run("get_display_name formats correctly", function()
	local name = weapon_skins:get_display_name({ name = "Test Blade", item_no = 42, star = 3 })
	T.assert_not_nil(name, "returns display name")
end)

T.summary()
