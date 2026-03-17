-- ============================================================
-- SUIT_SKINS.LUA - Suit/Guise Changer with Persistent Mode
-- ============================================================
-- Prerequisites: Bootstrap must be loaded first

local SuitSkins = {}

-- Reference libs via Reg (loaded once by bootstrap)
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Utils = Reg.get("Utils")
local Hooks = Reg.get("Hooks")

local function _log(msg)
	Logger.log("[SuitSkins] " .. msg)
end

-- Hook ID
local HOOK_SET_INIT_DRESSING = "skins_set_init_dressing_info"

-- Module path
local MODULE_PLAYER_AVATAR = "hexm.client.entities.local.player_avatar"

-- ============================================================
-- STATE (registered via Reg for reload safety)
-- ============================================================
local SKIN_STATE_NAME = "SKIN_STATE"
if not Reg.has(SKIN_STATE_NAME) then
	Reg.set(SKIN_STATE_NAME, {
		is_enabled = false,
		suit_no = nil,
		wear_info = nil,
	})
end
local _state = Reg.get(SKIN_STATE_NAME)

-- Reg keys for generated data (survives reload)
local SUIT_DATA_KEY = "SUIT_DATA"
local SUIT_LIST_KEY = "SUIT_LIST"

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

--- Generate SUIT_DATA and SUIT_LIST from G.datam.guise_suit_config
function SuitSkins.generate_suit_data()
	if not G or not G.datam or not G.datam.guise_suit_config then
		_log("ERROR: G.datam.guise_suit_config not available")
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
		_log("ERROR: guise_suit_config:items() returned nil")
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
				local name = _translate(d:get("collocation_name", nil))
					or _name_from_icon(d:get("suit_icon", ""))
					or ("Suit #" .. suit_no)

				local view_nos = _datam_dict_to_list(d:get("content_0", nil))
				local positions = _datam_dict_to_list(d:get("recommend_position_0", nil))

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

	-- Store in Reg for reload safety
	Reg.set(SUIT_DATA_KEY, suit_data)
	Reg.set(SUIT_LIST_KEY, suit_list)

	_log("Generated " .. visible_count .. " suits (hidden: " .. invisible_count .. ")")
	return suit_data, suit_list
end

--- Load suit data (generate once, then always from Reg cache)
function SuitSkins.load_suit_data()
	local suit_data = Reg.get(SUIT_DATA_KEY)
	local suit_list = Reg.get(SUIT_LIST_KEY)
	if suit_data and suit_list then
		return suit_data, suit_list
	end
	return SuitSkins.generate_suit_data()
end

function SuitSkins.get_suit_list()
	local _, suit_list = SuitSkins.load_suit_data()
	return suit_list or {}
end

function SuitSkins.get_suit_data(suit_no)
	local data, _ = SuitSkins.load_suit_data()
	return data and data[tonumber(suit_no)]
end

-- ============================================================
-- APPLY SUIT
-- ============================================================

function SuitSkins.apply(suit_no)
	local mp = Utils.get_main_player()
	if not mp then
		return false, "No main player"
	end

	suit_no = tonumber(suit_no)
	if not suit_no then
		return false, "Invalid suit_no"
	end

	_log("Applying suit_no: " .. suit_no)

	local guise_misc = Utils.safe_import("hexm.common.misc.guise_misc")
	if not guise_misc then
		return false, "guise_misc not found"
	end

	-- Get body type
	local body_type = 0
	if mp.get_guise_body_type then
		body_type = Utils.safe_call("body_type", mp.get_guise_body_type, mp) or 0
	end

	-- Parse and apply guise data
	local guise_data = Utils.safe_call("parse_guise", guise_misc.parse_guise_data_by_suit_no, suit_no, body_type, mp)

	if guise_data and mp.apply_guise_data then
		local _, err = Utils.safe_call("apply_guise", mp.apply_guise_data, mp, guise_data, false)
		if not err then
			_log("SUCCESS: Applied suit " .. tostring(guise_data))
			return true
		end
	end

	-- Fallback: wear info
	local wear_info = Utils.safe_call("wear_info", guise_misc.get_wear_info_by_suit_no, suit_no, body_type)
	if wear_info and mp.change_guise_by_point_and_no then
		for point, item in pairs(wear_info) do
			Utils.safe_call("change_point", mp.change_guise_by_point_and_no, mp, point, item.view_no or item, nil)
		end
		_log("SUCCESS: Applied suit via wear_info")
		return true
	end

	return false, "Failed to apply"
