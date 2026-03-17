-- ============================================================
-- SUIT_SKINS.LUA - Suit/Guise Changer with Persistent Mode
-- ============================================================
-- Prerequisites: Bootstrap must be loaded first

local ActionBase = _G.Reg.lib("ActionBase")

local SuitSkins = ActionBase:extend("actions.suit_skins")

-- ============================================================
-- STATE DEFINITION
-- ============================================================

function SuitSkins:define_state()
	return {
		persistent = {
			is_enabled = false,
			suit_no = nil,
		},
		transient = {
			wear_info = nil,
			suit_data = nil,
			suit_list = nil,
		},
	}
end

-- ============================================================
-- HOOKS DEFINITION
-- ============================================================

function SuitSkins:define_hooks()
	return {
		set_init_dressing_info = {
			spec = "hexm.client.entities.local.player_avatar:PlayerAvatar:set_init_dressing_info",
			override_orig_function = true,
			post_exec = function(self, original, self_avatar, wear_info)
				if self.state.is_enabled and self.state.wear_info then
					self:log("Intercepting wear_info, applying persistent suit " .. self.state.suit_no)
					-- Schedule the skin apply slightly after init completes
					pcall(function()
						local suit_no = self.state.suit_no -- Capture value now
						local scene = cc.Director:getInstance():getRunningScene()

						if scene then
							-- Create a one-time delayed action using Cocos2d-x Actions
							local delayed_action = cc.Sequence:create({
								cc.DelayTime:create(1.0),
								cc.CallFunc:create(function()
									self:log("Re-applying persistent suit " .. suit_no)
									self:apply(suit_no)
								end),
							})

							scene:runAction(delayed_action)
							self:log("Scheduled suit re-application in 5 seconds")
						else
							self:log("ERROR: No running scene for delayed suit application")
						end
					end)
				end
				return original(self_avatar, wear_info)
			end,
		},
	}
end

-- Module path constant
local MODULE_PLAYER_AVATAR = "hexm.client.entities.local.player_avatar"

-- ============================================================
-- SUIT DATA (generated from G.datam.guise_suit_config)
-- ============================================================

--- Extract readable name from icon path (fallback when translation fails)
local function _name_from_icon(suit_icon)
	if not suit_icon or suit_icon == "" then
		return nil
	end
	local name = suit_icon:match("suit_([A-Za-z0-9_]+)") or suit_icon:match("pic_([A-Za-z0-9_]+)")
	if name then
		-- "tianquan" -> "Tianquan", "san_geng" -> "San Geng"
		return name:gsub("_", " "):gsub("(%a)([%w]*)", function(a, b) return a:upper() .. b end)
	end
	return nil
end

--- Translate a collocation_name TID to display text
local function _translate(tid)
	if not tid then return nil end
	local ok, text = pcall(function()
		return G.locale_manager:get_locale_text_by_tid(tid)
	end)
	if ok and text and text ~= "" and text ~= tostring(tid) then
		return text
	end
	return nil
end

