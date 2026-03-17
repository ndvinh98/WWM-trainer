# Question / Scope

Analyze how buffs are handled in the game, using buff `21001002` from `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.buff.json` as the anchor example. Scope is limited to authoritative sources only:

- `Scripts/source_decompiled/`
- `Scripts/data/DirObject/`

# Evidence

## Evidence 1: Buff configs are turned into handlers by key presence

- Source: `Scripts/source_decompiled/hexm/common/combat/buff/factory.lua`
- Excerpt:
  - `function BuffHandlerFactory:get_sys_d(No) return G.datam.buff:get(No) or {} end`
  - `if it.should_enable(sys_d) then out_arr:append(it) end`
- Why it matters: a buff row is not interpreted by one monolithic function. The engine loads the buff config, then enables member handlers only for keys that exist on that config.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/combat/buff/members/import.lua`
- Excerpt:
  - `require("hexm.common.combat.buff.members.buff_attribute")`
  - `require("hexm.common.combat.buff.members.buff_passive")`
  - `require("hexm.common.combat.buff.members.buff_remove_by_sth").BuffHandlerMember`
- Why it matters: this shows the important subsystems that a buff can activate: direct attribute edits, passive trigger logic, removal ties to passive skills / martial arts, and many more.
- Evidence Confidence: 5/5

## Evidence 2: Buff instance lifecycle and stored runtime fields

- Source: `Scripts/source_decompiled/hexm/common/combat/buff/buff_comp.lua`
- Excerpt:
  - `local bdict = { ["ID"] = bid, ["No"] = buff_no, ["level"] = level, ["charge_level"] = charge_level, ["fromid"] = fromid, ["duration"] = duration, ["start_ts"] = start_ts, ["skill_id"] = skill_id, ["persistent"] = persistent }`
  - `local buff_handler = self:_add_buff_handler(buff, sys_d, true, kwargs)`
- Why it matters: when a buff is applied, the runtime instance stores ID, config No, level, charge, source entity, duration, start time, and skill source, then creates the handler bundle from config.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/property_define/common_prop/buff_item.lua`
- Excerpt:
  - `Property(BuffBase, "ID", "", _flag_db)`
  - `Property(BuffBase, "No", 0, _flag_db)`
  - `Property(BuffBase, "level", 1, _flag_db)`
  - `Property(BuffBase, "duration", 30.0, _flag_db)`
  - `Property(BuffBase, "charge_level", 1, _flag_db)`
  - `Property(BuffBase, "fromid", "", _flag_db)`
  - `Property(BuffBase, "skill_id", 0, _flag_db)`
- Why it matters: these are the concrete runtime fields available on every buff instance.
- Evidence Confidence: 5/5

## Evidence 3: `buff_attribute_type` and `buff_attribute_value` are zipped and applied to formula attributes

- Source: `Scripts/source_decompiled/hexm/common/combat/buff/members/buff_attribute.lua`
- Excerpt:
  - `local conf_attrs = self:get_sys_v("buff_attribute_type")`
  - `local conf_v = self:get_sys_v("buff_attribute_value")`
  - `self.comp:th_num_add(attr_k, attr_v, self.ID, "fcache")`
- Why it matters: the sample row's `CHU_DAMAGE_SCALE = -0.66000002622604` is applied directly as a formula attribute modifier while the buff exists.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/misc/buff_misc.lua`
- Excerpt:
  - `local param_keys = buff_data:get("buff_attribute_type", {})`
  - `local param_values = buff_data:get("buff_attribute_value", {})`
  - `buff_param[key] = param_values[idx]`
  - `return string.pformat(raw_buff_desc, nil, buff_param)`
- Why it matters: the same attribute pairs are also used to fill placeholders in `buff_detail` text.
- Evidence Confidence: 5/5

## Evidence 4: `CHU_DAMAGE_SCALE` is a real player attribute tied to a skill-class damage bucket

- Source: `Scripts/source_decompiled/hexm/common/property_define/avatar/attr.lua`
- Excerpt:
  - `Property(PlayerAttr, "CHU_DAMAGE_SCALE", 0.0, Property.OWN_CLIENT)`
- Why it matters: `CHU_DAMAGE_SCALE` is a first-class combat attribute, not a free-form string.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/combat/damage_judge_scale.lua`
- Excerpt:
  - `[skill_consts.SKILL_CLASS_ZHANSHA] = "CHU_DAMAGE_SCALE"`
- Why it matters: the attribute is used as the damage-scale modifier for the `SKILL_CLASS_ZHANSHA` damage class.
- Evidence Confidence: 4/5

## Evidence 5: `passive_effect` expands into buff passive IDs derived from the buff number

- Source: `Scripts/source_decompiled/hexm/common/combat/buff/members/buff_passive.lua`
- Excerpt:
  - `for _, passive_index in pairs(passive_effect) do`
  - `if passive_index < 10 then passive_id = self.No * 10 + int(passive_index) else passive_id = int(passive_index) end`
  - `if G.datam.buff_passive_data:get(passive_id) then buff_passive_misc.reg_passive_logic(self, passive_id) end`
- Why it matters: sample `passive_effect = [1, 2, 3]` becomes passive IDs `210010021`, `210010022`, and `210010023`.
- Evidence Confidence: 5/5

## Evidence 6: The three generated passive IDs for `21001002` have concrete triggers and effects

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.buff_passive_data.json`
- Excerpt:
  - `210010021 -> "effect_normal": [[116.0, 21001012.0]], "trigger": 112`
  - `210010022 -> "effect_normal": [[116.0, 21001012.0]], "trigger": 104`
  - `210010023 -> "cond_attack": [1, 0, 1], "effect_event": [[4.0, 21001012.0]], "trigger": 1`
