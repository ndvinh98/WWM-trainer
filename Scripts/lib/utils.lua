--[[
    Utils - Shared utility functions

    Provides:
    - safe_call: Execute function with error logging
    - safe_import: Try multiple import methods
    - safe_dofile: Load lua file safely
    - ensure_dir: Create directory if not exists
    - get_main_player: Get player reference safely
]]
local Utils = {}

-- Private: Lua 5.2+ compatibility
local _unpack = table.unpack
local _ROOT = "C:\\temp\\Where Winds Meet\\Scripts"
local inspect = dofile(_ROOT .. "\\lib\\inspect.lua")
local _Logger = dofile(_ROOT .. "\\lib\\logger.lua")
local ENABLE_LOGGING = true
local _log = function(msg)
	if ENABLE_LOGGING then
		_Logger.log("[Utils] " .. msg)
	end
end
-- Execute function safely, log error on failure
-- Returns: result, error (nil if success)
function Utils.safe_call(name, func, ...)
	local args = { ... }
	local ok, result = pcall(function()
		return func(_unpack(args))
	end)

	if ok then
		return result, nil
	else
		if _Logger then
			--_log("[ERROR] " .. tostring(name) .. ": " .. tostring(result))
		end
		return nil, result
	end
end

-- Import module using multiple methods
-- Returns: module, error
function Utils.safe_import(module_name)
	-- Try portable.import first (game-specific)
	if portable then
		if portable.import then
			local ok, mod = pcall(function()
				return portable.import(module_name)
			end)
			if ok and mod then
				return mod, nil
			end
			_log(
				"[ERROR] safe_import: portable.import failed for '"
					.. tostring(module_name)
					.. "' error: "
					.. tostring(mod)
			)
		end
		if portable.safe_import then
			local ok, mod = pcall(function()
				return portable.safe_import(module_name)
			end)
			if ok and mod then
				return mod, nil
			end
			_log(
				"[ERROR] safe_import: portable.safe_import failed for '"
					.. tostring(module_name)
					.. "' error: "
					.. tostring(mod)
			)
		end
		if portable.require then
			local ok, mod = pcall(function()
				return portable.require(module_name)
			end)
			if ok and mod then
				return mod, nil
			end
			_log(
				"[ERROR] safe_import: portable.require failed for '"
					.. tostring(module_name)
					.. "' error: "
					.. tostring(mod)
			)
		end
		if portable.try_import then
			local ok, mod = pcall(function()
				return portable.try_import(module_name)
			end)
			if ok and mod then
				return mod, nil
			end
			_log(
				"[ERROR] safe_import: portable.try_import failed for '"
					.. tostring(module_name)
					.. "' error: "
					.. tostring(mod)
			)
		end
	end

	-- Try require
	local ok, mod = pcall(function()
		return require(module_name)
	end)
	if ok and mod then
		return mod, nil
	end

	-- Try package.loaded
	local loaded = package.loaded[module_name]
	if loaded then
		return loaded, nil
	end

	_log("[ERROR] safe_import: Failed to import module '" .. tostring(module_name) .. "'")
	return nil, err_msg
end

-- Load lua file safely
-- Returns: result, error
function Utils.safe_dofile(filepath, name)
	name = name or filepath
	local result, err = Utils.safe_call("dofile:" .. name, dofile, filepath)
	if err and _Logger then
		_log("[ERROR] safe_dofile: Failed to load '" .. tostring(name) .. "': " .. tostring(err))
	end
	return result, err
end

-- Create directory if it doesn't exist
-- Uses PowerShell on Windows with hidden window
-- Returns: success, error
function Utils.ensure_dir(path)
	if not path then
		return false, "path is required"
	end

	-- Use PowerShell with hidden window to create directory (works on Windows)
	local cmd = string.format(
		"powershell -WindowStyle Hidden -Command \"if (!(Test-Path '%s')) { New-Item -ItemType Directory -Path '%s' -Force | Out-Null }\"",
		path,
		path
	)

	local ok, err = pcall(os.execute, cmd)
	if ok then
		return true, nil
	else
		return false, err
	end
end

-- Clear all files in a directory (keeps the folder, deletes files only)
-- Uses PowerShell with hidden window
-- Returns: success, error
function Utils.clear_dir_contents(path)
	if not path then
		return false, "path is required"
	end

	-- Use PowerShell to delete all files in the directory (not subdirectories)
	local cmd = string.format(
		"powershell -WindowStyle Hidden -Command \"if (Test-Path '%s') { Get-ChildItem -Path '%s' -File | Remove-Item -Force }\"",
		path,
		path
	)

	local ok, err = pcall(os.execute, cmd)
	if ok then
		return true, nil
	else
		return false, err
	end
end

