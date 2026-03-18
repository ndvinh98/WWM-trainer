# Auto-Minigame Region Solver — Design Spec

## Goal

Auto-complete region minigames that the player has already entered. When the game engine activates a region game (player walks into `__inner_range`), the module detects it and resolves it automatically — either via direct RPC or by delegating entity interactions to the autoloot module.

## Scope

- **In scope:** Games already loaded in `G.main_player._curr_region_game` (player is inside trigger range).
- **Out of scope:** Teleporting to games, game-type-specific puzzle logic, movement/positioning sequences, multiplayer occupy/lock system handling.

## File

`Scripts/actions/autominigame.lua`

## Module Structure

Extends `ActionBase` via `ActionBase:extend("actions.autominigame")`.

Must implement `define_state()` returning the state table and `define_hooks()` returning `{}`.
Must end with `return AutoMinigame:new()` (standard ActionBase singleton pattern).

### State

```lua
function AutoMinigame:define_state()
  return {
    persistent = {
      enabled         = false,   -- continuous scan toggle
      enable_logging  = true,    -- debug logging toggle
    },
    transient = {
      done            = {},      -- game_ids already processed
      timer_action    = nil,     -- cocos RepeatForever handle
      scan_interval   = 2.0,     -- seconds between scans
      log_cache       = {},      -- deduplicated log messages
    },
  }
end
```

### Hooks

```lua
function AutoMinigame:define_hooks()
  return {}
end
```

No hooks required — this module is RPC/interaction-driven.

### Public API

| Method        | Description                                      |
|---------------|--------------------------------------------------|
| `enable()`    | Start continuous scanning with periodic timer    |
| `disable()`   | Stop timer, clear state                          |
| `solve()`     | One-shot: process all active games once          |
| `reset()`     | Clear the `done` cache                           |
| `is_enabled()`| Return current enabled state                     |

## Core Logic: `do_scan()`

Iterates `G.main_player._curr_region_game` and routes each game to the appropriate completion path.

### Flow

```
do_scan()
  for game_id, game_handler in pairs(G.main_player._curr_region_game):
    skip if done[game_id]
    skip if region_game_consts.is_region_game_finished(nil, game_id)
      -- nil is safe: is_region_game_finished resolves to G.net:get_avatar() internally
    skip if game_handler.region_game_state == GAME_STATE_DONE (3)

    config = G.datam.region_game_config:get(game_id)

    if config:get("__rel_ins_serial_id_d") is non-empty:
      _solve_entity_game(game_id, config)
    else:
      _solve_direct(game_id, game_handler)
```

### Path 1: `_solve_direct(game_id, game_handler)`

For games without entity interactions:

1. Bypass handler delegation risk: call `G.main_player:send_success_region_game_id(game_id)` directly instead of `game_handler:success_game()`. This avoids triggering handler-specific logic that may expect server-side prerequisites.
2. Mark `done[game_id] = true`.
3. All wrapped in `pcall`.

**Why bypass `success_game()`:** Some games have common handlers (CHEST_FLY, PSBX, CHASE_MOUSE, PURSUE, COMPOSITE_BOX, QJZ, QZBML) where `success_game()` delegates to `handler:success_game()`, which may have server-side expectations (prior RPCs, state progression). Calling `send_success_region_game_id` directly fires `rpc_region_game_mask` cleanly.

### Path 2: `_solve_entity_game(game_id, config)`

For games with `__rel_ins_serial_id_d` entity serial IDs:

**Note:** `__rel_ins_serial_id_d` is a **dictionary** keyed by serial_id (not a list). Iterate with `for serial_id, _ in pairs(config:get("__rel_ins_serial_id_d", {}))`.

1. Get autoloot instance: `_G.Reg.module("actions.autoloot")`.
2. For each `serial_id` in `config:get("__rel_ins_serial_id_d", {})`:
   - Resolve entity: `G.space:get_entity_by_serial_no(serial_id)`.
   - If entity exists and not yet interacted: call `autoloot:try_interact_entity(entity)`.
   - If entity not spawned yet: skip, retry on next scan tick.
3. Mark `done[game_id]` after all entities have been passed to autoloot.
4. Fallback: if autoloot module is not loaded, call `G.main_player:send_success_region_game_id(game_id)` directly. **Known limitation:** this may not work for all entity-based games — the server may expect entity interactions before marking success. Log a warning when this path is taken.

## Autoloot Integration

- Autoloot module obtained via `_G.Reg.module("actions.autoloot")`.
- Autoloot's `try_interact_entity(entity)` handles the full interaction protocol:
  - PROGRESS_NORMAL (0): START -> wait start_back -> RESULT_AND_END
  - PROGRESS_CLIENT_FIRST (3): direct RESULT
  - PROGRESS_CALL_RESULT (2): direct RESULT, wait result_back
  - PROGRESS_LOCAL (1): skipped
  - TAG_GENERAL_STROKE entities: break entity path
  - Battle state entities: force transit path
- Autoloot manages its own pending slot and per-entity done tracking.
- AutoMinigame tracks per-game_id completion separately.

## Timer & Lifecycle

- `enable()`: sets `state.enabled = true`, runs `do_scan()` immediately, starts `cc.RepeatForever` timer at `scan_interval`.
- `disable()`: sets `state.enabled = false`, stops timer.
- `solve()`: calls `do_scan()` once regardless of enabled state.
- `reset()`: clears `done` cache (allows re-processing).
- Reload guard: on module reload, if enabled, restart the timer (same pattern as autoloot).

## Edge Cases

| Scenario                            | Handling                                              |
|-------------------------------------|-------------------------------------------------------|
| Game already finished               | Skip via `is_region_game_finished(nil, game_id)` — resolves avatar internally |
| Game in DONE state                  | Skip via `region_game_state == GAME_STATE_DONE` check  |
| Entity not yet spawned              | Skip this scan, retry next tick                       |
| Autoloot module not loaded          | Fall back to direct `send_success_region_game_id` (warning logged) |
| Game destroyed mid-scan             | pcall wrapper catches error, continue                 |
| Player leaves range during scan     | Engine removes game from `_curr_region_game`          |
| `solve()` while `enable()` active   | Works fine — `solve()` runs `do_scan()`, timer continues |
| Module reload while enabled         | Reload guard restarts timer                           |
| Handler-based games                 | Bypassed — use direct `send_success_region_game_id` to avoid handler prerequisites |

## Not Handled (Intentional)

- Teleporting to game locations.
- Game-type-specific puzzle solving (positioning, sequences).
- Games requiring specific player actions that cannot be bypassed via RPC or entity interaction.
- Multiplayer occupy/lock system — if another player has occupied a game, the RPC may fail silently.
