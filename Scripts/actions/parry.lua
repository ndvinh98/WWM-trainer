local ActionBase = _G.Reg.lib("ActionBase")
local Parry = ActionBase:extend("actions.parry")

local MODULE_LISTENABLE = "hexm.client.util.listenable"

local SLOT_PARRY = 16
local SLOT_DASH = 7

function Parry:define_state()
	return {
		persistent = {
			log_enabled = false,
		},
		transient = {
			events_module = nil,
			useful_npc_events = {
				E_SKILL_ANIM_BEGIN_CLIENT = true,
				E_GD_SIGNAL = true,
				E_BONE_COLLISION = true,
				E_BEHIT_BEGAN = true,
				E_DAMAGE_BEHIT_BEGAN = true,
				E_BE_PARRY = true,
				E_SKILL_START = true,
				E_SKILL_RELEASE = true,
				E_SKILL_END = true,
				E_PRE_HIT = true,
			},
		},
	}
end

function Parry:define_hooks()
	return {
		listenable = {
			spec = MODULE_LISTENABLE .. ":Listenable:_notify_declared_additional_listens",
			post_exec = function(self_action, args, results, traceback)
				self_action:_intercept_listenable(args)
			end,
		},
	}
end

function Parry:_get_events()
	if not self.state.events_module then
		local ok, m = pcall(portable.safe_import, "hexm.client.consts.events")
		if ok and m then self.state.events_module = m end
	end
	return self.state.events_module
end

function Parry:_get_key_by_value(tbl, value)
	for k, v in pairs(tbl) do
		if v == value then return k end
	end
	return nil
end

function Parry:_safe_get(obj, key, default)
	if obj == nil then return default end
	local ok, value = pcall(function() return obj[key] end)
	if ok and value ~= nil then return value end
	local ok_getter, getter = pcall(function() return obj.get end)
	if ok_getter and type(getter) == "function" then
		local ok_get, value_get = pcall(function() return getter(obj, key, default) end)
		if ok_get then return value_get end
	end
	return default
end

function Parry:_intercept_listenable(args)
	local entity = args[1]
	local ins_str = tostring(entity)
	local event = args[3]
	local event_data = args[4]
	local events = self:_get_events()
	local ev_name = events and self:_get_key_by_value(events, event) or "N/A"

	if ins_str:find("PlayerAvatar") and ev_name == "E_DAMAGE_BEHIT_BEGAN" then
		local Serialize = _G.Reg.lib("Serialize")
		local fromer_id = self:_safe_get(event_data, "fromer_id", nil)
		local skill_id = self:_safe_get(event_data, "skill_id", nil)
		local ctx = self:_safe_get(event_data, "context", nil)
		if not skill_id and ctx then
			skill_id = self:_safe_get(ctx, "skill_id", nil)
		end
		local calcpoint_id = self:_safe_get(event_data, "calcpoint_id", nil)
		local dmg = self:_safe_get(event_data, "damage", nil)

		local attacker = G.space:get_entity(fromer_id)
		local anim, curr_segment
		pcall(function()
			anim = attacker.skill_driver:get_ex_data("cur_anim")
			curr_segment = attacker.skill_driver.cur_skill_segment
		end)

		self:log(string.format(
			"PLAYER DAMAGE skill=%s anim=%s seg=%s cp=%s dmg=%s from=%s data=%s",
			tostring(skill_id), tostring(anim), tostring(curr_segment),
			tostring(calcpoint_id), tostring(dmg), tostring(fromer_id),
			Serialize.dump_value(event_data)
		))
	end

	if not ins_str:find("Npc") and not ins_str:find("CombativeAnimal") then return end

	if ev_name == "E_PRE_HIT" then
		local difficulty = G.main_player.skill_ctrl:get_difficulty()
		local skill_id = entity.skill_driver.cur_skill.skill_id
		local skill_d = G.datam.skills:get(tonumber(skill_id))
		local huajie = self:_safe_get(skill_d, "huajie", nil)
		self:log(string.format("NPC PRE_HIT skill=%s parriable=%s diff=%s",
			tostring(skill_id), tostring(huajie ~= nil), tostring(difficulty)))
		if huajie ~= nil then
			G.main_player:try_use_parry()
		else
			local dash_skill_no = G.main_player:get_skill_no_by_slot(SLOT_DASH)
			G.main_player:use_skill(dash_skill_no)
		end
	end

	if self.state.useful_npc_events[tostring(ev_name)] then
		self:log("NPC EVENT " .. ev_name .. " code=" .. tostring(event))
	end
end

function Parry:enable()
	self:hook("listenable")
	self.state.is_enabled = true
	self:log("Enabled")
	return true
end

function Parry:disable()
	self:unhook("listenable")
	self.state.is_enabled = false
	self:log("Disabled")
	return true
end

function Parry:is_enabled()
	return self.state.is_enabled == true
end

return Parry:new()