- Why it matters: the sample buff is not just a flat stat modifier. It also installs three passive trigger rules that can apply buff `21001012`.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/consts/buff_passive_consts.lua`
- Excerpt:
  - `[1] = "adjust_params_out"`
  - `[104] = "parry"`
  - `[112] = "invincible"`
  - `[4] = "_effect_event_tg_get_buff"`
  - `[116] = "_effect_trigger_parry_extra"`
- Why it matters: this maps the passive config numbers to named trigger/effect handlers.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/misc/buff_passive_misc.lua`
- Excerpt:
  - `function _M._effect_event_tg_get_buff(...) _M._sub_effect_add_buff(buff, dd.target, buff_id, buff.owner.id, kwargs) end`
  - `function _M._effect_trigger_parry_extra(...) ... _M._sub_effect_add_buff(buff, target, buff_no, buff.owner.id) end`
- Why it matters: both sample passive effects explicitly add buff `21001012` to a target under their trigger conditions.
- Evidence Confidence: 5/5

## Evidence 7: `add_cd` mixes passive cooldown data with cooldown-clear flags

- Source: `Scripts/source_decompiled/hexm/common/misc/buff_misc.lua`
- Excerpt:
  - `local cd, max_cnt = G.datam.buff:get(buff_no, {}):get("add_cd", {}):unpack()`
- Why it matters: the first two positions in `add_cd` are treated as passive cooldown seconds and max trigger count.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/combat/buff/buff_dispel.lua`
- Excerpt:
  - `local add_cd = sysd and sysd:get("add_cd")`
  - `if event_type <= #add_cd then is_clear = 1 == add_cd[event_type] else is_clear = 1 == buff_consts.PASSIVE_CLEAR_DEFAULT:get(event_type) end`
- Why it matters: later positions in the same `add_cd` array are interpreted as event-specific clear flags for passive cooldown state.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/consts/buff_consts.lua`
- Excerpt:
  - `_M.PASSIVE_CLEAR_LEAVE_BATTLE = 3`
  - `_M.PASSIVE_CLEAR_DEAD = 4`
  - `_M.PASSIVE_CLEAR_TRANSFER = 5`
  - `_M.PASSIVE_CLEAR_LEAVE_SPACE = 6`
  - `_M.PASSIVE_CLEAR_RM_BUFF = 7`
- Why it matters: this gives the positional meaning of `add_cd[3+]`.
- Evidence Confidence: 5/5

## Evidence 8: `buff_destroy_owner` and `buff_destroy_fromer` are per-event survival flags

- Source: `Scripts/source_decompiled/hexm/common/combat/buff/members/buff_life.lua`
- Excerpt:
  - `_M.LIFE_ENTITY_EVENT = { events.D_DEAD, events.D_LEAVE_BATTLE, events.D_ON_LEAVE_SPACE }`
  - `conf_v = self.sys_d:get("buff_destroy_owner")`
  - `if 1 ~= is_on then self._dispatcher:add_by_cbname(e, self, "_life_on_destroy_event") end`
  - `conf_v = self.sys_d:get("buff_destroy_fromer")`
  - `if 1 ~= is_on then disp:add_by_cbname(events.cat_event(self.data.fromid, evt), self, "_life_on_destroy_event") end`
- Why it matters: the first three slots of the owner/fromer arrays control whether the buff is removed when owner or source dies, leaves battle, or leaves space.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/combat/buff/buff_funcs.lua`
- Excerpt:
  - `remove_dead_destroy_buffs -> conf_v[1]`
  - `_on_leave -> conf_v[3]`
  - `_on_lose -> conf_v[4]`
- Why it matters: owner index `1` is dead removal, owner index `3` is leave-space removal, and owner index `4` is another loss/persistence slot used elsewhere in buff lifecycle.
- Evidence Confidence: 4/5

- Source: `Scripts/source_decompiled/hexm/common/combat/buff/buff_comp.lua`
- Excerpt:
  - `local conf = sys_d:get("buff_destroy_owner")`
  - `persistent = conf and #conf >= 4 and conf[4] or 0`
- Why it matters: owner slot `4` also decides default persistence when explicit `buff_persistent` is absent.
- Evidence Confidence: 5/5

## Evidence 9: `buff_maxtime`, `buff_name`, `buff_detail`, `buff_estimate`, and `buff_show_flag` all feed runtime/UI behavior

- Source: `Scripts/source_decompiled/hexm/common/combat/buff/buff_funcs.lua`
- Excerpt:
  - `if nil == duration then duration = sys_d:get("buff_maxtime", 20) end`
- Why it matters: `buff_maxtime` is the default duration; `-1` means permanent / no natural expiry.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/combat/buff/members/buff_duration.lua`
- Excerpt:
  - `if duration >= 0 then self:add_k_callback(K_TMR, duration, 0, "_on_duration_end") end`
  - `_on_duration_end -> self.comp:remove_buffs({ self.data.ID }, "duration", buff_consts.RTYPE_TIME_END)`
- Why it matters: timed buffs schedule removal; permanent buffs do not.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/misc/buff_misc.lua`
- Excerpt:
  - `local raw_buff_desc = LOC(buff_data:get("buff_detail"))`
- Why it matters: `buff_detail` is a text-table ID, not literal text.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/ui/windows/buff/home_buff_float_window.lua`
- Excerpt:
  - `local buff_name = TextByTable(buff_sys_d, "buff_name", "")`
  - `local text_buff = TextByTable(buff_sys_d, "buff_detail") or ""`
- Why it matters: `buff_name` and `buff_detail` drive tooltip text.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/buff/buff.lua`
- Excerpt:
  - `function Buff:get_is_debuff() return 2 == self:get_sys_data():get("buff_estimate") end`
  - `function Buff:get_is_show() return 1 ~= self:get_sys_data():get("buff_show_flag", 0) end`
