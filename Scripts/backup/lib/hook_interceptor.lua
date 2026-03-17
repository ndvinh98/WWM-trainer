local Reg = _G.Reg
local Hooks = Reg.get("Hooks")
local Logger = Reg.get("Logger")
local Utils = Reg.get("Utils")

local HookInterceptor = {}
local function _log(msg)
	if Logger then
		Logger.log("[HookInterceptor] " .. msg)
	end
end

-- ────────────────────────────────────────────────────────────
-- Spec parsing
-- ────────────────────────────────────────────────────────────

--[[
    Parse method spec string into components.

    Formats:
      "module:function"                         → 2 parts
      "module:class:method"                     → 3 parts
      "module:class:instance_field:key"          → 4 parts (nested instance)

    Returns: {
        module_path, class_name, method_name,
        instance_field, instance_key
    }
]]
local function _parse_spec(spec)
	local parts = {}
	for part in spec:gmatch("[^:]+") do
		table.insert(parts, part)
	end

	if #parts == 2 then
		return {
			module_path = parts[1],
			class_name = nil,
			method_name = parts[2],
			instance_field = nil,
			instance_key = nil,
		}
	elseif #parts == 3 then
		return {
			module_path = parts[1],
			class_name = parts[2],
			method_name = parts[3],
			instance_field = nil,
			instance_key = nil,
		}
	elseif #parts == 4 then
		return {
			module_path = parts[1],
			class_name = parts[2],
			method_name = nil,
			instance_field = parts[3],
			instance_key = parts[4],
		}
	else
		return nil, "Invalid spec format: " .. spec
	end
end

--[[
    Normalize a raw spec item (string or table) into its components.
    Returns: spec_str, custom_callback, per_method_traceback, override_orig, or nil on error.
]]
local function _normalize_spec_item(spec_item)
	if type(spec_item) == "string" then
		return spec_item, nil, nil, nil
	elseif type(spec_item) == "table" then
		return spec_item.spec, spec_item.post_exec, spec_item.enable_traceback, spec_item.override_orig_function
	else
		_log("Invalid spec item type: " .. type(spec_item))
		return nil
	end
end

-- ────────────────────────────────────────────────────────────
-- Container replacement helpers (shared by hook & unhook)
-- ────────────────────────────────────────────────────────────

--[[
    Replace the function at index 1 inside a container (table or list),
    or replace the value directly if it's a plain function slot.
]]
local function _replace_fn_in_container(container, key, new_fn, bound_instance)
	if bound_instance then
		local tuple = container[key]
		local tuple_type = type(tuple)
		if tuple_type == "table" then
			rawset(tuple, 1, new_fn)
		else
			tuple[1] = new_fn
		end
	else
		container[key] = new_fn
	end
end

--[[
    Restore the original function inside a container, mirroring
    the structure-aware logic used during hooking.
]]
local function _restore_fn_in_container(container, key, original_fn)
	local current_value = container[key]
	local value_type = type(current_value)

	if value_type == "table" then
		rawset(current_value, 1, original_fn)
	elseif value_type == "list" then
		current_value[1] = original_fn
	else
		container[key] = original_fn
	end
end

-- ────────────────────────────────────────────────────────────
-- Default logging
-- ────────────────────────────────────────────────────────────

--[[
    Build the default log message when no custom callback is provided.
]]
local function _build_default_log(parsed, args, results, should_traceback, traceback)
	local msg_parts = {}

	if parsed.instance_field and parsed.instance_key then
		table.insert(
			msg_parts,
			parsed.class_name .. "." .. parsed.instance_field .. "[" .. tostring(parsed.instance_key) .. "]"
		)
	elseif parsed.class_name then
		table.insert(msg_parts, parsed.class_name .. ":" .. parsed.method_name)
	else
		table.insert(msg_parts, parsed.method_name)
	end

	table.insert(msg_parts, "args=" .. Utils.dump_value(args))
	table.insert(msg_parts, "returns=" .. Utils.dump_value(results))

	_log(table.concat(msg_parts, " | ") .. "\n")

	if should_traceback and traceback then
		_log("Traceback:\n" .. traceback)
	end
end

