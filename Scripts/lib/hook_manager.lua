-- ============================================================
-- HOOK_MANAGER.LUA - Centralized hook system (PUBLIC API)
-- ============================================================
-- The ONLY public hook API. Actions never call hooks.lua directly.
-- Auto-generates hook keys from module name.
-- Stores everything in Reg._ns("hooks").
--
-- Two hook types (auto-detected from spec):
--   3 parts "module:Class:method" → method hook
--   2 parts "module:function"     → function hook

local HookManager = {}

local Hooks -- loaded lazily to avoid circular dependency
local Logger

local function _hooks_ns()
	return _G.Reg._ns("hooks")
end

local function _reload_hooks_ns()
	return _G.Reg._ns("reload_hooks")
end

local function _get_hooks()
	Hooks = Hooks or (_G.Reg and _G.Reg.lib("Hooks"))
	return Hooks
end

local function _log(msg)
	Logger = Logger or (_G.Reg and _G.Reg.lib("Logger"))
	if Logger then
		Logger.log("[HookManager] " .. msg)
	end
end

-- ────────────────────────────────────────────────────────────
-- Spec parsing
-- ────────────────────────────────────────────────────────────

local function _parse_spec(spec)
	local parts = {}
	for part in spec:gmatch("[^:]+") do
		parts[#parts + 1] = part
	end
	if #parts == 2 then
		return { type = "function", module_path = parts[1], func_name = parts[2] }
	elseif #parts == 3 then
		return { type = "method", module_path = parts[1], class_name = parts[2], method_name = parts[3] }
	else
		return nil, "Invalid spec (expected 2 or 3 parts): " .. spec
	end
end

-- ────────────────────────────────────────────────────────────
-- Key generation
-- ────────────────────────────────────────────────────────────

local function _make_key(module_name, hook_name)
	return module_name .. "." .. hook_name
end

-- ────────────────────────────────────────────────────────────
-- Auto-derive module name from filepath
-- ────────────────────────────────────────────────────────────

function HookManager.derive_module_name(filepath)
	local scripts_root = "C:\\temp\\Where Winds Meet\\Scripts\\"
	-- Normalize separators
	local path = filepath:gsub("/", "\\")
	-- Strip scripts root
	if path:sub(1, #scripts_root) == scripts_root then
		path = path:sub(#scripts_root + 1)
	end
	-- Strip .lua extension
	path = path:gsub("%.lua$", "")
	-- Replace \ with .
	path = path:gsub("\\", ".")
	return path
end

-- ────────────────────────────────────────────────────────────
-- Registration
-- ────────────────────────────────────────────────────────────

function HookManager.register(module_name, hook_name, hook_def)
	local key = _make_key(module_name, hook_name)

	-- Parse spec to validate
	local parsed, err = _parse_spec(hook_def.spec)
	if not parsed then
		_log("Failed to register " .. key .. ": " .. tostring(err))
		return false, err
	end

	-- Preserve active state if re-registering in-process, or restore intent after bootstrap reload.
	local existing = _hooks_ns()[key]
	local restore_module = _reload_hooks_ns()[module_name]
	local was_active = (existing and existing.active) or (restore_module and restore_module[hook_name]) or false

	_hooks_ns()[key] = {
		module = module_name,
		hook_name = hook_name,
		spec = hook_def.spec,
		parsed = parsed,
		active = false, -- starts inactive, ActionBase decides
		def = hook_def,
		original = existing and existing.original or nil,
		target = existing and existing.target or nil,
		target_key = existing and existing.target_key or nil,
		was_active_before_reload = was_active,
	}

	return true
end

-- ────────────────────────────────────────────────────────────
-- Activation / Deactivation
-- ────────────────────────────────────────────────────────────

function HookManager.activate(module_name, hook_name, action_instance)
	local key = _make_key(module_name, hook_name)
	local entry = _hooks_ns()[key]
	if not entry then
		return false, "Hook not registered: " .. key
	end
	if entry.active then
		return true -- already active
	end

	local hooks = _get_hooks()
	if not hooks then
		return false, "Hooks engine not loaded"
	end

	local parsed = entry.parsed
	local def = entry.def

	-- Resolve module
	local mod = portable.safe_import(parsed.module_path)
	if not mod then
		return false, "Module not found: " .. parsed.module_path
	end

	-- Install hook based on type
	if parsed.type == "method" then
		local ok_cls, class = pcall(rawget, mod, parsed.class_name)
		if not ok_cls or not class then
			return false, "Class not found: " .. parsed.class_name
		end
		local ok_fn, orig = pcall(rawget, class, parsed.method_name)
		if not orig then
			orig = class[parsed.method_name]
		end
		if not ok_fn or type(orig) ~= "function" then
			return false, "Not a method: " .. parsed.class_name .. "." .. parsed.method_name
		end

		-- Use stored original if we have one (re-hook scenario)
		if entry.original then
			orig = entry.original
		end

		-- Build wrapper with the real original
		local wrapper = hooks.make_wrapper(orig, def.post_exec, {
			override_orig_function = def.override_orig_function,
			enable_traceback = def.enable_traceback,
			raise_err = def.raise_err,
			action_instance = action_instance,
		})

		rawset(class, parsed.method_name, wrapper)
		entry.original = orig
		entry.target = class
		entry.target_key = parsed.method_name
	elseif parsed.type == "function" then
		local ok_fn, orig = pcall(rawget, mod, parsed.func_name)
		if not ok_fn or type(orig) ~= "function" then
			return false, "Not a function: " .. parsed.func_name
		end

		if entry.original then
			orig = entry.original
		end

		local wrapper = hooks.make_wrapper(orig, def.post_exec, {
			override_orig_function = def.override_orig_function,
			enable_traceback = def.enable_traceback,
			raise_err = def.raise_err,
			action_instance = action_instance,
		})

		rawset(mod, parsed.func_name, wrapper)
		entry.original = orig
		entry.target = mod
		entry.target_key = parsed.func_name
	end

	entry.active = true
	_log("Activated: " .. key)
	return true
end

function HookManager.deactivate(module_name, hook_name)
	local key = _make_key(module_name, hook_name)
	local entry = _hooks_ns()[key]
	if not entry then
		return false, "Hook not registered: " .. key
	end
	if not entry.active then
		return true -- already inactive
	end

	local hooks = _get_hooks()

	-- Restore original
	if entry.original and entry.target and entry.target_key then
		hooks.restore(entry.target, entry.target_key, entry.original)
	end

	entry.active = false
	_log("Deactivated: " .. key)
	return true
end

-- ────────────────────────────────────────────────────────────
-- Query API
-- ────────────────────────────────────────────────────────────

function HookManager.is_active(module_name, hook_name)
	local key = _make_key(module_name, hook_name)
	local entry = _hooks_ns()[key]
	return entry and entry.active or false
end

function HookManager.get_all_active()
	local result = {}
	for key, entry in pairs(_hooks_ns()) do
		if entry.active then
			result[key] = entry
		end
	end
	return result
end

function HookManager.get_module_hooks(module_name)
	local result = {}
	for key, entry in pairs(_hooks_ns()) do
		if entry.module == module_name then
			result[entry.hook_name] = entry
		end
	end
	return result
end

function HookManager.get_module_active(module_name)
	local result = {}
	for key, entry in pairs(_hooks_ns()) do
		if entry.module == module_name and entry.active then
			result[entry.hook_name] = entry
		end
	end
	return result
end

function HookManager.list_modules()
	local seen = {}
	local result = {}
	for _, entry in pairs(_hooks_ns()) do
		if not seen[entry.module] then
			seen[entry.module] = true
			result[#result + 1] = entry.module
		end
	end
	table.sort(result)
	return result
end

-- ────────────────────────────────────────────────────────────
-- Batch operations
-- ────────────────────────────────────────────────────────────

function HookManager.activate_all(module_name, action_instance)
	local count = 0
	for key, entry in pairs(_hooks_ns()) do
		if entry.module == module_name and not entry.active then
			local ok = HookManager.activate(module_name, entry.hook_name, action_instance)
			if ok then
				count = count + 1
			end
		end
	end
	return count
end

function HookManager.deactivate_all(module_name)
	local count = 0
	for key, entry in pairs(_hooks_ns()) do
		if entry.module == module_name and entry.active then
			HookManager.deactivate(module_name, entry.hook_name)
			count = count + 1
		end
	end
	return count
end

function HookManager.deactivate_everything()
	local count = 0
	for key, entry in pairs(_hooks_ns()) do
		if entry.active then
			HookManager.deactivate(entry.module, entry.hook_name)
			count = count + 1
		end
	end
	_log("Deactivated everything: " .. count .. " hooks")
	return count
end

-- ────────────────────────────────────────────────────────────
-- Reload support (passive — ActionBase drives the flow)
-- ────────────────────────────────────────────────────────────

function HookManager.clear_module(module_name)
	local to_remove = {}
	for key, entry in pairs(_hooks_ns()) do
		if entry.module == module_name then
			if entry.active then
				HookManager.deactivate(module_name, entry.hook_name)
			end
			to_remove[#to_remove + 1] = key
		end
	end
	for _, key in ipairs(to_remove) do
		_hooks_ns()[key] = nil
	end
	_reload_hooks_ns()[module_name] = nil
end

function HookManager.get_previously_active(module_name)
	local result = {}
	for key, entry in pairs(_hooks_ns()) do
		if entry.module == module_name and entry.was_active_before_reload then
			result[#result + 1] = entry.hook_name
		end
	end
	return result
end

function HookManager.clear_previously_active(module_name)
	local reload_hooks = _reload_hooks_ns()
	reload_hooks[module_name] = nil
	for _, entry in pairs(_hooks_ns()) do
		if entry.module == module_name then
			entry.was_active_before_reload = false
		end
	end
end

return HookManager
