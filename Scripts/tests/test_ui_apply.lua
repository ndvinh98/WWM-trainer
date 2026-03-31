-- Scripts/tests/test_ui_apply.lua
-- Tests that SelectorFactory apply flow works correctly with action modules
local T = dofile(_G.SCRIPTS_PATH .. "\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg

-- ============================================================
-- WEAPON SKINS: apply accepts item objects
-- ============================================================
local weapon_skins = Reg.module("actions.weapon_skins")

T.run("weapon_skins: apply accepts raw item_no", function()
	T.assert_not_nil(weapon_skins)
	T.assert_not_nil(weapon_skins.apply, "has apply method")
	-- Should not error when called with a number (even if skin doesn't exist in-game)
	local ok, err = pcall(function()
		weapon_skins:apply(99999)
	end)
	T.assert_true(ok, "apply(number) should not throw: " .. tostring(err))
end)

T.run("weapon_skins: apply accepts item object", function()
	local item = { item_no = 88888, name = "Test Weapon" }
	local ok, err = pcall(function()
		weapon_skins:apply(item)
	end)
	T.assert_true(ok, "apply(item_obj) should not throw: " .. tostring(err))
end)

T.run("weapon_skins: apply_dual exists", function()
	T.assert_not_nil(weapon_skins.apply_dual, "has apply_dual method")
	local ok, err = pcall(function()
		weapon_skins:apply_dual({ item_no = 11111 }, { item_no = 22222 })
	end)
	T.assert_true(ok, "apply_dual should not throw: " .. tostring(err))
end)

T.run("weapon_skins: disable clears state", function()
	weapon_skins:disable()
	local count = 0
	for _ in pairs(weapon_skins.state.skin_map) do
		count = count + 1
	end
	T.assert_eq(count, 0, "skin_map cleared after disable")
	T.assert_false(weapon_skins:is_hooked("create_weapon"), "hook removed after disable")
end)

T.run("weapon_skins: get_bow_list exists", function()
	T.assert_not_nil(weapon_skins.get_bow_list, "has get_bow_list")
end)

T.run("weapon_skins: get_primary_weapon_list exists", function()
	T.assert_not_nil(weapon_skins.get_primary_weapon_list, "has get_primary_weapon_list")
end)

T.run("weapon_skins: get_secondary_weapon_list exists", function()
	T.assert_not_nil(weapon_skins.get_secondary_weapon_list, "has get_secondary_weapon_list")
end)

T.run("weapon_skins: get_display_name exists", function()
	T.assert_not_nil(weapon_skins.get_display_name, "has get_display_name")
	local name = weapon_skins:get_display_name({ name = "Test", item_no = 123, star = 2 })
	T.assert_not_nil(name, "returns a display name")
end)

-- ============================================================
-- SUIT SKINS: apply accepts item objects
-- ============================================================
local suit_skins = Reg.module("actions.suit_skins")

T.run("suit_skins: apply accepts raw suit_no", function()
	T.assert_not_nil(suit_skins)
	local ok, err = pcall(function()
		suit_skins:apply(99999)
	end)
	T.assert_true(ok, "apply(number) should not throw: " .. tostring(err))
end)

T.run("suit_skins: apply accepts item object", function()
	local item = { suit_no = 88888, name = "Test Suit" }
	local ok, err = pcall(function()
		suit_skins:apply(item)
	end)
	T.assert_true(ok, "apply(item_obj) should not throw: " .. tostring(err))
end)

T.run("suit_skins: enable/disable lifecycle", function()
	suit_skins:disable()
	T.assert_false(suit_skins:is_enabled(), "disabled after disable()")
	T.assert_false(suit_skins:is_hooked("set_init_dressing_info"), "hook removed")
end)

-- ============================================================
-- EFFECTS: apply methods + kongfu filtering
-- ============================================================
local effects = Reg.module("actions.effects")

T.run("effects: get_primary_effect_list exists", function()
	T.assert_not_nil(effects.get_primary_effect_list, "has get_primary_effect_list")
end)

T.run("effects: get_secondary_effect_list exists", function()
	T.assert_not_nil(effects.get_secondary_effect_list, "has get_secondary_effect_list")
end)

T.run("effects: apply_dual_items exists", function()
	T.assert_not_nil(effects.apply_dual_items, "has apply_dual_items")
end)

T.run("effects: get_display_name exists", function()
	T.assert_not_nil(effects.get_display_name, "has get_display_name")
	local name = effects:get_display_name({ name = "Fire Blade", effect_id = 42 })
	T.assert_eq(name, "Fire Blade [42]", "display name format")
end)

T.run("effects: enable_single/disable lifecycle", function()
	effects:disable()
	T.assert_false(effects:is_enabled(), "disabled after disable()")
	T.assert_false(effects:is_hooked("get_kongfu_fx"), "hook removed after disable")

	-- enable_single with valid IDs
	local ok = effects:enable_single(12345, 67890)
	T.assert_true(ok, "enable_single returns true")
	T.assert_true(effects:is_enabled(), "enabled after enable_single")
	T.assert_true(effects:is_hooked("get_kongfu_fx"), "hook installed after enable_single")

	-- Verify mapping
	local mappings = effects:get_dual_mappings()
	T.assert_eq(mappings[67890], 12345, "kungfu_to_effect mapping correct")

	effects:disable()
	T.assert_false(effects:is_enabled(), "disabled again")
end)

T.run("effects: enable_dual/disable lifecycle", function()
	effects:disable()

	local ok = effects:enable_dual(100, 200, 300, 400)
	T.assert_true(ok, "enable_dual returns true")
	T.assert_true(effects:is_enabled(), "enabled after enable_dual")

	local mappings = effects:get_dual_mappings()
	T.assert_eq(mappings[300], 100, "main kungfu mapped to main effect")
	T.assert_eq(mappings[400], 200, "secondary kungfu mapped to secondary effect")

	effects:disable()
	T.assert_false(effects:is_enabled(), "disabled after dual")
end)

-- ============================================================
-- SELECTOR FACTORY
-- ============================================================

T.run("SelectorFactory loads", function()
	local Constants = Reg.lib("Constants")
	local ok, SF = pcall(dofile, Constants.SCRIPTS_ROOT .. "\\ui\\lib\\selector_factory.lua")
	T.assert_true(ok, "SelectorFactory loads: " .. tostring(SF))
	T.assert_not_nil(SF.show, "has show")
	T.assert_not_nil(SF.close, "has close")
end)

T.summary()
