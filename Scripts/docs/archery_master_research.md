# Archery Master — Research & Findings

## Overview

Automating the Archery Master minigame by remotely triggering hits on target entities (birds, `No=6600096`) via the game's combat pipeline.

## What Works

### Remote Damage via `process_calcpoint_to_eid`

Targets can be killed remotely using `CalcpointBase:process_calcpoint_to_eid`:

```lua
attacker:process_calcpoint_to_eid(calc_id, {target_eid}, skill_id, params)
```

- `params` must use `TypeUtils.init_dict({...})` (needs `:contains()` method for `calcpoint_base.lua:372`)
- Plain Lua table `{eid}` works for `target_ids` argument
- `TypeUtils.init_dict` works for scalar values like `arrow_dmg=true`

### Trace-Derived Parameters

From manual gameplay trace (`index_session_20260323_152928.log`):

| Parameter | NPC Attacker (seq 200) | Player Arrow (seq 541) |
|-----------|----------------------|----------------------|
| Attacker entity | `Npc(sid.1630240370)(No.6600097)` | `PlayerAvatar(sid.-1)` |
| `calcpoint_id` | `8702110101` | `11202502` |
| `skill_id` | `87021103` | `112024` |
| `kongfu_id` | `0` | `10102` |
| `arrow_dmg` | absent | `true` |
| `target_ids` | absent | `[p_npc_...]` |

### Test Results

| Attacker | calc_id | skill_id | Damage | Score |
|----------|---------|----------|--------|-------|
| `G.main_player.fake_server` | `11202502` | `112024` | ✅ | ❌ |
| `G.main_player.fake_server` | `8702110101` | `87021103` | ✅ | ❌ |
| Opponent NPC `.fake_server` | `8702110101` | `87021103` | ✅ | ✅ (opponent) |
| `G.main_player` (local) | `8702110101` | `87021103` | untested | untested |

## What's Stuck — Score Attribution

### Problem

Damage registers but score does not count for the player. When using the opponent NPC as attacker, score counts but credits the opponent.

### Root Cause Analysis

#### Key code in `DamageManager:process_calcpoint` (`damage_manager.lua`)

1. **Line 188-189** — `fake_server` is auto-converted to `local_entity`:
   ```lua
   if attacker.is_fake_server then
       attacker = attacker.local_entity
   end
   ```
   So `fake_server` vs `local_entity` as input does NOT matter.

2. **Line 198** — Ghost check determines code path:
   ```lua
   if atk_owner:is_ghost() then
       atk_owner:call_real_syn("process_calcpoint_to_eid", ...)
       return
   end
   ```

3. **Lines 485-504** — Client-side path (used by player) **defers** via timer:
   ```lua
   self.timer_mgr:add_timer(0, function()
       local res = target:behit(calc_id, dmg_res, param_context)
       attacker:on_calcpoint_hit_tg(process_id, calc_id, target_id, res)
   end)
   ```
   The `on_calcpoint_hit_tg` fires on the **next tick**, separately from the main trace.

4. **Lines 512-543** — Server-side path (used by NPC) runs **synchronously**:
   ```lua
   tg:call_real("behit", {...}, function(...)
       atk:on_calcpoint_hit_tg(process_id, calc_id, target_id, res)
   end, ...)
   ```

#### Trace Evidence

- **NPC trace (seq 200)**: `on_calcpoint_hit_tg` IS present at end of trace → `e_calcpoint_hit_tg` dispatched via `fake_dispatcher_redirect.lua` on the **local Npc entity**
- **Player trace (seq 541)**: `on_calcpoint_hit_tg` is **NOT present** → deferred to next tick (timer callback not captured in trace)

### Root Cause (Resolved)

The score system works through `E_HP_COMBAT_CHANGE`, NOT `E_CALCPOINT_HIT_TG`:

1. When target HP changes, `attr_base:_hp_change_dispatch` (line 293-304) calls:
   ```lua
   self.space:defer_dispatch(fromid, events.E_HP_COMBAT_CHANGE, data)
   ```
   where `fromid` = **attacker entity ID** (from `parse_context.attacker_id`)

2. The archery scoring module (`ArcheryGameplay`, not in decompiled source) listens for `E_HP_COMBAT_CHANGE` on the **archery NPC entity** (No=6600097)

3. When `G.main_player` is attacker: `fromid` = player ID → event dispatched on player entity → NPC's listener never fires → **no score**

4. When archery NPC is attacker: `fromid` = NPC ID → event dispatched on NPC entity → NPC's listener fires → **score counted**

**Key evidence**: `sync_calcpoint` (damage_manager.lua:1417) only syncs BOSS targets to the real server. Birds are not bosses, so all scoring is client-side via the fake_server path.

**Fix**: Use the player's own archery NPC (closest one) as the attacker instead of `G.main_player`. The NPC's `is_ghost()=true` causes `call_real_syn` to route through the fake_server, matching the normal gameplay path exactly.

## Architecture Reference

```
process_calcpoint_to_eid (calcpoint_base.lua:360)
  └─ DamageManager:process_calcpoint (damage_manager.lua:182)
       ├─ if attacker.is_fake_server → attacker = attacker.local_entity
       ├─ if atk_owner:is_ghost() → call_real_syn (server path)
       └─ _real_process (damage_manager.lua:~350)
            ├─ reg_calcpoint_process (stores targets in _calc_process_info)
            ├─ CLIENT: add_timer(0, function()
            │    ├─ target:behit(calc_id, dmg_res, context)
            │    │    ├─ _on_damage → attr_set_HP → _hp_change_dispatch
            │    │    │    └─ defer_dispatch(fromid, E_HP_COMBAT_CHANGE)
            │    │    └─ e_behit dispatched on target
            │    └─ attacker:on_calcpoint_hit_tg(...)
            │         └─ dispatcher:dispatch(E_CALCPOINT_HIT_TG)
            └─ SERVER: call_real("behit", ..., callback)
                 └─ atk:on_calcpoint_hit_tg(...) [synchronous]
```
