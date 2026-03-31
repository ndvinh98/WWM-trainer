-- Scripts/tests/test_weapon_skins.lua
local T = dofile(_G.SCRIPTS_PATH .. "\\tests\\run_test.lua")
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

T.run("state uses skin_map not item_nos", function()
	T.assert_eq(type(weapon_skins.state.skin_map), "table", "skin_map is table")
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

-- === NEW TESTS: slot-based skin_map ===

T.run("disable clears skin_map", function()
	weapon_skins.state.skin_map = { primary = 1001 }
	weapon_skins:disable()
	local count = 0
	for _ in pairs(weapon_skins.state.skin_map) do
		count = count + 1
	end
	T.assert_eq(count, 0, "skin_map empty after disable")
end)

T.run("apply stores slot in skin_map", function()
	weapon_skins:disable()
	-- apply(item_no_or_item, slot) should store the skin_no under slot key
	weapon_skins:apply(1001, "primary")
	T.assert_eq(weapon_skins.state.skin_map["primary"], 1001, "primary slot set")
	weapon_skins:apply(2002, "secondary")
	T.assert_eq(weapon_skins.state.skin_map["secondary"], 2002, "secondary slot set")
	-- primary should still be 1001
	T.assert_eq(weapon_skins.state.skin_map["primary"], 1001, "primary slot unchanged")
	weapon_skins:disable()
end)

T.run("apply_dual stores both slots", function()
	weapon_skins:disable()
	weapon_skins:apply_dual({ item_no = 3003 }, { item_no = 4004 })
	T.assert_eq(weapon_skins.state.skin_map["primary"], 3003, "primary from apply_dual")
	T.assert_eq(weapon_skins.state.skin_map["secondary"], 4004, "secondary from apply_dual")
	weapon_skins:disable()
end)

T.run("apply replaces existing slot", function()
	weapon_skins:disable()
	weapon_skins:apply(1001, "primary")
	T.assert_eq(weapon_skins.state.skin_map["primary"], 1001, "initial primary")
	weapon_skins:apply(5005, "primary")
	T.assert_eq(weapon_skins.state.skin_map["primary"], 5005, "replaced primary")
	weapon_skins:disable()
end)

T.run("get_skin_map returns current map", function()
	weapon_skins:disable()
	T.assert_not_nil(weapon_skins.get_skin_map, "has get_skin_map method")
	local map = weapon_skins:get_skin_map()
	T.assert_eq(type(map), "table", "get_skin_map returns table")
end)

T.run("apply_bow stores in bow slot", function()
	weapon_skins:disable()
	T.assert_not_nil(weapon_skins.apply_bow, "has apply_bow method")
	weapon_skins:apply_bow(6006)
	T.assert_eq(weapon_skins.state.skin_map["bow"], 6006, "bow slot set")
	weapon_skins:disable()
end)

T.summary()