end

-- ============================================================
-- PERSISTENT MODE (HOOK)
-- ============================================================

-- Get wear_info for a suit
local function _get_wear_info_for_suit(suit_no)
	local guise_misc = Utils.safe_import("hexm.common.misc.guise_misc")
	if not guise_misc then
		return nil
	end

	local mp = Utils.get_main_player()
	local body_type = 0
	if mp and mp.get_guise_body_type then
		body_type = Utils.safe_call("body_type", mp.get_guise_body_type, mp) or 0
	end

	return Utils.safe_call("wear_info", guise_misc.get_wear_info_by_suit_no, suit_no, body_type)
end

-- Install hook using Hooks module
local function _hook()
	if Hooks.is_hooked(HOOK_SET_INIT_DRESSING) then
		_log("Already hooked")
		return true
	end

	local ok, err =
		Hooks.hook_method(HOOK_SET_INIT_DRESSING, MODULE_PLAYER_AVATAR, "PlayerAvatar", "set_init_dressing_info", {
			override_exec = function(orig, self, wear_info)
				if _state.is_enabled and _state.wear_info then
					_log("Intercepting wear_info, applying persistent suit " .. _state.suit_no)
					-- Schedule the skin apply slightly after init completes
					pcall(function()
						local suit_no = _state.suit_no -- Capture value now
						local scene = cc.Director:getInstance():getRunningScene()

						if scene then
							-- Create a one-time delayed action using Cocos2d-x Actions
							local delayed_action = cc.Sequence:create({
								cc.DelayTime:create(1.0), -- 5 second delay
								cc.CallFunc:create(function()
									_log("Re-applying persistent suit " .. suit_no)
									SuitSkins.apply(suit_no)
								end),
							})

							scene:runAction(delayed_action)
							_log("Scheduled suit re-application in 5 seconds")
						else
							_log("ERROR: No running scene for delayed suit application")
						end
					end)
				end
				return orig(self, wear_info)
			end,
		})

	if ok then
		_log("HOOKED: PlayerAvatar.set_init_dressing_info")
		return true
	else
		_log("ERROR: " .. tostring(err))
		return false, err
	end
end

-- Unhook using Hooks module
local function _unhook()
	if Hooks.is_hooked(HOOK_SET_INIT_DRESSING) then
		Hooks.unhook(HOOK_SET_INIT_DRESSING)
		_log("Unhooked: PlayerAvatar.set_init_dressing_info")
	end
end

-- ============================================================
-- PUBLIC API
-- ============================================================

-- Enable persistent mode for a suit
function SuitSkins.enable(suit_no)
	if _state.is_enabled then
		_log("Already enabled")
		return true
	end

	suit_no = tonumber(suit_no)
	if not suit_no then
		return false, "Invalid suit_no"
	end

	-- Get wear_info for this suit
	local wear_info = _get_wear_info_for_suit(suit_no)
	if not wear_info then
		return false, "Could not get wear_info for suit " .. suit_no
	end

	_state.suit_no = suit_no
	_state.wear_info = wear_info
	_state.is_enabled = true

	-- Install hook
	local ok, err = _hook()
	if not ok then
		_log("ERROR: Could not install hook: " .. tostring(err))
		_state.is_enabled = false
		return false, err
	end

	-- Apply immediately
	SuitSkins.apply(suit_no)

	_log("=== PERSISTENT SKIN ENABLED === suit_no: " .. suit_no)
	return true
end

-- Disable persistent mode
function SuitSkins.disable()
	_state.is_enabled = false
	_state.suit_no = nil
	_state.wear_info = nil
	_unhook()

	_log("=== PERSISTENT SKIN DISABLED ===")
	return true
end

-- Check if enabled
function SuitSkins.is_enabled()
	return _state.is_enabled
end

-- Get current persistent suit
function SuitSkins.get_current_suit()
	return _state.suit_no
end

-- Legacy aliases
SuitSkins.change_suit = SuitSkins.apply
SuitSkins.ChangeSuitBySuitNo = SuitSkins.apply
SuitSkins.GetSuitList = SuitSkins.get_suit_list
SuitSkins.GetSuitData = SuitSkins.get_suit_data
SuitSkins.unhook = _unhook

return SuitSkins
