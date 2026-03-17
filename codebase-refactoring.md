# Codebase Refactoring Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor Scripts/lib/, Scripts/actions/, Scripts/ui/ to use OOP ActionBase, centralized HookManager, eliminate Utils.lua, and add injectable tests.

**Architecture:** OOP inheritance via ActionBase abstract class. HookManager is the single public hook API with auto-generated keys, centralized registry in `_G.KURO_hooks`, and per-hook independent activation. State stored in `_G.KURO_state` with persistent/transient split. Selectors replaced by declarative config + factory.

**Tech Stack:** Lua 5.x, Cocos2d-x (cc/ccui), game runtime (G, portable), Python injector for testing.

**Spec:** `docs/superpowers/specs/2026-03-16-codebase-refactoring-design.md`

---

## Progress Tracker (verified 2026-03-17)

### Runtime Verification

**149/149 assertions pass, 14/14 suites green, 12/12 modules load.**
Injection: `dofile('C:/temp/Where Winds Meet/Scripts/tests/run_all.lua')` → `Scripts/logs/test_results.txt`
Pipe requires admin. Activate venv: `source .venv/Scripts/activate`. Forward slashes only (backslash = ERRSYNTAX).

### Summary

| Chunk | Status | Done |
|-------|--------|------|
| ~~1 Backup & Test Infra~~ | DONE | 2/2 |
| ~~2 Foundation Modules~~ | DONE | 7/7 |
| ~~3 Foundation Tests~~ | DONE | 3/3 |
| ~~4 Simple Actions (buffs, world, combat)~~ | DONE | 3/3 |
| ~~5 Remaining Action Migrations~~ | DONE | 12/12 |
| ~~6 Standalone Lib Updates~~ | DONE | 3/3 |
| ~~7 UI Refactoring~~ | DONE | 4/4 |
| ~~8 Finalize~~ | DONE | 3/3 |

**Overall: 37/37 tasks done ✅**

### Chunk 5 — Action Migrations

| Task | File | Status | Old Patterns |
|------|------|--------|--------------|
| ~~16~~ | ~~suit_skins.lua~~ | ~~DONE~~ | |
| ~~17~~ | ~~effects.lua~~ | ~~DONE~~ | Redone: proper `define_hooks()`, `self:hook()`/`self:unhook()`, `self:log()` |
| ~~18~~ | ~~weapon_skins.lua~~ | ~~DONE~~ | |
| ~~19~~ | ~~xinfa_buffs.lua~~ | ~~DONE~~ | |
| ~~20~~ | ~~gm_panel.lua~~ | ~~DONE~~ | |
| ~~21~~ | ~~spy.lua~~ | ~~DONE~~ | Fixed `Utils.dump_value` → `Serialize.dump_value` |
| ~~22~~ | ~~trace.lua~~ | ~~DONE~~ | |
| ~~23~~ | ~~dump.lua~~ | ~~DONE~~ | |
| ~~24~~ | ~~parry.lua~~ | ~~DONE~~ | Full rewrite to ActionBase |
| ~~25~~ | ~~parry_v2.lua → parry_online.lua~~ | ~~DONE~~ | Full rewrite (1393→540 lines), `parry_v2.lua` deleted |
| ~~26~~ | ~~autoloot.lua~~ | ~~DONE~~ | Fixed `Cocos.delay_call` signature bug, removed unused local |
| ~~27~~ | ~~sync_observer.lua~~ | ~~DONE~~ | Full rewrite to ActionBase, 3 hooks |

~~`actions/test.lua` — deleted (was obsolete, superseded by combat.lua)~~

### Chunk 6 — Lib Updates

| Task | Status |
|------|--------|
| ~~28 anticheat_bypass.lua~~ | ~~DONE~~ (uses `KURO_lib`, `portable.safe_import`) |
| ~~29 dump_core.lua + trace_core.lua~~ | ~~DONE~~ (uses `KURO_lib.Serialize`) |
| ~~30 Delete utils.lua + hook_interceptor.lua~~ | ~~DONE~~ — blocked until Chunk 5 TODO files migrated, then delete |

### Chunk 7 — UI Refactoring

| Task | File | Status | Notes |
|------|------|--------|-------|
| ~~31~~ | ~~selector_factory.lua~~ | ~~DONE~~ | |
| ~~32~~ | ~~menu_config.lua~~ | ~~DONE~~ | `Utils.safe_dofile` → `pcall(dofile, ...)` |
| ~~33~~ | ~~menu_controller.lua~~ | ~~DONE~~ | |
| ~~34~~ | ~~Delete 7 selector wrappers~~ | ~~DONE~~ | All 7 deleted: suit/weapon/bow/effect/dual_effect/dual_weapon/xinfa_selector |

**Also cleaned:** 3 UI files had `Reg.get("Utils")`:
- ~~`ui/menu.lua`~~ — `Utils.safe_dofile` → `pcall(dofile, ...)`, Utils import removed
- ~~`ui/components/item_selector.lua`~~ — `Utils.safe_dofile` → Reg.get fallback + `pcall(dofile)`, Utils import removed
- ~~`ui/components/dual_selector.lua`~~ — `Utils.safe_dofile` → `pcall(dofile, ...)`, Utils import removed

### Chunk 8 — Finalize

| Task | Status |
|------|--------|
| ~~35 run_all.lua~~ | ~~DONE~~ (`Scripts/tests/run_safe.lua` created and verified) |
| ~~36~~ | ~~Update IMPLEMENT.md~~ — ~~DONE~~ |
| ~~37~~ | ~~Final verification + git commit~~ — ~~DONE~~ |

---

### Subagent Task Queue

Each task: read `Scripts/backup/actions/<file>` for original logic → rewrite to ActionBase → write test → verify loads.

**Reference:** See any completed migration (e.g. `Scripts/actions/combat.lua`, `Scripts/actions/spy.lua`) for the exact pattern.

**Pattern checklist:**
- `local ActionBase = _G.Reg.lib("ActionBase")`
- `local X = ActionBase:extend("actions.<name>")`
- `define_state()` → `{ persistent = {...}, transient = {} }`
- `define_hooks()` → named hooks with `spec`, `override_orig_function`, `post_exec`
- Replace `Utils.safe_import` → `portable.safe_import`
- Replace `Utils.safe_call` → `pcall`
- Replace `Utils.safe_dofile` → `pcall(dofile, ...)`
- Replace `Utils.get_main_player()` → `G.main_player`
- Replace `Utils.dump_value` → `Serialize.dump_value` (get via `_G.Reg.lib("Serialize")`, NEVER `_G.KURO_lib` directly)
- Replace `Utils.init_dict(tbl)` → `require("common.classutils").CustomMapType(tbl):to_valid_dict()` (Lua→engine dict, NOT Serialize.normalize)
- Replace `Utils.init_list(tbl)` → `require("common.classutils").CustomListType(tbl)` (Lua→engine list)
- Replace `Reg.get/set` state → `self.state`
- Replace `HookInterceptor` → `define_hooks()` with named entries
- Replace `_log()` → `self:log()`
- End with `return X:new()`

| ID | Task | Complexity | Deps | Status |
|----|------|-----------|------|--------|
| ~~A2~~ | ~~Migrate gm_panel.lua + test~~ | ~~MED~~ | — | **DONE** |
| ~~A7~~ | ~~Delete actions/test.lua~~ | ~~LOW~~ | — | **DONE** |
| ~~A1~~ | ~~Migrate effects.lua + test~~ | ~~MED~~ | — | **DONE** |
| ~~A3~~ | ~~Migrate autoloot.lua + test~~ | ~~HIGH~~ | — | **DONE** |
| ~~A4~~ | ~~Migrate parry.lua + test~~ | ~~HIGH~~ | — | **DONE** |
| ~~A5~~ | ~~Migrate parry_v2.lua → parry_online.lua + test~~ | ~~HIGH~~ | A4 | **DONE** |
| ~~A6~~ | ~~Migrate sync_observer.lua + test~~ | ~~HIGH~~ | — | **DONE** |
| ~~U1~~ | ~~Update menu_config.lua (Task 32)~~ | ~~MED~~ | — | **DONE** |
| ~~U2~~ | ~~Delete 7 selector wrappers (Task 34)~~ | ~~LOW~~ | U1 | **DONE** |
| ~~U3~~ | ~~Clean UI Utils refs~~ | ~~LOW~~ | — | **DONE** |
| ~~D1~~ | ~~Delete hook_interceptor.lua + fix spy.lua~~ | ~~LOW~~ | A1-A6 | **DONE** |
| ~~F1~~ | ~~Update IMPLEMENT.md + final verification~~ | ~~LOW~~ | All | **DONE** |

---

## Chunk 1: Backup & Test Infrastructure

### Task 1: Backup Current Code

**Files:**
- Source: `Scripts/lib/`, `Scripts/actions/`, `Scripts/ui/`
- Create: `Scripts/backup/lib/`, `Scripts/backup/actions/`, `Scripts/backup/ui/`

- [ ] **Step 1: Copy current lib/ to backup**

```bash
cp -r "Scripts/lib" "Scripts/backup/lib"
```

- [ ] **Step 2: Copy current actions/ to backup**

```bash
cp -r "Scripts/actions" "Scripts/backup/actions"
```

- [ ] **Step 3: Copy current ui/ to backup**

```bash
cp -r "Scripts/ui" "Scripts/backup/ui"
```

- [ ] **Step 4: Verify backup completeness**

```bash
diff <(ls Scripts/lib/*.lua | wc -l) <(ls Scripts/backup/lib/*.lua | wc -l)
diff <(ls Scripts/actions/*.lua | wc -l) <(ls Scripts/backup/actions/*.lua | wc -l)
```
Expected: counts match.

- [ ] **Step 5: Commit backup**

```bash
git add Scripts/backup/
git commit -m "chore: backup pre-refactor code"
```

---

### Task 2: Create Test Runner

**Files:**
- Create: `Scripts/tests/run_test.lua`