-- ────────────────────────────────────────────────────────────
-- Callback construction
-- ────────────────────────────────────────────────────────────

--[[
    Build a callbacks table compatible with Hooks._make_wrapper.

    Hooks.lua supports two callback modes:
      - callbacks.override_exec(original_fn, ...)  → full control, no auto-call
      - callbacks.post_exec(args, results, tb)      → observe after auto-call

    When override_orig is true, we emit override_exec so hooks.lua skips
    calling the original. When false, we emit post_exec for observation.
    This fixes the prior bug where override_orig_function was set on a
    field that hooks.lua never checked.
]]
local function _make_callbacks(parsed, custom_callback, global_callback, should_traceback, override_orig)
	local cb = custom_callback or global_callback

	if override_orig then
		return {
			override_exec = function(original_fn, ...)
				local args = table.pack(...)
				local tb = should_traceback and debug.traceback("", 1) or nil
				if cb then
					return cb(parsed, args, {}, tb, original_fn)
				end
				_build_default_log(parsed, args, {}, should_traceback, tb)
			end,
		}
	end

	return {
		post_exec = function(args, results, tb)
			if cb then
				local ok, err = pcall(cb, parsed, args, results, tb)
				if not ok then
					_log("post_exec error: " .. tostring(err))
				end
			else
				_build_default_log(parsed, args, results, should_traceback, tb)
			end
		end,
	}
end

-- ────────────────────────────────────────────────────────────
-- Wrapper for non-Hooks paths (nested instance, ancestor class)
-- ────────────────────────────────────────────────────────────

--[[
    Build a wrapper matching Hooks._make_wrapper semantics.
    Used only for paths that bypass Hooks (nested instance, ancestor).
]]
local function _wrap_fn(original_fn, callbacks)
	return function(...)
		if callbacks.override_exec then
			return callbacks.override_exec(original_fn, ...)
		end

		local args = table.pack(...)
		local results = table.pack(original_fn(...))

		if callbacks.post_exec then
			local ok, err = pcall(callbacks.post_exec, args, results, debug.traceback("", 1))
			if not ok then
				_log("post_exec error: " .. tostring(err))
			end
		end

		return table.unpack(results, 1, results.n)
	end
end

-- ────────────────────────────────────────────────────────────
-- Ancestor class resolution (for unexported base classes)
-- ────────────────────────────────────────────────────────────

--[[
    Check if a table's class name matches the target, trying common
    field names used by different Lua class systems.
]]
local function _get_class_name(tbl)
	return rawget(tbl, "__cname__")
		or rawget(tbl, "__cname")
		or rawget(tbl, "classname")
		or rawget(tbl, "__name")
		or rawget(tbl, "__name__")
end

--[[
    Walk from a class table up its inheritance chain, returning the
    next parent class or nil. Handles multiple class system conventions.
]]
local function _get_parent_class(tbl)
	local mt = getmetatable(tbl)
	if mt and type(mt) == "table" then
		local idx = rawget(mt, "__index")
		if type(idx) == "table" and idx ~= tbl then
			return idx
		end
	end
	local super = rawget(tbl, "super")
	if type(super) == "table" and super ~= tbl then
		return super
	end
	return nil
end

--[[
    Search a module's exported values for an unexported ancestor class.
    Walks the inheritance chain of each exported table to find a class
    whose name matches class_name.

    Returns the class table if found, nil otherwise.
]]
local function _find_ancestor_class(module, class_name)
	for _, value in pairs(module) do
		if type(value) ~= "table" then
			goto next_value
		end

		local current = value
		local visited = {}
		while current and type(current) == "table" do
			if visited[current] then
				break
			end
			visited[current] = true

			local name = _get_class_name(current)
			if name == class_name then
				return current
			end

			current = _get_parent_class(current)
		end

		::next_value::
	end
	return nil
end

-- ────────────────────────────────────────────────────────────
-- Nested-instance resolution & hooking
-- ────────────────────────────────────────────────────────────

