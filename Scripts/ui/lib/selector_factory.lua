-- Scripts/ui/lib/selector_factory.lua
-- Generic selector creation from declarative config.
-- Replaces 7 individual selector wrapper files.

local SelectorFactory = {}

local Reg = _G.Reg
local Constants = Reg.lib("Constants")
local Logger = Reg.lib("Logger")

local function _log(msg)
	if Logger then
		Logger.log("[SelectorFactory] " .. msg)
	end
end

-- Lazy-load ItemSelector and DualSelector
local _item_selector, _dual_selector

local function _get_item_selector()
	if not _item_selector then
		_item_selector = dofile(Constants.SCRIPTS_ROOT .. "\\ui\\components\\item_selector.lua")
	end
	return _item_selector
end

local function _get_dual_selector()
	if not _dual_selector then
		_dual_selector = dofile(Constants.SCRIPTS_ROOT .. "\\ui\\components\\dual_selector.lua")
	end
	return _dual_selector
end

--[[
    Create a selector from declarative config.

    Single selector config:
    {
        type = "single",
        action = "suit_skins",      -- module name in KURO_modules
        data_fn = "get_list",        -- method on action to get items
        apply_fn = "apply",          -- method on action to apply selection
        display_fn = "get_display_name",  -- method or function(item) for display text
        id_fn = "get_id",           -- optional: method or function(item) for unique ID
        memory_key = "LAST_SUIT",   -- Reg key for persisting selection
        title = "Suit Selector",
        enable_search = true,
        empty_message = "No items available",
    }

    Dual selector config:
    {
        type = "dual",
        action = "effects",
        left = { data_fn = "get_kungfu_list", display_fn = ..., title = "Left" },
        right = { data_fn = "get_effect_list", display_fn = ..., title = "Right" },
        apply_fn = "apply_dual",
        memory_key = "LAST_DUAL_EFFECT",
        title = "Effect Selector",
    }
]]
function SelectorFactory.show(config, user_callbacks)
	user_callbacks = user_callbacks or {}
	local action_name = "actions." .. config.action
	local action = Reg.module(action_name)

	if not action then
		_log("Action module not found: " .. action_name)
		return nil
	end

	if config.type == "dual" then
		return SelectorFactory._show_dual(config, action, user_callbacks)
	else
		return SelectorFactory._show_single(config, action, user_callbacks)
	end
end

function SelectorFactory._show_single(config, action, user_callbacks)
	local ItemSelector = _get_item_selector()
	if not ItemSelector then
		_log("ItemSelector not loaded")
		return nil
	end

	-- Get items from action module
	local items = action[config.data_fn](action)
	if not items then
		_log("No data from " .. config.data_fn)
		items = {}
	end

	-- Build display function
	local display_fn
	if type(config.display_fn) == "function" then
		display_fn = config.display_fn
	elseif type(config.display_fn) == "string" and action[config.display_fn] then
		display_fn = function(item)
			return action[config.display_fn](action, item)
		end
	else
		display_fn = function(item)
			return item.name or tostring(item)
		end
	end

	-- Build ID function
	local id_fn
	if type(config.id_fn) == "function" then
		id_fn = config.id_fn
	elseif type(config.id_fn) == "string" and action[config.id_fn] then
		id_fn = function(item)
			return action[config.id_fn](action, item)
		end
	else
		id_fn = function(item)
			return item.id or item.no or tostring(item)
		end
	end

	return ItemSelector.show({
		title = config.title or "Selector",
		items = items,
		get_display_name = display_fn,
		get_id = id_fn,
		on_apply = function(item)
			if action[config.apply_fn] then
				local ok, result, reason = pcall(action[config.apply_fn], action, item)
				_log("Item: " .. _G.dump(item))

				if not ok then
					_log("Apply exception: " .. tostring(result))
					return false
				end
				if not result then
					_log("Apply returned false: " .. tostring(reason or "no reason given"))
				end
				return result
			end
			_log("Apply method '" .. tostring(config.apply_fn) .. "' not found on action")
			return false
		end,
		on_select = function(item, success)
			if user_callbacks.on_select then
				user_callbacks.on_select(item, success, action)
			end
		end,
		on_close = user_callbacks.on_close,
		instance_name = config.memory_key and ("VAR_" .. config.memory_key) or nil,
		enable_search = config.enable_search ~= false,
		empty_message = config.empty_message or "No items available",
	})
end

function SelectorFactory._show_dual(config, action, user_callbacks)
	local DualSelector = _get_dual_selector()
	if not DualSelector then
		_log("DualSelector not loaded")
		return nil
	end

	local left_items = action[config.left.data_fn](action)
	local right_items = action[config.right.data_fn](action)

	local function _make_display(cfg)
		if type(cfg.display_fn) == "function" then
			return cfg.display_fn
		end
		if type(cfg.display_fn) == "string" and action[cfg.display_fn] then
			return function(item)
				return action[cfg.display_fn](action, item)
			end
		end
		return function(item)
			return item.name or tostring(item)
		end
	end

	return DualSelector.show({
		title = config.title or "Dual Selector",
		left = {
			title = config.left.title or "Left",
			items = left_items or {},
			get_display_name = _make_display(config.left),
			get_id = function(item)
				return item.id or item.no or tostring(item)
			end,
			empty_message = config.left.empty_message or "No items",
		},
		right = {
			title = config.right.title or "Right",
			items = right_items or {},
			get_display_name = _make_display(config.right),
			get_id = function(item)
				return item.id or item.no or tostring(item)
			end,
			empty_message = config.right.empty_message or "No items",
		},
		on_apply = function(left_item, right_item)
			if action[config.apply_fn] then
				local ok, result, reason = pcall(action[config.apply_fn], action, left_item, right_item)
				if not ok then
					_log("Apply exception: " .. tostring(result))
					return false
				end
				if not result then
					_log("Apply returned false: " .. tostring(reason or "no reason given"))
				end
				return result
			end
			return false
		end,
		on_select = function(left_item, right_item, success)
			if user_callbacks.on_select then
				user_callbacks.on_select(left_item, right_item, success, action)
			end
		end,
		on_close = user_callbacks.on_close,
		instance_name = config.memory_key and ("VAR_" .. config.memory_key) or nil,
		enable_search = config.enable_search ~= false,
	})
end

function SelectorFactory.close(config)
	local instance_name = config.memory_key and ("VAR_" .. config.memory_key) or nil
	if not instance_name then
		return
	end

	if config.type == "dual" then
		local DualSelector = _get_dual_selector()
		if DualSelector then
			DualSelector.close(instance_name)
		end
	else
		local ItemSelector = _get_item_selector()
		if ItemSelector then
			ItemSelector.close(instance_name)
		end
	end
end

return SelectorFactory