- [ ] **Step 1: Write test runner**

```lua
-- Scripts/tests/run_test.lua
-- Lightweight test runner for injectable tests
-- Usage: local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
--        T.run("test name", function() ... end)

local T = {}
T._passed = 0
T._failed = 0
T._errors = {}

function T.run(name, test_fn)
    local ok, err = pcall(test_fn)
    if ok then
        T._passed = T._passed + 1
        print("PASS: " .. name)
    else
        T._failed = T._failed + 1
        T._errors[#T._errors + 1] = { name = name, err = tostring(err) }
        print("FAIL: " .. name .. " -- " .. tostring(err))
    end
    return ok
end

function T.assert_eq(actual, expected, label)
    label = label or ""
    if actual ~= expected then
        error(label .. " expected [" .. tostring(expected) .. "] got [" .. tostring(actual) .. "]")
    end
end

function T.assert_true(val, label)
    if not val then
        error((label or "") .. " expected true, got " .. tostring(val))
    end
end

function T.assert_false(val, label)
    if val then
        error((label or "") .. " expected false, got " .. tostring(val))
    end
end

function T.assert_nil(val, label)
    if val ~= nil then
        error((label or "") .. " expected nil, got " .. tostring(val))
    end
end

function T.assert_not_nil(val, label)
    if val == nil then
        error((label or "") .. " expected non-nil")
    end
end

function T.assert_type(val, expected_type, label)
    if type(val) ~= expected_type then
        error((label or "") .. " expected type " .. expected_type .. ", got " .. type(val))
    end
end

function T.summary()
    print(string.format("\n=== RESULTS: %d passed, %d failed ===", T._passed, T._failed))
    if #T._errors > 0 then
        print("Failures:")
        for _, e in ipairs(T._errors) do
            print("  - " .. e.name .. ": " .. e.err)
        end
    end
    return T._failed == 0
end

function T.reset()
    T._passed = 0
    T._failed = 0
    T._errors = {}
end

return T
```

- [ ] **Step 2: Commit test runner**

```bash
git add Scripts/tests/run_test.lua
git commit -m "feat: add test runner for injectable tests"
```

---

## Chunk 2: Foundation — Constants, Logger, Reg, Serialize, Cocos

### Task 3: Update Constants

**Files:**
- Modify: `Scripts/lib/constants.lua`

- [ ] **Step 1: Add TESTS_ROOT path**

Add to constants.lua after the TRACES_ROOT line:

```lua
Constants.TESTS_ROOT = Constants.SCRIPTS_ROOT .. "\\tests"
Constants.BACKUP_ROOT = Constants.SCRIPTS_ROOT .. "\\backup"
```

No other changes to constants.lua — it's already clean.

- [ ] **Step 2: Commit**

```bash
git add Scripts/lib/constants.lua
git commit -m "feat: add TESTS_ROOT and BACKUP_ROOT to Constants"
```

---

### Task 4: Create serialize.lua

**Files:**
- Create: `Scripts/lib/serialize.lua`
- Reference: `Scripts/lib/utils.lua` (extract `dump_value`, `_normalize`, `_pretty`, type helpers)
- Reference: `Scripts/lib/inspect.lua` (used by serialize)

- [ ] **Step 1: Write serialize.lua**

Extract the serialization functions from utils.lua. These are the functions NOT available in the game runtime:

```lua
-- Scripts/lib/serialize.lua
-- Value serialization: game types → plain Lua → human-readable strings
-- Extracted from utils.lua — only contains custom logic not in the runtime.

local _ROOT = "C:\\temp\\Where Winds Meet\\Scripts"
local inspect = dofile(_ROOT .. "\\lib\\inspect.lua")

local Serialize = {}

-- ────────────────────────────────────────────────────────────
-- Type checking helpers
-- ────────────────────────────────────────────────────────────

function Serialize.is_pairable(obj)
    if obj == nil then return false end
    local t = type(obj)
    if t == "table" then return true end
    if t == "userdata" then
        local ok = pcall(function() for _ in pairs(obj) do break end end)
        return ok
    end
    -- Engine types: list, dict, instance
    if t == "list" or t == "dict" or t == "instance" then
        return true
    end
    return false
end

function Serialize.is_instance_like(obj)
    if obj == nil then return false end
    local t = type(obj)
    return t == "instance" or t == "class" or t == "userdata"
end

-- ────────────────────────────────────────────────────────────
-- Normalization: convert game types to plain Lua tables
-- ────────────────────────────────────────────────────────────

local function _normalize(val, depth, max_depth, seen)
    depth = depth or 0
    max_depth = max_depth or 5
    seen = seen or {}

    if depth > max_depth then return "<max_depth>" end
    if val == nil then return nil end

    local t = type(val)

    -- Plain types pass through
    if t == "string" or t == "number" or t == "boolean" then
        return val
    end

    -- Cycle detection for reference types
    if t == "table" or t == "list" or t == "dict" or t == "instance" or t == "class" or t == "tuple" or t == "userdata" then
        if seen[val] then return "<cycle>" end
        seen[val] = true
    end

    -- dict → plain table
    if t == "dict" then
        local result = {}
        local ok, _ = pcall(function()
            if val.keys and val.get then
                for _, k in ipairs(val:keys()) do
                    local v = val:get(k)
                    result[_normalize(k, depth + 1, max_depth, seen)] = _normalize(v, depth + 1, max_depth, seen)
                end
            elseif val.items then
                for _, pair in ipairs(val:items()) do
                    result[_normalize(pair[1], depth + 1, max_depth, seen)] = _normalize(pair[2], depth + 1, max_depth, seen)
                end
            end
        end)
        if not ok then
            pcall(function()
                for k, v in pairs(val) do
                    result[_normalize(k, depth + 1, max_depth, seen)] = _normalize(v, depth + 1, max_depth, seen)
                end
            end)
        end
        return result
    end

    -- list / tuple → plain array
    if t == "list" or t == "tuple" then
        local result = {}
        local ok, _ = pcall(function()
            if val.tolist then
                local lst = val:tolist()
                for i, v in ipairs(lst) do
                    result[i] = _normalize(v, depth + 1, max_depth, seen)
                end
            else
                for i = 1, #val do
                    result[i] = _normalize(val[i], depth + 1, max_depth, seen)
                end
            end
        end)
        if not ok then
            pcall(function()
                for i, v in ipairs(val) do
                    result[i] = _normalize(v, depth + 1, max_depth, seen)
                end
            end)
        end
        return result
    end

    -- instance / class → best-effort extraction
    if t == "instance" or t == "class" then
        local result = { __type = t }
        pcall(function()
            if val.__cname__ then result.__class = val.__cname__ end
            if val.todict then
                local d = val:todict()
                for k, v in pairs(d) do
                    result[tostring(k)] = _normalize(v, depth + 1, max_depth, seen)
                end
            end
        end)
        return result
    end

    -- userdata → try tostring
    if t == "userdata" then
        local ok, s = pcall(tostring, val)
        return ok and s or "<userdata>"
    end

    -- plain table
    if t == "table" then
        local result = {}
        for k, v in pairs(val) do
            result[_normalize(k, depth + 1, max_depth, seen)] = _normalize(v, depth + 1, max_depth, seen)
        end
        return result
    end

    return tostring(val)
end

Serialize.normalize = _normalize

-- ────────────────────────────────────────────────────────────
-- Pretty printing
-- ────────────────────────────────────────────────────────────

function Serialize.dump_value(val, options)
    options = options or {}
    local max_depth = options.max_depth or 5
    local pretty = options.pretty ~= false

    -- Normalize game types first
    local normalized = _normalize(val, 0, max_depth, {})

    -- Use inspect for pretty printing
    return inspect(normalized, {
        depth = max_depth,
        pretty = pretty,
        newline = pretty and "\n" or " ",
        indent = "  ",
    })
end

function Serialize.dump_instance(obj)
    if not Serialize.is_instance_like(obj) then
        return Serialize.dump_value(obj)
    end
    return inspect(obj, {
        depth = 3,
        pretty = true,
        inspect_instances_deep = true,
    })
end

return Serialize
```

- [ ] **Step 2: Commit**

```bash
git add Scripts/lib/serialize.lua
git commit -m "feat: add serialize.lua extracted from utils.lua"
```

---

### Task 5: Create cocos.lua

**Files:**
- Create: `Scripts/lib/cocos.lua`
- Reference: `Scripts/lib/utils.lua` (extract `delay_call`, `create_empty_proxy`, scene access)

- [ ] **Step 1: Write cocos.lua**

```lua
-- Scripts/lib/cocos.lua
-- Cocos2d-x helper functions not available in the game runtime.

local Cocos = {}

function Cocos.get_running_scene()
    local ok, scene = pcall(function()
        return cc.Director:getInstance():getRunningScene()
    end)
    if ok and scene then return scene end
    return nil
end

function Cocos.delay_call(delay_seconds, func)
    local scene = Cocos.get_running_scene()
    if not scene then return false end

    local action = cc.Sequence:create({
        cc.DelayTime:create(delay_seconds),
        cc.CallFunc:create(func),
    })
    scene:runAction(action)
    return true
end

function Cocos.create_empty_proxy()
    local proxy = {}
    local mt = {
        __index = function() return proxy end,
        __newindex = function() end,
        __call = function() return proxy end,
        __tostring = function() return "EmptyProxy" end,
        __len = function() return 0 end,
    }
    setmetatable(proxy, mt)
    return proxy
end

return Cocos
```

- [ ] **Step 2: Commit**

```bash
git add Scripts/lib/cocos.lua
git commit -m "feat: add cocos.lua extracted from utils.lua"
```

---

### Task 6: Refactor bootstrap.lua with new Reg API

**Files:**
- Modify: `Scripts/lib/bootstrap.lua`

- [ ] **Step 1: Rewrite bootstrap.lua**

Replace the entire contents of `Scripts/lib/bootstrap.lua`:

```lua
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

-- ============================================================
-- REG MODULE - Global registry with structured namespaces
-- ============================================================

local Reg = {}

-- Initialize global namespaces (preserve across reloads)
_G.KURO_lib = _G.KURO_lib or {}
_G.KURO_modules = _G.KURO_modules or {}
_G.KURO_state = _G.KURO_state or {}
_G.KURO_hooks = _G.KURO_hooks or {}

-- ── Structured accessors ──

function Reg.lib(name)
    return _G.KURO_lib[name]
end

function Reg.set_lib(name, value)
    _G.KURO_lib[name] = value
end

function Reg.module(name)
    return _G.KURO_modules[name]
end

function Reg.register_module(name, mod)
    _G.KURO_modules[name] = mod
end

function Reg.state(name)
    if not _G.KURO_state[name] then
        _G.KURO_state[name] = {}
    end
    return _G.KURO_state[name]
end

function Reg.list_modules()
    local names = {}
    for name in pairs(_G.KURO_modules) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

function Reg.reset_module(name)
    local mod = _G.KURO_modules[name]
    if mod and mod.disable then
        pcall(mod.disable, mod)
    end
    _G.KURO_state[name] = nil
    -- Deactivate hooks for this module
    local HookManager = _G.KURO_lib.HookManager
    if HookManager then
        HookManager.deactivate_all(name)
    end
    _G.KURO_modules[name] = nil
end

function Reg.reset_all()
    local HookManager = _G.KURO_lib.HookManager
    if HookManager then
        HookManager.deactivate_everything()
    end
    for name, mod in pairs(_G.KURO_modules) do
        if mod.disable then pcall(mod.disable, mod) end
    end
    _G.KURO_modules = {}
    _G.KURO_state = {}
    _G.KURO_hooks = {}
end

-- ── Legacy accessors (kept for migration) ──

function Reg.key(name)
    return _PREFIX .. "_" .. name
end

function Reg.get(name)
    -- Check new namespaces first
    if _G.KURO_lib[name] then return _G.KURO_lib[name] end
    if _G.KURO_modules[name] then return _G.KURO_modules[name] end
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

-- Register Constants
Reg.set_lib("Constants", Constants)
Reg.set("Constants", Constants)  -- legacy

-- Load Logger
local Logger = dofile(_ROOT .. "\\lib\\logger.lua")
Reg.set_lib("Logger", Logger)
Reg.set("Logger", Logger)  -- legacy

-- Load Serialize
local Serialize = dofile(_ROOT .. "\\lib\\serialize.lua")
Reg.set_lib("Serialize", Serialize)

-- Load Cocos
local Cocos = dofile(_ROOT .. "\\lib\\cocos.lua")
Reg.set_lib("Cocos", Cocos)

-- Load Hooks (internal engine)
local Hooks = dofile(_ROOT .. "\\lib\\hooks.lua")
Reg.set_lib("Hooks", Hooks)
Reg.set("Hooks", Hooks)  -- legacy

-- Load HookManager (public API)
local HookManager = dofile(_ROOT .. "\\lib\\hook_manager.lua")
Reg.set_lib("HookManager", HookManager)

-- Load ActionBase
local ActionBase = dofile(_ROOT .. "\\lib\\action_base.lua")
Reg.set_lib("ActionBase", ActionBase)

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

return {
    Reg = Reg,
    Constants = Constants,
    Logger = Logger,
}
```

- [ ] **Step 2: Commit**

```bash
git add Scripts/lib/bootstrap.lua
git commit -m "refactor: bootstrap.lua with new Reg API and structured namespaces"
```

---

### Task 7: Refactor hooks.lua (internal engine)

**Files:**
- Modify: `Scripts/lib/hooks.lua`

- [ ] **Step 1: Simplify hooks.lua**

Replace the entire contents. This is the INTERNAL engine — only HookManager calls it. Simplified to two hook types only, no more `Utils` dependency:

```lua
-- ============================================================
-- HOOKS.LUA - Low-level hook engine (INTERNAL - use HookManager instead)
-- ============================================================
-- Two hook types:
--   1. Function on module: module.function_name
--   2. Method on class: module.ClassName.method_name
--
-- HookManager is the public API. Do not call this directly from actions.

local Hooks = {}

local Logger = _G.KURO_lib and _G.KURO_lib.Logger
local function _log(msg)
    if Logger then Logger.log("[Hooks] " .. msg) end
end

-- ────────────────────────────────────────────────────────────
-- Wrapper construction
-- ────────────────────────────────────────────────────────────

function Hooks.make_wrapper(original_fn, callback_fn, options)
    options = options or {}
    local override = options.override_orig_function
    local traceback_enabled = options.enable_traceback
    local raise = options.raise_err
    local action_instance = options.action_instance

    return function(...)
        if override then
            -- MODE 1: callback has full control
            -- Signature: callback(action_instance, original_fn, ...)
            local ok, result = pcall(callback_fn, action_instance, original_fn, ...)
            if not ok then
                if raise then error(tostring(result)) end
                _log("override callback error: " .. tostring(result))
                return nil
            end
            return result
        else
            -- MODE 2: call original, then observe
            local args = table.pack(...)
            local results = table.pack(original_fn(...))

            if callback_fn then
                local tb = traceback_enabled and debug.traceback("", 2) or nil
                local ok, err = pcall(callback_fn, action_instance, args, results, tb)
                if not ok then
                    if raise then error(tostring(err)) end
                    _log("post_exec error: " .. tostring(err))
                end
            end

            return table.unpack(results, 1, results.n)
        end
    end
end

-- ────────────────────────────────────────────────────────────
-- Hook a module-level function
-- ────────────────────────────────────────────────────────────

function Hooks.hook_function(module_table, func_name, wrapper_fn)
    local ok, original_fn = pcall(rawget, module_table, func_name)
    if not ok or type(original_fn) ~= "function" then
        return nil, "Not a function: " .. tostring(func_name)
    end
    rawset(module_table, func_name, wrapper_fn)
    return original_fn
end

-- ────────────────────────────────────────────────────────────
-- Hook a method on a class
-- ────────────────────────────────────────────────────────────

function Hooks.hook_method(module_table, class_name, method_name, wrapper_fn)
    local ok_cls, class = pcall(rawget, module_table, class_name)
    if not ok_cls or not class then
        return nil, "Class not found: " .. tostring(class_name)
    end

    local ok_fn, original_fn = pcall(rawget, class, method_name)
    if not original_fn then
        -- Try through metatable/inheritance
        original_fn = class[method_name]
    end
    if not ok_fn or type(original_fn) ~= "function" then
        return nil, "Not a method: " .. tostring(class_name) .. "." .. tostring(method_name)
    end

    rawset(class, method_name, wrapper_fn)
    return original_fn
end

-- ────────────────────────────────────────────────────────────
-- Restore original function
-- ────────────────────────────────────────────────────────────

function Hooks.restore(target_table, target_key, original_fn)
    rawset(target_table, target_key, original_fn)
end

return Hooks
```

- [ ] **Step 2: Commit**

```bash
git add Scripts/lib/hooks.lua
git commit -m "refactor: simplify hooks.lua to internal engine with two hook types"
```

---

### Task 8: Create HookManager

**Files:**
- Create: `Scripts/lib/hook_manager.lua`
- Delete: `Scripts/lib/hook_interceptor.lua` (after all migrations)

- [ ] **Step 1: Write hook_manager.lua**

```lua
-- ============================================================
-- HOOK_MANAGER.LUA - Centralized hook system (PUBLIC API)
-- ============================================================
-- The ONLY public hook API. Actions never call hooks.lua directly.
-- Auto-generates hook keys from module name.
-- Stores everything in _G.KURO_hooks.
--
-- Two hook types (auto-detected from spec):
--   3 parts "module:Class:method" → method hook
--   2 parts "module:function"     → function hook

local HookManager = {}

local Hooks -- loaded lazily to avoid circular dependency
local Logger

local function _get_hooks()
    Hooks = Hooks or (_G.KURO_lib and _G.KURO_lib.Hooks)
    return Hooks
end

local function _log(msg)
    Logger = Logger or (_G.KURO_lib and _G.KURO_lib.Logger)
    if Logger then Logger.log("[HookManager] " .. msg) end
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

    -- Preserve active state if re-registering (reload scenario)
    local existing = _G.KURO_hooks[key]
    local was_active = existing and existing.active

    _G.KURO_hooks[key] = {
        module = module_name,
        hook_name = hook_name,
        spec = hook_def.spec,
        parsed = parsed,
        active = false,  -- starts inactive, ActionBase decides
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
    local entry = _G.KURO_hooks[key]
    if not entry then
        return false, "Hook not registered: " .. key
    end
    if entry.active then
        return true  -- already active
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

    -- Build wrapper
    local wrapper = hooks.make_wrapper(nil, def.post_exec, {
        override_orig_function = def.override_orig_function,
        enable_traceback = def.enable_traceback,
        raise_err = def.raise_err,
        action_instance = action_instance,
    })

    -- Install hook based on type
    local original, hook_err
    if parsed.type == "method" then
        -- Need to pass a wrapper that already has original baked in
        -- First get original, then rebuild wrapper with it
        local ok_cls, class = pcall(rawget, mod, parsed.class_name)
        if not ok_cls or not class then
            return false, "Class not found: " .. parsed.class_name
        end
        local ok_fn, orig = pcall(rawget, class, parsed.method_name)
        if not orig then orig = class[parsed.method_name] end
        if not ok_fn or type(orig) ~= "function" then
            return false, "Not a method: " .. parsed.class_name .. "." .. parsed.method_name
        end

        -- Use stored original if we have one (re-hook scenario)
        if entry.original then
            orig = entry.original
        end

        -- Build wrapper with the real original
        wrapper = hooks.make_wrapper(orig, def.post_exec, {
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

        wrapper = hooks.make_wrapper(orig, def.post_exec, {
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
    local entry = _G.KURO_hooks[key]
    if not entry then
        return false, "Hook not registered: " .. key
    end
    if not entry.active then
        return true  -- already inactive
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
    local entry = _G.KURO_hooks[key]
    return entry and entry.active or false
end

function HookManager.get_all_active()
    local result = {}
    for key, entry in pairs(_G.KURO_hooks) do
        if entry.active then
            result[key] = entry
        end
    end
    return result
end

function HookManager.get_module_hooks(module_name)
    local result = {}
    for key, entry in pairs(_G.KURO_hooks) do
        if entry.module == module_name then
            result[entry.hook_name] = entry
        end
    end
    return result
end

function HookManager.get_module_active(module_name)
    local result = {}
    for key, entry in pairs(_G.KURO_hooks) do
        if entry.module == module_name and entry.active then
            result[entry.hook_name] = entry
        end
    end
    return result
end

function HookManager.list_modules()
    local seen = {}
    local result = {}
    for _, entry in pairs(_G.KURO_hooks) do
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
    for key, entry in pairs(_G.KURO_hooks) do
        if entry.module == module_name and not entry.active then
            local ok = HookManager.activate(module_name, entry.hook_name, action_instance)
            if ok then count = count + 1 end
        end
    end
    return count
end

function HookManager.deactivate_all(module_name)
    local count = 0
    for key, entry in pairs(_G.KURO_hooks) do
        if entry.module == module_name and entry.active then
            HookManager.deactivate(module_name, entry.hook_name)
            count = count + 1
        end
    end
    return count
end

function HookManager.deactivate_everything()
    local count = 0
    for key, entry in pairs(_G.KURO_hooks) do
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
    for key, entry in pairs(_G.KURO_hooks) do
        if entry.module == module_name then
            if entry.active then
                HookManager.deactivate(module_name, entry.hook_name)
            end
            to_remove[#to_remove + 1] = key
        end
    end
    for _, key in ipairs(to_remove) do
        _G.KURO_hooks[key] = nil
    end
end

function HookManager.get_previously_active(module_name)
    local result = {}
    for key, entry in pairs(_G.KURO_hooks) do
        if entry.module == module_name and entry.was_active_before_reload then
            result[#result + 1] = entry.hook_name
        end
    end
    return result
end

return HookManager
```

