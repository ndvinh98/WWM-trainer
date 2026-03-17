# Codebase Refactoring — Remaining Waves Implementation Plan

> **Reference pattern (A-grade):** [dump.lua](file:///c:/temp/Where%20Winds%20Meet/Scripts/actions/dump.lua), [trace.lua](file:///c:/temp/Where%20Winds%20Meet/Scripts/actions/trace.lua)
>
> **Pattern checklist (every migration):**
> - `local ActionBase = _G.Reg.lib("ActionBase")`
> - `local X = ActionBase:extend("actions.<name>")`
> - `define_state()` → `{ persistent = {...}, transient = {} }`
> - `define_hooks()` → named hooks with `spec`, `override_orig_function`, `post_exec`
> - Replace `Utils.safe_import` → `portable.safe_import`
> - Replace `Utils.safe_call` → `pcall`
> - Replace `Utils.safe_dofile` → `pcall(dofile, ...)`
> - Replace `Utils.get_main_player()` → `G.main_player`
> - Replace `Utils.dump_value` → `Serialize.dump_value` (via `_G.Reg.lib("Serialize")`)
> - Replace `Utils.init_dict(tbl)` → `require("common.classutils").CustomMapType(tbl):to_valid_dict()` (converts Lua table → engine dict for RPC)
> - Replace `Utils.init_list(tbl)` → `require("common.classutils").CustomListType(tbl)` (converts Lua table → engine list)
> - Replace `Reg.get/set` state → `self.state`
> - Replace `HookInterceptor` → `define_hooks()` with named entries
> - Replace `_log()` → `self:log()`
> - End with `return X:new()`

---

## STRICT CODING RULES (MANDATORY — violations will be rejected)

### R1: Private helpers MUST be module methods, not local functions

```lua
-- WRONG: local function
local function _get_combat_action()
    return portable.safe_import("hexm.client.debug.gm.gm_commands.gm_combat")
end

-- RIGHT: module method with underscore prefix
function MyModule:_get_combat_action()
    return portable.safe_import("hexm.client.debug.gm.gm_commands.gm_combat")
end
```

**Exception:** Pure utility closures inside a hook callback (max 3 lines, no state access).

**Rationale:** Local functions can't access `self` or `self.state`. Module methods keep everything testable and overridable on reload.

### R2: ALL data belongs in `define_state()` — no module-level `local` data tables

```lua
-- WRONG: module-level data
local PRESETS = { combat = { 70001, 70002 }, gathering = { 80001 } }
local SPEED_PRESETS = { 1, 2, 5, 10, 50 }
local SUBTYPE_TO_WEAPON = { [1] = "sword", [2] = "spear" }

-- RIGHT: in define_state (transient for generated/cached data, persistent for user selection)
function MyModule:define_state()
    return {
        persistent = { active_preset = nil },
        transient = {
            presets = { combat = { 70001, 70002 }, gathering = { 80001 } },
            speed_presets = { 1, 2, 5, 10, 50 },
            weapon_type_map = { [1] = "sword", [2] = "spear" },
        },
    }
end
```

**Exception:** True scalar constants (IDs, magic numbers, string keys) as `local CONST = value`:
```lua
-- OK: these are constants, not data
local BUFF_GOD_MODE = 70063
local NPC_BLIND_REASON = "combat_mod_npc_blind"
local MODULE_PATH = "hexm.client.ui.base.text"
```

**Rationale:** Module-level tables don't survive reload. State in `define_state()` does (persistent) or resets cleanly (transient).

### R3: ALL imports use `portable.safe_import()` — never bare `require()`

```lua
-- WRONG
local GmWindow = require("hexm.client.ui.windows.gm.gm_shortcut_window").GmShortcutWindow

-- RIGHT
local ok, mod = pcall(portable.safe_import, "hexm.client.ui.windows.gm.gm_shortcut_window")
local GmWindow = ok and mod and mod.GmShortcutWindow
```

**Rationale:** `require()` throws on missing modules. `portable.safe_import` is the game's own safe loader.

### R4: ALL logging via `self:log()` — never `Logger.log()` or free `_log()`

```lua
-- WRONG
local function _log(msg) Logger.log("[MyModule] " .. msg) end
_log("something")
Logger.log("[MyModule] error: " .. err)

-- RIGHT
self:log("something")
self:log("error: " .. err)
```

Inside hook callbacks where `self` is captured as a closure param:
```lua
post_exec = function(self_action, original, ...)
    self_action:log("hook fired")  -- use the captured self
end
```

### R5: No duplicate definitions — one function, one place

```lua
-- WRONG: local + module method with same logic
local function _translate(s) return DICT[s] or s end
function Module:_translate(s) return DICT[s] or s end  -- duplicate!

-- RIGHT: just the module method
function Module:_translate(s) return self.state.translations[s] or s end
```

### R6: ALL hooks go through `define_hooks()` + `self:hook()`/`self:unhook()` — NEVER call Hooks directly

```lua
-- WRONG: calling old Hooks API directly
local Hooks = _G.Reg.get("Hooks")
Hooks.hook_method("my_hook_id", "hexm.module", "Class", "method", { ... })
Hooks.is_hooked("my_hook_id")
Hooks.unhook("my_hook_id")

-- ALSO WRONG: using ActionBase:extend but still calling Hooks directly
local Effects = ActionBase:extend("actions.effects")
-- ...later in a method:
Hooks.hook_method(HOOK_ID, MODULE_PATH, "Class", "method", { override_exec = ... })

-- RIGHT: declare in define_hooks(), control via self:hook()/self:unhook()
function MyModule:define_hooks()
    return {
        my_hook = {
            spec = "hexm.module:Class:method",
            override_orig_function = true,
            post_exec = function(self_action, original, self_target, ...)
                -- self_action = your module instance (use for state/logging)
                -- original = the original function to call
                -- self_target = the hooked class instance
                return original(self_target, ...)
            end,
        },
    }
end

-- In public methods:
function MyModule:enable_feature()
    self:hook("my_hook")        -- activates via HookManager
    self.state.feature_on = true
end

function MyModule:disable_feature()
    self:unhook("my_hook")      -- deactivates via HookManager
    self.state.feature_on = false
end

-- Query:
self:is_hooked("my_hook")       -- true/false
```

**Hook callback signatures:**
- **Override mode** (`override_orig_function = true`): `function(self_action, original, self_target, ...)` — you control whether/how to call `original`
- **Observe mode** (no override flag): `function(self_action, args, results, traceback)` — original runs first, you observe

**Dynamic hooks** (e.g. spy — target chosen at runtime): Use `HookManager.register()` at runtime, then `self:hook()` / `self:unhook()`:
```lua
function Spy:start_wrapper(spec_string)
    local HookManager = _G.Reg.lib("HookManager")
    HookManager.register(self.name, "spy_target", {
        spec = spec_string,
        override_orig_function = true,
        post_exec = function(self_action, original, ...)
            self_action:_on_call(original, ...)
        end,
    })
    self:hook("spy_target")
end
```

**Rationale:** `define_hooks()` is the single source of truth for static hooks. HookManager.register() handles dynamic hooks. Both go through the same lifecycle. Calling `Hooks.hook_method()` directly bypasses all of this.

### R7: Access everything through `Reg` — NEVER touch `_G.KURO_*` directly

```lua
-- WRONG: reaching into internals
local Serialize = _G.KURO_lib.Serialize
local my_state = _G.KURO_state["actions.my_module"]
local hooks = _G.KURO_hooks["actions.my_module.my_hook"]

-- RIGHT: use Reg API
local Serialize = _G.Reg.lib("Serialize")
local my_state = _G.Reg.state("actions.my_module")  -- only if outside the module itself
-- Inside ActionBase subclass: just use self.state
```

| Need | Use | Don't |
|------|-----|-------|
| Get a lib module | `_G.Reg.lib("Serialize")` | `_G.KURO_lib.Serialize` |
| Get an action module | `_G.Reg.module("actions.combat")` | `_G.KURO_modules["actions.combat"]` |
| Get/create state | `self.state` (inside ActionBase) | `_G.KURO_state[...]` |
| Check hook status | `self:is_hooked("name")` | `_G.KURO_hooks[...]` |

**Only `Scripts/lib/bootstrap.lua`, `hook_manager.lua`, `action_base.lua` may touch `_G.KURO_*` directly** — they own these namespaces.

### R8: Reuse existing utility functions — don't reinvent

| Need | Use | Don't |
|------|-----|-------|
| Serialize/dump a value | `_G.Reg.lib("Serialize").dump_value(val)` | Write your own serializer |
| Normalize engine types → Lua | `Serialize.normalize(val)` | Manual type checking |
| Lua table → engine dict | `require("common.classutils").CustomMapType(tbl):to_valid_dict()` | Manual dict construction |
| Lua table → engine list | `require("common.classutils").CustomListType(tbl)` | Manual list wrapping |
| Delay/timer | `_G.Reg.lib("Cocos").delay_call(node, delay, fn)` | Raw scheduler access |
| Empty proxy node | `Cocos.create_empty_proxy()` | Manual node creation |
| Get running scene | `Cocos.get_running_scene()` | `cc.Director:getInstance()` chain |
| Get main player | `G.main_player` | `Utils.get_main_player()` |
| Safe game import | `portable.safe_import(module_path)` | `require()` or `Utils.safe_import()` |

### R9: File structure order

Every action file MUST follow this order:
```lua
-- 1. Module declaration
local ActionBase = _G.Reg.lib("ActionBase")
local MyModule = ActionBase:extend("actions.my_module")

-- 2. Constants (scalar only)
local SOME_ID = 12345
local MODULE_PATH = "hexm.some.module"

-- 3. define_state() — ALL data here
function MyModule:define_state() ... end

-- 4. define_hooks() — ALL hooks here
function MyModule:define_hooks() ... end

-- 5. Lifecycle overrides (optional)
function MyModule:on_enable() ... end
function MyModule:on_disable() ... end
function MyModule:on_reload() ... end

-- 6. Private methods (underscore prefix)
function MyModule:_helper() ... end

-- 7. Public API methods
function MyModule:do_something() ... end

-- 8. Return instance
return MyModule:new()
```

### R10: No yapping — concise code, no comments explaining obvious things

```lua
-- WRONG: comment explains what the code already says
-- Check if the player exists before proceeding
local mp = G.main_player
if not mp then
    self:log("Player not found, aborting operation")
    return false, "No main player available"
end

-- RIGHT: let the code speak
local mp = G.main_player
if not mp then return false end
```

Only add comments for: non-obvious game engine behavior, hook spec explanations, workarounds for known bugs.

### R11: Tests must cover these 5 checks minimum

```lua
T.run("module registered", function()
    T.assert_not_nil(mod)
end)
T.run("is ActionBase subclass", function()
    T.assert_not_nil(mod.state, "has state")
    T.assert_not_nil(mod.is_enabled, "has is_enabled")
end)
T.run("state keys correct types", function()
    -- check each persistent/transient key
end)
T.run("hook lifecycle", function()
    -- hook → is_hooked true → unhook → is_hooked false
end)
T.run("enable/disable", function()
    mod:enable(); T.assert_true(mod:is_enabled())
    mod:disable(); T.assert_false(mod:is_enabled())
end)
```

### R12: Test verification MUST run after each refactoring

Every migrated module must have:
1. **Self-tests** (`Scripts/tests/test_<name>.lua`) covering R11 checks at minimum
2. **UI integration tests** (`Scripts/tests/test_menu_config.lua`, `Scripts/tests/test_ui_components.lua`) if the module is referenced from `Scripts/ui/` files
3. **Run the full suite** after each migration and confirm ALL GREEN before marking done:
```
dofile('C:/temp/Where Winds Meet/Scripts/tests/run_all.lua')
```
4. **New modules/tests must be added** to `run_all.lua` `action_files` and `test_suites` tables

---

## Wave 1 — Parallel (8 tasks, no interdependencies)

### ~~A1: REDO effects.lua~~ DONE

Verified: Already correctly migrated to ActionBase pattern with `define_hooks()`, `self:hook()`/`self:unhook()`, `self:log()`. 13/13 assertions pass in `test_effects.lua`.

---

### ~~A2: Migrate gm_panel.lua~~ DONE

Verified: 7 modules load, 9/9 assertions pass. Clean ActionBase pattern, proper state split, error-safe hook callback.

---

### ~~A3: Migrate autoloot.lua~~ DONE

Verified: Already correctly migrated to ActionBase pattern. Fixed `Cocos.delay_call` signature bug in reload guard (`nil, 0.5, func` → `0.5, func`). Removed unused `calc_distance` local function. 7/7 assertions pass in `test_autoloot.lua`.

---

### ~~A4: Migrate parry.lua~~ DONE

Full rewrite to ActionBase. HookInterceptor → `define_hooks()` with 1 hook (`listenable`). Local functions → module methods. `Utils.dump_value` → `Serialize.dump_value`. 8/8 assertions pass in `test_parry.lua`.

---

### ~~A6: Migrate sync_observer.lua~~ DONE

Full rewrite to ActionBase. 3 HookInterceptor specs → `define_hooks()` with `entity_method`, `do_sync`, `listenable`. All state in `define_state()`. `Utils.*` → `Serialize.dump_value`/`portable.safe_import`. 9/9 assertions pass in `test_sync_observer.lua`.

---

### ~~A7: Delete actions/test.lua~~ DONE

File deleted. Was superseded by combat.lua.

---

### ~~U1: Update menu_config.lua~~ DONE

Removed `Reg.get("Utils")`, replaced `Utils.safe_dofile(...)` → `pcall(dofile, ...)` with error handling. 6/6 assertions pass in `test_menu_config.lua`.

---

### ~~U3: Clean UI component Utils refs~~ DONE

Removed unused `Constants` import from `button.lua`. `dialog.lua` and `input.lua` had no Utils refs (already clean). 11/11 assertions pass in `test_ui_components.lua`.

---

## Wave 2 — After A4

### ~~A5: Migrate parry_v2.lua → parry_online.lua~~ DONE

Full rewrite (1393→540 lines). 6 HookInterceptor specs → `define_hooks()` (`listenable`, `set_ex_data`, `on_bone_hit`, `on_bone_hit_batch`, `set_enable_collider_query`, `do_attack`). NPC prediction/learning + JSON persistence preserved. `Utils.*` → `Serialize`/`portable`/`Cocos.delay_call`. `parry_v2.lua` deleted. 9/9 assertions pass in `test_parry_online.lua`.

### Wave 2 Results ✅
```
FINAL: 14 suites passed, 0 suites failed
       12 modules loaded, 0 modules failed
ALL GREEN — 149 assertions, 0 failures
```

---

## Wave 3 — After Waves 1+2

### ~~U2: Delete 7 selector wrappers~~ DONE

Deleted all 7 selector wrappers from `Scripts/ui/components/`: `suit_selector`, `weapon_selector`, `bow_selector`, `effect_selector`, `dual_effect_selector`, `dual_weapon_selector`, `xinfa_selector`. Base components (`item_selector.lua`, `dual_selector.lua`) kept.

### ~~D1: Delete legacy lib files~~ DONE

Deleted `hook_interceptor.lua`. Fixed `spy.lua` — replaced all `Utils.dump_value` → `Serialize.dump_value`. `dump.lua` confirmed already clean.

### Wave 3 Results ✅
```
FINAL: 14 suites passed, 0 suites failed
       12 modules loaded, 0 modules failed
ALL GREEN
```

---

## Wave 4 — Last

### F1: Update IMPLEMENT.md + Final Verification + Git Commit (LOW)

1. Update `docs/superpowers/plans/2026-03-16-codebase-refactoring.md` — mark all tasks complete
2. Run full test suite: `dofile('C:/temp/Where Winds Meet/Scripts/tests/run_safe.lua')`
3. Verify all assertions pass, all modules load
4. Git commit with descriptive message

---

## Verification Plan

### Automated Tests (per R12)
After each migration, run the full suite and confirm ALL GREEN:
```powershell
& "C:\temp\Where Winds Meet\.venv\Scripts\python.exe" "C:\temp\Where Winds Meet\Scripts\inject\debug.py" "dofile('C:/temp/Where Winds Meet/Scripts/tests/run_all.lua')"
```
Check results: `Scripts/logs/test_results.txt`

Each migration must include:
1. **Self-tests** (`test_<name>.lua`) covering R11's 5 minimum checks
2. **UI integration tests** if module is referenced from `Scripts/ui/` (e.g. `test_menu_config.lua`, `test_ui_components.lua`)
3. **Updated `run_all.lua`** — add module to `action_files` and test to `test_suites`

### Per-Task Verification
Each migration task should verify:
1. `_G.Reg.module("actions.<name>")` is not nil
2. `state` has expected keys with correct types
3. `hook`/`unhook` lifecycle works (hook activates, unhook deactivates)
4. `disable()` cleans up all hooks
5. No `Reg.get("Utils")` calls remain in the migrated file

### Wave 1 Results ✅
```
FINAL: 13 suites passed, 0 suites failed
       11 modules loaded, 0 modules failed
ALL GREEN — 140 assertions, 0 failures
```

### Final Verification (Wave 4)
```bash
# Verify no legacy patterns remain
grep -rn "Reg.get(\"Utils\")" Scripts/actions/ Scripts/ui/ --include="*.lua" | grep -v backup
grep -rn "HookInterceptor" Scripts/actions/ --include="*.lua" | grep -v backup
grep -rn "Utils\." Scripts/actions/ --include="*.lua" | grep -v backup | grep -v "-- "
```
Expected: Zero matches.

### Runtime Verification
Injection via pipe:
```powershell
& "C:\temp\Where Winds Meet\.venv\Scripts\python.exe" "C:\temp\Where Winds Meet\Scripts\inject\debug.py" "dofile('C:/temp/Where Winds Meet/Scripts/tests/run_all.lua')"
```
Check `Scripts/logs/test_results.txt` for results.
