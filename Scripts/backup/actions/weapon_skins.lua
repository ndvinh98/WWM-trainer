-- ============================================================
-- WEAPON_SKINS.LUA - Weapon Skin Changer with Persistent Mode
-- ============================================================
-- Prerequisites: Bootstrap must be loaded first

local WeaponSkins = {}

-- Reference libs via Reg (loaded once by bootstrap)
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Utils = Reg.get("Utils")
local Hooks = Reg.get("Hooks")
local HookInterceptor = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\lib\\hook_interceptor.lua", "HookInterceptor")

local function _log(msg)
	Logger.log("[WeaponSkins] " .. msg)
end

-- Hook ID
local HOOK_CREATE_WEAPON = "weapon_skins_create_weapon"

-- Module path
local MODULE_PLAYER_AVATAR = "hexm.client.entities.local.player_avatar"

-- ============================================================
-- STATE (registered via Reg for reload safety)
-- ============================================================
local WEAPON_SKIN_STATE_NAME = "WEAPON_SKIN_STATE"
if not Reg.has(WEAPON_SKIN_STATE_NAME) then
	Reg.set(WEAPON_SKIN_STATE_NAME, WeaponSkins)
end
local _state = Reg.get(WEAPON_SKIN_STATE_NAME)

-- Subtype to weapon_type mapping (matches kongfu weapon_type)
local SUBTYPE_TO_WEAPON_TYPE = {
	[22] = 101, -- Sword
	[23] = 102, -- Spear
	[24] = 103, -- Fan
	[25] = 107, -- Dual Blades
	[26] = 106, -- Saber
	[27] = 109, -- Umbrella
	[28] = 110, -- Rope Dart
	[30] = 108, -- Bow
	[31] = 111, -- Blade
}

local SUBTYPE_NAMES = {
	[22] = "Sword",
	[23] = "Spear",
	[24] = "Fan",
	[25] = "Dual Blades",
	[26] = "Saber",
	[27] = "Umbrella",
	[28] = "Rope Dart",
	[30] = "Bow",
	[31] = "Blade",
}

-- ============================================================
-- WEAPON SKIN DATA (generated from G.datam)
-- ============================================================

