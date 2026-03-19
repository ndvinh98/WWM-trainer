# 3700608 Silent Destroy Analysis

## 1. Question / Scope

Research how to destroy/interact with entity `3700608` silently through direct game API, without normal touch / play-skill interaction, using:

- `RESEARCH.md`
- authoritative code under `Scripts/source_decompiled/`
- authoritative data under `Scripts/data/DirObject/`
- trace capture under `Scripts/traces/`

## 2. Evidence

### Evidence A: `3700608` is a destructible interact entity whose HP/break resource is `10013`

Source:
`Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.entity_value.json`

Excerpt:
- `3700608`
- `"wanfa_resource_list": [10013001]`
- `"posui_resource_id": 10013`
- `"hp_resource_id": 10013`

Why it matters:
- `3700608` is not using an arbitrary destroy path here.
- Its break / HP path is explicitly wired to wanfa resource `10013`.

Evidence Confidence: 5/5

### Evidence B: the concrete resource config for `10013001` is `resource_id=10013`, default `100`, min `0`

Source:
`Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.combat_resource_config.json`

Excerpt:
- `10013001`
- `"resource_id": 10013`
- `"resource_default": 100`
- `"resource_min": 0`

Why it matters:
- A direct resource mutation that drives `10013` from `100` to `0` is sufficient to trigger break logic.
- `-100` is the clean exact destroy delta for this resource.

Evidence Confidence: 5/5

### Evidence C: latest traces contain live `3700608` runtime entities, identified as interact-comp entities with serial ids

Source:
`Scripts/traces/hexm/client/ui/windows/world_event/session_20260318_155718/world_event_listen_window_anon_155718_044.json`

Excerpt:
- `self=<instof InteractComEntity ...>(sid.1632320050)(No.3700608)`
- `self=<instof InteractComEntity ...>(sid.1632320048)(No.3700608)`
- `self=<instof InteractComEntity ...>(sid.1632320051)(No.3700608)`

Why it matters:
- This confirms the exact runtime form of `3700608` in the current trace session.
- The target is an `InteractComEntity`, not a separate special-case class.

Evidence Confidence: 5/5

### Evidence D: the normal damage path for the same destructible class family routes through `InteractDataManager():do_damage_to_entities_wanfa_resource(...)`

Source:
`Scripts/traces/hexm/client/entities/local/common_members/session_20260318_155718/charctrl_base_anon_155721_978.json`

Excerpt:
- `self=<instof InteractComEntity ...>(sid.1632320035)(No.3700607), res_id=10013`
- `entity_id_list %s [ins_entity1632320035_interact_comp]`
- `do_damage_to_entities_wanfa_resource`
- `res2dmg={10020: -20, 10013: -100}`

Why it matters:
- The traced gameplay hit does not call `interactcom_destroy(...)` first.
- It first converts the target into an interact-comp eid and sends resource damage through `InteractDataManager`.
- The sibling entity `3700607` has the same entity/value shape as `3700608` in `entity.json` and `entity_value.json`, so this is the strongest current traced analogue.

Evidence Confidence: 4/5

### Evidence E: client-side resource damage on interact comps removes the comp silently when the resource reaches the broken state

Source:
`Scripts/source_decompiled/hexm/common/base/interact_comp/interact_data_manager_members/imp_wanfa_resource/client_wanfa_resource_base.lua`

Excerpt:
- `function ClientWanfaResourceBase:do_damage_to_entities_wanfa_resource(...)`
- `local interact_comp = self:get_interact_comp(entity_id)`
- `self:change_client_interact_wanfa_resource(interact_comp, res2dmg, kwargs)`
- `if is_cause_broken then`
- `interact_comp.destroy_reason = entity_consts.DESTROY_REASON_RESOURCE_CHANGE`
- `self:remove_interact_comp(interact_comp.comp_eid)`

Why it matters:
- This is the direct decompiled proof that the manager path performs a silent local break/removal.
- No touch / active-interact / play-skill call is required on this path.

Evidence Confidence: 5/5

### Evidence F: interact-comp eid for ins entities is derived as `ins_entity<serial_id>_interact_comp`

Sources:
- `Scripts/source_decompiled/hexm/common/misc/interact_misc.lua`
- `Scripts/source_decompiled/hexm/common/consts/interact_component_consts.lua`

Excerpt:
- `return it[2] .. serial_id .. interact_component_consts.COMP_EID_POSTFIX`
- `COMP_TYPE_INS_ENTITY_PREFIX = "ins_entity"`
- `COMP_EID_POSTFIX = "_interact_comp"`

Why it matters:
- Given a live `3700608` serial id from runtime, the direct API target eid is derivable.
- For example, serial `1632320050` maps to `ins_entity1632320050_interact_comp`.

Evidence Confidence: 5/5

### Evidence G: `G.space:interactcom_destroy(...)` is a blunt removal path, not the traced gameplay damage path