-- Execute shell command with hidden window (no PowerShell popup)
-- Returns: success, error
function Utils.shell_hidden(cmd)
	if not cmd then
		return false, "cmd is required"
	end

	-- Wrap command in PowerShell to hide window
	local ps_cmd = string.format('powershell -WindowStyle Hidden -Command "%s"', cmd:gsub('"', '\\"'))

	local ok, err = pcall(os.execute, ps_cmd)
	if ok then
		return true, nil
	else
		return false, err
	end
end

-- Get main player reference safely
-- Returns: player, error
function Utils.get_main_player()
	if G and G.main_player then
		return G.main_player, nil
	end
	return nil, "main_player not available"
end

-- Get entity manager safely
-- Returns: entity_manager, error
function Utils.get_entity_manager()
	local ok, em = pcall(function()
		return MEntityManager:GetInstance()
	end)
	if ok and em then
		return em, nil
	else
		return nil, em or "MEntityManager not available"
	end
end

function Utils.get_key_by_value(tbl, val)
	if not tbl then
		return nil
	end
	for k, v in pairs(tbl) do
		if v == val then
			return tostring(k)
		end
	end
	return nil
end

-- ============================================================
-- PHASE 1: SHARED HELPER FUNCTIONS
-- ============================================================

--- Translate a TID to display text using the game's locale manager
--- @param tid number|string Translation ID
--- @return string|nil - Translated text or nil if unavailable
function Utils.translate(tid)
	if not tid then
		return nil
	end
	local ok, text = pcall(function()
		if not G or not G.locale_manager then
			return nil
		end
		return G.locale_manager:get_locale_text_by_tid(tid)
	end)
	if ok and text and text ~= "" and text ~= tostring(tid) then
		return text
	end
	return nil
end

--- Safely get a value from an object with fallback to .get() method
--- @param obj table - Object to get value from
--- @param key any - Key to lookup
--- @param default any - Default value if key not found
--- @return any - Value or default
function Utils.safe_get(obj, key, default)
	if obj == nil then
		return default
	end
	local ok, value = pcall(function()
		return obj[key]
	end)
	if ok and value ~= nil then
		return value
	end
	-- Try .get() method (common in game objects)
	local ok_getter, getter = pcall(function()
		return obj.get
	end)
	if ok_getter and type(getter) == "function" then
		local ok_get, value_get = pcall(function()
			return getter(obj, key, default)
		end)
		if ok_get then
			return value_get
		end
	end
	return default
end

--- Create a log function factory for consistent module logging
--- @param prefix string - Module prefix (e.g., "Combat", "Buffs")
--- @return function - Log function that accepts a message string
function Utils.create_log(prefix)
	local Logger = Reg and Reg.lib("Logger")
	return function(msg)
		if Logger then
			Logger.log("[" .. prefix .. "] " .. msg)
		end
	end
end

--- Unified buff application with priority chain
--- Priority: 1) fake_server.buff:add_buff, 2) mp:add_buff with options, 3) combat_train_action fallback
--- @param buff_id number - Buff ID to apply
--- @param opts table - Options: {duration, reason, source_id, ignore_dead, persistent}
--- @return boolean - Success
function Utils.apply_buff(buff_id, opts)
	opts = opts or {}
	local duration = opts.duration or -1
	local reason = opts.reason or "utils_mod"
	local source_id = opts.source_id
	local ignore_dead = opts.ignore_dead ~= false
	local persistent = opts.persistent ~= nil and opts.persistent or false

	local mp = G.main_player
	if not mp then
		return false
	end

	-- Priority 1: fake_server.buff:add_buff (works in single-mode spaces)
	if mp.fake_server and mp.fake_server.buff then
		local ok, err = pcall(function()
			mp.fake_server.buff:add_buff(buff_id, mp.id or source_id or mp.entity_id)
		end)
		if ok then
			return true
		end
	end

	-- Priority 2: mp:add_buff with options
	if mp.add_buff then
		local ok, err = pcall(function()
			mp:add_buff(buff_id, source_id or mp.id or mp.entity_id, {
				["duration"] = duration,
				["persistent"] = persistent,
				["reason"] = reason,
				["ignore_dead"] = ignore_dead,
			})
		end)
		if ok then
			return true
		end
	end

	-- Priority 3: combat_train_action fallback (GM module)
	local combat_action = Utils.safe_import("hexm.client.ui.windows.gm.gm_combat.combat_train_action")
	if combat_action and combat_action.add_buff then
		local ok = pcall(function()
			combat_action.add_buff(buff_id)
		end)
		if ok then
			return true
		end
	end

	return false
end

