-- Scripts/tests/test_menu_config.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local Constants = Reg.get("Constants")
local _SCRIPTS_ROOT = Constants.SCRIPTS_ROOT

local ok, MenuConfig = pcall(dofile, _SCRIPTS_ROOT .. "\\ui\\menu_config.lua")

T.run("menu_config loads", function()
	T.assert_true(ok, "dofile succeeds")
	T.assert_not_nil(MenuConfig, "MenuConfig is not nil")
end)

T.run("TABS is a table", function()
	T.assert_eq(type(MenuConfig.TABS), "table", "TABS is table")
	T.assert_true(#MenuConfig.TABS > 0, "has at least one tab")
end)

T.run("no Utils reference in module", function()
	local source_path = _SCRIPTS_ROOT .. "\\ui\\menu_config.lua"
	local f = io.open(source_path, "r")
	if f then
		local content = f:read("*a")
		f:close()
		local has_utils = content:find('Reg%.get%("Utils"%)') ~= nil
		T.assert_false(has_utils, "no Reg.get(\"Utils\") in menu_config.lua")
		local has_safe_dofile = content:find('Utils%.safe_dofile') ~= nil
		T.assert_false(has_safe_dofile, "no Utils.safe_dofile in menu_config.lua")
	else
		T.assert_true(false, "could not read source file")
	end
end)

T.run("each tab has name and items", function()
	for i, tab in ipairs(MenuConfig.TABS) do
		T.assert_not_nil(tab.name, "tab " .. i .. " has name")
		T.assert_eq(type(tab.items), "table", "tab " .. i .. " has items table")
		T.assert_true(#tab.items > 0, "tab " .. i .. " has at least one item")
	end
end)

T.run("each item has id, type, label", function()
	for _, tab in ipairs(MenuConfig.TABS) do
		for _, item in ipairs(tab.items) do
			T.assert_not_nil(item.id, "item has id")
			T.assert_not_nil(item.type, "item " .. item.id .. " has type")
			T.assert_not_nil(item.label, "item " .. item.id .. " has label")
		end
	end
end)

T.run("state defaults exist", function()
	T.assert_not_nil(MenuConfig.DUMP_FORMAT, "DUMP_FORMAT exists")
	T.assert_eq(type(MenuConfig.AUTO_SPLIT), "boolean", "AUTO_SPLIT is boolean")
end)

T.summary()
