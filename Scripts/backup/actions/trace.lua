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

local Trace = {}

-- Reference libs via Reg (loaded once by bootstrap)
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Utils = Reg.get("Utils")

local function _log(msg)
	Logger.log("[Trace] " .. msg)
end

-- Lazy load core module
local _core = nil
local function get_core()
	if not _core then
		_core = Utils.safe_dofile(Constants.LIB_ROOT .. "\\trace_core.lua", "TraceCore")
	end
	return _core
end

-- ============================================================
-- PUBLIC API
-- ============================================================

-- Start tracing
function Trace.start(options)
	_log("Starting trace...")

	local core = get_core()
	if not core or not core.start then
		_log("TraceCore not loaded")
		return false, "TraceCore not loaded"
	end

	local ok, err = core.start(options)
	if ok then
		_log("Started - output: " .. core.get_output_path())
	else
		_log("Failed: " .. tostring(err))
	end

	return ok, err
end

-- Stop tracing
function Trace.stop()
	_log("Stopping trace...")

	local core = get_core()
	if not core or not core.stop then
		-- Fallback: try to clear debug hook directly
		if debug and debug.sethook then
			debug.sethook()
		end
		return true, "Stopped (fallback)"
	end

	local ok, msg = core.stop()
	_log(msg or "Stopped")

	return ok, msg
end

-- Toggle tracing
function Trace.toggle(enabled)
	if enabled then
		return Trace.start()
	else
		return Trace.stop()
	end
end

-- Check if enabled
function Trace.is_enabled()
	local core = get_core()
	if core and core.is_enabled then
		return core.is_enabled()
	end
	return false
end

-- Get output path
function Trace.get_output_path()
	local core = get_core()
	if core and core.get_output_path then
		return core.get_output_path()
	end
	return Constants.SCRIPTS_ROOT .. "\\traces"
end

-- Get stats
function Trace.get_stats()
	local core = get_core()
	if core and core.get_stats then
		return core.get_stats()
	end
	return { is_enabled = false, call_sequence = 0, file_count = 0 }
end

-- Get raw core module (for advanced use)
function Trace.get_core()
	return get_core()
end

-- Set output format ("readable" or "json")
function Trace.set_format(format)
	local core = get_core()
	if core and core.set_format then
		local ok, msg = core.set_format(format)
		if ok then
			_log(msg)
		end
		return ok, msg
	end
	return false, "TraceCore not loaded"
end

-- Get current format
function Trace.get_format()
	local core = get_core()
	if core and core.get_format then
		return core.get_format()
	end
	return "readable"
end

-- ============================================================
-- LEGACY API (for backwards compatibility)
-- ============================================================
Trace.Start = Trace.start
Trace.Stop = Trace.stop
Trace.Toggle = Trace.toggle

return Trace
