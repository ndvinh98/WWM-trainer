# Question / Scope

How are player Inner Ways / Inner Arts (`xinfa`) activated, and can they be activated automatically from the player's equipped Martial Arts (`kongfu`)?

## Evidence

### 1. Passive xinfa activation is driven by the current xinfa plan's `passive_slots`
- Source: `Scripts/source_decompiled/hexm/common/property_define/avatar/xinfa.lua`
- Excerpt:
```lua
function XinfaInfo:passive_xinfas()
	local plan = self:cur_plan()
	if plan then
		return plan.passive_slots
	end
end
```
- Why it matters: Runtime consumers read equipped passive xinfa from `plan.passive_slots`, not from equipped `kongfu`.
- Evidence Confidence: 5/5

### 2. Saving/equipping xinfa is an explicit slot operation, not an automatic wuxue hook
- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/imp_xinfa.lua`
- Excerpt:
```lua
function Xinfa:save_equip_xinfa(active_xinfa, passive_xinfa)
	local se = self:get_server_entity()
	if not se then
		return
	end
	se.server:save_equip_xinfa(active_xinfa, passive_xinfa)
```
- Why it matters: The player path that changes equipped xinfa is an explicit `save_equip_xinfa(...)` RPC using slot arrays.
- Evidence Confidence: 5/5

### 3. Server-side xinfa equip validation does not check current martial arts, weapon, or liupai
- Source: `Scripts/source_decompiled/hexm/common/base/ai_avatar/xinfa_base.lua`
- Excerpt:
```lua
function Xinfa:_check_equip_xinfa(xinfa_id, slot_id, slots, skip_check_battle)
	local xinfa = self:get_xinfa(xinfa_id)
	if not xinfa then
		return errcode.ERR_XINFA_EQUIP_NOT_STUDY
	end
	if not xinfa:is_complete() then
		return errcode.ERR_XINFA_EQUIP_NOT_STUDY
	end
	local xinfa_d = xinfa:sysd()
	if xinfa_d:get("type") == xinfa_consts.XINFA_TYPE_ACTIVE then
		return errcode.ERR_XINFA_EQUIP_SLOT_LOCKED
	end
	local unlock_lv = G.datam.xinfa_params[1]:get("pass_slot_unlock_lv")
```
- Why it matters: Equip checks cover ownership/completion, battle lock, xinfa type, valid slot, and player level. There is no `kongfu`, `weapon_type`, or `liupai_id` match check here.
- Evidence Confidence: 5/5

### 4. Equipping xinfa directly adds its passive skill and recalculates active xinfa effects from `passive_slots`
- Source: `Scripts/source_decompiled/hexm/common/base/ai_avatar/xinfa_base.lua`
- Excerpt:
```lua
passive_slots:assign(passive_xinfa)
self:_disable_xinfa_skills(un_eq)
self:_enable_xinfa_skills(eq)
update_active_xinfa_effects(self)
```
```lua
function Xinfa:_enable_xinfa_skills(x_list)
	...
	local skill_id = xinfa:passive_skill()
	if skill_id then
		self.skill_ctrl:add_passive_skill(skill_id, {
			["level"] = xinfa.level,
		})
	end
```
```lua
local x_list = plan.passive_slots:tolist()
for _, xid in pairs(x_list) do
	local data = aiavt:get_xinfa(xid)
```
- Why it matters: Activation happens when xinfa IDs are present in `passive_slots`; that immediately enables their passive skills and recalculates xinfa-derived attributes.
- Evidence Confidence: 5/5

### 5. Combat/runtime systems consume equipped passive xinfa directly
- Source: `Scripts/source_decompiled/hexm/common/combat/skill_logics/fanji_skill.lua`
- Excerpt:
```lua
local passive = ent.xinfa:passive_xinfas()
if passive and passive:contains(401) then
	return false
end
```
- Why it matters: Combat logic checks membership in equipped passive xinfa slots directly. This confirms `passive_slots` is the activation source used by gameplay code.
- Evidence Confidence: 4/5

### 6. Wuxue-to-xinfa relationship exists in data and recommendation logic
- Source: `Scripts/source_decompiled/hexm/common/misc/combat_plan_misc.lua`
- Excerpt:
```lua
if 0 ~= main_wx then
	local target_lst = G.datam.xinfa_wuxue:get(main_wx, {})
	target_lst = _M._recommend_xf_sort(avt, target_lst)
	xf_lst:extend(target_lst)
