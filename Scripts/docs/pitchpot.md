# Pitchpot Minigame — Research Report

## Question / Scope

How does the pitchpot (投壶) minigame work internally, and what APIs are available to automate play?

## Evidence

### 1. Game Lifecycle (Score: 5 — Direct Definition)

**Source:** `hexm/client/entities/local/player_avatar_members/imp_pitch_pot.lua`

The pitchpot lifecycle flows through these stages:

1. **Enter**: `enter_pitchpot()` → `real_enter_pitchpot()` → `G.net:call_server("rpc_begin_pitch_pot", target_id, platform_entity_id, serial_id)`
2. **Server responds**: Status changes drive the flow via `_pitch_pot_status_change()`:
   - `PITCH_POT_STATE_ANIM (5)` → cutscene → `pitchpot_npc_ready()` or `pitchpot_player_ready()`
   - `PITCH_POT_STATE_DRINK (7)` → drinking animation
   - `PITCH_POT_STATE_PITCH_POT (8)` → actual throwing begins via `PITCH_POT_EVENTS_REAL_BEGIN`
3. **Throwing**: Player aims and throws arrows. Each throw reports: `G.net:call_server("rpc_add_pitch_pot_score", is_hit, config_id)`
4. **End**: Server sends `PITCH_POT_EVENTS_END` → `pitchpot_end_from_server(data)` → result UI

### 2. Scoring RPC (Score: 5 — Direct Definition)

**Source:** `imp_pitch_pot.lua:211-213`

```lua
function PlayerAvatarMember:pitchpot_add_score(is_hit, config_id)
    G.net:call_server("rpc_add_pitch_pot_score", is_hit, config_id)
end
```

- `is_hit` (boolean) — whether the arrow hit the pot
- `config_id` — the stage config ID for the current round

The server tracks: `score`, `combo`, `max_combo`, `hit_times` via `PitchPotFightInfo` properties.

### 3. State Constants (Score: 5 — Direct Definition)

**Source:** `hexm/common/consts/pitch_pot_consts.lua`

```
PITCH_POT_STATE_FREE = 0
PITCH_POT_STATE_INVITING_AGREE = 3
PITCH_POT_STATE_DIALOG = 4
PITCH_POT_STATE_ANIM = 5
PITCH_POT_STATE_DRINK = 7
PITCH_POT_STATE_PITCH_POT = 8
WIN = 0, LOSE = 1, DRAW = 2
```

### 4. Collimator/Aiming (Score: 4 — Strong Correlation)

**Source:** `imp_pitch_pot.lua:1161-1179`

Wine attribute affects aiming difficulty:
- `get_pitch_pot_wine_collimator_range_scale()` — scales the aiming range
- `get_pitch_pot_wine_collimator_move_scale()` — scales the aiming speed

These read from `G.datam.pitch_pot_wine_attr_data`. The actual aiming/throwing UI logic is in `StateDrinkPitchPot` (gameplay state) and `GangPitchPotWindow` (UI), **which are NOT in the decompiled codebase**.

### 5. Entry Points (Score: 5 — Direct Definition)

**Source:** `imp_pitch_pot.lua:129-143`

- **NPC game**: `G.main_player:pitch_pot_start_with_npc(entity_id)` → sets target → calls `enter_pitchpot()`
- **PvP game**: `G.main_player:pitch_pot_start_with_player(player_id, platform_entity_id, hostnum)`
- **Data-driven**: `G.main_player:enter_pitchpot()` (from go_to config)

### 6. Control RPCs (Score: 5 — Direct Definition)

**Source:** `imp_pitch_pot.lua:190-213`

| RPC | Purpose |
|-----|---------|
| `rpc_begin_pitch_pot(target, platform, serial)` | Start a match |
| `rpc_add_pitch_pot_score(is_hit, config_id)` | Report each throw |
| `rpc_pitch_pot_pause` | Pause |
| `rpc_pitch_pot_continue` | Resume |
| `rpc_pitch_pot_surrender` | Surrender |
| `rpc_pitch_pot_interrupt` | Interrupt |
| `rpc_pitch_pot_leave` | Leave |
| `rpc_pitch_pot_interest_skill` | Use special skill |
| `rpc_pitch_pot_choose_pour_money(bet_index)` | Place bet |
| `pitch_pot_leave_dialog` | Skip dialog |

### 7. State Detection (Score: 5 — Direct Definition)

**Source:** `imp_pitch_pot.lua:1278-1291`

```lua
function PlayerAvatarMember:is_in_pitchpot()
    if self.pitchpot_is_end then return false end
    local state_name = self.statem:curr_state_name()
    if "gameplay" == state_name then
        local curr_game_play_name = self.statem:curr_state():get_game_play_name()
        if "drink_pitch_pot" == curr_game_play_name then return true end
    end
    return false
end
```

### 8. Round Config (Score: 4 — Strong Correlation)

**Source:** `imp_pitch_pot.lua:1111-1114`

```lua
function PlayerAvatarMember:get_pitchpot_round_list()
    local stage_sysd = self:get_pitch_pot_stage_sysd()
    return G.datam.pitch_pot_stage_config_ids:get(stage_sysd:get("stage_group_no"))
end
```

Each round has a config ID. The round list is retrieved from `pitch_pot_stage_config_ids` data.

## Conclusions (Score ≥ 3 only)

1. **Automation is feasible via `rpc_add_pitch_pot_score`** (Score 5): The client reports each throw's result to the server. By calling `pitchpot_add_score(true, config_id)` repeatedly, we can report perfect hits without needing to interact with the aiming UI.

2. **Auto-aim hooking requires undumped files** (Score 4): The actual aiming mechanics live in `StateDrinkPitchPot` and `GangPitchPotWindow`, which are not yet decompiled. Two approaches exist:
   - **RPC-direct**: Call `rpc_add_pitch_pot_score` with `is_hit=true` on a timer → bypasses aiming entirely
   - **Hook aiming**: Would require dumping the gameplay state to find aim resolution logic

3. **Game flow can be fully automated** (Score 5): Dialog skip (`pitch_pot_leave_dialog`), state detection (`is_in_pitchpot`), and round config retrieval (`get_pitchpot_round_list`) are all accessible.

## Unknown / Missing Evidence

- `StateDrinkPitchPot` gameplay state — not dumped. Controls the aiming camera, input handling, throw timing.
- `GangPitchPotWindow` UI — not dumped. Manages the in-game HUD during pitchpot.
- Throw timing/interval — unclear how fast throws can be sent. Need probe test.
- `config_id` for each round — need to verify what value to pass to `rpc_add_pitch_pot_score`. Likely the current round's config from `get_pitchpot_round_list()`.

## Next Steps

1. Write probe test to verify:
   - `G.main_player:is_in_pitchpot()` works
   - `G.main_player:pitchpot_add_score(true, config_id)` accepts calls during gameplay
   - Round config retrieval via `get_pitchpot_round_list()`
   - Current fight info shape verification
2. Implement `pitchpot.lua` action module with auto-score feature
