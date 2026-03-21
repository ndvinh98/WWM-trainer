-- Scripts/actions/spy.lua
local ActionBase = _G.Reg.lib("ActionBase")

local Spy = ActionBase:extend("actions.spy")

-- ============================================================
-- CONSTANTS
-- ============================================================
local DEFAULT_STACK_START_LEVEL = 3
local MAX_STACK_DEPTH = 30
local SPY_HOOK_ID = "spy_wrapper"
local LOCAL_SCRIPTS_PATH = _G.Reg.lib("Constants").SCRIPTS_ROOT

local debug_getinfo = debug.getinfo
local debug_getlocal = debug.getlocal
local string_find = string.find

function Spy:define_state()
	return {
		persistent = {
			log_enabled = true,
		},
		transient = {
			config = {
				source_substr = "",
				func_name = "",
				capture_stack = true,
				cache_logs = true,
			},
			enabled = false,
			in_hook = false,
			call_stack = {},
			wrapper_mode = false,
			call_count = 0,
			log_cache = {},
		},
	}
end

function Spy:define_hooks()
	return {}
end

-- ============================================================
-- PRIVATE HELPERS
-- ============================================================

function Spy:_class_of_self(level)
	local arg_name, self_val = debug_getlocal(level, 1)
	if not arg_name or arg_name ~= "self" then
		return nil
	end
	if type(self_val) ~= "table" then
		return nil
	end

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

	local ok2, str_repr = pcall(tostring, self_val)
	if ok2 and type(str_repr) == "string" then
		local cn = str_repr:match("<instance of ([%w_]+) at ")
		if cn then
			return cn
		end
		cn = str_repr:match("^%[([%w_]+)")
		if cn and cn ~= "class" then
			return cn
		end
	end

	return nil
end