- Why it matters: UI uses `buff_estimate` as the debuff test, and `buff_show_flag == 1` is treated as not shown by standard icon filtering.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/ui/view/gen_view_extension/buff_icon_progress.lua`
- Excerpt:
  - `if 3 == buff_sys:get("buff_show_flag") then duration = -1 end`
- Why it matters: show flag `3` suppresses countdown/progress behavior.
- Evidence Confidence: 4/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/component/billboard_new/controllers/node_buffs.lua`
- Excerpt:
  - `if 4 == buff_show_flag then return self._owner.id == G.main_player_id or buff_item.fromer_id == G.main_player_id end`
- Why it matters: show flag `4` is a special display case tied to the main player relationship.
- Evidence Confidence: 4/5

## Evidence 10: `has_fake_need` affects client-side fake/local handling; `has_anti_need` is checked by anti-cleanup logic

- Source: `Scripts/source_decompiled/hexm/client/fake_server/entities/common_members/buff_base.lua`
- Excerpt:
  - `local function buff_need_fake_logic(sys_d) if sys_d:get("has_fake_need") then return true end`
- Why it matters: `has_fake_need` is an explicit switch for fake/local buff processing on the client side.
- Evidence Confidence: 4/5

- Source: `Scripts/source_decompiled/hexm/common/combat/buff/imp_buff.lua`
- Excerpt:
  - `if show_type == buff_consts.SHOW_SERVER_ONLY and ... and sys_d:get("has_fake_need") then show_type = buff_consts.SHOW_ALL_CLIENTS end`
- Why it matters: the flag also affects how a server buff is exposed to clients in single-player style cases.
- Evidence Confidence: 4/5

- Source: `Scripts/source_decompiled/hexm/common/combat/buff/imp_buff.lua`
- Excerpt:
  - `if it and it.sys_d:get("has_anti_need") then rm_buffs:append(it.ID) end`
- Why it matters: `has_anti_need` marks buffs that participate in `_buff_anti_on_check` cleanup.
- Evidence Confidence: 3/5

## Evidence 11: Sample downstream debuff `21001012` is a stacking debuff with threshold-triggered follow-up buffs

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.buff.json`
- Excerpt:
  - `21001012 -> "buff_sameadd_addelse": [[10,21001022,1,1,0],[18,21001032,1,1,0],[24,21001042,1,1,0],[30,21001052,1,1,0],[35,21001062,1,1,1]]`
  - `21001012 -> "buff_sameadd_max": 35`
- Why it matters: the sample buff's passive chain leads into a second buff that stacks up to 35 and spawns more buffs at thresholds.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/combat/buff/members/buff_sameadd_buff.lua`
- Excerpt:
  - `local need_charge, add_buff_no, add_charge, add_target, is_destroy_self = it:unpack()`
  - `if need_charge == curr_charge then self:add_buff_inherit(add_buff_no, nil, { ["add_charge"] = add_charge, ... }) end`
- Why it matters: this is the handler that consumes `buff_sameadd_addelse`.
- Evidence Confidence: 5/5

## Evidence 12: Xinfa / innerway systems connect to buffs through passive skills, and also add direct attributes without buffs

- Source: `Scripts/source_decompiled/hexm/common/base/ai_avatar/xinfa_base.lua`
- Excerpt:
  - `local skill_id = xinfa:passive_skill()`
  - `self.skill_ctrl:add_passive_skill(skill_id, { ["level"] = xinfa.level })`
  - `local passive_skills = G.datam.xinfa_passive_skills:get(xid)`
  - `self.skill_ctrl:del_passive_skill(sid)`
- Why it matters: equipping / unequipping Xinfa toggles passive skills.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/combat/skill_ctrl.lua`
- Excerpt:
  - `if 0 == sysd:get("condition", 0) then local buffs = sysd:get("buff_id")`
  - `self.entity:add_buff(bid, self.entity.id, { ["duration"] = -1, ["persistent"] = false, ["reason"] = "enable_passive_skill", ["ignore_dead"] = true })`
  - `self.entity:remove_buffs_by_No(buffs, self.entity.id, "passive_skill disable")`
- Why it matters: passive skills are one direct bridge from Xinfa into the buff system.
- Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.xinfa.json`
- Excerpt:
  - `154 -> "passive_skill_id": 21541`
- Why it matters: Xinfa data explicitly names the passive skill that will be enabled.
- Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.passive_skills.json`
- Excerpt:
  - `21541 -> "buff_id": [10215410, 10215411], "condition": 0, "wulin_type": "XINFA"`
- Why it matters: this confirms the data path Xinfa -> passive skill -> buff IDs.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/base/ai_avatar/xinfa_base.lua`
- Excerpt:
  - `update_xinfa_effects(...)`
  - `update_active_xinfa_effects(...)`
  - `aiavt.attr_formula:update_leaves(ks, vs)`
- Why it matters: Xinfa also changes combat attributes directly through `attr_formula`, without needing a buff row.
- Evidence Confidence: 5/5

## Evidence 13: Martial arts school and combat-plan systems connect to Xinfa selection

- Source: `Scripts/source_decompiled/hexm/common/misc/combat_plan_misc.lua`
- Excerpt:
  - `local target_lst = G.datam.xinfa_wuxue:get(main_wx, {})`
  - `local liupai_data = G.datam.liupai_xinfa`
  - `local target_lst = liupai_data:get(main_liupai, {})`
- Why it matters: martial arts (`wuxue`) and school/faction (`liupai`) data are used to recommend or select Xinfa, which can then feed passive skills and buffs.
- Evidence Confidence: 5/5

## Evidence 14: Buffs can be tied to passive-skill or martial-art removal

- Source: `Scripts/source_decompiled/hexm/common/combat/buff/members/buff_remove_by_sth.lua`
- Excerpt:
  - `return sysd:get("remove_kongfu_delete") or sysd:get("remove_passive_delete")`
  - `self.comp:th_dict_add(th_dict_key, th_map, self.ID, "oc_flags")`
