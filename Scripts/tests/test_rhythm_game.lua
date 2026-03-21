-- Scripts/tests/test_rhythm_game.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local mod = Reg.module("actions.rhythm_game")

-- 1. Module registered
T.run("module registered", function()
	T.assert_not_nil(mod, "module")
end)

-- 2. Is ActionBase subclass
T.run("is ActionBase subclass", function()
	T.assert_not_nil(mod.state, "has state")
	T.assert_not_nil(mod.is_enabled, "has is_enabled method")
end)

-- 3. State keys correct types
T.run("state initialized with correct types", function()
	T.assert_type(mod.state.auto_perfect, "boolean", "auto_perfect is boolean")
end)

-- 4. Enable/disable lifecycle
T.run("enable disable lifecycle", function()
	mod:enable()
	T.assert_true(mod:is_enabled(), "enabled after enable()")
	mod:disable()
	T.assert_false(mod:is_enabled(), "disabled after disable()")
end)

-- 5. Toggle works
T.run("toggle works", function()
	T.assert_false(mod:is_enabled(), "starts disabled")
	mod:toggle()
	T.assert_true(mod:is_enabled(), "enabled after toggle")
	mod:toggle()
	T.assert_false(mod:is_enabled(), "disabled after second toggle")
end)

-- 6. set_auto_perfect method exists
T.run("set_auto_perfect method exists", function()
	T.assert_not_nil(mod.set_auto_perfect, "method exists")
	T.assert_type(mod.set_auto_perfect, "function", "is function")
end)

-- 7. set_auto_perfect updates state
T.run("set_auto_perfect updates state", function()
	mod:set_auto_perfect(true)
	T.assert_true(mod.state.auto_perfect, "auto_perfect is true after set(true)")
	mod:set_auto_perfect(false)
	T.assert_false(mod.state.auto_perfect, "auto_perfect is false after set(false)")
end)

-- 8. Hook defined for auto_perfect_result
T.run("hook defined for auto_perfect_result", function()
	local hooks = mod:define_hooks()
	T.assert_not_nil(hooks.auto_perfect_result, "auto_perfect_result hook defined")
	T.assert_not_nil(hooks.auto_perfect_result.spec, "hook has spec")
end)

-- 9. set_auto_perfect sets G.RHYTHM_GAME_AUTO_PLAY flag
T.run("set_auto_perfect sets game auto_play flag", function()
	mod:set_auto_perfect(true)
	T.assert_true(G.RHYTHM_GAME_AUTO_PLAY == true, "G.RHYTHM_GAME_AUTO_PLAY is true")
	mod:set_auto_perfect(false)
	T.assert_true(G.RHYTHM_GAME_AUTO_PLAY == nil, "G.RHYTHM_GAME_AUTO_PLAY is nil after disable")
end)

-- 10. Persistent state survives reload simulation
T.run("persistent state survives reload", function()
	mod.state.auto_perfect = true
	mod:_init_state()
	T.assert_true(mod.state.auto_perfect, "auto_perfect survived reload")
	-- Clean up
	mod.state.auto_perfect = false
end)

T.summary()
