---
name: implement
description: TDD-first workflow for implementing features, fixing bugs, and verifying behavior in the live injected game runtime. Strict red-green-refactor cycle with probe-driven API discovery.
---

# When To Use

- Add a new feature or action module
- Fix a bug
- Extend an existing script/action
- Add data export or debug tooling
- Discover unknown game APIs (probe tests)
- Verify behavior in the live injected runtime

Do not use for pure brainstorming, architecture discussion without code changes, or broad reverse engineering reports.


# Core Rules

1. **Test first, code second.** Write the failing test before the implementation. No exceptions.
2. **Probe before assuming.** When interacting with unknown game APIs, write a probe test to discover the shape before implementing.
3. **Inspect the existing codebase first.** Do not design from memory.
4. **Reuse existing helpers, loaders, logging, and output paths** before adding new ones.
5. **Prefer live runtime source of truth** over static guesses.
6. **Keep edits local and minimal.**
7. **Verify in the live runtime.** A code change without runtime confirmation is incomplete.
8. **`Server reply: OK` proves nothing.** Always read the log file to confirm success.


# Source Priorities

1. Live runtime objects and existing workspace scripts
2. `Scripts/source_decompiled/`
3. `Scripts/data/DirObject/`
4. Existing local logs in `Scripts/logs/`

Use decompiled code to learn patterns before implementing.


---

# TDD Workflow (Mandatory)

Every implementation task follows this strict cycle. **Do not skip steps.**

## Phase 0: Probe (when touching unknown APIs)

When the task involves game APIs you haven't verified, write a **probe test** first.

### Probe test template

```lua
-- Scripts/tests/probe_<topic>.lua
-- Probe: Discover API shape for <target>
-- Run: dofile('C:/temp/Where Winds Meet/Scripts/tests/probe_<topic>.lua')

pcall(function()
    local f = io.open("C:/temp/Where Winds Meet/Scripts/logs/probe_<topic>.txt", "w")
    if f then f:close() end
end)

_G.print_file = "probe_<topic>.txt"

local function log(msg)
    print("[PROBE_<TOPIC>] " .. msg)
end

local function safe(fn, fallback)
    local ok, val = pcall(fn)
    if ok then return val end
    return fallback
end

-- === PROBE TESTS ===
-- Test each API method, parameter combination, return shape
-- Always test: positive case, negative case, edge cases

log(">>> TEST 1: <description>")
local ok, result = pcall(function() return <api_call> end)
log(string.format("  result: ok=%s type=%s val=%s", tostring(ok), type(result), tostring(result)))

-- ... more tests ...

log("\n========== PROBE COMPLETE ==========")
_G.print_file = nil
```

### Probe rules
- Output to `Scripts/logs/probe_<topic>.txt` via `_G.print_file`
- Wrap every call in `pcall()` — probes must never crash
- Test positive, negative, and edge cases
- Log types, shapes, and values — not just pass/fail
- Read the log file after running — `Server reply: OK` means nothing

### Run a probe

```powershell
.\run_test.ps1 -Probe probe_<topic>
```

Then **read** `Scripts/logs/probe_<topic>.txt` to learn the API shape.


## Phase 1: RED — Write a Failing Test

Before writing any implementation code:

1. Create `Scripts/tests/test_<name>.lua`
2. Write tests for the expected behavior (minimum 5 — see checklist below)
3. Register in `run_all.lua` (both `action_files` and `test_suites`)
4. Run the full test suite — **confirm the new tests FAIL**

```powershell
.\run_test.ps1 -Suite
```

### Minimum 5 tests per module (mandatory)

```lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local mod = Reg.module("actions.my_module")

-- 1. Module registered
T.run("module registered", function()
    T.assert_not_nil(mod, "module")
end)

-- 2. Is ActionBase subclass
T.run("is ActionBase subclass", function()
    T.assert_not_nil(mod.state, "has state")
    T.assert_not_nil(mod.is_enabled, "has is_enabled method")
end)

-- 3. State keys correct types
T.run("state initialized", function()
    T.assert_type(mod.state.my_flag, "boolean")
end)

-- 4. Hook lifecycle
T.run("hook lifecycle", function()
    mod:hook("my_hook")
    T.assert_true(mod:is_hooked("my_hook"))
    mod:unhook("my_hook")
    T.assert_false(mod:is_hooked("my_hook"))
end)

-- 5. Enable/disable
T.run("enable disable", function()
    mod:enable()
    T.assert_true(mod:is_enabled())
    mod:disable()
    T.assert_false(mod:is_enabled())
end)

T.summary()
```