- Why it matters: a buff can register itself to be deleted when particular passive skills or martial-arts IDs are removed.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/combat/buff/buff_comp.lua`
- Excerpt:
  - `function BuffCompCommon:remove_buffs_by_kongfu(kongfu_id)`
  - `function BuffCompCommon:remove_buffs_by_passive(ps_skill_id)`
- Why it matters: those registrations have concrete cleanup entry points.
- Evidence Confidence: 5/5

# Conclusions

1. Buff handling is data-driven and componentized. A buff row is loaded from `G.datam.buff`, then the handler factory enables member modules only for keys present on that row. Confidence: 5/5.

2. For sample buff `21001002`, the direct stat effect is:
   - `buff_attribute_type = ["CHU_DAMAGE_SCALE"]`
   - `buff_attribute_value = [-0.66000002622604]`
   This applies a `-0.66` modifier to `CHU_DAMAGE_SCALE`, which is the damage-scale attribute used for `SKILL_CLASS_ZHANSHA`. Confidence: 5/5 for the modifier application, 4/5 for the skill-class mapping label.

3. `passive_effect = [1,2,3]` on `21001002` expands to passive IDs `210010021`, `210010022`, `210010023`. Those passives register trigger logic from `buff_passive_data` and all three can add buff `21001012` to a target. Confidence: 5/5.

4. The sample's passive chain is:
   - `210010021`: trigger `112` (`invincible` / perfect-dodge path) -> effect `116` -> add `21001012`
   - `210010022`: trigger `104` (`parry`) -> effect `116` -> add `21001012`
   - `210010023`: trigger `1` (`adjust_params_out`) with `cond_attack = [1,0,1]` -> effect `4` -> add `21001012`
   Confidence: 5/5.

5. `21001012`, the downstream debuff created by the sample passives, is a stacking debuff. It can stack to `35`, and its `buff_sameadd_addelse` thresholds trigger extra follow-up buffs (`21001022`, `21001032`, `21001042`, `21001052`, `21001062`). Confidence: 5/5.

6. `add_cd` is a mixed-meaning array:
   - position `1`: passive cooldown seconds
   - position `2`: max trigger count inside that cooldown window
   - positions `3+`: clear-on-event flags keyed by passive-clear event IDs (`leave battle`, `dead`, `transfer`, `leave space`, `buff removed`)
   For sample `21001002`, `[2.0, 1.0, 1.0]` means a 2-second passive cooldown, max count 1, and explicit clear on `leave battle`; later clear behaviors fall back to defaults. Confidence: 5/5.

7. `buff_destroy_owner` and `buff_destroy_fromer` are event-survival flags, not generic booleans. The first three slots directly map to death, leave-battle, and leave-space checks for owner/source. Owner slot `4` is also used as default persistence when the buff instance is created. Confidence: 5/5 for slots `1-3`, 5/5 for owner slot `4` persistence use.

8. `buff_name` and `buff_detail` are localization-table IDs. `buff_detail` is formatted with `buff_attribute_type/value` pairs. Confidence: 5/5.

9. `buff_estimate` is the UI debuff/buff classification field. Exact naming is not declared in one enum in current scope, but `2` is directly treated as "debuff" by UI code; sample `21001002` uses `1`, so it is on the non-debuff branch in that logic. Confidence: 4/5.

10. `buff_show_flag` is a UI visibility mode, not combat logic. Verified meanings in current scope:
   - `1`: filtered out of standard buff icon lists
   - `3`: hides countdown/progress display
   - `4`: only shown when the main player is the owner or source
   Sample `21001002` has `buff_show_flag = 1`, so it is hidden from the normal buff icon list path. Confidence: 4/5.

11. `has_fake_need` is part of the client/fake-server synchronization path for buffs. It is used to decide whether fake/local handling is needed and can override server-only visibility in single-player style cases. Confidence: 4/5.

12. Xinfa / innerway systems relate to buffs in two verified ways:
   - Equipping Xinfa enables passive skills; passive skills with `condition = 0` can auto-add permanent buffs through `passive_skills.json`.
   - Xinfa also writes attributes directly into `attr_formula`, so not all innerway power is represented as buffs.
   Confidence: 5/5.

13. Martial arts and school data connect indirectly to buff behavior through Xinfa selection. `combat_plan_misc.lua` recommends Xinfa from `xinfa_wuxue` and `liupai_xinfa`; equipped Xinfa then enables passive skills, and those passive skills may add buffs. Confidence: 5/5.

14. Buffs can explicitly bind their lifetime to passive skills or martial arts via `remove_passive_delete` and `remove_kongfu_delete`. Confidence: 5/5.

15. `buff_type` is a real config field, but in current combat scope I only verified one concrete use: behit configs can remove buffs by matching `buff_type`. I did not find a direct enum naming what value `2` means for the sample. Confidence: 3/5 for "used as a removal category", not enough for stronger semantic naming.

16. `has_anti_need` is consulted by anti-cleanup logic, but the producer/trigger for `_buff_anti_on_check` was not identified in current authoritative scope. Confidence: 3/5 for this limited statement.

# Unknown / Missing Evidence

- No direct authoritative reference was found showing exactly which skill, passive skill, or behavior config first grants buff `21001002`. In current scope, the verified links are:
  - the buff row itself
  - its generated passive IDs
  - the downstream debuff `21001012`

- `buff_type = 2` for sample `21001002` was not mapped to a human-readable enum name in current scope.

- `has_anti_need = 1` is only weakly explained by the located code. The cleanup check is real, but the upstream anti-record producer was not found.

- For meridian / acupoint systems, I found activation and progression rule code (`meridian_base.lua`), but not an authoritative buff bridge in current scope. Xinfa-to-buff integration is clear; meridian-to-buff integration remains unverified here.

- `buff_destroy_fromer[4]` exists in data, but I did not find a direct authoritative consumer for the fourth source-side slot in current scope.

# Next Scoped Search Steps

1. Search authoritative skill configs for the first grant path of `21001002`, starting from passive-skill and combat-skill data tables that contain `buff_id`.
2. Search authoritative event wiring for `_buff_anti_on_check` to resolve the gameplay meaning of `has_anti_need`.
3. Search authoritative meridian / acupoint config files, if present elsewhere in `Scripts/data/DirObject`, to verify whether meridian progression adds buffs, passive skills, or only direct attributes.

# Follow-up Scope: Xinfa 104

Analyze Xinfa row `104` from `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.xinfa.json`, explain the runtime meaning of its fields, and map its full passive-buff progression:

- `104 -> passive_skill_id / uprank passive_skill_id -> passive_skills.buff_id -> buff / buff_passive_data`

## Evidence 15: Xinfa passive skill is rank-aware, not fixed to the base row

- Source: `Scripts/source_decompiled/hexm/common/property_define/avatar/xinfa.lua`
- Excerpt:
  - `function Xinfa:passive_skill() if self.rank > 0 then return self:rank_d():get("passive_skill_id") end return self:sysd():get("passive_skill_id") end`
  - `function Xinfa:rank_d() return G.datam.xinfa_uprank_info:get(self.id * 100 + self.rank) or {} end`
- Why it matters: `passive_skill_id` on the base Xinfa row only applies at rank `0`. Once the Xinfa is advanced, the passive skill comes from `xinfa_uprank_info`.
- Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.xinfa.json`
- Excerpt:
  - `104 -> "passive_skill_id": 21041`