- [ ] **Step 2: Commit**

```bash
git add Scripts/lib/hook_manager.lua
git commit -m "feat: add HookManager — centralized hook system with auto-keys"
```

---

### Task 9: Create ActionBase

**Files:**
- Create: `Scripts/lib/action_base.lua`

- [ ] **Step 1: Write action_base.lua**

```lua
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
    Logger = Logger or (_G.KURO_lib and _G.KURO_lib.Logger)
    return Logger
end

local function _get_hook_manager()
    HookManager = HookManager or (_G.KURO_lib and _G.KURO_lib.HookManager)
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
    _G.KURO_modules[instance._name] = instance

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

    -- Get or create state table
    local existing = _G.KURO_state[self._name]
    if not existing then
        -- First load: merge persistent + transient defaults
        local state = {}
        for k, v in pairs(persistent) do state[k] = v end
        for k, v in pairs(transient) do state[k] = v end
        _G.KURO_state[self._name] = state
        self.state = _G.KURO_state[self._name]
    else
        -- Reload: keep persistent, reset transient
        for k, v in pairs(transient) do
            existing[k] = v  -- always reset transient to defaults
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
    if not hm then return end

    local hooks = self:define_hooks()
    for hook_name, hook_def in pairs(hooks) do
        hm.register(self._name, hook_name, hook_def)
    end
end

function ActionBase:_restore_hooks()
    local hm = _get_hook_manager()
    if not hm then return end

    local previously_active = hm.get_previously_active(self._name)
    if #previously_active > 0 then
        self:log("Restoring " .. #previously_active .. " hooks from previous session")
        for _, hook_name in ipairs(previously_active) do
            hm.activate(self._name, hook_name, self)
        end
    end
end

-- Individual hook control
function ActionBase:hook(name)
    local hm = _get_hook_manager()
    if not hm then return false, "HookManager not loaded" end
    return hm.activate(self._name, name, self)
end

function ActionBase:unhook(name)
    local hm = _get_hook_manager()
    if not hm then return false, "HookManager not loaded" end
    return hm.deactivate(self._name, name)
end

function ActionBase:is_hooked(name)
    local hm = _get_hook_manager()
    if not hm then return false end
    return hm.is_active(self._name, name)
end

-- Batch hook control
function ActionBase:hook_all()
    local hm = _get_hook_manager()
    if not hm then return 0 end
    return hm.activate_all(self._name, self)
end

function ActionBase:unhook_all()
    local hm = _get_hook_manager()
    if not hm then return 0 end
    return hm.deactivate_all(self._name)
end

function ActionBase:hook_many(...)
    local hm = _get_hook_manager()
    if not hm then return 0 end
    local count = 0
    for _, name in ipairs({...}) do
        local ok = hm.activate(self._name, name, self)
        if ok then count = count + 1 end
    end
    return count
end

-- Query
function ActionBase:get_active_hooks()
    local hm = _get_hook_manager()
    if not hm then return {} end
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
```

- [ ] **Step 2: Commit**

```bash
git add Scripts/lib/action_base.lua
git commit -m "feat: add ActionBase abstract class with OOP lifecycle"
```

---

## Chunk 3: Foundation Tests

### Task 10: Test bootstrap & Reg

**Files:**
- Create: `Scripts/tests/test_bootstrap.lua`

- [ ] **Step 1: Write test**

```lua
-- Scripts/tests/test_bootstrap.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg

T.run("Reg exists", function()
    T.assert_not_nil(Reg, "Reg")
end)

T.run("KURO_lib namespace exists", function()
    T.assert_type(_G.KURO_lib, "table", "KURO_lib")
end)

T.run("KURO_modules namespace exists", function()
    T.assert_type(_G.KURO_modules, "table", "KURO_modules")
end)

T.run("KURO_state namespace exists", function()
    T.assert_type(_G.KURO_state, "table", "KURO_state")
end)

T.run("KURO_hooks namespace exists", function()
    T.assert_type(_G.KURO_hooks, "table", "KURO_hooks")
end)

T.run("Reg.lib returns Logger", function()
    T.assert_not_nil(Reg.lib("Logger"), "Logger")
end)

T.run("Reg.lib returns Constants", function()
    T.assert_not_nil(Reg.lib("Constants"), "Constants")
end)

T.run("Reg.lib returns HookManager", function()
    T.assert_not_nil(Reg.lib("HookManager"), "HookManager")
end)

T.run("Reg.lib returns ActionBase", function()
    T.assert_not_nil(Reg.lib("ActionBase"), "ActionBase")
end)

T.run("Reg.lib returns Serialize", function()
    T.assert_not_nil(Reg.lib("Serialize"), "Serialize")
end)

T.run("Reg.lib returns Cocos", function()
    T.assert_not_nil(Reg.lib("Cocos"), "Cocos")
end)

T.run("Reg.state creates empty table", function()
    local s = Reg.state("_test_state")
    T.assert_type(s, "table", "state")
    _G.KURO_state["_test_state"] = nil  -- cleanup
end)

T.run("Reg.legacy get/set still works", function()
    Reg.set("_test_legacy", 42)
    T.assert_eq(Reg.get("_test_legacy"), 42, "legacy value")
    Reg.del("_test_legacy")
end)

T.summary()
```

- [ ] **Step 2: Verify via injection**

```powershell
cd C:\temp\Where Winds Meet\Scripts\utils
& '.\.venv\Scripts\Activate.ps1'
python ..\inject\debug.py "dofile('C:\\temp\\Where Winds Meet\\Scripts\\tests\\test_bootstrap.lua')"
```
Expected: All tests PASS.

- [ ] **Step 3: Commit**

```bash
git add Scripts/tests/test_bootstrap.lua
git commit -m "test: add bootstrap test"
```

---

### Task 11: Test HookManager

**Files:**
- Create: `Scripts/tests/test_hook_manager.lua`

- [ ] **Step 1: Write test**

```lua
-- Scripts/tests/test_hook_manager.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local HookManager = Reg.lib("HookManager")

-- Use a real game class for testing: hexm.client.ui.base.text:Text:set_text
local TEST_MODULE = "test_hm_module"

T.run("HookManager exists", function()
    T.assert_not_nil(HookManager, "HookManager")
end)

T.run("derive_module_name", function()
    local name = HookManager.derive_module_name("C:\\temp\\Where Winds Meet\\Scripts\\actions\\combat.lua")
    T.assert_eq(name, "actions.combat", "derived name")
end)

T.run("register hook", function()
    local ok = HookManager.register(TEST_MODULE, "test_hook", {
        spec = "hexm.client.ui.base.text:Text:set_text",
        post_exec = function() end,
    })
    T.assert_true(ok, "register")
end)

T.run("hook starts inactive", function()
    T.assert_false(HookManager.is_active(TEST_MODULE, "test_hook"), "should be inactive")
end)

T.run("get_module_hooks returns registered hook", function()
    local hooks = HookManager.get_module_hooks(TEST_MODULE)
    T.assert_not_nil(hooks["test_hook"], "hook entry")
end)

T.run("activate hook", function()
    local ok, err = HookManager.activate(TEST_MODULE, "test_hook")
    T.assert_true(ok, "activate: " .. tostring(err))
end)

T.run("hook is active after activate", function()
    T.assert_true(HookManager.is_active(TEST_MODULE, "test_hook"))
end)

T.run("get_all_active includes test hook", function()
    local active = HookManager.get_all_active()
    T.assert_not_nil(active[TEST_MODULE .. ".test_hook"])
end)

T.run("deactivate hook", function()
    HookManager.deactivate(TEST_MODULE, "test_hook")
    T.assert_false(HookManager.is_active(TEST_MODULE, "test_hook"))
end)

T.run("deactivate_everything", function()
    HookManager.activate(TEST_MODULE, "test_hook")
    HookManager.deactivate_everything()
    T.assert_false(HookManager.is_active(TEST_MODULE, "test_hook"))
end)

-- Cleanup
HookManager.clear_module(TEST_MODULE)

T.summary()
```

