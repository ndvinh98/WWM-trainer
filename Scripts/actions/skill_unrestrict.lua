-- Scripts/actions/skill_unrestrict.lua
local ActionBase = _G.Reg.lib("ActionBase")
local errcode = portable.safe_import("hexm.common.errcode")

local SkillUnrestrict = ActionBase:extend("actions.skill_unrestrict")

-- ── Constants ──
local ERR_OK = errcode and errcode.ERR_OK or 0
local ERR_SKILL_FORBID_ABLITY_LIMIT = errcode and errcode.ERR_SKILL_FORBID_ABLITY_LIMIT or nil

function SkillUnrestrict:define_state()
	return {
		persistent = {
			unrestrict_skills = false,
		},
		transient = {},
	}
end

function SkillUnrestrict:define_hooks()
	return {
		-- Bypass _forbid_skill flag and ability limit in PAvtSkillCtrl:check_use_skill_new
		bypass_forbid_skill = {
			spec = "hexm.client.combat.skill_ctrl:PAvtSkillCtrl:check_use_skill_new",
			override_orig_function = true,
			post_exec = function(self_action, original, self_ctrl, skill_context, reason_map)
				-- Temporarily clear _forbid_skill so original doesn't block
				local saved = self_ctrl._forbid_skill
				self_ctrl._forbid_skill = false

				local ret, tip, ex = original(self_ctrl, skill_context, reason_map)

				-- Restore original state
				self_ctrl._forbid_skill = saved

				-- Swallow ability-limit errors
				if ERR_SKILL_FORBID_ABLITY_LIMIT and ret == ERR_SKILL_FORBID_ABLITY_LIMIT then
					ret = ERR_OK
					tip = nil
				end

				return ret, tip, ex
			end,
		},
		-- Bypass game_forbidden_rule.check_skill_forbidden_state (jump skill restrictions)
		bypass_skill_forbidden = {
			spec = "hexm.common.game_forbidden_rule:check_skill_forbidden_state",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return nil
			end,
		},
		-- Bypass game_forbidden_rule.check_rule_forbidden_state (fly/region restrictions)
		bypass_rule_forbidden = {
			spec = "hexm.common.game_forbidden_rule:check_rule_forbidden_state",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return nil
			end,
		},
	}
end

-- ── Public API ──

function SkillUnrestrict:set_unrestrict_skills(enabled)
	if enabled then
		self:hook("bypass_forbid_skill")
		self:hook("bypass_skill_forbidden")
		self:hook("bypass_rule_forbidden")
	else
		self:unhook("bypass_forbid_skill")
		self:unhook("bypass_skill_forbidden")
		self:unhook("bypass_rule_forbidden")
	end
	self.state.unrestrict_skills = enabled
	self:log("Unrestrict Skills: " .. (enabled and "ON" or "OFF"))
end

return SkillUnrestrict:new()
