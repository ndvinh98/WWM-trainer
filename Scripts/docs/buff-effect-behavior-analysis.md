# Question / Scope

Can buff data tell us the actual effect/behavior applied to a player, such as attack, defense, recovery, or similar combat roles?

# Evidence

## Evidence 1
- Source: `Scripts/source_decompiled/hexm/common/combat/buff/factory.lua`
- Excerpt:
  - `function BuffHandlerFactory:get_components(uid, sys_d, is_partial)`
  - `if it.should_enable then`
  - `if it.should_enable(sys_d) then`
  - `out_arr:append(it)`
- Why it matters:
  - A buff row does not map to one fixed effect type. The engine inspects the buff data and enables multiple handler components depending on which fields are present.
- Evidence Confidence: 5/5

## Evidence 2
- Source: `Scripts/source_decompiled/hexm/common/combat/buff/members/import.lua`
- Excerpt:
  - `require("hexm.common.combat.buff.members.buff_attribute")`
  - `require("hexm.common.combat.buff.members.buff_add_shield")`
  - `require("hexm.common.combat.buff.members.buff_lifesteal").BuffHandlerMember`
  - `require("hexm.common.combat.buff.members.buff_liferegain").BuffHandlerMember`
  - `require("hexm.common.combat.buff.members.buff_immune_dmg")`
  - `require("hexm.common.combat.buff.members.buff_passive")`
- Why it matters:
  - The buff system supports many effect families directly: attributes, shield, lifesteal, recovery, immunity, passive logic, and more.
- Evidence Confidence: 5/5

## Evidence 3
- Source: `Scripts/source_decompiled/hexm/common/combat/buff/members/buff_attribute.lua`
- Excerpt:
  - `function BuffAttrFixHandler.should_enable(sys_d)`
  - `return sys_d:get("buff_attribute_value")`
  - `local conf_attrs = self:get_sys_v("buff_attribute_type")`
  - `self.comp:th_num_add(attr_k, attr_v, self.ID, "fcache")`
- Why it matters:
  - Buff rows can directly change combat attributes. This is one of the main places where attack/defense-style behavior can be inferred from data.
- Evidence Confidence: 5/5

## Evidence 4
- Source: `Scripts/source_decompiled/hexm/common/combat/buff/members/buff_liferegain.lua`
- Excerpt:
  - `function BuffHandlerMember.should_enable(sys_d)`
  - `return sys_d:get("life_regain")`
  - `self.comp:add_hp(v, self.data.fromid, "life_regain")`
- Why it matters:
  - Recovery behavior is directly inferable when the buff row contains `life_regain`.
- Evidence Confidence: 5/5

## Evidence 5
- Source: `Scripts/source_decompiled/hexm/common/combat/buff/members/buff_lifesteal.lua`
- Excerpt:
  - `function BuffHandlerMember.should_enable(sys_d)`
  - `return sys_d:get("life_steal")`
  - `self.comp:add_hp(v, self.data.fromid, "lifesteal")`
- Why it matters:
  - Some offensive/recovery hybrid behaviors are directly encoded by a field in the buff row.
- Evidence Confidence: 5/5

## Evidence 6
- Source: `Scripts/source_decompiled/hexm/common/combat/buff/members/buff_add_shield.lua`
- Excerpt:
  - `function BuffAddShield.should_enable(sys_d)`
  - `return sys_d:get("buff_shield_calc_id")`
  - `function BuffAddShieldHP.should_enable(sysd)`
  - `return sysd:get("buff_shield_calc_hp")`
  - `self.comp:add_shield(self, res, true, ratio)`
- Why it matters:
  - Defensive behavior such as shielding is directly inferable from specific buff fields.
- Evidence Confidence: 5/5

## Evidence 7
- Source: `Scripts/source_decompiled/hexm/common/combat/buff/members/buff_passive.lua`
- Excerpt:
  - `function PassiveLogic.should_enable(sysd)`
  - `return sysd:get("passive_effect")`
  - `for _, passive_index in pairs(passive_effect) do`
  - `if G.datam.buff_passive_data:get(passive_id) then`
  - `buff_passive_misc.reg_passive_logic(self, passive_id)`
