-- Scripts/tests/test_suit_skins.lua
local T = dofile(_G.SCRIPTS_PATH .. "\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local suit_skins = Reg.module("actions.suit_skins")

T.run("module registered", function()
	T.assert_not_nil(suit_skins)
end)

T.run("is ActionBase subclass", function()
	T.assert_not_nil(suit_skins.enable)
	T.assert_not_nil(suit_skins.disable)
	T.assert_not_nil(suit_skins.hook)
	T.assert_not_nil(suit_skins.unhook)
	T.assert_not_nil(suit_skins.log)
end)

T.run("state keys have correct types", function()
	T.assert_eq(type(suit_skins.state.is_enabled), "boolean", "is_enabled is boolean")
	T.assert_eq(suit_skins.state.suit_no, nil, "suit_no is nil by default")
	T.assert_eq(suit_skins.state.wear_info, nil, "wear_info is nil by default")
end)

T.run("hook lifecycle", function()
	suit_skins:hook("set_init_dressing_info")
	T.assert_true(suit_skins:is_hooked("set_init_dressing_info"), "hook installed")
	suit_skins:unhook("set_init_dressing_info")
	T.assert_false(suit_skins:is_hooked("set_init_dressing_info"), "hook removed")
end)

T.run("enable/disable lifecycle", function()
	suit_skins:disable()
	T.assert_false(suit_skins:is_enabled(), "disabled after disable()")
	T.assert_false(suit_skins:is_hooked("set_init_dressing_info"), "hook removed after disable")
end)

T.run("private helpers exist", function()
	T.assert_not_nil(suit_skins._name_from_icon, "has _name_from_icon method")
	T.assert_not_nil(suit_skins._translate, "has _translate method")
	T.assert_not_nil(suit_skins._datam_dict_to_list, "has _datam_dict_to_list method")
	T.assert_not_nil(suit_skins._generate_suit_data, "has _generate_suit_data method")
	T.assert_not_nil(suit_skins._load_suit_data, "has _load_suit_data method")
end)

T.run("public API methods exist", function()
	T.assert_not_nil(suit_skins.apply, "has apply")
	T.assert_not_nil(suit_skins.get_suit_list, "has get_suit_list")
	T.assert_not_nil(suit_skins.get_suit_data, "has get_suit_data")
	T.assert_not_nil(suit_skins.get_current_suit, "has get_current_suit")
end)

T.run("legacy aliases exist", function()
	T.assert_eq(suit_skins.change_suit, suit_skins.apply, "change_suit aliased")
	T.assert_eq(suit_skins.ChangeSuitBySuitNo, suit_skins.apply, "ChangeSuitBySuitNo aliased")
	T.assert_eq(suit_skins.GetSuitList, suit_skins.get_suit_list, "GetSuitList aliased")
	T.assert_eq(suit_skins.GetSuitData, suit_skins.get_suit_data, "GetSuitData aliased")
end)

T.summary()
