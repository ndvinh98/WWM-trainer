# Codebase Refactoring Audit Report

**Date:** 2026-03-17
**Scope:** All changes from the refactoring across `Scripts/actions/`, `Scripts/ui/`, `Scripts/lib/`, `Scripts/tests/`
**Audited against:** [IMPLEMENT.md](file:///c:/temp/Where%20Winds%20Meet/IMPLEMENT.md), [implementation_plan.md](file:///c:/temp/Where%20Winds%20Meet/implementation_plan.md), [design spec](file:///c:/temp/Where%20Winds%20Meet/docs/superpowers/specs/2026-03-16-codebase-refactoring-design.md)

---

## ✅ What's Correct

| Check | Status |
|-------|--------|
| All 15 action files use `ActionBase:extend()` | ✅ |
| All 15 action files have `define_state()` | ✅ |
| All 15 action files have `define_hooks()` | ✅ |
| All 15 action files end with `return X:new()` | ✅ |
| `hook_interceptor.lua` deleted (only in `backup/`) | ✅ |
| `actions/test.lua` deleted | ✅ |
| `parry_v2.lua` deleted + renamed to `parry_online.lua` | ✅ |
| 7 selector wrappers deleted from `ui/components/` | ✅ |
| `selector_factory.lua` created in `ui/lib/` | ✅ |
| No `HookInterceptor` refs in `Scripts/actions/` | ✅ |
| No `_G.KURO_*` direct access in `Scripts/actions/` | ✅ |
| No `Reg.set()` calls in `Scripts/actions/` | ✅ |
| Test suite in `run_all.lua` covers 16 suites | ✅ |
| Foundation tests exist (`test_bootstrap`, `test_hook_manager`, `test_action_base`) | ✅ |

---

## 🔴 Critical Violations

### V1: `spy.lua` — R6: Direct `Hooks.hook_method()` call

```
spy.lua:205  ok, err = Hooks.hook_method(SPY_HOOK_ID, module_path, class_name, func_name, callbacks)
```

Rule R6 says **NEVER call Hooks directly**. Should use `HookManager.register()` + `self:hook()`.

> [!CAUTION]
> `spy.lua` also fetches Hooks via legacy `Reg.get("Hooks")` at lines 158 and 226 — double violation (R6 + R7).

### V2: `spy.lua` — R4: Direct `Logger.log()` call

```
spy.lua:373  pcall(Logger.log, "[Spy:ERROR] Hook handler failed: " .. tostring(err))
```

Should use `self_action:log()` or `self:log()`.

### V3: `spy.lua` — R7: `Reg.get()` instead of `Reg.lib()`

```
spy.lua:158  local Hooks = _G.Reg.get("Hooks")
spy.lua:226  local Hooks = _G.Reg.get("Hooks")
spy.lua:242  local Logger = _G.Reg.get("Logger")
```

### V4: `dump.lua` — R3/R8: `Utils.safe_import()` and `Utils.ensure_dir()`

```
dump.lua:133   local imported, import_err = Utils.safe_import(module_path)
dump.lua:526   local ok, err = Utils.ensure_dir(dir_path)
dump.lua:1243  if Utils and Utils.safe_import then
dump.lua:1244  _buff_passive_consts = Utils.safe_import("hexm.common.consts.buff_passive_consts")
dump.lua:1949  local rapidjson = Utils.safe_import("rapidjson")
dump.lua:1950  local dirObj = Utils.safe_import("hexm.common.data.dir_object")
dump.lua:2086  local rapidjson = Utils.safe_import("rapidjson")
dump.lua:2087  local dirObj = Utils.safe_import("hexm.common.data.dir_object")
dump.lua:2189  local rapidjson = Utils.safe_import("rapidjson")
dump.lua:2190  local dirObj = Utils.safe_import("hexm.common.data.dir_object")
dump.lua:2284  local rapidjson = Utils.safe_import("rapidjson")
```

> [!WARNING]
> `dump.lua` was listed as **"A-grade reference pattern"** in the implementation plan header, but it still has **11 `Utils.*` calls**. This contradicts the plan's own checklist which says "Replace `Utils.safe_import` → `portable.safe_import`".

### V5: `dump.lua` and `trace.lua` — R7: `Reg.get()` instead of `Reg.lib()`

```
dump.lua:34    local Constants = _G.Reg and _G.Reg.get("Constants")
dump.lua:64    local Constants = _G.Reg and _G.Reg.get("Constants")
trace.lua:32   local Constants = _G.Reg and _G.Reg.get("Constants")
trace.lua:109  local Constants = _G.Reg and _G.Reg.get("Constants")
```

### V6: `parry_online.lua` — R7: `Reg.get()` fallback pattern

```
parry_online.lua:253  local Constants = _G.Reg.lib("Constants") or _G.Reg.get("Constants")
parry_online.lua:383  local Constants = _G.Reg.lib("Constants") or _G.Reg.get("Constants")
```

The `or _G.Reg.get()` fallback is redundant — `Reg.lib()` is the canonical API. If it returns nil, `Reg.get()` won't help.

### V7: `parry_online.lua` and `gm_panel.lua` and `autoloot.lua` — R3: bare `require()` for game modules

```
parry_online.lua:145  self.state.DateTimeManager = require("hexm.common.datetime_manager").DateTimeManager
parry_online.lua:353  local cjson = require("cjson")
parry_online.lua:390  local cjson = require("cjson")
gm_panel.lua:160      local GmShortcutWindow = require(MODULE_GM_SHORTCUT).GmShortcutWindow
autoloot.lua:417      local InteractDataManager = require("hexm.common.base...").InteractDataManager
autoloot.lua:664      local interact_misc = require("hexm.common.misc.interact_misc")
dump.lua:1250         return require("hexm.common.consts.buff_passive_consts")
```

Rule R3: **ALL imports use `portable.safe_import()`** — never bare `require()`.

> [!NOTE]
> `require("common.classutils")` in `autoloot.lua` (lines 83, 413, 502) is borderline — the implementation plan's own replacement table uses `require("common.classutils")` for `Utils.init_dict`/`Utils.init_list`. This appears intentional.

---

## 🟡 Moderate Violations

### V8: R1 — `local function _*()` in migrated action files

Rule R1 says private helpers **MUST be module methods**, with exception only for "pure utility closures (max 3 lines, no state access)".

**Files with many `local function _*()` definitions:**

| File | Count | Severity |
|------|-------|----------|
| [dump.lua](file:///c:/temp/Where%20Winds%20Meet/Scripts/actions/dump.lua) | **~25+** | High — many exceed 3 lines |
| [parry_online.lua](file:///c:/temp/Where%20Winds%20Meet/Scripts/actions/parry_online.lua) | **14** | High — `_npc_learned_for_json`, `_encode_npc_learned_json` etc. are complex |
| [xinfa_buffs.lua](file:///c:/temp/Where%20Winds%20Meet/Scripts/actions/xinfa_buffs.lua) | **5** | Medium — `_build_rank_progression`, `_collect_all_rank_buffs` are multi-line |
| [suit_skins.lua](file:///c:/temp/Where%20Winds%20Meet/Scripts/actions/suit_skins.lua) | **3** | Low — `_name_from_icon`, `_translate`, `_datam_dict_to_list` |
| [world.lua](file:///c:/temp/Where%20Winds%20Meet/Scripts/actions/world.lua) | **1** | Medium — `_get_combat_action` accesses game state |
| [spy.lua](file:///c:/temp/Where%20Winds%20Meet/Scripts/actions/spy.lua) | **3** | Low — `_class_of_self`, `_path_to_module`, `_parse_source` |

> [!IMPORTANT]
> `dump.lua` has **25+ local functions** despite being called an "A-grade reference". Many are multi-line data transformers that access module state indirectly. These should be `Dump:_method()` module methods per R1.

### V9: `utils.lua` still exists in `Scripts/lib/`

The design spec (Section 2) says:
> `lib/utils.lua` → deleted, use runtime functions directly

But `Scripts/lib/utils.lua` still exists. Since `dump.lua` still calls `Utils.safe_import()` and `Utils.ensure_dir()`, it can't be deleted yet — but this means **the migration is incomplete**.

### V10: `menu_controller.lua` — `Reg.get()` fallback pattern

```
menu_controller.lua:10   local Constants = Reg.lib("Constants") or Reg.get("Constants")
menu_controller.lua:11   local Logger = Reg.lib("Logger") or Reg.get("Logger")
menu_controller.lua:490  local MenuConfig = Reg.get("MenuConfig")
menu_controller.lua:511  local MenuConfig = Reg.get("MenuConfig")
menu_controller.lua:522  local MenuConfig = Reg.get("MenuConfig")
menu_controller.lua:538  local MenuConfig = Reg.get("MenuConfig")
```

---

## 🟠 Missing Items (per design spec)

### M1: Missing test files for 5 action modules

Test files exist for 10/15 action modules. **Missing tests:**

| Module | Expected Test File | Status |
|--------|--------------------|--------|
| `suit_skins.lua` | `test_suit_skins.lua` | ❌ Missing |
| `weapon_skins.lua` | `test_weapon_skins.lua` | ❌ Missing |
| `xinfa_buffs.lua` | `test_xinfa_buffs.lua` | ❌ Missing |
| `spy.lua` | `test_spy.lua` | ❌ Missing |
| `dump.lua` | `test_dump.lua` | ❌ Missing |
| `trace.lua` | `test_trace.lua` | ❌ Missing |

Per R11: "Tests must cover 5 checks minimum" and per R12: "Every migrated module must have self-tests".

> [!NOTE]
> `trace.lua` and `dump.lua` were listed as "A-grade reference" in the implementation plan, implying they were already done before the migration waves. But they still lack dedicated test files and have rule violations.

### M2: `run_all.lua` doesn't include the missing tests

Even if the test files existed, they're not listed in `run_all.lua`'s `test_suites` table.

### M3: UI files not migrated from `Reg.get()` to `Reg.lib()`

The design spec Section 2 lists UI files as either "Unchanged" or "Simplified". However, **48+ calls to `Reg.get()` remain** across:
- `menu.lua` (5 calls)
- `menu_config.lua` (2 calls)
- `menu_controller.lua` (6 calls)
- `item_selector.lua` (9 calls)
- `dual_selector.lua` (10 calls)
- `dialog.lua` (4 calls)
- `button.lua` (2 calls)
- `input.lua` (4 calls)
- `ui_utils.lua` (1 call)
- `log_config.lua` (1 call)

The design spec says `Reg.get/set` are "Legacy (kept during migration, removed later)" — so this may be intentional deferral. But the implementation plan's replacement table says `Reg.get("X")` / `Reg.set("X", v)` → `_G.Reg.lib("X")` or `_G.Reg.module("X")`.

### M4: Implementation plan Wave 4 (F1) not executed

The implementation plan lists Wave 4 task F1:
> 1. Update `docs/superpowers/plans/2026-03-16-codebase-refactoring.md` — mark all tasks complete
> 2. Run full test suite
> 3. Git commit

This task has no "DONE" marker.

---

## 🔵 Redundancies

### R-1: `utils.lua` is redundant but can't be deleted

`Scripts/lib/utils.lua` still exists because `dump.lua` depends on it. Once `dump.lua` is migrated, this file should be deleted.

### R-2: `Reg.get()` fallback pattern is redundant

The `Reg.lib("X") or Reg.get("X")` pattern in `parry_online.lua` and `menu_controller.lua` is defensive but pointless — both resolve to the same `_G.KURO_lib` table.

### R-3: `dump.lua` and `trace.lua` labeled "A-grade reference" despite violations

The implementation plan header says:
> **Reference pattern (A-grade):** dump.lua, trace.lua

But both files have `Reg.get()` calls and `dump.lua` has extensive `Utils.*` usage. Either the label should be removed or the files need further cleanup.

---

## Summary Matrix

| Rule | Description | Violations Found |
|------|-------------|-----------------|
| **R1** | Private helpers as module methods | `dump.lua` (25+), `parry_online.lua` (14), `xinfa_buffs.lua` (5), `suit_skins.lua` (3), `spy.lua` (3), `world.lua` (1) |
| **R2** | All data in `define_state()` | ✅ No violations found |
| **R3** | `portable.safe_import()` only | `dump.lua` (11×), `parry_online.lua` (3×), `gm_panel.lua` (1×), `autoloot.lua` (2×) |
| **R4** | Logging via `self:log()` | `spy.lua` (1×) |
| **R5** | No duplicate definitions | ✅ No violations found |
| **R6** | Hooks via `define_hooks()` only | `spy.lua` (1× direct `Hooks.hook_method`) |
| **R7** | Access via `Reg.lib/module` | `spy.lua` (3×), `dump.lua` (2×), `trace.lua` (2×), `parry_online.lua` (2×) |
| **R8** | Reuse existing utilities | `dump.lua` (`Utils.ensure_dir`, `Utils.safe_import`) |
| **R9** | File structure order | ✅ All files follow correct order |
| **R10** | No yapping | Not audited (subjective) |
| **R11** | 5 minimum test checks | 6 modules lack test files entirely |
| **R12** | Tests run after each refactoring | Waves 1-3 confirmed ✅; Wave 4 not executed |

### Bottom Line

**Structural migration is complete** — all 15 action files follow the ActionBase pattern. **However, 4 files (`dump.lua`, `spy.lua`, `parry_online.lua`, `trace.lua`) have significant rule violations that were not caught.** The most concerning is `dump.lua` being labeled "A-grade reference" while containing 25+ `local function` violations and 11 `Utils.*` calls. Six modules lack test files entirely, violating R11/R12.
