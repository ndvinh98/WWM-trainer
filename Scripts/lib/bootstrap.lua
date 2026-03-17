-- ============================================================
-- BOOTSTRAP.LUA - Initialize foundation modules into _G
-- ============================================================
-- Usage: dofile(SCRIPTS_ROOT .. "\\lib\\bootstrap.lua")
--
-- After loading:
--   local Reg = _G.Reg
--   local Logger = Reg.lib("Logger")
--   local HookManager = Reg.lib("HookManager")

local _ROOT = "C:\\temp\\Where Winds Meet\\Scripts"

-- Load constants first
local Constants = dofile(_ROOT .. "\\lib\\constants.lua")
local _PREFIX = Constants.GLOBAL_PREFIX or "KURO"
local _K_LIB = _PREFIX .. "_lib"
local _K_MOD = _PREFIX .. "_modules"
local _K_STATE = _PREFIX .. "_state"
local _K_HOOKS = _PREFIX .. "_hooks"
local _K_RELOAD_HOOKS = _PREFIX .. "_reload_hooks"

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

-- ── Namespace accessor (for core lib files that need raw table access) ──

local _NS_KEYS = {
	lib = _K_LIB,
	modules = _K_MOD,
	state = _K_STATE,
	hooks = _K_HOOKS,
	reload_hooks = _K_RELOAD_HOOKS,
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
end

-- ── Reload support ──

function Reg.reload_all()
	local log = _G[_K_LIB].Logger
	local function _log(msg)
		if log then log.log("[Reg.reload] " .. msg) end
	end

	-- 0. Snapshot active hooks by module/hook name only.
	local reload_hooks = {}
	for _, entry in pairs(_G[_K_HOOKS]) do
		if entry.active and entry.module and entry.hook_name then
			reload_hooks[entry.module] = reload_hooks[entry.module] or {}
			reload_hooks[entry.module][entry.hook_name] = true
		end
	end
	_G[_K_RELOAD_HOOKS] = reload_hooks

	-- 1. Log and deactivate all active hooks
	local HM = _G[_K_LIB].HookManager
	if HM then
		for key, entry in pairs(_G[_K_HOOKS]) do
			if entry.active then
				_log("Deactivating: " .. key .. " (spec: " .. tostring(entry.spec) .. ")")
			end
		end
		HM.deactivate_everything()
	end

	-- 2. Disable all modules (clear is_enabled in persistent state)
	for name, st in pairs(_G[_K_STATE]) do
		if type(st) == "table" and st.is_enabled then
			_log("Disabling module: " .. name)
			st.is_enabled = false
		end
	end

	-- 3. Clear module instances (re-created when action files are dofile'd)
	_G[_K_MOD] = {}

	-- 4. Clear hook registrations (originals already restored in step 1)
	_G[_K_HOOKS] = {}

	_log("Done. Re-dofile action modules to pick up changes.")
end

function Reg.restore_reloaded_modules()
	local log = _G[_K_LIB].Logger
	local function _log(msg)
		if log then log.log("[Reg.reload] " .. msg) end
	end

	local reload_hooks = _G[_K_RELOAD_HOOKS] or {}
	local modules = {}
	for module_name in pairs(reload_hooks) do
		modules[#modules + 1] = module_name
	end
	table.sort(modules)

	local restored = 0
	for _, module_name in ipairs(modules) do
		local rel_path = module_name:gsub("%.", "\\") .. ".lua"
		local full_path = _ROOT .. "\\" .. rel_path
		_log("Re-loading module for hook restore: " .. module_name)
		local ok, err = pcall(dofile, full_path)
		if ok then
			restored = restored + 1
		else
			_log("Failed to re-load module " .. module_name .. ": " .. tostring(err))
			reload_hooks[module_name] = nil
		end
	end

	if restored > 0 then
		_log("Re-loaded " .. restored .. " module(s) for hook restore")
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

if _is_reload then
	Reg.restore_reloaded_modules()
end

-- ============================================================
-- LEGACY UTILS SHIM (for UI components not yet migrated)
-- ============================================================

local Utils = {}

function Utils.safe_import(module_path)
	if type(module_path) == "table" then
		return module_path
	end
	local ok, mod = pcall(portable.safe_import, module_path)
	if ok and mod then
		return mod
	end
	return nil
end

function Utils.safe_dofile(path, label)
	local ok, result = pcall(dofile, path)
	if ok then
		return result
	end
	Logger.log("[Utils.shim] safe_dofile failed: " .. tostring(label) .. " - " .. tostring(result))
	return nil
end

function Utils.safe_call(label, fn, ...)
	local ok, result = pcall(fn, ...)
	if ok then
		return result
	end
	Logger.log("[Utils.shim] safe_call failed: " .. tostring(label) .. " - " .. tostring(result))
	return nil, result
end

function Utils.get_main_player()
	return G and G.main_player or nil
end

function Utils.dump_value(val, options)
	return Serialize.dump_value(val, options)
end

function Utils.create_empty_proxy()
	return Cocos.create_empty_proxy()
end

function Utils.delay_call(delay, fn)
	return Cocos.delay_call(delay, fn)
end

function Utils.get_running_scene()
	return Cocos.get_running_scene()
end

-- table.unpack alias for compatibility
Utils.unpack = table.unpack

Reg.set_lib("Utils", Utils)
Reg.set("Utils", Utils) -- legacy

-- ============================================================
-- REDIRECT PRINT TO LOGGER
-- ============================================================

_G.print = function(...)
	local n = select("#", ...)
	if n > 0 then
		local parts = {}
		for i = 1, n do
			parts[i] = tostring(select(i, ...))
		end
		Logger.log("[Print] " .. table.concat(parts, "\t"))
	end
end

-- ============================================================
-- MARK LOADED
-- ============================================================

Reg.set("VAR_LIB_LOADED", true)

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
