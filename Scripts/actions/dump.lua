--[[
    Dump - Module Dumping Actions

    Provides:
    - dump_all: Dump all loaded modules
    - dump_module: Dump a single module
    - dump_gm: Dump GM menu
    - dump_booleans: Find all boolean variables
    - dump_buffs_csv: Dump all live buffs to CSV with locale text

    Output: C:\temp\Where Winds Meet\LuaDebugging\

    Prerequisites: Bootstrap must be loaded first
]]

local ActionBase = _G.Reg.lib("ActionBase")

local Dump = ActionBase:extend("actions.dump")

function Dump:define_state()
	return {
		persistent = {},
		transient = { _core = nil, _is_running = false },
	}
end

function Dump:define_hooks()
	return {}
end

-- Lazy load core module
function Dump:_get_core()
	if not self.state._core then
		local Constants = _G.Reg.lib("Constants")
		local lib_root = Constants and Constants.LIB_ROOT or "C:\\temp\\Where Winds Meet\\Scripts\\lib\\"
		
		if not lib_root then
			self:log("ERROR: Constants.LIB_ROOT is nil!")
			return nil
		end

		local path = lib_root .. "dump_core.lua"
		self:log("Loading core from: " .. path)

		local ok, result = pcall(dofile, path)

		if not ok then
			self:log("ERROR: pcall failed: " .. tostring(result))
			return nil
		end

		self.state._core = result
		if not self.state._core then
			self:log("ERROR: Failed to load DumpCore!")
		else
			self:log("DumpCore loaded successfully")
		end
	end
	return self.state._core
end

-- Get output directory (for display)
function Dump:get_output_dir()
	local Constants = _G.Reg.lib("Constants")
	return Constants and Constants.LUA_DEBUGGING_ROOT or "C:\\temp\\Where Winds Meet\\LuaDebugging"
end

-- ============================================================
-- PUBLIC API
-- ============================================================

-- Dump all loaded modules
function Dump:dump_all(options)
	if self.state._is_running then
		self:log("Already running")
		return false, "Already running"
	end

	self.state._is_running = true
	self:log("Starting dump_all to: " .. self:get_output_dir())

	local core = self:_get_core()
	if not core or not core.dump_all_modules then
		self.state._is_running = false
		self:log("ERROR: DumpCore not loaded or missing dump_all_modules")
		return false, "DumpCore not loaded"
	end

	options = options or {}
	local dump_self = self
	options.write_debug = function(msg)
		dump_self:log(msg)
	end

	local ok, count_or_err, skipped = pcall(core.dump_all_modules, options)

	self.state._is_running = false

	if not ok then
		self:log("ERROR: " .. tostring(count_or_err))
		return false, tostring(count_or_err)
	end

	local output_dir = self:get_output_dir()
	self:log(string.format("Complete! %d dumped, %d skipped", count_or_err or 0, skipped or 0))
	self:log("Output folder: " .. output_dir)

	return true, output_dir
end

-- Dump a single module
function Dump:dump_module(module_path, options)
	if not module_path or module_path == "" then
		self:log("ERROR: module_path is required")
		return nil, "module_path is required"
	end

	local start_time = os.clock()
	options = options or {}
	local was_loaded = package.loaded[module_path] ~= nil
	local mod_data = nil

	self:log("[DumpModule] ==========================================")
	self:log("[DumpModule] START: " .. module_path)

	if was_loaded then
		mod_data = package.loaded[module_path]
		self:log("[DumpModule] Source: package.loaded (cached)")
	else
		self:log("[DumpModule] Source: importing via safe_import...")
		local import_start = os.clock()
		local imported, import_err = portable.safe_import(module_path)
		local import_time = os.clock() - import_start
		self:log(string.format("[DumpModule] Import took %.2fs", import_time))

		if imported then
			mod_data = imported
			self:log("[DumpModule] Import succeeded")
		else
			self:log("[DumpModule] SKIP: Import failed - " .. tostring(import_err))
			return nil, "Failed to import: " .. module_path
		end
	end

	self:log("[DumpModule] Module type: " .. type(mod_data))

	local key_count = 0
	local count_start = os.clock()
	pcall(function()
		for _ in pairs(mod_data) do
			key_count = key_count + 1
		end
	end)
	local count_time = os.clock() - count_start
	self:log(string.format("[DumpModule] Key count: %d (scan took %.2fs)", key_count, count_time))

	local core = self:_get_core()
	if not core or not core.dump_module then
		self:log("ERROR: DumpCore not loaded")
		return nil, "DumpCore not loaded"
	end

	local dump_self = self
	options.write_debug = options.verbose and function(msg)
		dump_self:log(msg)
	end or function() end
	options.module_data = mod_data

	self:log("[DumpModule] Calling core.dump_module...")
	local dump_start = os.clock()
	local ok, filepath_or_err, err = pcall(core.dump_module, module_path, options)
	local dump_time = os.clock() - dump_start
	self:log(string.format("[DumpModule] core.dump_module took %.2fs", dump_time))

	if not was_loaded and options.unload_after ~= false then
		package.loaded[module_path] = nil
	end

	local total_time = os.clock() - start_time

	if not ok then
		self:log("[DumpModule] ERROR: " .. tostring(filepath_or_err))
		self:log(string.format("[DumpModule] FAILED after %.2fs", total_time))
		self:log("[DumpModule] ==========================================")
		return nil, tostring(filepath_or_err)
	end

	if filepath_or_err then
		self:log(string.format("[DumpModule] COMPLETE: %.2fs total", total_time))
		self:log("[DumpModule] ==========================================")
		return filepath_or_err, nil
	else
		self:log("[DumpModule] ERROR: " .. tostring(err or "Unknown"))
		self:log(string.format("[DumpModule] FAILED after %.2fs", total_time))
		self:log("[DumpModule] ==========================================")
		return nil, err or "Unknown error"
	end
end

-- Dump GM menu
function Dump:dump_gm(options)
	self:log("Dumping GM menu...")

	local core = self:_get_core()
	if not core or not core.dump_gm then
		self:log("ERROR: DumpCore not loaded")
		return nil, "DumpCore not loaded"
	end

	options = options or {}
	local dump_self = self
	options.write_debug = function(msg)
		dump_self:log(msg)
	end

	local ok, filepath_or_err, err = pcall(core.dump_gm, options)

	if not ok then
		self:log("ERROR: " .. tostring(filepath_or_err))
		return nil, tostring(filepath_or_err)
	end

	if filepath_or_err then
		self:log("SUCCESS! Saved to: " .. filepath_or_err)
		return filepath_or_err, nil
	else
		self:log("ERROR: " .. tostring(err or "Unknown error"))
		return nil, err or "Unknown error"
	end
end

