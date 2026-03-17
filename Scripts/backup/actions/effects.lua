-- ============================================================
-- EFFECTS.LUA - Wuxue Skill Effect Changer with Persistent Mode
-- ============================================================
-- Prerequisites: Bootstrap must be loaded first

local Effects = {}

-- Reference libs via Reg (loaded once by bootstrap)
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Utils = Reg.get("Utils")
local Hooks = Reg.get("Hooks")

local function _log(msg)
	Logger.log("[Effects] " .. msg)
end

-- Hook IDs
local HOOK_GET_KONGFU_FX = "effects_get_kongfu_fx_item"
local HOOK_REFRESH_FASHION_KONGFU = "effects_refresh_fashion_kongfu"
local HOOK_DISCOVERY = "effects_discovery_get_kongfu_fx"

-- Module paths
local MODULE_PLAYER_AVATAR = "hexm.client.entities.local.player_avatar"
local MODULE_ENCHANT_BASE = "hexm.client.combat.enchant_base"

-- ============================================================
-- STATE (registered via Reg for reload safety)
-- ============================================================
local STATE_NAME = "EFFECTS_STATE"
if not Reg.has(STATE_NAME) then
	Reg.set(STATE_NAME, {
		is_enabled = false,
		-- Dual mode: { [kungfu_id] = effect_id }
		kungfu_to_effect = {},
		discovery_mode = false,
		logged_count = 0,
	})
end
local _state = Reg.get(STATE_NAME)

-- Reg keys for generated data (survives reload)
local EFFECT_DATA_KEY = "EFFECT_DATA"
local EFFECT_LIST_KEY = "EFFECT_LIST"

-- ============================================================
-- EFFECT DATA (generated from G.datam)
-- ============================================================

--- Translate a name TID to display text
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

