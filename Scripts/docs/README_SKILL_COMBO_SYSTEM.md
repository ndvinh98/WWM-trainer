# Skill Combo System Analysis

## Question / Scope

How does the skill combo system work in Where Winds Meet? What are the mechanisms for combo chaining, combo state transitions, slot resolution, and how does kongfu (martial art style) relate to equipped skills?

---

## Evidence

### E1: Combo State Machine (skill_ctrl.lua)

**Source:** `Scripts/source_decompiled/hexm/common/combat/skill_ctrl.lua:59-62, 94, 560`
**Source:** `Scripts/source_decompiled/hexm/common/consts/skill_consts.lua:665-682`

```lua
-- State constants
COMBO_STATE_START = "COMBO_START"
COMBO_STATE_END = "COMBO_END"

-- In SkillCtrl:
self.combo_state = ""  -- Reset on init and skill_end

-- State callback mapping:
[COMBO_STATE_START] = "on_skill_combo_start"
[COMBO_STATE_END]   = "on_skill_combo_end"
```

**Why it matters:** The combo system is driven by a state machine on `skill_ctrl`. The `combo_state` field transitions between `""` → `"COMBO_START"` → `"COMBO_END"` → `""`. The state is reset to `""` on every `skill_end_notify`.

**Evidence Confidence:** 5/5

---

### E2: Two Combo Modes — Cue Combo vs Time Combo

**Source:** `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/imp_skill_slots.lua:560-618, 666-830`

The skill event handler dispatches to two different combo paths:

```lua
-- Event: E_SKILL_COMBO_START → Cue Combo (immediate)
self:skill_manager_handle_combo_start()

-- Event: E_SKILL_START + skill_combo_info present → Time Combo (timed window)
self:skill_manager_handle_time_combo_start()
```

#### Cue Combo (`skill_manager_handle_combo_start`, line 666):
- Triggered by animation event `COMBO_START`
- Reads `skill_combo_ids` from skill sys_d (data table)
- Randomly picks one combo from the list (excluding the last used one to avoid repeats)
- Only executes if `skill_ctrl.combo_state == "COMBO_START"`
- Updates `_combo_skills_map` → replaces the slot's active skill with the combo skill

#### Time Combo (`skill_manager_handle_time_combo_start`, line 732):
- Triggered at `E_SKILL_START` if the skill has `skill_combo_mode > 0` and `skill_combo_info`
- Uses `skill_combo_window` duration to create a timed window
- `skill_combo_mode == 1`: Standard timer — combo expires after window
- `skill_combo_mode == 2`: Persistent display — combo stays visible, timer still runs
- `skill_combo_info = [total_combo, cur_combo]`: When `cur_combo == total_combo`, combo chain ends