- Why it matters: this is the base passive skill for Xinfa `104`.
- Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.xinfa_uprank_info.json`
- Excerpt:
  - `10401 -> "passive_skill_id": 21042`
  - `10402 -> "passive_skill_id": 21042`
  - `10403 -> "passive_skill_id": 21043`
  - `10404 -> "passive_skill_id": 21044`
  - `10405 -> "passive_skill_id": 21044`
  - `10406 -> "passive_skill_id": 21045`
- Why it matters: Xinfa `104` replaces its passive skill as rank increases.
- Evidence Confidence: 5/5

## Evidence 16: Equipped Xinfa enables passive skills, and passive skills auto-add their buff lists

- Source: `Scripts/source_decompiled/hexm/common/base/ai_avatar/xinfa_base.lua`
- Excerpt:
  - `local skill_id = xinfa:passive_skill()`
  - `self.skill_ctrl:add_passive_skill(skill_id, { ["level"] = xinfa.level })`
- Why it matters: equipping a Xinfa is the runtime step that enables its passive skill.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/combat/skill_ctrl.lua`
- Excerpt:
  - `if 0 == sysd:get("condition", 0) then local buffs = sysd:get("buff_id")`
  - `self.entity:add_buff(bid, self.entity.id, { ["duration"] = -1, ["persistent"] = false, ["reason"] = "enable_passive_skill", ["ignore_dead"] = true })`
- Why it matters: passive skills with `condition = 0` immediately add their `buff_id` list as permanent buffs while enabled.
- Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.passive_skills.json`
- Excerpt:
  - `21041 -> "buff_id": [10210410, 10210418, 10210426], "condition": 0`
  - `21042 -> "buff_id": [10210411, 10210418, 10210426, 10210412], "condition": 0`
  - `21043 -> "buff_id": [10210413, 10210418, 10210426, 10210412], "condition": 0`
  - `21044 -> "buff_id": [10210414, 10210418, 10210426, 10210412], "condition": 0`
  - `21045 -> "buff_id": [10210416, 10210418, 10210426, 10210412, 10210425, 10210427], "condition": 0`
- Why it matters: this is the authoritative rank-by-rank buff payload for Xinfa `104`.
- Evidence Confidence: 5/5

## Evidence 17: `splinter_num`, `max_advanced_lv`, `splinter_id`, and `original_id` drive study / progress / uprank flow

- Source: `Scripts/source_decompiled/hexm/common/property_define/avatar/xinfa.lua`
- Excerpt:
  - `function Xinfa:max_progress() return self:sysd():get("splinter_num", 1) end`
  - `function Xinfa:is_max_rank() return self.rank >= self:sysd():get("max_advanced_lv", 6) end`
- Why it matters: `splinter_num` is the progress requirement for completing the base Xinfa, and `max_advanced_lv` is the rank cap.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/consts/xinfa_consts.lua`
- Excerpt:
  - `_M.STUDY_SPLINTER = 1`
  - `_M.STUDY_ORIGINAL = 2`
  - `_M.STUDY_KEY = { [_M.STUDY_SPLINTER] = "splinter_id", [_M.STUDY_ORIGINAL] = "original_id" }`
- Why it matters: the study system explicitly maps study modes to `splinter_id` and `original_id`.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/combat/neigong/xinfa_base.lua`
- Excerpt:
  - `local splinter_id, original_id = sysd:get("splinter_id"), sysd:get("original_id")`
  - `if not splinter_id or not original_id then return errcode.ERR_XINFA_UPRANK_ERROR end`
- Why it matters: both item fields are required by the Xinfa uprank path.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/imp_xinfa.lua`
- Excerpt:
  - `local original_stuff_no = xinfa_info:get("original_id")`
  - `local splinter_stuff_no = xinfa_info:get("splinter_id")`
  - `local can_add_progress = original_stuff_num * volume_num * splinter_num + volume_stuff_num * splinter_num + splinter_stuff_num`
- Why it matters: local Xinfa UI/progress checks treat `original_id` and `splinter_id` as the actual study items that fill Xinfa progress.
- Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.xinfa_splinter_items.json`
- Excerpt:
  - `2208104 -> 104`
- Why it matters: `splinter_id = 2208104` is the fragment item for Xinfa `104`.
- Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.xinfa_original_items.json`
- Excerpt:
  - `2210104 -> 104`
- Why it matters: `original_id = 2210104` is the complete/original item for Xinfa `104`.
- Evidence Confidence: 5/5