### Test assertion API

| Method | Purpose |
|--------|---------|
| `T.run(name, fn)` | Run a named test (pcall-wrapped) |
| `T.assert_eq(actual, expected, label)` | Equality |
| `T.assert_true(val, label)` | Boolean true |
| `T.assert_false(val, label)` | Boolean false |
| `T.assert_nil(val, label)` | Nil check |
| `T.assert_not_nil(val, label)` | Non-nil check |
| `T.assert_type(val, type_str, label)` | Type check |
| `T.summary()` | Print `=== RESULTS: N passed, M failed ===` |
| `T.reset()` | Reset counters |

### State testing caveat

Persistent state survives across runs. Use `assert_type(mod.state.key, "type")` instead of `assert_eq(mod.state.key, default_value)` for persistent keys.


## Phase 2: GREEN — Implement Minimum Code to Pass

1. Read the target file and related modules
2. Read decompiled code for API patterns
3. Write the minimum implementation to make tests pass
4. Format: `uv run stylua --syntax Lua54 <changed_files>`
5. Run the full suite — **confirm ALL GREEN**

```powershell
.\run_test.ps1 -Suite
```

Then **read** `Scripts/logs/test_results.txt` — look for `ALL GREEN`.


## Phase 3: REFACTOR — Clean Up While Green

Only after ALL GREEN:
- Extract helpers, simplify logic, improve naming
- Run the full suite after every change — must stay ALL GREEN
- Do not add features in this phase


## Phase 4: VERIFY — Runtime Confirmation

Run the full suite in the live game and confirm:

```powershell
.\run_test.ps1 -Suite
```

### Completion checklist

Before closing the task, **every box must be checked**:

- [ ] Test file exists at `Scripts/tests/test_<name>.lua` with ≥5 tests
- [ ] Test file registered in `run_all.lua` (`action_files` + `test_suites`)
- [ ] `Scripts/logs/test_results.txt` shows `ALL GREEN`
- [ ] No banned patterns (see Coding Rules below)
- [ ] Lua files formatted with `stylua`
- [ ] Runtime logs in `Scripts/logs/script_debug.txt` confirm execution


---

# Architecture Quick Reference

## Global Registry (`_G.Reg`)

| Need | API | Example |
|------|-----|---------|
| Get a lib | `_G.Reg.lib(name)` | `_G.Reg.lib("Serialize")` |
| Get an action module | `_G.Reg.module(name)` | `_G.Reg.module("actions.combat")` |
| Get/create state table | `_G.Reg.state(name)` | Inside ActionBase: just use `self.state` |
| List loaded modules | `_G.Reg.list_modules()` | Returns sorted name list |
| Reload all modules | `_G.Reg.reload_all()` | Deactivates hooks, clears modules, preserves state |
| Raw namespace table | `_G.Reg._ns(name)` | `_G.Reg._ns("hooks")` — for core lib files only |

**Available libs:** `Constants`, `Logger`, `Serialize`, `Cocos`, `Hooks`, `HookManager`, `ActionBase`

## ActionBase Pattern

Every action module extends `ActionBase`. Reference modules: `effects.lua`, `combat.lua`, `gm_panel.lua`.

```lua
local ActionBase = _G.Reg.lib("ActionBase")
local MyModule = ActionBase:extend("actions.my_module")

-- Constants (scalar only)
local SOME_ID = 12345
local MODULE_PATH = "hexm.some.module"

-- State: ALL data here
function MyModule:define_state()
    return {
        persistent = { is_enabled = false, user_setting = "default" },
        transient = { cache = {}, temp_data = {} },
    }
end

-- Hooks: ALL hooks here
function MyModule:define_hooks()
    return {
        my_hook = {
            spec = "hexm.module:Class:method",
            override_orig_function = true,
            post_exec = function(self_action, original, self_target, ...)
                return original(self_target, ...)
            end,
        },
    }
end

-- Private methods (underscore prefix)
function MyModule:_helper() end

-- Public API
function MyModule:do_something()
    self:hook("my_hook")
    self.state.user_setting = "changed"
end

return MyModule:new()
```