**Why it matters:** There are two distinct combo trigger paths. Cue combos are animation-driven (triggered by the skill's animation hitting a specific frame). Time combos are data-driven (opened by a timer window after skill start).

**Evidence Confidence:** 5/5

---

### E3: Combo Skill Selection Algorithm

**Source:** `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/imp_skill_slots.lua:677-708`

```lua
local combo_skill_ids = cur_skill:get_sys_d("skill_combo_ids", {})
-- Filter out last used combo to avoid repeats
if last_combo_id and len(combo_skill_ids) > 1 then
    combo_skill_ids = combo_skill_ids:filter(function(item)
        return item[1] ~= last_combo_id
    end)
end
-- Random selection from remaining options
local combo_id, _ = common_misc.randlist(combo_skill_ids)
-- Override by server cue if present
if self._cue_combo_skills:contains(skill_main_id) then
    combo_id = self._cue_combo_skills[skill_main_id]
end
```

**Why it matters:** Combo selection is: (1) random from `skill_combo_ids`, (2) avoids repeating the last combo, (3) can be overridden by server-side cue (`on_combo_skill_set` via string data `"base:target:1/0"`).

**Evidence Confidence:** 5/5

---

### E4: Slot Resolution with Combo Override

**Source:** `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/imp_skill_slots.lua:1498-1511, 842-867`

```lua
-- In skill_slot_update_active_skills:
local is_combo = slot_skill_util.GET_IS_CHANGED_BY_COMBO_SLOT(function_no)
if is_combo then
    local combo_skill_config = self._combo_skills_map:get(skill_no, nil)
    if combo_skill_config then
        local combo_skill_no = combo_skill_config:get("combo_skill_no")
        if combo_skill_no then
            self.slot_active_skills[slot_no] = combo_skill_no  -- OVERRIDE
        end
    end
end

-- _combo_skills_map is built from:
function slot_update_combo_skills_map()
    local skill_map = {}
    skill_map:update(self._cue_combos)    -- animation-triggered combos
    skill_map:update(self._time_combos)   -- timer-triggered combos
    self:set_combo_skill_map(skill_map)
end
```

**Why it matters:** The combo system works by *temporarily replacing* the skill on a slot. When a combo is active, `slot_active_skills[slot_no]` points to the combo skill instead of the base skill. This is what makes pressing the same button execute the next move in the chain.

**Evidence Confidence:** 5/5

---

### E5: Skill Data Structure (skills.json)

**Source:** `Scripts/data/DirObject/DirObject_Cache/hexm.client.data_oversea.skills.json` (lines ~1826-1857)

```json
{
    "skill_combo_mode": 1,
    "skill_combo_assist": 4,
    "skill_combo_ids": [[20602133913, 1]],
    "skill_combo_info": [2, 1],
    "skill_combo_charge_id": 20603005911,
    "skill_main_id": 20602103913,
    "skill_class": 109,
    "skill_kongfu": [20602],
    "skill_interrupt_lowpriority_nocombo": [3],
    "skill_interrupt_lowpriority_combo": [3]
}
```

Key fields:
- **`skill_main_id`**: The "root" skill ID. All combo variants share the same `skill_main_id`.
- **`skill_combo_ids`**: Array of `[next_skill_id, weight]` pairs for combo transitions.
- **`skill_combo_mode`**: 0 = no time combo, 1 = standard timer, 2 = persistent display.
- **`skill_combo_window`**: Duration (seconds) of the time combo window.
- **`skill_combo_info`**: `[total_steps, current_step]` — position in the combo chain.
- **`skill_combo_charge_id`**: Hold-to-charge variant of this combo step.
- **`skill_kongfu`**: Array of kongfu IDs this skill belongs to.
- **`skill_class`**: Type enum (101=Normal/Light, 102=Heavy, 103=TuBreak, 104=Xuli/Charge, etc.)

**Evidence Confidence:** 5/5

---

### E6: Kongfu ↔ Skill Slot Mapping

**Source:** `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/imp_skill_slots.lua:968-994`

```lua
function PlayerAvatarMember:get_now_active_kongfu()
    local active_main = self._client_active_main or self:get_server_entity().kongfu.active_main
    if 1 == active_main then
        return self:get_server_entity().kongfu.kongfu_main
    else
        return self:get_server_entity().kongfu.kongfu_sub
    end
end
```

**Source:** `imp_skill_slots.lua:1487-1491`
```lua
local kongfu_id = self:get_server_entity().skill_slot.gameplay_slots_kongfu:get(slot_no)
if kongfu_id and kongfu_id ~= self:get_now_active_kongfu() then
    -- Skip this gameplay slot — it belongs to the inactive kongfu
end
```

**Why it matters:** Players equip two kongfu (main + sub). Only the active kongfu's skills appear in slots. Each slot can be bound to a specific kongfu, and the slot resolution filters by active kongfu.

**Evidence Confidence:** 5/5

---

### E7: Auto-Combo on Hold (Setting)

**Source:** `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/skill/models/common/normal_skill_model.lua:89-104`

```lua
function NormalSkillModel:handle_auto_combo()
    if not bool(G.setting_manager:get_setting_cache(setting_config.SETTING_HOLD_AUTO_COMBO)) then
        return
    end
    local skill_id = self:get_slot_skill_no()
    local skill_tb = G.datam.skills:get(skill_id)
    local skill_main_id = skill_tb:get("skill_main_id")
    if not skill_main_id then return end
    local main_skill_tb = G.datam.skills:get(skill_main_id)
    if main_skill_tb:get("skill_touch_type") == skill_consts.SKILL_TOUCH_TYPE_XULI then
        return  -- Don't auto-combo charge skills
    end
    G.main_player:skill_panel_click(self.index)
end
```

**Setting key:** `"hold_to_autocombo"` (setting_config.lua:120)

**Why it matters:** The game has a built-in "hold to auto combo" setting. When enabled and button is held, `on_skill_movepost_event` calls `handle_auto_combo()` which re-clicks the slot, causing the next combo skill (now loaded in the slot via `_combo_skills_map`) to fire automatically.

**Evidence Confidence:** 5/5

---

### E8: Skill Execution Path

**Source:** `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/imp_skill_panel.lua:67-74, 84-122`

```lua
function PlayerAvatarMember:skill_panel_click(slot_idx, skill_no, force_background)
    local skill_no = skill_no or self:skill_panel_get_skill_no(slot_idx, true)
    if not self:is_skill_xuli_type(skill_no) then
        return self:skill_panel_try_start_skill(slot_idx, nil, nil, skill_no, force_background)
    end
end

function PlayerAvatarMember:skill_panel_try_start_skill(slot_idx, ...)
    -- Builds params with slot_id, skill_id, from_ui_click
    local ret = self:use_slot_skill(slot_idx, params)
    return ret
end
```

`skill_panel_get_skill_no` → `get_skill_no_by_slot` → reads `slot_active_skills[slot]` (which may already be the combo skill).

**Evidence Confidence:** 5/5

---

### E9: Skill Class Enum (Important for Combo Logic)

**Source:** `Scripts/source_decompiled/hexm/common/consts/skill_consts.lua:501-530`

```lua
SKILL_CLASS_NORMAL = 101   -- Normal attack (resets combo)
SKILL_CLASS_QING   = 101   -- Light attack
SKILL_CLASS_ZHONG  = 102   -- Heavy attack
SKILL_CLASS_TU     = 103   -- Break attack
SKILL_CLASS_XULI   = 104   -- Charge attack
SKILL_CLASS_QISHEN = 105   -- Qi skill
SKILL_CLASS_PARRY  = 14    -- Parry
SKILL_CLASS_EVADE  = 13    -- Dodge
SKILL_CLASS_WEAPON = 15    -- Weapon skill
SKILL_CLASS_FANJI  = 17    -- Counter-attack
SKILL_CLASS_ZHANSHA = 18   -- Execution/Finisher
```

**Why it matters:** `SKILL_CLASS_NORMAL` (101) triggers `skill_manager_handle_combo_end` — normal attacks RESET the combo chain. Only non-normal skills with `skill_main_id` can participate in combos.

**Evidence Confidence:** 5/5

---

## Conclusions (Score ≥ 3)

### C1: Combo Chain Architecture
A combo chain is a sequence of skills sharing the same `skill_main_id`. Each step has `skill_combo_ids` pointing to the next possible steps. The combo system temporarily replaces the slot's active skill with the next combo skill via `_combo_skills_map`. Pressing the same button executes the chain.

### C2: Two Trigger Mechanisms
- **Cue Combo**: Animation-event driven (`COMBO_START` state). The animation timeline fires a combo event at a specific frame.
- **Time Combo**: Timer-based. After skill starts, a window (`skill_combo_window` seconds) opens during which the next combo can be triggered.

### C3: Combo Selection
Next combo is randomly chosen from `skill_combo_ids` (weighted), avoiding the last-used combo. Server can override via `on_combo_skill_set`.

### C4: Auto-Combo Exists Natively
The game has a `"hold_to_autocombo"` setting. When held, the `on_skill_movepost_event` re-clicks the slot, which fires the next combo automatically. This only works for non-charge (non-xuli) skills.

### C5: Kongfu Determines Available Skills
Two kongfu are equipped (main + sub). Only the active kongfu's skills populate slots. Skills declare their kongfu via `skill_kongfu` array. Switching kongfu changes the entire skill loadout.

### C6: Full Combo Flow
```
Player presses slot button
  → get_skill_no_by_slot(slot_idx) → slot_active_skills[idx]
  → use_slot_skill() → skill_driver starts skill
  → Animation plays → hits COMBO_START frame → combo_state = "COMBO_START"
  → skill_manager_handle_combo_start()
    → reads skill_combo_ids from current skill
    → picks random combo_id
    → _combo_skills_map[skill_main_id] = {combo_skill_no, slot_no}
    → slot_update_combo_skills_map() → slot_active_skills[slot] NOW = combo_skill
  → UI updates to show combo skill icon
  → Player presses same button again → fires combo skill
  → On skill_end or normal_attack → combo_state reset → slot reverts
```

---

## Unknown / Requires Further Investigation

1. **Combo interrupt priorities**: `skill_interrupt_lowpriority_combo` vs `skill_interrupt_lowpriority_nocombo` — exact behavior unclear (how combo vs non-combo interrupts differ).
2. **`skill_combo_assist`**: Referenced in data but not found in code logic — may control aim assist strength during combo.
3. **Sensor skill interaction with combos**: Sensor skills (conditional skill replacements) interact with combo resolution but the priority order is complex.
4. **Full kongfu → skill_slot_mode mapping**: How `get_kongfu_slot(kongfu_id)` resolves to specific `skill_slot_mode` IDs.

---

## Implementation Plan: Auto Skill Combo

### Goal
Build a `Scripts/actions/auto_combo.lua` module that automatically executes optimal combo chains based on the player's active kongfu and equipped skills.

### Design

```
┌──────────────────────────────┐
│     auto_combo.lua           │
├──────────────────────────────┤
│ 1. Read active kongfu        │
│ 2. Read slot_active_skills   │
│ 3. Build combo chain map     │
│    per skill_main_id         │
│ 4. On enable:                │
│    - Hook on_skill_combo_start│
│    - Hook on_skill_movepost  │
│    - Auto-click next combo   │
│ 5. Respect skill_combo_window│
│ 6. Skip xuli (charge) skills │
│ 7. Handle combo_end reset    │
└──────────────────────────────┘
```

### Key Implementation Steps

1. **Read Current Loadout**
   - `G.main_player:get_now_active_kongfu()` → active kongfu ID
   - `G.main_player.slot_active_skills` → current slot→skill mapping
   - `G.datam.skills:get(skill_id)` → skill data with combo info

2. **Build Combo Chain Graph**
   - For each slotted skill, follow `skill_main_id` → `skill_combo_ids` chain
   - Build: `{skill_main_id → [step1_id, step2_id, ..., stepN_id]}`

3. **Hook Combo Events**
   - Listen on `G.main_player.dispatcher` for:
     - `E_SKILL_COMBO_START` — cue combo ready
     - `E_SKILL_START` — time combo check
     - `E_SKILL_END` — chain complete/reset
   - On combo ready: call `G.main_player:skill_panel_click(slot_idx)`

4. **Timing**
   - For cue combos: fire immediately on `COMBO_START` state
   - For time combos: fire within `skill_combo_window` duration
   - Small delay (~0.05s) to avoid frame-perfect issues

5. **Safety**
   - Check `skill_ctrl.combo_state == "COMBO_START"` before acting
   - Skip `SKILL_TOUCH_TYPE_XULI` (charge skills)
   - Disable during parry/evade states
   - Toggle on/off via menu

### Integration
- Add to `Scripts/actions/auto_combo.lua`
- Register in `ui/menu_config.lua` under Combat tab
- Use same Hooks/Reg/Logger framework as other actions
