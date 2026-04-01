-- ============================================================
-- BOOTSTRAP.LUA - Initialize foundation modules into _G
-- ============================================================
-- Usage: dofile(SCRIPTS_ROOT .. "\\lib\\bootstrap.lua")
--
-- After loading:
--   local Reg = _G.Reg
--   local Logger = Reg.lib("Logger")
--   local HookManager = Reg.lib("HookManager")

local _ROOT = _G.SCRIPTS_PATH

-- Load constants first
local Constants = dofile(_ROOT .. "\\lib\\constants.lua")
local _PREFIX = Constants.GLOBAL_PREFIX or "KURO"
local _K_LIB = _PREFIX .. "_lib"
local _K_MOD = _PREFIX .. "_modules"
local _K_STATE = _PREFIX .. "_state"
local _K_HOOKS = _PREFIX .. "_hooks"
local _K_RELOAD_HOOKS = _PREFIX .. "_reload_hooks"
local _K_RELOAD_ENABLED = _PREFIX .. "_reload_enabled"

-- ============================================================
-- RELOAD DETECTION (must run before namespace init)
-- ============================================================
local _is_reload = type(_G[_K_LIB]) == "table" and _G[_K_LIB].HookManager ~= nil

-- ============================================================
-- REG MODULE - Global registry with structured namespaces
-- ============================================================

local Reg = {}

-- Initialize global namespaces (preserve across reloads)
_G[_K_LIB] = _G[_K_LIB] or {}
_G[_K_MOD] = _G[_K_MOD] or {}
_G[_K_STATE] = _G[_K_STATE] or {}
_G[_K_HOOKS] = _G[_K_HOOKS] or {}
_G[_K_RELOAD_HOOKS] = _G[_K_RELOAD_HOOKS] or {}
_G[_K_RELOAD_ENABLED] = _G[_K_RELOAD_ENABLED] or {}

-- ── Namespace accessor (for core lib files that need raw table access) ──

local _NS_KEYS = {
	lib = _K_LIB,
	modules = _K_MOD,
	state = _K_STATE,
	hooks = _K_HOOKS,
	reload_hooks = _K_RELOAD_HOOKS,
	reload_enabled = _K_RELOAD_ENABLED,
}

function Reg._ns(name)
	return _G[_NS_KEYS[name]]
end

-- ── Structured accessors ──

function Reg.lib(name)
	return _G[_K_LIB][name]
end

function Reg.set_lib(name, value)
	_G[_K_LIB][name] = value
end

function Reg.module(name)
	return _G[_K_MOD][name]
end

function Reg.register_module(name, mod)
	_G[_K_MOD][name] = mod
end

function Reg.state(name)
	if not _G[_K_STATE][name] then
		_G[_K_STATE][name] = {}
	end
	return _G[_K_STATE][name]
end