- [ ] **Step 2: Verify via injection**

```powershell
python ..\inject\debug.py "dofile('C:\\temp\\Where Winds Meet\\Scripts\\tests\\test_hook_manager.lua')"
```
Expected: All tests PASS.

- [ ] **Step 3: Commit**

```bash
git add Scripts/tests/test_hook_manager.lua
git commit -m "test: add HookManager test"
```

---

### Task 12: Test ActionBase

**Files:**
- Create: `Scripts/tests/test_action_base.lua`

- [ ] **Step 1: Write test**

```lua
-- Scripts/tests/test_action_base.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local ActionBase = Reg.lib("ActionBase")
local HookManager = Reg.lib("HookManager")

-- Define a test subclass
local TestAction = ActionBase:extend("test.action_base_test")

function TestAction:define_state()
    return {
        persistent = { my_flag = false, counter = 0 },
        transient = { _cache = {}, _log_lines = {} },
    }
end

function TestAction:define_hooks()
    return {
        test_hook = {
            spec = "hexm.client.ui.base.text:Text:set_text",
            post_exec = function(self, args, results, tb)
                self.state._log_lines[#self.state._log_lines + 1] = "called"
            end,
        },
    }
end

function TestAction:on_enable()
    self:hook_all()
end

-- Create instance
local mod = TestAction:new()

T.run("module registered in KURO_modules", function()
    T.assert_not_nil(_G.KURO_modules["test.action_base_test"])
end)

T.run("state initialized with defaults", function()
    T.assert_false(mod.state.my_flag, "my_flag default")
    T.assert_eq(mod.state.counter, 0, "counter default")
    T.assert_type(mod.state._cache, "table", "_cache type")
end)

T.run("starts disabled", function()
    T.assert_false(mod:is_enabled())
end)

T.run("enable sets is_enabled", function()
    mod:enable()
    T.assert_true(mod:is_enabled())
end)

T.run("hooks active after enable (on_enable hooks all)", function()
    T.assert_true(mod:is_hooked("test_hook"))
end)

T.run("disable unhooks and sets is_enabled false", function()
    mod:disable()
    T.assert_false(mod:is_enabled())
    T.assert_false(mod:is_hooked("test_hook"))
end)

T.run("individual hook control", function()
    mod:hook("test_hook")
    T.assert_true(mod:is_hooked("test_hook"))
    mod:unhook("test_hook")
    T.assert_false(mod:is_hooked("test_hook"))
end)

T.run("toggle works", function()
    mod:toggle()
    T.assert_true(mod:is_enabled())
    mod:toggle()
    T.assert_false(mod:is_enabled())
end)

T.run("persistent state survives reload simulation", function()
    mod.state.my_flag = true
    mod.state.counter = 42
    mod.state._cache = { "dirty" }

    -- Simulate reload
    mod:_init_state()

    T.assert_true(mod.state.my_flag, "persistent: my_flag kept")
    T.assert_eq(mod.state.counter, 42, "persistent: counter kept")
    T.assert_eq(#mod.state._cache, 0, "transient: _cache reset")
end)

-- Cleanup
HookManager.clear_module("test.action_base_test")
_G.KURO_modules["test.action_base_test"] = nil
_G.KURO_state["test.action_base_test"] = nil

T.summary()
```

- [ ] **Step 2: Verify via injection**

```powershell
python ..\inject\debug.py "dofile('C:\\temp\\Where Winds Meet\\Scripts\\tests\\test_action_base.lua')"
```
Expected: All tests PASS.

- [ ] **Step 3: Commit**

```bash
git add Scripts/tests/test_action_base.lua
git commit -m "test: add ActionBase test"
```

---

## Chunk 4: Migrate Simple Actions (buffs, world, combat)

### Task 13: Migrate buffs.lua

**Files:**
- Modify: `Scripts/actions/buffs.lua`
- Create: `Scripts/tests/test_buffs.lua`

- [ ] **Step 1: Rewrite buffs.lua using ActionBase**

```lua
-- Scripts/actions/buffs.lua
local ActionBase = _G.Reg.lib("ActionBase")

local Buffs = ActionBase:extend("actions.buffs")

-- ── Constants ──
local PRESETS = {
    combat = { 109040, 109041, 104027, 102704, 102701, 102452, 77120 },
    hunting = { 104051 },
    farming = { 104027 },
    mining = { 104031 },
    fishing = { 104045 },
    crafting = { 104021 },
}

local DEFAULT_DURATION = 604800 -- 7 days

-- ── State ──
function Buffs:define_state()
    return {
        persistent = { active_preset = nil },
        transient = {},
    }
end

-- No hooks — buff application uses game APIs directly
function Buffs:define_hooks() return {} end

-- ── Helpers ──

local function _get_combat_action()
    local ok, mod = pcall(portable.safe_import, "hexm.client.ui.windows.gm.gm_combat.combat_train_action")
    if ok and mod then return mod end
    return nil
end

-- ── Public API ──

function Buffs:apply_buff(buff_id, duration)
    local mp = G.main_player
    if not mp then return false, "No main player" end
    if type(buff_id) ~= "number" then return false, "Invalid buff_id" end

    duration = duration or DEFAULT_DURATION

    -- Try player method
    if mp.add_buff then
        local ok, err = pcall(mp.add_buff, mp, buff_id, duration)
        if ok then
            self:log(string.format("Applied buff %d", buff_id))
            return true
        end
    end

    -- Try combat action
    local action = _get_combat_action()
    if action and action.add_buff then
        local ok, err = pcall(action.add_buff, buff_id)
        if ok then
            self:log(string.format("Applied buff %d via action", buff_id))
            return true
        end
    end

    self:log(string.format("Failed to apply buff %d", buff_id))
    return false, "No method available"
end

function Buffs:remove_buff(buff_id)
    local mp = G.main_player
    if not mp then return false end
    local eid = mp.entity_id
    local action = _get_combat_action()

    local methods = {
        { obj = action, name = "rm_buff", args = { buff_id } },
        { obj = action, name = "remove_buff", args = { buff_id, eid } },
        { obj = mp, name = "remove_buff", args = { mp, buff_id } },
        { obj = mp, name = "remove_buffs_by_No", args = { mp, buff_id } },
    }

    for _, m in ipairs(methods) do
        if m.obj and m.obj[m.name] then
            local ok = pcall(m.obj[m.name], table.unpack(m.args))
            if ok then
                self:log(string.format("Removed buff %d via %s", buff_id, m.name))
                return true
            end
        end
    end

    return false, "No method worked"
end

function Buffs:apply_preset(preset_name)
    local buffs = PRESETS[preset_name]
    if not buffs then
        self:log("Unknown preset: " .. tostring(preset_name))
        return 0, 0
    end

    local applied = 0
    for _, buff_id in ipairs(buffs) do
        if self:apply_buff(buff_id) then
            applied = applied + 1
        end
    end

    self.state.active_preset = preset_name
    self:log(string.format("Applied preset '%s': %d/%d", preset_name, applied, #buffs))
    return applied, #buffs
end

function Buffs:remove_preset(preset_name)
    local buffs = PRESETS[preset_name]
    if not buffs then return 0, 0 end

    local removed = 0
    for _, buff_id in ipairs(buffs) do
        if self:remove_buff(buff_id) then
            removed = removed + 1
        end
    end

    if self.state.active_preset == preset_name then
        self.state.active_preset = nil
    end

    self:log(string.format("Removed preset '%s': %d/%d", preset_name, removed, #buffs))
    return removed, #buffs
end

function Buffs:toggle_preset(preset_name, enabled)
    if enabled then
        return true, self:apply_preset(preset_name)
    else
        return false, self:remove_preset(preset_name)
    end
end

function Buffs:get_presets()
    return PRESETS
end

return Buffs:new()
```

- [ ] **Step 2: Write test**

```lua
-- Scripts/tests/test_buffs.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local mod = Reg.module("actions.buffs")

T.run("buffs module registered", function()
    T.assert_not_nil(mod, "module")
end)

T.run("has get_presets", function()
    local presets = mod:get_presets()
    T.assert_not_nil(presets.combat, "combat preset")
    T.assert_true(#presets.combat > 0, "combat has buffs")
end)

T.run("state has active_preset", function()
    T.assert_nil(mod.state.active_preset, "starts nil")
end)

T.summary()
```

- [ ] **Step 3: Verify**

```powershell
python ..\inject\debug.py "dofile('C:\\temp\\Where Winds Meet\\Scripts\\tests\\test_buffs.lua')"
```

- [ ] **Step 4: Commit**

```bash
git add Scripts/actions/buffs.lua Scripts/tests/test_buffs.lua
git commit -m "refactor: migrate buffs.lua to ActionBase"
```

---

### Task 14: Migrate world.lua

**Files:**
- Modify: `Scripts/actions/world.lua`
- Create: `Scripts/tests/test_world.lua`

- [ ] **Step 1: Rewrite world.lua using ActionBase**