--- Generate EFFECT_DATA and EFFECT_LIST from G.datam
function Effects.generate_effect_data()
	if not G or not G.datam then
		_log("ERROR: G.datam not available")
		return nil, nil
	end

	if not G.datam.wuxue_effect_data then
		_log("ERROR: G.datam.wuxue_effect_data not available")
		return nil, nil
	end

	-- Build kongfu name lookup
	local kongfu_names = {}
	if G.datam.kongfu then
		local kf_items = G.datam.kongfu:items()
		if kf_items then
			for _, kf_entry in pairs(kf_items) do
				local kf_id = tonumber(kf_entry[1])
				local kf = kf_entry[2]
				if kf_id and kf then
					local name = _translate(kf:get("name", nil))
					if name then
						kongfu_names[kf_id] = name
					end
				end
			end
		end
	end

	-- Build default effect -> kongfu mapping from wuxue_effect_default
	local effect_to_extra_kongfu = {} -- effect_id -> { kongfu_id, ... }
	if G.datam.wuxue_effect_default then
		local def_items = G.datam.wuxue_effect_default:items()
		if def_items then
			for _, def_entry in pairs(def_items) do
				local kf_id = tonumber(def_entry[1])
				local def = def_entry[2]
				if kf_id and def then
					-- Check default_id
					local default_id = def:get("default_id", nil)
					if default_id then
						if not effect_to_extra_kongfu[default_id] then
							effect_to_extra_kongfu[default_id] = {}
						end
						local tbl = effect_to_extra_kongfu[default_id]
						tbl[#tbl + 1] = kf_id
					end
				end
			end
		end
	end

	-- Iterate wuxue_effect_data
	local effect_data = {}
	local effect_list_arr = {}
	local count = 0

	local items = G.datam.wuxue_effect_data:items()
	if not items then
		_log("ERROR: wuxue_effect_data:items() returned nil")
		return nil, nil
	end

	for _, entry in pairs(items) do
		local effect_id = tonumber(entry[1])
		local d = entry[2]
		if effect_id and d then
			local name_tid = d:get("name", nil)
			local base_name = _translate(name_tid) or ("Effect #" .. effect_id)

			-- Collect kongfu_ids
			local kongfu_id_set = {}
			local kongfu_id_arr = {}
			local direct_kf = d:get("kongfu_id", nil)
			if direct_kf and direct_kf > 0 then
				kongfu_id_set[direct_kf] = true
				kongfu_id_arr[#kongfu_id_arr + 1] = direct_kf
			end
			-- Add from default mappings
			if effect_to_extra_kongfu[effect_id] then
				for _, kid in ipairs(effect_to_extra_kongfu[effect_id]) do
					if not kongfu_id_set[kid] then
						kongfu_id_set[kid] = true
						kongfu_id_arr[#kongfu_id_arr + 1] = kid
					end
				end
			end
			table.sort(kongfu_id_arr)

			-- Build kongfu_names map
			local kf_names_map = {}
			for _, kid in ipairs(kongfu_id_arr) do
				if kongfu_names[kid] then
					kf_names_map[kid] = kongfu_names[kid]
				end
			end

			-- Display name with kongfu prefix
			local display_name = base_name
			if kongfu_id_arr[1] and kf_names_map[kongfu_id_arr[1]] then
				display_name = "[" .. kf_names_map[kongfu_id_arr[1]] .. "] " .. base_name
			end

			local icon_no = d:get("icon_no", "")
			local item_group = d:get("item_group", 0)
			local fenghua_value = d:get("fenghua_value", 0)
			local fh_value = d:get("fh_value", 0)

			-- Icon list
			local icon_arr = {}
			local icon_transverse = d:get("icon_no_transverse_list", nil)
			if icon_transverse then
				pcall(function()
					for _, iv in pairs(icon_transverse) do
						if iv and iv ~= "" then
							icon_arr[#icon_arr + 1] = iv
						end
					end
				end)
			end

			effect_data[effect_id] = {
				effect_id = effect_id,
				name = display_name,
				base_name = base_name,
				icon = icon_no,
				icon_list = icon_arr,
				kongfu_ids = kongfu_id_arr,
				kongfu_names = kf_names_map,
				item_group = item_group,
				fenghua_value = fenghua_value,
				fh_value = fh_value,
			}

			effect_list_arr[#effect_list_arr + 1] = {
				effect_id = effect_id,
				name = display_name,
				kongfu_ids = kongfu_id_arr,
				icon = icon_no,
				fh_value = fh_value,
			}

			count = count + 1
		end
	end

	-- Sort by first kongfu_id, then effect_id
	table.sort(effect_list_arr, function(a, b)
		local a_kf = a.kongfu_ids[1] or 999999
		local b_kf = b.kongfu_ids[1] or 999999
		if a_kf ~= b_kf then return a_kf < b_kf end
		return a.effect_id < b.effect_id
	end)

	-- Store in Reg
	Reg.set(EFFECT_DATA_KEY, effect_data)
	Reg.set(EFFECT_LIST_KEY, effect_list_arr)

	_log("Generated " .. count .. " effects")
	return effect_data, effect_list_arr
end

--- Load effect data (generate once, then from Reg cache)
function Effects.load_effect_data()
	local effect_data = Reg.get(EFFECT_DATA_KEY)
	local effect_list_arr = Reg.get(EFFECT_LIST_KEY)
	if effect_data and effect_list_arr then
		return effect_data, effect_list_arr
	end
	return Effects.generate_effect_data()
end

function Effects.get_effect_list(kongfu_id)
	local _, all_effects = Effects.load_effect_data()
	if not all_effects then
		return {}
	end

	-- Filter effects
	local filtered = {}
	for _, effect in ipairs(all_effects) do
		local include = true

		-- Filter out fh_value = 0 (default/base effects)
		if effect.fh_value == 0 then
			include = false
		end

		-- If kongfu_id provided, filter by kongfu compatibility
		if include and kongfu_id then
			if effect.kongfu_ids and #effect.kongfu_ids > 0 then
				local matches = false
				for _, kid in ipairs(effect.kongfu_ids) do
					if kid == kongfu_id then
						matches = true
						break
					end
				end
				include = matches
			end
		end

		if include then
			filtered[#filtered + 1] = effect
		end
	end

	_log(
		"Filtered effects: "
			.. #filtered
			.. " / "
			.. #all_effects
			.. (kongfu_id and (" for kongfu_id: " .. kongfu_id) or "")
	)

	return filtered
end

function Effects.get_effect_data(effect_id)
	local data, _ = Effects.load_effect_data()
	return data and data[tonumber(effect_id)]
end

-- ============================================================
-- APPLY EFFECT (ONE-TIME)
-- ============================================================

function Effects.apply(effect_id)
	local mp = Utils.get_main_player()
	if not mp then
		return false, "No main player"
	end

	effect_id = tonumber(effect_id)
	if not effect_id then
		return false, "Invalid effect_id"
	end

	_log("Applying effect_id: " .. effect_id)

	if mp and mp.refresh_fashion_kongfu then
		-- Ensure fashion kongfu is refreshed to pick up changes
		local ok, err = pcall(function()
			mp:refresh_fashion_kongfu()
		end)
		if not ok then
			_log("ERROR refreshing fashion kongfu: " .. tostring(err))
			return false, "Error refreshing fashion kongfu"
		end
	end

	_log("SUCCESS: Applied effect_id " .. effect_id .. " (via temp hook)")
	return true
end

-- ============================================================
-- PERSISTENT MODE (HOOK)
-- ============================================================

-- Install persistent hook
local function _hook()
	if Hooks.is_hooked(HOOK_GET_KONGFU_FX) then
		_log("Already hooked")
		return true
	end

	local ok, err = Hooks.hook_method(HOOK_GET_KONGFU_FX, MODULE_PLAYER_AVATAR, "PlayerAvatar", "get_kongfu_fx_item", {
		override_exec = function(orig, self, kongfu_id)
			if not _state.is_enabled then
				return orig(self, kongfu_id)
			end

			-- Check if we have a mapping for this kungfu
			if kongfu_id and _state.kungfu_to_effect[kongfu_id] then
				local effect_id = _state.kungfu_to_effect[kongfu_id]
				_log("Applying mapped effect: kungfu " .. kongfu_id .. " -> effect " .. effect_id)
				return effect_id
			end

			-- No mapping for this kungfu, pass through original
			return orig(self, kongfu_id)
		end,
	})

	if ok then
		_log("HOOKED: PlayerAvatar.get_kongfu_fx_item")
		return true
	else
		_log("ERROR: " .. tostring(err))
		return false, err
	end
end

-- Unhook
local function _unhook()
	if Hooks.is_hooked(HOOK_GET_KONGFU_FX) then
		Hooks.unhook(HOOK_GET_KONGFU_FX)
		_log("Unhooked: PlayerAvatar.get_kongfu_fx_item")
	end

	if Hooks.is_hooked(HOOK_REFRESH_FASHION_KONGFU) then
		Hooks.unhook(HOOK_REFRESH_FASHION_KONGFU)
		_log("Unhooked: EnchantBase.refresh_fashion_kongfu")
	end
end

-- ============================================================
-- PUBLIC API
-- ============================================================

-- Enable effect for a single kungfu
function Effects.enable_single(effect_id, kungfu_id)
	effect_id = tonumber(effect_id)
	kungfu_id = tonumber(kungfu_id)

	if not effect_id then
		return false, "Invalid effect ID"
	end

	if not kungfu_id then
		return false, "Invalid kungfu ID"
	end

	_log("=== ENABLING EFFECT FOR KUNGFU " .. kungfu_id .. " ===")
	_log("Kungfu " .. kungfu_id .. " -> effect " .. effect_id)

	-- Set kungfu → effect mapping (preserve existing mappings)
	_state.kungfu_to_effect[kungfu_id] = effect_id
	_state.is_enabled = true

	-- Install hooks if not already
	if not Hooks.is_hooked(HOOK_GET_KONGFU_FX) then
		local ok, err = _hook()
		if not ok then
			_log("ERROR: Could not install hook: " .. tostring(err))
			_state.is_enabled = false
			return false, err
		end
	end

	-- Trigger refresh
	local mp = Utils.get_main_player()
	if mp and mp.refresh_fashion_kongfu then
		pcall(function()
			mp:refresh_fashion_kongfu()
		end)
	end

	_log("=== EFFECT ENABLED ===")
	return true
end

-- Enable dual weapon mode with main and secondary effects
function Effects.enable_dual(main_effect_id, secondary_effect_id, main_kungfu_id, secondary_kungfu_id)
	main_effect_id = tonumber(main_effect_id)
	secondary_effect_id = tonumber(secondary_effect_id)
	main_kungfu_id = tonumber(main_kungfu_id)
	secondary_kungfu_id = tonumber(secondary_kungfu_id)

	if not main_effect_id or not secondary_effect_id then
		return false, "Invalid effect IDs"
	end

	if not main_kungfu_id or not secondary_kungfu_id then
		return false, "Invalid kungfu IDs"
	end

	_log("=== ENABLING DUAL WEAPON MODE ===")
	_log("Main kungfu " .. main_kungfu_id .. " -> effect " .. main_effect_id)
	_log("Secondary kungfu " .. secondary_kungfu_id .. " -> effect " .. secondary_effect_id)

	-- Set kungfu → effect mappings
	_state.kungfu_to_effect = {
		[main_kungfu_id] = main_effect_id,
		[secondary_kungfu_id] = secondary_effect_id,
	}
	_state.is_enabled = true

	-- Install hooks if not already
	if not Hooks.is_hooked(HOOK_GET_KONGFU_FX) then
		local ok, err = _hook()
		if not ok then
			_log("ERROR: Could not install hook: " .. tostring(err))
			_state.is_enabled = false
			return false, err
		end
	end

	-- Trigger refresh
	local mp = Utils.get_main_player()
	if mp and mp.refresh_fashion_kongfu then
		pcall(function()
			mp:refresh_fashion_kongfu()
		end)
	end

	_log("=== DUAL MODE ENABLED ===")
	return true
end

-- Disable persistent mode
function Effects.disable()
	_state.is_enabled = false
	_state.kungfu_to_effect = {}
	_unhook()

	_log("=== EFFECTS DISABLED ===")
	return true
end

-- Check if enabled
function Effects.is_enabled()
	return _state.is_enabled
end

-- Get current mappings
function Effects.get_dual_mappings()
	return _state.kungfu_to_effect or {}
end

-- ============================================================
-- DISCOVERY MODE (for debugging)
-- ============================================================

function Effects.enable_discovery()
	if Hooks.is_hooked(HOOK_DISCOVERY) then
		_log("Discovery mode already enabled")
		return true
	end

	_state.discovery_mode = true
	_state.logged_count = 0

	local ok, err = Hooks.hook_method(HOOK_DISCOVERY, MODULE_PLAYER_AVATAR, "PlayerAvatar", "get_kongfu_fx_item", {
		post_exec = function(args, results, tb)
			_log("========================================")
			_log("get_kongfu_fx_item CALLED")
			_log("========================================")

			-- Log INPUT arguments
			_log("Input Arguments:")
			if args and args.n and args.n > 0 then
				for i = 1, args.n do
					local arg = args[i]
					local arg_type = type(arg)
					if arg_type == "table" then
						local mt = getmetatable(arg)
						if mt and mt.__tostring then
							_log("  args[" .. i .. "]: " .. tostring(arg) .. " (instance)")
						else
							local count = 0
							for _ in pairs(arg) do
								count = count + 1
							end
							_log("  args[" .. i .. "]: <table> (" .. count .. " items)")
						end
					else
						_log("  args[" .. i .. "]: " .. tostring(arg) .. " (" .. arg_type .. ")")
					end
				end
			else
				_log("  (no arguments)")
			end

			-- Log RETURN values
			_log("Return Values:")
			if results and results.n and results.n > 0 then
				_log("  Number of return values: " .. results.n)
				for i = 1, results.n do
					local result = results[i]
					_log("  results[" .. i .. "]: " .. tostring(result) .. " (" .. type(result) .. ")")
				end
			else
				_log("  (no return values / nil)")
			end

			_state.logged_count = _state.logged_count + 1
			_log("Total calls logged: " .. _state.logged_count)
			_log("========================================")
		end,
	})

	if ok then
		_log("=== DISCOVERY MODE ENABLED ===")
		_log("Hook installed on: PlayerAvatar.get_kongfu_fx_item")
		return true
	else
		_log("ERROR: Failed to install hook: " .. tostring(err))
		_state.discovery_mode = false
		return false, err
	end
end

function Effects.disable_discovery()
	if Hooks.is_hooked(HOOK_DISCOVERY) then
		Hooks.unhook(HOOK_DISCOVERY)
		_log("=== DISCOVERY MODE DISABLED ===")
		_log("Total calls logged: " .. _state.logged_count)
	end
	_state.discovery_mode = false
	return true
end

function Effects.is_discovery_active()
	return _state.discovery_mode
end

function Effects.get_log_count()
	return _state.logged_count
end

-- ============================================================
-- INFO
-- ============================================================

function Effects.info()
	_log("=== EFFECTS MODULE INFO ===")
	_log("Persistent mode: " .. tostring(_state.is_enabled))
	if _state.is_enabled and _state.effect_id then
		_log("Current effect_id: " .. _state.effect_id)
		local effect_data = Effects.get_effect_data(_state.effect_id)
		if effect_data then
			_log("Effect name: " .. effect_data.name)
		end
	end
	_log("Discovery mode: " .. tostring(_state.discovery_mode))
	_log("Calls logged: " .. _state.logged_count)
	_log("=========================")
end

return Effects
