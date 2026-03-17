-- ============================================================
-- ACTION_BASE.LUA - Abstract base class for all action modules
-- ============================================================
-- Provides: OOP inheritance, state lifecycle (persistent/transient),
-- hook management via HookManager, logging, reload support.
--
-- Usage:
--   local ActionBase = Reg.lib("ActionBase")
--   local Combat = ActionBase:extend("actions.combat")
--   function Combat:define_hooks() return { ... } end
--   function Combat:define_state() return { persistent = {...}, transient = {...} } end
--   return Combat:new()

local ActionBase = {}
ActionBase.__index = ActionBase

local Logger
local HookManager

local function _get_logger()
	Logger = Logger or (_G.Reg and _G.Reg.lib("Logger"))
	return Logger
end

local function _get_hook_manager()
	HookManager = HookManager or (_G.Reg and _G.Reg.lib("HookManager"))
	return HookManager
end

-- ────────────────────────────────────────────────────────────
-- Subclassing
-- ────────────────────────────────────────────────────────────

function ActionBase:extend(name)
	if not name then
		error("ActionBase:extend() requires a name, e.g. 'actions.combat'")
	end
	local cls = setmetatable({}, { __index = self })
	cls.__index = cls
	cls._name = name
	return cls
end

-- ────────────────────────────────────────────────────────────
-- Constructor
-- ────────────────────────────────────────────────────────────

function ActionBase:new()
	local instance = setmetatable({}, { __index = self })
	instance._name = self._name

	-- 1. Initialize state (persistent survives reload, transient resets)
	instance:_init_state()

	-- 2. Register hooks from define_hooks() into HookManager
	instance:_register_hooks()

	-- 3. Re-activate hooks that were active before reload
	instance:_restore_hooks()

	-- 4. Register in global module table
	_G.Reg.register_module(instance._name, instance)

	instance:log("Module loaded")
	return instance
end

-- ────────────────────────────────────────────────────────────
-- ABSTRACT: subclass should override
-- ────────────────────────────────────────────────────────────

function ActionBase:define_hooks()
	return {}
end

function ActionBase:define_state()
	return { persistent = {}, transient = {} }
end

-- ────────────────────────────────────────────────────────────
-- OPTIONAL: subclass can override
-- ────────────────────────────────────────────────────────────

function ActionBase:on_enable() end
function ActionBase:on_disable() end
function ActionBase:on_reload() end

-- ────────────────────────────────────────────────────────────
-- State management (INTERNAL)
-- ────────────────────────────────────────────────────────────

function ActionBase:_init_state()
	local def = self:define_state()
	local persistent = def.persistent or {}
	local transient = def.transient or {}

	-- Get or create state table via Reg
	local state_ns = _G.Reg._ns("state")
	local existing = state_ns[self._name]
	if not existing then
		-- First load: merge persistent + transient defaults
		local state = {}
		for k, v in pairs(persistent) do
			state[k] = v
		end
		for k, v in pairs(transient) do
			state[k] = v
		end
		state_ns[self._name] = state
		self.state = state_ns[self._name]
	else
		-- Reload: keep persistent, reset transient
		for k, v in pairs(transient) do
			existing[k] = v -- always reset transient to defaults
		end
		-- Init any new persistent keys that don't exist yet
		for k, v in pairs(persistent) do
			if existing[k] == nil then
				existing[k] = v
			end
		end
		self.state = existing
	end

	-- Store transient key names for future reloads
	self._transient_keys = {}
	for k in pairs(transient) do
		self._transient_keys[k] = true
	end
end

-- ────────────────────────────────────────────────────────────
-- Hook management
-- ────────────────────────────────────────────────────────────

function ActionBase:_register_hooks()
	local hm = _get_hook_manager()
	if not hm then
		return
	end

	local hooks = self:define_hooks()
	for hook_name, hook_def in pairs(hooks) do
		hm.register(self._name, hook_name, hook_def)
	end
end

function ActionBase:_restore_hooks()
	local hm = _get_hook_manager()
	if not hm then
		return
	end

	local previously_active = hm.get_previously_active(self._name)
	if #previously_active > 0 then
		self:log("Restoring " .. #previously_active .. " hooks from previous session")
		for _, hook_name in ipairs(previously_active) do
			hm.activate(self._name, hook_name, self)
		end
	end
	hm.clear_previously_active(self._name)
end

-- Individual hook control
function ActionBase:hook(name)
	local hm = _get_hook_manager()
	if not hm then
		return false, "HookManager not loaded"
	end
	return hm.activate(self._name, name, self)
end

function ActionBase:unhook(name)
	local hm = _get_hook_manager()
	if not hm then
		return false, "HookManager not loaded"
	end
	return hm.deactivate(self._name, name)
end

function ActionBase:is_hooked(name)
	local hm = _get_hook_manager()
	if not hm then
		return false
	end
	return hm.is_active(self._name, name)
end

-- Batch hook control
function ActionBase:hook_all()
	local hm = _get_hook_manager()
	if not hm then
		return 0
	end
	return hm.activate_all(self._name, self)
end

function ActionBase:unhook_all()
	local hm = _get_hook_manager()
	if not hm then
		return 0
	end
	return hm.deactivate_all(self._name)
end

function ActionBase:hook_many(...)
	local hm = _get_hook_manager()
	if not hm then
		return 0
	end
	local count = 0
	for _, name in ipairs({ ... }) do
		local ok = hm.activate(self._name, name, self)
		if ok then
			count = count + 1
		end
	end
	return count
end

-- Query
function ActionBase:get_active_hooks()
	local hm = _get_hook_manager()
	if not hm then
		return {}
	end
	return hm.get_module_active(self._name)
end

function ActionBase:get_all_hooks()
	return self:define_hooks()
end

-- ────────────────────────────────────────────────────────────
-- Module lifecycle
-- ────────────────────────────────────────────────────────────

function ActionBase:enable()
	self.state.is_enabled = true
	self:on_enable()
	self:log("Enabled")
	return true
end

function ActionBase:disable()
	self:unhook_all()
	self.state.is_enabled = false
	self:on_disable()
	self:log("Disabled")
	return true
end

function ActionBase:is_enabled()
	return self.state.is_enabled == true
end

function ActionBase:toggle()
	if self:is_enabled() then
		return self:disable()
	else
		return self:enable()
	end
end

function ActionBase:reload()
	-- 1. Snapshot active hooks
	local hm = _get_hook_manager()
	local active_hooks = {}
	if hm then
		local active = hm.get_module_active(self._name)
		for name in pairs(active) do
			active_hooks[#active_hooks + 1] = name
		end
	end

	-- 2. Unhook all
	self:unhook_all()

	-- 3. Reset transient state
	local def = self:define_state()
	local transient = def.transient or {}
	for k, v in pairs(transient) do
		self.state[k] = v
	end

	-- 4. Re-register hooks (fresh callbacks)
	self:_register_hooks()

	-- 5. Re-activate previously active hooks
	if hm then
		for _, name in ipairs(active_hooks) do
			hm.activate(self._name, name, self)
		end
	end

	-- 6. Callback
	self:on_reload()
	self:log("Reloaded with " .. #active_hooks .. " active hooks")
end

-- ────────────────────────────────────────────────────────────
-- Logging
-- ────────────────────────────────────────────────────────────

function ActionBase:log(msg)
	local logger = _get_logger()
	if logger then
		logger.log("[" .. self._name .. "] " .. msg)
	end
end

return ActionBase