```lua
-- Scripts/actions/world.lua
local ActionBase = _G.Reg.lib("ActionBase")

local World = ActionBase:extend("actions.world")

-- ── Constants ──
local SPEED_PRESETS = {
    { speed = 1.0, label = "Speed: OFF" },
    { speed = 1.5, label = "Speed: 1.5x" },
    { speed = 5.0, label = "Speed: 5x" },
    { speed = 20.0, label = "Speed: 20x" },
}

function World:define_state()
    return {
        persistent = { current_speed = 1.0 },
        transient = {},
    }
end

function World:define_hooks() return {} end

-- ── Helpers ──

local function _get_combat_action()
    local ok, mod = pcall(portable.safe_import, "hexm.client.ui.windows.gm.gm_combat.combat_train_action")
    if ok and mod then return mod end
    return nil
end

-- ── Public API ──

function World:set_speed(speed)
    local target = speed or 1.0
    local action = _get_combat_action()

    if action and action.set_game_speed then
        pcall(action.set_game_speed, target)
        self:log("Speed set via GM API: x" .. target)
        self.state.current_speed = target
        return true
    end

    if G then
        if G.dialog_global_time_scale ~= nil then
            G.dialog_global_time_scale = target
        end
        if G.space then
            local space = G.space
            if space.dialog_global_time_scale ~= nil then
                space.dialog_global_time_scale = target
            end
            if space.dialog_set_global_time_scale then
                pcall(space.dialog_set_global_time_scale, space, target)
            end
        end
        local mp = G.main_player
        if mp and mp.dialog_set_time_speed_scale then
            pcall(mp.dialog_set_time_speed_scale, mp, target > 1, target)
        end
    end

    self.state.current_speed = target
    self:log("Speed set via legacy: x" .. target)
    return true
end

function World:kill_npc()
    self:log("Kill NPC triggered")
    local count = 0
    local mp = G.main_player
    local action = _get_combat_action()

    if action then
        if action.set_npc_mortal then pcall(action.set_npc_mortal, true) end
        if action.kill_all_npc then pcall(action.kill_all_npc) end
    end

    if mp then
        local ok, target_id = pcall(function() return mp:get_lock_target_id() end)
        if ok and target_id and G.space then
            local target = G.space:get_entity(target_id)
            if target then
                pcall(target.do_direct_damage, target, 999999999, mp.entity_id, 0, 0, 0, 0)
                count = count + 1
            end
        end
    end

    local ok, entities = pcall(function() return MEntityManager:GetAOIEntities() end)
    if ok and entities and mp then
        for i = 1, #entities do
            local ent = entities[i]
            local ok_n, name = pcall(function() return ent:GetName() end)
            if ok_n and name and (name:find("AiAvatar") or name:find("Npc") or name:find("Boss")) then
                local eid = ent.entity_id
                if eid and G.space then
                    local target = G.space:get_entity(eid)
                    if target and target ~= mp then
                        pcall(target.do_direct_damage, target, 999999999, mp.entity_id, 0, 0, 0, 0)
                        count = count + 1
                    end
                end
            end
        end
    end

    self:log("Killed: " .. count)
    return count
end

function World:reset_crime()
    local ok, dec = pcall(portable.safe_import, "hexm.client.debug.gm.gm_decorator")
    if ok and dec and dec.gm_command_short_cuts and dec.gm_command_short_cuts.game then
        local cmds = dec.gm_command_short_cuts.game
        if cmds["$forbid_witness_wanfa"] then pcall(cmds["$forbid_witness_wanfa"], 1) end
        if cmds["$forbid_police_wanfa"] then pcall(cmds["$forbid_police_wanfa"], 1) end
    end
    self:log("Reset crime executed")
    return true
end

function World:disable_logs()
    local count = 0
    local ok, gm_combat = pcall(portable.safe_import, "hexm.client.debug.gm.gm_commands.gm_combat")
    if ok and gm_combat then
        if gm_combat.gm_forbid_behit_highlight then
            pcall(gm_combat.gm_forbid_behit_highlight, 1)
            count = count + 1
        end
        if gm_combat.gm_enable_stopframe_debug then
            pcall(gm_combat.gm_enable_stopframe_debug, 0)
            count = count + 1
        end
    end

    local ok2, gm_cutscene = pcall(portable.safe_import, "hexm.client.debug.gm.gm_commands.gm_cutscene")
    if ok2 and gm_cutscene and gm_cutscene.gm_cutscene_clear_log then
        pcall(gm_cutscene.gm_cutscene_clear_log)
        count = count + 1
    end

    self:log("Logging disabled (" .. count .. " items)")
    return true
end

function World:get_speed_presets()
    return SPEED_PRESETS
end

return World:new()
```

- [ ] **Step 2: Write test**

```lua
-- Scripts/tests/test_world.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local mod = _G.Reg.module("actions.world")

T.run("world module registered", function()
    T.assert_not_nil(mod)
end)

T.run("has speed presets", function()
    local presets = mod:get_speed_presets()
    T.assert_true(#presets > 0)
end)

T.run("state has current_speed", function()
    T.assert_eq(mod.state.current_speed, 1.0)
end)

T.summary()
```

- [ ] **Step 3: Verify and commit**

```bash
git add Scripts/actions/world.lua Scripts/tests/test_world.lua
git commit -m "refactor: migrate world.lua to ActionBase"
```

---

### Task 15: Migrate combat.lua

**Files:**
- Modify: `Scripts/actions/combat.lua`
- Create: `Scripts/tests/test_combat.lua`

- [ ] **Step 1: Rewrite combat.lua using ActionBase**

This is the most complex simple action — it has both hook-based features (infinite stamina, instant charge) and non-hook features (god mode via buffs, NPC blind via flag stacks).

```lua
-- Scripts/actions/combat.lua
local ActionBase = _G.Reg.lib("ActionBase")

local Combat = ActionBase:extend("actions.combat")

-- ── Constants ──
local BUFF_GOD_MODE = 70063
local BUFF_INVISIBLE = 108010
local BUFF_RECOVER = { 30383, 30363 }
local NPC_BLIND_REASON = "combat_mod_npc_blind"
local NPC_BLIND_PRIORITY = 999
local STAMINA_RES_ID = 5

function Combat:define_state()
    return {
        persistent = {
            god_mode = false,
            infinite_stamina = false,
            instant_charge = false,
            npc_blind = false,
        },
        transient = {},
    }
end

function Combat:define_hooks()
    return {
        -- Infinite stamina hooks
        stamina_skill_cost = {
            spec = "hexm.common.actionline.nodes.logic_nodes:SkillRelease:do_cost",
            override_orig_function = true,
            post_exec = function(self, original, ...)
                return nil
            end,
        },
        stamina_charge_drain = {
            spec = "hexm.common.actionline.nodes.action_nodes:ChargeNode:_start_res_consume",
            override_orig_function = true,
            post_exec = function(self, original, ...)
                return nil
            end,
        },
        stamina_auto_consume = {
            spec = "hexm.common.base.combat_resource_base:CombatResourceBase:skill_auto_consume_res",
            override_orig_function = true,
            post_exec = function(self, original, ...)
                return nil
            end,
        },
        stamina_resource_consume = {
            spec = "hexm.client.fake_server.entities.player_avatar:FakePlayerAvatar:consume_resource",
            override_orig_function = true,
            post_exec = function(self, original, self_entity, res_id, ...)
                if res_id ~= STAMINA_RES_ID then
                    return original(self_entity, res_id, ...)
                end
                return 0
            end,
        },
        -- Instant charge hooks
        charge_start = {
            spec = "hexm.common.actionline.nodes.action_nodes:ChargeNode:start",
            override_orig_function = true,
            post_exec = function(self, original, self_node, graph, ...)
                if not self_node or not graph then
                    return original(self_node, graph, ...)
                end
                local context = graph.context
                if not context or not context.entity then
                    return original(self_node, graph, ...)
                end

                local DateTimeManager = portable.safe_import("hexm.common.datetime_manager")
                DateTimeManager = DateTimeManager and DateTimeManager.DateTimeManager or DateTimeManager
                local now = DateTimeManager and DateTimeManager.now and DateTimeManager:now()
                if not now then
                    return original(self_node, graph, ...)
                end

                local charge_time = math.min(context.charge_time or self_node.max_time, self_node.max_time)
                if not charge_time or charge_time <= 0 then
                    return original(self_node, graph, ...)
                end

                local speed = context.get and context:get("global_speed", 1.0) or 1.0
                charge_time = charge_time / speed
                context.charge_start_ts = now - charge_time
                context.charge_dur = charge_time

                pcall(function()
                    graph:finish_node(self_node, {
                        __out__ = 1,
                        timeout = 1,
                        charge_lv = 2,
                    })
                end)
                return nil
            end,
        },
        filter_targets = {
            spec = "hexm.common.actionline.nodes.target_nodes:FilterTargetsInBattle:start",
            override_orig_function = true,
            post_exec = function(self, original, ...)
                return {}
            end,
        },
    }
end

-- ── Buff helpers (non-hook) ──

local function _apply_buff(buff_id)
    local mp = G.main_player
    if not mp then return false end
    local ok = pcall(function() mp.fake_server.buff:add_buff(buff_id, mp.id) end)
    if ok then return true end
    if mp.add_buff then
        local ok2 = pcall(function()
            mp:add_buff(buff_id, mp.id, { duration = -1, persistent = false, reason = "combat_mod", ignore_dead = true })
        end)
        if ok2 then return true end
    end
    return false
end

local function _remove_buff(buff_id)
    local mp = G.main_player
    if not mp then return end
    pcall(function() mp.fake_server.buff:remove_buffs_by_No({ buff_id }, mp.id, "combat_mod") end)
end

-- ── God Mode (buff-based) ──

function Combat:set_god_mode(enabled)
    if enabled then
        _apply_buff(BUFF_GOD_MODE)
    else
        _remove_buff(BUFF_GOD_MODE)
    end
    self.state.god_mode = enabled
    self:log("God Mode: " .. (enabled and "ON" or "OFF"))
end

-- ── Infinite Stamina (hook-based) ──

function Combat:set_infinite_stamina(enabled)
    if enabled then
        self:hook("stamina_skill_cost")
        self:hook("stamina_charge_drain")
        self:hook("stamina_auto_consume")
        self:hook("stamina_resource_consume")
    else
        self:unhook("stamina_skill_cost")
        self:unhook("stamina_charge_drain")
        self:unhook("stamina_auto_consume")
        self:unhook("stamina_resource_consume")
    end
    self.state.infinite_stamina = enabled
    self:log("Infinite Stamina: " .. (enabled and "ON" or "OFF"))
end

-- ── Instant Charge (hook-based) ──

function Combat:set_instant_charge(enabled)
    if enabled then
        self:hook("charge_start")
        self:hook("filter_targets")
    else
        self:unhook("charge_start")
        self:unhook("filter_targets")
    end
    self.state.instant_charge = enabled
    self:log("Instant Charge: " .. (enabled and "ON" or "OFF"))
end

-- ── NPC Blind (flag-stack based, non-hook) ──

function Combat:set_npc_blind(enabled)
    local mp = G.main_player
    if not mp then return false, "No main player" end
    local fs = mp.fake_server
    if not fs then return false, "No fake_server" end

    if enabled then
        pcall(function() mp:push_sight_reverse_enable(NPC_BLIND_REASON, nil, false, NPC_BLIND_PRIORITY) end)
        pcall(function() fs:get_aggro_reverse():push_aggro_reverse_enabled(NPC_BLIND_REASON, false, NPC_BLIND_PRIORITY) end)
        pcall(function() fs:clear_aggro_reverse(NPC_BLIND_REASON) end)
        pcall(function() fs:push_alert_reverse_enabled(NPC_BLIND_REASON, false, NPC_BLIND_PRIORITY) end)
        pcall(function() fs:clear_reverse_alert_table() end)
        pcall(function() fs.ignore_alert = true end)
    else
        pcall(function() mp:pop_sight_reverse_enable(NPC_BLIND_REASON) end)
        pcall(function() fs:get_aggro_reverse():pop_aggro_reverse_enabled(NPC_BLIND_REASON) end)
        pcall(function() fs:pop_alert_reverse_enabled(NPC_BLIND_REASON) end)
        pcall(function() mp:pop_alert_reverse_enabled(NPC_BLIND_REASON) end)
        pcall(function() fs.ignore_alert = false end)
    end

    self.state.npc_blind = enabled
    self:log("NPC Blind: " .. (enabled and "ON" or "OFF"))
    return true
end

-- ── Recover ──

function Combat:recover()
    for _, buff_id in ipairs(BUFF_RECOVER) do
        _apply_buff(buff_id)
    end
    return true
end

-- ── Reload: re-apply non-hook features ──

function Combat:on_reload()
    if self.state.god_mode then _apply_buff(BUFF_GOD_MODE) end
    if self.state.npc_blind then self:set_npc_blind(true) end
end

return Combat:new()
```

