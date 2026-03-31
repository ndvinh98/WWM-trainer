# Remote Entity AI Trigger — Analysis

## Question / Scope

How to remotely trigger entity AI behaviors (e.g. guider butterfly pursuit) without physically teleporting the player to the entity's position.

## Evidence

### 1. Entity AI Proximity Sensor

**Source:** `Scripts/source_decompiled/hexm/client/entities/local/common_members/proximity_base.lua`
**Probe:** `ent.proximity_rb_map` inspection on entity sid=1630600024

Entities with AI behavior trees register proximity sensors via `add_proximity_from_ai()`. These appear in `ent.proximity_rb_map` with IDs matching the pattern `AI_<entity_id>_<N>` where N is the radius.

```
proximity_id: AI_actHBhDWbbl+qMsR_3
config type: dict
  collision_type = 26
  radius = 3
  callback = [function]
  is_optimal_trigger = true
```

**Evidence Confidence: 5/5** — direct runtime probe confirmed.

### 2. Callback Fires Successfully

**Probe:** `cb(G.main_player_id, "enter")` on the proximity config's callback function.

Firing the callback with the player's entity ID and "enter" flag triggers the entity's AI behavior tree (confirmed visually — butterfly started pursuit sequence).

**Evidence Confidence: 5/5** — runtime probe confirmed + user visual confirmation.

### 3. Why `on_main_player_npc_collision()` Failed

**Source:** `Scripts/source_decompiled/hexm/client/entities/local/npc_members/imp_collision.lua:82-98`

The collision system and the AI proximity system are **independent paths**:

| System | Code | This entity |
|--------|------|-------------|
| NPC collision (`imp_collision.lua`) | Checks `collision_avatar`, `player_collision_reaction` in ai_data | `collision_avatar=0` — **disabled** |
| AI proximity (`DistanceDecorator` BT node) | Creates proximity via `add_proximity_from_ai` | `AI_*_3`, radius=3 — **active** |

The entity's `collision_avatar=0` and `is_surprise=0` mean the NPC collision reaction system is completely disabled. The entity uses AI behavior tree proximity detection instead.

**Evidence Confidence: 5/5** — probe confirmed all guard conditions.

### 4. AI Behavior Tree: `fsbd_hudie` (Butterfly)

**Source:** `Scripts/source_decompiled/Sunshine/AI/bt2code/output/fsbd_hudie.lua`
**Probe:** `ent.fake_server.__dict__._latest_ai_file = "fsbd_hudie"`

The butterfly BT structure:
1. `ReceiveWanFaEvent` — waits for `E_REGION_GAME_PURSUE_START`
2. `DistanceDecorator` — creates the `AI_*_3` proximity sensor, monitors `bb_main_player` (Avatar type)
3. On proximity enter → abort filter triggers → proceeds to `NaviWithHexPathLauncher` (navigation to waypoints)
4. `SendEventAction` dispatches `E_REGION_GAME_PURSUE_MID` at each waypoint
5. At final waypoint: plays `b_die` animation, dispatches `E_REGION_GAME_PURSUE_ARRIVE`

**Evidence Confidence: 5/5** — source + runtime confirmation.

### 5. Entity Tags Pattern

**Probe:** `ent.tag` on target entity

```
TAG_NPC, TAG_CHARACTER_TYPE, TAG_GUIDER_BUTTERFLY, TAG_PEACEFUL_NPC, 
TAG_MODE_INTERACT_ALL, TAG_XS_XUANSHANG, TAG_GENERAL_STROKE
```

Entities with AI proximity sensors are NPCs with behavior trees. Not all NPCs have them — only those whose AI tree includes proximity-based nodes (like `DistanceDecorator`).

**Evidence Confidence: 5/5**

## Conclusions

1. **Remote AI trigger works by firing the entity's proximity callback directly.** Read `ent.proximity_rb_map`, extract the callback, call `cb(G.main_player_id, "enter")`.

2. **The NPC collision system is unrelated.** `on_main_player_npc_collision` is for stumble/dodge reactions controlled by `collision_avatar` in ai_data. AI proximity is a separate system driven by behavior tree nodes.

3. **Detection pattern:** Entities with AI proximity sensors have entries in `proximity_rb_map` with IDs starting with `AI_`. The config is a game Dict with `callback`, `radius`, and `is_optimal_trigger=true`.

4. **Generic approach for all entities:**
   - Scan `G.space:get_entities_in_range()` for nearby NPCs
   - For each entity, check `proximity_rb_map` for `AI_*` entries
   - Fire `callback(G.main_player_id, "enter")` for each

## Implementation Plan

**Module:** `actions.auto_proximity` — scans nearby entities on a timer, fires AI proximity callbacks for entities within configurable range.

**Scan logic:**
1. `G.space:get_entities_in_range(player_pos, scan_radius, nil, filter_fn, true)`
2. Filter: `ent.tag:is_npc()` and `ent.proximity_rb_map` is non-empty
3. For each qualifying entity, iterate `proximity_rb_map`
4. Fire callbacks where proximity_id starts with `"AI_"` and config has `is_optimal_trigger`
5. Track fired entities in `done` set to avoid re-firing

**Lifecycle:** Timer-based scan (like autoloot), enable/disable/reset API.