end
if num > #xf_lst and 0 ~= sub_wx then
	local target_lst = G.datam.xinfa_wuxue:get(sub_wx, {})
	target_lst = _M._recommend_xf_sort(avt, target_lst)
	xf_lst:extend(target_lst)
end
...
local target_lst = liupai_data:get(main_liupai, {})
```
- Why it matters: The game does have explicit logic that derives recommended xinfa from equipped main/sub wuxue first, then same-`liupai` xinfa, then generic `liupai 0` xinfa.
- Evidence Confidence: 5/5

### 7. Example data mapping: wuxue `10101` maps to xinfa `154`, and both share `liupai_id = 6`
- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.xinfa_wuxue.json`
- Excerpt:
```json
[
  10101,
  [
    154
  ]
]
```
- Why it matters: This is a direct wuxue -> xinfa mapping entry.
- Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.xinfa.json`
- Excerpt:
```json
"id": 154,
"liupai_id": 6,
"passive_skill_id": 21541,
"related_wuxue_id": 10101,
```
- Why it matters: Xinfa `154` explicitly records both its passive skill and its related wuxue.
- Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.kongfu.json`
- Excerpt:
```json
"kongfu_type": 1,
"liupai_id": 6,
"passive_skill_id": 7011,
```
- Why it matters: The related wuxue entry shares the same `liupai_id`, matching the recommendation logic.
- Evidence Confidence: 4/5

### 8. Passive xinfa slot count is level-gated
- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.xinfa_params.json`
- Excerpt:
```json
"pass_slot_unlock_lv": [
  1,
  21,
  31,
  41
]
```
- Why it matters: Even if you derive all matching xinfa from wuxue, only up to the unlocked passive slot count can be activated through the normal player plan.
- Evidence Confidence: 5/5

## Conclusions

- Player Inner Ways / Inner Arts (`xinfa`) are activated by being equipped into `avatar.xinfa:cur_plan().passive_slots`, then saved through `save_equip_xinfa(...)`. Evidence Confidence: 5/5
- Equipped Martial Arts (`kongfu`) do not automatically activate matching xinfa in the runtime equip path. The xinfa equip validator has no check for current `kongfu`, `weapon_type`, or `liupai_id`; activation still requires explicit slot assignment. Evidence Confidence: 5/5
- The game does maintain wuxue -> xinfa and liupai -> xinfa recommendation data. `combat_plan_misc.recommend_kf_equip_xf(...)` builds a recommended xinfa list from equipped main/sub wuxue first, then same-liupai xinfa, then generic liupai `0` xinfa. Evidence Confidence: 5/5
- A practical "activate all innerways by equipped Martial Arts" implementation should therefore:
  1. Read `avt.kongfu.kongfu_main` and `avt.kongfu.kongfu_sub`.
  2. Build candidate xinfa from `G.datam.xinfa_wuxue` for each equipped wuxue.
  3. If slots remain, append same-`liupai_id` xinfa from `G.datam.liupai_xinfa`.
  4. If slots still remain, append generic `liupai 0` xinfa.
  5. Deduplicate, trim to unlocked passive slot count, then call `save_equip_xinfa(active_xinfa, passive_xinfa)`.
  Evidence Confidence: 4/5

## Unknown / Missing Evidence

- Not found in current investigation scope - requires broader review: the authoritative server RPC implementation behind `se.server:save_equip_xinfa(...)` is not present in the current Lua scope, so the network stub target itself was not inspected.
- Not found in current investigation scope - requires broader review: no code path was found that automatically consumes `recommend_kf_equip_xf(...).xf` and writes it into player xinfa slots.

## Next Scoped Search Steps

1. Inspect any available server-side RPC implementation for `save_equip_xinfa` if that source becomes available.
2. Trace UI/controllers that present combat-plan recommendations to see whether `recommend_kf_equip_xf(...).xf` is surfaced to the user anywhere.
3. If you want this behavior implemented, patch the player-side flow to derive passive xinfa from current `kongfu_main` / `kongfu_sub` and call `save_equip_xinfa(...)` with the computed slot list.