- [ ] **Step 2: Write test**

```lua
-- Scripts/tests/test_combat.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local mod = _G.Reg.module("actions.combat")

T.run("combat module registered", function()
    T.assert_not_nil(mod)
end)

T.run("has all state keys", function()
    T.assert_false(mod.state.god_mode)
    T.assert_false(mod.state.infinite_stamina)
    T.assert_false(mod.state.instant_charge)
    T.assert_false(mod.state.npc_blind)
end)

T.run("set_infinite_stamina hooks correctly", function()
    mod:set_infinite_stamina(true)
    T.assert_true(mod:is_hooked("stamina_skill_cost"))
    T.assert_true(mod:is_hooked("stamina_charge_drain"))
    T.assert_true(mod.state.infinite_stamina)

    mod:set_infinite_stamina(false)
    T.assert_false(mod:is_hooked("stamina_skill_cost"))
    T.assert_false(mod.state.infinite_stamina)
end)

T.run("set_instant_charge hooks correctly", function()
    mod:set_instant_charge(true)
    T.assert_true(mod:is_hooked("charge_start"))
    T.assert_true(mod:is_hooked("filter_targets"))

    mod:set_instant_charge(false)
    T.assert_false(mod:is_hooked("charge_start"))
end)

T.run("disable unhooks all", function()
    mod:set_infinite_stamina(true)
    mod:set_instant_charge(true)
    mod:disable()
    T.assert_false(mod:is_hooked("stamina_skill_cost"))
    T.assert_false(mod:is_hooked("charge_start"))
    T.assert_false(mod:is_enabled())
end)

T.summary()
```

- [ ] **Step 3: Verify and commit**

```bash
git add Scripts/actions/combat.lua Scripts/tests/test_combat.lua
git commit -m "refactor: migrate combat.lua to ActionBase with independent hooks"
```

---

## Chunk 5: Remaining Action Migrations

**Note:** Each remaining action follows the same pattern as Tasks 13-15. The implementation agent should:

1. Read the backup version of each file
2. Rewrite using ActionBase:extend() pattern
3. Replace `Utils.safe_import` with `portable.safe_import`
4. Replace `Utils.safe_call` with direct `pcall`
5. Replace `Utils.safe_dofile` with direct `dofile` + pcall
6. Replace `Utils.get_main_player()` with `G.main_player`
7. Replace `_log()` with `self:log()`
8. Replace `Reg.get/set` state with `self.state`
9. Define hooks in `define_hooks()` with named keys
10. Write test file
11. Verify via injection
12. Commit

### Task 16: Migrate suit_skins.lua
### Task 17: Migrate effects.lua
### Task 18: Migrate weapon_skins.lua
### Task 19: Migrate xinfa_buffs.lua
### Task 20: Migrate gm_panel.lua
### Task 21: Migrate spy.lua
### Task 22: Migrate trace.lua
### Task 23: Migrate dump.lua
### Task 24: Migrate parry.lua (offline)
### Task 25: Migrate parry_online.lua (rename from parry_v2.lua)
### Task 26: Migrate autoloot.lua
### Task 27: Migrate sync_observer.lua

Each task follows the identical pattern shown in Tasks 13-15. Read the backup, apply the ActionBase pattern, test, commit.

**Priority order** (simplest to most complex):
1. suit_skins, effects, weapon_skins, xinfa_buffs (data + hooks pattern)
2. gm_panel, trace, dump (utility actions)
3. spy (debug hook + wrapper hooks)
4. parry, parry_online, autoloot, sync_observer (complex state + hooks)

---

## Chunk 6: Update Standalone Lib Modules

### Task 28: Update anticheat_bypass.lua

**Files:**
- Modify: `Scripts/lib/anticheat_bypass.lua`

- [ ] **Step 1: Replace Utils references**

Search and replace in anticheat_bypass.lua:
- `Utils.safe_import(...)` → `portable.safe_import(...)`
- `Utils.dump_value(...)` → `Serialize.dump_value(...)` (where `Serialize = _G.KURO_lib.Serialize`)
- `Utils.create_empty_proxy()` → inline the proxy creation (copy the 10-line implementation from cocos.lua: `Cocos.create_empty_proxy()` or `_G.KURO_lib.Cocos.create_empty_proxy()`)
- State: move from `Reg.get/set("ACB_STATE")` to `_G.KURO_state["lib.anticheat_bypass"]`

- [ ] **Step 2: Verify the module still loads**

```powershell
python ..\inject\debug.py "local acb = dofile('C:\\temp\\Where Winds Meet\\Scripts\\lib\\anticheat_bypass.lua'); print('ACB loaded: ' .. tostring(acb ~= nil))"
```

- [ ] **Step 3: Commit**

```bash
git add Scripts/lib/anticheat_bypass.lua
git commit -m "refactor: remove Utils dependency from anticheat_bypass.lua"
```

---

### Task 29: Update dump_core.lua and trace_core.lua

**Files:**
- Modify: `Scripts/lib/dump_core.lua`
- Modify: `Scripts/lib/trace_core.lua`

- [ ] **Step 1: Replace Utils references in both files**

In both files, change:
```lua
local Utils = Reg.get("Utils")
```
to:
```lua
local Serialize = _G.KURO_lib.Serialize
```