## Hook System

Two hook types, auto-detected from spec:
- **3 parts** `"module:Class:method"` → method hook
- **2 parts** `"module:function"` → function hook

Two callback modes:
- **Override** (`override_orig_function = true`): `function(self_action, original, self_target, ...)` — you control `original`
- **Observe** (default): `function(self_action, args, results, traceback)` — original runs first

Hook lifecycle: `self:hook("name")` → `self:is_hooked("name")` → `self:unhook("name")`

Dynamic hooks (target chosen at runtime):
```lua
local HookManager = _G.Reg.lib("HookManager")
HookManager.register(self._name, "dynamic_hook", { spec = spec_string, ... })
self:hook("dynamic_hook")
```

## State Lifecycle

- **persistent**: Survives reload. User settings, toggles, cached data.
- **transient**: Resets to defaults on reload. Caches, temp buffers.
- `is_enabled` should be in persistent if the module uses it.
- Inside ActionBase: access via `self.state.key`, never via `_G.Reg.state()`.

## Reload Mechanism

When `bootstrap.lua` is re-dofile'd:
1. Detects it's a reload (HookManager already exists)
2. `Reg.reload_all()`: deactivates all hooks, restores originals, sets `is_enabled = false`, clears modules + hooks, preserves `_G.Reg._ns("state")`
3. Libs are re-loaded fresh from disk
4. Action modules must be re-dofile'd separately — they start disabled with no active hooks

Manual reload of a single module: `Reg.reset_module("actions.name")`


---

# Runtime Type System

The game engine injects Python-like types into the Lua VM via C++ bindings (`asiocore`). These are **not plain Lua tables** — they have custom metatables, methods, and `type()` returns distinct strings. Mishandling them is the #1 source of runtime crashes.

## type() return values

| `type(x)` returns | What it is | Example source |
|-------------------|------------|----------------|
| `"table"` | Plain Lua table | `{}`, `{ a = 1 }` |
| `"dict"` | Engine dict (map) | `G.datam` rows, `CustomMapType` instances |
| `"list"` | Engine list (array) | `entity:get_buffs()`, `CustomListType` instances |
| `"tuple"` | Engine tuple (immutable) | Some return values from engine APIs |
| `"instance"` | Class instance | Game entities, UI widgets, most game objects |
| `"class"` | Class definition | The class itself (not an instance) |
| `"userdata"` | Raw C++ object | Cocos nodes, low-level engine handles |

**Critical:** `type(game_dict)` returns `"dict"`, NOT `"table"`. Code that checks `type(x) == "table"` will miss game containers.

## Constructing custom types

To create engine-compatible dict/list values from plain Lua tables, use `common.classutils`:

```lua
local ClassUtils = require("common.classutils")

-- Dict from plain table
local d = ClassUtils.CustomMapType({ key1 = "val1", key2 = 42 })

-- List from plain array
local lst = ClassUtils.CustomListType({ 1, 2, 3 })

-- Typed variants (auto-convert values)
local int_list = ClassUtils.CustomIntListType({ 1, 2, 3 })
local str_map  = ClassUtils.CustomStrMapType({ name = "test" })
```

### When to construct

The main reason to construct a `CustomMapType` in our code is **preparing data for game RPC calls** — the game engine expects engine-typed dicts, not plain Lua tables.

```lua
-- Pattern: wrap plain table → to_valid_dict() for RPC
local ClassUtils = require("common.classutils")
local bd = ClassUtils.CustomMapType({
    target_eid = entity.entity_id,
    way_info = ClassUtils.CustomMapType({ way_no = 1, comp_id = 2 }):to_valid_dict(),
}):to_valid_dict()
-- bd is now a plain Lua table with only non-default values, ready for RPC
```

### How entity initialization works

Game entities use `init_from_dict(bdict)` which calls `_initProperty(data)` internally. The `_initProperty` method iterates the data (using `normal_pairs()` if available, else `pairs()`) and:
- If a property default is a CustomType class → wraps the value: `self[name] = DefaultClass(value)`
- If a `VALUE_TYPE` is set → auto-converts via `int()`, `float()`, `str()`
- Otherwise → assigns directly: `self[name] = value`

