# Auto-Minigame Region Solver — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create an action module that auto-completes region minigames the player has already entered, using direct RPC for simple games and delegating entity interaction to autoloot.

**Architecture:** New `ActionBase` module following the same pattern as `autoloot.lua`. Scans `G.main_player._curr_region_game` on a timer, routes each game to either direct `send_success_region_game_id` or autoloot's `try_interact_entity`. No hooks needed.

**Tech Stack:** Lua 5.x, ActionBase framework, Cocos2d-x timers, game RPC layer

**Spec:** `docs/superpowers/specs/2026-03-18-auto-minigame-design.md`

**IMPLEMENT.md rules apply.** Key constraints:
- All data in `define_state()`, all hooks in `define_hooks()`
- Private helpers as `function Module:_name()`, not `local function`
- `portable.safe_import()` instead of bare `require()` for game modules
- `self:log()` for logging
- `_G.Reg.lib()` / `_G.Reg.module()` for dependencies
- File structure order: extend → constants → define_state → define_hooks → lifecycle → private → public → return :new()

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `Scripts/actions/autominigame.lua` | **Create** | Main module: scan, route, solve |
| `Scripts/tests/test_autominigame.lua` | **Create** | 7+ test cases per R11 |
| `Scripts/tests/run_all.lua` | **Modify** | Register module + test suite |

---

## Task 1: Register module in test harness

**Files:**
- Modify: `Scripts/tests/run_all.lua:55-72` (action_files table)
- Modify: `Scripts/tests/run_all.lua:98-122` (test_suites table)

- [ ] **Step 1: Add "autominigame" to action_files**

In `Scripts/tests/run_all.lua`, add `"autominigame"` to the `action_files` table after `"dump_static_data"`:

```lua
local action_files = {
	"buffs",
	"world",
	"combat",
	"xinfa_buffs",
	"weapon_skins",
	"suit_skins",
	"spy",
	"gm_panel",
	"effects",
	"autoloot",
	"parry",
	"sync_observer",
	"parry_online",
	"trace",
	"dump_bytecode",
	"dump_static_data",
	"autominigame",
}
```

- [ ] **Step 2: Add "test_autominigame" to test_suites**

In the same file, add `"test_autominigame"` to the `test_suites` table after `"test_trace"`:

```lua
	"test_trace",
	"test_autominigame",
}
```

- [ ] **Step 3: Commit**

```bash
git add Scripts/tests/run_all.lua
git commit -m "test: register autominigame module and test suite in run_all"
```

---

## Task 2: Create the module skeleton with state and hooks

**Files:**
- Create: `Scripts/actions/autominigame.lua`

- [ ] **Step 1: Write the module skeleton**

```lua
-- Scripts/actions/autominigame.lua
-- Auto-solve region minigames the player has entered.
-- Direct RPC for simple games, autoloot delegation for entity-based games.

local ActionBase = _G.Reg.lib("ActionBase")
local AutoMinigame = ActionBase:extend("actions.autominigame")

-- ── Constants ──
local SCAN_INTERVAL = 2.0

-- ── State ──

function AutoMinigame:define_state()
	return {
		persistent = {
			enabled = false,
			enable_logging = true,
		},
		transient = {
			done = {},
			timer_action = nil,
			scan_interval = SCAN_INTERVAL,
			log_cache = {},
		},
	}
end

-- ── Hooks ──

function AutoMinigame:define_hooks()
	return {}
end

-- ── Private methods ──

function AutoMinigame:_log(msg)
	if self.state.log_cache[msg] then
		return
	end
	self.state.log_cache[msg] = true
	self:log(msg)
end

function AutoMinigame:_debug(msg)
	if not self.state.enable_logging then
		return
	end
	if self.state.log_cache[msg] then
		return
	end
	self.state.log_cache[msg] = true
	self:log("[DBG] " .. msg)
end

-- ── Public API (stubs — filled in Task 4-5) ──

function AutoMinigame:is_enabled()
	return self.state.enabled
end

function AutoMinigame:reset()
	self.state.done = {}
	self.state.log_cache = {}
	self:_log("State reset — done cache cleared")
end

return AutoMinigame:new()
```

- [ ] **Step 2: Commit**

```bash
git add Scripts/actions/autominigame.lua
git commit -m "feat: add autominigame module skeleton with state and hooks"
```

---

## Task 3: Write failing tests