--[[
    Walk the module → class → instance_field → key chain and return
    the container table, resolved key, original function, and bound instance.
    Raises on any missing link.
]]
local function _resolve_nested_target(parsed)
	local module = Utils.safe_import(parsed.module_path)
	if not module then
		error("Module not found: " .. parsed.module_path)
	end

	local class = module[parsed.class_name]
	if not class then
		error("Class not found: " .. parsed.class_name)
	end

	local instance_field = class[parsed.instance_field]
	if not instance_field then
		error("Instance field not found: " .. parsed.instance_field)
	end

	local key = parsed.instance_key
	if tonumber(key) then
		key = tonumber(key)
	end

	local original_value = instance_field[key]
	if not original_value then
		error("No value at [" .. tostring(key) .. "]")
	end

	-- Unpack direct function or [function, instance] tuple
	local original_fn, bound_instance
	local value_type = type(original_value)

	if value_type == "function" then
		original_fn = original_value
		bound_instance = nil
	elseif value_type == "table" or value_type == "list" then
		original_fn = original_value[1]
		bound_instance = original_value[2]

		if type(original_fn) ~= "function" then
			error("Expected [function, instance] tuple at [" .. tostring(key) .. "], but [1] is: " .. type(original_fn))
		end
	else
		error("Not a function or callable tuple at [" .. tostring(key) .. "]: " .. value_type)
	end

	return instance_field, key, original_fn, bound_instance
end

--[[
    Install a nested-instance hook: resolve the target, wrap the function,
    and store restoration metadata in the registry.
]]
local function _hook_nested_instance(hook_id, parsed, callbacks)
	local instance_field, key, original_fn, bound_instance = _resolve_nested_target(parsed)

	Reg.set("HOOK_ORIG_" .. hook_id, original_fn)

	_replace_fn_in_container(instance_field, key, _wrap_fn(original_fn, callbacks), bound_instance)

	Reg.set("HOOK_INFO_" .. hook_id, {
		type = "nested_instance",
		module_path = parsed.module_path,
		class_name = parsed.class_name,
		instance_field = parsed.instance_field,
		instance_key = key,
	})
end

-- ────────────────────────────────────────────────────────────
-- Public API
-- ────────────────────────────────────────────────────────────

--[[
    Create a new interceptor instance.

    @param specs: array - Method specs to hook. Each element can be:
        - string: "module:class:method" (uses default/global callback)
        - string: "module:class:instance_field:key" (nested instance hook)
        - table: {
            spec = "module:class:method" or "module:class:instance_field:key",
            post_exec = function(...) end,  -- optional
            enable_traceback = bool,  -- optional, overrides global setting
            override_orig_function = bool  -- optional, overrides global setting
          }
    @param options: table - {
        enable_traceback = bool (default: false),
        override_orig_function = bool (default: false) - When true, the wrapper
            does NOT call the original function automatically. Instead, orig_function
            is passed as the last argument to post_exec, letting the callback modify
            args, decide whether/when to call the original, and control the return value.
        post_exec = function(spec_info, args, results, traceback[, orig_function])
            - spec_info: {module_path, class_name, method_name}
            - args: packed table {n=count, [1]=..., [2]=...}
            - results: packed table {n=count, [1]=..., [2]=...}
            - traceback: string (if enable_traceback=true)
            - orig_function: the original function (only when override_orig_function=true)
    }
    @return interceptor instance
]]
function HookInterceptor.create(specs, options)
	options = options or {}

	local instance = {
		_hook_ids = {},
		_specs = specs or {},
		_options = options,
		_counter = 0,
	}

	setmetatable(instance, { __index = HookInterceptor })

	-- Auto-hook on creation
	instance:hook_all()

	return instance
end

