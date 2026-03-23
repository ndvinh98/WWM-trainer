# Archery Master: Remote Damage / BeHit Analysis

## Question / Scope
How can we remotely trigger damage or the "behit" functionality on archery target entities (birds), since `G.space:remove_entity()` (destroy) does not satisfy the minigame's hit-detection requirements?

## Evidence

### 1. `BehitBase:do_direct_damage()` — Direct HP Damage API
**Source**: [behit_base.lua](file:///c:/temp/Where%20Winds%20Meet/Scripts/source_decompiled/hexm/common/combat/behit/behit_base.lua#L190-L233)

```lua
function BehitBase:do_direct_damage(damage, fromer_id, flag, damage_type, res_id, effect_id, skill_id)
  -- deducts HP, dispatches E_BEHIT, handles death if HP=0
end
```

**Signature**: `entity:do_direct_damage(damage, fromer_id, flag, damage_type, res_id, effect_id, skill_id)`
- `damage`: number — HP to deduct
- `fromer_id`: string — attacker entity ID (use player ID)
- `flag`: number (optional, default 0) — DamageFlag bitmask
- `damage_type`: number (optional, default DAMAGE_NORMAL) — skill_consts value
- `res_id`: string (optional, default "HP") — resource ID to damage
- `effect_id`: optional effect
- `skill_id`: optional skill ID

**Key behavior**:
- Dispatches `E_PRE_DAMAGE`, `E_BEHIT` events on the target
- Calls `self:_behit_post()` which dispatches `D_POST_HIT` to the attacker
- Calls `self:dead(fromer_id)` if HP reaches 0
- This is a **server-side RPC** method — may require `call_real` or accessing `fake_server`

**Evidence Confidence: 5/5** — Direct definition found, widely used pattern.

---

### 2. `BehitBase:behit()` — Full Combat Hit Pipeline
**Source**: [behit_base.lua](file:///c:/temp/Where%20Winds%20Meet/Scripts/source_decompiled/hexm/common/combat/behit/behit_base.lua#L628-L758)

```lua
function BehitBase:behit(calc_id, result, context)
  -- full combat hit with calcpoint, animations, damage calc
end
```

Requires:
- A valid `calc_id` (calcpoint ID from game data)
- A pre-calculated `result` dict with damage values
- A `context` dict with `attacker_id`, `skill_id`, etc.

**Evidence Confidence: 5/5** — Direct definition, used by DamageManager.

---

### 3. `DamageManager:process_calcpoint()` — Full Pipeline Entry Point
**Source**: [damage_manager.lua](file:///c:/temp/Where%20Winds%20Meet/Scripts/source_decompiled/hexm/common/combat/damage_manager.lua#L182-L554)

The arrow hit flow goes: `ArrowLaunch.on_client_hit()` → builds params with `arrow_dmg=true` → calls `DamageManager():process_calcpoint(cal_no, entity, targets, context, skill_id, params)`.

**Key client-side flow** (line 486-504):
```lua
-- On CLIENT, behit is called via timer:
target:set_behit_tag(true)
self.timer_mgr:add_timer(0, function()
  target:set_behit_tag(false)
  local param_context = parse_context(attacker, target, context, params)
  local res = target:behit(calc_id, dmg_res, param_context)
  attacker:on_calcpoint_hit_tg(process_id, calc_id, target_id, res)
end)
```

**Evidence Confidence: 5/5**

---

### 4. God Mode Damage Shortcut (via `is_niubility`)
**Source**: [behit_base.lua](file:///c:/temp/Where%20Winds%20Meet/Scripts/source_decompiled/hexm/common/combat/behit/behit_base.lua#L314-L315)

```lua
if skill_consts.DAMAGE_HIT:contains(damage_type) and fromer and fromer.is_niubility and fromer ~= self then
  res.damage = self:attr_get_HP() * 10  -- instant kill
end
```

If the attacker has `is_niubility = true`, damage auto-scales to 10x target HP. However this only applies within `_on_damage`, not `do_direct_damage`.

**Evidence Confidence: 5/5**

---

### 5. Entity Access Pattern
**Source**: [damage_manager.lua](file:///c:/temp/Where%20Winds%20Meet/Scripts/source_decompiled/hexm/common/combat/damage_manager.lua#L247-L254)

On CLIENT, entities must use their `fake_server` proxy for damage operations:
```lua
function DamageManager:get_entity(eid)
  local entity = G.space:get_entity(eid)
  if entity then
    return entity.fake_server
  end
end
```

**Evidence Confidence: 5/5**

---

### 6. `yaoyuan_target` Data — Purely Config-Driven
**Source**: [entity_blackboard.json](file:///c:/temp/Where%20Winds%20Meet/Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.entity_blackboard.json)

The `yaoyuan_target` key is found only in `entity_blackboard` data (linking NPC No → target entity No). It is NOT referenced in decompiled source code, confirming it's purely data-driven configuration.

**Evidence Confidence: 4/5** — Clear config-to-data mapping, but no code reference found.

## Conclusions (Score ≥3 only)

### Approach A: `do_direct_damage` (Recommended — Simplest)
Call `do_direct_damage` on the target entity's fake_server:
```lua
local target_entity = G.space:get_entity(target_eid)
local fs = target_entity and target_entity.fake_server
if fs and fs.do_direct_damage then
  fs:do_direct_damage(99999, G.main_player.id, 0)
end
```
**Pros**: Simple API, no calcpoint/context needed, triggers death + E_BEHIT event chain.
**Cons**: May not trigger full behit animation chain; needs runtime verification.

### Approach B: `process_calcpoint` via DamageManager (Full Pipeline)
Simulate a full arrow hit via DamageManager:
```lua
local DamageManager = require("hexm.common.combat.damage_manager").DamageManager
local targets = {target_entity.fake_server}
DamageManager():process_calcpoint(calc_id, G.main_player.fake_server, targets, context, skill_id, {arrow_dmg=true})
```
**Pros**: Full hit pipeline with proper animations, events.
**Cons**: Requires valid calc_id, context, skill_id — complex setup.

### Approach C: Direct `behit()` Call (Mid-Level)
```lua
target_fs:behit(calc_id, {HP=99999}, {attacker_id=G.main_player.id, skill_id=0})
```
**Pros**: Triggers full behit chain.
**Cons**: Needs valid calcpoint_id, may fail without proper context.

## Unknown / Missing Evidence
- Whether `do_direct_damage` on `fake_server` triggers the minigame completion callback (needs runtime probe)
- What `fake_server` methods are available on non-NPC entities (target birds)
- Whether target entities even have BehitBase mixed in (likely yes if they are combat entities)

## Next Steps — Runtime Probes Required

### Probe 1: Entity Shape Discovery
Discover the API shape of the yaoyuan target entity:
- Does it have `fake_server`?
- Does `fake_server` have `do_direct_damage`?
- Does it have `attr_get_HP`? What's its HP?
- Is it a combat entity (has BehitBase)?

### Probe 2: `do_direct_damage` Effect
Call `do_direct_damage` on a target entity while in the archery minigame and observe if the minigame registers the hit.

### Probe 3: Fallback — `DamageManager:process_calcpoint`
If `do_direct_damage` doesn't trigger minigame completion, try `process_calcpoint` with `arrow_dmg=true` and a valid calcpoint.
