--[[
    Constants - Base configuration paths and global prefix
    All other paths are created dynamically using Utils.ensure_dir()
]]

local Constants = {}

-- Global variable prefix (change this to change all _G.KURO_* references)
Constants.GLOBAL_PREFIX = "KURO"

-- Base path (auto-detect from current script location if possible)
Constants.SCRIPTS_ROOT = "C:\\temp\\Where Winds Meet\\Scripts"

-- Derived paths
Constants.LIB_ROOT = Constants.SCRIPTS_ROOT .. "\\lib"
Constants.ACTIONS_ROOT = Constants.SCRIPTS_ROOT .. "\\actions"
Constants.UI_ROOT = Constants.SCRIPTS_ROOT .. "\\ui"
Constants.DATA_ROOT = Constants.SCRIPTS_ROOT .. "\\data"
Constants.LOGS_ROOT = Constants.SCRIPTS_ROOT .. "\\logs"

-- Output paths
Constants.LUA_DEBUGGING_ROOT = "C:\\temp\\Where Winds Meet\\Scripts\\dumped"
Constants.TRACES_ROOT = Constants.SCRIPTS_ROOT .. "\\traces"

-- Default log filename (used by Logger when no filename specified)
Constants.DEFAULT_LOG_FILE = "script_debug.txt"

return Constants