**Files:**
- Create: `Scripts/tests/test_autominigame.lua`

- [ ] **Step 1: Write the test file**

```lua
-- Scripts/tests/test_autominigame.lua
local T = dofile("C:\\temp\\Where Winds Meet\\Scripts\\tests\\run_test.lua")
T.reset()

local Reg = _G.Reg
local mod = Reg.module("actions.autominigame")

T.run("module registered", function()
	T.assert_not_nil(mod)
end)

T.run("is ActionBase subclass", function()
	T.assert_not_nil(mod.state, "has state")
	T.assert_not_nil(mod.enable, "has enable")
	T.assert_not_nil(mod.disable, "has disable")
end)

T.run("state keys have correct types", function()
	T.assert_eq(type(mod.state.enabled), "boolean", "enabled is boolean")
	T.assert_eq(type(mod.state.enable_logging), "boolean", "enable_logging is boolean")
	T.assert_eq(type(mod.state.done), "table", "done is table")
	T.assert_eq(type(mod.state.scan_interval), "number", "scan_interval is number")
end)

T.run("has solve method", function()
	T.assert_not_nil(mod.solve, "has solve()")
end)

T.run("has reset method", function()
	T.assert_not_nil(mod.reset, "has reset()")
end)

T.run("enable/disable lifecycle", function()
	mod:disable()
	T.assert_false(mod.state.enabled)

	mod:enable()
	T.assert_true(mod.state.enabled)
	T.assert_not_nil(mod.state.timer_action, "timer started")

	mod:disable()
	T.assert_false(mod.state.enabled)
	T.assert_nil(mod.state.timer_action, "timer stopped")
end)

T.run("is_enabled returns state", function()
	mod:enable()
	T.assert_true(mod:is_enabled())
	mod:disable()
	T.assert_false(mod:is_enabled())
end)

T.run("reset clears done cache", function()
	mod.state.done["test_game"] = true
	mod:reset()
	T.assert_nil(mod.state.done["test_game"])
	T.assert_eq(next(mod.state.done), nil, "done is empty")
end)

T.summary()
```

- [ ] **Step 2: Run tests to verify enable/disable/solve tests fail**

Run:
```powershell
& "C:\temp\Where Winds Meet\.venv\Scripts\python.exe" "C:\temp\Where Winds Meet\Scripts\inject\debug.py" "dofile('C:/temp/Where Winds Meet/Scripts/tests/run_all.lua')"
```

Check: `Scripts/logs/test_results.txt`
Expected: `test_autominigame` suite loaded, "has solve()" test FAILS (not yet implemented), enable/disable tests FAIL (not yet implemented).

- [ ] **Step 3: Commit**

```bash
git add Scripts/tests/test_autominigame.lua
git commit -m "test: add failing tests for autominigame module"
```

---

## Task 4: Implement timer, enable, disable, solve

**Files:**
- Modify: `Scripts/actions/autominigame.lua`

- [ ] **Step 1: Add timer management (private methods)**

Add after the `_debug` method:

```lua
-- ── Timer ──

function AutoMinigame:_stop_timer()
	if self.state.timer_action then
		pcall(function()
			local scene = _G.Reg.lib("Cocos").get_running_scene()
			if scene then
				scene:stopAction(self.state.timer_action)
			end
		end)
		self.state.timer_action = nil
	end
end

function AutoMinigame:_start_timer()
	self:_stop_timer()
	local scene = nil
	pcall(function()
		scene = _G.Reg.lib("Cocos").get_running_scene()
	end)
	if scene then
		self.state.timer_action = cc.RepeatForever:create(cc.Sequence:create({
			cc.DelayTime:create(self.state.scan_interval),
			cc.CallFunc:create(function()
				if self.state.enabled then
					self:_do_scan()
				end
			end),
		}))
		scene:runAction(self.state.timer_action)
	else
		self:_log("WARN: No scene found for timer")
	end
end
```

- [ ] **Step 2: Add scan stub and public API**

Replace the existing public API stubs with:

```lua
-- ── Core scan (stub — replaced in Task 5 with full routing) ──

function AutoMinigame:_do_scan()
	local mp = G.main_player
	if not mp then
		return false
	end
	if not mp._curr_region_game then
		return false
	end
	-- Stub: iterate games but no solve logic yet (added in Task 5)
	for game_id, _ in pairs(mp._curr_region_game) do
		self:_debug("scan: found active game " .. tostring(game_id))
	end
	return true
end

-- ── Public API ──

function AutoMinigame:enable()
	if self.state.enabled then
		self:_log("Already enabled")
		return true
	end
	self.state.enabled = true
	self:_log(string.format("Enabled — scanning every %ss", self.state.scan_interval))
	self:_do_scan()
	self:_start_timer()
	return true
end

function AutoMinigame:disable()
	if not self.state.enabled then
		self:_log("Already disabled")
		return true
	end
	self.state.enabled = false
	self:_stop_timer()
	self:_log("Disabled")
	return true
end

function AutoMinigame:solve()
	self:_log("One-shot solve triggered")
	return self:_do_scan()
end
```

- [ ] **Step 3: Add reload guard**

Add before `return AutoMinigame:new()`:

```lua
-- ── Reload guard ──

_G.Reg.lib("Cocos").delay_call(0.5, function()
	local instance = _G.Reg.module("actions.autominigame")
	if instance and instance.state.enabled then
		instance:_log("Reload detected while enabled — restarting timer")
		instance:_start_timer()
	end
end)
```

- [ ] **Step 4: Run tests**

Run:
```powershell
& "C:\temp\Where Winds Meet\.venv\Scripts\python.exe" "C:\temp\Where Winds Meet\Scripts\inject\debug.py" "dofile('C:/temp/Where Winds Meet/Scripts/tests/run_all.lua')"
```

Check: `Scripts/logs/test_results.txt`
Expected: All `test_autominigame` tests PASS. ALL GREEN.

- [ ] **Step 5: Commit**

```bash
git add Scripts/actions/autominigame.lua
git commit -m "feat: implement timer, enable/disable, solve for autominigame"
```

---

## Task 5: Implement _try_solve routing logic

**Files:**
- Modify: `Scripts/actions/autominigame.lua`

- [ ] **Step 1: Implement _try_solve, _solve_direct, _solve_entity_game**

Add after the `_debug` method and before `_stop_timer`:

```lua
-- ── Solve routing ──

function AutoMinigame:_try_solve(game_id, game_handler, region_game_consts)
	-- Skip if already finished
	if region_game_consts then
		local is_finished = false
		pcall(function()
			is_finished = region_game_consts.is_region_game_finished(nil, game_id)
		end)
		if is_finished then
			self:_debug("skip(finished): " .. tostring(game_id))
			self.state.done[game_id] = true
			return
		end
	end

	-- Skip if game is in DONE state (3)
	if game_handler.region_game_state == 3 then
		self:_debug("skip(state=DONE): " .. tostring(game_id))
		self.state.done[game_id] = true
		return
	end

	-- Lookup config
	local config = nil
	pcall(function()
		config = G.datam.region_game_config:get(game_id)
	end)
	if not config then
		self:_debug("skip(no config): " .. tostring(game_id))
		return
	end

	-- Route: entity-based or direct
	local rel_entities = nil
	pcall(function()
		rel_entities = config:get("__rel_ins_serial_id_d")
	end)

	local has_entities = false
	if rel_entities then
		pcall(function()
			has_entities = next(rel_entities) ~= nil
		end)
	end

	if has_entities then
		self:_solve_entity_game(game_id, rel_entities)
	else
		self:_solve_direct(game_id)
	end
end

function AutoMinigame:_solve_direct(game_id)
	self:_log(string.format("solve_direct: game_id=%s", tostring(game_id)))
	local ok, err = pcall(function()
		G.main_player:send_success_region_game_id(game_id)
	end)
	if ok then
		self.state.done[game_id] = true
		self:_log(string.format("  success: game_id=%s", tostring(game_id)))
	else
		self:_log(string.format("  FAIL: game_id=%s err=%s", tostring(game_id), tostring(err)))
	end
end

function AutoMinigame:_solve_entity_game(game_id, rel_entities)
	local autoloot = _G.Reg.module("actions.autoloot")

	if not autoloot then
		self:_log(string.format("WARN: autoloot not loaded, falling back to direct RPC for game_id=%s", tostring(game_id)))
		self:_solve_direct(game_id)
		return
	end

	local all_handled = true
	for serial_id, _ in pairs(rel_entities) do
		local entity = nil
		pcall(function()
			entity = G.space:get_entity_by_serial_no(serial_id)
		end)
		if entity then
			self:_debug(string.format("  entity_interact: game=%s serial=%s entity=%s", tostring(game_id), tostring(serial_id), tostring(entity.entity_id)))
			pcall(function()
				autoloot:try_interact_entity(entity)
			end)
		else
			self:_debug(string.format("  entity_not_spawned: game=%s serial=%s", tostring(game_id), tostring(serial_id)))
			all_handled = false
		end
	end

	if all_handled then
		self.state.done[game_id] = true
		self:_log(string.format("  all entities handled: game_id=%s", tostring(game_id)))
	end
end
```