Replace `Utils.dump_value(...)` → `Serialize.dump_value(...)`.
Replace `Utils.safe_import(...)` → `portable.safe_import(...)`.
Replace `Utils.ensure_dir(...)` → inline powershell directory creation (copy from logger.lua's `_ensure_dir`).

- [ ] **Step 2: Commit**

```bash
git add Scripts/lib/dump_core.lua Scripts/lib/trace_core.lua
git commit -m "refactor: remove Utils dependency from dump_core and trace_core"
```

---

### Task 30: Delete utils.lua and hook_interceptor.lua

**Files:**
- Delete: `Scripts/lib/utils.lua`
- Delete: `Scripts/lib/hook_interceptor.lua`

- [ ] **Step 1: Verify no remaining references**

Search for `Reg.get("Utils")` and `safe_dofile.*hook_interceptor` across all Scripts/ files. Should find zero matches outside backup/.

- [ ] **Step 2: Delete files**

```bash
rm Scripts/lib/utils.lua Scripts/lib/hook_interceptor.lua
```

- [ ] **Step 3: Commit**

```bash
git add -u Scripts/lib/
git commit -m "chore: delete utils.lua and hook_interceptor.lua"
```

---

## Chunk 7: UI Refactoring

### Task 31: Create selector_factory.lua

**Files:**
- Create: `Scripts/ui/lib/selector_factory.lua`

- [ ] **Step 1: Write selector factory**

```lua
-- Scripts/ui/lib/selector_factory.lua
-- Generic selector creation from declarative config.
-- Replaces 7 individual selector wrapper files.

local SelectorFactory = {}

local Reg = _G.Reg
local Constants = Reg.lib("Constants")
local Logger = Reg.lib("Logger")

local function _log(msg)
    if Logger then Logger.log("[SelectorFactory] " .. msg) end
end

-- Lazy-load ItemSelector and DualSelector
local _item_selector, _dual_selector

local function _get_item_selector()
    if not _item_selector then
        _item_selector = dofile(Constants.SCRIPTS_ROOT .. "\\ui\\components\\item_selector.lua")
    end
    return _item_selector
end

local function _get_dual_selector()
    if not _dual_selector then
        _dual_selector = dofile(Constants.SCRIPTS_ROOT .. "\\ui\\components\\dual_selector.lua")
    end
    return _dual_selector
end

--[[
    Create a selector from declarative config.

    Single selector config:
    {
        type = "single",
        action = "suit_skins",      -- module name in KURO_modules
        data_fn = "get_list",        -- method on action to get items
        apply_fn = "apply",          -- method on action to apply selection
        display_fn = "get_display_name",  -- method or function(item) for display text
        id_fn = "get_id",           -- optional: method or function(item) for unique ID
        memory_key = "LAST_SUIT",   -- Reg key for persisting selection
        title = "Suit Selector",
        enable_search = true,
        empty_message = "No items available",
    }

    Dual selector config:
    {
        type = "dual",
        action = "effects",
        left = { data_fn = "get_kungfu_list", display_fn = ..., title = "Left" },
        right = { data_fn = "get_effect_list", display_fn = ..., title = "Right" },
        apply_fn = "apply_dual",
        memory_key = "LAST_DUAL_EFFECT",
        title = "Effect Selector",
    }
]]
function SelectorFactory.show(config, user_callbacks)
    user_callbacks = user_callbacks or {}
    local action_name = "actions." .. config.action
    local action = Reg.module(action_name)

    if not action then
        _log("Action module not found: " .. action_name)
        return nil
    end

    if config.type == "dual" then
        return SelectorFactory._show_dual(config, action, user_callbacks)
    else
        return SelectorFactory._show_single(config, action, user_callbacks)
    end
end

function SelectorFactory._show_single(config, action, user_callbacks)
    local ItemSelector = _get_item_selector()
    if not ItemSelector then
        _log("ItemSelector not loaded")
        return nil
    end

    -- Get items from action module
    local items = action[config.data_fn](action)
    if not items then
        _log("No data from " .. config.data_fn)
        items = {}
    end

    -- Build display function
    local display_fn
    if type(config.display_fn) == "function" then
        display_fn = config.display_fn
    elseif type(config.display_fn) == "string" and action[config.display_fn] then
        display_fn = function(item) return action[config.display_fn](action, item) end
    else
        display_fn = function(item) return item.name or tostring(item) end
    end

    -- Build ID function
    local id_fn
    if type(config.id_fn) == "function" then
        id_fn = config.id_fn
    elseif type(config.id_fn) == "string" and action[config.id_fn] then
        id_fn = function(item) return action[config.id_fn](action, item) end
    else
        id_fn = function(item) return item.id or item.no or tostring(item) end
    end

    return ItemSelector.show({
        title = config.title or "Selector",
        items = items,
        get_display_name = display_fn,
        get_id = id_fn,
        on_apply = function(item)
            if action[config.apply_fn] then
                return action[config.apply_fn](action, item)
            end
            return false
        end,
        on_select = function(item, success)
            if user_callbacks.on_select then
                user_callbacks.on_select(item, success, action)
            end
        end,
        on_close = user_callbacks.on_close,
        instance_name = config.memory_key and ("VAR_" .. config.memory_key) or nil,
        enable_search = config.enable_search ~= false,
        empty_message = config.empty_message or "No items available",
    })
end

function SelectorFactory._show_dual(config, action, user_callbacks)
    local DualSelector = _get_dual_selector()
    if not DualSelector then
        _log("DualSelector not loaded")
        return nil
    end

    local left_items = action[config.left.data_fn](action)
    local right_items = action[config.right.data_fn](action)

    local function _make_display(cfg)
        if type(cfg.display_fn) == "function" then return cfg.display_fn end
        if type(cfg.display_fn) == "string" and action[cfg.display_fn] then
            return function(item) return action[cfg.display_fn](action, item) end
        end
        return function(item) return item.name or tostring(item) end
    end

    return DualSelector.show({
        title = config.title or "Dual Selector",
        left = {
            title = config.left.title or "Left",
            items = left_items or {},
            get_display_name = _make_display(config.left),
            get_id = function(item) return item.id or item.no or tostring(item) end,
            empty_message = config.left.empty_message or "No items",
        },
        right = {
            title = config.right.title or "Right",
            items = right_items or {},
            get_display_name = _make_display(config.right),
            get_id = function(item) return item.id or item.no or tostring(item) end,
            empty_message = config.right.empty_message or "No items",
        },
        on_apply = function(left_item, right_item)
            if action[config.apply_fn] then
                return action[config.apply_fn](action, left_item, right_item)
            end
            return false
        end,
        on_select = function(left_item, right_item, success)
            if user_callbacks.on_select then
                user_callbacks.on_select(left_item, right_item, success, action)
            end
        end,
        on_close = user_callbacks.on_close,
        instance_name = config.memory_key and ("VAR_" .. config.memory_key) or nil,
        enable_search = config.enable_search ~= false,
    })
end

function SelectorFactory.close(config)
    local instance_name = config.memory_key and ("VAR_" .. config.memory_key) or nil
    if not instance_name then return end

    if config.type == "dual" then
        local DualSelector = _get_dual_selector()
        if DualSelector then DualSelector.close(instance_name) end
    else
        local ItemSelector = _get_item_selector()
        if ItemSelector then ItemSelector.close(instance_name) end
    end
end

return SelectorFactory
```

- [ ] **Step 2: Commit**

```bash
git add Scripts/ui/lib/selector_factory.lua
git commit -m "feat: add SelectorFactory for declarative selector configs"
```

---

### Task 32: Add selector configs to menu_config.lua

**Files:**
- Modify: `Scripts/ui/menu_config.lua`

- [ ] **Step 1: Add selectors table to menu_config.lua**

Read the current menu_config.lua first, then add a `selectors` table at the end (before the return statement). The configs should match what the 7 deleted selector files did. Pull the exact data_fn/apply_fn/display_fn names from each backup selector file.

- [ ] **Step 2: Update menu item handlers to use SelectorFactory**

For each menu item that currently calls a selector file (e.g., `SuitSelector.show()`), change to `SelectorFactory.show(MenuConfig.selectors.suit)`.

- [ ] **Step 3: Commit**

```bash
git add Scripts/ui/menu_config.lua
git commit -m "feat: add declarative selector configs to menu_config"
```

---

### Task 33: Simplify menu_controller.lua

**Files:**
- Modify: `Scripts/ui/controllers/menu_controller.lua`

- [ ] **Step 1: Replace individual handler methods**

Read the current file. Replace the 20+ individual `handle_*` methods with:
- Generic `handle_toggle(item_id, enabled)` — calls `Reg.module():enable/disable`
- Generic `handle_selector(selector_name)` — uses `SelectorFactory.show(config)`
- Keep only truly unique handlers (e.g., spy input, dump module path)

Replace `Utils.safe_dofile(...)` references for loading actions with `Reg.module("actions.xxx")`.

- [ ] **Step 2: Commit**

```bash
git add Scripts/ui/controllers/menu_controller.lua
git commit -m "refactor: simplify menu_controller with generic handlers"
```

---

### Task 34: Delete selector wrapper files

**Files:**
- Delete: 7 selector files in `Scripts/ui/components/`

- [ ] **Step 1: Delete**

```bash
rm Scripts/ui/components/suit_selector.lua
rm Scripts/ui/components/weapon_selector.lua
rm Scripts/ui/components/bow_selector.lua
rm Scripts/ui/components/effect_selector.lua
rm Scripts/ui/components/dual_effect_selector.lua
rm Scripts/ui/components/dual_weapon_selector.lua
rm Scripts/ui/components/xinfa_selector.lua
```

- [ ] **Step 2: Commit**

```bash
git add -u Scripts/ui/components/
git commit -m "chore: delete selector wrappers replaced by SelectorFactory"
```

---

## Chunk 8: Finalize

### Task 35: Create run_all.lua

**Files:**
- Create: `Scripts/tests/run_all.lua`

- [ ] **Step 1: Write run_all.lua**

```lua
-- Scripts/tests/run_all.lua
local test_dir = "C:\\temp\\Where Winds Meet\\Scripts\\tests\\"
local tests = {
    "test_bootstrap",
    "test_hook_manager",
    "test_action_base",
    "test_buffs",
    "test_world",
    "test_combat",
    -- Add more as migrated
}

local passed, failed = 0, 0
for _, name in ipairs(tests) do
    print("\n>>> " .. name .. " <<<")
    local ok, err = pcall(dofile, test_dir .. name .. ".lua")
    if ok then
        passed = passed + 1
    else
        failed = failed + 1
        print("SUITE FAIL: " .. name .. " -- " .. tostring(err))
    end
end

print(string.format("\n=== FINAL: %d suites passed, %d suites failed ===", passed, failed))
```

- [ ] **Step 2: Run full test suite**

```powershell
python ..\inject\debug.py "dofile('C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_all.lua')"
```
Expected: All suites pass.

- [ ] **Step 3: Commit**

```bash
git add Scripts/tests/run_all.lua
git commit -m "feat: add run_all.lua test suite runner"
```

---

### Task 36: Update IMPLEMENT.md

**Files:**
- Modify: `Scripts/IMPLEMENT.md` (at project root: `C:\temp\Where Winds Meet\IMPLEMENT.md`)

- [ ] **Step 1: Rewrite IMPLEMENT.md**

Replace with the new structure: Quick Start Templates (adding new action, menu item, selector, hook), Architecture Overview, Runtime Patterns, Verification, Common Pitfalls. All templates should be copy-paste ready with the ActionBase pattern.

Reference the spec document for architecture details. Keep it concise.

- [ ] **Step 2: Commit**

```bash
git add IMPLEMENT.md
git commit -m "docs: update IMPLEMENT.md with new ActionBase patterns and templates"
```

---

### Task 37: Final verification

- [ ] **Step 1: Run full test suite**

```powershell
python ..\inject\debug.py "dofile('C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_all.lua')"
```

- [ ] **Step 2: Test menu loads**

```powershell
python ..\inject\debug.py "dofile('C:\\temp\\Where Winds Meet\\Scripts\\lib\\bootstrap.lua'); dofile('C:\\temp\\Where Winds Meet\\Scripts\\ui\\menu.lua')"
```

- [ ] **Step 3: Verify no Utils references remain**

```bash
grep -r "Reg.get(\"Utils\")" Scripts/ --include="*.lua" | grep -v backup/
grep -r "Utils.safe_import" Scripts/ --include="*.lua" | grep -v backup/
```
Expected: zero matches.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "refactor: complete codebase refactoring to ActionBase + HookManager"
```