## Evidence 18: UI and filter code directly consume `type`, `star`, `liupai_id`, `effect_type`, `icon_no`, `name`, and `passive_skill_brief_description`

- Source: `Scripts/source_decompiled/hexm/common/consts/xinfa_consts.lua`
- Excerpt:
  - `_M.XINFA_TYPE_PASSIVE = 1`
  - `_M.XINFA_TYPE_ACTIVE = 2`
- Why it matters: `type = 1` on Xinfa `104` means this row is a passive Xinfa, not an active one.
- Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.xinfa_types.json`
- Excerpt:
  - `1 -> "xinfa_type": 1`
  - `2 -> "xinfa_type": 2`
- Why it matters: the data-side type table matches the code-side passive/active enum.
- Evidence Confidence: 4/5

- Source: `Scripts/source_decompiled/hexm/client/consts/xinfa_consts.lua`
- Excerpt:
  - `local xinfa_type = xinfa_info:get("type")`
  - `local xinfa_star = xinfa_info:get("star")`
  - `local xinfa_effect = xinfa_info:get("effect_type", {})`
  - `local xinfa_liupai = xinfa_info:get("liupai_id", 0)`
- Why it matters: filtering and sorting logic read these base fields directly.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/ui/windows/chiji/bag/float/chiji_xinfa_float.lua`
- Excerpt:
  - `:set_texture(xinfa_client_consts.XINFA_STAR_TO_BG_PINZHI[self.xinfa_data:get("star")])`
  - `local xinfa_effects = self.xinfa_data:get("effect_type")`
  - `local effect_info = G.datam.xinfa_eff_types:get(effect_id)`
  - `local describe_text_raw = LOC(self.xinfa_data:get("passive_skill_brief_description", ""))`
- Why it matters: `star`, `effect_type`, and `passive_skill_brief_description` are UI display fields.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/consts/xinfa_consts.lua`
- Excerpt:
  - `["icon"] = xinfa_config:get("icon_no", "")`
  - `["name"] = LOC(xinfa_config:get("name", ""))`
  - `0 == xinfa_rank and xinfa_config:get("passive_skill_brief_description", "")`
- Why it matters: `icon_no`, `name`, and `passive_skill_brief_description` are used for resume/summary UI.
- Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.xinfa_eff_types.json`
- Excerpt:
  - `1 -> "icon": "buff_fight_gong_rise"`
  - `17 -> "icon": "wuxue_school_icon"`
  - `7 -> "icon": "com_hot_icon_96"`
- Why it matters: Xinfa `104` uses `effect_type = [1, 17, 7]`, which are tags resolved through `xinfa_eff_types`.
- Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.xinfa_icon_config.json`
- Excerpt:
  - `104 -> { "ccs": "xinfa_v2_item_icon_6", "icon": "xinfa_wuming_icon", "point_offset1": [...], ... }`
- Why it matters: there is a separate icon/layout table keyed by `104`, which is the data-side correlation behind `view_id = 104`.
- Evidence Confidence: 3/5

## Evidence 19: `grey_test_description` is a list of grey-description IDs, resolved through `xinfa_grey_desc_data`

- Source: `Scripts/source_decompiled/hexm/client/consts/xinfa_consts.lua`
- Excerpt:
  - `return bool(xinfa_data:get("grey_test_description"))`
  - `return xinfa_data:get("grey_test_description", nil)`
  - `local sys_d = G.datam.xinfa_grey_desc_data`
  - `if sys_d[grey_desc_id]:get("xinfa_lv") == rank then return true end`
- Why it matters: `grey_test_description` is not free text. It is a list of IDs into `xinfa_grey_desc_data`, keyed by required Xinfa rank.
- Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.xinfa_grey_desc_data.json`
- Excerpt:
  - `1011 -> "xinfa_lv": 6`
- Why it matters: sample Xinfa `104` carries `grey_test_description = [1011]`, so its grey description entry is tied to rank `6`.
- Evidence Confidence: 5/5

## Evidence 20: `convert_type`, `targeted_rewards_id`, `targeted_goods_id`, `xinde_id`, and swap-side `liupai_id` are consumed through `G.datam.xinfa_swap`

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.xinfa_swap.json`
- Excerpt:
  - `104 -> "convert_type": 1, "liupai_id": 1, "targeted_rewards_id": [1311081, 1311082, 1311083, 890505, 890506, 890507, 890508, 890509], "xinde_id": 2232104`
- Why it matters: the swap/conversion subsystem reads these values from the specialized `xinfa_swap` table.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/combat/neigong/xinfa_base.lua`
- Excerpt:
  - `local a_sys_d = G.datam.xinfa_swap:get(a_xinfa_id, {})`
  - `local a_convert_type = a_sys_d:get("convert_type", 0)`
  - `if 0 == b_convert_type or 0 == b_convert_type then return errcode.ERR_XINFA_CONVERT_TYPE end`
  - `if 2 == a_convert_type then local convert_start_time = a_sys_d:get("convert_start_time", 0) if nowstamp < convert_start_time then return errcode.ERR_XINFA_CONVERT_TIME end end`
- Why it matters: verified `convert_type` behavior in current scope is:
  - `0`: cannot participate in swap
  - `1`: normal swappable state
  - `2`: swappable only after `convert_start_time`
- Evidence Confidence: 4/5

- Source: `Scripts/source_decompiled/hexm/common/combat/neigong/xinfa_base.lua`
- Excerpt:
  - `local targeted_rewards_id = sys_d:get("targeted_rewards_id", {})`
  - `local targeted_goods_id = sys_d:get("targeted_goods_id", {})`
  - `local xinde_id = sys_d:get("xinde_id", 0)`
  - `for _, reward_no in pairs(targeted_rewards_id) do ... if stuff[1] == xinde_id then fix_xinde_cnt = fix_xinde_cnt + stuff[2] end end`