- [ ] **Step 2: Replace do_scan with full version**

**Replace** the `do_scan()` method written in Task 4 with this version that passes `region_game_consts` to `_try_solve`. Note: `portable` is a game engine global — no import needed.

```lua
function AutoMinigame:_do_scan()
	local mp = G.main_player
	if not mp then
		return false
	end
	if not mp._curr_region_game then
		return false
	end

	local region_game_consts = nil
	pcall(function()
		region_game_consts = portable.safe_import("hexm.common.consts.region_game_consts")
	end)

	for game_id, game_handler in pairs(mp._curr_region_game) do
		if not self.state.done[game_id] then
			pcall(function()
				self:_try_solve(game_id, game_handler, region_game_consts)
			end)
		end
	end
	return true
end
```

- [ ] **Step 3: Format**

```powershell
uv run stylua --syntax Lua54 "C:\temp\Where Winds Meet\Scripts\actions\autominigame.lua"
```

- [ ] **Step 4: Run tests**

Run:
```powershell
& "C:\temp\Where Winds Meet\.venv\Scripts\python.exe" "C:\temp\Where Winds Meet\Scripts\inject\debug.py" "dofile('C:/temp/Where Winds Meet/Scripts/tests/run_all.lua')"
```

Check: `Scripts/logs/test_results.txt`
Expected: ALL GREEN.

- [ ] **Step 5: Commit**

```bash
git add Scripts/actions/autominigame.lua
git commit -m "feat: implement _try_solve routing with entity and direct paths"
```

---

## Task 6: Final verification — full test suite

**Files:** None (verification only)

- [ ] **Step 1: Format all changed files**

```powershell
uv run stylua --syntax Lua54 "C:\temp\Where Winds Meet\Scripts\actions\autominigame.lua" "C:\temp\Where Winds Meet\Scripts\tests\test_autominigame.lua"
```

- [ ] **Step 2: Run full test suite**

```powershell
& "C:\temp\Where Winds Meet\.venv\Scripts\python.exe" "C:\temp\Where Winds Meet\Scripts\inject\debug.py" "dofile('C:/temp/Where Winds Meet/Scripts/tests/run_all.lua')"
```

- [ ] **Step 3: Verify checklist**

Check `Scripts/logs/test_results.txt` for:
- [ ] ALL GREEN (all suites pass, all modules load)
- [ ] `autominigame` appears in LOADED modules list
- [ ] `test_autominigame` suite passes with 0 failures

Check `Scripts/actions/autominigame.lua` for:
- [ ] No `_G.KURO_*` direct access
- [ ] No `Utils.*` calls
- [ ] No bare `require()` for game modules (only `portable.safe_import()`)
- [ ] File structure order: extend → constants → define_state → define_hooks → private → public → return :new()

- [ ] **Step 4: Final commit if any formatting changes**

```bash
git add -A
git commit -m "style: format autominigame module and tests"
```

---

## Complete File Reference

After all tasks, the final `Scripts/actions/autominigame.lua` should contain these sections in order:

1. Header comment
2. `ActionBase:extend("actions.autominigame")`
3. Constants: `SCAN_INTERVAL`
4. `define_state()` — persistent: `enabled`, `enable_logging`; transient: `done`, `timer_action`, `scan_interval`, `log_cache`
5. `define_hooks()` — returns `{}`
6. Private: `_log`, `_debug`, `_try_solve`, `_solve_direct`, `_solve_entity_game`, `_stop_timer`, `_start_timer`, `_do_scan`
7. Public: `enable()`, `disable()`, `is_enabled()`, `solve()`, `reset()`
8. Reload guard
9. `return AutoMinigame:new()`

Note: `portable` is a game engine global (always available in the VM). Do not import it — use it directly like all other action modules do.
