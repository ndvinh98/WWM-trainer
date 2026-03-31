-- Scripts/tests/test_skill_unrestrict.lua
local T = dofile(_G.SCRIPTS_PATH .. "\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local mod = Reg.module("actions.skill_unrestrict")

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
T.run("state initialized", function()
	T.assert_type(mod.state.unrestrict_skills, "boolean", "unrestrict_skills is bool")
end)

-- 4. Hook lifecycle — bypass_forbid_skill
T.run("hook lifecycle bypass_forbid_skill", function()
	mod:hook("bypass_forbid_skill")
	T.assert_true(mod:is_hooked("bypass_forbid_skill"), "hooked")
	mod:unhook("bypass_forbid_skill")
	T.assert_false(mod:is_hooked("bypass_forbid_skill"), "unhooked")
end)

-- 5. Hook lifecycle — bypass_skill_forbidden
T.run("hook lifecycle bypass_skill_forbidden", function()
	mod:hook("bypass_skill_forbidden")
	T.assert_true(mod:is_hooked("bypass_skill_forbidden"), "hooked")
	mod:unhook("bypass_skill_forbidden")
	T.assert_false(mod:is_hooked("bypass_skill_forbidden"), "unhooked")
end)

-- 6. Hook lifecycle — bypass_rule_forbidden
T.run("hook lifecycle bypass_rule_forbidden", function()
	mod:hook("bypass_rule_forbidden")
	T.assert_true(mod:is_hooked("bypass_rule_forbidden"), "hooked")
	mod:unhook("bypass_rule_forbidden")
	T.assert_false(mod:is_hooked("bypass_rule_forbidden"), "unhooked")
end)

-- 7. set_unrestrict_skills hooks and unhooks correctly
T.run("set_unrestrict_skills hooks correctly", function()
	mod:set_unrestrict_skills(true)
	T.assert_true(mod:is_hooked("bypass_forbid_skill"), "forbid hooked")
	T.assert_true(mod:is_hooked("bypass_skill_forbidden"), "skill_forbidden hooked")
	T.assert_true(mod:is_hooked("bypass_rule_forbidden"), "rule_forbidden hooked")
	T.assert_true(mod.state.unrestrict_skills, "state is true")

	mod:set_unrestrict_skills(false)
	T.assert_false(mod:is_hooked("bypass_forbid_skill"), "forbid unhooked")
	T.assert_false(mod:is_hooked("bypass_skill_forbidden"), "skill_forbidden unhooked")
	T.assert_false(mod:is_hooked("bypass_rule_forbidden"), "rule_forbidden unhooked")
	T.assert_false(mod.state.unrestrict_skills, "state is false")
end)

-- 8. Enable/disable toggles correctly
T.run("enable disable", function()
	T.assert_false(mod:is_enabled())
	mod:enable()
	T.assert_true(mod:is_enabled())
	mod:disable()
	T.assert_false(mod:is_enabled())
end)

-- 9. disable unhooks all
T.run("disable unhooks all", function()
	mod:set_unrestrict_skills(true)
	mod:disable()
	T.assert_false(mod:is_hooked("bypass_forbid_skill"), "forbid unhooked")
	T.assert_false(mod:is_hooked("bypass_skill_forbidden"), "skill_forbidden unhooked")
	T.assert_false(mod:is_hooked("bypass_rule_forbidden"), "rule_forbidden unhooked")
	T.assert_false(mod:is_enabled())
end)

T.summary()
