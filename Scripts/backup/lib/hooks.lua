-- ============================================================
-- HOOKS.LUA - Simple hook management system
-- ============================================================

local Hooks = {}

local Reg = _G.Reg
local Utils = Reg.get("Utils")
local Logger = Reg.get("Logger")

local REGISTRY_NAME = "HOOKS_REGISTRY"
local ORIG_PREFIX = "HOOK_ORIG_"

-- ────────────────────────────────────────────────────────────
-- Internal helpers
-- ────────────────────────────────────────────────────────────

local function _log(msg)
    if Logger then
        Logger.log("[Hooks] " .. msg)
    end
end

local function _get_registry()
    if not Reg.has(REGISTRY_NAME) then
        Reg.set(REGISTRY_NAME, {})
    end
    return Reg.get(REGISTRY_NAME)
end

local function _get_orig(hook_id)
    return Reg.get(ORIG_PREFIX .. hook_id)
end

local function _set_orig(hook_id, fn)
    Reg.set(ORIG_PREFIX .. hook_id, fn)
end

local function _del_orig(hook_id)
    Reg.del(ORIG_PREFIX .. hook_id)
end

--[[
    Resolve the original function for a hook, handling re-hook scenarios.
    On first hook: stores original_fn and returns it.
    On re-hook (original already stored): returns the stored original.
]]
local function _resolve_original(hook_id, original_fn)
    local stored = _get_orig(hook_id)
    if not stored then
        _set_orig(hook_id, original_fn)
        return original_fn
    end
    return stored
end

-- ────────────────────────────────────────────────────────────
-- Wrapper construction
-- ────────────────────────────────────────────────────────────

--[[
    Build wrapper with callbacks.
    Handles: nil args, varying arg counts, multiple return values.
]]
local function _make_wrapper(original_fn, callbacks)
    return function(...)
        -- Override mode - full control, user handles everything
        if callbacks.override_exec then
            return callbacks.override_exec(original_fn, ...)
        end

        local args = table.pack(...) -- keeps nils + count
        local results = table.pack(original_fn(...)) -- keeps nils + count

        if callbacks.post_exec then
            local tb = debug.traceback("", 1)
            local ok, err = pcall(callbacks.post_exec, args, results, tb)
            if not ok then
                if callbacks.raise_err then
                    error(tostring(err))
                end
                _log("post_exec error: " .. tostring(err))
            end
        end

        return table.unpack(results, 1, results.n)
    end
end

-- ────────────────────────────────────────────────────────────
-- Restore logic (shared by unhook and _restore_on_load)
-- ────────────────────────────────────────────────────────────

--[[
    Restore the original function for a single hook entry.
    Returns true if restoration succeeded, false otherwise.
]]
local function _restore_original(info, original_fn)
    if info.type == "instance" then
        if info.instance then
            rawset(info.instance, info.method_name, original_fn)
            return true
        end
    else
        local module = Utils.safe_import(info.module_path)
        if not module then
            return false
        end

        if info.type == "function" then
            rawset(module, info.func_name, original_fn)
            return true
        elseif info.type == "method" then
            local ok, class = pcall(rawget, module, info.class_name)
            if ok and class then
                rawset(class, info.method_name, original_fn)
                return true
            end
        end
    end

    return false
end

-- ────────────────────────────────────────────────────────────
-- Public API: Hooking
-- ────────────────────────────────────────────────────────────

--[[
    Hook a module-level function: module.function_name

    @param hook_id: string - Unique identifier
    @param module_path: string|table - Module path or table
    @param func_name: string - Function name in module
    @param callbacks: table - {pre_exec, post_exec, override_exec}
    @return success, error
]]
function Hooks.hook_function(hook_id, module_path, func_name, callbacks)
    if not hook_id or not func_name or not callbacks then
        return false, "Missing required parameters"
    end

    local registry = _get_registry()
    if registry[hook_id] then
        _log("Hook '" .. hook_id .. "' already registered")
        return true
    end

    local module = Utils.safe_import(module_path)
    if not module then
        return false, "Could not resolve module: " .. tostring(module_path)
    end

    local ok, original_fn = pcall(rawget, module, func_name)
    if not ok or type(original_fn) ~= "function" then
        return false, "Not a function: " ..
            func_name .. " - Type: " .. type(original_fn) .. " - Module: " .. tostring(module)
    end

    original_fn = _resolve_original(hook_id, original_fn)

    rawset(module, func_name, _make_wrapper(original_fn, callbacks))

    registry[hook_id] = {
        type = "function",
        module_path = module_path,
        func_name = func_name
    }

    _log("Hooked function: " .. hook_id)
    return true
end