--[[
    Hook all methods from specs.
]]
function HookInterceptor:hook_all()
	for _, spec_item in ipairs(self._specs) do
		local spec_str, custom_callback, per_method_traceback, override_orig = _normalize_spec_item(spec_item)
		if not spec_str then
			goto continue
		end

		local parsed, parse_err = _parse_spec(spec_str)
		if not parsed then
			_log("Failed to parse spec: " .. tostring(parse_err))
			goto continue
		end

		-- Generate unique hook ID
		self._counter = self._counter + 1
		local hook_suffix = parsed.method_name or (parsed.instance_field .. "_" .. parsed.instance_key)
		local hook_id = "interceptor_" .. self._counter .. "_" .. hook_suffix

		-- Determine traceback setting: per-method > global
		local should_traceback = per_method_traceback
		if should_traceback == nil then
			should_traceback = self._options.enable_traceback
		end

		-- Determine override setting: per-method > global
		if override_orig == nil then
			override_orig = self._options.override_orig_function
		end

		-- Build callbacks compatible with Hooks._make_wrapper
		local callbacks =
			_make_callbacks(parsed, custom_callback, self._options.post_exec, should_traceback, override_orig)

		-- Hook based on parsed type
		local success, hook_err

		if parsed.instance_field and parsed.instance_key then
			success, hook_err = pcall(_hook_nested_instance, hook_id, parsed, callbacks)
			if not success then
				hook_err = tostring(hook_err)
			end
		elseif parsed.class_name then
			success, hook_err =
				Hooks.hook_method(hook_id, parsed.module_path, parsed.class_name, parsed.method_name, callbacks)

			-- Fallback: class may be local (not exported) but reachable via inheritance
			if not success and hook_err and hook_err:find("Class not found") then
				local module = Utils.safe_import(parsed.module_path)
				if module then
					local ancestor = _find_ancestor_class(module, parsed.class_name)
					if ancestor then
						local original_fn = rawget(ancestor, parsed.method_name) or ancestor[parsed.method_name]
						if type(original_fn) == "function" then
							Reg.set("HOOK_ORIG_" .. hook_id, original_fn)
							rawset(ancestor, parsed.method_name, _wrap_fn(original_fn, callbacks))
							Reg.set("HOOK_INFO_" .. hook_id, {
								type = "direct_class",
								class_ref = ancestor,
								method_name = parsed.method_name,
							})
							success = true
							hook_err = nil
							_log("Resolved unexported class " .. parsed.class_name .. " via ancestor walk")
						else
							hook_err = "Method not found on ancestor class: "
								.. parsed.class_name
								.. ":"
								.. parsed.method_name
						end
					end
				end
			end
		else
			success, hook_err = Hooks.hook_function(hook_id, parsed.module_path, parsed.method_name, callbacks)
		end

		if success then
			table.insert(self._hook_ids, hook_id)
			_log("Hooked: " .. spec_str)
		else
			_log("Failed to hook " .. spec_str .. ": " .. tostring(hook_err))
		end

		::continue::
	end

	_log("Hooked " .. #self._hook_ids .. "/" .. #self._specs .. " methods")
end

--[[
    Unhook all registered hooks.
]]
function HookInterceptor:unhook_all()
	local count = 0
	for _, hook_id in ipairs(self._hook_ids) do
		local hook_info = Reg.get("HOOK_INFO_" .. hook_id)

		if hook_info and hook_info.type == "direct_class" then
			local original_fn = Reg.get("HOOK_ORIG_" .. hook_id)
			if original_fn and hook_info.class_ref then
				rawset(hook_info.class_ref, hook_info.method_name, original_fn)
				Reg.del("HOOK_ORIG_" .. hook_id)
				Reg.del("HOOK_INFO_" .. hook_id)
				count = count + 1
			end
		elseif hook_info and hook_info.type == "nested_instance" then
			pcall(function()
				local module = Utils.safe_import(hook_info.module_path)
				if module then
					local class = module[hook_info.class_name]
					if class then
						local instance_field = class[hook_info.instance_field]
						if instance_field then
							local original_fn = Reg.get("HOOK_ORIG_" .. hook_id)
							if original_fn then
								_restore_fn_in_container(instance_field, hook_info.instance_key, original_fn)
								Reg.del("HOOK_ORIG_" .. hook_id)
								Reg.del("HOOK_INFO_" .. hook_id)
								count = count + 1
							end
						end
					end
				end
			end)
		else
			local success = Hooks.unhook(hook_id)
			if success then
				count = count + 1
			end
		end
	end

	_log("Unhooked " .. count .. " methods")
	self._hook_ids = {}
end

--[[
    Check if interceptor is active.
]]
function HookInterceptor:is_active()
	return #self._hook_ids > 0
end

--[[
    Get list of hooked specs.
]]
function HookInterceptor:get_specs()
	return self._specs
end

-- Register globally
Reg.set("HookInterceptor", HookInterceptor)

return HookInterceptor
