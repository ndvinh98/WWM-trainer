-- ============================================================
-- BOOTSTRAP.LUA - Load foundation modules once into _G
-- ============================================================
-- Usage: dofile(SCRIPTS_ROOT .. "\\lib\\bootstrap.lua")
--
-- After loading, use:
--   local Reg = _G.KURO_Reg
--   local Constants = Reg.get("Constants")
--   local Logger = Reg.get("Logger")
--
-- Or direct access (less flexible):
--   local Constants = _G.KURO_Constants
--
-- Naming convention:
--   _G.KURO_CamelCase  -> module/class
--   _G.KURO_snake_case -> function
--   _G.KURO_VAR_XXXX   -> runtime variable

local _ROOT = "C:\\temp\\Where Winds Meet\\Scripts"

-- Load constants first to get prefix
local Constants = dofile(_ROOT .. "\\lib\\constants.lua")
local _PREFIX = Constants.GLOBAL_PREFIX or "KURO"

-- ============================================================
-- REG MODULE - Global variable registry with prefix handling
-- ============================================================
-- Use this instead of direct _G.KURO_* access for flexibility

local Reg = {}

-- Get prefixed global name
function Reg.key(name)
    return _PREFIX .. "_" .. name
end

-- Get a global variable by name (without prefix)
-- Example: Reg.get("Constants") returns _G.KURO_Constants
function Reg.get(name)
    return _G[Reg.key(name)]
end

-- Set a global variable by name (without prefix)
-- Example: Reg.set("MyModule", module) sets _G.KURO_MyModule = module
function Reg.set(name, value)
    _G[Reg.key(name)] = value
end

-- Check if a global variable exists
function Reg.has(name)
    return _G[Reg.key(name)] ~= nil
end

-- Delete a global variable
function Reg.del(name)
    _G[Reg.key(name)] = nil
end

-- Get the current prefix
function Reg.prefix()
    return _PREFIX
end

-- List all registered globals with our prefix
function Reg.list_all()
    local result = {}
    local prefix = _PREFIX .. "_"
    for k, v in pairs(_G) do
        if type(k) == "string" and k:sub(1, #prefix) == prefix then
            local name = k:sub(#prefix + 1)
            result[name] = type(v)
        end
    end
    return result
end

-- ============================================================
-- RELOAD HANDLING
-- ============================================================

-- Check for force reload flag
local force_reload = true
if force_reload then
    Reg.del("VAR_FORCE_RELOAD")
    Reg.del("VAR_LIB_LOADED")
end

-- Only load once (unless force_reload was set)
if Reg.get("VAR_LIB_LOADED") then
    return {
        Reg = Reg.get("Reg"),
        Constants = Reg.get("Constants"),
        Logger = Reg.get("Logger"),
        Utils = Reg.get("Utils"),
        Hooks = Reg.get("Hooks")
    }
end

-- ============================================================
-- LOAD FOUNDATION MODULES
-- ============================================================

-- Register Reg module first (so other modules can use it)
_G.Reg = Reg

local _Logger = dofile(_ROOT .. "\\lib\\logger.lua")
local _Utils = dofile(_ROOT .. "\\lib\\utils.lua")
-- Register Constants
Reg.set("Constants", Constants)

-- Load and register Logger
Reg.set("Logger", _Logger)

-- Load and register Utils
Reg.set("Utils", _Utils)

-- Load and register Hooks (requires Utils to be initialized)
Reg.set("Hooks", dofile(_ROOT .. "\\lib\\hooks.lua"))
Reg.set("HookInterceptor", dofile(_ROOT .. "\\lib\\hook_interceptor.lua"))

-- ============================================================
-- MARK AS LOADED
-- ============================================================

Reg.set("VAR_LIB_LOADED", true)
Reg.set("VAR_PREFIX", _PREFIX)

_G.print = function(...)
    local n = select("#", ...)
    if n > 0 then
        local parts = {}
        for i = 1, n do
            parts[i] = tostring(select(i, ...))
        end
        _Logger.log("[Print] " .. table.concat(parts, "\t"))
    end
end

return {
    Reg = Reg,
    Constants = Constants,
    Logger = _Logger,
    Utils = _Utils
}
