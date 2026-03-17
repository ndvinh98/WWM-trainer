-- Scripts/actions/effects.lua - Wuxue Skill Effect Changer
local ActionBase = _G.Reg.lib("ActionBase")
local Effects = ActionBase:extend("actions.effects")

local MODULE_PLAYER_AVATAR = "hexm.client.entities.local.player_avatar"

function Effects:define_state()
	return {
		persistent = {
			is_enabled = false,
			kungfu_to_effect = {},
			discovery_mode = false,
			logged_count = 0,
			effect_data = {},
			effect_list = {},
		},
		transient = {},
	}
end

function Effects:define_hooks()
	return {
		get_kongfu_fx = {
			spec = MODULE_PLAYER_AVATAR .. ":PlayerAvatar:get_kongfu_fx_item",
			override_orig_function = true,
			post_exec = function(self_action, original, self_target, kongfu_id)
				if not self_action.state.is_enabled then
					return original(self_target, kongfu_id)
				end

				if kongfu_id and self_action.state.kungfu_to_effect[kongfu_id] then
					return self_action.state.kungfu_to_effect[kongfu_id]
				end

				return original(self_target, kongfu_id)
			end,
		},
		discovery = {
			spec = MODULE_PLAYER_AVATAR .. ":PlayerAvatar:get_kongfu_fx_item",
			post_exec = function(self_action, args, results, traceback)
				if not self_action.state.discovery_mode then return end
				local kongfu_id = args[2] -- arg[1] is self
				self_action.state.logged_count = self_action.state.logged_count + 1
				self_action:log(string.format("[Discovery] get_kongfu_fx_item(%s) -> %s", tostring(kongfu_id), tostring(results)))
			end,
		},
	}
end

function Effects:_translate(tid)
	if not tid then return nil end
	local ok, text = pcall(function()
		return G.locale_manager:get_locale_text_by_tid(tid)
	end)
	if ok and text and text ~= "" and text ~= tostring(tid) then
		return text
	end
	return nil
end

