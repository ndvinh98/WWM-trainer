-- Scripts/tests/test_gm_panel.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local mod = _G.Reg.module("actions.gm_panel")

T.run("gm_panel module registered", function()
	T.assert_not_nil(mod)
end)

T.run("module is ActionBase subclass", function()
	T.assert_not_nil(mod.state, "has state")
	T.assert_not_nil(mod.is_enabled, "has is_enabled method")
end)

T.run("has state keys", function()
	T.assert_type(mod.state.translation_enabled, "boolean", "translation_enabled")
	T.assert_type(mod.state.capture_enabled, "boolean", "capture_enabled")
	T.assert_type(mod.state.translations, "table", "translations")
	T.assert_type(mod.state.written_keys, "table", "written_keys")
end)

T.run("state keys have correct defaults", function()
	T.assert_true(mod.state.translation_enabled, "translation_enabled default true")
	T.assert_false(mod.state.capture_enabled, "capture_enabled default false")
end)

T.run("hook/unhook lifecycle", function()
	mod:hook("text_set_text")
	T.assert_true(mod:is_hooked("text_set_text"), "hook activates")

	mod:unhook("text_set_text")
	T.assert_false(mod:is_hooked("text_set_text"), "unhook deactivates")
end)

T.run("disable cleans up", function()
	mod:hook("text_set_text")
	mod:disable()
	T.assert_false(mod:is_hooked("text_set_text"), "disable unhooks")
	T.assert_false(mod:is_enabled(), "disable sets enabled false")
end)

T.run("starts disabled", function()
	T.assert_false(mod:is_enabled(), "starts disabled")
end)

T.run("can enable and disable", function()
	mod:enable()
	T.assert_true(mod:is_enabled(), "enabled after enable()")
	mod:disable()
	T.assert_false(mod:is_enabled(), "disabled after disable()")
end)

T.run("toggle works correctly", function()
	T.assert_false(mod:is_enabled())
	mod:toggle()
	T.assert_true(mod:is_enabled())
	mod:toggle()
	T.assert_false(mod:is_enabled())
end)



T.summary()
