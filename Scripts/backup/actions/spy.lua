-- ============================================================
-- HOOK.LUA - Function Interception Module
-- ============================================================
-- Intercepts target function calls to log parameters and results.
-- Prerequisites: Bootstrap must be loaded first

local Spy = {}

-- Reference libs via Reg (loaded once by bootstrap)
local Reg = _G.Reg
local Logger = Reg.get("Logger")
local Hooks = Reg.get("Hooks")
local Utils = Reg.get("Utils")
local Logger = Reg.get("Logger")
local Constants = Reg.get("Constants")
local Parry = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\actions\\parry.lua", "Parry")
-- ============================================================
-- LOG CACHING (to avoid spam)
-- ============================================================
local _log_cache = {} -- Simple lookup: { [signature] = true }

local function _log(msg)
	-- for _, kw in ipairs(FILTER_KEYWORDS) do
	--     if msg:find(kw, 1, true) then
	--         return
	--     end
	-- end
	Logger.log(string.format("[Spy:%s] %s ", tostring(os.time()), msg))
end

-- ============================================================
-- CONFIGURATION
-- ============================================================
Spy.config = {
	source_substr = "", -- Source file substring filter
	func_name = "", -- Function name to spy
	capture_stack = true, -- Whether to capture stack trace (false = only params and call info)
	cache_logs = true, -- Enable log caching to avoid duplicate signatures (default: false)
}

-- ============================================================
-- STATE
-- ============================================================
local _enabled = false
local _in_hook = false -- Re-entrancy guard
local _call_stack = {} -- Stack of {func, call_id, log_line, traceback}
local _wrapper_mode = false -- True when using wrapper (captures returns)
local _call_count = 0

-- ============================================================
-- LOCAL REFERENCES
-- ============================================================
-- ============================================================
-- CONSTANTS
-- ============================================================
local DEFAULT_STACK_START_LEVEL = 3 -- Level for debug.getinfo AND debug.getlocal (target function)
local MAX_STACK_DEPTH = 30 -- Maximum stack frames to capture
local SPY_HOOK_ID = "spy_wrapper" -- Hook ID for wrapper mode

local debug_getinfo = debug.getinfo
local debug_getlocal = debug.getlocal
local string_find = string.find

-- ============================================================
-- PRIVATE HELPERS
-- ============================================================

local function _beep()
	local cmd = 'cmd /c start "" /b powershell -NoProfile -WindowStyle Hidden -Command "[console]::Beep(1000,200)"'
	os.execute(cmd)
end

-- Lightweight class detection from self (first arg of method calls)
-- Uses mt.__index.__cname and tostring() parsing (matches game patterns)
local function _class_of_self(level)
	local arg_name, self_val = debug_getlocal(level, 1)
	if not arg_name or arg_name ~= "self" then
		return nil
	end
	if type(self_val) ~= "table" then
		return nil
	end

	-- Try 1: metatable.__index.__cname (standard Lua class pattern in this codebase)
	local ok, class_name = pcall(function()
		local mt = getmetatable(self_val)
		if mt and mt.__index and type(mt.__index) == "table" then
			return mt.__index.__cname
		end
		return nil
	end)
	if ok and class_name then
		return class_name
	end

	-- Try 2: parse tostring() output for class name
	local ok2, str_repr = pcall(tostring, self_val)
	if ok2 and type(str_repr) == "string" then
		-- Pattern: <instance of ClassName at ADDRESS>
		local cn = str_repr:match("<instance of ([%w_]+) at ")
		if cn then
			return cn
		end
		-- Pattern: [ClassName at ADDRESS] or [ClassName]
		cn = str_repr:match("^%[([%w_]+)")
		if cn and cn ~= "class" then
			return cn
		end
	end

	return nil
end