Source:
`Scripts/source_decompiled/hexm/client/entities/local/space_members/create_entity/imp_interactcom_entity.lua`

Excerpt:
- `function SpaceMember:interactcom_destroy(comp_eid, e, delay, fromid)`
- `self:_interactcom_destroy_comp(comp, fromid)`
- `return self:remove_interactcom(comp.comp_eid, true)`

Why it matters:
- This API can delete the interact comp directly.
- But it bypasses the traced wanfa-resource reduction path, so it is less aligned with normal gameplay semantics than the manager damage API.

Evidence Confidence: 5/5

## 3. Conclusions

### Conclusion 1: The evidence-backed silent destroy path for `3700608` is wanfa-resource damage on its interact-comp eid, not active-interact or skill playback

Supported by:
- Evidence A
- Evidence B
- Evidence E
- Evidence F

Practical API shape:

```lua
local idm_mod = portable.safe_import("hexm.common.base.interact_comp.interact_data_manager")
local IDM = idm_mod and (idm_mod.InteractDataManagerInst or idm_mod.InteractDataManager)

local serial_id = target.serial_id
local comp_eid = "ins_entity" .. tostring(serial_id) .. "_interact_comp"

IDM:do_damage_to_entities_wanfa_resource(
	{ comp_eid },
	{ [10013] = -100 },
	{ creator_id = G.main_player_id or (G.main_player and G.main_player.entity_id) }
)
```

Why:
- `3700608` breaks on resource `10013`.
- `-100` matches the full default resource value.
- the decompiled client path removes the interact comp when broken.

Evidence Confidence: 5/5

### Conclusion 2: A lower-level equivalent exists if you already hold the interact comp object

Supported by:
- Evidence E

Practical API shape:

```lua
IDM:change_client_interact_wanfa_resource(
	interact_comp,
	{ [10013] = -100 },
	{ creator_id = G.main_player_id or (G.main_player and G.main_player.entity_id) }
)
```

Why:
- `do_damage_to_entities_wanfa_resource(...)` resolves the comp and then delegates into `change_client_interact_wanfa_resource(...)`.

Evidence Confidence: 5/5

### Conclusion 3: `G.space:interactcom_destroy(comp_eid, ...)` is possible but is a bypass path, not the best match for “destroy it like gameplay, but silently”

Supported by:
- Evidence G

Why:
- It directly removes the interact comp.
- It does not match the traced normal-hit route, which goes through resource damage first.

Evidence Confidence: 5/5

### Conclusion 4: `3700608` is very likely to use the same direct API destroy path as traced `3700607`

Supported by:
- Evidence A
- Evidence D

Why:
- `3700607` and `3700608` share the same authoritative destruct/value pattern:
  `value_id == id`, `entity_type = 3`, `base_tag = 31001`, `destroy_show_type = 6`, and the same `entity_value` resource setup using `10013001 -> resource_id 10013`.
- The traced sibling hit already shows the manager damage route on an `InteractComEntity`.

Evidence Confidence: 4/5

## 4. Unknown / Missing Evidence

- I did not find a trace in the current `Scripts/traces/` scope where the exact live `3700608` serials `1632320050`, `1632320048`, or `1632320051` flow into `do_damage_to_entities_wanfa_resource(...)`.
- Because of that, the exact “normal attack on `3700608`” call chain is not directly proven from traces in the current scope.
- The strongest available trace analogue is `3700607`, not `3700608`.

## 5. Next Scoped Search Steps

1. Capture one more trace session while attacking the exact `3700608` instance nearest the player.
2. Immediately grep the new session for one of:
   - `No.3700608`
   - the exact serial id
   - the derived comp eid `ins_entity<serial>_interact_comp`
3. Confirm whether that exact trace reaches:
   - `do_damage_to_entities_wanfa_resource(...)`
   - `change_client_interact_wanfa_resource(...)`
4. If needed, compare whether gameplay adds extra ignored damage keys besides `10013` like the traced sibling case did with `10020`.

## Practical Answer

Best evidence-backed silent destroy call for `3700608`:

```lua
local idm_mod = portable.safe_import("hexm.common.base.interact_comp.interact_data_manager")
local IDM = idm_mod and (idm_mod.InteractDataManagerInst or idm_mod.InteractDataManager)

local ent = target_3700608
local comp_eid = "ins_entity" .. tostring(ent.serial_id) .. "_interact_comp"

IDM:do_damage_to_entities_wanfa_resource(
	{ comp_eid },
	{ [10013] = -100 },
	{ creator_id = G.main_player_id or (G.main_player and G.main_player.entity_id) }
)
```

Fallback bypass call if you only want silent deletion and do not care about matching the traced gameplay path:

```lua
G.space:interactcom_destroy(comp_eid, G.space:get_entity(comp_eid), nil, G.main_player_id or "")
```
