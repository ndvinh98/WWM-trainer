--[[
    Trace - Call Tracing Actions
    
    Provides:
    - start: Start call tracing
    - stop: Stop tracing and save files
    - toggle: Toggle tracing on/off
    - is_enabled: Check if tracing is active
    - get_output_path: Get trace output directory
    
    Prerequisites: Bootstrap must be loaded first
]]

local ActionBase = _G.Reg.lib("ActionBase")

local Trace = ActionBase:extend("actions.trace")

function Trace:define_state()
	return {
		persistent = {},
		transient = { _core = nil },
	}
end

function Trace:define_hooks()
	return {}
end

-- Lazy load core module
function Trace:_get_core()
	if not self.state._core then
		local Constants = _G.Reg.lib("Constants")
		local lib_root = Constants and Constants.LIB_ROOT or "C:\\temp\\Where Winds Meet\\Scripts\\lib\\"
		local ok, core = pcall(dofile, lib_root .. "trace_core.lua")
		if ok and core then
			self.state._core = core
		end
	end
	return self.state._core
end

-- ============================================================
-- PUBLIC API
-- ============================================================

-- Start tracing
function Trace:start(options)
	self:log("Starting trace...")

	local core = self:_get_core()
	if not core or not core.start then
		self:log("TraceCore not loaded")
		return false, "TraceCore not loaded"
	end

	local ok, err = core.start(options)
	if ok then
		self:log("Started - output: " .. core.get_output_path())
	else
		self:log("Failed: " .. tostring(err))
	end

	return ok, err
end

-- Stop tracing
function Trace:stop()
	self:log("Stopping trace...")

	local core = self:_get_core()
	if not core or not core.stop then
		-- Fallback: try to clear debug hook directly
		if debug and debug.sethook then
			debug.sethook()
		end
		return true, "Stopped (fallback)"
	end

	local ok, msg = core.stop()
	self:log(msg or "Stopped")

	return ok, msg
end

-- Toggle tracing
function Trace:toggle(enabled)
	if enabled then
		return self:start()
	else
		return self:stop()
	end
end

-- Check if enabled
function Trace:is_enabled()
	local core = self:_get_core()
	if core and core.is_enabled then
		return core.is_enabled()
	end
	return false
end

-- Get output path
function Trace:get_output_path()
	local core = self:_get_core()
	if core and core.get_output_path then
		return core.get_output_path()
	end
	local Constants = _G.Reg.lib("Constants")
	return Constants and (Constants.SCRIPTS_ROOT .. "\\traces") or "C:\\temp\\Where Winds Meet\\Scripts\\traces"
end

-- Get stats
function Trace:get_stats()
	local core = self:_get_core()
	if core and core.get_stats then
		return core.get_stats()
	end
	return { is_enabled = false, call_sequence = 0, file_count = 0 }
end

-- Get raw core module (for advanced use)
function Trace:get_core()
	return self:_get_core()
end

-- Set output format ("readable" or "json")
function Trace:set_format(format)
	local core = self:_get_core()
	if core and core.set_format then
		local ok, msg = core.set_format(format)
		if ok then
			self:log(msg)
		end
		return ok, msg
	end
	return false, "TraceCore not loaded"
end

-- Get current format
function Trace:get_format()
	local core = self:_get_core()
	if core and core.get_format then
		return core.get_format()
	end
	return "readable"
end

return Trace:new()
