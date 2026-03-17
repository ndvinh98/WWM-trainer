-- ============================================================
-- BUFFS.LUA - Buff Management
-- ============================================================
-- Prerequisites: Bootstrap must be loaded first

local Buffs = {}

-- Reference libs via Reg (loaded once by bootstrap)
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Utils = Reg.get("Utils")

local function _log(msg)
	Logger.log("[Buffs] " .. msg)
end

-- Presets
Buffs.PRESETS = {
	combat = { 109040, 109041, 104027, 102704, 102701, 102452, 77120 },
	hunting = { 104051 },
	farming = { 104027 },
	mining = { 104031 },
	fishing = { 104045 },
	crafting = { 104021 },
}

Buffs.DEFAULT_DURATION = 604800 -- 7 days

-- Cache combat action module
local _combat_action = nil
local function get_combat_action()
	if not _combat_action then
		_combat_action = Utils.safe_import("hexm.client.ui.windows.gm.gm_combat.combat_train_action")
	end
	return _combat_action
end

function Buffs.apply_buff(buff_id, duration)
	local mp = Utils.get_main_player()
	if not mp then
		return false, "No main player"
	end
	if type(buff_id) ~= "number" then
		return false, "Invalid buff_id"
	end

	duration = duration or Buffs.DEFAULT_DURATION

	-- Try player method
	if mp.add_buff then
		local _, err = Utils.safe_call("add_buff:" .. buff_id, mp.add_buff, mp, buff_id, duration)
		if not err then
			_log(string.format("Applied buff %d ✓", buff_id))
			return true
		end
	end

	-- Try combat action
	local action = get_combat_action()
	if action and action.add_buff then
		local _, err = Utils.safe_call("action.add_buff:" .. buff_id, action.add_buff, buff_id)
		if not err then
			_log(string.format("Applied buff %d via action ✓", buff_id))
			return true
		end
	end

	_log(string.format("Failed to apply buff %d", buff_id))
	return false, "No method available"
end

function Buffs.remove_buff(buff_id)
	local mp = Utils.get_main_player()
	local eid = mp and mp.entity_id
	local action = get_combat_action()

	_log(string.format("Removing buff %d...", buff_id))

	-- Try various methods
	local methods = {
		{ obj = action, name = "rm_buff", args = { buff_id } },
		{ obj = action, name = "remove_buff", args = { buff_id, eid } },
		{ obj = action, name = "del_buff", args = { buff_id, eid } },
		{ obj = mp, name = "remove_buff", args = { mp, buff_id } },
		{ obj = mp, name = "del_buff", args = { mp, buff_id } },
		{ obj = mp, name = "remove_buffs_by_No", args = { mp, buff_id } },
	}

	for _, m in ipairs(methods) do
		if m.obj and m.obj[m.name] then
			local _, err = Utils.safe_call(m.name .. ":" .. buff_id, m.obj[m.name], table.unpack(m.args))
			if not err then
				_log(string.format("Removed buff %d via %s ✓", buff_id, m.name))
				return true
			end
		end
	end

	_log(string.format("Failed to remove buff %d", buff_id))
	return false, "No method worked"
end

function Buffs.apply_preset(preset_name)
	local buffs = Buffs.PRESETS[preset_name]
	if not buffs then
		_log("Unknown preset: " .. tostring(preset_name))
		return 0, 0
	end

	local applied = 0
	for _, buff_id in ipairs(buffs) do
		if Buffs.apply_buff(buff_id) then
			applied = applied + 1
		end
	end

	_log(string.format("Applied preset '%s': %d/%d", preset_name, applied, #buffs))
	return applied, #buffs
end

function Buffs.remove_preset(preset_name)
	local buffs = Buffs.PRESETS[preset_name]
	if not buffs then
		_log("Unknown preset: " .. tostring(preset_name))
		return 0, 0
	end

	local removed = 0
	for _, buff_id in ipairs(buffs) do
		if Buffs.remove_buff(buff_id) then
			removed = removed + 1
		end
	end

	_log(string.format("Removed preset '%s': %d/%d", preset_name, removed, #buffs))
	return removed, #buffs
end

function Buffs.toggle_preset(preset_name, enabled)
	if enabled then
		local applied, total = Buffs.apply_preset(preset_name)
		return true, applied, total
	else
		local removed, total = Buffs.remove_preset(preset_name)
		return false, removed, total
	end
end

return Buffs