-- Capture function parameters from stack level (all params)
local function capture_params(level)
	local params = {}
	local i = 1
	while true do
		local name, value = debug_getlocal(level, i)
		if not name then
			break
		end
		if name:sub(1, 1) ~= "(" then
			params[#params + 1] = name .. "=" .. Utils.dump_value(value)
		end
		i = i + 1
	end
	return table.concat(params, ", ")
end

-- Capture return values (negative indices)
-- NOTE: Return values cannot be captured via debug.getlocal in a hook.
-- To capture return values, you must wrap the target function directly.
-- Example: local orig = target; target = function(...) local r = {orig(...)}; log(r); return unpack(r) end

-- Capture call stack (traceback)
local function capture_traceback(start_level)
	local stack = {}
	local level = start_level or DEFAULT_STACK_START_LEVEL
	while true do
		local info = debug_getinfo(level, "nSl")
		if not info then
			break
		end

		local src = info.source or "?"
		if src:sub(1, 1) == "@" then
			src = src:sub(2)
		end

		local name = info.name or "<anonymous>"
		local line = info.currentline or info.linedefined or 0

		stack[#stack + 1] = string.format("  [%d] %s:%d in %s", level - start_level + 1, src, line, name)

		level = level + 1
		if level > start_level + MAX_STACK_DEPTH then
			break
		end
	end
	return table.concat(stack, "\n")
end

-- The spy handler
-- ============================================================
-- WRAPPER MODE (captures params + returns)
-- ============================================================
-- Used when both source_substr and func_name are specified.
-- Wraps the target function using Hooks module to capture return values.

-- Convert file path to module path
-- "hexm/client/net/network_comp/net_call_rpc.lua" -> "hexm.client.net.network_comp.net_call_rpc"
local function _path_to_module(path)
	local module_path = path
	-- Remove .lua extension
	module_path = module_path:gsub("%.lua$", "")
	-- Replace / and \ with .
	module_path = module_path:gsub("[/\\]", ".")
	return module_path
end

-- Parse source_substr to extract file path and optional class name
-- "hexm/client/net/net_call_rpc.lua:NetCallRpc" -> { path = "hexm/client/net/net_call_rpc.lua", class = "NetCallRpc" }
-- "hexm/client/net/net_call_rpc.lua" -> { path = "hexm/client/net/net_call_rpc.lua", class = nil }
local function _parse_source(source)
	local colon_pos = source:find(":", 1, true)
	if colon_pos then
		return {
			path = source:sub(1, colon_pos - 1),
			class = source:sub(colon_pos + 1),
		}
	end
	return { path = source, class = nil }
end

local function _start_wrapper_mode()
	local parsed = _parse_source(Spy.config.source_substr)
	local module_path = _path_to_module(parsed.path)
	local class_name = parsed.class
	local func_name = Spy.config.func_name

	if not Hooks then
		_log("ERROR: Hooks module not available")
		return false, "Hooks module required for wrapper mode"
	end

	if Hooks.is_hooked(SPY_HOOK_ID) then
		_log("WARNING: Already hooked")
		return false, "Already hooked"
	end

	-- Build display name for logging
	local display_name
	if class_name then
		display_name = module_path .. "." .. class_name .. ":" .. func_name
		_log("Hooking method: " .. Spy.config.source_substr .. " -> " .. display_name)
	else
		display_name = module_path .. "." .. func_name
		_log("Hooking function: " .. Spy.config.source_substr .. " -> " .. display_name)
	end

	local callbacks = {
		-- override_exec = function (...)
		--     _log("Bypassing original function: " .. display_name)
		--     return nil
		-- end

		post_exec = function(args, results, traceback)
			local signature = string.format("(%s):(%s)", Utils.dump_value(args), Utils.dump_value(results))
			-- If caching enabled, check if we've seen this signature before
			if Spy.config.cache_logs then
				if _log_cache[signature] then
					-- Already logged, skip it
					_in_hook = false
					return
				end
				-- Mark as logged
				_log_cache[signature] = true
			end

			_log("Detection incoming call for: " .. display_name)
			_log("      Args: " .. Utils.dump_value(args))
			_log("      Results: " .. Utils.dump_value(results))
			if Spy.config.capture_stack then
				_log("      Traceback: " .. tostring(traceback))
			end
		end,
	}

	-- Use hook_method for class methods, hook_function for module functions
	local ok, err
	if class_name then
		_log("Using hook_method for class: " .. class_name)
		ok, err = Hooks.hook_method(SPY_HOOK_ID, module_path, class_name, func_name, callbacks)
	else
		ok, err = Hooks.hook_function(SPY_HOOK_ID, module_path, func_name, callbacks)
	end

	if not ok then
		_log("ERROR: Failed to hook - " .. tostring(err))
		Spy.list_G_instances()
		return false, err
	end

	_wrapper_mode = true
	_log("Wrapper mode: hooked " .. display_name)
	return true
end

local function _stop_wrapper_mode()
	if not _wrapper_mode then
		return true
	end

	if Hooks and Hooks.is_hooked(SPY_HOOK_ID) then
		Hooks.unhook(SPY_HOOK_ID)
		_log("Wrapper mode: unhooked")
	end

	_wrapper_mode = false
	return true
end

local function spy_handler(event)
	-- Re-entrancy guard: prevent recursion from hook calling Lua code
	if _in_hook then
		return
	end
	_in_hook = true

	-- Fetch cheap info first (source + func), filter before expensive work
	-- These debug calls are safe and won't error
	local info = debug_getinfo(DEFAULT_STACK_START_LEVEL, "Sf")
	if not info or not info.source then
		_in_hook = false
		return
	end

	local src = info.source
	local func = info.func

	-- Strip @ prefix (normalize once)
	if src:sub(1, 1) == "@" then
		src = src:sub(2)
	end

	-- Apply source filter early (before fetching name/params)
	if Spy.config.source_substr ~= "" then
		local parsed = _parse_source(Spy.config.source_substr)
		if not string_find(src, parsed.path, 1, true) then
			_in_hook = false
			return
		end
	end

	-- Now fetch name (slightly more expensive due to name lookup)
	local name_info = debug_getinfo(DEFAULT_STACK_START_LEVEL, "n")
	local name = name_info and name_info.name

	-- Improve function name when debug.getinfo returns "?" or nil
	if not name or name == "?" then
		if info.linedefined and info.linedefined > 0 then
			name = string.format("<func@L%d>", info.linedefined)
		else
			name = "<anonymous>"
		end
	end

	-- Apply func_name filter - supports multiple patterns separated by ";"
	if Spy.config.func_name ~= "" then
		local match_found = false

		for func_filter in Spy.config.func_name:gmatch("[^;]+") do
			func_filter = func_filter:match("^%s*(.-)%s*$") -- trim whitespace

			if func_filter ~= "" then
				if name:find(func_filter, 1, true) then
					match_found = true
					break
				end
				if src:find(func_filter, 1, true) then
					match_found = true
					break
				end
			end
		end

		if not match_found then
			_in_hook = false
			return
		end
	end

	-- Past all filters — capture stack-sensitive data at correct level BEFORE pcall
	-- Stack layout from spy_handler (direct debug.getlocal):
	--   level 1: spy_handler
	--   level 2: [C] function that triggered hook
	--   level 3: target (e.g. on_bone_hit with self, graph, d)
	-- But capture_params/_class_of_self are function calls, adding +1 to the stack:
	--   level 1: capture_params/_class_of_self
	--   level 2: spy_handler
	--   level 3: [C] trigger
	--   level 4: target (self, graph, d)
	local params, class_name, traceback
	if event == "call" or event == "tail call" then
		params = capture_params(DEFAULT_STACK_START_LEVEL + 1)
		class_name = _class_of_self(DEFAULT_STACK_START_LEVEL + 1)
		traceback = Spy.config.capture_stack and capture_traceback(DEFAULT_STACK_START_LEVEL + 1) or nil
	end

	-- Now do the rest inside pcall so _in_hook always resets on error
	local ok, err = pcall(function()
		if event == "call" or event == "tail call" then
			-- Tail call = pop replaced frame, then push new one
			if event == "tail call" then
				_call_stack[#_call_stack] = nil
			end

			_call_count = _call_count + 1
			local call_id = _call_count

			-- Class tag from pre-captured self
			local class_tag = ""
			if class_name then
				class_tag = string.format(" [class=%s]", class_name)
			end

			-- Get function definition info
			local func_def = ""
			local def_src_key = "<?>"
			local def_line_key = -1
			local func_source_info = debug_getinfo(func, "S")
			if func_source_info and func_source_info.source then
				local def_src = func_source_info.source
				if def_src:sub(1, 1) == "@" then
					def_src = def_src:sub(2)
				end
				local def_line = func_source_info.linedefined or "?"
				func_def = string.format(" [def@%s:%s]", def_src, def_line)
				def_src_key = def_src
				def_line_key = def_line
			end

			-- Cache by function definition identity (source+line+name), not params
			local cache_key = string.format("%s:%s:%s", def_src_key, def_line_key, name)

			-- Full signature for logging (still includes params for readability)
			local signature = string.format("%s:%s(%s)%s%s", src, name, params, func_def, class_tag)

			-- Push onto call stack (matched by function object)
			_call_stack[#_call_stack + 1] = {
				func = func,
				call_id = call_id,
				log_line = signature,
				traceback = traceback,
			}

			-- If caching enabled, check by definition identity (not full signature)
			if Spy.config.cache_logs then
				if _log_cache[signature] then
					return
				end
				_log_cache[signature] = true
			end

			-- Log with call_id prefix
			_log(string.format("#%d %s", call_id, signature))
			if traceback then
				_log("Traceback:\n" .. traceback)
			end
		elseif event == "return" then
			-- Pop from call stack, matching by function object
			for i = #_call_stack, 1, -1 do
				if _call_stack[i].func == func then
					table.remove(_call_stack, i)
					break
				end
			end
		end
	end)

	_in_hook = false

	if not ok then
		pcall(Logger.log, "[Spy:ERROR] Hook handler failed: " .. tostring(err))
	end
end

-- ============================================================
-- PUBLIC API
-- ============================================================

function Spy.set_target(source_substr, func_name)
	Spy.config.source_substr = source_substr or ""
	Spy.config.func_name = func_name or ""
	_log("Target: src='" .. Spy.config.source_substr .. "' func='" .. Spy.config.func_name .. "'")
	return true
end

function Spy.start(options)
	if _enabled then
		return false, "Already running"
	end

	if options then
		Spy.config.source_substr = options.source or Spy.config.source_substr
		Spy.config.func_name = options.func or Spy.config.func_name
		if options.cache_logs ~= nil then
			Spy.config.cache_logs = options.cache_logs
		end
	end

	_call_count = 0
	_call_stack = {}
	_in_hook = false
	_wrapper_mode = false
	_log_cache = {} -- Clear cache on start

	-- Use wrapper mode when BOTH source and func are specified (can capture returns)
	if Spy.config.source_substr ~= "" and Spy.config.func_name ~= "" then
		local ok, err = _start_wrapper_mode()
		if not ok then
			return false, err
		end
		_enabled = true
		_log("Started (wrapper mode - captures params + returns)")
		return true
	end

	-- Use debug.sethook mode (can only capture params, not returns)
	if Spy.config.source_substr == "" and Spy.config.func_name == "" then
		_log("WARNING: No filter - will spy ALL calls!")
	end

	debug.sethook(spy_handler, "cr")
	_enabled = true
	_log("Started (hook mode - params only, no returns)")
	return true
end

function Spy.stop()
	if not _enabled then
		return false, "Not running"
	end

	if _wrapper_mode then
		_stop_wrapper_mode()
	else
		debug.sethook()
	end

	_enabled = false

	-- Log stats
	local unique_count = 0
	for _ in pairs(_log_cache) do
		unique_count = unique_count + 1
	end

	if Spy.config.cache_logs then
		_log(string.format("Stopped - %d calls intercepted (%d unique)", _call_count, unique_count))
	else
		_log(string.format("Stopped - %d calls intercepted", _call_count))
	end

	_log_cache = {} -- Clear cache
	return true
end

function Spy.is_enabled()
	return _enabled
end

function Spy.get_stats()
	local unique_count = 0
	for _ in pairs(_log_cache) do
		unique_count = unique_count + 1
	end

	return {
		is_enabled = _enabled,
		call_count = _call_count,
		unique_count = unique_count,
		config = Spy.config,
	}
end

-- Clear the cache to start fresh (useful for testing)
function Spy.clear_cache()
	_log_cache = {}
	_log("Cache cleared")
end

-- ============================================================
-- INSTANCE REGISTRY UTILITIES
-- ============================================================

-- List all variables/instances stored in G (game global state)
function Spy.list_G_instances(filter_prefix)
	if not G then
		_log("ERROR: G (game global state) not available")
		return nil
	end

	filter_prefix = filter_prefix or ""

	_log("=== LISTING G (GAME GLOBAL STATE) ===")
	_log("G type: " .. type(G))
	_log("G tostring: " .. tostring(G))

	-- Collect all keys
	local keys = {}
	local instance_count = 0
	local total_count = 0

	for k, v in pairs(G) do
		total_count = total_count + 1

		-- Apply filter if specified
		if filter_prefix == "" or (type(k) == "string" and k:sub(1, #filter_prefix) == filter_prefix) then
			table.insert(keys, k)

			if type(v) == "table" or type(v) == "userdata" then
				instance_count = instance_count + 1
			end
		end
	end

	-- Sort keys by type priority (instance -> function -> others), then alphabetically
	table.sort(keys, function(a, b)
		local va, vb = G[a], G[b]
		local ta, tb = type(va), type(vb)

		-- Get type labels (to detect instance type)
		local label_a = ta
		local label_b = tb

		-- Check if it's an instance (has metatable with __tostring)
		if ta == "table" then
			local mt_a = getmetatable(va)
			if mt_a and rawget(mt_a, "__tostring") then
				label_a = "instance"
			end
		end

		if tb == "table" then
			local mt_b = getmetatable(vb)
			if mt_b and rawget(mt_b, "__tostring") then
				label_b = "instance"
			end
		end

		-- Priority: instance=1, function=2, others=3
		local priority_a = (label_a == "instance" and 1) or (ta == "function" and 2) or 3
		local priority_b = (label_b == "instance" and 1) or (tb == "function" and 2) or 3

		if priority_a ~= priority_b then
			return priority_a < priority_b
		end

		-- Same priority, sort alphabetically (case-insensitive)
		return tostring(a):lower() < tostring(b):lower()
	end)

	_log("\n--- G CONTENTS ---")

	-- Log each item (use Utils.dump_value for consistent formatting)
	for _, k in ipairs(keys) do
		local v = G[k]
		local v_type = type(v)
		local v_str = Utils.dump_value(v)

		_log(string.format("  [%s] (%s) = %s", tostring(k), v_type, v_str))
	end

	_log("\nTotal items in G: " .. total_count)
	_log("Filtered items: " .. #keys)
	_log("Instance/table/userdata count: " .. instance_count)
	_log("=== END LISTING ===\n")

	return keys
end

return Spy
