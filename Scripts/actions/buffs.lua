-- Scripts/actions/buffs.lua
local ActionBase = _G.Reg.lib("ActionBase")

local Buffs = ActionBase:extend("actions.buffs")

-- ── Constants ──
local PRESETS = {
	combat = { 109040, 109041, 104027, 102704, 102701, 102452, 77120 },
	hunting = { 104051 },
	farming = { 104027 },
	mining = { 104031 },
	fishing = { 104045 },
	crafting = { 104021 },
}

local DEFAULT_DURATION = 604800 -- 7 days

-- ── State ──
function Buffs:define_state()
	return {
		persistent = { active_preset = nil },
		transient = {},
	}
end

-- Hooks to re-apply buffs after map transition / reconnection
function Buffs:define_hooks()
	local function _on_transition(self_action)
		if not self_action.state.active_preset then
			return
		end
		local preset_name = self_action.state.active_preset
		self_action:log("Buff wipe detected — re-applying preset '" .. preset_name .. "'")
		_G.Reg.lib("Cocos").delay_call(0.5, function()
			self_action:_reapply(preset_name)
		end)
	end

	return {
		buff_resync = {
			spec = "hexm.client.fake_server.entities.player_avatar_members.imp_buff:FakePlayerAvatarMember:_buff_resync_server_buffs",
			post_exec = function(self_action, args, results, tb)
				_on_transition(self_action)
			end,
		},
		mode_single_in = {
			spec = "hexm.client.entities.local.player_avatar_members.imp_buff:PlayerAvatarMember:__mode_single_in_component__",
			post_exec = function(self_action, args, results, tb)
				_on_transition(self_action)
			end,
		},
	}
end

-- ── Helpers ──

local function _get_combat_action()
	local ok, mod = pcall(portable.safe_import, "hexm.client.ui.windows.gm.gm_combat.combat_train_action")
	if ok and mod then
		return mod
	end
	return nil
end

-- ── Persistence ──

function Buffs:_reapply(preset_name)
	local mp = G.main_player
	if not mp then
		self:log("Re-apply skipped — no main player")
		return
	end
	local buffs = PRESETS[preset_name]
	if not buffs then
		self:log("Re-apply skipped — unknown preset: " .. tostring(preset_name))
		return
	end
	local applied = 0
	for _, buff_id in ipairs(buffs) do
		if self:apply_buff(buff_id) then
			applied = applied + 1
		end
	end
	self:log(string.format("Re-applied preset '%s': %d/%d", preset_name, applied, #buffs))
end

function Buffs:_update_hooks()
	if self.state.active_preset then
		self:hook("buff_resync")
		self:hook("mode_single_in")
	else
		self:unhook("buff_resync")
		self:unhook("mode_single_in")
	end
end

-- ── Public API ──

function Buffs:apply_buff(buff_id, duration)
	local mp = G.main_player
	if not mp then
		return false, "No main player"
	end
	if type(buff_id) ~= "number" then
		return false, "Invalid buff_id"
	end

	duration = duration or DEFAULT_DURATION

	-- Try player method
	if mp.add_buff then
		local ok, err = pcall(mp.add_buff, mp, buff_id, duration)
		if ok then
			self:log(string.format("Applied buff %d", buff_id))
			return true
		end
	end

	-- Try combat action
	local action = _get_combat_action()
	if action and action.add_buff then
		local ok, err = pcall(action.add_buff, buff_id)
		if ok then
			self:log(string.format("Applied buff %d via action", buff_id))
			return true
		end
	end

	self:log(string.format("Failed to apply buff %d", buff_id))
	return false, "No method available"
end

function Buffs:remove_buff(buff_id)
	local mp = G.main_player
	if not mp then
		return false
	end
	local eid = mp.entity_id
	local action = _get_combat_action()

	local methods = {
		{ obj = action, name = "rm_buff", args = { buff_id } },
		{ obj = action, name = "remove_buff", args = { buff_id, eid } },
		{ obj = mp, name = "remove_buff", args = { mp, buff_id } },
		{ obj = mp, name = "remove_buffs_by_No", args = { mp, buff_id } },
	}

	for _, m in ipairs(methods) do
		if m.obj and m.obj[m.name] then
			local ok = pcall(m.obj[m.name], table.unpack(m.args))
			if ok then
				self:log(string.format("Removed buff %d via %s", buff_id, m.name))
				return true
			end
		end
	end

	return false, "No method worked"
end

function Buffs:apply_preset(preset_name)
	local buffs = PRESETS[preset_name]
	if not buffs then
		self:log("Unknown preset: " .. tostring(preset_name))
		return 0, 0
	end

	local applied = 0
	for _, buff_id in ipairs(buffs) do
		if self:apply_buff(buff_id) then
			applied = applied + 1
		end
	end

	self.state.active_preset = preset_name
	self:_update_hooks()
	self:log(string.format("Applied preset '%s': %d/%d", preset_name, applied, #buffs))
	return applied, #buffs
end

function Buffs:remove_preset(preset_name)
	local buffs = PRESETS[preset_name]
	if not buffs then
		return 0, 0
	end

	local removed = 0
	for _, buff_id in ipairs(buffs) do
		if self:remove_buff(buff_id) then
			removed = removed + 1
		end
	end

	if self.state.active_preset == preset_name then
		self.state.active_preset = nil
	end
	self:_update_hooks()

	self:log(string.format("Removed preset '%s': %d/%d", preset_name, removed, #buffs))
	return removed, #buffs
end

function Buffs:toggle_preset(preset_name, enabled)
	if enabled then
		return true, self:apply_preset(preset_name)
	else
		return false, self:remove_preset(preset_name)
	end
end

function Buffs:get_presets()
	return PRESETS
end

return Buffs:new()
