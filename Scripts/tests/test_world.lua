-- Scripts/tests/test_world.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local mod = _G.Reg.module("actions.world")

T.run("world module registered", function()
	T.assert_not_nil(mod)
end)

T.run("module is ActionBase subclass", function()
	T.assert_not_nil(mod.state, "has state")
	T.assert_not_nil(mod.is_enabled, "has is_enabled method")
end)

T.run("has speed presets", function()
	local presets = mod:get_speed_presets()
	T.assert_not_nil(presets, "presets exists")
	T.assert_true(#presets > 0, "has at least one preset")
end)

T.run("speed presets are valid table entries", function()
	local presets = mod:get_speed_presets()
	for i, preset in ipairs(presets) do
		T.assert_not_nil(preset, "preset " .. i .. " exists")
	end
end)

T.run("state has current_speed", function()
	T.assert_eq(mod.state.current_speed, 1.0)
end)

T.run("state speed is a number", function()
	T.assert_type(mod.state.current_speed, "number", "current_speed is number")
end)


T.run("can enable and disable", function()
	mod:enable()
	T.assert_true(mod:is_enabled())
	mod:disable()
	T.assert_false(mod:is_enabled())
end)

T.run("toggle works correctly", function()
	T.assert_false(mod:is_enabled())
	mod:toggle()
	T.assert_true(mod:is_enabled())
	mod:toggle()
	T.assert_false(mod:is_enabled())
end)



T.run("multiple toggles work correctly", function()
	for i = 1, 3 do
		mod:toggle()
		if i % 2 == 1 then
			T.assert_true(mod:is_enabled(), "odd toggle: enabled")
		else
			T.assert_false(mod:is_enabled(), "even toggle: disabled")
		end
	end
end)

T.summary()