function Effects:generate_effect_data()
	if not G or not G.datam then
		self:log("ERROR: G.datam not available")
		return nil, nil
	end

	if not G.datam.wuxue_effect_data then
		self:log("ERROR: G.datam.wuxue_effect_data not available")
		return nil, nil
	end

	local kongfu_names = {}
	if G.datam.kongfu then
		local kf_items = G.datam.kongfu:items()
		if kf_items then
			for _, kf_entry in pairs(kf_items) do
				local kf_id = tonumber(kf_entry[1])
				local kf = kf_entry[2]
				if kf_id and kf then
					local name = self:_translate(kf:get("name", nil))
					if name then
						kongfu_names[kf_id] = name
					end
				end
			end
		end
	end

	local effect_to_extra_kongfu = {}
	if G.datam.wuxue_effect_default then
		local def_items = G.datam.wuxue_effect_default:items()
		if def_items then
			for _, def_entry in pairs(def_items) do
				local kf_id = tonumber(def_entry[1])
				local def = def_entry[2]
				if kf_id and def then
					local default_id = def:get("default_id", nil)
					if default_id then
						if not effect_to_extra_kongfu[default_id] then
							effect_to_extra_kongfu[default_id] = {}
						end
						table.insert(effect_to_extra_kongfu[default_id], kf_id)
					end
				end
			end
		end
	end

	local effect_data = {}
	local effect_list_arr = {}
	local count = 0

	local items = G.datam.wuxue_effect_data:items()
	if not items then
		self:log("ERROR: wuxue_effect_data:items() returned nil")
		return nil, nil
	end

	for _, entry in pairs(items) do
		local effect_id = tonumber(entry[1])
		local d = entry[2]
		if effect_id and d then
			local name_tid = d:get("name", nil)
			local base_name = self:_translate(name_tid) or ("Effect #" .. effect_id)

			local kongfu_id_set = {}
			local kongfu_id_arr = {}
			local direct_kf = d:get("kongfu_id", nil)
			if direct_kf and direct_kf > 0 then
				kongfu_id_set[direct_kf] = true
				table.insert(kongfu_id_arr, direct_kf)
			end
			if effect_to_extra_kongfu[effect_id] then
				for _, kid in ipairs(effect_to_extra_kongfu[effect_id]) do
					if not kongfu_id_set[kid] then
						kongfu_id_set[kid] = true
						table.insert(kongfu_id_arr, kid)
					end
				end
			end
			table.sort(kongfu_id_arr)

			local kf_names_map = {}
			for _, kid in ipairs(kongfu_id_arr) do
				if kongfu_names[kid] then
					kf_names_map[kid] = kongfu_names[kid]
				end
			end

			local display_name = base_name
			if kongfu_id_arr[1] and kf_names_map[kongfu_id_arr[1]] then
				display_name = "[" .. kf_names_map[kongfu_id_arr[1]] .. "] " .. base_name
			end

			local icon_no = d:get("icon_no", "")
			local item_group = d:get("item_group", 0)
			local fenghua_value = d:get("fenghua_value", 0)
			local fh_value = d:get("fh_value", 0)

			local icon_arr = {}
			local icon_transverse = d:get("icon_no_transverse_list", nil)
			if icon_transverse then
				pcall(function()
					for _, iv in pairs(icon_transverse) do
						if iv and iv ~= "" then
							table.insert(icon_arr, iv)
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

			table.insert(effect_list_arr, {
				effect_id = effect_id,
				name = display_name,
				kongfu_ids = kongfu_id_arr,
				icon = icon_no,
				fh_value = fh_value,
			})

			count = count + 1
		end
	end

	table.sort(effect_list_arr, function(a, b)
		local a_kf = a.kongfu_ids[1] or 999999
		local b_kf = b.kongfu_ids[1] or 999999
		if a_kf ~= b_kf then return a_kf < b_kf end
		return a.effect_id < b.effect_id
	end)

	self.state.effect_data = effect_data
	self.state.effect_list = effect_list_arr

	self:log("Generated " .. count .. " effects")
	return effect_data, effect_list_arr
end

function Effects:load_effect_data()
	if self.state.effect_data and next(self.state.effect_data) then
		return self.state.effect_data, self.state.effect_list
	end
	return self:generate_effect_data()
end

function Effects:get_effect_list(kongfu_id)
	local _, all_effects = self:load_effect_data()
	if not all_effects then
		return {}
	end

	local filtered = {}
	for _, effect in ipairs(all_effects) do
		local include = true

		if effect.fh_value == 0 then
			include = false
		end

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
			table.insert(filtered, effect)
		end
	end

	return filtered
end

function Effects:get_effect_data(effect_id)
	local data, _ = self:load_effect_data()
	return data and data[tonumber(effect_id)]
end

function Effects:_get_player_kongfu_id(slot)
	local mp = G and G.main_player
	if not mp then return nil end
	local kongfu_id
	if slot == "secondary" then
		pcall(function()
			if mp.get_sub_kongfu then
				kongfu_id = mp:get_sub_kongfu()
			end
		end)
	else
		pcall(function()
			if mp.enchant_get_kongfu_id then
				kongfu_id = mp:enchant_get_kongfu_id()
			end
		end)
	end
	return kongfu_id
end

function Effects:get_primary_effect_list()
	local kongfu_id = self:_get_player_kongfu_id("primary")
	return self:get_effect_list(kongfu_id)
end

function Effects:get_secondary_effect_list()
	local kongfu_id = self:_get_player_kongfu_id("secondary")
	return self:get_effect_list(kongfu_id)
end

function Effects:get_display_name(effect)
	return (effect.name or "Unknown") .. " [" .. tostring(effect.effect_id or "?") .. "]"
end

function Effects:apply_dual_items(left_effect, right_effect)
	local primary_kf = self:_get_player_kongfu_id("primary")
	local secondary_kf = self:_get_player_kongfu_id("secondary")
	if left_effect and right_effect and primary_kf and secondary_kf then
		return self:enable_dual(
			left_effect.effect_id or left_effect,
			right_effect.effect_id or right_effect,
			primary_kf,
			secondary_kf
		)
	elseif left_effect and primary_kf then
		return self:enable_single(left_effect.effect_id or left_effect, primary_kf)
	end
	return false
end

function Effects:apply(effect_id)
	local mp = G.main_player
	if not mp then
		return false, "No main player"
	end

	effect_id = tonumber(effect_id)
	if not effect_id then
		return false, "Invalid effect_id"
	end

	if mp and mp.refresh_fashion_kongfu then
		local ok = pcall(function()
			mp:refresh_fashion_kongfu()
		end)
		if not ok then
			return false, "Error refreshing fashion kongfu"
		end
	end

	return true
end

function Effects:_refresh_player()
	local mp = G.main_player
	if mp and mp.refresh_fashion_kongfu then
		pcall(function() mp:refresh_fashion_kongfu() end)
	end
end

function Effects:enable_single(effect_id, kungfu_id)
	effect_id = tonumber(effect_id)
	kungfu_id = tonumber(kungfu_id)

	if not effect_id or not kungfu_id then return false end

	self.state.kungfu_to_effect[kungfu_id] = effect_id
	self.state.is_enabled = true

	self:hook("get_kongfu_fx")
	self:_refresh_player()
	return true
end

function Effects:enable_dual(main_effect_id, secondary_effect_id, main_kungfu_id, secondary_kungfu_id)
	main_effect_id = tonumber(main_effect_id)
	secondary_effect_id = tonumber(secondary_effect_id)
	main_kungfu_id = tonumber(main_kungfu_id)
	secondary_kungfu_id = tonumber(secondary_kungfu_id)

	if not main_effect_id or not secondary_effect_id or not main_kungfu_id or not secondary_kungfu_id then
		return false
	end

	self.state.kungfu_to_effect = {
		[main_kungfu_id] = main_effect_id,
		[secondary_kungfu_id] = secondary_effect_id,
	}
	self.state.is_enabled = true

	self:hook("get_kongfu_fx")
	self:_refresh_player()
	return true
end

function Effects:disable()
	self.state.is_enabled = false
	self.state.kungfu_to_effect = {}
	self:unhook("get_kongfu_fx")
	self:unhook("discovery")
	self:_refresh_player()
	return true
end

function Effects:is_enabled()
	return self.state.is_enabled
end

function Effects:get_dual_mappings()
	return self.state.kungfu_to_effect or {}
end

function Effects:enable_discovery()
	self.state.discovery_mode = true
	self.state.logged_count = 0
	self:hook("discovery")
	return true
end

function Effects:disable_discovery()
	self:unhook("discovery")
	self.state.discovery_mode = false
	return true
end

function Effects:is_discovery_active()
	return self.state.discovery_mode
end

function Effects:get_log_count()
	return self.state.logged_count
end

function Effects:info()
	self:log("Enabled: " .. tostring(self.state.is_enabled))
	self:log("Discovery: " .. tostring(self.state.discovery_mode))
	self:log("Logs: " .. self.state.logged_count)
end

return Effects:new()
