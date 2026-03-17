-- ============================================================
-- HOOKS.LUA - Low-level hook engine (INTERNAL - use HookManager instead)
-- ============================================================
-- Two hook types:
--   1. Function on module: module.function_name
--   2. Method on class: module.ClassName.method_name
--
-- HookManager is the public API. Do not call this directly from actions.

local Hooks = {}

local Logger = _G.Reg and _G.Reg.lib("Logger")
local function _log(msg)
	if Logger then
		Logger.log("[Hooks] " .. msg)
	end
end

-- ────────────────────────────────────────────────────────────
-- Wrapper construction
-- ────────────────────────────────────────────────────────────

function Hooks.make_wrapper(original_fn, callback_fn, options)
	options = options or {}
	local override = options.override_orig_function
	local traceback_enabled = options.enable_traceback
	local raise = options.raise_err
	local action_instance = options.action_instance

	return function(...)
		if override then
			-- MODE 1: callback has full control
			-- Signature: callback(action_instance, original_fn, ...)
			local ok, result = pcall(callback_fn, action_instance, original_fn, ...)
			if not ok then
				if raise then
					error(tostring(result))
				end
				_log("override callback error: " .. tostring(result))
				return nil
			end
			return result
		else
			-- MODE 2: call original, then observe
			local args = table.pack(...)
			local results = table.pack(original_fn(...))

			if callback_fn then
				local tb = traceback_enabled and debug.traceback("", 2) or nil
				local ok, err = pcall(callback_fn, action_instance, args, results, tb)
				if not ok then
					if raise then
						error(tostring(err))
					end
					_log("post_exec error: " .. tostring(err))
				end
			end

			return table.unpack(results, 1, results.n)
		end
	end
end

-- ────────────────────────────────────────────────────────────
-- Hook a module-level function
-- ────────────────────────────────────────────────────────────

function Hooks.hook_function(module_table, func_name, wrapper_fn)
	local ok, original_fn = pcall(rawget, module_table, func_name)
	if not ok or type(original_fn) ~= "function" then
		return nil, "Not a function: " .. tostring(func_name)
	end
	rawset(module_table, func_name, wrapper_fn)
	return original_fn
end

-- ────────────────────────────────────────────────────────────
-- Hook a method on a class
-- ────────────────────────────────────────────────────────────

function Hooks.hook_method(module_table, class_name, method_name, wrapper_fn)
	local ok_cls, class = pcall(rawget, module_table, class_name)
	if not ok_cls or not class then
		return nil, "Class not found: " .. tostring(class_name)
	end

	local ok_fn, original_fn = pcall(rawget, class, method_name)
	if not original_fn then
		-- Try through metatable/inheritance
		original_fn = class[method_name]
	end
	if not ok_fn or type(original_fn) ~= "function" then
		return nil, "Not a method: " .. tostring(class_name) .. "." .. tostring(method_name)
	end

	rawset(class, method_name, wrapper_fn)
	return original_fn
end

-- ────────────────────────────────────────────────────────────
-- Restore original function
-- ────────────────────────────────────────────────────────────

function Hooks.restore(target_table, target_key, original_fn)
	rawset(target_table, target_key, original_fn)
end

return Hooks
