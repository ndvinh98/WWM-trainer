local T = dofile(_G.SCRIPTS_PATH .. "\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local Constants = Reg.get("Constants")
local dump = Reg.module("actions.dump_static_data")

T.run("module registered", function()
	T.assert_not_nil(dump)
end)

T.run("is ActionBase subclass", function()
	T.assert_not_nil(dump.enable)
	T.assert_not_nil(dump.disable)
	T.assert_not_nil(dump.hook)
	T.assert_not_nil(dump.unhook)
	T.assert_not_nil(dump.log)
end)

T.run("state has correct defaults", function()
	T.assert_eq(type(dump.state), "table", "state table exists")
end)

T.run("public API methods exist", function()
	T.assert_not_nil(dump.dump_grey_table, "has dump_grey_table")
	T.assert_not_nil(dump.dump_dir_object_cache, "has dump_dir_object_cache")
	T.assert_not_nil(dump.dump_dir_object_weak_cache, "has dump_dir_object_weak_cache")
	T.assert_not_nil(dump.get_output_dir, "has get_output_dir")
	T.assert_not_nil(dump.get_output_path, "has get_output_path")
end)

T.run("get_output_dir resolves retained dump targets", function()
	T.assert_eq(dump:get_output_dir("grey"), Constants.DATA_ROOT .. "\\DirObject\\GreyTableInfo", "grey output dir")
	T.assert_eq(dump:get_output_dir("cache"), Constants.DATA_ROOT .. "\\DirObject\\DirObject_Cache", "cache output dir")
	T.assert_eq(
		dump:get_output_dir("weak_cache"),
		Constants.DATA_ROOT .. "\\DirObject\\DirObject_WeakCache",
		"weak cache output dir"
	)
end)

T.run("real game-data names map to expected output paths", function()
	local grey_path = dump:get_output_path("grey", "hexm.client.data_oversea.xinfa")
	local cache_path = dump:get_output_path("cache", "hexm.client.data_oversea.entity_tags")
	local weak_path = dump:get_output_path("weak_cache", "hexm.client.data_oversea.region_game_config")
	T.assert_eq(
		grey_path,
		Constants.DATA_ROOT .. "\\DirObject\\GreyTableInfo\\hexm.client.data_oversea.xinfa.json",
		"grey path"
	)
	T.assert_eq(
		cache_path,
		Constants.DATA_ROOT .. "\\DirObject\\DirObject_Cache\\hexm.client.data_oversea.entity_tags.json",
		"cache path"
	)
	T.assert_eq(
		weak_path,
		Constants.DATA_ROOT .. "\\DirObject\\DirObject_WeakCache\\hexm.client.data_oversea.region_game_config.json",
		"weak path"
	)
end)

T.summary()