You should never call `_initProperty` directly. Use `init_from_dict()` on entities, or construct via `CustomMapType(data)` for standalone dicts.

## Working with dict

Engine dicts behave like Python dicts. Source: `common.classutils.CustomMapType`.

```lua
-- Access
local val = d[key]          -- direct index
local val = d:get(key)      -- safe get (returns nil if missing)

-- Iteration
for k, v in pairs(d) do end              -- works
for _, k in ipairs(d:keys()) do end       -- explicit key list
for _, pair in ipairs(d:items()) do       -- k,v pairs
    local k, v = pair[1], pair[2]
end

-- Mutation
d[key] = value               -- direct set
d:setdefault(key, default)   -- set only if key absent, returns value
d:update(other_dict)         -- merge all keys from other into d
d:pop(key)                   -- remove key and return value

-- Query
d:keys()                     -- returns list of keys
d:values()                   -- returns list of values
d:items()                    -- returns list of {k,v} pairs
d:contains(key)              -- boolean
#d                           -- size (calls dsize())

-- Conversion to plain Lua table
d:to_valid_dict()            -- only modified values (skips defaults) — use for RPC
d:todict()                   -- all values
```

## Working with list

Engine lists behave like Python lists. Source: `common.classutils.CustomListType`.

```lua
-- Access
local val = lst[1]           -- 1-based index
#lst                         -- length

-- Iteration
for i, v in pairs(lst) do end      -- works
for i = 1, #lst do                 -- index loop works
    local v = lst[i]
end

-- Mutation
lst:append(item)             -- add one item
lst:extend(other_list)       -- add multiple items (from list or table)
lst:pop(index)               -- remove by index, returns value
lst:remove(value)            -- remove first occurrence by value
lst:clear()                  -- empty the list
lst[i] = new_value           -- direct index set

-- Query
lst:contains(item)           -- boolean
lst:index(item)              -- first index of item (or nil)

-- Conversion to plain Lua table
lst:tolist()                 -- plain array
```

## Working with instance / class

```lua
-- Type checking
isinstance(obj, SomeClass)   -- like Python isinstance()
issubclass(child, parent)    -- like Python issubclass()
hasattr(obj, "method_name")  -- safe attribute check (pcall-wrapped)
getattr(obj, "name", default) -- safe get with fallback

-- Class name
obj.__cname__                -- string class name (if available)
```

## Typed variants

`CustomMapType` and `CustomListType` have typed subclasses with `VALUE_TYPE` that auto-convert values on construction:

| List variant | Map variant | VALUE_TYPE |
|-------------|-------------|-----------|
| `CustomIntListType` | `CustomIntMapType` | `"int"` |
| `CustomFloatListType` | `CustomFloatMapType` | `"float"` |
| `CustomStrListType` | `CustomStrMapType` | `"str"` |

All are available via `require("common.classutils")`.

## What NOT to do

| Mistake | Why it fails | Do instead |
|---------|-------------|------------|
| `table.insert(lst, item)` | Not a plain table | `lst:append(item)` |
| `table.remove(lst, i)` | Not a plain table | `lst:pop(i)` |
| `type(d) == "table"` | Returns `"dict"` | Check for both or use `Serialize.normalize()` |
| `ipairs(lst)` | May not work on engine lists | `pairs(lst)` or index loop |
| `for k,v in pairs(d) do d[k2]=v2 end` | Mutation during iteration | Build second table, merge after |
| `next(d)` to check empty | Unreliable on engine types | `#d > 0` or `bool(d)` |
| Assume `pairs()` order | Engine dicts are unordered | Use `:keys()` + sort if order matters |

## Normalizing for serialization

Before writing game values to files or comparing them, always normalize:

```lua
local Serialize = _G.Reg.lib("Serialize")

-- Convert any game type → plain Lua tables recursively
local plain = Serialize.normalize(game_value)

-- Handles: dict→table, list→array, tuple→array,
-- instance→{__type, __class, ...}, userdata→string, cycle detection
```

The normalize function handles all type conversions with cycle detection and depth limiting. Prefer this over manual type-switching.

