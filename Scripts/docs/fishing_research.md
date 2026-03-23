# Fishing Minigame Research Report

## Scope
Research fishing minigame mechanics to implement an auto-play module.

## Evidence

### 1. Fishing State Machine
**Source:** `hexm.client.ui.windows.fish.fish_game_consts` (Score: 5/5)

Sub-states within `GAMEPLAY_FISHING`:
- `FISHING_WAIT` — preparing, pole in hand, waiting for player to cast
- `FISHING_CORE` — active minigame (throw → wait → hook → drag/QTE → result)
- `FISHING_ANIM` — pole draw animation
- `FISHING_LEAVE` — exit state

### 2. RPC Flow (Score: 5/5)

**Client → Server:**
- `start_fishing_game_btn_end(inter_time)` — sends throw data: `{bait, throw, rod_id, farm}`
- `rpc_fish_rod_activate` / `rpc_fish_rod_deactivate` — rod equip management
- `rpc_fishing_contest_start` — for contest mode

**Server → Client callbacks:**
1. `rpc_fishing_back(err, data)` — error/timeout response
2. `rpc_fishing_throw(data)` → dispatches `E_FISH_THROW_POLE_BACK` — line is in water
3. `rpc_fishing_hooked(data)` → dispatches `E_FISH_HOOK_BACK` — fish is on the hook
4. `rpc_fishing_send_reward(data)` → dispatches `E_FISH_GAME_RESULT` — minigame completed
5. `rpc_fishing_finish(err)` → dispatches `E_FISH_GAME_GIVE_UP_BACK` — gave up

### 3. Fishing Consts (Score: 5/5)
- `FISHING_STATE_IDLE = 1`, `FISHING_STATE_THROW = 2`, `FISHING_STATE_HOOK = 3`
- `FISHING_CAPACITY_NORMAL = 1`, `FISHING_CAPACITY_BOOM = 2`
- `FISHING_BASETYPE_FISH = 0`, `FISHING_BASETYPE_GARBAGE = 1`

### 4. Key Player Methods (Score: 5/5)
- `G.main_player:is_in_fish_state()` — check if in GAMEPLAY_FISHING
- `G.main_player:try_start_fishing_game()` — initiate fishing (checks water, pole, bait, farm)
- `G.main_player:start_fishing_game_btn_end(inter_time)` — send throw with hold time
- `G.main_player:check_fish_pole_is_in_hand()` — pole readiness
- `G.main_player:check_fish_game_bait_state()` — bait available
- `G.main_player:get_curr_fish_farm_id()` — current fishing zone

### 5. Data Config: `fishing_base` (Score: 5/5)
- `max_press = 1.6` — max button hold time for throw
- `finish_max = 100` — progress bar max for catching
- `drag_per = 0.8` — drag percentage
- `play_fish_region = [-3, 3]` — fish movement region
- `speed_bound = 3.5` — fish speed limit
- `fail_time_1 = 10`, `fail_time_2 = 60` — timeout values

### 6. Key Events (from event_consts.lua) (Score: 5/5)
- `E_FISH_THROW_POLE_BACK` — throw acknowledged by server
- `E_FISH_HOOK_BACK` — fish hooked
- `E_FISH_GAME_RESULT` — game result
- `E_FISH_PLAYER_DRAG` — player drag interaction
- `E_FISH_GAME_QTE_SUCCESS` — QTE prompt success
- `E_FISH_GAME_ACCELERATE_HOOK` — accelerate the hook
- `E_FISH_PC_DRAG_FISH_LEFT/RIGHT` — PC drag directions
- `E_FISH_GAME_GIVE_UP_BACK` — gave up

## Conclusions

The fishing minigame involves:
1. **Throw phase**: Hold button → release, with `inter_time` determining throw distance
2. **Wait phase**: Wait for server to notify fish bite (`rpc_fishing_throw`)
3. **Hook phase**: Server notifies hook (`rpc_fishing_hooked`)
4. **Drag/QTE phase**: Interactive minigame (progress towards `finish_max=100`) — UI code not in decompiled sources
5. **Result phase**: Server sends reward or failure

### Auto-play Strategy
Since the drag/QTE UI code isn't in decompiled sources, we need runtime probing to discover:
1. How the drag progress is updated (what APIs move the progress bar)
2. Whether we can hook the throw → hook → result flow directly
3. Whether dispatching `E_FISH_PLAYER_DRAG` or `E_FISH_GAME_QTE_SUCCESS` events can automate the minigame

**Approach A (Hook-based):** Hook the game's throw/hook response handlers to auto-respond
**Approach B (Event-based):** Dispatch drag/QTE events to simulate player input
**Approach C (Direct RPC):** Mirror what the game does on success (needs more research)

## Next Steps
1. Write probe test to discover: fish state properties, available methods, drag mechanics
2. Based on probe results, choose approach and implement
