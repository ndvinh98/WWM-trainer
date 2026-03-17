# Skill 20201006 — Multi-Hit vs Single-Hit Analysis

## Question / Scope

Skill 20201006 fires multiple sword energy attacks when enemies are NOT in combat, but only one hit when enemies ARE in combat. What controls this, and how to make it always fire multiple hits?

## Skill Structure

| Skill ID | skill_class | attackline | Role |
|---|---|---|---|
| 20201006 | 102 (charge) | `"20201006"` (jian.json) | Base charge skill |
| 20201008 | — | `"20201008"` (jian.json) | Combo follow-up |
| 20201006300 | 3 | `"20201006300"` (jian_20202.json) | Full-charge variant (base) |
| 20201006301 | 3 | `"20201006300"` (shared) | Full-charge variant |
| 20201006302 | 3 | `"20201006300"` (shared) | Full-charge variant |

# Evidence

## E1 — GraphID 20: The `jianqi` Tag Gate (Root Cause)

- **Source:** `GreyTableInfo/hexm.client.data_oversea.AL.skill.jian.json`, actionline `"20201006"`, GraphID 20
- **Excerpt (flow):**
```
CheckBuffNode(buff=10210412) → SimpleSelect(group=99, target_type=0)
  → FilterTargetsInBattle(from_id=99, in_battle=false, to_id=99)
  → TargetNumberBranch(group=99, num=0, way=2)
  → ResultFilterNode(des=1) → SetTag("jianqi", 1)
```
- **Why it matters:** This graph runs at skill start. `FilterTargetsInBattle(in_battle=false)` keeps ONLY targets that are NOT in battle. If enemies have noticed the player (are "in battle"), they get filtered out. If no non-battle targets remain, `TargetNumberBranch` fails → `jianqi` stays 0.
- **Evidence Confidence: 5/5**

## E2 — FilterTargetsInBattle Source Code

- **Source:** `source_decompiled/hexm/common/actionline/nodes/target_nodes.lua:1149-1180`
- **Excerpt:**
```lua
function FilterTargetsInBattle:start(graph)
    local tgs = helper.get_targets(self.from_id, context) or {}
    local res = {}
    for _, tg in pairs(tgs) do
        if bool(tg.is_in_battle and tg:is_in_battle()) == self.in_battle then
            res:append(tg)
        end
    end
    if self.without_zero and 0 == #res then
        res = tgs:copy()
    end
    context.targets[self.to_id] = res
end
```
- **Why it matters:** Confirms the filter. `in_battle=false` → only keeps targets where `tg:is_in_battle() == false`. When all enemies ARE in battle, result is empty.
- **Evidence Confidence: 5/5**

## E3 — GraphID 21: Charge Level → Branch → jianqi Check

- **Source:** `GreyTableInfo/hexm.client.data_oversea.AL.skill.jian.json`, actionline `"20201006"`, GraphID 21
- **Excerpt (flow):**
```
ChargeNode(charge_lv_list=[0.55, 1.2], max_time=1.6, enable_charge_lv=true)
  .charge_lv → ResultBranch(branch1_res=0, branch2_res=1, branch3_res=2)
    branch1 (lv=0, <0.55s) → TriggerEvent("e_no_jianqi")        ← NO sword energy
    branch2 (lv=1, 0.55-1.2s) → TriggerEvent("e_normal_jianqi") ← SINGLE hit
    branch3 (lv=2, >1.2s) → GetTag("jianqi") → SimpleBranch(des=1)
      jianqi==1 → TriggerEvent("e_skill_ex_jianqi")              ← MULTI-HIT
      jianqi!=1 → TriggerEvent("e_normal_jianqi2")               ← SINGLE hit
```
- **Why it matters:** The 2nd-stage full charge (`charge_lv=2`) routes to branch3. There, it checks the `jianqi` tag. Only if `jianqi==1` does it trigger `e_skill_ex_jianqi` (the multi-hit variant). Otherwise it falls back to `e_normal_jianqi2` (single hit).
- **Evidence Confidence: 5/5**

## E4 — ChargeNode charge_lv Calculation