--[[
    Hook a class method: module.ClassName.method_name

    @param hook_id: string - Unique identifier
    @param module_path: string|table - Module path or table
    @param class_name: string - Class name in module
    @param method_name: string - Method name in class
    @param callbacks: table - {pre_exec, post_exec, override_exec}
    @return success, error
]]
function Hooks.hook_method(hook_id, module_path, class_name, method_name, callbacks)
    if not hook_id or not class_name or not method_name or not callbacks then
        return false, "Missing required parameters"
    end

    local registry = _get_registry()
    if registry[hook_id] then
        _log("Hook '" .. hook_id .. "' already registered")
        return true
    end

    local module = Utils.safe_import(module_path)
    if not module then
        return false, "Could not resolve module: " .. tostring(module_path)
    end

    local ok_cls, class = pcall(rawget, module, class_name)
    if not ok_cls or not class then
        return false, "Class not found: " .. class_name
    end

    local ok_fn, original_fn = pcall(rawget, class, method_name)
    if not original_fn then
        original_fn = class[method_name]
    end
    if not ok_fn or type(original_fn) ~= "function" then
        return false, "Not a method: " .. class_name .. "." .. method_name .. " - Result: " .. tostring(ok_fn)
    end

    original_fn = _resolve_original(hook_id, original_fn)

    rawset(class, method_name, _make_wrapper(original_fn, callbacks))

    registry[hook_id] = {
        type = "method",
        module_path = module_path,
        class_name = class_name,
        method_name = method_name
    }

    _log("Hooked method: " .. hook_id)
    return true
end

--[[
    Hook an instance method: instance:method_name(...)

    This hooks a method on a SPECIFIC instance, not the entire class.
    For example: hook main_player:get_pos() without affecting other Avatar instances.

    @param hook_id: string - Unique identifier
    @param instance: table - The instance object (e.g., main_player)
    @param method_name: string - Method name to hook (e.g., "get_pos")
    @param callbacks: table - {pre_exec, post_exec, override_exec}
    @return success, error

    Example:
        Hooks.hook_instance_method("player_pos_hook", main_player, "get_pos", {
            post_exec = function(args, results, traceback)
                print("Player position:", results[1], results[2], results[3])
            end
        })
]]
function Hooks.hook_instance_method(hook_id, instance, method_name, callbacks)
    local registry = _get_registry()
    if registry[hook_id] then
        _log("Hook '" .. hook_id .. "' already registered")
        return true
    end

    -- Read through __index to find inherited methods
    local original_fn = instance[method_name]

    original_fn = _resolve_original(hook_id, original_fn)

    -- Shadow on the instance directly, bypassing __newindex
    rawset(instance, method_name, _make_wrapper(original_fn, callbacks))

    registry[hook_id] = {
        type = "instance",
        instance = instance,
        method_name = method_name
    }
    return true
end

-- ────────────────────────────────────────────────────────────
-- Public API: Unhooking
-- ────────────────────────────────────────────────────────────

--[[
    Unhook and restore original function.
]]
function Hooks.unhook(hook_id)
    local registry = _get_registry()
    local info = registry[hook_id]
    if not info then
        return false, "Hook not found"
    end

    local original_fn = _get_orig(hook_id)
    if not original_fn then
        return false, "Original not found"
    end

    _restore_original(info, original_fn)

    registry[hook_id] = nil
    _del_orig(hook_id)
    _log("Unhooked: " .. hook_id)
    return true
end

--[[
    Unhook all registered hooks.
]]
function Hooks.unhook_all()
    local registry = _get_registry()
    local ids = {}
    for id in pairs(registry) do
        table.insert(ids, id)
    end
    for _, id in ipairs(ids) do
        Hooks.unhook(id)
    end
    _log("Unhooked all (" .. #ids .. ")")
end

-- ────────────────────────────────────────────────────────────
-- Public API: Queries
-- ────────────────────────────────────────────────────────────

--[[
    Get original function for a hook.
]]
function Hooks.get_original(hook_id)
    return _get_orig(hook_id)
end

--[[
    Check if hook is registered.
]]
function Hooks.is_hooked(hook_id)
    return _get_registry()[hook_id] ~= nil
end

--[[
    List all hooks.
]]
function Hooks.list_hooks()
    return _get_registry()
end

-- ============================================================
-- AUTO-RESTORE ON LOAD
-- ============================================================
-- If script reloads but Reg still has originals, restore them first

local function _restore_on_load()
    local registry = _get_registry()
    local restored = 0

    for hook_id, info in pairs(registry) do
        local original_fn = _get_orig(hook_id)

        if original_fn then
            if _restore_original(info, original_fn) then
                restored = restored + 1
            end
        end

        -- Clear registry entry
        registry[hook_id] = nil
        _del_orig(hook_id)
    end

    if restored > 0 then
        _log("Restored " .. restored .. " originals on load")
    end
end

_restore_on_load()

-- Register globally via Reg
Reg.set("Hooks", Hooks)

return Hooks