## When to probe

If you encounter a game API return value and aren't sure of its type, **write a probe test**:

```lua
local val = some_api_call()
log(string.format("type=%s", type(val)))                    -- dict? list? instance?
log(string.format("#val=%s", tostring(#val)))               -- length
log(string.format("has keys=%s", tostring(val.keys ~= nil))) -- dict method?
log(string.format("has append=%s", tostring(val.append ~= nil))) -- list method?
```

Never guess — probe it.


---

# Coding Rules

## DO — Required patterns

| Pattern | Example |
|---------|---------|
| Private helpers as module methods | `function MyModule:_helper()` |
| All data in `define_state()` | `persistent = { ... }, transient = { ... }` |
| All hooks in `define_hooks()` | Controlled via `self:hook()`/`self:unhook()` |
| Imports via `portable.safe_import()` | `pcall(portable.safe_import, "hexm.module")` |
| Logging via `self:log()` | `self:log("message")` |
| Access libs via Reg | `_G.Reg.lib("Serialize")` |
| Access modules via Reg | `_G.Reg.module("actions.combat")` |
| Inside hooks: `self_action:log()` | `self_action:log("hook fired")` |

## DON'T — Banned patterns (violations rejected)

| Banned | Use instead |
|--------|-------------|
| `local function _helper()` for module logic | `function Module:_helper()` |
| Module-level `local DATA = {...}` tables | `define_state()` transient |
| `require("hexm.module")` | `portable.safe_import()` |
| `Logger.log("[Mod] msg")` | `self:log("msg")` |
| `_G.KURO_*` (outside bootstrap.lua) | `_G.Reg` API |
| `Hooks.hook_method(...)` directly | `define_hooks()` + `self:hook()` |
| `Utils.*` (entire module is banned) | See table below |

## File Structure Order

Every action file MUST follow this order:
1. Module declaration (`ActionBase:extend`)
2. Constants (scalar only)
3. `define_state()`
4. `define_hooks()`
5. Lifecycle overrides (`on_enable`, `on_disable`, `on_reload`) — optional
6. Private methods (underscore prefix)
7. Public API methods
8. `return MyModule:new()`

Local functions OK only for: pure utility closures (max 3 lines, no state access) and scalar constants.


---

# Implementation Guidelines

## Read Before Editing

Start with:
- the target file you will edit
- matching action/controller/helper modules
- decompiled usage sites for the same API or data path

## Follow Existing Runtime Patterns

- Game data tables: `G.datam.<table>:get(key)`, `:keys()`, `:values()`, `:items()`
- Text fields: `LOC(...)`, `TextByTable(...)`, or `G.locale_manager:get_locale_text_by_tid(...)`
- Dumps/exports: reuse `Constants`, `Logger`, and existing output directories
- Custom data types: `list`, `dict`, `instance`, `class`, `tuple`, `userdata`

Do not invent access patterns when the game already has one.

## Handle Runtime Data Defensively

- **Always check `type(val)`** — game values return `"dict"`, `"list"`, `"instance"`, not `"table"` (see Runtime Type System section)
- Normalize before serializing: `_G.Reg.lib("Serialize").normalize(val)`
- Use type-appropriate methods: `:keys()/:get()` for dict, `:append()/:tolist()` for list
- Wrap risky calls in `pcall(...)`
- Do not mutate a container while iterating with `pairs(...)`

## Log Progress and Failures

Log target: `Scripts/logs/script_debug.txt`

Log: start of operation, progress for long-running loops, final success/error, output path.


---

# Common Pitfalls

| Pitfall | Prevention |
|---------|------------|
| Syntax mistakes from variable names | Re-load the file after edits. Parse errors survive until injection. |
| Runtime container assumptions | Don't assume `G.datam` rows are plain tables. Use `Serialize.normalize()`. |
| Table mutation during iteration | Build a second table, then merge. |
| Static cache vs live runtime | Static JSON for shape discovery only. Implementation must use live data. |
| Unverified success | `Server reply: OK` only means pipe accepted. **Read the log file.** |
| Stale module references after reload | Re-fetch via `_G.Reg.module("name")` after reload. |
| Hook callbacks: self vs self_action | First param in `define_hooks()` callbacks is `self_action`, not `self`. |
