# Question / Scope

How can a charge skill be made to fire immediately, based on authoritative runtime code in `Scripts/source_decompiled` and one concrete charge-skill config/actionline example from `Scripts/data/DirObject`?

# Evidence

## E1
- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/imp_skill_panel.lua`
- Excerpt:
```lua
function PlayerAvatarMember:skill_panel_click_began(slot_idx, skill_no)
    ...
    if self:is_skill_xuli_type(skill_no) then
        succ = self:skill_panel_try_start_skill(slot_idx, nil, nil, skill_no)
        G.gui_dispatcher:dispatch(event_consts.E_SKILL_PANEL_CHANGE_BAN, { ["is_ban"] = true })
    end
```
```lua
function PlayerAvatarMember:skill_panel_click_ended(slot_idx, skill_no)
    ...
    if self:is_skill_xuli_type(skill_no) then
        self.dispatcher:dispatch(event_consts.E_SKILL_XULI_CLICK_END, { ["skill_id"] = skill_no })
```
```lua
function PlayerAvatarMember:skill_panel_click(slot_idx, skill_no, force_background)
    ...
    if not self:is_skill_xuli_type(skill_no) then
        return self:skill_panel_try_start_skill(slot_idx, nil, nil, skill_no, force_background)
    end
end
```
- Why it matters: charge (`xuli`) skills are a two-phase input path. They start on `click_began`, and release is driven by a later `E_SKILL_XULI_CLICK_END`. A plain `skill_panel_click()` intentionally does not fire xuli skills.
- Evidence Confidence: 5/5

## E2
- Source: `Scripts/source_decompiled/hexm/client/combat/skill_ctrl.lua`
- Excerpt:
```lua
self.dispatcher:add_by_cbname_keep_sticky(events.E_SKILL_XULI_CLICK_END, self, "on_charge_end")
```
```lua
function PAvtSkillCtrl:on_charge_end(event, data)
    local skill = self.entity.skill_driver.cur_skill
    ...
    if skill and skill.skill_id == data.skill_id then
        self.entity.skill_driver.charge_end_time = DateTimeManager:now()
        self.entity.dispatcher:dispatch(events.E_SKILL_CHARGE_END, {
            ["skill_id"] = data.skill_id,
        })
    end
end
```
- Why it matters: the actual charge-release latch is `on_charge_end()`. When release is signaled, the controller stamps `charge_end_time` and emits `E_SKILL_CHARGE_END`.
- Evidence Confidence: 5/5

## E3
- Source: `Scripts/source_decompiled/hexm/common/actionline/nodes/action_nodes.lua`
- Excerpt:
```lua
local charge_end_ts = entity.skill_driver.charge_end_time or context.charge_end_time
if charge_end_ts then
    charge_time = math.max(0.06, charge_end_ts - DateTimeManager:now())
    delay = charge_time
    timeout = 0
else
    local ev = events[self.end_event] or self.end_event
    self.lis = helper.add_listener(entity.dispatcher, ev, function(e, d)
        if not skill or skill.skill_id == d.skill_id then
            self:reboot(graph, { ["es_id"] = es_id })
        end
    end)
end
```
```lua
context.charge_dur = charge_time
...
graph:finish_node(self, {
    __out__ = 1,
    timeout = timeout,
    charge_lv = charge_lv,
})
```
- Why it matters: `ChargeNode` waits for `E_SKILL_CHARGE_END` unless `charge_end_time` is already set. If release is forced immediately, the node exits almost immediately and records a very small `charge_dur`.
- Evidence Confidence: 5/5

## E4
- Source: `Scripts/source_decompiled/hexm/common/actionline/nodes/logic_nodes.lua`
- Excerpt:
```lua
local dur = context.charge_dur or -1
local factor = 1.0
if dur > 0 then
    local charge_list = skill:get_sys_d("skill_segment_duration_jmparam")
    if charge_list then
        for i = #charge_list, 1, -1 do
            if dur > charge_list[i][1] then
                factor = charge_list[i][2]
                break
            end
        end
    end
end
context.skill_factor = factor
```
- Why it matters: some skills can scale their damage/effect from `charge_dur`. "Immediate fire" may therefore change gameplay output, not just responsiveness.
- Evidence Confidence: 4/5

## E5
- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/skill/models/common/normal_skill_model.lua`
- Excerpt:
```lua
if self.skill_xuli_holdpost_ts then
    if self.skill_xuli_holdpost_ts < self.in_click_ts then
        return
    end
else
    if G.DateTimeManager:now() - self.in_click_ts < 0.2 then
        return
    end
end
...
self.click_skill_no = charge_skill_id
G.main_player:skill_panel_click_began(self.index, self.click_skill_no)
```
```lua
if main_skill_tb:get("skill_touch_type") == skill_consts.SKILL_TOUCH_TYPE_XULI then
    return
end
```
- Why it matters: combo-to-charge conversion is separate from charge release. If a normal combo step has `skill_combo_charge_id`, the model waits for `holdpost` or `0.2s` before switching into the charge skill. Also, built-in hold auto-combo explicitly skips xuli skills.
- Evidence Confidence: 5/5