--- Unified buff removal with priority chain
--- Priority: 1) fake_server.buff:remove_buffs_by_No, 2) mp:remove_buffs_by_No
--- @param buff_id number - Buff ID to remove
--- @param opts table - Options: {reason, source_id}
--- @return boolean - Success
function Utils.remove_buff(buff_id, opts)
	opts = opts or {}
	local reason = opts.reason or "utils_mod"
	local source_id = opts.source_id

	local mp = G.main_player
	if not mp then
		return false
	end

	-- Priority 1: fake_server.buff:remove_buffs_by_No
	if mp.fake_server and mp.fake_server.buff then
		local ok = pcall(function()
			mp.fake_server.buff:remove_buffs_by_No({ buff_id }, source_id or mp.id or mp.entity_id, reason)
		end)
		if ok then
			return true
		end
	end

	-- Priority 2: mp:remove_buffs_by_No
	if mp.remove_buffs_by_No then
		local ok = pcall(function()
			mp:remove_buffs_by_No({ buff_id }, source_id or mp.id or mp.entity_id, reason)
		end)
		if ok then
			return true
		end
	end

	-- Priority 3: combat_train_action fallback (GM module)
	local combat_action = Utils.safe_import("hexm.client.ui.windows.gm.gm_combat.combat_train_action")
	if combat_action and (combat_action.rm_buff or combat_action.remove_buff) then
		local ok = pcall(function()
			if combat_action.rm_buff then
				combat_action.rm_buff(buff_id)
			elseif combat_action.remove_buff then
				combat_action.remove_buff(buff_id, mp.entity_id)
			end
		end)
		if ok then
			return true
		end
	end

	return false
end

-- Pack args preserving count (handles nil values correctly)
function Utils.pack(...)
	return table.pack(...)
end

-- Unpack args using stored count
function Utils.unpack(t)
	return table.unpack(t, 1, t.n)
end

function Utils.decode_msgpack(data)
	local cmsgpack = Utils.safe_import("cmsgpack")

	local ok, unpacked = pcall(cmsgpack.unpack, data)
	if ok then
		_log("Decoded MessagePack data: " .. tostring(unpacked))
		return unpacked
	else
		_log("Failed to decode MessagePack data: " .. tostring(unpacked))
		return data -- Return original if decode fails
	end
end

-- This creates proxy tables that silently absorb all writes and always appear empty
function Utils.create_empty_proxy()
	local proxy = {}
	-- Stub function that does nothing and returns nil
	local noop = function()
		return nil
	end
	-- Common dict-like methods that should return safe values
	local safe_methods = {
		setdefault = function(self, key, default)
			return default
		end,
		get = function(self, key, default)
			return default
		end,
		keys = function(self)
			return {}
		end,
		values = function(self)
			return {}
		end,
		items = function(self)
			return {}
		end,
		pop = function(self, key, default)
			return default
		end,
		clear = noop,
		update = noop,
		copy = function(self)
			return {}
		end,
		append = noop,
		insert = noop,
		remove = noop,
		extend = noop,
	}
	local mt = {
		-- Return safe stub for method calls, nil for other keys
		__index = function(t, k)
			if safe_methods[k] then
				return safe_methods[k]
			end
			return nil
		end,
		-- Silently absorb all writes
		__newindex = function(t, k, v)
			-- Do nothing - discard the write
		end,
		-- Always return 0 for length
		__len = function(t)
			return 0
		end,
		-- pairs() returns empty iterator
		__pairs = function(t)
			return function()
				return nil
			end, t, nil
		end,
		-- ipairs() returns empty iterator
		__ipairs = function(t)
			return function()
				return nil
			end, t, 0
		end,
		-- Comparison operators
		__le = function(a, b)
			return true
		end,
		__lt = function(a, b)
			return false
		end,
		-- tostring returns empty representation
		__tostring = function(t)
			return "{}"
		end,
		-- Prevent metatable access
		__metatable = "protected",
	}
	setmetatable(proxy, mt)
	return proxy
end

function Utils.delay_call(delay_seconds, func, ...)
	local args = table.pack(...)
	local scene = cc.Director:getInstance():getRunningScene()
	local delayed_action = cc.Sequence:create({
		cc.DelayTime:create(delay_seconds or 1),
		cc.CallFunc:create(function()
			local ok, err = pcall(func, table.unpack(args, 1, args.n))
			if not ok then
				_log("Error in delayed call: " .. tostring(err))
			end
		end),
	})
	scene:runAction(delayed_action)
end

-- Decide what counts as "instance-like" in your environment.
-- Tweak this predicate to match your engine/framework.
-- Helper: safe tostring
local function safe_tostring(x)
	local ok, s = pcall(tostring, x)
	if ok then
		return s
	end
	return "<tostring failed>"
end

function Utils.is_pairable(obj)
	-- Check explicit types first: list, dict, table, userdata
	local t = type(obj)
	if t == "table" or t == "list" or t == "dict" then
		return true
	end

	if Utils.is_instance_like(obj) then
		local ok, err = pcall(function()
			for _, v in pairs(obj) do
				-- If we can iterate without error, it's pairable
				return true
			end
		end)
		if ok then
			return true
		end
	end

	return false
end

function Utils.is_instance_like(obj)
	local t = type(obj)
	if t == "class" or t == "instance" then
		return true
	end
	return false
end