function WeaponSkins.generate_weapon_data()
	if not G or not G.datam then
		_log("ERROR: G.datam not available")
		return nil, nil
	end

	if not G.datam.guise_items then
		_log("ERROR: G.datam.guise_items not available")
		return nil, nil
	end

	-- Build weapon_type -> kongfu list mapping
	local weapon_type_to_kongfu = {}
	if G.datam.kongfu then
		local kongfu_items = G.datam.kongfu:items()
		if kongfu_items then
			for _, kf_entry in pairs(kongfu_items) do
				local kf_id = tonumber(kf_entry[1])
				local kf = kf_entry[2]
				if kf_id and kf then
					local wt = kf:get("weapon_type", nil)
					local name_tid = kf:get("name", nil)
					if wt then
						if not weapon_type_to_kongfu[wt] then
							weapon_type_to_kongfu[wt] = {}
						end
						local kf_name = Utils.translate(name_tid) or ("Kongfu " .. kf_id)
						local tbl = weapon_type_to_kongfu[wt]
						tbl[#tbl + 1] = { kongfu_id = kf_id, name = kf_name }
					end
				end
			end
		end
	end

	-- Iterate guise_items, filter weapon_view == 1
	local weapon_data = {}
	local weapon_skin_list = {}
	local count = 0

	local items = G.datam.guise_items:items()
	if not items then
		_log("ERROR: guise_items:items() returned nil")
		return nil, nil
	end

	for _, entry in pairs(items) do
		local item_no = tonumber(entry[1])
		local d = entry[2]
		if item_no and d then
			if d:get("weapon_view", 0) == 1 then
				local name_tid = d:get("name", nil)
				local name = Utils.translate(name_tid) or ("Weapon Skin " .. item_no)
				local subtype = d:get("subtype", 0)
				local subtype_name = SUBTYPE_NAMES[subtype] or ("Type " .. subtype)
				local weapon_type = SUBTYPE_TO_WEAPON_TYPE[subtype]
				local star = d:get("star", 0)
				local category = d:get("category", 0)
				local view_no = d:get("view_no", item_no)
				local default_skin = d:get("default_skin", 0)
				local compatible_kongfu = weapon_type_to_kongfu[weapon_type] or {}

				weapon_data[item_no] = {
					item_no = item_no,
					name = name,
					subtype = subtype,
					subtype_name = subtype_name,
					category = category,
					star = star,
					view_no = view_no,
					default_skin = default_skin,
					weapon_type = weapon_type,
					compatible_kongfu = compatible_kongfu,
				}

				local first_kongfu_id = compatible_kongfu[1] and compatible_kongfu[1].kongfu_id or nil
				weapon_skin_list[#weapon_skin_list + 1] = {
					item_no = item_no,
					name = name,
					star = star,
					subtype = subtype,
					subtype_name = subtype_name,
					weapon_type = weapon_type,
					kongfu_id = first_kongfu_id,
				}

				count = count + 1
			end
		end
	end

	-- Sort by star desc, then item_no asc
	table.sort(weapon_skin_list, function(a, b)
		if a.star ~= b.star then
			return a.star > b.star
		end
		return a.item_no < b.item_no
	end)

	-- Store in Reg
	_state.weapon_data = weapon_data
	_state.weapon_skin_list = weapon_skin_list

	_log("Generated " .. count .. " weapon skins")
	return weapon_data, weapon_skin_list
end
--- Load weapon data (generate once, then from Reg cache)
function WeaponSkins.load_weapon_data()
	local weapon_data = _state.weapon_data
	local weapon_skin_list = _state.weapon_skin_list
	if weapon_data and weapon_skin_list then
		return weapon_data, weapon_skin_list
	end
	return WeaponSkins.generate_weapon_data()
end

function WeaponSkins.get_weapon_list()
	local _, skin_list = WeaponSkins.load_weapon_data()
	return skin_list or {}
end

function WeaponSkins.get_weapon_data(item_no)
	local data, _ = WeaponSkins.load_weapon_data()
	return data and data[tonumber(item_no)]
end

-- ============================================================
-- APPLY WEAPON SKIN
-- ============================================================
function WeaponSkins.disable()
	if _state.hook_installed then
		_state.hook_installed:unhook_all()
		_state.hook_installed = nil
		_state.item_nos = {}
	end
end

function WeaponSkins.install_hook()
	if _state.hook_installed then
		return
	end
	_state.hook_installed = HookInterceptor.create({
		{
			spec = "hexm.client.entities.local.player_avatar:PlayerAvatar:_create_weapon",
			post_exec = function(spec, args, results, traceback)
				Utils.delay_call(0.2, function()
					for _, skin_no in ipairs(_state.item_nos) do
						WeaponSkins.apply(skin_no)
					end
				end)
			end,
		},
	})
end

function WeaponSkins.apply(item_no)
	WeaponSkins.install_hook()
	-- Check if this item_no is already in the list
	local already_added = false
	for _, existing_item_no in ipairs(_state.item_nos) do
		if existing_item_no == item_no then
			already_added = true
			break
		end
	end

	if not already_added then
		table.insert(_state.item_nos, item_no)
		_log("Added weapon skin to persistent list: " .. item_no)
	else
		_log("Weapon skin already in persistent list: " .. item_no)
	end

	local mp = Utils.get_main_player()
	if not mp then
		return false, "No main player"
	end

	item_no = tonumber(item_no)
	if not item_no then
		return false, "Invalid item_no"
	end

	_log("Applying weapon skin: " .. item_no)

	-- Verify weapon skin exists
	local weapon_data = WeaponSkins.get_weapon_data(item_no)
	if not weapon_data then
		_log("WARNING: Weapon skin " .. item_no .. " not found in data")
	end

	-- Apply weapon skin using the game's method
	if mp.equip_weapon_dressing then
		local ok, err = pcall(function()
			return mp:equip_weapon_dressing(item_no)
		end)

		if ok then
			_log("SUCCESS: Applied weapon skin " .. item_no)
			return true
		else
			_log("ERROR: Failed to apply weapon skin: " .. tostring(err))
			return false, tostring(err)
		end
	end

	return false, "equip_weapon_dressing method not found"
end

return WeaponSkins
