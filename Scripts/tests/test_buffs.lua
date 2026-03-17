-- Scripts/tests/test_buffs.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local mod = Reg.module("actions.buffs")

T.run("buffs module registered", function()
	T.assert_not_nil(mod, "module")
end)

T.run("buffs module is ActionBase subclass", function()
	T.assert_not_nil(mod.state, "has state")
	T.assert_not_nil(mod.is_enabled, "has is_enabled method")
end)

T.run("has get_presets", function()
	local presets = mod:get_presets()
	T.assert_not_nil(presets, "presets exists")
	T.assert_not_nil(presets.combat, "combat preset")
	T.assert_true(#presets.combat > 0, "combat has buffs")
end)

T.run("all presets have valid structure", function()
	local presets = mod:get_presets()
	for preset_name, buffs in pairs(presets) do
		T.assert_type(buffs, "table", "preset " .. preset_name .. " is table")
		T.assert_true(#buffs >= 0, "preset " .. preset_name .. " is array-like")
	end
end)

T.run("state has active_preset", function()
	T.assert_nil(mod.state.active_preset, "starts nil")
end)

T.run("state initialized correctly", function()
	T.assert_not_nil(mod.state, "state exists")
	T.assert_type(mod.state, "table", "state is table")
end)

T.run("module starts disabled", function()
	T.assert_false(mod:is_enabled(), "starts disabled")
end)

T.run("can enable module", function()
	mod:enable()
	T.assert_true(mod:is_enabled(), "enabled after enable()")
	mod:disable()
end)

T.run("can disable module", function()
	mod:enable()
	mod:disable()
	T.assert_false(mod:is_enabled(), "disabled after disable()")
end)

T.run("preset values are non-empty tables", function()
	local presets = mod:get_presets()
	for preset_name, buffs in pairs(presets) do
		if #buffs > 0 then
			local first_buff = buffs[1]
			T.assert_not_nil(first_buff, "preset " .. preset_name .. " has buff entries")
		end
	end
end)

T.run("toggle works correctly", function()
	T.assert_false(mod:is_enabled(), "starts disabled")
	mod:toggle()
	T.assert_true(mod:is_enabled(), "enabled after first toggle")
	mod:toggle()
	T.assert_false(mod:is_enabled(), "disabled after second toggle")
end)

T.summary()