-- Your exact extraction logic -> returns a TABLE
function Utils.dump_instance_obj(obj)
	local out = {
		__name__ = tostring(obj),
		__type__ = type(obj),
		__properties__ = {},
		__methods__ = {},
	}
	--------------------------------------------------
	-- 🔹 PROPERTIES (EXACT logic)
	--------------------------------------------------
	if obj._query_properties then
		local ok_props, props = pcall(function()
			return obj:_query_properties()
		end)
		if ok_props and props then
			for _, name in pairs(props) do
				local ok_val, val = pcall(function()
					return obj[name]
				end)
				if not ok_val then
					val = "<error reading>"
				end
				out.__properties__[tostring(name)] = repr(val)
			end
		end
	end

	--------------------------------------------------
	-- 🔹 CLASS METHODS (EXACT logic part 1: pairs(obj))
	--------------------------------------------------
	local is_pairable = pcall(function()
		for _, v in pairs(obj) do
			-- If we can iterate without error, it's pairable
			return true
		end
	end)

	if is_pairable then
		pcall(function()
			for k, v in pairs(obj) do
				out.__methods__[k] = repr(v)
			end
		end)
	end

	return out
end

-- ============================================================
-- IMPROVED dump_value: pre-normalize game types before inspect
-- Uses patterns from: functions.lua (dump, repr, hasattr, getattr, dirclass),
-- console.lua (#e slot, _query_properties, class hierarchy),
-- solo_boss_recorder.lua (_convert_value with todict/tolist/to_tuple),
-- classutils.lua (CustomMapType, CustomListType).
-- ============================================================

-- Check if a value can be iterated with pairs().
-- Must verify BOTH type compatibility AND actual iterability (some engine
-- objects have the right type but crash on pairs).
local function _can_pairs(x)
	if x == nil then
		return false
	end
	local tx = type(x)
	-- Known iterable types in this engine
	if tx ~= "table" and tx ~= "list" and tx ~= "dict" and tx ~= "tuple" and tx ~= "instance" and tx ~= "class" then
		return false
	end
	-- Probe: try to actually call pairs() — engine objects can crash
	local ok = pcall(function()
		for _ in pairs(x) do
			break
		end
	end)
	return ok
end

-- Try to get the class name of an instance (e.g. "Vector3", "CustomMapType").
-- Uses the .sub chain (class reference) rather than tostring which gives value repr.
local function _get_class_name(val)
	local ok, name = pcall(function()
		local sub = val.sub
		if sub then
			local s = tostring(sub)
			-- Class tostring often looks like "<class 'ClassName'>" or just "ClassName"
			local class_name = s:match("class%s+'([^']+)'") or s:match("class%s+(%S+)")
			if class_name then
				return class_name
			end
			-- If tostring of class doesn't have "class" prefix, use it directly
			if not s:match("^<") then
				return s
			end
		end
	end)
	return ok and name or nil
end

-- Pre-normalize a value into plain Lua tables that inspect() can handle.
-- Works recursively with cycle detection and depth limiting.
local function _normalize(val, seen, depth, max_depth)
	if val == nil then
		return nil
	end

	-- Depth guard
	depth = depth or 0
	max_depth = max_depth or 8
	if depth > max_depth then
		local ok_s, s = pcall(tostring, val)
		return ok_s and (s .. " <max depth>") or "<max depth>"
	end

	local t = type(val)

	-- Primitives: pass through
	if t == "number" or t == "boolean" or t == "string" or t == "nil" then
		return val
	end

	-- Functions: show source info (like game's repr())
	if t == "function" then
		local ok_info, info = pcall(debug.getinfo, val, "S")
		if ok_info and info and info.what ~= "C" then
			return string.format("function<%s:%s>", info.short_src or "?", info.linedefined or "?")
		end
		local ok_s, s = pcall(tostring, val)
		return ok_s and s or "<function>"
	end

	-- Cycle detection for reference types
	seen = seen or {}
	if
		t == "table"
		or t == "list"
		or t == "dict"
		or t == "tuple"
		or t == "instance"
		or t == "class"
		or t == "userdata"
	then
		if seen[val] then
			local ok_s, s = pcall(tostring, val)
			return ok_s and ("*REF:" .. s .. "*") or "*REF*"
		end
		seen[val] = true
	end

	-- ----------------------------------------------------------------
	-- list type → convert to plain array
	-- ----------------------------------------------------------------
	if t == "list" then
		-- Try :tolist() first (CustomListType pattern from classutils.lua)
		local ok_tl, tl = pcall(function()
			return val:tolist()
		end)
		if ok_tl and tl and type(tl) == "table" then
			local arr = { __type__ = "list" }
			for i, v in ipairs(tl) do
				arr[i] = _normalize(v, seen, depth + 1, max_depth)
			end
			return arr
		end
		-- Fallback: iterate with pairs (from functions.lua dump pattern)
		if _can_pairs(val) then
			local arr = { __type__ = "list" }
			pcall(function()
				for _, v in pairs(val) do
					arr[#arr + 1] = _normalize(v, seen, depth + 1, max_depth)
				end
			end)
			return arr
		end
		local ok_s, s = pcall(tostring, val)
		return ok_s and s or "<list>"
	end

	-- ----------------------------------------------------------------
	-- tuple type → convert to plain array (same as list)
	-- Pattern from GameLevelNodesPart2.lua: type(x) == "list" or type(x) == "tuple"
	-- Tuples are ordered, iterable with pairs(), like lists
	-- ----------------------------------------------------------------
	if t == "tuple" then
		if _can_pairs(val) then
			local arr = { __type__ = "tuple" }
			pcall(function()
				for _, v in pairs(val) do
					arr[#arr + 1] = _normalize(v, seen, depth + 1, max_depth)
				end
			end)
			return arr
		end
		local ok_s, s = pcall(tostring, val)
		return ok_s and s or "<tuple>"
	end

	-- ----------------------------------------------------------------
	-- dict type → convert to plain table
	-- ----------------------------------------------------------------
	if t == "dict" then
		-- Try :todict() first (CustomMapType pattern)
		local ok_td, td = pcall(function()
			return val:todict()
		end)
		if ok_td and td and type(td) == "table" then
			local out = { __type__ = "dict" }
			for k, v in pairs(td) do
				out[tostring(k)] = _normalize(v, seen, depth + 1, max_depth)
			end
			return out
		end
		-- Fallback: iterate with pairs
		if _can_pairs(val) then
			local out = { __type__ = "dict" }
			pcall(function()
				for k, v in pairs(val) do
					out[tostring(k)] = _normalize(v, seen, depth + 1, max_depth)
				end
			end)
			return out
		end
		local ok_s, s = pcall(tostring, val)
		return ok_s and s or "<dict>"
	end

	-- ----------------------------------------------------------------
	-- instance / class → structured introspection
	-- Uses patterns from: console.lua (#e slot, _query_properties, .sub/.find hierarchy)
	-- solo_boss_recorder.lua (Vector/CustomMap/CustomList conversion)
	-- ----------------------------------------------------------------
	if t == "instance" or t == "class" then
		local ok_name, name_str = pcall(tostring, val)
		name_str = ok_name and name_str or ("<" .. t .. " ?>")

		-- Resolve class name via .sub chain (tostring gives VALUE repr for vectors etc.)
		local class_name = _get_class_name(val) or t

		-- Check for known value types with simple serialization (Vector, etc.)
		-- Pattern from solo_boss_recorder._convert_value
		if t == "instance" then
			-- to_tuple() → vectors, matrices, etc.
			local ok_tt, has_tt = pcall(function()
				return val.to_tuple ~= nil
			end)
			if ok_tt and has_tt then
				local ok_tup, tup = pcall(function()
					return val:to_tuple()
				end)
				if ok_tup and tup then
					return { __type__ = class_name, __value__ = _normalize(tup, seen, depth + 1, max_depth) }
				end
			end

			-- CustomMapType → :todict()
			local ok_td2, has_td2 = pcall(function()
				return val.todict ~= nil
			end)
			if ok_td2 and has_td2 then
				local ok_td3, td3 = pcall(function()
					return val:todict()
				end)
				if ok_td3 and td3 then
					return { __type__ = class_name, __value__ = _normalize(td3, seen, depth + 1, max_depth) }
				end
			end

			-- CustomListType → :tolist()
			local ok_tl2, has_tl2 = pcall(function()
				return val.tolist ~= nil
			end)
			if ok_tl2 and has_tl2 then
				local ok_tl3, tl3 = pcall(function()
					return val:tolist()
				end)
				if ok_tl3 and tl3 then
					return { __type__ = class_name, __value__ = _normalize(tl3, seen, depth + 1, max_depth) }
				end
			end
		end

		-- Simple value-types whose tostring is already informative
		-- e.g. Vector3 "(1,2,3)" — no "<instance" prefix
		local is_complex = (t == "instance" and name_str:find("instance")) or (t == "class" and name_str:find("class"))
		if not is_complex then
			return { __type__ = class_name, __value__ = name_str }
		end

		-- Deep introspection for complex instances/classes
		local out = { __name__ = name_str, __type__ = t }

		-- 1) _query_properties() — the primary property enumeration mechanism
		-- Pattern from functions.lua hasattr + console.lua _query_properties
		local ok_has_qp, has_qp = pcall(function()
			return val._query_properties ~= nil
		end)
		if ok_has_qp and has_qp then
			local ok_qp, props = pcall(function()
				return val:_query_properties()
			end)
			if ok_qp and props and _can_pairs(props) then
				local prop_out = {}
				pcall(function()
					for _, pname in pairs(props) do
						local ok_pv, pv = pcall(function()
							return val[pname]
						end)
						if ok_pv then
							prop_out[tostring(pname)] = _normalize(pv, seen, depth + 1, max_depth)
						else
							prop_out[tostring(pname)] = "<error reading>"
						end
					end
				end)
				if next(prop_out) then
					out.__properties__ = prop_out
				end
			end
		end

		-- 2) #e internal slot — used by console.lua for instance/class introspection
		local ok_e, e_data = pcall(function()
			return val["#e "]
		end)
		if ok_e and e_data ~= nil then
			local slot_out = {}
			if type(e_data) == "dict" then
				-- dict with _data sub-table
				local ok_has_data, data_field = pcall(function()
					return e_data:get("_data")
				end)
				if ok_has_data and data_field ~= nil and _can_pairs(data_field) then
					pcall(function()
						for k, v in pairs(data_field) do
							slot_out[tostring(k)] = _normalize(v, seen, depth + 1, max_depth)
						end
					end)
				elseif _can_pairs(e_data) then
					pcall(function()
						for k, v in pairs(e_data) do
							slot_out[tostring(k)] = _normalize(v, seen, depth + 1, max_depth)
						end
					end)
				end
			elseif _can_pairs(e_data) then
				pcall(function()
					for k, v in pairs(e_data) do
						slot_out[tostring(k)] = _normalize(v, seen, depth + 1, max_depth)
					end
				end)
			end
			if next(slot_out) then
				out.__slots__ = slot_out
			end
		end

		-- 3) Class hierarchy members — walk .sub chain (console.lua pattern)
		local method_out = {}
		if t == "instance" then
			local ok_sub, sub = pcall(function()
				return val.sub
			end)
			if ok_sub and sub then
				local chain = sub
				local chain_depth = 0
				while chain and chain_depth < 5 do
					pcall(function()
						local ok_ce, clz_tb = pcall(function()
							return chain["#e "]
						end)
						if ok_ce and clz_tb ~= nil and _can_pairs(clz_tb) then
							for k, v in pairs(clz_tb) do
								local ks = tostring(k)
								if not method_out[ks] then
									method_out[ks] = type(v) == "function" and "function"
										or _normalize(v, seen, depth + 1, max_depth)
								end
							end
						end
					end)
					local ok_next, next_chain = pcall(function()
						return chain.find
					end)
					chain = ok_next and next_chain or nil
					chain_depth = chain_depth + 1
				end
			end
		end

		-- 4) Try pairs() on the object itself for any remaining members
		-- (from functions.lua dump + inspect.lua patterns)
		if _can_pairs(val) then
			pcall(function()
				for k, v in pairs(val) do
					local ks = tostring(k)
					if not method_out[ks] then
						if type(v) == "function" then
							method_out[ks] = "function"
						else
							method_out[ks] = _normalize(v, seen, depth + 1, max_depth)
						end
					end
				end
			end)
		end

		if next(method_out) then
			out.__members__ = method_out
		end

		return out
	end

	-- ----------------------------------------------------------------
	-- userdata → metatable walking (from console.lua userdata introspection)
	-- ----------------------------------------------------------------
	if t == "userdata" then
		local ok_s, ustr = pcall(tostring, val)
		local out = { __name__ = ok_s and ustr or "<userdata>", __type__ = "userdata" }
		local ud_data = {}

		-- Walk metatable chain
		local ok_mt, mt = pcall(getmetatable, val)
		if ok_mt and mt and type(mt) == "table" then
			local mt_chain = mt
			local mt_depth = 0
			while mt_chain and type(mt_chain) == "table" and mt_depth < 5 do
				pcall(function()
					for k, v in pairs(mt_chain) do
						local ks = tostring(k)
						-- .get table contains properties (console.lua pattern)
						if ks == ".get" and type(v) == "table" then
							for get_k, get_v in pairs(v) do
								ud_data[tostring(get_k)] = type(get_v) == "function" and "property(function)"
									or _normalize(get_v, seen, depth + 1, max_depth)
							end
						elseif not ks:match("^__") and not ks:match("^%.") then
							if not ud_data[ks] then
								ud_data[ks] = type(v) == "function" and "function"
									or _normalize(v, seen, depth + 1, max_depth)
							end
						end
					end
				end)
				local ok_next_mt, next_mt = pcall(getmetatable, mt_chain)
				if ok_next_mt and type(next_mt) == "table" and next_mt ~= mt_chain then
					mt_chain = next_mt
				else
					mt_chain = nil
				end
				mt_depth = mt_depth + 1
			end
		end

		if next(ud_data) then
			out.__members__ = ud_data
		end
		return out
	end

	-- ----------------------------------------------------------------
	-- plain table → recurse normally
	-- ----------------------------------------------------------------
	if t == "table" then
		local out = {}
		for k, v in pairs(val) do
			out[k] = _normalize(v, seen, depth + 1, max_depth)
		end
		return out
	end

	-- Fallback
	local ok_s, s = pcall(tostring, val)
	return ok_s and s or ("<" .. t .. ">")
end

-- ============================================================
-- Type-aware pretty-printer
-- Reads __type__ markers from _normalize to render:
--   dict   → dict{key: val, key: val}
--   list   → [val, val, val]
--   tuple  → (val, val, val)
--   instance → Instance<ClassName>  (with optional expanded body)
--   class    → class<ClassName>     (with optional expanded body)
--   table  → {key = val, ...}      (plain Lua tables)
-- ============================================================
local function _pretty(v, indent_str, depth, max_depth)
	indent_str = indent_str or "  "
	depth = depth or 0
	max_depth = max_depth or 12

	-- nil
	if v == nil then
		return "nil"
	end

	local tv = type(v)

	-- primitives
	if tv == "number" or tv == "boolean" then
		return tostring(v)
	end
	if tv == "string" then
		-- Check if it already looks like a formatted representation (starts with special chars)
		-- to avoid double-quoting things like "function<...>" or "*REF:...*"
		if
			v:match("^function<")
			or v:match("^%*REF")
			or v:match("^<")
			or v == "function"
			or v == "property(function)"
		then
			return v
		end
		return string.format("%q", v)
	end

	-- non-table → tostring
	if tv ~= "table" then
		local ok_s, s = pcall(tostring, v)
		return ok_s and s or ("<" .. tv .. ">")
	end

	-- depth guard
	if depth > max_depth then
		return "{...}"
	end

	local pad = string.rep(indent_str, depth + 1)
	local pad_close = string.rep(indent_str, depth)

	local marker = v.__type__

	-- -------------------------------------------------------
	-- Instance / class with full introspection body
	-- These have __name__, __type__ = "instance"|"class",
	-- and optionally __properties__, __slots__, __members__
	-- -------------------------------------------------------
	if marker == "instance" or marker == "class" then
		local label = (marker == "instance") and "Instance" or "class"
		local name = v.__name__ or tostring(v)

		-- Check if there are any body sections
		local has_body = v.__properties__ or v.__slots__ or v.__members__
		if not has_body then
			return label .. "<" .. name .. ">"
		end

		local parts = {}
		parts[#parts + 1] = label .. "<" .. name .. "> {"

		-- __properties__
		if v.__properties__ and type(v.__properties__) == "table" and next(v.__properties__) then
			parts[#parts + 1] = pad .. "__properties__:"
			for pk, pv in pairs(v.__properties__) do
				parts[#parts + 1] = pad
					.. indent_str
					.. tostring(pk)
					.. ": "
					.. _pretty(pv, indent_str, depth + 2, max_depth)
			end
		end

		-- __slots__
		if v.__slots__ and type(v.__slots__) == "table" and next(v.__slots__) then
			parts[#parts + 1] = pad .. "__slots__:"
			for sk, sv in pairs(v.__slots__) do
				parts[#parts + 1] = pad
					.. indent_str
					.. tostring(sk)
					.. ": "
					.. _pretty(sv, indent_str, depth + 2, max_depth)
			end
		end

		-- __members__
		if v.__members__ and type(v.__members__) == "table" and next(v.__members__) then
			parts[#parts + 1] = pad .. "__members__:"
			for mk, mv in pairs(v.__members__) do
				parts[#parts + 1] = pad
					.. indent_str
					.. tostring(mk)
					.. ": "
					.. _pretty(mv, indent_str, depth + 2, max_depth)
			end
		end

		parts[#parts + 1] = pad_close .. "}"
		return table.concat(parts, "\n")
	end

	-- -------------------------------------------------------
	-- Instance/class with simple __value__ (e.g. Vector3)
	-- __type__ is the class name, __value__ is the data
	-- -------------------------------------------------------
	if marker and v.__value__ ~= nil and not v.__name__ then
		return "Instance<" .. tostring(marker) .. ">(" .. _pretty(v.__value__, indent_str, depth + 1, max_depth) .. ")"
	end

	-- -------------------------------------------------------
	-- dict → dict{key: val, key: val}
	-- -------------------------------------------------------
	if marker == "dict" then
		local items = {}
		for k, dv in pairs(v) do
			if k ~= "__type__" then
				items[#items + 1] = pad .. tostring(k) .. ": " .. _pretty(dv, indent_str, depth + 1, max_depth)
			end
		end
		if #items == 0 then
			return "dict{}"
		end
		return "dict{\n" .. table.concat(items, ",\n") .. "\n" .. pad_close .. "}"
	end

	-- -------------------------------------------------------
	-- list → [val, val, val]
	-- -------------------------------------------------------
	if marker == "list" then
		local items = {}
		for i = 1, #v do
			items[#items + 1] = _pretty(v[i], indent_str, depth + 1, max_depth)
		end
		if #items == 0 then
			return "[]"
		end
		-- Short lists inline, long lists multiline
		local inline = "[" .. table.concat(items, ", ") .. "]"
		if #inline <= 80 then
			return inline
		end
		local ml_items = {}
		for _, item in ipairs(items) do
			ml_items[#ml_items + 1] = pad .. item
		end
		return "[\n" .. table.concat(ml_items, ",\n") .. "\n" .. pad_close .. "]"
	end

	-- -------------------------------------------------------
	-- tuple → (val, val, val)
	-- -------------------------------------------------------
	if marker == "tuple" then
		local items = {}
		for i = 1, #v do
			items[#items + 1] = _pretty(v[i], indent_str, depth + 1, max_depth)
		end
		if #items == 0 then
			return "()"
		end
		local inline = "(" .. table.concat(items, ", ") .. ")"
		if #inline <= 80 then
			return inline
		end
		local ml_items = {}
		for _, item in ipairs(items) do
			ml_items[#ml_items + 1] = pad .. item
		end
		return "(\n" .. table.concat(ml_items, ",\n") .. "\n" .. pad_close .. ")"
	end

	-- -------------------------------------------------------
	-- userdata with introspection body
	-- -------------------------------------------------------
	if marker == "userdata" then
		local name = v.__name__ or "?"
		local has_body = v.__members__
		if not has_body then
			return "userdata<" .. name .. ">"
		end
		local parts = {}
		parts[#parts + 1] = "userdata<" .. name .. "> {"
		if v.__members__ and type(v.__members__) == "table" and next(v.__members__) then
			for mk, mv in pairs(v.__members__) do
				parts[#parts + 1] = pad .. tostring(mk) .. ": " .. _pretty(mv, indent_str, depth + 1, max_depth)
			end
		end
		parts[#parts + 1] = pad_close .. "}"
		return table.concat(parts, "\n")
	end

	-- -------------------------------------------------------
	-- plain table → {key = val, ...}
	-- -------------------------------------------------------
	-- Check if it's an array-like table (consecutive integer keys)
	local is_array = true
	local max_i = 0
	local count = 0
	for k, _ in pairs(v) do
		count = count + 1
		if type(k) == "number" and k == math.floor(k) and k >= 1 then
			if k > max_i then
				max_i = k
			end
		else
			is_array = false
		end
	end
	-- Verify no gaps
	if is_array and max_i ~= count then
		is_array = false
	end

	if count == 0 then
		return "{}"
	end

	if is_array then
		local items = {}
		for i = 1, max_i do
			items[#items + 1] = _pretty(v[i], indent_str, depth + 1, max_depth)
		end
		local inline = "{ " .. table.concat(items, ", ") .. " }"
		if #inline <= 80 then
			return inline
		end
		local ml_items = {}
		for _, item in ipairs(items) do
			ml_items[#ml_items + 1] = pad .. item
		end
		return "{\n" .. table.concat(ml_items, ",\n") .. "\n" .. pad_close .. "}"
	else
		local items = {}
		for k, tv2 in pairs(v) do
			local key_str
			if type(k) == "string" and k:match("^[%a_][%w_]*$") then
				key_str = k
			else
				key_str = "[" .. _pretty(k, indent_str, depth + 1, max_depth) .. "]"
			end
			items[#items + 1] = pad .. key_str .. " = " .. _pretty(tv2, indent_str, depth + 1, max_depth)
		end
		return "{\n" .. table.concat(items, ",\n") .. "\n" .. pad_close .. "}"
	end
end

Utils.dump_value = function(val, options)
	options = options or {}
	local max_depth = options.max_depth or 8

	-- Step 1: pre-normalize game types into plain Lua tables
	local ok_norm, normalized = pcall(_normalize, val, nil, 0, max_depth)
	if not ok_norm then
		-- Normalization failed entirely, fall back to raw inspect
		local ok_raw, rs = pcall(function()
			return inspect(val, options)
		end)
		if not ok_raw then
			return "<dump_value error: " .. tostring(rs) .. "> raw: " .. safe_tostring(val)
		end
		return rs
	end

	-- Step 2: type-aware pretty-print
	local indent = options.indent or "  "
	local ok_pp, result = pcall(_pretty, normalized, indent, 0, options.depth or 12)
	if not ok_pp then
		-- Fallback to inspect if pretty-printer fails
		local ok_insp, insp_result = pcall(function()
			return inspect(normalized, { depth = options.depth or math.huge, pretty = false })
		end)
		if not ok_insp then
			return "<dump_value error: " .. tostring(result) .. "> raw: " .. safe_tostring(val)
		end
		return insp_result
	end

	return result
end

Utils.init_dict = function(tbl)
	local CustomMapType = require("common.classutils").CustomMapType
	local data = CustomMapType(tbl):to_valid_dict()
	return data
end

Utils.init_list = function(tbl)
	local CustomListType = require("common.classutils").CustomListType
	local data = CustomListType(tbl)
	return data
end

Utils.get_action = function(name)
	if not Utils._actions then
		Utils._actions = {}
	end
	if not Utils._actions[name] then
		local path = _ROOT .. "\\actions\\" .. name .. ".lua"
		Utils._actions[name] = Utils.safe_dofile(path, name:gsub("^%l", string.upper))
	end
	return Utils._actions[name]
end

return Utils