## E6
- Source: `Scripts/data/DirObject/DirObject_Cache/hexm.client.data_oversea.skills.json`
- Excerpt:
```json
[
    20103005,
    {
        "skill_combo_charge_id": 20103005,
        "skill_touch_type": 1,
        "skill_main_id": 20103005,
        "attackline": "20103005"
    }
]
```
- Why it matters: `20103005` is a concrete charge skill in data. It is marked xuli (`skill_touch_type = 1`) and links to attackline `20103005`.
- Evidence Confidence: 5/5

## E7
- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.AL.skill.qiang_20103.json`
- Excerpt:
```json
{
  "NodeID": 28,
  "Type": "ChargeNode",
  "Data": {
    "end_event": "E_SKILL_CHARGE_END",
    "max_time": 0.3,
    "show_bar": false
  }
}
```
- Why it matters: the concrete charge skill above really does run through a `ChargeNode` that ends on `E_SKILL_CHARGE_END`. This confirms the generic engine path is active for at least one real skill.
- Evidence Confidence: 5/5

## E8
- Source: `Scripts/source_decompiled/hexm/client/manager/input/input_function_handler.lua`, `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/skill/managers/skill_input.lua`, `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/skill/models/model_base.lua`
- Excerpt:
```lua
function InputFunctionHandler:_play_skill_by_slot(slot, raw_input, func_info, proxy_input)
    ...
    if raw_input then
        down = raw_input:get("key_state") == keyboard_consts.STATE_DOWN
    end
    ...
    ret = G.main_player:get_skill_manager():handle_skill_input(slot, down, trigger)
```
```lua
function SkillMember:handle_skill_input(ui_slot_idx, down, trigger)
    ...
    ret = handler:trigger_input_action(down)
```
```lua
function ModelBase:trigger_input_action(is_down)
    ...
    if self:is_trigger_click_on_input_down() then
        if is_down then
            self:trigger_start()
            ...
        else
            ...
            self:trigger_end()
        end
        return true
    end
```
- Why it matters: on PC, a held skill hotkey is not special-cased. Key-down and key-up are forwarded into the slot model, which then calls the same charge start/end flow analyzed above.
- Evidence Confidence: 5/5

## E9
- Source: `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.windows_key_map_config.json`, `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.input_func_config.json`
- Excerpt:
```json
[
    101,
    {
        "key_id": "KEY_R",
        "map_id": 101,
        "input_func_id": 12
    }
]
```
```json
[
    12,
    {
        "play_skill_by_slot": 2,
        "input_func_id": 12
    }
]
```
- Why it matters: in the default PC keymap of this data set, `R` is bound to slot `2`. Holding `R` therefore drives slot 2 through `_play_skill_by_slot()` and into the slot model's start/end path.
- Evidence Confidence: 5/5

# Conclusions

1. A charge skill does not "fire on click" in the normal path. It starts on `skill_panel_click_began()` and only exits charge when `E_SKILL_XULI_CLICK_END -> on_charge_end() -> E_SKILL_CHARGE_END` runs. Evidence Confidence: 5/5.
2. If the goal is immediate release of an already-started charge skill, the cleanest runtime hook is to trigger the release signal immediately after successful xuli start, not to change `skill_touch_type`. Evidence Confidence: 5/5.
3. Changing `skill_touch_type` from xuli to non-xuli is not sufficient by itself. The normal click path skips xuli-specific release handling, while the actionline still waits on `E_SKILL_CHARGE_END` or timeout. Evidence Confidence: 5/5.
4. If the goal is immediate combo-charge activation, the relevant gate is different: `NormalSkillModel:handle_combo_charge()` enforces `holdpost` or a `0.2s` hold before it swaps to `skill_combo_charge_id`. Evidence Confidence: 5/5.
5. Immediate release can change gameplay output because `ChargeNode` records a small `charge_dur`, and downstream logic can convert that into lower `skill_factor`. Evidence Confidence: 4/5.
6. For the user's PC-keyboard context, holding `R` is just the slot-2 version of the same flow. `KEY_R -> input_func_id 12 -> play_skill_by_slot 2 -> handle_skill_input(slot=2, down/up) -> trigger_start()/trigger_end()`. Evidence Confidence: 5/5.

# Unknown / Missing Evidence

1. Per-skill actionline branching still needs targeted review before patching a specific skill globally. Some skills may branch differently on `timeout` versus normal release.
2. Not every charge skill is proven to consume `charge_dur` for damage/effect. The mechanism exists, but each target skill should be checked individually.

# Next Scoped Search Steps

1. Pick the exact skill ID you want to change and inspect its `attackline` graph in `Scripts/data/DirObject/GreyTableInfo/*.json` for `ChargeNode` connections and `timeout` branches.
2. If you want a client-side patch, verify the least invasive hook:
   - `skill_panel_click_began()` immediate release for xuli skills, or
   - `on_skill_start_event()` / `on_charge_end()` allowlist logic for selected skill IDs.
3. If the actual goal is "enter charge mode immediately from a combo step," inspect that skill's `skill_combo_charge_id` path and the `NormalSkillModel:handle_combo_charge()` threshold behavior instead of the release path.
