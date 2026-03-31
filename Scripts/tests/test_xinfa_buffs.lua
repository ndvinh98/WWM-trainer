-- Scripts/tests/test_xinfa_buffs.lua
local T = dofile(_G.SCRIPTS_PATH .. "\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local xinfa_buffs = Reg.module("actions.xinfa_buffs")

T.run("module registered", function()
	T.assert_not_nil(xinfa_buffs)
end)

T.run("is ActionBase subclass", function()
	T.assert_not_nil(xinfa_buffs.enable)
	T.assert_not_nil(xinfa_buffs.disable)
	T.assert_not_nil(xinfa_buffs.hook)
	T.assert_not_nil(xinfa_buffs.unhook)
	T.assert_not_nil(xinfa_buffs.log)
end)

T.run("state keys have correct types", function()
	T.assert_eq(type(xinfa_buffs.state.applied_buffs), "table", "applied_buffs is table")
	T.assert_eq(type(xinfa_buffs.state.applied_xinfa_ids), "table", "applied_xinfa_ids is table")
end)

T.run("private helpers exist as module methods", function()
	T.assert_not_nil(xinfa_buffs._translate, "has _translate")
	T.assert_not_nil(xinfa_buffs._get_passive_skill_id, "has _get_passive_skill_id")
	T.assert_not_nil(xinfa_buffs._get_buff_ids, "has _get_buff_ids")
	T.assert_not_nil(xinfa_buffs._build_rank_progression, "has _build_rank_progression")
	T.assert_not_nil(xinfa_buffs._collect_all_rank_buffs, "has _collect_all_rank_buffs")
	T.assert_not_nil(xinfa_buffs._apply_buff, "has _apply_buff")
	T.assert_not_nil(xinfa_buffs._remove_buff, "has _remove_buff")
end)

T.run("public API methods exist", function()
	T.assert_not_nil(xinfa_buffs.apply, "has apply")
	T.assert_not_nil(xinfa_buffs.apply_current, "has apply_current")
	T.assert_not_nil(xinfa_buffs.remove_applied, "has remove_applied")
	T.assert_not_nil(xinfa_buffs.get_applied, "has get_applied")
	T.assert_not_nil(xinfa_buffs.is_applied, "has is_applied")
	T.assert_not_nil(xinfa_buffs.get_list, "has get_list")
	T.assert_not_nil(xinfa_buffs.get_xinfa, "has get_xinfa")
	T.assert_not_nil(xinfa_buffs.generate_data, "has generate_data")
end)

T.run("is_applied returns false initially", function()
	T.assert_false(xinfa_buffs:is_applied(), "no buffs applied initially")
end)

T.run("get_applied returns empty initially", function()
	local applied = xinfa_buffs:get_applied()
	T.assert_eq(type(applied), "table", "returns table")
	T.assert_eq(next(applied), nil, "table is empty")
end)

T.run("remove_applied returns 0 when nothing applied", function()
	local removed = xinfa_buffs:remove_applied()
	T.assert_eq(removed, 0, "nothing to remove")
end)

T.summary()