- **Source:** `source_decompiled/hexm/common/actionline/nodes/action_nodes.lua:560-603`
- **Excerpt:**
```lua
local charge_lv = 0
if self.enable_charge_lv then
    charge_lv = #self.charge_lv_list  -- starts at max (2)
    for lv, min_ts in pairs(self.charge_lv_list) do
        if min_ts > charge_time * global_spd then
            charge_lv = lv - 1
            break
        end
    end
end
graph:finish_node(self, { __out__ = 1, timeout = timeout, charge_lv = charge_lv })
```
- **Why it matters:** With `charge_lv_list=[0.55, 1.2]`, holding >1.2s gives `charge_lv=2`, which routes to branch3 in the ResultBranch.
- **Evidence Confidence: 5/5**

## E5 — combat_posture_is_in_battle (entity check)

- **Source:** `source_decompiled/hexm/client/entities/local/ai_avatar_members/imp_combat_posture.lua:424-426`
- **Excerpt:**
```lua
function AIAvatarMember:combat_posture_is_in_battle()
    if self.anim and self.anim._actor_cxx then
        return 1 == self:get_variable("G_BATTLE_MODE", graph_consts.VARIABLE_TYPE_INT)
```
- **Why it matters:** `is_in_battle()` checks `G_BATTLE_MODE == 1`. Enemies that have noticed the player are in battle mode, causing `FilterTargetsInBattle(in_battle=false)` to exclude them.
- **Evidence Confidence: 5/5**

# Conclusions (Score ≥3 only)

## The Complete Mechanism

1. **Skill start** (Timeline 283, GraphID 20 at time=0.0):
   - Select nearby entities into group 99
   - `FilterTargetsInBattle(in_battle=false)` removes entities whose `is_in_battle()` returns true
   - `TargetNumberBranch(num=0, way=2)` checks: are there any remaining?
   - If yes → **`jianqi` tag = 1** (multi-hit enabled)
   - If no → `jianqi` stays 0 (single hit only)

2. **2nd-stage charge release** (GraphID 21, charge_lv=2):
   - `ResultBranch` routes to branch3
   - Checks `jianqi` tag
   - `jianqi==1` → `e_skill_ex_jianqi` → **multiple sword energy attacks**
   - `jianqi==0` → `e_normal_jianqi2` → **single sword energy attack**

## Why Single-Hit in Combat

When enemies have **noticed the player** (are "in battle"), `G_BATTLE_MODE==1` for those entities. `FilterTargetsInBattle(in_battle=false)` filters them ALL out → empty target list → `TargetNumberBranch` fails → `jianqi` stays 0 → charge branch3 falls to single hit.

## How to Force Multi-Hit Always

**Hook `FilterTargetsInBattle:start`** to bypass the `in_battle` filter.

**Target module:** `hexm.common.actionline.nodes.target_nodes`
**Target class:** `FilterTargetsInBattle`
**Target method:** `start`

The hook should make it copy ALL targets from `from_id` to `to_id` regardless of battle state, effectively making `jianqi` always set to 1 when any targets exist nearby.

```lua
-- Pseudocode for the hook
-- Override FilterTargetsInBattle:start to skip in_battle check
-- Original: keeps only tg:is_in_battle() == self.in_battle
-- Hooked: keeps all targets unconditionally
```

This ensures the `jianqi` tag is always 1 when enemies are present, regardless of combat state.

# Unknown / Requires Further Investigation

1. **Buff gate (10210412):** CheckBuffNode(buff_no=10210412) gates the entire jianqi detection path. If this buff is absent, the graph skips the detection. When/how this buff is applied is unclear.
2. **Secondary jianqi path:** Buffs 10210418 + 400081 can also set jianqi=1 independently (GraphID 20, nodes 199-201). Unclear when these buffs are active.
3. **Downstream events:** `e_skill_ex_jianqi` vs `e_normal_jianqi2` — what exact actionlines/timelines they trigger to produce the multi-hit vs single-hit effects was not traced in this pass.
4. **Full-charge variants (20201006300-304):** The `ResultBranch` in the 20201006300 AL also branches by `skill_id`, but this is for variant selection, not for the multi/single hit distinction.

# Next Scoped Search Steps

1. Trace `e_skill_ex_jianqi` event to find the multi-hit attack graph downstream
2. Investigate buff 10210412 to determine when the jianqi detection path is active
3. Implement the `FilterTargetsInBattle` hook and test
