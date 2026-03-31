-- Scripts/tests/test_ui_components.lua
local T = dofile(_G.SCRIPTS_PATH .. "\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local Constants = Reg.lib("Constants")
local _SCRIPTS_ROOT = Constants.SCRIPTS_ROOT

local function assert_no_legacy_registry(path)
	local f = io.open(path, "r")
	if not f then
		return
	end

	local content = f:read("*a")
	f:close()

	T.assert_false(content:find('Reg%.get%("Logger"%)') ~= nil, "no Logger flat alias in " .. path)
	T.assert_false(content:find('Reg%.get%("Constants"%)') ~= nil, "no Constants flat alias in " .. path)
	T.assert_false(content:find('Reg%.get%("Theme"%)') ~= nil, "no Theme flat alias in " .. path)
	T.assert_false(content:find('Reg%.get%("UIUtils"%)') ~= nil, "no UIUtils flat alias in " .. path)
end

-- ── Button ──

local ok_btn, Button = pcall(dofile, _SCRIPTS_ROOT .. "\\ui\\components\\button.lua")

T.run("button.lua loads", function()
	T.assert_true(ok_btn, "dofile succeeds: " .. tostring(Button))
	T.assert_not_nil(Button, "Button module loaded")
end)

T.run("Button has create and create_action", function()
	T.assert_eq(type(Button.create), "function", "has create")
	T.assert_eq(type(Button.create_action), "function", "has create_action")
end)

T.run("Button.DEFAULTS has expected keys", function()
	T.assert_not_nil(Button.DEFAULTS.width, "has width")
	T.assert_not_nil(Button.DEFAULTS.height, "has height")
	T.assert_not_nil(Button.DEFAULTS.font_size, "has font_size")
	T.assert_not_nil(Button.DEFAULTS.color_on, "has color_on")
	T.assert_not_nil(Button.DEFAULTS.color_off, "has color_off")
end)

T.run("button.lua has no Utils ref in source", function()
	local f = io.open(_SCRIPTS_ROOT .. "\\ui\\components\\button.lua", "r")
	if f then
		local content = f:read("*a")
		f:close()
		T.assert_false(content:find('Reg%.get%("Utils"%)') ~= nil, "no Utils in button.lua")
	end
end)

T.run("button.lua uses structured registry lookups", function()
	assert_no_legacy_registry(_SCRIPTS_ROOT .. "\\ui\\components\\button.lua")
end)

-- ── Dialog ──

local ok_dlg, Dialog = pcall(dofile, _SCRIPTS_ROOT .. "\\ui\\components\\dialog.lua")

T.run("dialog.lua loads", function()
	T.assert_true(ok_dlg, "dofile succeeds: " .. tostring(Dialog))
	T.assert_not_nil(Dialog, "Dialog module loaded")
end)

T.run("Dialog has create and confirm", function()
	T.assert_eq(type(Dialog.create), "function", "has create")
	T.assert_eq(type(Dialog.confirm), "function", "has confirm")
	T.assert_eq(type(Dialog.close_current), "function", "has close_current")
end)

T.run("dialog.lua has no Utils ref in source", function()
	local f = io.open(_SCRIPTS_ROOT .. "\\ui\\components\\dialog.lua", "r")
	if f then
		local content = f:read("*a")
		f:close()
		T.assert_false(content:find('Reg%.get%("Utils"%)') ~= nil, "no Utils in dialog.lua")
	end
end)

T.run("dialog.lua uses structured registry lookups", function()
	assert_no_legacy_registry(_SCRIPTS_ROOT .. "\\ui\\components\\dialog.lua")
end)

-- ── Input ──

local ok_inp, InputComp = pcall(dofile, _SCRIPTS_ROOT .. "\\ui\\components\\input.lua")

T.run("input.lua loads", function()
	T.assert_true(ok_inp, "dofile succeeds: " .. tostring(InputComp))
	T.assert_not_nil(InputComp, "Input module loaded")
end)

T.run("Input has show and show_persistent", function()
	T.assert_eq(type(InputComp.show), "function", "has show")
	T.assert_eq(type(InputComp.show_persistent), "function", "has show_persistent")
end)

T.run("Input.DEFAULTS has expected keys", function()
	T.assert_not_nil(InputComp.DEFAULTS.dialog_width, "has dialog_width")
	T.assert_not_nil(InputComp.DEFAULTS.dialog_height, "has dialog_height")
	T.assert_not_nil(InputComp.DEFAULTS.input_width, "has input_width")
	T.assert_not_nil(InputComp.DEFAULTS.font_size, "has font_size")
end)

T.run("input.lua has no Utils ref in source", function()
	local f = io.open(_SCRIPTS_ROOT .. "\\ui\\components\\input.lua", "r")
	if f then
		local content = f:read("*a")
		f:close()
		T.assert_false(content:find('Reg%.get%("Utils"%)') ~= nil, "no Utils in input.lua")
	end
end)

T.run("input.lua uses structured registry lookups", function()
	assert_no_legacy_registry(_SCRIPTS_ROOT .. "\\ui\\components\\input.lua")
end)

T.summary()
