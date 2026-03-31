--[[
    Logger - Simplified logging module

    Usage:
        Logger.log("message")                    -- writes to script_debug.txt
        Logger.log("message", "parry_debug")     -- writes to parry_debug.txt
]]
local Logger = {}

-- Private: Dependencies (set via init)
local _ROOT = _G.SCRIPTS_PATH
local _Constants = dofile(_ROOT .. "\\lib\\constants.lua")

-- State
Logger.is_enabled = true
Logger._file_handles = {} -- { filename = file_handle }

-- Private: Ensure directory exists (inline, no Utils dependency)
local function _ensure_dir(path)
	local cmd = string.format(
		"powershell -WindowStyle Hidden -Command \"if (!(Test-Path '%s')) { New-Item -ItemType Directory -Path '%s' -Force | Out-Null }\"",
		path,
		path
	)
	pcall(os.execute, cmd)
end

-- Private: Get or create log file handle
-- Returns: file_handle, error
local function _get_file(filename)
	filename = filename or "script_debug.txt"

	-- Add .txt extension if not present
	if not filename:match("%.txt$") then
		filename = filename .. ".txt"
	end

	-- Check if already open
	if Logger._file_handles[filename] then
		return Logger._file_handles[filename], nil
	end

	-- Build path and ensure directory exists
	local SCRIPTS_ROOT = _G.SCRIPTS_PATH
	if _Constants then
		SCRIPTS_ROOT = _Constants.SCRIPTS_ROOT
	end
	local logs_dir = SCRIPTS_ROOT .. "\\logs"
	_ensure_dir(logs_dir)

	local filepath = logs_dir .. "\\" .. filename

	-- Open file for append
	local f, err = io.open(filepath, "a")
	if f then
		Logger._file_handles[filename] = f
		return f, nil
	end

	return nil, err or "Failed to open file"
end

-- Private: Safe file write
-- Returns: success, error
local function _write_to_file(f, line)
	local ok, err = pcall(function()
		f:write(line)
		f:flush()
	end)
	if ok then
		return true, nil
	else
		return false, err
	end
end

-- Private: Safe file close
-- Returns: success, error
local function _close_file(f)
	local ok, err = pcall(function()
		f:close()
	end)
	if ok then
		return true, nil
	else
		return false, err
	end
end

-- Main log function
-- msg: string message to log
-- filename: optional filename (defaults to script_debug.txt)
-- Returns: success, error
function Logger.log(msg, filename)
	if not Logger.is_enabled then
		return true, nil
	end

	local f, err = _get_file(filename)
	if not f then
		return false, err
	end

	local line = string.format("[%s | %.3f] %s\n", os.date("%H:%M:%S"), os.clock(), tostring(msg))

	return _write_to_file(f, line)
end

-- Close all file handles
-- Returns: success_count
function Logger.close_all()
	local count = 0
	for filename, f in pairs(Logger._file_handles) do
		local ok, _ = _close_file(f)
		if ok then
			count = count + 1
		end
	end
	Logger._file_handles = {}
	return count
end

-- Close specific file handle
-- Returns: success, error
function Logger.close(filename)
	filename = filename or _Constants.DEFAULT_LOG_FILE
	if not filename:match("%.txt$") then
		filename = filename .. ".txt"
	end

	local f = Logger._file_handles[filename]
	if f then
		local ok, err = _close_file(f)
		Logger._file_handles[filename] = nil
		return ok, err
	end
	return true, nil -- Already closed
end

return Logger