function Spy:_capture_params(level)
	local Serialize = _G.Reg.lib("Serialize")
	local params = {}
	local i = 1
	while true do
		local name, value = debug_getlocal(level, i)
		if not name then
			break
		end
		if name:sub(1, 1) ~= "(" then
			params[#params + 1] = name .. "=" .. Serialize.dump_value(value)
		end
		i = i + 1
	end
	return table.concat(params, ", ")
end

function Spy:_capture_traceback(start_level)
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

-- ============================================================
-- WRAPPER MODE
-- ============================================================

function Spy:_path_to_module(path)
	local module_path = path
	module_path = module_path:gsub("%.lua$", "")
	module_path = module_path:gsub("[/\\]", ".")
	return module_path
end

function Spy:_parse_source(source)
	local colon_pos = source:find(":", 1, true)
	if colon_pos then
		return {
			path = source:sub(1, colon_pos - 1),
			class = source:sub(colon_pos + 1),
		}
	end
	return { path = source, class = nil }
end

function Spy:_start_wrapper_mode()
	local config = self.state.config
	local parsed = self:_parse_source(config.source_substr)
	local module_path = self:_path_to_module(parsed.path)
	local class_name = parsed.class
	local func_name = config.func_name

	local HookManager = _G.Reg.lib("HookManager")
	local Serialize = _G.Reg.lib("Serialize")

	if self:is_hooked(SPY_HOOK_ID) then
		self:log("WARNING: Already hooked")
		return false, "Already hooked"
	end

	local spec_string
	local display_name
	if class_name then
		spec_string = module_path .. ":" .. class_name .. ":" .. func_name
		display_name = module_path .. "." .. class_name .. ":" .. func_name
		self:log("Hooking method: " .. config.source_substr .. " -> " .. display_name)
	else
		spec_string = module_path .. ":" .. func_name
		display_name = module_path .. "." .. func_name
		self:log("Hooking function: " .. config.source_substr .. " -> " .. display_name)
	end

	HookManager.register(self._name, SPY_HOOK_ID, {
		spec = spec_string,
		override_orig_function = false,
		post_exec = function(self_action, args, results, traceback)
			local signature = string.format("(%s):(%s)", Serialize.dump_value(args), Serialize.dump_value(results))
			if config.cache_logs then
				if self_action.state.log_cache[signature] then
					self_action.state.in_hook = false
					return
				end
				self_action.state.log_cache[signature] = true
			end

			self_action:log("Detection incoming call for: " .. display_name)
			self_action:log("      Args: " .. Serialize.dump_value(args))
			self_action:log("      Results: " .. Serialize.dump_value(results))
			if config.capture_stack then
				self_action:log("      Traceback: " .. tostring(traceback))
			end
		end,
	})

	local ok, err = pcall(function() self:hook(SPY_HOOK_ID) end)
	if not ok then
		self:log("ERROR: Failed to hook - " .. tostring(err))
		self:list_G_instances()
		return false, err
	end

	self.state.wrapper_mode = true
	self:log("Wrapper mode: hooked " .. display_name)
	return true
end

function Spy:_stop_wrapper_mode()
	if not self.state.wrapper_mode then
		return true
	end

	if self:is_hooked(SPY_HOOK_ID) then
		self:unhook(SPY_HOOK_ID)
		self:log("Wrapper mode: unhooked")
	end

	self.state.wrapper_mode = false
	return true
end

-- ============================================================
-- SPY HANDLER (debug.sethook mode)
-- ============================================================

function Spy:_create_spy_handler()
	local spy_self = self

	return function(event)
		if spy_self.state.in_hook then
			return
		end
		spy_self.state.in_hook = true

		local config = spy_self.state.config
		local info = debug_getinfo(DEFAULT_STACK_START_LEVEL, "Sf")
		if not info or not info.source then
			spy_self.state.in_hook = false
			return
		end

		local src = info.source
		local func = info.func
		

		if src:sub(1, 1) == "@" then
			src = src:sub(2)
		end

		if config.source_substr ~= "" then
			local parsed = spy_self:_parse_source(config.source_substr)
			if not string_find(src, parsed.path, 1, true) then
				spy_self.state.in_hook = false
				return
			end
		end

		local name_info = debug_getinfo(DEFAULT_STACK_START_LEVEL, "n")
		local name = name_info and name_info.name

		if not name or name == "?" then
			if info.linedefined and info.linedefined > 0 then
				name = string.format("<func@L%d>", info.linedefined)
			else
				name = "<anonymous>"
			end
		end

		if config.func_name ~= "" then
			local match_found = false
			for func_filter in config.func_name:gmatch("[^;]+") do
				func_filter = func_filter:match("^%s*(.-)%s*$")
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
				spy_self.state.in_hook = false
				return
			end
		else
			spy_self.state.in_hook = false
			return
		end

		local params, class_name, traceback_str
		if event == "call" or event == "tail call"  then
			local is_local_src = string_find(src, LOCAL_SCRIPTS_PATH, 1, true)
			if not is_local_src then
				params = spy_self:_capture_params(DEFAULT_STACK_START_LEVEL + 1)
			end
			class_name = spy_self:_class_of_self(DEFAULT_STACK_START_LEVEL + 1)
			traceback_str = config.capture_stack and spy_self:_capture_traceback(DEFAULT_STACK_START_LEVEL + 1) or nil
		end

		local ok, err = pcall(function()
			if event == "call" or event == "tail call" then
				if event == "tail call" then
					spy_self.state.call_stack[#spy_self.state.call_stack] = nil
				end

				spy_self.state.call_count = spy_self.state.call_count + 1
				local call_id = spy_self.state.call_count

				local class_tag = ""
				if class_name then
					class_tag = string.format(" [class=%s]", class_name)
				end

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

				local signature = string.format("%s:%s(%s)%s%s", src, name, params or "", func_def, class_tag)

				spy_self.state.call_stack[#spy_self.state.call_stack + 1] = {
					func = func,
					call_id = call_id,
					log_line = signature,
					traceback = traceback_str,
				}

				if config.cache_logs then
					if spy_self.state.log_cache[signature] then
						return
					end
					spy_self.state.log_cache[signature] = true
				end

				spy_self:log(string.format("#%d %s", call_id, signature))
				if traceback_str then
					spy_self:log("Traceback:\n" .. traceback_str)
				end
			elseif event == "return" then
				for i = #spy_self.state.call_stack, 1, -1 do
					if spy_self.state.call_stack[i].func == func then
						table.remove(spy_self.state.call_stack, i)
						break
					end
				end
			end
		end)

		spy_self.state.in_hook = false

		if not ok then
			spy_self:log("ERROR: Hook handler failed: " .. tostring(err))
		end
	end
end

-- ============================================================
-- PUBLIC API
-- ============================================================

function Spy:set_target(source_substr, func_name)
	self.state.config.source_substr = source_substr or ""
	self.state.config.func_name = func_name or ""
	self:log("Target: src='" .. self.state.config.source_substr .. "' func='" .. self.state.config.func_name .. "'")
	return true
end

function Spy:start(options)
	if self.state.enabled then
		return false, "Already running"
	end

	local config = self.state.config
	if options then
		config.source_substr = options.source or config.source_substr
		config.func_name = options.func or config.func_name
		if options.cache_logs ~= nil then
			config.cache_logs = options.cache_logs
		end
	end

	self.state.call_count = 0
	self.state.call_stack = {}
	self.state.in_hook = false
	self.state.wrapper_mode = false
	self.state.log_cache = {}

	-- Use wrapper mode when BOTH source and func are specified
	if config.source_substr ~= "" and config.func_name ~= "" then
		local ok, err = self:_start_wrapper_mode()
		if not ok then
			return false, err
		end
		self.state.enabled = true
		self:log("Started (wrapper mode - captures params + returns)")
		return true
	end

	-- Use debug.sethook mode
	if config.source_substr == "" and config.func_name == "" then
		self:log("WARNING: No filter - will spy ALL calls!")
	end

	debug.sethook(self:_create_spy_handler(), "cr")
	self.state.enabled = true
	self:log("Started (hook mode - params only, no returns)")
	return true
end

function Spy:stop()
	if not self.state.enabled then
		return false, "Not running"
	end

	if self.state.wrapper_mode then
		self:_stop_wrapper_mode()
	else
		debug.sethook()
	end

	self.state.enabled = false

	local unique_count = 0
	for _ in pairs(self.state.log_cache) do
		unique_count = unique_count + 1
	end

	if self.state.config.cache_logs then
		self:log(string.format("Stopped - %d calls intercepted (%d unique)", self.state.call_count, unique_count))
	else
		self:log(string.format("Stopped - %d calls intercepted", self.state.call_count))
	end

	self.state.log_cache = {}
	return true
end

function Spy:is_enabled()
	return self.state.enabled
end

function Spy:get_stats()
	local unique_count = 0
	for _ in pairs(self.state.log_cache) do
		unique_count = unique_count + 1
	end

	return {
		is_enabled = self.state.enabled,
		call_count = self.state.call_count,
		unique_count = unique_count,
		config = self.state.config,
	}
end

function Spy:clear_cache()
	self.state.log_cache = {}
	self:log("Cache cleared")
end

-- ============================================================
-- INSTANCE REGISTRY UTILITIES
-- ============================================================

function Spy:list_G_instances(filter_prefix)
	local Serialize = _G.Reg.lib("Serialize")
	if not G then
		self:log("ERROR: G (game global state) not available")
		return nil
	end

	filter_prefix = filter_prefix or ""

	self:log("=== LISTING G (GAME GLOBAL STATE) ===")
	self:log("G type: " .. type(G))
	self:log("G tostring: " .. tostring(G))

	local keys = {}
	local instance_count = 0
	local total_count = 0

	for k, v in pairs(G) do
		total_count = total_count + 1
		if filter_prefix == "" or (type(k) == "string" and k:sub(1, #filter_prefix) == filter_prefix) then
			table.insert(keys, k)
			if type(v) == "table" or type(v) == "userdata" then
				instance_count = instance_count + 1
			end
		end
	end

	table.sort(keys, function(a, b)
		local va, vb = G[a], G[b]
		local ta, tb = type(va), type(vb)
		local label_a = ta
		local label_b = tb

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

		local priority_a = (label_a == "instance" and 1) or (ta == "function" and 2) or 3
		local priority_b = (label_b == "instance" and 1) or (tb == "function" and 2) or 3

		if priority_a ~= priority_b then
			return priority_a < priority_b
		end
		return tostring(a):lower() < tostring(b):lower()
	end)

	self:log("\n--- G CONTENTS ---")
	for _, k in ipairs(keys) do
		local v = G[k]
		local v_type = type(v)
		local v_str = Serialize.dump_value(v)
		self:log(string.format("  [%s] (%s) = %s", tostring(k), v_type, v_str))
	end

	self:log("\nTotal items in G: " .. total_count)
	self:log("Filtered items: " .. #keys)
	self:log("Instance/table/userdata count: " .. instance_count)
	self:log("=== END LISTING ===\n")

	return keys
end

return Spy:new()