- Why it matters:
  - Many important buff behaviors are not described directly on the buff row. They are delegated through `passive_effect` into `buff_passive_data`.
- Evidence Confidence: 5/5

## Evidence 8
- Source: `Scripts/source_decompiled/hexm/common/consts/buff_passive_consts.lua`
- Excerpt:
  - `_M.EFFECT_EVENT_MAP = {`
  - `[1] = "_effect_event_adj_dmg",`
  - `[2] = "_effect_event_adj_heal",`
  - `[3] = "_effect_event_steal_hp",`
  - `_M.EFFECT_NORMAL_MAP = {`
  - `[102] = "_effect_trigger_add_hp",`
  - `[110] = "_effect_trigger_remove_buff",`
- Why it matters:
  - Passive IDs resolve into typed effect handlers such as damage adjustment, heal adjustment, HP gain, and buff application/removal.
- Evidence Confidence: 5/5

## Evidence 9
- Source: `Scripts/source_decompiled/hexm/common/misc/buff_passive_misc.lua`
- Excerpt:
  - `function _M.reg_passive_logic(buff, passive_id)`
  - `local passive_data = G.datam.buff_passive_data:get(passive_id)`
  - `local trigger = passive_data.trigger`
  - `local trigger_name = buff_passive_consts.TRIGGER_EVENT:get(trigger)`
- Why it matters:
  - To understand passive behavior, buff data must be cross-referenced with `buff_passive_data`, trigger tables, and effect handlers.
- Evidence Confidence: 5/5

## Evidence 10
- Source: `Scripts/source_decompiled/hexm/common/misc/buff_passive_misc.lua`
- Excerpt:
  - `function _M._effect_event_adj_dmg(...)`
  - `function _M._effect_event_adj_heal(...)`
  - `function _M._effect_trigger_add_hp(...)`
- Why it matters:
  - The passive system contains concrete attack/recovery semantics, but they are only visible after decoding the passive effect path.
- Evidence Confidence: 5/5

## Evidence 11
- Source: `Scripts/source_decompiled/hexm/client/entities/local/buff/buff.lua`
- Excerpt:
  - `function Buff:get_is_control_buff()`
  - `return 0 ~= self:get_sys_data():get("buff_control_type", 0)`
  - `function Buff:get_is_debuff()`
  - `return 2 == self:get_sys_data():get("buff_estimate")`
- Why it matters:
  - `buff_control_type` and `buff_estimate` describe broad status categories only. They do not explain the full effect behavior.
- Evidence Confidence: 4/5

# Conclusions

1. Yes, buff data can reveal actual behavior in many cases, but not from a single field like `buff_type`. The reliable path is to decode which buff member handlers are enabled by the row. Confidence: 5/5
2. Direct categories are inferable from concrete fields on the buff row:
   - attack/stat modification: `buff_attribute_type` + `buff_attribute_value`, `has_formula_attr`
   - recovery: `life_regain`, `life_steal`
   - defense: `buff_shield_calc_id`, `buff_shield_calc_hp`, immunity-related fields
   - control/debuff metadata: `buff_control_type`, `buff_estimate`
   Confidence: 5/5
3. A large portion of real buff behavior is indirect through `passive_effect`, which must be resolved into `buff_passive_data`, then mapped through trigger/effect tables in `buff_passive_consts.lua` and `buff_passive_misc.lua`. Confidence: 5/5
4. Therefore, the current condensed buff CSV is enough for broad grouping, but not enough for a full “attack / defense / recovery / utility” classifier unless passive effects and direct handler fields are decoded together. Confidence: 5/5

# Unknown / Missing Evidence

- A complete attack/defense/recovery taxonomy still requires enumerating all attribute keys and all passive effect handlers.
- Some buffs may span multiple categories at once, because the same row can enable several handler modules.

# Next Scoped Search Steps

1. Map `buff_attribute_type` values to concrete attribute meanings used by combat formula code.
2. Export `passive_effect` -> `buff_passive_data` -> trigger/effect handler names into a derived CSV.
3. Add multi-label categories such as `attack`, `defense`, `recovery`, `resource`, `control`, `utility`, `summon`, `mobility`.
