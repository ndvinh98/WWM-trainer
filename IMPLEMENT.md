---
name: implement
description: Reusable workflow for implementing new features or fixing bugs in this workspace, with source-guided investigation, minimal-risk edits, and runtime verification through the existing inject/debug path.
---

# When To Use

- Add a new feature or action module
- Fix a bug
- Extend an existing script/action
- Add data export or debug tooling
- Verify behavior in the live injected runtime

Do not use for pure brainstorming, architecture discussion without code changes, or broad reverse engineering reports.


# Core Rules

- Inspect the existing codebase first. Do not design from memory.
- Reuse existing helpers, loaders, logging, and output paths before adding new ones.
- Prefer the live runtime source of truth over static guesses.
- Keep edits local and minimal.
- Verify the behavior after editing. A code change without runtime confirmation is incomplete if the task is testable.


# Source Priorities

1. Live runtime objects and existing workspace scripts
2. `Scripts/source_decompiled/`
3. `Scripts/data/DirObject/`
4. Existing local logs in `Scripts/logs/`

Use decompiled code to learn patterns before implementing.


---

# Architecture Quick Reference

## Global Registry (`_G.Reg`)

Bootstrap initializes `_G.Reg` with these accessors:

| Need | API | Example |
|------|-----|---------|
| Get a lib | `_G.Reg.lib(name)` | `_G.Reg.lib("Serialize")` |
| Get an action module | `_G.Reg.module(name)` | `_G.Reg.module("actions.combat")` |
| Get/create state table | `_G.Reg.state(name)` | Inside ActionBase: just use `self.state` |
| List loaded modules | `_G.Reg.list_modules()` | Returns sorted name list |
| Reload all modules | `_G.Reg.reload_all()` | Deactivates hooks, clears modules, preserves state |
| Raw namespace table | `_G.Reg._ns(name)` | `_G.Reg._ns("hooks")` — for core lib files only |

**Available libs:** `Constants`, `Logger`, `Serialize`, `Cocos`, `Hooks`, `HookManager`, `ActionBase`, `Utils` (legacy shim)

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

## DON'T — Violations will be rejected

| Anti-pattern | Why | Use instead |
|-------------|-----|-------------|
| `local function _helper()` for module logic | Can't access `self`, untestable | `function Module:_helper()` |
| Module-level `local DATA = {...}` tables | Don't survive reload | `define_state()` transient |
| `require("hexm.module")` | Throws on missing | `portable.safe_import()` |
| `Logger.log("[Mod] msg")` | Not prefixed, not associated | `self:log("msg")` |
| `_G.KURO_lib.Serialize` | Hardcoded prefix, breaks if changed | `_G.Reg.lib("Serialize")` |
| `_G.KURO_state["actions.x"]` | Direct namespace access | `self.state` or `_G.Reg.state()` |
| `Hooks.hook_method(...)` directly | Bypasses HookManager lifecycle | `define_hooks()` + `self:hook()` |
| `Utils.safe_import(...)` | Legacy shim, being removed | `portable.safe_import()` |
| `Utils.get_main_player()` | Legacy shim | `G.main_player` |
| `Utils.dump_value(...)` | Legacy shim | `_G.Reg.lib("Serialize").dump_value()` |

## Replacement Quick Reference

| Old | New |
|-----|-----|
| `Utils.safe_import(path)` | `portable.safe_import(path)` |
| `Utils.safe_call(label, fn, ...)` | `pcall(fn, ...)` |
| `Utils.safe_dofile(path)` | `pcall(dofile, path)` |
| `Utils.get_main_player()` | `G.main_player` |
| `Utils.dump_value(val)` | `_G.Reg.lib("Serialize").dump_value(val)` |
| `Utils.init_dict(tbl)` | `require("common.classutils").CustomMapType(tbl):to_valid_dict()` |
| `Utils.init_list(tbl)` | `require("common.classutils").CustomListType(tbl)` |
| `Utils.create_empty_proxy()` | `_G.Reg.lib("Cocos").create_empty_proxy()` |
| `Utils.delay_call(delay, fn)` | `_G.Reg.lib("Cocos").delay_call(delay, fn)` |
| `Reg.get("X")` / `Reg.set("X", v)` | `_G.Reg.lib("X")` or `_G.Reg.module("X")` |

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

## Exception: local functions

Local functions are OK only for:
- Pure utility closures (max 3 lines, no state access): `local function _apply_buff(id) ... end`
- Constants that aren't methods: `local BUFF_ID = 70063`


---

# Standard Workflow

## 1. Read Before Editing

Start with:
- the target file you will edit
- matching action/controller/helper modules
- decompiled usage sites for the same API or data path

Look for:
- existing naming/style
- output/logging conventions
- how runtime data is normally accessed

## 2. Follow Existing Runtime Patterns

Before adding logic, search for current usage of the same runtime objects.

- For game data tables: `G.datam.<table>:get(key)`, `:keys()`, `:values()`, `:items()`
- For text fields: `LOC(...)`, `TextByTable(...)`, or `G.locale_manager:get_locale_text_by_tid(...)`
- For dumps/exports: reuse `Constants`, `Logger`, and existing output directories
- Custom data types: `list`, `dict`, `instance`, `class`, `tuple`, `userdata`