function Reg.list_modules()
	local names = {}
	for name in pairs(_G[_K_MOD]) do
		names[#names + 1] = name
	end
	table.sort(names)
	return names
end

function Reg.reset_module(name)
	local mod = _G[_K_MOD][name]
	if mod and mod.disable then
		pcall(mod.disable, mod)
	end
	_G[_K_STATE][name] = nil
	_G[_K_RELOAD_HOOKS][name] = nil
	-- Deactivate hooks for this module
	local HookManager = _G[_K_LIB].HookManager
	if HookManager then
		HookManager.deactivate_all(name)
	end
	_G[_K_MOD][name] = nil
end

function Reg.reset_all()
	local HookManager = _G[_K_LIB].HookManager
	if HookManager then
		HookManager.deactivate_everything()
	end
	for name, mod in pairs(_G[_K_MOD]) do
		if mod.disable then
			pcall(mod.disable, mod)
		end
	end
	_G[_K_MOD] = {}
	_G[_K_STATE] = {}
	_G[_K_HOOKS] = {}
	_G[_K_RELOAD_HOOKS] = {}
	_G[_K_RELOAD_ENABLED] = {}
end

-- ── Reload support ──

function Reg.reload_all()
	local log = _G[_K_LIB].Logger
	local function _log(msg)
		if log then
			log.log("[Reg.reload] " .. msg)
		end
	end

	-- 0a. Identify reload-protected modules (e.g. anticheat_bypass)
	local protected = {}
	for name, st in pairs(_G[_K_STATE]) do
		if type(st) == "table" and st.reload_protected then
			protected[name] = true
			_log("Protected (skipping): " .. name)
		end
	end

	-- 0b. Snapshot active hooks for NON-protected modules only
	local reload_hooks = {}
	for _, entry in pairs(_G[_K_HOOKS]) do
		if entry.active and entry.module and entry.hook_name then
			if not protected[entry.module] then
				reload_hooks[entry.module] = reload_hooks[entry.module] or {}
				reload_hooks[entry.module][entry.hook_name] = true
			end
		end
	end
	_G[_K_RELOAD_HOOKS] = reload_hooks

	-- 0c. Snapshot enabled modules (handles both is_enabled and enabled flags)
	local reload_enabled = {}
	for name, st in pairs(_G[_K_STATE]) do
		if type(st) == "table" and not protected[name] then
			if st.is_enabled or st.enabled then
				reload_enabled[name] = true
				_log("Snapshot enabled: " .. name)
			end
		end
	end
	_G[_K_RELOAD_ENABLED] = reload_enabled

	-- 1. Deactivate NON-protected hooks only
	local HM = _G[_K_LIB].HookManager
	if HM then
		for key, entry in pairs(_G[_K_HOOKS]) do
			if entry.active and not protected[entry.module] then
				_log("Deactivating: " .. key .. " (spec: " .. tostring(entry.spec) .. ")")
				HM.deactivate(entry.module, entry.hook_name)
			end
		end
	end

	-- 2. Disable NON-protected modules
	for name, st in pairs(_G[_K_STATE]) do
		if type(st) == "table" and not protected[name] then
			if st.is_enabled then
				_log("Disabling module: " .. name)
				st.is_enabled = false
			end
			if st.enabled then
				_log("Disabling module (enabled flag): " .. name)
				st.enabled = false
			end
		end
	end

	-- 3. Clear module instances, preserving protected
	local kept_mods = {}
	for name, mod in pairs(_G[_K_MOD]) do
		if protected[name] then
			kept_mods[name] = mod
		end
	end
	_G[_K_MOD] = kept_mods

	-- 4. Clear hook registrations, preserving protected
	local kept_hooks = {}
	for key, entry in pairs(_G[_K_HOOKS]) do
		if protected[entry.module] then
			kept_hooks[key] = entry
		end
	end
	_G[_K_HOOKS] = kept_hooks

	_log("Done. Re-dofile action modules to pick up changes.")
end

function Reg.restore_reloaded_modules()
	local log = _G[_K_LIB].Logger
	local function _log(msg)
		if log then
			log.log("[Reg.reload] " .. msg)
		end
	end

	-- Merge modules needing reload: those with hooks OR those that were enabled
	local reload_hooks = _G[_K_RELOAD_HOOKS] or {}
	local reload_enabled = _G[_K_RELOAD_ENABLED] or {}
	local need_reload = {}
	for module_name in pairs(reload_hooks) do
		need_reload[module_name] = true
	end
	for module_name in pairs(reload_enabled) do
		need_reload[module_name] = true
	end

	local modules = {}
	for module_name in pairs(need_reload) do
		modules[#modules + 1] = module_name
	end
	table.sort(modules)

	-- Re-load all modules that need it
	local restored = 0
	for _, module_name in ipairs(modules) do
		local rel_path = module_name:gsub("%.", "\\") .. ".lua"
		local full_path = _ROOT .. "\\" .. rel_path
		_log("Re-loading module: " .. module_name)
		local ok, err = pcall(dofile, full_path)
		if ok then
			restored = restored + 1
		else
			_log("Failed to re-load module " .. module_name .. ": " .. tostring(err))
			reload_hooks[module_name] = nil
			reload_enabled[module_name] = nil
		end
	end

	-- Re-enable modules that were previously enabled
	for module_name in pairs(reload_enabled) do
		local mod = _G[_K_MOD][module_name]
		if mod and mod.enable then
			_log("Re-enabling module: " .. module_name)
			local ok, err = pcall(mod.enable, mod)
			if not ok then
				_log("Failed to re-enable " .. module_name .. ": " .. tostring(err))
			end
		end
	end
	_G[_K_RELOAD_ENABLED] = {}

	if restored > 0 then
		_log("Re-loaded " .. restored .. " module(s) for reload restore")
	end

	return restored
end

-- ── Legacy accessors (kept for migration) ──

function Reg.key(name)
	return _PREFIX .. "_" .. name
end

function Reg.get(name)
	-- Check new namespaces first
	if _G[_K_LIB][name] then
		return _G[_K_LIB][name]
	end
	if _G[_K_MOD][name] then
		return _G[_K_MOD][name]
	end
	-- Fall back to flat _G
	return _G[Reg.key(name)]
end

function Reg.set(name, value)
	_G[Reg.key(name)] = value
end

function Reg.has(name)
	return _G[Reg.key(name)] ~= nil
end

function Reg.del(name)
	_G[Reg.key(name)] = nil
end

function Reg.prefix()
	return _PREFIX
end

function Reg.list_all()
	local result = {}
	local prefix = _PREFIX .. "_"
	for k, v in pairs(_G) do
		if type(k) == "string" and k:sub(1, #prefix) == prefix then
			result[k:sub(#prefix + 1)] = type(v)
		end
	end
	return result
end

-- ============================================================
-- LOAD FOUNDATION MODULES
-- ============================================================

-- Make Reg globally available
_G.Reg = Reg

-- ── Reload cleanup (run BEFORE re-loading libs, while old HookManager is still functional) ──
if _is_reload then
	Reg.reload_all()
end

-- Register Constants
Reg.set_lib("Constants", Constants)
Reg.set("Constants", Constants) -- legacy

-- Load Logger
local Logger = dofile(_ROOT .. "\\lib\\logger.lua")
Reg.set_lib("Logger", Logger)
Reg.set("Logger", Logger) -- legacy

-- Load Serialize
local Serialize = dofile(_ROOT .. "\\lib\\serialize.lua")
Reg.set_lib("Serialize", Serialize)

-- Load Cocos
local Cocos = dofile(_ROOT .. "\\lib\\cocos.lua")
Reg.set_lib("Cocos", Cocos)

-- Load Hooks (internal engine)
local Hooks = dofile(_ROOT .. "\\lib\\hooks.lua")
Reg.set_lib("Hooks", Hooks)
Reg.set("Hooks", Hooks) -- legacy

-- Load HookManager (public API)
local HookManager = dofile(_ROOT .. "\\lib\\hook_manager.lua")
Reg.set_lib("HookManager", HookManager)

-- Load ActionBase
local ActionBase = dofile(_ROOT .. "\\lib\\action_base.lua")
Reg.set_lib("ActionBase", ActionBase)

-- Load TypeUtils
local TypeUtils = dofile(_ROOT .. "\\lib\\type_utils.lua")
Reg.set_lib("TypeUtils", TypeUtils)

if _is_reload then
	Reg.restore_reloaded_modules()
end

-- ============================================================
-- REDIRECT PRINT TO LOGGER
-- ============================================================
_G.print_file = "print.txt"
_G.print = function(...)
	local n = select("#", ...)
	if n > 0 then
		local parts = {}
		for i = 1, n do
			parts[i] = tostring(select(i, ...))
		end
		Logger.log("[Print] " .. table.concat(parts, "\t"), _G.print_file)
	end
end

-- ============================================================
-- MARK LOADED
-- ============================================================

if _is_reload then
	Logger.log("[Bootstrap] Reload complete.")
else
	Logger.log("[Bootstrap] Initial load complete.")
end

return {
	Reg = Reg,
	Constants = Constants,
	Logger = Logger,
}