- Why it matters: `targeted_rewards_id` / `targeted_goods_id` and `xinde_id` are used to count fixed conversion material ("xinde") attached to this Xinfa.
- Evidence Confidence: 5/5

## Evidence 21: Xinfa-to-wuxue and Xinfa-to-liupai relations are exposed through derived tables

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.xinfa_wuxue.json`
- Excerpt:
  - `10102 -> [104]`
- Why it matters: Xinfa `104` is the recommended Xinfa linked to martial-art (`wuxue`) `10102`.
- Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.liupai_xinfa.json`
- Excerpt:
  - `1 -> [101, 102, 103, 104, 100911, 101911]`
- Why it matters: Xinfa `104` is also grouped under `liupai_id = 1`.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/misc/combat_plan_misc.lua`
- Excerpt:
  - `local target_lst = G.datam.xinfa_wuxue:get(main_wx, {})`
  - `local liupai_data = G.datam.liupai_xinfa`
  - `local target_lst = liupai_data:get(main_liupai, {})`
- Why it matters: recommendation and selection logic use the derived Xinfa relation tables, not the base `related_wuxue_id` field directly.
- Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.passive_skill_to_xinfa.json`
- Excerpt:
  - `21041 -> 104`
- Why it matters: there is also a reverse index from passive skill back to Xinfa.
- Evidence Confidence: 5/5

## Evidence 22: Xinfa 104 has shared marker buffs and shared mechanic buffs

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.buff.json`
- Excerpt:
  - `10210418 -> only lifecycle / UI fields`
  - `10210426 -> "passive_effect": [1]`
- Why it matters: the shared buff list for Xinfa `104` mixes plain marker/state buffs with a real passive trigger carrier.
- Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.AL.skill.jian.json`
- Excerpt:
  - `Type": "CheckBuffNode", "buff_no": 10210418, "need": 1`
- Why it matters: `10210418` is explicitly checked by sword action-line skill data, so even though its buff row has no direct stat or passive members, it functions as a gating marker for skill logic.
- Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.buff_passive_data.json`
- Excerpt:
  - `102104261 -> "effect_normal": [[117.0, 1.0, 0.01, 20.0]], "trigger": 127`
- Why it matters: `10210426` expands to passive `102104261`, so it is an actual mechanic carrier.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/consts/buff_passive_consts.lua`
- Excerpt:
  - `[127] = "ex_jianqi"`
  - `[117] = "_effect_trigger_ex_jianqi_adj_dmg"`