Do not invent access patterns when the game already has one.

## 3. Implement Conservatively

Prefer:
- additive public functions over broad rewrites
- helper functions for normalization/serialization
- output under existing dump/data/log roots
- explicit error logging

Avoid:
- mutating unrelated code paths
- changing behavior outside the requested scope
- assuming plain Lua tables when runtime may return custom types

## 4. Handle Runtime Data Defensively

Runtime values may be: plain Lua values, `table`, `list`, `dict`, `instance`, userdata-backed objects.

- Normalize values before serializing: `_G.Reg.lib("Serialize").normalize(val)`
- Use `:todict()` / `:tolist()` when available
- Use `:keys()` + `:get()` when iteration is supported
- Wrap risky calls in `pcall(...)`
- Do not mutate a table while iterating it with `pairs(...)`

## 5. Localize Meaningful Text

- Prefer the same path the game uses
- For TID-like numeric values: `G.locale_manager:get_locale_text_by_tid(tid, tostring(tid))`
- Keep both raw field value and translated `_text` companion when useful
- Do not blindly translate every numeric field

## 6. Log Progress and Failures

Log target: `Scripts/logs/script_debug.txt`

Log: start of operation, progress for long-running loops, final success/error, output path.


---

# Testing Requirements

## Minimum 5 checks per module (R11)

```lua
-- 1. Module registered
T.assert_not_nil(Reg.module("actions.my_module"))
-- 2. Is ActionBase subclass
T.assert_not_nil(mod.state)
T.assert_not_nil(mod.is_enabled)
-- 3. State keys correct types
T.assert_type(mod.state.my_flag, "boolean")
-- 4. Hook lifecycle
mod:hook("my_hook"); T.assert_true(mod:is_hooked("my_hook"))
mod:unhook("my_hook"); T.assert_false(mod:is_hooked("my_hook"))
-- 5. Enable/disable
mod:enable(); T.assert_true(mod:is_enabled())
mod:disable(); T.assert_false(mod:is_enabled())
```

## Test file naming

- Action module: `Scripts/tests/test_<name>.lua`
- Add to `run_all.lua`: both `action_files` and `test_suites` tables

## Run full suite after every change

```powershell
& "C:\temp\Where Winds Meet\.venv\Scripts\python.exe" "C:\temp\Where Winds Meet\Scripts\inject\debug.py" "dofile('C:/temp/Where Winds Meet/Scripts/tests/run_all.lua')"
```
Check results: `Scripts/logs/test_results.txt`

## Formatting

Format Lua edits before verification:

```powershell
uv run stylua --syntax Lua54 <files...>
```

Prefer formatting only the files you changed.

## State testing caveat

Persistent state survives across runs. Test with `assert_type(mod.state.key, "type")` instead of `assert_eq(mod.state.key, default_value)` for persistent keys.


---

# Runtime Verification

## Injection path

```powershell
& "C:\temp\Where Winds Meet\.venv\Scripts\python.exe" "C:\temp\Where Winds Meet\Scripts\inject\debug.py" "dofile('C:/temp/Where Winds Meet/Scripts/tests/run_all.lua')"
```

**Critical:** Use forward slashes in Lua strings sent via pipe. Backslashes cause ERRSYNTAX in `lua_load`.

Check:
- `Scripts/logs/test_results.txt` — test results
- `Scripts/logs/script_debug.txt` — runtime logs

## Test Confirmation Checklist

Before closing the task:
- [ ] Edited Lua file loads without syntax errors
- [ ] New public entry point is callable
- [ ] Runtime logs show the code path executed
- [ ] Test suite: ALL GREEN (all suites pass, all modules load)
- [ ] No `_G.KURO_*` direct access outside bootstrap.lua
- [ ] No `Utils.*` calls in migrated code
- [ ] No bare `require()` for game modules


---

# Common Pitfalls

## Syntax mistakes from variable names
Do not trust that a quick local rename is harmless. Re-load the file after edits. A parse error can survive until runtime injection.

## Runtime container assumptions
Do not assume `G.datam` rows are plain tables. They often require normalization via `Serialize.normalize()`.

## Table mutation during iteration
Do not add keys to the same table while iterating it with `pairs(...)`. Build a second table, then merge.

## Static cache vs live runtime
Static dumped JSON is useful for shape discovery, but implementation should prefer live runtime data when the feature runs in-game.

## Unverified success
`Server reply: OK` only confirms the pipe call was accepted. It does not prove the Lua task succeeded. Always inspect the log and output artifacts.

## Hardcoded prefix
Never write `_G.KURO_*` in any file except `bootstrap.lua`. The prefix is configurable via `Constants.GLOBAL_PREFIX`. Use `_G.Reg` API instead.

## Stale module references after reload
When bootstrap is re-dofile'd, old module instances in `_G.Reg._ns("modules")` are cleared. Any code holding a stale reference to a module must re-fetch via `_G.Reg.module("name")`.

## Hook callbacks: self vs self_action
In `define_hooks()` callbacks, the first parameter is `self_action` (your module instance), NOT `self`. Use `self_action:log()`, `self_action.state`, etc.
