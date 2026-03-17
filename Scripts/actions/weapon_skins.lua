-- Scripts/actions/weapon_skins.lua
local ActionBase = _G.Reg.lib("ActionBase")

local WeaponSkins = ActionBase:extend("actions.weapon_skins")

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

function WeaponSkins:define_state()
	return {
		persistent = {
			item_nos = {}, -- List of weapon skin item_nos to persistently apply
			weapon_data = nil, -- Generated weapon data cache
			weapon_skin_list = nil,
		},
		transient = {},
	}
end

function WeaponSkins:define_hooks()
	return {
		create_weapon = {
			spec = "hexm.client.entities.local.player_avatar:PlayerAvatar:_create_weapon",
			post_exec = function(self, args, results, traceback)
				local action = self
				pcall(function()
					local scene = cc.Director:getInstance():getRunningScene()
					if scene then
						scene:runAction(cc.Sequence:create({
							cc.DelayTime:create(0.2),
							cc.CallFunc:create(function()
								for _, skin_no in ipairs(action.state.item_nos) do
									action:apply(skin_no)
								end
							end),
						}))
					end
				end)
			end,
		},
	}
end

-- ============================================================
-- WEAPON SKIN DATA (generated from G.datam)
-- ============================================================

function WeaponSkins:generate_weapon_data()
	if not G or not G.datam then
		self:log("ERROR: G.datam not available")
		return nil, nil
	end

	if not G.datam.guise_items then
		self:log("ERROR: G.datam.guise_items not available")
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
						local ok, kf_name = pcall(function()
							return G.locale_manager:get_locale_text_by_tid(name_tid)
						end)
						kf_name = (ok and kf_name and kf_name ~= "" and kf_name ~= tostring(name_tid)) and kf_name
							or ("Kongfu " .. kf_id)
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
		self:log("ERROR: guise_items:items() returned nil")
		return nil, nil
	end

	for _, entry in pairs(items) do
		local item_no = tonumber(entry[1])
		local d = entry[2]
		if item_no and d then
			if d:get("weapon_view", 0) == 1 then
				local name_tid = d:get("name", nil)
				local ok, name = pcall(function()
					return G.locale_manager:get_locale_text_by_tid(name_tid)
				end)
				name = (ok and name and name ~= "" and name ~= tostring(name_tid)) and name
					or ("Weapon Skin " .. item_no)
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

	-- Store in state
	self.state.weapon_data = weapon_data
	self.state.weapon_skin_list = weapon_skin_list

	self:log("Generated " .. count .. " weapon skins")
	return weapon_data, weapon_skin_list
end

--- Load weapon data (generate once, then from state cache)
function WeaponSkins:load_weapon_data()
	local weapon_data = self.state.weapon_data
	local weapon_skin_list = self.state.weapon_skin_list
	if weapon_data and weapon_skin_list then
		return weapon_data, weapon_skin_list
	end
	return self:generate_weapon_data()
end

function WeaponSkins:get_weapon_list()
	local _, skin_list = self:load_weapon_data()
	return skin_list or {}
end

function WeaponSkins:get_bow_list()
	local all = self:get_weapon_list()
	local bows = {}
	for _, weapon in ipairs(all) do
		if (weapon.subtype_name or "") == "Bow" then
			bows[#bows + 1] = weapon
		end
	end
	return bows
end

function WeaponSkins:get_weapons_for_kongfu(kongfu_id)
	if not kongfu_id then return {} end
	local all = self:get_weapon_list()
	local filtered = {}
	for _, weapon in ipairs(all) do
		local data = self:get_weapon_data(weapon.item_no)
		if data and data.compatible_kongfu then
			for _, kf in ipairs(data.compatible_kongfu) do
				if kf.kongfu_id == kongfu_id then
					filtered[#filtered + 1] = weapon
					break
				end
			end
		end
	end
	return filtered
end

function WeaponSkins:get_primary_weapon_list()
	local mp = G and G.main_player
	if not mp then return {} end
	local kongfu_id
	pcall(function()
		if mp.enchant_get_kongfu_id then
			kongfu_id = mp:enchant_get_kongfu_id()
		end
	end)
	return self:get_weapons_for_kongfu(kongfu_id)
end

function WeaponSkins:get_secondary_weapon_list()
	local mp = G and G.main_player
	if not mp then return {} end
	local kongfu_id
	pcall(function()
		if mp.get_sub_kongfu then
			kongfu_id = mp:get_sub_kongfu()
		end
	end)
	return self:get_weapons_for_kongfu(kongfu_id)
end

function WeaponSkins:get_display_name(weapon)
	local stars = string.rep("\226\152\133", weapon.star or 1)
	return (weapon.name or "Unknown") .. " [" .. (weapon.item_no or "?") .. "] " .. stars
end

function WeaponSkins:get_weapon_data(item_no)
	local data, _ = self:load_weapon_data()
	return data and data[tonumber(item_no)]
end

-- ============================================================
-- APPLY WEAPON SKIN
-- ============================================================
function WeaponSkins:disable()
	self:unhook("create_weapon")
	self.state.item_nos = {}
end

function WeaponSkins:apply(item_no_or_item)
	-- Accept either raw item_no or item object from SelectorFactory
	local item_no = item_no_or_item
	if type(item_no_or_item) == "table" then
		item_no = item_no_or_item.item_no
	end

	self:hook("create_weapon")

	-- Check if this item_no is already in the list
	local already_added = false
	for _, existing_item_no in ipairs(self.state.item_nos) do
		if existing_item_no == item_no then
			already_added = true
			break
		end
	end

	if not already_added then
		table.insert(self.state.item_nos, item_no)
		self:log("Added weapon skin to persistent list: " .. item_no)
	else
		self:log("Weapon skin already in persistent list: " .. item_no)
	end

	local mp = G.main_player
	if not mp then
		return false, "No main player"
	end

	item_no = tonumber(item_no)
	if not item_no then
		return false, "Invalid item_no"
	end

	self:log("Applying weapon skin: " .. item_no)

	-- Verify weapon skin exists
	local weapon_data = self:get_weapon_data(item_no)
	if not weapon_data then
		self:log("WARNING: Weapon skin " .. item_no .. " not found in data")
	end

	-- Apply weapon skin using the game's method
	if mp.equip_weapon_dressing then
		local ok, err = pcall(function()
			return mp:equip_weapon_dressing(item_no)
		end)

		if ok then
			self:log("SUCCESS: Applied weapon skin " .. item_no)
			return true
		else
			self:log("ERROR: Failed to apply weapon skin: " .. tostring(err))
			return false, tostring(err)
		end
	end

	return false, "equip_weapon_dressing method not found"
end

function WeaponSkins:apply_dual(left_weapon, right_weapon)
	if left_weapon then self:apply(left_weapon) end
	if right_weapon then self:apply(right_weapon) end
	return true
end

return WeaponSkins:new()