--- Convert a datam dict-like object (content_0, recommend_position_0) to a plain list
local function _datam_dict_to_list(obj)
	if not obj then return {} end
	local result = {}
	-- obj behaves like a dict with integer keys
	local ok, items = pcall(function()
		local t = {}
		for k, v in pairs(obj) do
			t[#t + 1] = { k = tonumber(k) or 0, v = v }
		end
		table.sort(t, function(a, b) return a.k < b.k end)
		local out = {}
		for _, item in ipairs(t) do
			out[#out + 1] = item.v
		end
		return out
	end)
	return ok and items or {}
end

-- ============================================================
-- SUIT DATA HELPERS
-- ============================================================

--- Extract readable name from icon path (fallback when translation fails)
function SuitSkins:_name_from_icon(suit_icon)
	if not suit_icon or suit_icon == "" then
		return nil
	end
	local name = suit_icon:match("suit_([A-Za-z0-9_]+)") or suit_icon:match("pic_([A-Za-z0-9_]+)")
	if name then
		-- "tianquan" -> "Tianquan", "san_geng" -> "San Geng"
		return name:gsub("_", " "):gsub("(%a)([%w]*)", function(a, b) return a:upper() .. b end)
	end
	return nil
end

--- Translate a collocation_name TID to display text
function SuitSkins:_translate(tid)
	if not tid then return nil end
	local ok, text = pcall(function()
		return G.locale_manager:get_locale_text_by_tid(tid)
	end)
	if ok and text and text ~= "" and text ~= tostring(tid) then
		return text
	end
	return nil
end

--- Convert a datam dict-like object (content_0, recommend_position_0) to a plain list
function SuitSkins:_datam_dict_to_list(obj)
	if not obj then return {} end
	local result = {}
	-- obj behaves like a dict with integer keys
	local ok, items = pcall(function()
		local t = {}
		for k, v in pairs(obj) do
			t[#t + 1] = { k = tonumber(k) or 0, v = v }
		end
		table.sort(t, function(a, b) return a.k < b.k end)
		local out = {}
		for _, item in ipairs(t) do
			out[#out + 1] = item.v
		end
		return out
	end)
	return ok and items or {}
end

--- Generate suit data from G.datam.guise_suit_config
function SuitSkins:_generate_suit_data()
	if not G or not G.datam or not G.datam.guise_suit_config then
		self:log("ERROR: G.datam.guise_suit_config not available")
		return nil, nil
	end

	local config = G.datam.guise_suit_config
	local suit_data = {}
	local suit_list = {}
	local visible_count = 0
	local invisible_count = 0

	-- Iterate all suits via :items() (python-like dict iteration)
	local items = config:items()
	if not items then
		self:log("ERROR: guise_suit_config:items() returned nil")
		return nil, nil
	end

	for _, entry in pairs(items) do
		-- entry is [suit_no, dict] pair; dict supports :get(key, default)
		local suit_no = tonumber(entry[1])
		local d = entry[2]
		if suit_no and d then
			-- Skip invisible suits
			if d:get("invisible", 0) == 1 then
				invisible_count = invisible_count + 1
			else
				-- Resolve name: translation > icon fallback > generic
				local name = self:_translate(d:get("collocation_name", nil))
					or self:_name_from_icon(d:get("suit_icon", ""))
					or ("Suit #" .. suit_no)

				local view_nos = self:_datam_dict_to_list(d:get("content_0", nil))
				local positions = self:_datam_dict_to_list(d:get("recommend_position_0", nil))

				suit_data[suit_no] = {
					name = name,
					stuff_id = d:get("stuff_id", 0),
					icon = d:get("suit_icon", ""),
					fh_value = d:get("fh_value", 0),
					costume_tag = d:get("costume_tag", 0),
					view_nos = view_nos,
					positions = positions,
				}

				suit_list[#suit_list + 1] = {
					suit_no = suit_no,
					name = name,
					stuff_id = d:get("stuff_id", 0),
					costume_tag = d:get("costume_tag", 0),
				}

				visible_count = visible_count + 1
			end
		end
	end

	-- Sort list by costume_tag desc, then name asc
	table.sort(suit_list, function(a, b)
		if a.costume_tag ~= b.costume_tag then
			return a.costume_tag > b.costume_tag
		end
		return a.name < b.name
	end)

	-- Store in transient state for reload safety
	self.state.suit_data = suit_data
	self.state.suit_list = suit_list

	self:log("Generated " .. visible_count .. " suits (hidden: " .. invisible_count .. ")")
	return suit_data, suit_list
end

--- Load suit data (generate once, then always from state cache)
function SuitSkins:_load_suit_data()
	local suit_data = self.state.suit_data
	local suit_list = self.state.suit_list
	if suit_data and suit_list then
		return suit_data, suit_list
	end
	return self:_generate_suit_data()
end

function SuitSkins:get_suit_list()
	local _, suit_list = self:_load_suit_data()
	return suit_list or {}
end

function SuitSkins:get_suit_data(suit_no)
	local data, _ = self:_load_suit_data()
	return data and data[tonumber(suit_no)]
end

-- ============================================================
-- APPLY SUIT
-- ============================================================

-- ============================================================
-- APPLY SUIT
-- ============================================================

function SuitSkins:apply(suit_no_or_item)
	-- Accept either raw suit_no or item object from SelectorFactory
	local suit_no = suit_no_or_item
	if type(suit_no_or_item) == "table" then
		suit_no = suit_no_or_item.suit_no or suit_no_or_item.id
	end

	local mp = G.main_player
	if not mp then
		return false, "No main player"
	end

	suit_no = tonumber(suit_no)
	if not suit_no then
		return false, "Invalid suit_no"
	end

	self:log("Applying suit_no: " .. suit_no)

	local guise_misc = portable.safe_import("hexm.common.misc.guise_misc")
	if not guise_misc then
		return false, "guise_misc not found"
	end

	-- Get body type
	local body_type = 0
	if mp.get_guise_body_type then
		local ok, bt = pcall(mp.get_guise_body_type, mp)
		if ok then body_type = bt or 0 end
	end

	-- Parse and apply guise data
	local ok_parse, guise_data = pcall(guise_misc.parse_guise_data_by_suit_no, suit_no, body_type, mp)

	if ok_parse and guise_data and mp.apply_guise_data then
		local ok_apply = pcall(mp.apply_guise_data, mp, guise_data, false)
		if ok_apply then
			self:log("SUCCESS: Applied suit " .. tostring(guise_data))
			return true
		end
	end

	-- Fallback: wear info
	local ok_wear, wear_info = pcall(guise_misc.get_wear_info_by_suit_no, suit_no, body_type)
	if ok_wear and wear_info and mp.change_guise_by_point_and_no then
		for point, item in pairs(wear_info) do
			pcall(mp.change_guise_by_point_and_no, mp, point, item.view_no or item, nil)
		end
		self:log("SUCCESS: Applied suit via wear_info")
		return true
	end

	return false, "Failed to apply"
end

-- ============================================================
-- GET WEAR INFO (for persistent mode)
-- ============================================================

function SuitSkins:_get_wear_info_for_suit(suit_no)
	local guise_misc = portable.safe_import("hexm.common.misc.guise_misc")
	if not guise_misc then
		return nil
	end

	local mp = G.main_player
	local body_type = 0
	if mp and mp.get_guise_body_type then
		local ok, bt = pcall(mp.get_guise_body_type, mp)
		if ok then body_type = bt or 0 end
	end

	local ok, wear_info = pcall(guise_misc.get_wear_info_by_suit_no, suit_no, body_type)
	return ok and wear_info or nil
end

-- ============================================================
-- PERSISTENT MODE
-- ============================================================

function SuitSkins:enable(suit_no_or_item)
	if self.state.is_enabled then
		return self:apply(suit_no_or_item)
	end

	-- Accept either raw suit_no or item object from SelectorFactory
	local suit_no = suit_no_or_item
	if type(suit_no_or_item) == "table" then
		suit_no = suit_no_or_item.suit_no or suit_no_or_item.id
	end

	suit_no = tonumber(suit_no)
	if not suit_no then
		return false, "Invalid suit_no"
	end

	-- Get wear_info for this suit
	local wear_info = self:_get_wear_info_for_suit(suit_no)
	if not wear_info then
		self:log("Could not get wear_info for suit " .. suit_no)
		return false, "Could not get wear_info for suit " .. suit_no
	end

	self.state.suit_no = suit_no
	self.state.wear_info = wear_info
	self.state.is_enabled = true

	-- Install hook
	self:hook("set_init_dressing_info")

	-- Apply immediately
	self:apply(suit_no)

	self:log("=== PERSISTENT SKIN ENABLED === suit_no: " .. suit_no)
	return true
end

-- Disable persistent mode
function SuitSkins:disable()
	self.state.is_enabled = false
	self.state.suit_no = nil
	self.state.wear_info = nil
	self:unhook("set_init_dressing_info")

	self:log("=== PERSISTENT SKIN DISABLED ===")
	return true
end

-- Check if enabled
function SuitSkins:is_enabled()
	return self.state.is_enabled
end

-- Get current persistent suit
function SuitSkins:get_current_suit()
	return self.state.suit_no
end

-- Legacy aliases
SuitSkins.change_suit = SuitSkins.apply
SuitSkins.ChangeSuitBySuitNo = SuitSkins.apply
SuitSkins.GetSuitList = SuitSkins.get_suit_list
SuitSkins.GetSuitData = SuitSkins.get_suit_data

return SuitSkins:new()