-- Dump all boolean variables
function Dump:dump_booleans(options)
	self:log("Scanning for booleans...")

	local core = self:_get_core()
	if not core or not core.dump_booleans then
		self:log("ERROR: DumpCore not loaded")
		return nil, "DumpCore not loaded"
	end

	options = options or {}
	local dump_self = self
	options.write_debug = function(msg)
		dump_self:log(msg)
	end

	local ok, vars_or_err, err = pcall(core.dump_booleans, options)

	if not ok then
		self:log("ERROR: " .. tostring(vars_or_err))
		return nil, tostring(vars_or_err)
	end

	if vars_or_err then
		local output_path = self:get_output_dir() .. "\\booleans_dump.lua"
		self:log("SUCCESS! Found " .. #vars_or_err .. " booleans")
		self:log("Saved to: " .. output_path)
		return vars_or_err, nil
	else
		self:log("ERROR: " .. tostring(err or "Unknown error"))
		return nil, err or "Unknown error"
	end
end

-- Dump all modules matching a path prefix
function Dump:dump_by_prefix(path_prefix, options)
	if not path_prefix or path_prefix == "" then
		self:log("ERROR: path_prefix is required")
		return 0, 0, "path_prefix is required"
	end

	options = options or {}

	local modules = {}
	for name, mod in pairs(package.loaded) do
		if type(name) == "string" and mod ~= nil then
			if name:sub(1, #path_prefix) == path_prefix then
				modules[#modules + 1] = name
			end
		end
	end

	table.sort(modules)
	local total = #modules
	self:log(string.format("[DumpByPrefix] Found %d modules matching '%s'", total, path_prefix))

	local count = 0
	local errors = 0

	for i, name in ipairs(modules) do
		self:log(string.format("[DumpByPrefix] [%d/%d] %s", i, total, name))

		local ok, err = self:dump_module(name, {
			format = options.format,
			depth = options.depth,
			include_source = options.include_source,
			unload_after = true,
		})

		if ok then
			count = count + 1
		else
			errors = errors + 1
		end
	end

	local output_dir = self:get_output_dir()
	self:log(string.format("[DumpByPrefix] Complete: %d dumped, %d errors", count, errors))
	self:log("[DumpByPrefix] Output: " .. output_dir)

	return count, errors
end

-- Check if running
-- ============================================================
-- ASYNC DUMP API - Non-blocking module dumping
-- ============================================================

--[[
    Start async dump of all modules (non-blocking)

    @param options table:
        - format: string - "json" (default) or "readable"
        - batch_size: number - Modules per tick (default: 3)
        - delay_ms: number - Delay between batches in ms (default: 50)
        - on_progress: function(current, total, name) - Progress callback
        - on_complete: function(count, errors) - Completion callback

    @return boolean - true if started, false if already running
]]
function Dump:dump_all_async(options)
	if self.state._is_running then
		self:log("[AsyncDump] Sync dump already running")
		return false, "Sync dump already running"
	end

	local core = self:_get_core()
	if not core or not core.dump_all_modules_async then
		self:log("[AsyncDump] ERROR: DumpCore.dump_all_modules_async not available")
		return false, "Async dump not available"
	end

	self:log("[AsyncDump] Starting async dump to: " .. self:get_output_dir())

	options = options or {}
	local dump_self = self
	options.write_debug = function(msg)
		dump_self:log(msg)
	end
	options.format = options.format or "json"

	local user_on_progress = options.on_progress
	local user_on_complete = options.on_complete

	options.on_progress = function(current, total, name)
		if user_on_progress then
			pcall(user_on_progress, current, total, name)
		end
	end

	options.on_complete = function(count, errors)
		local output_dir = dump_self:get_output_dir()
		dump_self:log(string.format("[AsyncDump] FINISHED: %d dumped, %d errors", count, errors))
		dump_self:log("[AsyncDump] Output folder: " .. output_dir)

		if user_on_complete then
			pcall(user_on_complete, count, errors)
		end
	end

	return core.dump_all_modules_async(options)
end

--[[
    Stop/cancel running async dump

    @return boolean - true if cancelled, false if not running
]]
function Dump:stop_async_dump()
	local core = self:_get_core()
	if not core then
		return false
	end

	if core.cancel_async_dump then
		self:log("[AsyncDump] Requesting cancellation...")
		return core.cancel_async_dump()
	elseif core.stop_async_dump then
		return core.stop_async_dump()
	end

	return false
end

--[[
    Check if async dump is running

    @return boolean
]]
function Dump:is_async_running()
	local core = self:_get_core()
	if not core or not core.is_async_dump_running then
		return false
	end
	return core.is_async_dump_running()
end

--[[
    Get async dump progress

    @return table|nil - { running, current, total, count, errors, elapsed }
]]
function Dump:get_async_progress()
	local core = self:_get_core()
	if not core or not core.get_async_dump_progress then
		return nil
	end
	return core.get_async_dump_progress()
end

function Dump:is_running()
	return self.state._is_running
end

-- ============================================================
-- BYTECODE DUMP ALL API - Dump all module loaders as raw .luac
-- ============================================================

function Dump:dump_all_bytecodes_async(options)
	local core = self:_get_core()
	if not core or not core.dump_all_bytecodes_async then
		self:log("[BytecodeDumpAll] ERROR: DumpCore.dump_all_bytecodes_async not available")
		return false, "Bytecode dump not available"
	end

	self:log("[BytecodeDumpAll] Starting async bytecode dump to: " .. self:get_output_dir())

	options = options or {}
	local dump_self = self
	options.write_debug = function(msg)
		dump_self:log(msg)
	end

	local user_on_progress = options.on_progress
	local user_on_complete = options.on_complete

	options.on_progress = function(current, total, name)
		if user_on_progress then
			pcall(user_on_progress, current, total, name)
		end
	end

	options.on_complete = function(count, errors)
		local output_dir = dump_self:get_output_dir()
		dump_self:log(string.format("[BytecodeDumpAll] FINISHED: %d dumped, %d errors", count, errors))
		dump_self:log("[BytecodeDumpAll] Output folder: " .. output_dir)

		if user_on_complete then
			pcall(user_on_complete, count, errors)
		end
	end

	return core.dump_all_bytecodes_async(options)
end

function Dump:stop_bytecode_dump()
	local core = self:_get_core()
	if not core then return false end

	if core.cancel_bytecode_dump then
		self:log("[BytecodeDumpAll] Requesting cancellation...")
		return core.cancel_bytecode_dump()
	elseif core.stop_bytecode_dump then
		return core.stop_bytecode_dump()
	end

	return false
end

function Dump:is_bytecode_dump_running()
	local core = self:_get_core()
	if not core or not core.is_bytecode_dump_running then
		return false
	end
	return core.is_bytecode_dump_running()
end

function Dump:get_core()
	return self:_get_core()
end

-- ============================================================
-- DIROBJECT DATA DUMP API
-- ============================================================

-- Helper: Write data to JSON file with pretty formatting
-- Returns: success (bool), error_message (string or nil)
local function _write_json_file(data, filename, rapidjson)
	local json_ok, json_str =
		pcall(
		function()
			return rapidjson.encode(data, {pretty = true})
		end
	)

	if not json_ok or not json_str then
		return false, "Failed to encode JSON: " .. tostring(json_str)
	end

	local file = io.open(filename, "w")
	if not file then
		return false, "Failed to open file for writing: " .. filename
	end

	file:write(json_str)
	file:close()
	return true, nil
end

function Dump:_setup_output_dir(dir_path)
	local ok = os.execute('mkdir "' .. dir_path .. '" 2>nul')
	if not ok then
		-- Directory might already exist, check by trying to open a file
		local test = io.open(dir_path .. "\\.__test", "w")
		if test then
			test:close()
			os.remove(dir_path .. "\\.__test")
			return true, nil
		end
		return false, "Failed to create directory: " .. dir_path
	end
	return true, nil
end

local BUFF_TEXT_FIELD_HINTS = {
	["buff_name"] = true,
	["buff_detail"] = true,
	["talk_add_word"] = true,
}

local BUFF_TEXT_FIELD_EXCLUDES = {
	"icon",
	"anim",
	"audio",
	"shader",
	"effect",
	"sameadd",
	"model",
	"path",
	"tag",
}

local function _sort_mixed_values(a, b)
	local na = tonumber(a)
	local nb = tonumber(b)
	if na and nb then
		return na < nb
	end
	return tostring(a) < tostring(b)
end

local function _sort_sequence(seq)
	local ok =
		pcall(
		function()
			if seq.sort then
				seq:sort(_sort_mixed_values)
			else
				table.sort(seq, _sort_mixed_values)
			end
		end
	)
	if not ok and type(seq) == "table" then
		table.sort(seq, _sort_mixed_values)
	end
	return seq
end

local function _normalize_export_value(value, depth, seen)
	depth = depth or 0
	seen = seen or {}

	if depth > 12 then
		return tostring(value)
	end

	local value_type = type(value)
	if nil == value or "number" == value_type or "string" == value_type or "boolean" == value_type then
		return value
	end

	if "instance" == value_type or "userdata" == value_type then
		local ok_dict, as_dict =
			pcall(
			function()
				if value.todict then
					return value:todict()
				end
			end
		)
		if ok_dict and as_dict ~= nil and as_dict ~= value then
			return _normalize_export_value(as_dict, depth + 1, seen)
		end

		local ok_list, as_list =
			pcall(
			function()
				if value.tolist then
					return value:tolist()
				end
			end
		)
		if ok_list and as_list ~= nil and as_list ~= value then
			return _normalize_export_value(as_list, depth + 1, seen)
		end

		local ok_dict2, dict2 =
			pcall(
			function()
				if value.toDict then
					return value:toDict()
				end
			end
		)
		if ok_dict2 and dict2 ~= nil and dict2 ~= value then
			return _normalize_export_value(dict2, depth + 1, seen)
		end

		return tostring(value)
	end

	if "list" == value_type then
		local ok_list, as_list =
			pcall(
			function()
				if value.tolist then
					return value:tolist()
				end
			end
		)
		if ok_list and as_list ~= nil and as_list ~= value then
			return _normalize_export_value(as_list, depth + 1, seen)
		end
	end

	if "list" == value_type or "dict" == value_type or "table" == value_type then
		if seen[value] then
			return tostring(value)
		end
		seen[value] = true

		local normalized = {}
		local key_count = 0
		local numeric_only = true
		local max_index = 0
		local iter_ok, iter, state, var = pcall(pairs, value)

		if not iter_ok then
			seen[value] = nil
			return tostring(value)
		end

		for key, item in iter, state, var do
			key_count = key_count + 1
			normalized[key] = _normalize_export_value(item, depth + 1, seen)
			if "number" == type(key) and key > 0 and math.floor(key) == key then
				if key > max_index then
					max_index = key
				end
			else
				numeric_only = false
			end
		end

		seen[value] = nil

		if numeric_only and max_index > 0 and max_index == key_count then
			local arr = {}
			for i = 1, max_index do
				arr[i] = normalized[i]
			end
			return arr
		end

		return normalized
	end

	return tostring(value)
end

local function _row_to_export_dict(row)
	if nil == row then
		return {}
	end

	local ok_dict, as_dict =
		pcall(
		function()
			if row.todict then
				return row:todict()
			end
		end
	)
	if ok_dict and as_dict ~= nil then
		return _normalize_export_value(as_dict)
	end

	local ok_dict2, dict2 =
		pcall(
		function()
			if row.toDict then
				return row:toDict()
			end
		end
	)
	if ok_dict2 and dict2 ~= nil then
		return _normalize_export_value(dict2)
	end

	local ok_keys, keys =
		pcall(
		function()
			if row.keys then
				return row:keys()
			end
		end
	)
	if ok_keys and keys then
		local dict_data = {}
		for i = 1, #keys do
			local key = keys[i]
			local ok_value, value =
				pcall(
				function()
					return row:get(key)
				end
			)
			if ok_value then
				dict_data[key] = _normalize_export_value(value)
			end
		end
		return dict_data
	end

	return _normalize_export_value(row)
end

local function _should_translate_buff_field(key, value)
	if "string" ~= type(key) then
		return false
	end

	if BUFF_TEXT_FIELD_HINTS[key] then
		return true
	end

	if "number" ~= type(value) then
		return false
	end

	local lowered = key:lower()
	for _, token in ipairs(BUFF_TEXT_FIELD_EXCLUDES) do
		if lowered:find(token, 1, true) then
			return false
		end
	end

	return lowered:find("_name", 1, true) ~= nil or lowered:find("_detail", 1, true) ~= nil
		or lowered:find("_desc", 1, true) ~= nil
		or lowered:find("_text", 1, true) ~= nil
		or lowered:find("_word", 1, true) ~= nil
		or lowered:find("_title", 1, true) ~= nil
		or lowered:find("_content", 1, true) ~= nil
end

local function _resolve_locale_text(value)
	local ok, text =
		pcall(
		function()
			return G.locale_manager:get_locale_text_by_tid(value, tostring(value))
		end
	)
	if ok and text ~= nil then
		return text
	end
	return tostring(value)
end

local function _csv_escape(value)
	if nil == value then
		return '""'
	end
	local s = tostring(value):gsub('"', '""')
	return '"' .. s .. '"'
end

local function _serialize_csv_value(value, rapidjson)
	local normalized = _normalize_export_value(value)
	local normalized_type = type(normalized)

	if nil == normalized then
		return ""
	end

	if "table" == normalized_type or "list" == normalized_type or "dict" == normalized_type then
		if rapidjson and rapidjson.encode then
			local ok, encoded =
				pcall(
				function()
					return rapidjson.encode(normalized)
				end
			)
			if ok and encoded then
				return encoded
			end
		end
	end

	return tostring(normalized)
end

local function _open_csv_file(filename)
	local file = io.open(filename, "wb")
	if not file then
		return nil, "Failed to open file for writing: " .. filename
	end
	file:write("\239\187\191")
	return file, nil
end

local function _build_csv_columns(rows)
	local base_keys = {}
	local text_columns = {}
	local base_lookup = {}
	local text_lookup = {}
	local preferred = {
		"buff_id",
		"buff_name",
		"buff_detail",
		"talk_add_word",
	}
	local preferred_lookup = {}

	for _, key in ipairs(preferred) do
		preferred_lookup[key] = true
	end

	for _, row in ipairs(rows) do
		for key, _ in pairs(row) do
			if "string" == type(key) and key:sub(-5) == "_text" then
				if not text_lookup[key] then
					text_lookup[key] = true
					text_columns[#text_columns + 1] = key
				end
			else
				if not base_lookup[key] then
					base_lookup[key] = true
					base_keys[#base_keys + 1] = key
				end
			end
		end
	end

	_sort_sequence(base_keys)
	_sort_sequence(text_columns)

	local columns = {}
	for _, key in ipairs(preferred) do
		if base_lookup[key] then
			columns[#columns + 1] = key
			base_lookup[key] = nil
		end
		local text_key = key .. "_text"
		if text_lookup[text_key] then
			columns[#columns + 1] = text_key
			text_lookup[text_key] = nil
		end
	end

	for _, key in ipairs(base_keys) do
		if base_lookup[key] then
			columns[#columns + 1] = key
			base_lookup[key] = nil
			local text_key = tostring(key) .. "_text"
			if text_lookup[text_key] then
				columns[#columns + 1] = text_key
				text_lookup[text_key] = nil
			end
		end
	end

	for _, key in ipairs(text_columns) do
		if text_lookup[key] then
			local base_key = key:sub(1, -6)
			if not preferred_lookup[base_key] then
				columns[#columns + 1] = key
				text_lookup[key] = nil
			end
		end
	end

	return columns
end

local function _write_csv_rows(filepath, columns, rows, rapidjson)
	local file, err = _open_csv_file(filepath)
	if not file then
		return false, err
	end

	local ok, write_err =
		pcall(
		function()
			local header = {}
			for i = 1, #columns do
				header[i] = _csv_escape(columns[i])
			end
			file:write(table.concat(header, ","), "\r\n")

			for idx, row in ipairs(rows) do
				local line = {}
				for col_idx = 1, #columns do
					local column = columns[col_idx]
					line[col_idx] = _csv_escape(_serialize_csv_value(row[column], rapidjson))
				end
				file:write(table.concat(line, ","), "\r\n")

				if idx % 500 == 0 then
					file:flush()
				end
			end
		end
	)

	file:close()

	if not ok then
		return false, tostring(write_err)
	end

	return true, nil
end

local function _collect_sorted_buff_ids(buff_table)
	local ok_keys, keys =
		pcall(
		function()
			return buff_table:keys()
		end
	)
	if not ok_keys or not keys then
		return nil, "Failed to iterate G.datam.buff keys"
	end

	_sort_sequence(keys)
	local buff_ids = {}
	for i = 1, #keys do
		buff_ids[#buff_ids + 1] = keys[i]
	end
	return buff_ids, nil
end

local function _has_meaningful_value(value)
	if nil == value or false == value then
		return false
	end

	local value_type = type(value)
	if "number" == value_type then
		return 0 ~= value
	end
	if "string" == value_type then
		return "" ~= value
	end
	if "table" == value_type then
		return next(value) ~= nil
	end

	return true
end

local function _derive_buff_estimate_label(buff_estimate)
	if 1 == buff_estimate then
		return "buff"
	end
	if 2 == buff_estimate then
		return "debuff"
	end
	if nil == buff_estimate then
		return ""
	end
	return "estimate_" .. tostring(buff_estimate)
end

local function _derive_duration_label(duration)
	if nil == duration then
		return ""
	end
	if -1 == duration then
		return "infinite"
	end
	if 0 == duration then
		return "instant"
	end
	return tostring(duration)
end

local EFFECT_CATEGORY_ORDER = {
	["attack"] = 1,
	["defense"] = 2,
	["recovery"] = 3,
	["resource"] = 4,
	["control"] = 5,
	["mobility"] = 6,
	["utility"] = 7,
	["attribute"] = 8,
}

local STATUS_CATEGORY_ORDER = {
	["passive"] = 1,
	["active"] = 2,
	["control"] = 3,
	["immune"] = 4,
	["debuff"] = 5,
	["persistent"] = 6,
}

local BUFF_PASSIVE_CONSTS_FALLBACK = {
	["TRIGGER_EVENT"] = {
		[1] = "adjust_params_out",
		[2] = "adjust_calcpoint_hit_tg",
		[3] = "adjust_params_in",
		[4] = "adjust_behit",
		[5] = "adjust_pre_damage",
		[101] = "on_buff_add",
		[102] = "resource_accumulate",
		[103] = "attr",
		[104] = "parry",
		[105] = "hit_combo",
		[106] = "hit_multi_cnt",
		[107] = "inbattle_hp",
		[108] = "skill_class_end",
		[109] = "kill",
		[110] = "behit_calcpoint",
		[111] = "add_jingyuan",
		[112] = "invincible",
		[113] = "taunt",
		[114] = "immune_event",
		[115] = "immune_damage_sp",
		[116] = "get_shield",
		[117] = "hit_after_defence",
		[118] = "hp_add_buff",
		[119] = "immune_damage_sp2",
		[120] = "skill_class_start",
		[121] = "on_buff_remove",
		[122] = "on_tg_buff_add",
		[123] = "no_dmg_in_battle",
		[124] = "shield_break",
		[125] = "res_consume",
		[126] = "dead",
		[127] = "ex_jianqi",
		[128] = "change_battle_state",
		[129] = "hit_floating",
		[130] = "skill_switch",
		[131] = "behit_max",
		[132] = "sand_skiing_fish",
		[133] = "defence_success",
		[134] = "chiji_kill",
		[135] = "pro_dmg_accumulate",
		[136] = "overflow_heal_acc",
		[137] = "cause_pro_dmg",
		[138] = "jianqi_atk_first",
	},
	["EFFECT_EVENT_MAP"] = {
		[1] = "_effect_event_adj_dmg",
		[2] = "_effect_event_adj_heal",
		[3] = "_effect_event_steal_hp",
		[4] = "_effect_event_tg_get_buff",
		[5] = "_effect_event_no_consume_naili",
		[6] = "_effect_event_reduce_renxing",
		[7] = "_effect_event_adj_formula",
		[8] = "_effect_event_hurt_self",
		[9] = "_effect_event_adj_dmg_by_tg_hp",
		[10] = "_effect_event_adj_formula_by_tg_num",
		[11] = "_effect_event_ex_zq_dmg",
		[12] = "_effect_event_adj_resource",
		[13] = "_effect_event_get_kill_reward",
		[14] = "_effect_event_ex_dmg",
		[15] = "_effect_event_xinfa_wmg",
		[16] = "_effect_event_do_calcpoint",
		[17] = "_effect_event_zed_ult",
		[18] = "_effect_event_adj_dmg_by_hp",
		[19] = "_effect_event_reflect_dmg",
		[20] = "_effect_event_steal_hp_with_limit",
		[21] = "_effect_event_revert_consume_resource",
		[22] = "_effect_event_heal_by_consume_resource",
		[23] = "_effect_event_tg_remove_buff",
		[24] = "_effect_event_spec_judge",
		[25] = "_effect_event_adj_dmg_by_cmp_hp",
		[26] = "_effect_event_mod_impact_force_lv",
		[27] = "_effect_event_adj_dmg_by_tg_cnt",
		[28] = "_effect_event_overflow_heal_to_shield",
	},
	["EFFECT_NORMAL_MAP"] = {
		[101] = "_effect_trigger_add_buff",
		[102] = "_effect_trigger_add_hp",
		[103] = "_effect_trigger_add_resource",
		[104] = "_effect_trigger_add_random_buff",
		[105] = "_effect_trigger_revert_consume_resource",
		[106] = "_effect_trigger_get_buff",
		[107] = "_effect_trigger_get_buff_with_shield",
		[108] = "_effect_trigger_inherit_buff",
		[109] = "_effect_trigger_skill_cd",
		[110] = "_effect_trigger_remove_buff",
		[111] = "_effect_trigger_remove_self",
		[112] = "_effect_trigger_add_buff_multi",
		[113] = "_effect_trigger_dec_passive_cd",
		[114] = "_effect_trigger_get_buff_multi_charge",
		[115] = "_effect_trigger_add_buff_for_teammate",
		[116] = "_effect_trigger_parry_extra",
		[117] = "_effect_trigger_ex_jianqi_adj_dmg",
		[118] = "_effect_trigger_skill_class_cd",
		[119] = "_effect_trigger_remove_buff_to_ratio",
		[120] = "_effect_trigger_cur_kf_skill_class_cd",
		[121] = "_effect_trigger_add_passive_mark",
		[122] = "_effect_trigger_del_passive_mark",
		[123] = "_effect_trigger_hit_multi_add_buff",
		[124] = "_effect_trigger_inherit_buff_add",
		[125] = "_effect_trigger_add_hp_by_hppct",
	},
}

local _buff_passive_consts_loaded = false
local _buff_passive_consts = nil
local _formula_attr_name_cache = {}
local _passive_effect_descriptor_cache = {}

local function _append_unique_string(values, lookup, value)
	if not _has_meaningful_value(value) then
		return
	end

	local normalized = tostring(value)
	if "" == normalized or lookup[normalized] then
		return
	end

	lookup[normalized] = true
	values[#values + 1] = normalized
end

local function _sequence_values(seq)
	local values = {}
	if "table" ~= type(seq) then
		return values
	end

	local numeric_keys = {}
	for key, _ in pairs(seq) do
		if "number" == type(key) then
			numeric_keys[#numeric_keys + 1] = key
		end
	end

	table.sort(numeric_keys)
	for _, key in ipairs(numeric_keys) do
		values[#values + 1] = seq[key]
	end

	return values
end

local function _to_integer(value)
	local num = tonumber(value)
	if not num then
		return nil
	end

	if num >= 0 then
		return math.floor(num + 1.0e-7)
	end
	return math.ceil(num - 1.0e-7)
end

local function _sort_strings_with_order(values, order_lookup)
	table.sort(
		values,
		function(a, b)
			local a_order = order_lookup and order_lookup[a] or nil
			local b_order = order_lookup and order_lookup[b] or nil
			if nil ~= a_order or nil ~= b_order then
				a_order = a_order or 999
				b_order = b_order or 999
				if a_order ~= b_order then
					return a_order < b_order
				end
			end
			return tostring(a) < tostring(b)
		end
	)

	return values
end

local function _join_sorted_strings(values, order_lookup)
	if 0 == #values then
		return ""
	end

	_sort_strings_with_order(values, order_lookup)
	return table.concat(values, "; ")
end

local function _safe_map_get(map_obj, key)
	if nil == map_obj then
		return nil
	end

	local ok, value =
		pcall(
		function()
			if map_obj.get then
				return map_obj:get(key)
			end
			return map_obj[key]
		end
	)
	if ok then
		return value
	end
	return nil
end

local function _safe_map_get_with_fallback(primary_map, fallback_map, key)
	local value = _safe_map_get(primary_map, key)
	if nil ~= value then
		return value
	end
	return _safe_map_get(fallback_map, key)
end

local function _get_buff_passive_consts()
	if not _buff_passive_consts_loaded then
		_buff_passive_consts_loaded = true
		if Utils and Utils.safe_import then
			_buff_passive_consts = Utils.safe_import("hexm.common.consts.buff_passive_consts")
		end
		if not _buff_passive_consts then
			local ok_require, required =
				pcall(
				function()
					return require("hexm.common.consts.buff_passive_consts")
				end
			)
			if ok_require then
				_buff_passive_consts = required
			end
		end
		if not _buff_passive_consts then
			_buff_passive_consts = BUFF_PASSIVE_CONSTS_FALLBACK
		end
	end
	return _buff_passive_consts
end

local function _format_effect_source_label(func_name)
	local label = tostring(func_name or "")
	label = label:gsub("^_effect_event_", "event:")
	label = label:gsub("^_effect_trigger_", "trigger:")
	return label
end

local function _resolve_formula_attr_name(attr_ref)
	local cache_key = tostring(attr_ref)
	if nil ~= _formula_attr_name_cache[cache_key] then
		return _formula_attr_name_cache[cache_key]
	end

	local attr_name
	local attr_id = _to_integer(attr_ref)
	if attr_id and G and G.datam and G.datam.formula_base_attrs then
		local ok_sysd, sysd =
			pcall(
			function()
				return G.datam.formula_base_attrs:get(attr_id, {})
			end
		)
		if ok_sysd and sysd then
			local ok_name_en, name_en =
				pcall(
				function()
					if sysd.get then
						return sysd:get("prop_name_en")
					end
					return sysd.prop_name_en
				end
			)
			if ok_name_en and _has_meaningful_value(name_en) then
				attr_name = tostring(name_en)
			end

			if not _has_meaningful_value(attr_name) then
				local ok_name_cn, name_cn =
					pcall(
					function()
						if sysd.get then
							return sysd:get("prop_name_cn")
						end
						return sysd.prop_name_cn
					end
				)
				if ok_name_cn and _has_meaningful_value(name_cn) then
					attr_name = tostring(name_cn)
				end
			end
		end
	end

	if not _has_meaningful_value(attr_name) then
		attr_name = cache_key
	end

	_formula_attr_name_cache[cache_key] = attr_name
	return attr_name
end

local function _classify_attr_name(attr_name, categories, category_lookup)
	local upper_name = tostring(attr_name):upper()
	local matched = false
	local is_defensive_name =
		"HP" == upper_name
		or upper_name:find("HP_", 1, true)
		or upper_name:find("_HP", 1, true)
		or upper_name:find("DEF", 1, true)
		or upper_name:find("RESIST", 1, true)
		or upper_name:find("REDUCE", 1, true)
		or upper_name:find("SHIELD", 1, true)
		or upper_name:find("PARRY", 1, true)
		or upper_name:find("DODGE", 1, true)
		or upper_name:find("BLOCK", 1, true)
		or upper_name:find("RENXING", 1, true)
		or upper_name:find("IMMUNE", 1, true)

	local function add_category(category)
		_append_unique_string(categories, category_lookup, category)
		matched = true
	end

	if is_defensive_name then
		add_category("defense")
	end

	if
		(
			upper_name:find("ATK", 1, true)
			or upper_name:find("DMG", 1, true)
			or upper_name:find("DAMAGE", 1, true)
			or upper_name:find("CRIT", 1, true)
			or upper_name:find("PEN", 1, true)
			or upper_name:find("HIT", 1, true)
			or upper_name:find("WEAK", 1, true)
			or upper_name:find("FINAL", 1, true)
			or upper_name:find("HUMANPRO", 1, true)
		)
		and not is_defensive_name
	then
		add_category("attack")
	end

	if upper_name:find("HEAL", 1, true) or upper_name:find("RECOVER", 1, true) or upper_name:find("REGAIN", 1, true) then
		add_category("recovery")
	end

	if upper_name:find("RESOURCE", 1, true) or upper_name:find("NAILI", 1, true) or upper_name:find("JINGYUAN", 1, true)
		or upper_name:find("ZHENQI", 1, true)
		or upper_name:find("ENERGY", 1, true)
		or upper_name:find("MANA", 1, true)
	then
		add_category("resource")
	end

	if upper_name:find("SPD", 1, true) or upper_name:find("SPEED", 1, true) or upper_name:find("MOVE", 1, true) then
		add_category("mobility")
	end

	if upper_name:find("CD", 1, true) then
		add_category("utility")
	end

	if not matched then
		add_category("attribute")
	end
end

local function _classify_direct_key(key, categories, category_lookup)
	local lowered = key:lower()
	local matched = false

	local function add_category(category)
		_append_unique_string(categories, category_lookup, category)
		matched = true
	end

	if lowered:find("resource", 1, true) or lowered:find("naili", 1, true) or lowered:find("jingyuan", 1, true)
		or lowered:find("recover_speed", 1, true)
		or lowered:find("cost_change", 1, true)
	then
		add_category("resource")
	end

	if lowered:find("skill_cd", 1, true) or lowered:find("replace_skill", 1, true) or lowered:find("temp_skill", 1, true)
		or lowered:find("change_skill_charge", 1, true)
		or lowered:find("unlock_combo", 1, true)
		or lowered:find("replace_combo", 1, true)
		or lowered:find("change_bow_skill", 1, true)
		or lowered:find("disable_skill", 1, true)
		or lowered:find("forbid_switch_kongfu", 1, true)
		or lowered:find("temp_view", 1, true)
		or lowered:find("change_faction", 1, true)
		or lowered:find("change_face", 1, true)
		or lowered:find("run_al", 1, true)
		or lowered:find("talk_add_word", 1, true)
	then
		add_category("utility")
	end

	if lowered:find("spd", 1, true) or lowered:find("speed", 1, true) or lowered:find("joystick", 1, true)
		or lowered:find("ride", 1, true)
		or lowered:find("swim", 1, true)
	then
		add_category("mobility")
	end

	if lowered:find("calcpoint", 1, true) or lowered:find("adjust_dmg", 1, true) or lowered:find("enchant", 1, true)
		or lowered:find("fromer_dmg", 1, true)
		or lowered:find("replace_calcpoint", 1, true)
		or lowered:find("impact_force", 1, true)
	then
		add_category("attack")
	end

	if lowered:find("shield", 1, true) or lowered:find("immune_dmg", 1, true) or lowered:find("lock_hp", 1, true)
		or lowered:find("absorb", 1, true)
		or lowered:find("immune_dead", 1, true)
	then
		add_category("defense")
	end

	return matched
end

local function _collect_attribute_effects(row, categories, category_lookup, sources, source_lookup)
	local attribute_names = {}
	local attribute_lookup = {}
	local attr_refs = {}

	if "table" == type(row.buff_attribute_type) then
		attr_refs = _sequence_values(row.buff_attribute_type)
	else
		if _has_meaningful_value(row.buff_attribute_type) then
			attr_refs = { row.buff_attribute_type }
		end
	end

	for _, attr_ref in ipairs(attr_refs) do
		local attr_name = _resolve_formula_attr_name(attr_ref)
		_append_unique_string(attribute_names, attribute_lookup, attr_name)
		_append_unique_string(sources, source_lookup, "attr:" .. attr_name)
		_classify_attr_name(attr_name, categories, category_lookup)
	end

	if _has_meaningful_value(row.has_formula_attr) then
		_append_unique_string(categories, category_lookup, "attribute")
		_append_unique_string(sources, source_lookup, "field:has_formula_attr")
	end

	_sort_sequence(attribute_names)
	return attribute_names
end

local function _collect_immune_abilities(row)
	local abilities = {}

	for key, value in pairs(row) do
		if "string" == type(key) and key:find("immune_", 1, true) == 1 and _has_meaningful_value(value) then
			if true == value or 1 == value then
				abilities[#abilities + 1] = key
			else
				abilities[#abilities + 1] = string.format("%s=%s", key, tostring(value))
			end
		end
	end

	table.sort(abilities)
	return table.concat(abilities, "; ")
end

local function _build_flag_summary(row)
	local flags = {}
	local show_flag = row.buff_show_flag
	local specialshow_flag = row.buff_specialshow_flag
	local control_type = row.buff_control_type

	if nil ~= show_flag then
		flags[#flags + 1] = "show=" .. tostring(show_flag)
	end
	if nil ~= specialshow_flag then
		flags[#flags + 1] = "special=" .. tostring(specialshow_flag)
	end
	if nil ~= control_type and 0 ~= control_type then
		flags[#flags + 1] = "control=" .. tostring(control_type)
	end
	if _has_meaningful_value(row.is_client_display) then
		flags[#flags + 1] = "client_display=" .. tostring(row.is_client_display)
	end

	return table.concat(flags, "; ")
end

local function _collect_direct_effect_info(row)
	local categories = {}
	local category_lookup = {}
	local sources = {}
	local source_lookup = {}

	if _has_meaningful_value(row.life_regain) then
		_append_unique_string(categories, category_lookup, "recovery")
		_append_unique_string(sources, source_lookup, "field:life_regain")
	end

	if _has_meaningful_value(row.life_steal) then
		_append_unique_string(categories, category_lookup, "attack")
		_append_unique_string(categories, category_lookup, "recovery")
		_append_unique_string(sources, source_lookup, "field:life_steal")
	end

	if _has_meaningful_value(row.buff_shield_calc_id) then
		_append_unique_string(categories, category_lookup, "defense")
		_append_unique_string(sources, source_lookup, "field:buff_shield_calc_id")
	end

	if _has_meaningful_value(row.buff_shield_calc_hp) then
		_append_unique_string(categories, category_lookup, "defense")
		_append_unique_string(sources, source_lookup, "field:buff_shield_calc_hp")
	end

	if _has_meaningful_value(row.shield_end_recover) then
		_append_unique_string(categories, category_lookup, "defense")
		_append_unique_string(categories, category_lookup, "recovery")
		_append_unique_string(sources, source_lookup, "field:shield_end_recover")
	end

	if _has_meaningful_value(row.buff_control_type) and 0 ~= row.buff_control_type then
		_append_unique_string(categories, category_lookup, "control")
		_append_unique_string(sources, source_lookup, "field:buff_control_type")
	end

	for key, value in pairs(row) do
		if "string" == type(key) and _has_meaningful_value(value) then
			if key:find("immune_", 1, true) == 1 then
				_append_unique_string(categories, category_lookup, "defense")
				_append_unique_string(sources, source_lookup, "field:" .. key)
			end

			if _classify_direct_key(key, categories, category_lookup) then
				_append_unique_string(sources, source_lookup, "field:" .. key)
			end
		end
	end

	local attribute_names = _collect_attribute_effects(row, categories, category_lookup, sources, source_lookup)

	return {
		["categories"] = categories,
		["sources"] = sources,
		["attribute_names"] = attribute_names,
	}
end

local function _resolve_passive_ids(row, buff_id)
	local passive_ids = {}
	local lookup = {}
	local passive_values = {}
	local effect_list = row.passive_effect
	local resolved_buff_id = _to_integer(row.buff_id or buff_id)

	if "table" == type(effect_list) then
		passive_values = _sequence_values(effect_list)
	else
		if _has_meaningful_value(effect_list) then
			passive_values = { effect_list }
		end
	end

	for _, passive_ref in ipairs(passive_values) do
		local passive_index = _to_integer(passive_ref)
		if passive_index then
			local passive_id = passive_index
			if resolved_buff_id and passive_index < 10 then
				passive_id = resolved_buff_id * 10 + passive_index
			end
			_append_unique_string(passive_ids, lookup, tostring(passive_id))
		end
	end

	_sort_sequence(passive_ids)
	return passive_ids
end

local function _classify_passive_handler(
	func_name,
	params,
	categories,
	category_lookup,
	sources,
	source_lookup,
	attribute_names,
	attribute_lookup
)
	local lowered = tostring(func_name or ""):lower()
	local source_label = _format_effect_source_label(func_name)

	if "" ~= source_label then
		_append_unique_string(sources, source_lookup, "passive:" .. source_label)
	end

	if lowered:find("steal_hp", 1, true) then
		_append_unique_string(categories, category_lookup, "attack")
		_append_unique_string(categories, category_lookup, "recovery")
	end

	if lowered:find("adj_dmg", 1, true) or lowered:find("ex_dmg", 1, true) or lowered:find("do_calcpoint", 1, true)
		or lowered:find("mod_impact_force_lv", 1, true)
		or lowered:find("xinfa_wmg", 1, true)
	then
		_append_unique_string(categories, category_lookup, "attack")
	end

	if lowered:find("adj_heal", 1, true) or lowered:find("heal", 1, true) or lowered:find("add_hp", 1, true) then
		_append_unique_string(categories, category_lookup, "recovery")
	end

	if lowered:find("overflow_heal_to_shield", 1, true) then
		_append_unique_string(categories, category_lookup, "defense")
		_append_unique_string(categories, category_lookup, "recovery")
	end

	if lowered:find("shield", 1, true) or lowered:find("reflect_dmg", 1, true) or lowered:find("immune", 1, true) then
		_append_unique_string(categories, category_lookup, "defense")
	end

	if lowered:find("resource", 1, true) or lowered:find("consume_resource", 1, true) or lowered:find("naili", 1, true)
		or lowered:find("jingyuan", 1, true)
	then
		_append_unique_string(categories, category_lookup, "resource")
	end

	if lowered:find("reduce_renxing", 1, true) then
		_append_unique_string(categories, category_lookup, "control")
	end

	if lowered:find("add_buff", 1, true) or lowered:find("get_buff", 1, true) or lowered:find("remove_buff", 1, true)
		or lowered:find("skill_cd", 1, true)
		or lowered:find("passive_mark", 1, true)
		or lowered:find("spec_judge", 1, true)
	then
		_append_unique_string(categories, category_lookup, "utility")
	end

	if lowered:find("adj_formula", 1, true) then
		local attr_name = params[1] and _resolve_formula_attr_name(params[1]) or nil
		if _has_meaningful_value(attr_name) then
			_append_unique_string(attribute_names, attribute_lookup, attr_name)
			_append_unique_string(sources, source_lookup, "passive:attr:" .. tostring(attr_name))
			_classify_attr_name(attr_name, categories, category_lookup)
		else
			_append_unique_string(categories, category_lookup, "attribute")
		end
	end
end

local function _collect_passive_effect_entries(effect_list, effect_map, fallback_prefix, descriptor)
	for _, effect_entry in ipairs(_sequence_values(effect_list)) do
		if "table" == type(effect_entry) then
			local values = _sequence_values(effect_entry)
			local effect_id = _to_integer(values[1])
			if effect_id then
				local fallback_map =
					("effect_event_" == fallback_prefix and BUFF_PASSIVE_CONSTS_FALLBACK.EFFECT_EVENT_MAP)
					or ("effect_normal_" == fallback_prefix and BUFF_PASSIVE_CONSTS_FALLBACK.EFFECT_NORMAL_MAP)
					or nil
				local func_name =
					_safe_map_get_with_fallback(effect_map, fallback_map, effect_id) or (fallback_prefix .. tostring(effect_id))
				local params = {}
				for i = 2, #values do
					params[#params + 1] = values[i]
				end
				_classify_passive_handler(
					func_name,
					params,
					descriptor.categories,
					descriptor.category_lookup,
					descriptor.sources,
					descriptor.source_lookup,
					descriptor.attribute_names,
					descriptor.attribute_lookup
				)
			end
		end
	end
end

local function _describe_passive_effect(passive_id)
	local cache_key = tostring(passive_id)
	if _passive_effect_descriptor_cache[cache_key] then
		return _passive_effect_descriptor_cache[cache_key]
	end

	local descriptor = {
		["categories"] = {},
		["category_lookup"] = {},
		["sources"] = {},
		["source_lookup"] = {},
		["attribute_names"] = {},
		["attribute_lookup"] = {},
		["trigger_name"] = "",
	}

	if not (G and G.datam and G.datam.buff_passive_data) then
		_passive_effect_descriptor_cache[cache_key] = descriptor
		return descriptor
	end

	local ok_sysd, sysd =
		pcall(
		function()
			return G.datam.buff_passive_data:get(_to_integer(passive_id))
		end
	)
	if not ok_sysd or not sysd then
		_passive_effect_descriptor_cache[cache_key] = descriptor
		return descriptor
	end

	local passive_row = _row_to_export_dict(sysd)
	local passive_consts = _get_buff_passive_consts()
	local trigger_id = _to_integer(passive_row.trigger)
	descriptor.trigger_name =
		_safe_map_get_with_fallback(
			passive_consts and passive_consts.TRIGGER_EVENT,
			BUFF_PASSIVE_CONSTS_FALLBACK.TRIGGER_EVENT,
			trigger_id
		)
		or (trigger_id and ("trigger_" .. tostring(trigger_id)) or "")

	_collect_passive_effect_entries(
		passive_row.effect_event,
		passive_consts and passive_consts.EFFECT_EVENT_MAP,
		"effect_event_",
		descriptor
	)
	_collect_passive_effect_entries(
		passive_row.effect_normal,
		passive_consts and passive_consts.EFFECT_NORMAL_MAP,
		"effect_normal_",
		descriptor
	)

	if _has_meaningful_value(passive_row.effect_actionline) then
		_append_unique_string(descriptor.categories, descriptor.category_lookup, "utility")
		_append_unique_string(descriptor.sources, descriptor.source_lookup, "passive:actionline")
	end

	if _has_meaningful_value(passive_row.effect_snapshot) or _has_meaningful_value(passive_row.effect_dynamic_snapshot) then
		_append_unique_string(descriptor.categories, descriptor.category_lookup, "utility")
		_append_unique_string(descriptor.sources, descriptor.source_lookup, "passive:snapshot")
	end

	_passive_effect_descriptor_cache[cache_key] = descriptor
	return descriptor
end

local function _collect_passive_effect_info(row, buff_id)
	local passive_ids = _resolve_passive_ids(row, buff_id)
	local categories = {}
	local category_lookup = {}
	local sources = {}
	local source_lookup = {}
	local attribute_names = {}
	local attribute_lookup = {}
	local passive_triggers = {}
	local trigger_lookup = {}

	for _, passive_id in ipairs(passive_ids) do
		local descriptor = _describe_passive_effect(passive_id)

		_append_unique_string(passive_triggers, trigger_lookup, descriptor.trigger_name)

		for _, category in ipairs(descriptor.categories) do
			_append_unique_string(categories, category_lookup, category)
		end

		for _, source in ipairs(descriptor.sources) do
			_append_unique_string(sources, source_lookup, source)
		end

		for _, attr_name in ipairs(descriptor.attribute_names) do
			_append_unique_string(attribute_names, attribute_lookup, attr_name)
		end
	end

	return {
		["passive_ids"] = passive_ids,
		["passive_triggers"] = passive_triggers,
		["categories"] = categories,
		["sources"] = sources,
		["attribute_names"] = attribute_names,
	}
end

local function _collect_effect_summary(row, buff_id)
	local direct_info = _collect_direct_effect_info(row)
	local passive_info = _collect_passive_effect_info(row, buff_id)
	local categories = {}
	local category_lookup = {}
	local sources = {}
	local source_lookup = {}
	local attribute_names = {}
	local attribute_lookup = {}

	for _, category in ipairs(direct_info.categories) do
		_append_unique_string(categories, category_lookup, category)
	end
	for _, category in ipairs(passive_info.categories) do
		_append_unique_string(categories, category_lookup, category)
	end

	for _, source in ipairs(direct_info.sources) do
		_append_unique_string(sources, source_lookup, source)
	end
	for _, source in ipairs(passive_info.sources) do
		_append_unique_string(sources, source_lookup, source)
	end

	for _, attr_name in ipairs(direct_info.attribute_names) do
		_append_unique_string(attribute_names, attribute_lookup, attr_name)
	end
	for _, attr_name in ipairs(passive_info.attribute_names) do
		_append_unique_string(attribute_names, attribute_lookup, attr_name)
	end

	_sort_strings_with_order(categories, EFFECT_CATEGORY_ORDER)
	_sort_sequence(sources)
	_sort_sequence(attribute_names)
	_sort_sequence(passive_info.passive_ids)
	_sort_sequence(passive_info.passive_triggers)

	return {
		["primary"] = categories[1] or "",
		["categories"] = table.concat(categories, "; "),
		["sources"] = table.concat(sources, "; "),
		["attribute_names"] = table.concat(attribute_names, "; "),
		["passive_ids"] = table.concat(passive_info.passive_ids, "; "),
		["passive_triggers"] = table.concat(passive_info.passive_triggers, "; "),
	}
end

local function _derive_buff_category(row, immune_abilities)
	if _has_meaningful_value(row.passive_effect) then
		return "passive"
	end
	if 2 == row.buff_estimate then
		return "debuff"
	end
	if nil ~= row.buff_control_type and 0 ~= row.buff_control_type then
		return "control"
	end
	if "" ~= immune_abilities then
		return "immune"
	end
	if -1 == row.buff_maxtime then
		return "persistent"
	end
	return "active"
end

local function _build_buff_summary_row(raw_row, buff_id)
	local duration = raw_row.buff_maxtime
	local immune_abilities = _collect_immune_abilities(raw_row)
	local effect_info = _collect_effect_summary(raw_row, buff_id)

	return {
		["category"] = _derive_buff_category(raw_row, immune_abilities),
		["effect_primary"] = effect_info.primary,
		["effect_categories"] = effect_info.categories,
		["id"] = raw_row.buff_id or buff_id,
		["name"] = _has_meaningful_value(raw_row.buff_name) and _resolve_locale_text(raw_row.buff_name) or "",
		["details"] = _has_meaningful_value(raw_row.buff_detail) and _resolve_locale_text(raw_row.buff_detail) or "",
		["effect_sources"] = effect_info.sources,
		["attribute_effects"] = effect_info.attribute_names,
		["passive_ids"] = effect_info.passive_ids,
		["passive_triggers"] = effect_info.passive_triggers,
		["duration"] = duration,
		["duration_label"] = _derive_duration_label(duration),
		["type"] = raw_row.buff_type,
		["estimate"] = raw_row.buff_estimate,
		["estimate_label"] = _derive_buff_estimate_label(raw_row.buff_estimate),
		["group"] = raw_row.buff_group,
		["control_type"] = raw_row.buff_control_type,
		["flags"] = _build_flag_summary(raw_row),
		["immune_abilities"] = immune_abilities,
		["has_anti_need"] = raw_row.has_anti_need,
		["has_fake_need"] = raw_row.has_fake_need,
		["buff_tag"] = raw_row.buff_tag,
		["icon"] = raw_row.buff_icon,
	}
end

local function _sort_buff_summary_rows(rows)
	table.sort(rows, function(a, b)
		local a_effect = a.effect_primary or ""
		local b_effect = b.effect_primary or ""
		local a_effect_order = EFFECT_CATEGORY_ORDER[a_effect] or 999
		local b_effect_order = EFFECT_CATEGORY_ORDER[b_effect] or 999
		if a_effect_order ~= b_effect_order then
			return a_effect_order < b_effect_order
		end
		if a_effect ~= b_effect then
			return a_effect < b_effect
		end

		local a_cat = a.category or ""
		local b_cat = b.category or ""
		local a_order = STATUS_CATEGORY_ORDER[a_cat] or 999
		local b_order = STATUS_CATEGORY_ORDER[b_cat] or 999
		if a_order ~= b_order then
			return a_order < b_order
		end
		if a_cat ~= b_cat then
			return a_cat < b_cat
		end
		if (a.effect_categories or "") ~= (b.effect_categories or "") then
			return (a.effect_categories or "") < (b.effect_categories or "")
		end
		return _sort_mixed_values(a.id or 0, b.id or 0)
	end)
end

function Dump:dump_grey_table()
	_log("dump_grey_table: Starting dump process...")
	local rapidjson = Utils.safe_import("rapidjson")
	local dirObj = Utils.safe_import("hexm.common.data.dir_object")

	if not dirObj or not dirObj.DirObject or not dirObj.DirObject.GreyTableInfo then
		_log("[ERROR] dump_grey_table: Failed to get GreyTableInfo")
		return false, "GreyTableInfo not available"
	end

	local grey_table = dirObj.DirObject.GreyTableInfo:items()
	if not grey_table then
		_log("[ERROR] dump_grey_table: GreyTableInfo:items() returned nil")
		return false, "Failed to get grey_table items"
	end

	_log("Starting grey_table dump...")
	_log("Total entries: " .. tostring(#grey_table))

	local _ROOT = Constants.SCRIPTS_ROOT
	local output_dir = _ROOT .. "\\data\\DirObject\\GreyTableInfo"
	local ok, err = _setup_output_dir(output_dir)
	if not ok then
		_log("[ERROR] dump_grey_table: " .. tostring(err))
		return false, err
	end

	local success_count = 0
	local fail_count = 0
	_log("Type of grey_table: " .. type(grey_table))

	local total = #grey_table
	for i = 1, total do
		local entry = grey_table[i]

		if i <= 5 then
			_log(string.format("[DEBUG %d] Processing entry: %s (type: %s)", i, tostring(entry), type(entry)))
		end

		local module_path, enabled

		local ok =
			pcall(
			function()
				module_path = entry[1] or entry[0]
				enabled = entry[2] or entry[1]
			end
		)

		if i <= 5 then
			_log(string.format("[DEBUG %d] Extract ok=%s, type(entry)=%s", i, tostring(ok), type(entry)))
			_log(string.format("[DEBUG %d] module_path=%s (type: %s)", i, tostring(module_path), type(module_path)))
			_log(string.format("[DEBUG %d] enabled=%s (type: %s)", i, tostring(enabled), type(enabled)))
		end

		if not ok or not module_path then
			if i <= 5 then
				_log(string.format("[DEBUG %d] SKIPPED - extraction failed", i))
			end
			goto continue
		end

		if type(module_path) ~= "string" then
			if i <= 5 then
				_log(string.format("[DEBUG %d] SKIPPED - module_path is not string", i))
			end
			goto continue
		end

		if not enabled then
			if i <= 5 then
				_log(string.format("[DEBUG %d] SKIPPED - enabled is false/nil", i))
			end
			goto continue
		end

		if i <= 5 or success_count == 0 then
			_log(string.format("[DEBUG %d] PROCESSING: %s", i, module_path))
		end

		local datam_path = module_path:gsub("^hexm%.client%.data_oversea%.", "")

		local ok, data_obj =
			pcall(
			function()
				if not G or not G.datam then
					error("G.datam not available")
				end

				local obj = G.datam
				for part in datam_path:gmatch("[^.]+") do
					obj = obj[part]
					if not obj then
						error("Path not found: " .. part)
					end
				end
				return obj
			end
		)

		if ok and data_obj then
			local items_ok, items =
				pcall(
				function()
					return data_obj:items()
				end
			)

			if items_ok and items then
				local filename = output_dir .. "\\" .. module_path .. ".json"
				local write_ok, write_err = _write_json_file(items, filename, rapidjson)

				if write_ok then
					success_count = success_count + 1
					if success_count % 10 == 0 then
						_log(string.format("Progress: %d/%d saved...", success_count, total))
					end
				else
					_log("[ERROR] " .. module_path .. ": " .. tostring(write_err))
					fail_count = fail_count + 1
				end
			else
				_log("[ERROR] Failed to call :items() on: " .. module_path .. " - " .. tostring(items))
				fail_count = fail_count + 1
			end
		else
			_log("[ERROR] Failed to navigate to: " .. module_path .. " - " .. tostring(data_obj))
			fail_count = fail_count + 1
		end

		::continue::
	end

	_log(string.format("Dump complete: %d success, %d failed", success_count, fail_count))
	return true
end

function Dump:dump_dir_object_cache()
	_log("dump_dir_object_cache: Starting dump process...")
	local rapidjson = Utils.safe_import("rapidjson")
	local dirObj = Utils.safe_import("hexm.common.data.dir_object")

	if not dirObj or not dirObj.DirObject or not dirObj.DirObject.DirObject_Cache then
		_log("[ERROR] dump_dir_object_cache: Failed to get DirObject_Cache")
		return false, "DirObject_Cache not available"
	end

	local keys_ok, keys =
		pcall(
		function()
			return dirObj.DirObject.DirObject_Cache:keys()
		end
	)

	if not keys_ok or not keys then
		_log("[ERROR] dump_dir_object_cache: Failed to get keys - " .. tostring(keys))
		return false, "Failed to get DirObject_Cache keys"
	end

	local total = #keys
	_log("Starting DirObject_Cache dump...")
	_log("Total keys: " .. tostring(total))

	local _ROOT = Constants.SCRIPTS_ROOT
	local output_dir = _ROOT .. "\\data\\DirObject\\DirObject_Cache"
	local ok, err = _setup_output_dir(output_dir)
	if not ok then
		_log("[ERROR] dump_dir_object_cache: " .. tostring(err))
		return false, err
	end

	local success_count = 0
	local fail_count = 0

	for i = 1, total do
		local key = keys[i]

		if i <= 5 then
			_log(string.format("[DEBUG %d] Processing key: %s (type: %s)", i, tostring(key), type(key)))
		end

		if type(key) ~= "string" then
			if i <= 5 then
				_log(string.format("[DEBUG %d] SKIPPED - key is not string", i))
			end
			fail_count = fail_count + 1
			goto continue
		end

		local get_ok, data_obj =
			pcall(
			function()
				return dirObj.DirObject.DirObject_Cache:get(key)
			end
		)

		if not get_ok or not data_obj then
			_log("[ERROR] Failed to get object for key: " .. key .. " - " .. tostring(data_obj))
			fail_count = fail_count + 1
			goto continue
		end

		local items_ok, items =
			pcall(
			function()
				return data_obj:items()
			end
		)

		if not items_ok or not items then
			_log("[ERROR] Failed to call :items() on: " .. key .. " - " .. tostring(items))
			fail_count = fail_count + 1
			goto continue
		end

		local filename = output_dir .. "\\" .. key .. ".json"
		local write_ok, write_err = _write_json_file(items, filename, rapidjson)

		if write_ok then
			success_count = success_count + 1

			if success_count % 10 == 0 then
				_log(string.format("Progress: %d/%d saved...", success_count, total))
			end

			if success_count == 1 then
				_log(string.format("[DEBUG] First success: %s", key))
			end
		else
			_log("[ERROR] " .. key .. ": " .. tostring(write_err))
			fail_count = fail_count + 1
		end

		::continue::
	end

	_log(string.format("Dump complete: %d success, %d failed out of %d total", success_count, fail_count, total))
	return true
end

function Dump:dump_dir_object_weak_cache()
	_log("dump_dir_object_weak_cache: Starting dump process...")
	local rapidjson = Utils.safe_import("rapidjson")
	local dirObj = Utils.safe_import("hexm.common.data.dir_object")

	if not dirObj or not dirObj.DirObject or not dirObj.DirObject.DirObject_WeakCache then
		_log("[ERROR] dump_dir_object_weak_cache: Failed to get DirObject_WeakCache")
		return false, "DirObject_WeakCache not available"
	end

	local weak_cache = dirObj.DirObject.DirObject_WeakCache

	local _ROOT = Constants.SCRIPTS_ROOT
	local output_dir = _ROOT .. "\\data\\DirObject\\DirObject_WeakCache"
	local ok, err = _setup_output_dir(output_dir)
	if not ok then
		_log("[ERROR] dump_dir_object_weak_cache: " .. tostring(err))
		return false, err
	end

	local success_count = 0
	local fail_count = 0
	local total_count = 0

	_log("Starting WeakCache dump...")

	for key, value in pairs(weak_cache) do
		if type(key) == "string" then
			total_count = total_count + 1

			if total_count <= 5 then
				_log(string.format("[DEBUG %d] Processing key: %s (type: %s)", total_count, key, type(value)))
			end

			local items_ok, items_or_err =
				pcall(
				function()
					if value and type(value.items) == "function" then
						return value:items()
					else
						error("No items() method - type: " .. type(value))
					end
				end
			)

			if items_ok and items_or_err then
				local filename = output_dir .. "\\" .. key .. ".json"
				local write_ok, write_err = _write_json_file(items_or_err, filename, rapidjson)

				if write_ok then
					success_count = success_count + 1

					if success_count % 50 == 0 then
						_log(string.format("Progress: %d/%d saved...", success_count, total_count))
					end

					if success_count == 1 then
						_log(string.format("[DEBUG] First success: %s", key))
					end
				else
					_log("[ERROR] Write failed for " .. key .. ": " .. tostring(write_err))
					fail_count = fail_count + 1
				end
			else
				fail_count = fail_count + 1

				if fail_count <= 5 then
					_log(string.format("[SKIP %d] %s - %s", fail_count, key, tostring(items_or_err)))
				end
			end
		end
	end

	_log(
		string.format(
			"WeakCache dump complete: %d success, %d failed out of %d total",
			success_count,
			fail_count,
			total_count
		)
	)
	return true
end

function Dump:dump_buffs_csv(options)
	options = options or {}

	if not G or not G.datam or not G.datam.buff then
		_log("[ERROR] dump_buffs_csv: G.datam.buff not available")
		return nil, "G.datam.buff not available"
	end

	if not G.locale_manager or not G.locale_manager.get_locale_text_by_tid then
		_log("[ERROR] dump_buffs_csv: G.locale_manager not available")
		return nil, "G.locale_manager not available"
	end

	local rapidjson = Utils.safe_import("rapidjson")
	local output_dir = options.output_dir or (Constants.SCRIPTS_ROOT .. "\\data")
	local ok, err = _setup_output_dir(output_dir)
	if not ok then
		_log("[ERROR] dump_buffs_csv: " .. tostring(err))
		return nil, err
	end

	local buff_ids, keys_err = _collect_sorted_buff_ids(G.datam.buff)
	if not buff_ids then
		_log("[ERROR] dump_buffs_csv: " .. tostring(keys_err))
		return nil, keys_err
	end

	local rows = {}
	local skipped_rows = 0
	_log(string.format("dump_buffs_csv: exporting %d buff rows", #buff_ids))

	for idx, buff_id in ipairs(buff_ids) do
		local sysd = G.datam.buff:get(buff_id)
		if not sysd then
			skipped_rows = skipped_rows + 1
			goto continue
		end

		local raw_row = _row_to_export_dict(sysd)
		raw_row.buff_id = raw_row.buff_id or buff_id
		rows[#rows + 1] = _build_buff_summary_row(raw_row, buff_id)

		if idx % 1000 == 0 then
			_log(string.format("dump_buffs_csv: prepared %d/%d rows", idx, #buff_ids))
		end

		::continue::
	end

	_sort_buff_summary_rows(rows)

	local columns = {
		"category",
		"effect_primary",
		"effect_categories",
		"id",
		"name",
		"details",
		"effect_sources",
		"attribute_effects",
		"passive_ids",
		"passive_triggers",
		"duration",
		"duration_label",
		"type",
		"estimate",
		"estimate_label",
		"group",
		"control_type",
		"flags",
		"immune_abilities",
		"has_anti_need",
		"has_fake_need",
		"buff_tag",
		"icon",
	}
	local filename = options.filename or "buffs_dump.csv"
	local filepath = output_dir .. "\\" .. filename
	local write_ok, write_err = _write_csv_rows(filepath, columns, rows, rapidjson)

	if not write_ok then
		_log("[ERROR] dump_buffs_csv: " .. tostring(write_err))
		return nil, write_err
	end

	_log(
		string.format(
			"dump_buffs_csv: wrote %d rows (%d skipped), %d columns -> %s",
			#rows,
			skipped_rows,
			#columns,
			filepath
		)
	)

	return filepath, nil
end

-- expects: write_debug(string)
function Dump:find_related(term, max_depth)
	term = tostring(term or ""):lower()
	max_depth = max_depth or 30

	local visited = setmetatable({}, { __mode = "k" })
	local total = 0

	local function match(s)
		return type(s) == "string" and s:lower():find(term, 1, true) ~= nil
	end

	local function add(kind, path, extra)
		total = total + 1
		_log(string.format("found %-8s : %s%s", kind, path, extra and (" (" .. extra .. ")") or ""))
	end

	local function safe_pairs(t)
		local ok, it, st, var = pcall(pairs, t)
		if ok then
			return it, st, var
		end
		return nil
	end

	-- recursive safe walker for lua objects
	local function walk(path, v, depth)
		if depth > max_depth then
			return
		end
		local tv = type(v)

		if tv == "string" then
			if match(v) then
				add("string", path)
			end
			return
		end

		if tv == "function" then
			local ok, info = pcall(debug.getinfo, v, "nS")
			if ok and info then
				if match(info.name) then
					add("func", path, info.name)
				end
				if match(info.source) then
					add("source", path, info.source)
				end
			end
			return
		end

		if tv ~= "table" then
			return
		end
		if visited[v] then
			return
		end
		visited[v] = true

		local it, st, var = safe_pairs(v)
		if not it then
			return
		end

		for k, val in it, st, var do
			if type(k) == "string" and match(k) then
				add("key", path .. "." .. k)
			end

			local child = type(k) == "string" and (path .. "." .. k) or string.format("%s[%s]", path, tostring(k))

			walk(child, val, depth + 1)
		end
	end

	-- recursive dump table (for searcher state), also matches term in keys/values
	local function dump_table(t, prefix, depth, seen)
		if depth > max_depth then
			return
		end
		if type(t) ~= "table" then
			return
		end

		seen = seen or setmetatable({}, { __mode = "k" })
		if seen[t] then
			return
		end
		seen[t] = true

		local it, st, var = safe_pairs(t)
		if not it then
			return
		end

		for k, v in it, st, var do
			if type(k) == "string" and match(k) then
				add("skey", prefix .. "." .. k)
			end
			if type(v) == "string" and match(v) then
				add("sstr", prefix .. "." .. tostring(k), v)
			end

			-- if value tostring contains term (covers userdata/class handles)
			local ok_ts, ts = pcall(tostring, v)
			if ok_ts and type(ts) == "string" and match(ts) then
				add("sval", prefix .. "." .. tostring(k), ts)
			end

			if type(v) == "table" then
				dump_table(v, prefix .. "." .. tostring(k), depth + 1, seen)
			end
		end
	end

	_log("starting recursive scan")

	-- 1) globals
	walk("_G", _G, 0)

	-- 2) loaded modules
	for name, mod in pairs(package.loaded) do
		if match(name) then
			add("loaded", name)
		end
		walk("package.loaded." .. tostring(name), mod, 0)
	end

	-- 3) preload
	for name in pairs(package.preload) do
		if match(name) then
			add("preload", name)
		end
	end

	-- 4) Lua files (package.path)
	for path in tostring(package.path or ""):gmatch("[^;]+") do
		local p = path:gsub("%?", term)
		local f = io.open(p, "r")
		if f then
			f:close()
			add("lua", p)
		end
	end

	-- 5) C modules (package.cpath)
	for path in tostring(package.cpath or ""):gmatch("[^;]+") do
		local p = path:gsub("%?", term)
		local f = io.open(p, "rb")
		if f then
			f:close()
			add("cmod", p)
		end
	end

	-- 6) package.searchers (Lua 5.4)
	for idx, searcher in ipairs(package.searchers or {}) do
		-- _log(string.format("[Dump] searcher[%d] = %s", idx, tostring(searcher)))

		-- function info
		-- local ok, info = pcall(debug.getinfo, searcher, "Snlu")
		-- if ok and info then
		--     for k, v in pairs(info) do
		--         _log(string.format("[Dump]   info.%s = %s", k, tostring(v)))
		--         -- also match info fields
		--         if type(v) == "string" and match(v) then
		--             add("sinfo", string.format("searcher[%d].info.%s", idx, k), v)
		--         end
		--     end
		-- else
		--     _log("[Dump]   debug.getinfo failed")
		-- end

		-- upvalues (and dump any table upvalues deeply)
		local uv = 1
		while true do
			local ok2, uv_name, uv_val = pcall(debug.getupvalue, searcher, uv)
			if not ok2 or not uv_name then
				break
			end

			if type(uv_name) == "string" and match(uv_name) then
				add("supv", string.format("searcher[%d].upvalue[%d].%s", idx, uv, uv_name))
			end

			local ok_ts, ts = pcall(tostring, uv_val)
			if ok_ts and type(ts) == "string" and match(ts) then
				add("supv", string.format("searcher[%d].upvalue[%d]", idx, uv), ts)
			end

			if type(uv_val) == "table" then
				local ok3, err3 = pcall(dump_table, uv_val, string.format("searcher_state[%d].upvalue[%d]", idx, uv), 0)
				if not ok3 then
					_log("[Dump]   dump_table failed: " .. tostring(err3))
				end
			end

			uv = uv + 1
		end
	end

	_log(string.format("done, %d matches", total))
end

return Dump