- Why it matters: the passive triggers on `ex_jianqi` and uses the special Jianqi damage-adjust function.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/misc/buff_passive_misc.lua`
- Excerpt:
  - `local cnt = int(owner_naili // naili_per)`
  - `adj_dmg = adj_dmg * cnt`
  - `buff:do_change_combat_res(attr_consts.COMBAT_RES_NAILI, -adj_naili, 0)`
  - `damage_adjust_misc.adjust_calc_params(d.adjust_params, 0, adj_dmg)`
- Why it matters: `10210426` consumes `Naili` and converts it into extra Jianqi damage. With `[117, 1, 0.01, 20]`, the effect is `1 Naili` per step, `+0.01` damage each step, capped at `20` steps.
- Evidence Confidence: 5/5

## Evidence 23: Higher-rank Xinfa 104 buffs add extra passive trigger chains

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.buff.json`
- Excerpt:
  - `10210413 -> "passive_effect": [1]`
  - `10210414 -> "passive_effect": [102104131, 1]`
  - `10210416 -> "passive_effect": [1, 102104131, 102104141]`
  - `10210425 -> "add_cd": [20.0], "cd_related_buff": 10210428, "passive_effect": [1]`
  - `10210427 -> "add_cd": [20.0, 8.0], "passive_effect": [1]`
- Why it matters: higher ranks do not just swap a text buff. They add more trigger carriers and cooldown-linked helper buffs.
- Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.buff_passive_data.json`
- Excerpt:
  - `102104131 -> "effect_event": [[4.0, 10210424.0, 1.0]], "trigger": 1`
  - `102104141 -> "effect_normal": [[106.0, 10210423.0, 100.0]], "trigger": 127`
  - `102104251 -> "effect_normal": [[106.0, 10210423.0, 100.0, 10210417.0, 100.0]], "trigger": 127`
  - `102104161 -> "effect_normal": [[113.0, 20.0, 10210427.0]], "trigger": 101`
  - `102104271 -> "effect_normal": [[113.0, 1.0, 10210425.0]], "trigger": 138`
- Why it matters: rank-up buffs add helper-buff application and passive-cooldown interaction on top of the shared Xinfa 104 baseline.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/consts/buff_passive_consts.lua`
- Excerpt:
  - `[1] = "adjust_params_out"`
  - `[101] = "on_buff_add"`
  - `[138] = "jianqi_atk_first"`
  - `[106] = "_effect_trigger_get_buff"`
  - `[113] = "_effect_trigger_dec_passive_cd"`
- Why it matters: this resolves the major trigger/effect IDs used by the higher-rank passives.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/misc/buff_passive_misc.lua`
- Excerpt:
  - `function _M._cond_trigger_jianqi_atk_first(...) if not target or not target.tag:is_boss() then return end ... if cur_jm_tag and cur_jm_tag:contains(1001) then ... return true end`
- Why it matters: the `jianqi_atk_first` trigger is specifically boss-targeted and gated by Jianqi-tagged calcpoints.
- Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.buff.json`
- Excerpt:
  - `10210417 -> "buff_add_resource": [10.0, 5, 0.0, 20.0, 1, 0.0], "buff_maxtime": 5.0`
  - `10210423 -> "buff_maxtime": 5.0`
  - `10210424 -> "buff_estimate": 2, "buff_maxtime": 5.0, "buff_sameadd_max": 3, "passive_effect": [1, 2]`
  - `10210428 -> "buff_show_flag": 0, "get_buff_toast": 1`
- Why it matters: the higher-rank helper buffs are real follow-up state objects, not just hidden bookkeeping IDs.
- Evidence Confidence: 4/5

# Follow-up Conclusions: Xinfa 104

1. The authoritative runtime chain for Xinfa `104` is:
   - `G.datam.xinfa[104]` for base row fields
   - `G.datam.xinfa_uprank_info[10401..10406]` for rank replacements
   - `Xinfa:passive_skill()` chooses the current passive skill
   - `skill_ctrl:enable_passive_skill()` adds the passive skill's `buff_id` list
   - `G.datam.buff` and `G.datam.buff_passive_data` define the real buff behavior
   Confidence: 5/5.

2. Xinfa `104` passive-buff progression is:
   - Rank `0`: passive skill `21041` -> buffs `10210410`, `10210418`, `10210426`
   - Rank `1-2`: passive skill `21042` -> buffs `10210411`, `10210418`, `10210426`, `10210412`
   - Rank `3`: passive skill `21043` -> buffs `10210413`, `10210418`, `10210426`, `10210412`
   - Rank `4-5`: passive skill `21044` -> buffs `10210414`, `10210418`, `10210426`, `10210412`
   - Rank `6`: passive skill `21045` -> buffs `10210416`, `10210418`, `10210426`, `10210412`, `10210425`, `10210427`
   Confidence: 5/5.

3. Shared-buff interpretation for Xinfa `104`:
   - `10210418` is a marker buff used by sword action-line skill checks (`CheckBuffNode`), not a direct attribute or passive carrier in its own row.
   - `10210426` is the shared mechanic buff. It installs passive `102104261`, which converts `Naili` into extra `ex_jianqi` damage.
   Confidence: 5/5.

4. High-rank Xinfa `104` adds new trigger carriers instead of only replacing text:
   - `10210413` / `10210414` add passive `102104131`, which can apply helper buff `10210424`
   - `10210416` adds the shared Jianqi passive plus extra helper-buff logic through `102104141` and `102104161`
   - `10210425` and `10210427` are cooldown-linked high-rank helpers that add more passive-cooldown / helper-buff interaction
   Confidence: 4/5.

5. Verified field map for Xinfa row `104`:
   - `id`: primary config key for the Xinfa row. Confidence: 5/5.
   - `name`: localization-table ID used for Xinfa UI naming. Confidence: 5/5.
   - `icon_no`: icon asset key used by Xinfa summary / resume UI. Confidence: 5/5.
   - `type`: Xinfa category. `1` means passive Xinfa. Confidence: 5/5.
   - `star`: quality/tier. Used for sorting, UI background, and swap same-star validation. Confidence: 5/5.
   - `liupai_id`: school/faction grouping. Used for filters, display, swap rules, and `liupai_xinfa` relation tables. Confidence: 5/5.
   - `effect_type`: list of effect-tag IDs resolved through `xinfa_eff_types`, mainly for display/filter categorization. Confidence: 5/5.
   - `passive_skill_id`: base-rank passive skill (`21041`). Confidence: 5/5.
   - `passive_skill_brief_description`: rank-0 brief description shown in UI until uprank descriptions replace it. Confidence: 5/5.
   - `max_advanced_lv`: rank cap. For Xinfa `104`, this is `6`. Confidence: 5/5.
   - `splinter_num`: progress requirement used as the Xinfa's base completion threshold. For Xinfa `104`, this is `10`. Confidence: 5/5.
   - `splinter_id`: fragment item ID used for Xinfa study/progress. For Xinfa `104`, this is `2208104`. Confidence: 5/5.
   - `original_id`: complete/original item ID used for Xinfa study/progress and uprank checks. For Xinfa `104`, this is `2210104`. Confidence: 5/5.
   - `grey_test_description`: list of grey-description IDs resolved through `xinfa_grey_desc_data`. For Xinfa `104`, `[1011]` points at a rank-6 grey description entry. Confidence: 5/5.
   - `convert_type`: swap/conversion mode read from `G.datam.xinfa_swap`; `1` is the normal immediately swappable state in current scope. Confidence: 4/5.
   - `targeted_rewards_id`: reward IDs scanned when counting fixed `xinde` obtained for swap/conversion accounting. Confidence: 5/5.
   - `xinde_id`: conversion material ID used by the swap/fix-xinde system. For Xinfa `104`, this is `2232104`. Confidence: 5/5.

6. Partially verified / data-correlation fields for Xinfa row `104`:
   - `related_wuxue_id = 10102`: this matches the derived reverse table `xinfa_wuxue[10102] -> [104]`, but I did not find a direct runtime read of the base field itself. Confidence: 3/5 for "data-side relation", not stronger.
   - `view_id = 104`: this matches the key in `xinfa_icon_config[104]`, but I did not find the direct runtime consumer in current scope. Confidence: 3/5.
   - `view_name = "xinfa_v2_item_icon_view"`: looks like a UI template name, but I did not find the direct runtime consumer in current scope. Confidence: 3/5.

# Follow-up Unknown / Missing Evidence

- `describe_str = 540028` is present on the base Xinfa row, but I did not find a direct runtime consumer for this exact field in current authoritative scope.

- `min_study_unit = 2` is present on the base Xinfa row, and the codebase clearly has Xinfa study-unit constants (`splinter` / `original`), but I did not find a direct read of `min_study_unit` itself in current authoritative scope.

- I did not find a direct runtime consumer for the base-row copies of `convert_type`, `targeted_rewards_id`, `xinde_id`, or `liupai_id`; the swap logic reads them from `G.datam.xinfa_swap`, which duplicates the Xinfa `104` swap-side values.

- `xinfa_icon_config[104]` exists and contains icon/layout offsets for Xinfa `104`, but I did not find the direct consumer path in current scope, so the exact runtime role of `view_id` remains only partially verified here.
