# ON_BONE_HIT Dispatch Chain Analysis

## 1. Question / Scope

How does the system dispatch the `ON_BONE_HIT` callback that is bound via `Anim:bind_collision_notify`?

Trace the full chain from C++ engine `ActorComponent` firing `"BoneCollisionNotify"` through to actionline node processing (`BoneCollision:on_bone_hit` / `BatchBoneCollision:on_bone_hit`). Include deep analysis of how `ActorComponent` is configured for bone collision and all Lua-side `_actor_cxx:XXX` usage related to collision.


## 2. Evidence

### Evidence 2.1 — ActorComponent: Creation and Collision Identity

- **Source:** `hexm/client/entities/local/component/anim.lua` lines 61-85
- **Excerpt:**
```lua
function Anim:recreate_actor_cxx()
    local actor_cxx = self._owner.entity_cxx.Skeleton
    if actor_cxx then
        self._actor_cxx = actor_cxx
    else
        self._actor_cxx = MObject.CreateObject("ActorComponent")
        self._owner.entity_cxx.Skeleton = self._actor_cxx
    end
    self._actor_cxx.eid = self._owner.id
    self._actor_cxx:BindEvent("SignalNotify", function(trigger, subtype, value)
        self:_on_signal_notify(trigger, subtype, value)
    end)
    -- DeltaTimeCollectNotify binding (if MHexAC)
    self._actor_cxx.MaxSuffixNum = anim_consts.SUFFIX_SLOT_NUM
end
```
- **Why it matters:** `ActorComponent` is either reused from `entity_cxx.Skeleton` or newly created via `MObject.CreateObject("ActorComponent")`. The critical line `self._actor_cxx.eid = self._owner.id` stamps the entity ID onto the C++ component. When the engine detects a bone collision, it reads the **target's** `ActorComponent.eid` and embeds it in each result as `result.actor.eid` — this is how `on_bone_hit` resolves which Lua entity was hit.
- **Evidence Confidence:** 5/5 — Direct definition.

---

### Evidence 2.2 — ActorComponent: Runtime Properties (from live dump)

- **Source:** `Scripts/logs/script_debug.txt` lines 87-114
- **Excerpt:**
```
__name__ = "<instance ActorComponent at 000001F1DE1C84D0>"
__properties__ = {
    ApplyMotion = true,           -- whether graph motion drives entity transform
    EnableActionGroupChangeNotify = true,
    EnableTickBeforePhyX = true,  -- tick order relative to physics
    EnableTickWithPrePost = false,
    ForceUpdateFilter = false,
    HideTPose = true,
    IsReady = true,               -- skeleton + graph fully loaded
    MaxSuffixNum = 12,
    ReplaceSuffix = "jian",       -- weapon suffix for animation variant lookup
    UseDynamicVisibilityBox = true,
    UserSkeletonTag = -1,
    UserTag = "PlayerAvatar",
}
```
- **Why it matters:** This live dump shows the full set of C++ properties on a player's `ActorComponent`. Notable for collision: `IsReady` must be `true` before collision evaluation occurs (the skeleton and collision skeleton data must be loaded). `ApplyMotion` controls whether bone movement feeds back into entity position. `ReplaceSuffix = "jian"` selects weapon-variant animation states.
- **Evidence Confidence:** 5/5 — Direct runtime observation.

---

### Evidence 2.3 — ActorComponent: Collision Enable/Disable via `SetEnableColliderQuery`

- **Source:** `hexm/client/entities/local/component/anim.lua` lines 364-368
- **Excerpt:**
```lua
function Anim:set_enable_collider_query(enable)
    if self._actor_cxx then
        self._actor_cxx:SetEnableColliderQuery(enable)
    end
end
```
- **Source (usage):** `hexm/client/entities/local/avatar_members/imp_skill.lua` line 31
- **Excerpt:**
```lua
function SkillComp:__skeleton_ready_component__()
    self.anim:set_enable_collider_query(false)
end
```
- **Why it matters:** `SetEnableColliderQuery(bool)` is the C++ on/off switch for bone collision detection on an `ActorComponent`. Player avatars **disable** it at skeleton ready — the collision query is **not active by default** for the attacker. The engine's collision detection runs on the **target's** collision skeleton shapes, not the attacker's. The attacker's collider shapes (named "C1", "C2", etc.) are authored in the animation graph and activated by graph state transitions during skill animations. The target's collision skeleton is always loaded as part of the skeleton asset.
- **Evidence Confidence:** 5/5 — Direct definition and usage.

---

### Evidence 2.4 — ActorComponent: Collision Skeleton Diagnostics

- **Source:** `hexm/client/entities/local/component/anim.lua` lines 2452-2464
- **Excerpt:**
```lua
function Anim:get_collision_skeleton_sphere_radius()
    return self._actor_cxx:GetCollisionSkeletonBoundingSphereRadius()
end

function Anim:is_collision_skeleton_anomaly()
    return self._actor_cxx:IsCollisionSkeletonAnomaly()
end
```
- **Source (usage):** `hexm/client/entities/local/common_members/inspection/imp_inspection.lua` lines 163-226
- **Excerpt:**
```lua
local collision_radius = self.anim:get_collision_skeleton_sphere_radius()
local is_collision_radius_cheated = collision_radius
    and collision_radius
        > math.max(static_box_extend_in_world.x, ...) * 5
local is_collision_cheated = self.anim:is_collision_skeleton_anomaly()
```
- **Why it matters:** The C++ `ActorComponent` maintains a **collision skeleton** — a simplified skeletal hierarchy of capsule/sphere shapes attached to bones. `GetCollisionSkeletonBoundingSphereRadius()` returns the bounding sphere of all collision shapes. `IsCollisionSkeletonAnomaly()` detects if collision shapes have been tampered with (anti-cheat). The collision skeleton is loaded from the `.skeleton` asset alongside the render skeleton — it's authored in the engine's skeleton editor, not from Lua configuration.
- **Evidence Confidence:** 4/5 — Usage-inferred; collision skeleton loading is opaque C++.

---

### Evidence 2.5 — ActorComponent: All Supported BindEvent Types

- **Source:** `hexm/client/entities/local/component/anim.lua` lines 54-55, 70-76, 370-386, 2148-2152
- **Excerpt (all event types bound on ActorComponent):**
```lua
-- 1. SignalNotify — graph animation cue signals (always bound at creation)
self._actor_cxx:BindEvent("SignalNotify", function(trigger, subtype, value) ... end)

-- 2. BoneCollisionNotify — bone collider overlap detection
self._actor_cxx:BindEvent("BoneCollisionNotify", callback)

-- 3. PhysicsCollisionNotify — physics-based projectile collision
self._actor_cxx:BindEvent("PhysicsCollisionNotify", callback)

-- 4. ActorSelectNotify — entity selection (UI interaction)
self._actor_cxx:BindEvent("ActorSelectNotify", callback)

-- 5. ActiveActionGroupChangedNotify — animation group change
self._actor_cxx:BindEvent("ActiveActionGroupChangedNotify", function(group) ... end)

-- 6. DeltaTimeCollectNotify — frame delta time profiling (if MHexAC)
self._actor_cxx:BindEvent("DeltaTimeCollectNotify", function(result) ... end)

-- 7. CinematicsTickedNotify — cutscene tick (via entity_cxx.Skeleton directly)
entity_cxx.Skeleton:BindEvent("CinematicsTickedNotify", ...)

-- 8. CinematicsActorDisplayNotify — cutscene actor display
entity_cxx.Skeleton:BindEvent("CinematicsActorDisplayNotify", ...)
```
- **Why it matters:** `ActorComponent` supports 8 known event types. `BoneCollisionNotify` is one of 3 collision-related events. `PhysicsCollisionNotify` handles sweep/raycast projectile collisions (different from bone overlap). `SignalNotify` is the general animation cue system. All events are fired by the C++ tick pipeline.
- **Evidence Confidence:** 5/5 — All directly from source.

---

### Evidence 2.6 — ActorComponent: Full Collision-Related Method API

- **Source:** `hexm/client/entities/local/component/anim.lua` (various lines)
- **Summary of all collision-relevant `_actor_cxx:XXX` calls:**

| Method/Property | Line | Purpose |
|---|---|---|
| `.eid = owner.id` | 69 | Stamps entity ID for collision result attribution |
| `:BindEvent("BoneCollisionNotify", cb)` | 372 | Registers Lua callback for bone collision |
| `:BindEvent("PhysicsCollisionNotify", cb)` | 378 | Registers Lua callback for physics collision |
| `:SetEnableColliderQuery(enable)` | 366 | Enables/disables this entity as a collision **target** |
| `:GetCollisionSkeletonBoundingSphereRadius()` | 2456 | Returns bounding sphere of collision shapes |
| `:IsCollisionSkeletonAnomaly()` | 2463 | Anti-cheat: detects collision shape tampering |
| `.SkeletonViewer:set_drawCollisionSkeleton(false)` | 234 | Debug: visualize collision skeleton |
| `:PrepareRagdollHolder()` | 2250 | Allocates ragdoll physics for this skeleton |
| `:GetBoneTransform(bone_name)` | 1594 | Gets local-space bone transform |
| `:GetBoneWorldTransform(bone_name)` | 1603 | Gets world-space bone transform |
| `:HasBone(bone_name)` | 1613 | Checks if bone exists in skeleton |
| `:SetTargetPoint(pos)` | 1469 | Sets IK/collision target point |
| `:SetTargetPointToBone(target_cxx, bone)` | 1509 | Sets target to another skeleton's bone |
| `:AddTarget(actor_cxx)` | 1364 | Adds another actor as collision/IK target |
| `:DelTarget(actor_cxx)` | 1374 | Removes collision/IK target |
| `:ClearTargets()` | 1424 | Removes all targets |
| `.ApplyMotion` | 435/442 | Whether bone motion drives entity transform |
| `.EnableTickBeforePhyX` | 2275 | Tick order: before physics simulation |

- **Evidence Confidence:** 5/5 — All directly from source.

---

### Evidence 2.7 — Alternate BoneCollisionNotify Bindings (Bullet, Particle, Koi)

**BulletCharCtrl path:**
- **Source:** `hexm/client/entities/local/common_members/bullet_charctrl.lua` lines 27-84
- **Excerpt:**
```lua
function BulletCharCtrl:__post_component__(bdata)
    local skeleton = self.entity_cxx.Skeleton
    if skeleton then
        skeleton:BindEvent("BoneCollisionNotify", function(res)
            self:bone_collision(res)
        end)
    end
end

function BulletCharCtrl:bone_collision(res)
    local hit_bone_name = res[1].boneName
    local eid = res[1].actor.eid
    local e = G.space:get_entity(eid)
    self:on_bullet_hit(true, eid, res[1].hitPos, nil, weakpoint_id)
end
```
- **Why it matters:** Bullet entities with `CharCtrl` (physics-driven projectiles) bind `BoneCollisionNotify` directly on their `entity_cxx.Skeleton` and handle the collision result immediately — no dispatcher relay. The bullet reads the first result's `actor.eid` and calls `on_bullet_hit` to apply damage.

**ParticleManager path:**
- **Source:** `hexm/client/manager/particle_manager.lua` lines 951-953, 1887-2025
- **Excerpt:**
```lua
entity.Skeleton:BindEvent("BoneCollisionNotify", function(res)
    self:_bone_collision(res, callback, entity)
end)
```
- **Why it matters:** Particle entities (graph-driven projectiles like arrows, spells) also bind `BoneCollisionNotify` directly. The particle manager handles the hit by resolving targets, checking weapon collision names, and calling `_on_particle_hit`. Particles set graph variables (`CollisionRadius`, `CollisionFilter`, `CollisionDelay`, `CollisionFollow`) to configure the C++ collision shape at launch time.

**Particle collision graph variables:**
- **Source:** `hexm/client/manager/particle_manager.lua` lines 710-713
- **Excerpt:**
```lua
entity.Skeleton:SetVariable(0, "CollisionDelay", collision:get("delay_enable", 0), false)
entity.Skeleton:SetVariable(0, "CollisionFollow", collision_follow, false)
entity.Skeleton:SetVariable(0, "CollisionRadius", collision.radius, false)
entity.Skeleton:SetVariable(0, "CollisionFilter", collision_mask, false)
```
- **Why it matters:** This reveals how the C++ animation graph configures collision at runtime. The graph reads these variables to activate collision shapes at the right time with the right parameters. `CollisionDelay` = delay before detection activates (frames after launch). `CollisionRadius` = sphere radius of the collision check. `CollisionFilter` = bitmask filtering which collision layers to test against. `CollisionFollow` = whether the collision shape follows the particle's trajectory.

**KoiEntityMember path:**
- **Source:** `hexm/client/entities/local/koi_members/imp_anim.lua` lines 11-24
- **Excerpt:**
```lua
function KoiEntityMember:__skeleton_ready_component__()
    self:bind_collision_notify(function(result)
        self._bone_collision_cb(result)
    end)
end
```
- **Why it matters:** Koi (companion/pet) entities bind collision with a custom callback passed during init.

- **Evidence Confidence:** 5/5 — All direct definitions.

---

### Evidence 2.8 — Primary Binding Path: `SkillBase.__skeleton_ready_component__`

- **Source:** `hexm/client/combat/skill_base.lua` lines 6-16
- **Excerpt:**
```lua
function SkillBase:__skeleton_ready_component__()
    self.anim:bind_collision_notify(function(results)
        self:_on_bone_collision_cb(results)
    end)
end

function SkillBase:_on_bone_collision_cb(results)
    if self.dispatcher then
        self.dispatcher:dispatch(events.E_BONE_COLLISION, { ["results"] = results })
    end
end
```
- **Why it matters:** When the entity's skeleton finishes loading, `SkillBase` immediately binds the collision notify. The callback wraps the raw C++ results into a `{ results = ... }` table and dispatches `events.E_BONE_COLLISION` (`"e_bone_collision"`) through the entity's event dispatcher. This is the **primary path** for player and NPC entities with combat capability.
- **Evidence Confidence:** 5/5

---

### Evidence 2.9 — Alternate Binding Paths (Weapon, AttachModel, Special Nodes)

**Weapon path:**
- **Source:** `hexm/client/entities/local/weapon_members/imp_be_weapon.lua` lines 25-27, 147-152
- **Excerpt:**
```lua
self:bind_collision_notify(function(results)
    return self:_on_bone_collision(results)
end)

function WeaponMember:_on_bone_collision(results)
    local owner = self:get_owner()
    owner.dispatcher:dispatch(events.E_BONE_COLLISION, { ["weapon"] = self, ["results"] = results })
end
```
- **Why it matters:** Weapon entities have their own collision skeleton. When a weapon bone collider hits a target, the weapon forwards the event to its **owner's** dispatcher as `E_BONE_COLLISION`, adding `["weapon"] = self` to the payload.

**AttachModel path:**
- **Source:** `hexm/client/entities/local/common_members/attach_model_base.lua` lines 268, 276-286
- **Excerpt:**
```lua
entity.anim:bind_collision_notify(function(results)
    return self:_attach_model_bone_collision(results)
end)

function AttachModelBase:_attach_model_bone_collision(results)
    -- filters out self-hits
    self.dispatcher:dispatch(events.E_BONE_COLLISION, { ["results"] = final_result })
end
```

**BindInteractBoneColider (special_nodes):**
- **Source:** `hexm/common/actionline/nodes/special_nodes.lua` lines 2730-2736
- **Excerpt:**
```lua
com.anim:bind_collision_notify(function(results)
    if entity.al_driver:check_main_AL(self.al_id) then
        entity.dispatcher:dispatch(events.E_BONE_COLLISION, { ["results"] = results })
    end
end)
```
- **Why it matters:** An actionline node binds collision on a companion entity and forwards the result to the skill-owning entity's dispatcher.

- **Evidence Confidence:** 5/5 — All are direct definitions.

---

### Evidence 2.10 — Event Constant Definition

- **Source:** `hexm/common/consts/events.lua` line 67
- **Excerpt:**
```lua
_M.E_BONE_COLLISION = "e_bone_collision"
```
- **Evidence Confidence:** 5/5

---

### Evidence 2.11 — Listener Registration: `BoneCollisionBase:start`

- **Source:** `hexm/common/actionline/nodes/logic_nodes.lua` lines 1336-1384
- **Excerpt:**
```lua
function BoneCollisionBase:start(graph)
    local context = graph.context
    local entity = context.entity
    -- ...
    if enable_bone_collision then
        self.lis = helper.add_listener(entity.dispatcher, events.E_BONE_COLLISION, function(e, d)
            self:on_bone_hit(graph, d)
        end)
    end
    -- ...
    if not entity.fake_server then
        self.sync_bone_hit = helper.add_listener(entity.dispatcher, events.E_SKILL_BONE_HIT, function(e, d)
            self:on_sync_bone_hit(sync_id, graph, d)
        end)
    end
    -- ...
    local colliders = entity.skill_driver:get_ex_data("colliders")
    colliders:update(self.colliders_data)
end
```
- **Why it matters:** When an actionline `BoneCollision` or `BatchBoneCollision` node starts, it registers a listener on the entity's dispatcher for `E_BONE_COLLISION`. When the dispatcher fires the event, it calls `self:on_bone_hit(graph, d)` where `d` is `{ results = <raw C++ results> }`. It also registers `colliders_data` (collider configs like name, calcpoint_id, max_num, max_same_hit, etc.) into the entity's `skill_driver` ex_data.
- **Evidence Confidence:** 5/5

---

### Evidence 2.12 — Hit Processing: `BoneCollisionBase:on_bone_hit`

- **Source:** `hexm/common/actionline/nodes/logic_nodes.lua` lines 1432-1587
- **Excerpt (key steps):**
```lua
function BoneCollisionBase:on_bone_hit(graph, d)
    -- 1) Iterate d.results
    -- 2) For each result, resolve actor.eid -> target entity via entity.space:get_entity(tid)
    -- 3) Match result.colliderName against self.colliders_data
    -- 4) Apply hit count limits (max_num, max_same_hit), cooldown (tg_cd), target filtering (tg_filter_id)
    -- 5) Collect valid targets per collider name
    -- 6) Call self:on_hit_targets(graph, name, tgs, info)
    -- 7) Report hits to server via self:report_hit(...)
end
```
- **Why it matters:** This is the core hit resolution logic. It validates each collision result against the collider configuration (calcpoint_id, max_num, max_same_hit, min_interval cooldown), filters targets, and then dispatches to `on_hit_targets` which calls `DamageManager:process_calcpoint(...)` to apply damage.
- **Evidence Confidence:** 5/5

---

### Evidence 2.13 — Damage Application: `BoneCollisionBase:on_hit_targets`

- **Source:** `hexm/common/actionline/nodes/logic_nodes.lua` lines 1856-1978
- **Excerpt:**
```lua
function BoneCollisionBase:on_hit_targets(graph, collider, targets, hit_info)
    local cld = self.colliders_data:get(collider)
    if 0 ~= cld.calcpoint_id then
        local DM = DamageManager()
        for _, tg in pairs(tgs) do
            DM:process_calcpoint(cld.calcpoint_id, attacker, { tg }, context, skill_id, params)
        end
    end
    -- optionally start target timelines (if self.timelineID set)
end
```
- **Why it matters:** This is the final step where actual damage calculation occurs via `DamageManager:process_calcpoint`, using the `calcpoint_id` from the collider data. This triggers the behit/damage pipeline visible in logs as `BehitWithoutAnim`.
- **Evidence Confidence:** 5/5

---

### Evidence 2.14 — Log Correlation

- **Source:** `Scripts/logs/script_debug.txt`
- **Excerpt (first ON_BONE_HIT at 14:34:06):**
```
ON_BONE_HIT | actor="aaqDVl6fk2w8KA1s" colliderData={bind=true, calcpoint_id=230004201, collider_name="C1", ...}
    rsHitPos="(138.3907, 52.3999, 250.9058)"
    rsHitBone="Bip001 Pelvis-Bip001 Spine2"

>>>>>>>>>>>> TRY_USE_PARRY called from on_bone_hit

CLIENT_EVENT | >>>>>>>>> NPC Event: E_BEHIT_BEGAN - Code: 531
CLIENT_EVENT | >>>>>>>>> NPC Event: E_DAMAGE_BEHIT_BEGAN - Code: 533

IN*| BehitWithoutAnim | args={1890, 1890, "aWHEttFIAUazfw08", 2300042, 230004201, ...
    {27, {138.39..., 52.39..., 250.90...}, ...}}
```
- **Why it matters:** The log confirms the full dispatch chain in real time:
  1. `ON_BONE_HIT` is logged by the sync_observer hook intercepting `BoneCollision:on_bone_hit`
  2. The collider data matches what `BoneCollisionBase:start` registered (`C1`, `calcpoint_id=230004201`)
  3. `TRY_USE_PARRY` fires (auto-parry feature in sync_observer)
  4. `E_BEHIT_BEGAN` / `E_DAMAGE_BEHIT_BEGAN` events fire (from DamageManager pipeline)
  5. `BehitWithoutAnim` sync carries the damage (1890) and the hit position from the bone collision
- **Evidence Confidence:** 5/5

---

### Evidence 2.15 — Hook Mechanism (sync_observer)

- **Source:** `Scripts/actions/sync_observer.lua` lines 476-506, 583-588
- **Excerpt:**
```lua
local function _intercept_on_bone_hit(spec, args, results, traceback)
    local self = args[1]    -- BoneCollision/BatchBoneCollision instance
    local graph = args[2]
    local d = args[3]       -- { results = <collision results> }
    for _, result in pairs(d.results) do
        local cld_name = result.colliderName
        local cld = self.colliders_data:get(cld_name)
        _log("ON_BONE_HIT | actor=%s colliderData=%s rsHitPos=%s ...", ...)
    end
end

-- Hooked on:
{ spec = "hexm.common.actionline.nodes.logic_nodes:BoneCollision:on_bone_hit", post_exec = _intercept_on_bone_hit },
{ spec = "hexm.common.actionline.nodes.logic_nodes:BatchBoneCollision:on_bone_hit", post_exec = _intercept_on_bone_hit },
```
- **Why it matters:** Confirms `ON_BONE_HIT` log entries are a `post_exec` hook on `BoneCollision:on_bone_hit` and `BatchBoneCollision:on_bone_hit` — they fire **after** the real `on_bone_hit` has already processed.
- **Evidence Confidence:** 5/5


## 3. Conclusions (Score >= 3 only)

### Full Dispatch Chain

```
┌─────────────────────────────────────────────────────────────────────┐
│  C++ ActorComponent (engine-level)                                  │
│                                                                     │
│  Created: MObject.CreateObject("ActorComponent")                    │
│  Stamped: _actor_cxx.eid = owner.id                                │
│                                                                     │
│  Collision skeleton: loaded from .skeleton asset                    │
│  Collision shapes: capsules/spheres on bones (editor-authored)      │
│  Collider names: "C1","C2","C3"... from animation graph nodes      │
│                                                                     │
│  During each animation tick:                                        │
│    1. Evaluates animation graph → updates bone transforms           │
│    2. If collision shapes active in graph state:                    │
│       - Tests attacker's collider shapes vs target's collision skel │
│       - For each overlap: records {actor(.eid), colliderName,      │
│         hitPos, hitNormal, hitDir, boneName}                        │
│    3. Fires "BoneCollisionNotify" with results array                │
│                                                                     │
│  Pre-conditions:                                                    │
│    - IsReady = true (skeleton loaded)                              │
│    - Target: SetEnableColliderQuery not disabled                   │
│    - Attacker: graph state activates collision shape                │
└────────────────┬────────────────────────────────────────────────────┘
                 │
    ═══ PATH A: Entity (Player/NPC) ═══════════════════════
                 │
                 ▼
    Anim:bind_collision_notify(callback)          [anim.lua:370]
                 │  _actor_cxx:BindEvent("BoneCollisionNotify", callback)
                 │
                 ├─► SkillBase._on_bone_collision_cb       [skill_base.lua:12]
                 │      wraps results → dispatches E_BONE_COLLISION
                 │
                 ├─► WeaponMember._on_bone_collision       [imp_be_weapon.lua:147]
                 │      forwards to owner.dispatcher as E_BONE_COLLISION
                 │
                 ├─► AttachModelBase._attach_model_bone_collision [attach_model_base.lua:276]
                 │      filters self-hits → dispatches E_BONE_COLLISION
                 │
                 ├─► KoiEntityMember._bone_collision_cb    [koi imp_anim.lua:13]
                 │      custom callback from init bdict
                 │
                 └─► BindInteractBoneColider               [special_nodes.lua:2730]
                        forwards to skill entity dispatcher as E_BONE_COLLISION
                 │
                 ▼
    entity.dispatcher:dispatch("e_bone_collision", { results = ... })
                 │
                 ▼
    BoneCollisionBase:start() listener            [logic_nodes.lua:1359]
                 │  helper.add_listener(entity.dispatcher, E_BONE_COLLISION, ...)
                 │
                 ▼
    BoneCollisionBase:on_bone_hit(graph, d)       [logic_nodes.lua:1432]
                 │  1. Iterates d.results
                 │  2. Matches colliderName → self.colliders_data
                 │  3. Validates hit counts, cooldowns, target filters
                 │  4. Collects valid targets per collider
                 │
                 ▼
    BoneCollisionBase:on_hit_targets(...)          [logic_nodes.lua:1856]
                 │  DamageManager:process_calcpoint(calcpoint_id, attacker, targets, ...)
                 │  Optionally starts target timelines
                 │
                 ▼
    DamageManager pipeline → BehitWithoutAnim sync → E_BEHIT_BEGAN events

    ═══ PATH B: Bullet (CharCtrl) ════════════════════════
                 │
    entity_cxx.Skeleton:BindEvent("BoneCollisionNotify", ...)
                 │                                         [bullet_charctrl.lua:31]
                 ▼
    BulletCharCtrl:bone_collision(res)            [bullet_charctrl.lua:73]
                 │  reads res[1].actor.eid → on_bullet_hit(...)
                 ▼
    Direct damage application (no dispatcher relay)

    ═══ PATH C: Particle (Graph-driven projectile) ═══════
                 │
    entity.Skeleton:BindEvent("BoneCollisionNotify", ...)
                 │                                         [particle_manager.lua:951]
                 │  Graph variables configure collision at launch:
                 │    CollisionRadius, CollisionFilter,
                 │    CollisionDelay, CollisionFollow
                 ▼
    ParticleManager:_bone_collision(res, callback, entity)
                 │                                         [particle_manager.lua:1887]
                 │  resolves targets, checks weakpoints, calls _on_particle_hit
                 ▼
    Particle hit pipeline → damage/destroy
```

### Key Observations from Logs

1. **Player skill 2300042** (first hit at 14:34:06): Player's entity (`aWHEttFIAUazfw08`) attacked NPC (`aaqDVl6fk2w8KA1s`) with `calcpoint_id=230004201`, collider `"C1"`, hit bone `"Bip001 Pelvis-Bip001 Spine2"`. Resulted in 1890 damage via `BehitWithoutAnim`.

2. **NPC skill 77031107** (hits at 14:34:14): NPC attacked player with `calcpoint_id=7703110701`, colliders `"C2"` and `"C3"`, hitting bones like `"Bip001 Pelvis-Bip001 Spine2"` and `"Bip001 R UpperArm-Bip001 R Forearm"`. First hit triggered parry (skill 23717001/23717011).

3. **colliderData=nil** entries (e.g., at 14:34:18 242.521): These occur when a result's `colliderName` does not match any entry in `self.colliders_data`. The `on_bone_hit` method simply skips these — no damage is applied.

4. **Two ON_BONE_HIT for same frame** (e.g., 14:34:18 242.52 and 242.521): This indicates both a `BoneCollision` and `BatchBoneCollision` node are listening simultaneously. The first finds a matching collider (`C2`), the second does not (`colliderData=nil`).

5. **Timing**: Between `ON_BONE_HIT` and `BehitWithoutAnim` there is typically ~50-70ms, during which `DamageManager:process_calcpoint` runs server damage calculation and the sync system dispatches behit.


## 4. Unknown / Missing Evidence

- **C++ collision shape activation**: Exact mechanism by which animation graph states activate/deactivate collider shapes (named "C1", "C2", etc.) during skill animations is opaque C++. The graph likely has collision nodes that are enabled by state transitions.
- **Collision skeleton asset format**: The `.skeleton` asset contains both the render skeleton and the collision skeleton (simplified capsule/sphere hierarchy), but the binary format is not accessible from Lua.
- **BoneCollisionNotify tick frequency**: Whether collision is evaluated every frame or throttled by `SetFrameLimit`/`SetInvisibleFrameLimit` is unknown from Lua side.
- **DamageManager:process_calcpoint internals**: The damage calculation pipeline from calcpoint to final behit numbers was not traced.
- **SetEnableColliderQuery semantics**: Whether this controls the entity as a collision **source** (attacker) or **target** is inferred but not confirmed — the only usage disables it on player avatars at skeleton ready, suggesting it controls target queryability (preventing the player from being queried as a source by default).


---

## 3. Bone-Hit Timing Prediction Analysis

### 3.1 Question / Scope

How do we predict the timing before the player gets hit by an NPC bone-collision skill?
What observable signals arrive before the actual `ON_BONE_HIT`, and how consistent are the timing deltas per `skill_id`?

---

### Evidence 3.1 — Full Timing Extraction from `full_traces.txt`

- **Source:** `Scripts/logs/full_traces.txt` (1058 lines, combat session with NPC `no=22000071`)
- **Entities:** NPC = `aaqDVl6fk2w8KA1s`, Player = `aWHEttFIAUazfw08`

Below is the complete timeline of every NPC skill instance observed, with timestamps extracted from the log's second column (engine frame time in seconds).

#### 3.1.1 — Skill 77031107 (4 samples, bone collision)

This is the most-frequently-observed NPC attack. It uses **BoneCollision** nodes with colliders C2 and C3.

| Sample | E_SKILL_START (s) | First ON_BONE_HIT C2 (s) | Δ to C2 | Second ON_BONE_HIT C3 (s) | Δ to C3 | SkillEnd (s) | Total Duration |
|--------|-------------------|---------------------------|---------|----------------------------|---------|--------------|----------------|
| 1      | 237.418           | 238.401                   | **0.983** | 238.701                  | **1.283** | 239.90      | 2.48s          |
| 2      | 244.952           | 245.937                   | **0.985** | 246.237                  | **1.285** | 247.44      | 2.49s          |
| 3      | 257.188           | 258.173                   | **0.985** | 258.482                  | **1.294** | 259.68      | 2.49s          |
| 4      | 267.759           | 268.755                   | **0.996** | 269.057                  | **1.298** | ~270.0      | ~2.24s         |
| **Mean** |                 |                           | **0.987** |                          | **1.290** |             |                |
| **StdDev** |               |                           | **±0.006** |                         | **±0.007** |            |                |

**Key finding:** Timing from `E_SKILL_START` to first bone hit is **deterministic to within ~6ms** across 4 independent executions of the same skill.

- **Evidence Confidence:** 5/5 — 4 independent samples, sub-10ms variance.

---

#### 3.1.2 — Skill 77031106 (1 sample, 2-phase bone collision)

This skill has two animation phases (`_1`, `_2`), each with its own bone-collision hit.

| Phase | Anim Name           | Phase Start (s) | ON_BONE_HIT | Δ from E_SKILL_START | Δ from Phase Start |
|-------|---------------------|-----------------|-------------|----------------------|---------------------|
| 1     | skill_77031106_1    | 240.402         | C1 @ 241.302 | **0.901s**           | 0.901s             |
| 2     | skill_77031106_2    | 241.984         | C2 @ 242.520 | **2.119s**           | 0.536s             |
| 2     | skill_77031106_2    | 241.984         | C3 @ 242.820 | **2.419s**           | 0.836s             |

Total skill duration: 240.401 → 244.469 = **4.07s**

- **Evidence Confidence:** 4/5 — Single sample but internally consistent.

---

#### 3.1.3 — Skill 77031105 (1 sample, 2-phase bone collision with `bind=true`)

This skill uses `bind=true` colliders (colliders attached to the skeleton), and has `max_time=2.6`.

| Phase | Anim Name           | Phase Start (s) | ON_BONE_HIT | Δ from E_SKILL_START | Δ from Phase Start |
|-------|---------------------|-----------------|-------------|----------------------|---------------------|
| 1     | skill_77031105_1    | 252.944         | C1 @ 253.682 | **0.738s**           | 0.738s             |
| 2     | skill_77031105_2    | 254.049         | C2 @ 254.633 | **1.689s**           | 0.584s             |

Total skill duration: 252.944 → 256.705 = **3.76s**

- **Evidence Confidence:** 4/5 — Single sample.

---

#### 3.1.4 — Skill 77031201 (1 sample, hybrid: server calcpoint + bone collision)

This skill mixes server-authoritative calcpoint hits with bone-collision hits in phase 2.

| Hit Type       | What          | Timestamp (s) | Δ from E_SKILL_START |
|---------------|---------------|---------------|----------------------|
| Server CP     | cp=7703120101  | 249.105       | **1.185s**          |
| E_GD_SIGNAL   | Gedang signal  | 249.120       | **1.200s**          |
| Bone Hit C1   | cp=7703120102  | 249.473       | **1.553s**          |
| Bone Hit C2   | cp=7703120102  | 249.958       | **2.038s**          |
| Server CP     | cp=7703120103  | 250.729       | **2.809s**          |

Total skill duration: 247.920 → 252.926 = **5.01s**

- **Evidence Confidence:** 4/5 — Single sample; shows important hybrid pattern.

---

#### 3.1.5 — Skill 77031108 (1 sample, server calcpoint only, NO bone collision)

This is a multi-hit combo (6 animation phases, ~10 server calcpoint hits). **No ON_BONE_HIT fired.**

| Hit Type       | What               | Timestamp (s)  | Δ from E_SKILL_START |
|---------------|--------------------|----------------|----------------------|
| E_GD_SIGNAL   | Gedang signal       | 262.567        | **1.903s**           |
| Server CP × 1 | First cp=7703110801 | 262.716        | **2.052s**           |
| Server CP × 9 | Subsequent hits     | 263.228–267.287 | 2.564–6.623s        |

Total skill duration: 260.664 → 267.758 = **7.09s**

**This skill is NOT predictable via bone collision interception — it uses server-side calcpoints only.**

- **Evidence Confidence:** 5/5 — No bone hit events in the entire skill execution.

---

#### 3.1.6 — Skill 77031211 (1 sample, server calcpoint only, NO bone collision)

| Hit Type       | What               | Timestamp (s)  | Δ from E_SKILL_START |
|---------------|--------------------|----------------|----------------------|
| E_GD_SIGNAL   | Gedang signal       | 232.516        | **1.481s**           |
| Server CP × 1 | First cp=7703121101 | 232.602        | **1.567s**           |
| Server CP × 4 | Subsequent hits     | 233.102–234.420 | 2.067–3.385s        |

Total skill duration: 231.035 → 237.35 = **6.32s**

- **Evidence Confidence:** 4/5 — Single sample.

---

### Evidence 3.2 — Observable Prediction Signals (Code Analysis)

From the traces and source code, these signals arrive **before** the bone hit and are interceptable in Lua:

| Signal                       | When it fires (relative to bone hit)    | How to intercept                                                      | Reliability |
|-----------------------------|-----------------------------------------|-----------------------------------------------------------------------|-------------|
| **E_SKILL_START** (355)      | ~0.7–1.0s before first bone hit         | `npc.dispatcher:add(events.E_SKILL_START, callback)`                  | Best — earliest, most reliable |
| **E_SKILL_ANIM_BEGIN_CLIENT**| Same frame as E_SKILL_START             | `npc.dispatcher:add("e_skill_anim_begin_client", callback)`           | Redundant with above |
| **SyncSkill:skill (IN)**     | Same frame as E_SKILL_START             | Hook `SyncSkill:skill` or intercept `do_sync` for the NPC entity      | Best — carries `skill_id` directly in args |
| **EX_DATA_SET colliders={}** | Same frame, after BoneCollision:start   | Hook `SkillDriver:set_ex_data` with key filter                        | Confirms bone collision is armed |
| **EX_DATA_SET cur_anim**     | Same frame, carries animation name      | Hook `SkillDriver:set_ex_data` with key filter                        | Gives animation name for lookup |
| **EX_DATA_SET cur_anim_start_ts** | Same frame, carries server timestamp | Hook `SkillDriver:set_ex_data` with key filter                       | Gives authoritative anchor time |
| **E_GD_SIGNAL**              | ~0.05–0.15s before first hit (server CP skills) | `npc.dispatcher:add(events.E_GD_SIGNAL, callback)`            | Late — only useful for server-CP skills |
| **E_SKILL_ANIM_BEGIN_CLIENT (phase N)** | On animation transition      | `npc.dispatcher:add("e_skill_anim_begin_client", callback)`           | Useful for multi-phase skills |

- **Source:** `hexm/common/consts/events.lua` line 27, `hexm/common/combat/skill_ctrl.lua` (E_SKILL_START dispatch), `hexm/common/actionline/nodes/logic_nodes.lua` lines 1304-1327 (E_GD_SIGNAL dispatch)
- **Evidence Confidence:** 5/5 — Direct code + log correlation.

---

### Evidence 3.3 — `E_GD_SIGNAL` Dispatch Mechanism

- **Source:** `hexm/common/actionline/nodes/logic_nodes.lua` lines 1304-1327
- **Excerpt:**
```lua
function BoneCollisionBase:trigger_gd_signal(context, entity)
    entity.al_driver:request_reboot(context.identifier .. "MPRE", function(data)
        local cal_id, min_k
        for k, d in pairs(self.colliders_data) do
            if not min_k or k < min_k then
                min_k = k
                cal_id = d.calcpoint_id
            end
        end
        if cal_id then
            entity.dispatcher:dispatch(events.E_GD_SIGNAL, {
                entity = entity, cal_id = cal_id, skill_id = context.skill_id,
            })
        end
    end)
end
```
- **Why it matters:** `E_GD_SIGNAL` is dispatched via `request_reboot` (async callback scheduled on the next actionline tick), which is why it fires slightly **before** the actual calcpoint hit — it signals to the NPC AI system ("gedang" = parry/defend) that an attack is incoming, giving the AI a chance to react. This same signal can be intercepted by the player's defense system.
- **Evidence Confidence:** 5/5 — Direct code.

---

### Evidence 3.4 — `E_GD_SIGNAL` Consumer: NPC Parry AI

- **Source:** `hexm/common/AI/nodes/common_action_nodes/combat_nodes.lua` lines 71-84
- **Excerpt:**
```lua
function NpcGeDangDecorator:start(entity, data)
    self._target_listener =
        self:add_node_dispatcher_event(target.dispatcher, events.E_GD_SIGNAL, "npc_gedang_event_callback")
end
function NpcGeDangDecorator:npc_gedang_event_callback(event, data)
    -- NPC parry/block decision based on E_GD_SIGNAL
end
```
- **Why it matters:** The NPC AI itself uses `E_GD_SIGNAL` to decide when to parry. This means the signal is designed as a **pre-hit warning** and is architecturally the correct event for prediction.
- **Evidence Confidence:** 5/5 — Direct code showing intended usage.

---

### Evidence 3.5 — Actionline Timeline Data (DirObject: `AL.skill.boss_duoren_wxh`)

The authoritative source for **when** each BoneCollision node arms is the actionline timeline data from `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.AL.skill.boss_duoren_wxh.json`. Below is the exact timeline decomposition for each observed NPC skill.

- **Evidence Confidence:** 5/5 — Direct authoritative data.

#### Skill 77031107 — Timeline Decomposition

```
StartGraph: 1
  Graph 1: PrepareSkillNode(6) → SkillRelease(7) → SkillTimelineNode(8, tl=20)
  Graph 2: AnimationNode(9, anim="skill_77031107", trans_time=0.5)
           + BatchBoneCollision(11) ← BoneCollisionData C2(10) + C3(12)
           + SkillTimelineNode(13, tl=21)

Timeline 20:
  t=0.000 → Graph 2    ◄── BoneCollision ARMED, animation begins (0.5s blend)

Timeline 21:
  t=2.414 → Graph 3 (SKILL_MOVEPOST)
  t=2.549 → Graph 4 (SKILL_POST)
  t=3.070 → Graph 5 (SKILL_END)

COMPUTED:  bone collision armed at T+0.000s
OBSERVED: first bone hit (C2) at T+0.987s → animation_reach_time = 0.987s
OBSERVED: second bone hit (C3) at T+1.290s → animation_reach_time = 1.290s
```

**Key:** `animation_reach_time` = time from animation start to when collision shapes overlap the target. This is embedded in the binary animation asset `skill_77031107`, NOT in any Lua/JSON data we have.

#### Skill 77031106 — Timeline Decomposition

```
StartGraph: 1
  Graph 1: SkillTimelineNode(tl=44)
  Graph 2: AnimationNode(anim="skill_77031106_1", trans_time=0.5)
           + BoneCollisionData C1 (cp=7703110601) + BatchBoneCollision
           + SkillTimelineNode(tl=45)
  Graph 3: AnimationNode(anim="skill_77031106_2", trans_time=0.5)
           + BoneCollisionData C2+C3 (cp=7703110601) + BatchBoneCollision
           + SkillTimelineNode(tl=46)

Timeline 44:
  t=0.004 → Graph 2    ◄── Phase 1: C1 bone collision ARMED
  t=1.576 → Graph 3    ◄── Phase 2: C2+C3 bone collision ARMED

Timeline 45:
  t=0.064 → Graph 4

Timeline 46:
  t=2.414 → SKILL_MOVEPOST
  t=2.549 → SKILL_POST
  t=3.070 → SKILL_END

COMPUTED:  phase 1 bone collision armed at T+0.004s
OBSERVED: C1 hit at T+0.901s → animation_reach_time = 0.897s

COMPUTED:  phase 2 bone collision armed at T+1.576s
OBSERVED: C2 hit at T+2.119s → animation_reach_time = 0.543s
OBSERVED: C3 hit at T+2.419s → animation_reach_time = 0.843s
```

#### Skill 77031105 — Timeline Decomposition

```
StartGraph: 2
  Graph 2: SkillTimelineNode(tl=40)
  Graph 3: AnimationNode(anim="skill_77031105_1", trans_time=0.5)
           + BoneCollision C1 (cp=7703110501, bind=true, max_time=2.6)
           + SkillTimelineNode(tl=39)
  Graph 22: AnimationNode(anim="skill_77031105_2", trans_time=0.5)
            + BoneCollision C2 (cp=7703110501)
            + SkillTimelineNode(tl=41)

Timeline 40:
  t=0.000 → Graph 3    ◄── Phase 1: C1 bone collision ARMED
  t=1.090 → Graph 22   ◄── Phase 2: C2 bone collision ARMED

Timeline 39: t=0.009 → Graph 1 (MOVEPRE)
Timeline 41: t=2.585 → MOVEPOST, t=3.123 → POST, t=3.671 → END

COMPUTED:  phase 1 bone collision armed at T+0.000s
OBSERVED: C1 hit at T+0.738s → animation_reach_time = 0.738s

COMPUTED:  phase 2 bone collision armed at T+1.090s
OBSERVED: C2 hit at T+1.689s → animation_reach_time = 0.599s
```

#### Skill 77031201 — Timeline Decomposition (Hybrid)

```
StartGraph: 4
  Graph 4: PrepareSkillNode → SkillRelease → SkillTimelineNode(tl=34)
  Graph 2: AnimationNode(anim="skill_77031201_1", trans_time=0.09) + SkillTimelineNode(tl=33)
  Graph 6: AnimationNode(anim="skill_77031201_2", trans_time=0.0)
           + BoneCollisionData C1+C2 (cp=7703120102) + BatchBoneCollision
           + SkillTimelineNode(tl=32)
  Graph 3: Attack (cp=7703120101)  ← server calcpoint
  Graph 9: Attack (cp=7703120103)  ← server calcpoint
  Graph 10: TriggerEvent (e_gd_signal, cal_id=7703120101)

Timeline 34:
  t=0.000 → Graph 2    ◄── Phase 1 animation starts (no bone collision)
  t=1.117 → Graph 6    ◄── Phase 2: C1+C2 bone collision ARMED

Timeline 32 (starts with Graph 6):
  Track 1: t=0.007 → Graph 3 (Attack cp=7703120101)    → absolute: T+1.124
           t=1.600 → Graph 9 (Attack cp=7703120103)    → absolute: T+2.717
  Track 3: t=0.000 → Graph 10 (e_gd_signal)            → absolute: T+1.117

COMPUTED:  bone collision armed at T+1.117s, first server CP at T+1.124s, e_gd_signal at T+1.117s
OBSERVED: first server CP hit at T+1.185s (data: 1.124, Δ=0.061s processing)
OBSERVED: e_gd_signal at T+1.200s (data: 1.117, Δ=0.083s async dispatch)
OBSERVED: C1 bone hit at T+1.553s → animation_reach_time = 0.436s
OBSERVED: C2 bone hit at T+2.038s → animation_reach_time = 0.921s
OBSERVED: last server CP at T+2.809s (data: 2.717, Δ=0.092s processing)
```

#### Skill 77031108 — Timeline Decomposition (Server Calcpoint Only)

```
StartGraph: 1
  SkillTimelineNode(tl=79)

Timeline 79 (4 tracks):
  Track 1 (animations):
    t=0.000 → Graph 2 (anim skill_77031108_1)
    t=2.078 → Graph 28 (anim _5)
    t=2.992 → Graph 29 (anim _4)
    t=3.900 → Graph 27 (anim _2)
    t=4.800 → Graph 26 (anim _3)
    t=5.700 → Graph 30 (anim _6)

  Track 3 (damage):
    CircleGraphKeyframe: graphID=44 (Attack cp=7703110801)
      first_time=1.986, interval=0.500, count=10
    → hits at: 1.986, 2.486, 2.986, 3.486, 3.986, 4.486, 4.986, 5.486, 5.986, 6.486

  Track 4 (pre-warning):
    t=1.886 → Graph 45 (e_gd_signal)

  Track 2 (state):
    t=7.002 → MOVEPOST, t=7.191 → POST, t=7.398 → END

COMPUTED:  e_gd_signal at T+1.886s, first Attack at T+1.986s
OBSERVED: e_gd_signal at T+1.903s (data: 1.886, Δ=0.017s)
OBSERVED: first hit at T+2.052s (data: 1.986, Δ=0.066s processing)

NO BONE COLLISION — this skill uses server Attack nodes with CircleGraphKeyframe for repeated hits.
```

---

### Evidence 3.6 — What is Computable vs What is Not

From the timeline data + trace correlation, the prediction window has **two components:**

```
Total Time to Hit = timeline_arm_time + animation_reach_time
                    ^^^^^^^^^^^^^^^^   ^^^^^^^^^^^^^^^^^^^^
                    COMPUTABLE         NOT COMPUTABLE
                    (from DirObject)   (from binary animation asset)
```

#### COMPUTABLE from DirObject (exact):

| Data Point                          | Source                                              |
|-------------------------------------|-----------------------------------------------------|
| When BoneCollision node arms        | Timeline keyframe `time` for the graph containing the node |
| When server Attack fires            | Timeline keyframe `time` for Attack graph            |
| When E_GD_SIGNAL dispatches         | Timeline keyframe `time` for TriggerEvent graph      |
| Animation transition blend time     | AnimationNode `trans_time` field                     |
| Multi-phase transition times        | Timeline keyframes for each phase graph              |
| Skill total duration                | Timeline keyframe for SKILL_END graph                |
| Server calcpoint hit schedule       | `CircleGraphKeyframe` fields: `time`, `interval`, `times` |

#### NOT COMPUTABLE (missing data):

| Data Point                          | Why it's missing                                     |
|-------------------------------------|-----------------------------------------------------|
| **`animation_reach_time`**          | Embedded in the binary animation asset (`.graph` skeleton animation). This is the time from animation start to when the C++ skeleton's collision capsule shapes physically overlap the target's collision shapes. Depends on: bone transform keyframes, collision capsule placement in skeleton editor, entity distance, attack range. |
| Animation keyframe data             | Binary engine format, not in Lua/JSON data           |
| Collision capsule geometry           | Defined in `.skeleton` binary asset                  |

#### Measured `animation_reach_time` per animation (from traces):

| Animation Asset              | Collider | animation_reach_time | Notes |
|------------------------------|----------|---------------------|-------|
| skill_77031107               | C2       | **0.987s** (±0.006) | 4 samples, very stable |
| skill_77031107               | C3       | **1.290s** (±0.007) | 4 samples, very stable |
| skill_77031106_1             | C1       | **0.897s**          | 1 sample |
| skill_77031106_2             | C2       | **0.543s**          | 1 sample |
| skill_77031106_2             | C3       | **0.843s**          | 1 sample |
| skill_77031105_1             | C1       | **0.738s**          | 1 sample |
| skill_77031105_2             | C2       | **0.599s**          | 1 sample |
| skill_77031201_2             | C1       | **0.436s**          | 1 sample |
| skill_77031201_2             | C2       | **0.921s**          | 1 sample |

---

### 3.2 Exact Prediction Formula

Given the above, the exact prediction formula for a bone-collision skill is:

```
time_to_hit = timeline_arm_time[skill_id][phase] + animation_reach_time[anim_name][collider]
              ─────────────────────────────────    ──────────────────────────────────────────
              FROM DirObject (exact)               FROM runtime measurement OR binary asset
```

For **server calcpoint skills**, the formula is simpler since Attack nodes fire on a fixed timeline:

```
time_to_hit = attack_keyframe_time[skill_id] + processing_overhead (~0.05-0.07s)
              ────────────────────────────────   ───────────────────────────────────
              FROM DirObject (exact)             Constant overhead (frame scheduling)
```

---

### 3.3 Compiled Timing Table (Per Skill ID)

Summary combining DirObject timeline data with empirical measurements:

| skill_id   | Hit Type    | Collider | timeline_arm (data) | anim_reach (measured) | Total Δ to Hit | Samples | Variance |
|------------|-------------|----------|--------------------|-----------------------|----------------|---------|----------|
| 77031107   | Bone        | C2       | 0.000s             | 0.987s                | **0.987s**     | 4       | ±0.006s  |
| 77031107   | Bone        | C3       | 0.000s             | 1.290s                | **1.290s**     | 4       | ±0.007s  |
| 77031106   | Bone (ph1)  | C1       | 0.004s             | 0.897s                | **0.901s**     | 1       | —        |
| 77031106   | Bone (ph2)  | C2       | 1.576s             | 0.543s                | **2.119s**     | 1       | —        |
| 77031106   | Bone (ph2)  | C3       | 1.576s             | 0.843s                | **2.419s**     | 1       | —        |
| 77031105   | Bone (ph1)  | C1       | 0.000s             | 0.738s                | **0.738s**     | 1       | —        |
| 77031105   | Bone (ph2)  | C2       | 1.090s             | 0.599s                | **1.689s**     | 1       | —        |
| 77031201   | Server CP   | —        | 1.124s (data)      | ~0.061s (overhead)    | **1.185s**     | 1       | —        |
| 77031201   | Bone        | C1       | 1.117s             | 0.436s                | **1.553s**     | 1       | —        |
| 77031201   | Bone        | C2       | 1.117s             | 0.921s                | **2.038s**     | 1       | —        |
| 77031108   | Server CP   | —        | 1.986s (data)      | ~0.066s (overhead)    | **2.052s**     | 1       | —        |
| 77031108   | E_GD_SIGNAL | —        | 1.886s (data)      | ~0.017s (overhead)    | **1.903s**     | 1       | —        |

---

### 3.3 Prediction Architecture

Based on the evidence, a bone-hit prediction system would work as follows:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PREDICTION TIMELINE                              │
│                                                                     │
│  T=0.000s    T≈0.000s         T≈0.000s           T≈0.7-1.0s       │
│  ┌──────┐    ┌───────────┐    ┌────────────┐     ┌──────────────┐  │
│  │SKILL │───>│ANIM_BEGIN  │───>│colliders={}│────>│ ON_BONE_HIT  │  │
│  │START │    │CLIENT      │    │(armed)     │     │ (damage)     │  │
│  │(355) │    │            │    │            │     │              │  │
│  └──┬───┘    └────────────┘    └────────────┘     └──────────────┘  │
│     │                                                    ▲          │
│     │  PREDICTION WINDOW: ~0.7-1.0s                      │          │
│     │                                                    │          │
│     │  ┌────────────────────────────────────────────┐    │          │
│     └──│ 1. Extract skill_id from SyncSkill args    │    │          │
│        │ 2. Lookup timing_table[skill_id]           │    │          │
│        │ 3. Schedule parry at T + Δ - reaction_time │    │          │
│        └────────────────────────────────────────────┘    │          │
│                                                          │          │
│  For multi-phase skills:                                 │          │
│  E_SKILL_ANIM_BEGIN_CLIENT fires per phase ─────────────>│          │
│  → Use phase_timing_table[skill_id][phase] for Δ        │          │
└─────────────────────────────────────────────────────────────────────┘
```

#### Interception Points (ranked by usefulness):

1. **`SyncSkill:skill` (IN message)** — Best. Fires on the NPC entity when the server syncs a new skill start. Contains `skill_id` in `args[1]` and `target_id` in kwargs. Already intercepted by `sync_observer.lua`.

2. **`E_SKILL_START` (event 355)** — Same frame as SyncSkill. Can be listened on any NPC's dispatcher. Carries skill context through the NPC's `skill_driver.ex_data`.

3. **`EX_DATA_SET key=colliders`** — Confirms bone collision is armed. If `colliders={}` is set, the skill will produce bone hits; if absent, the skill uses server calcpoints only.

4. **`E_SKILL_ANIM_BEGIN_CLIENT`** — Per-phase anchor for multi-phase skills. Essential for skills like 77031106 (2 phases) or 77031108 (6 phases).

#### Detection of Bone-Collision vs Server-Calcpoint Skills:

| Indicator                        | Bone Collision Skill            | Server Calcpoint Skill         |
|---------------------------------|---------------------------------|--------------------------------|
| `EX_DATA_SET key=colliders`     | Present (empty `{}` then fills) | Absent from ex_data            |
| `ON_BONE_HIT` fires             | Yes                             | No                             |
| `E_GD_SIGNAL` fires             | Sometimes                       | Always (before first CP hit)   |
| `TRY_USE_PARRY` logged          | Yes (from `on_bone_hit`)        | No                             |
| SyncSkill kwargs                | May have `arbiter_channels`     | Has `arbiter_channels`         |

From the traces, we can detect at `E_SKILL_START` time whether bone collision will be used by checking if `colliders` key appears in the `ex_data` within the same frame batch. If it does, the skill uses bone collision and timing is predictable from the table above.

---

### 3.4 Prediction Accuracy Summary

| Category                     | Accuracy          | Basis                                              |
|-----------------------------|-------------------|-----------------------------------------------------|
| Same skill_id, same collider | **±6-7ms**        | 4 samples of 77031107 show sub-10ms variance        |
| DirObject timeline_arm_time  | **Exact** (0ms)   | Deterministic from JSON data                        |
| Server Attack timing         | **±60-90ms**      | timeline_keyframe ± processing overhead             |
| E_GD_SIGNAL timing           | **±17-83ms**      | timeline_keyframe ± async dispatch overhead          |
| animation_reach_time (unknown skill) | **Not computable** | Requires binary animation asset OR runtime measurement |

**Answer to the question: "Can we compute the exact prediction window?"**

**Partially.** The prediction window decomposes into two parts:

1. **`timeline_arm_time`** — **Exactly computable** from DirObject JSON. This tells us precisely when the BoneCollision node activates within the skill's actionline timeline.

2. **`animation_reach_time`** — **NOT computable** from any available source (code or data). This is the time from when the animation starts playing to when the C++ skeleton's collision capsules physically overlap the target. It is encoded in the **binary animation asset** (`.graph` / `.skeleton` files authored in the engine's skeleton editor), which we do not have in decompiled form.

**However**, `animation_reach_time` is a **constant per animation asset + collider name**. Once measured empirically (from a single combat trace), it never changes. With `skill_speed=1.0` it is frame-deterministic to within **±6ms**.

**For server-calcpoint-only skills** (77031108, 77031211), the timing IS fully computable from DirObject alone — the `CircleGraphKeyframe` and `Attack` graph keyframes give exact hit schedules with only ~60-90ms processing overhead.

---

### 3.5 Player Response Skills (from traces)

The traces also reveal the player's automatic parry/counter system:

| Player Skill | Purpose                | Trigger                     | Response Time from Bone Hit |
|-------------|------------------------|-----------------------------|-----------------------------|
| 23717001    | Auto-dodge/behit react | Fires on every `ON_BONE_HIT` | **~0.066–0.068s** (same frame batch) |
| 23717011    | Parry counter          | Fires on `TRY_USE_PARRY`    | **~0.100–0.350s** (1-2 frames later) |

These are the player's _reactive_ skills. `23717001` fires immediately on every bone hit (behit reaction), while `23717011` is the active parry counter that fires when `TRY_USE_PARRY` succeeds (the `E_BE_PARRY` → `Parry` sync path).

---

### 3.6 Practical Implementation Notes

1. **Build the timing table at runtime:** Hook `SyncSkill:skill` on the NPC. On each skill execution, record `{skill_id, E_SKILL_START_ts, ON_BONE_HIT_ts}`. After 1-2 observations of each skill, the table self-populates with per-skill deltas.

2. **`skill_speed` multiplier:** The traces show `skill_speed=1.0` in all NPC skill kwargs. If this changes (e.g., buffs), bone hit timing scales proportionally. Read it from `anim_variables.skill_speed` in the SyncSkill kwargs.

3. **Distance independence:** Bone collision timing is determined by animation keyframes, not distance to target. The NPC's skeleton animates regardless of player position. The only distance-dependent factor is whether the collision shapes physically overlap with the player's collision skeleton — but the timing of when collision _detection_ runs is fixed by the animation timeline.

4. **`max_time` field:** Colliders with `bind=true` have a `max_time` field (e.g., 7.0s for skill 2300042, 2.6s for skill 77031105) that defines how long the collision is active. The bone hit occurs when the animated collider first overlaps the target, typically much earlier than `max_time`.

---

## 4. Conclusions (Updated)

### Full Dispatch Chain (Updated with Timing)

```
NPC AI decides to attack
    │
    ▼
SkillCtrl:start_skill(skill_id)
    │
    ├─ E_SKILL_START dispatched ─────────────── T = 0.000s  ◄── INTERCEPT HERE
    ├─ E_SKILL_ANIM_BEGIN_CLIENT dispatched ─── T = 0.000s
    ├─ SyncSkill:skill sent to server ────────── T = 0.000s
    ├─ cur_anim_start_ts set ─────────────────── T = 0.000s
    │
    ▼
Actionline plays animation timeline
    │
    ├─ BoneCollision:start() ──── colliders={} armed ── T ≈ 0.000s
    │   └─ trigger_gd_signal() ── E_GD_SIGNAL ───────── T ≈ 0.000s (async, fires slightly later)
    │
    ▼
C++ ActorComponent ticks physics
    │
    ├─ Collision skeleton shapes animate
    ├─ Overlap detected with player's collision skeleton
    │
    ▼
BoneCollisionNotify fired (C++) ────────────────────── T ≈ 0.7-1.0s  ◄── HIT LANDS
    │
    ├─ BoneCollision:on_bone_hit(results)
    │   ├─ TRY_USE_PARRY called
    │   ├─ DamageManager:process_calcpoint()
    │   └─ BehitWithoutAnim synced
    │
    ▼
Player takes damage ──────────────────────────────────── T ≈ 0.7-1.05s
```

### Key Insights

1. **Bone-collision timing is animation-deterministic.** The delay from `E_SKILL_START` to `ON_BONE_HIT` is fixed per `skill_id` because it depends on which animation frame the collision shape first overlaps the target. With `skill_speed=1.0`, this is always the same frame.

2. **The prediction window is 0.7–1.0 seconds** for most bone-collision skills. This is more than enough time for a frame-perfect parry (which only needs ~0.1–0.35s based on `23717011` parry timing).

3. **Server-calcpoint skills bypass bone collision entirely.** Skills 77031211 and 77031108 never fire `ON_BONE_HIT`. For these, `E_GD_SIGNAL` is the only pre-hit warning, with only ~0.05–0.15s lead time — much harder to predict.

4. **Multi-phase skills are still predictable** if you track `E_SKILL_ANIM_BEGIN_CLIENT` for each animation phase and use phase-relative timing tables.

5. **The system is self-documenting at runtime.** By hooking `SyncSkill:skill` and `ON_BONE_HIT`, you can build the timing table automatically without prior knowledge of skill IDs.

---

## 5. Deep Dive: `animation_reach_time` Resolution

### 5.1 Question / Scope

Resolve whether `animation_reach_time` (the time from animation start to when C++ collision shapes overlap the target) is computed or stored by the game itself, rather than being an opaque property of the binary animation asset.

Focus areas: anim/graph/timeline/node modules, server-side validation data, graph variable system.

---

### Evidence 5.1 — Server-Side Timing Data: `G.datam.anim_bone_colliders`

- **Source:** `hexm/common/actionline/nodes/action_nodes.lua` lines 25-50
- **Excerpt:**
```lua
local function update_bone_collider_info(context, entity, anim_name)
    if not entity.tag:is_player() then
        return
    end
    local colliders = G.datam.anim_bone_colliders:get(anim_name)
    if not colliders then
        return
    end
    local info = context.bone_colliders
    if not info then
        info = {}
        context:set_global("bone_colliders", info)
    end
    local now = DateTimeManager:now()
    for _, cld in pairs(colliders) do
        local cld_name = cld:get("name")
        if cld_name then
            local ts = cld:get("ts", 0)
            ts = ts - math.max(0.1, ts * 0.2)
            if ts < 0.1 then
                ts = 0
            end
            info[cld_name] = math.min(info:get(cld_name, 1.0E99), now + ts)
        end
    end
end
```
- **Call site:** `AnimationNode:start()` line 146, inside `if portable.IS_SERVER then` block — **server-only**.
- **Why it matters:** The game **does** maintain a pre-computed timing table for bone collisions. `G.datam.anim_bone_colliders` is keyed by animation name (e.g., `"skill_77031107"`) and contains an array of collider entries, each with:
  - `name` — collider name (e.g., `"C1"`, `"C2"`, `"C3"`)
  - `ts` — time in seconds from animation start to expected collision overlap
- The `ts` value IS the `animation_reach_time`. It's adjusted with a tolerance margin (reduced by 20%, minimum 0.1s reduction) before being used as a validation timestamp.
- **Evidence Confidence:** 5/5 — Direct definition.

---

### Evidence 5.2 — Server-Side Anti-Cheat Consumer: `check_is_speed_up`

- **Source:** `hexm/common/actionline/nodes/logic_nodes.lua` lines 1702, 1739-1745
- **Excerpt:**
```lua
local skill_collider_info = context.bone_colliders
-- ...
for collider, info in pairs(hit_info) do
    local cld = self.colliders_data:get(collider)
    if cld then
        if skill_collider_info then
            local dt = attacker:check_is_speed_up(skill_collider_info:get(collider), now)
            if dt then
                cheat_detect[collider] = { info:keys(), dt }
            end
        end
    end
end
```
- **Source (definition):** `hexm/common/base/combat_base.lua` line 102
- **Excerpt:**
```lua
function CombatBase:check_is_speed_up(min_ts, now) end  -- server-only stub
```
- **Why it matters:** When a client reports a bone collision hit, the server validates the timing against `context.bone_colliders[collider_name]`. If the hit arrives BEFORE the expected `ts - tolerance` time, it's flagged as speed hack (`cheat_detect`). The `ts` value is the authoritative expected `animation_reach_time`.
- **Evidence Confidence:** 5/5 — Direct usage in anti-cheat validation.

---

### Evidence 5.3 — Data Path Resolution

- **Source:** `hexm/common/data_manager.lua` line 19-21, `hexm/client/game_setup.lua` line 77
- **Excerpt:**
```lua
-- game_setup.lua
G.datam = DataManager()
G.datam:pre_setup()

-- data_manager.lua
function DataManager:ctor()
    DataManager.ctor.ctor(self, data_consts.DATA_ROOT)  -- "hexm.client.data_oversea"
end
```
- **Why it matters:** `G.datam.anim_bone_colliders` resolves to `hexm.client.data_oversea.anim_bone_colliders` via DirObject attribute lookup. However:
  - This table does NOT appear in the GreyTableInfo dump (`Scripts/data/DirObject/GreyTableInfo/`)
  - No corresponding JSON file exists in our data directory
  - It is likely loaded from binary tables via `MTableReader` (engine native data format)
  - The data IS conceptually "client data" (stored in `data_oversea`), but only consumed by the server code path (`if portable.IS_SERVER`)
- **Evidence Confidence:** 4/5 — Data path confirmed, but binary format prevents access.

---

### Evidence 5.4 — `update_bone_collider_info` Is Server-Only

- **Source:** `hexm/common/actionline/nodes/action_nodes.lua` lines 107-148
- **Excerpt:**
```lua
function AnimationNode:start(graph)
    local context = graph.context
    local entity = context.entity
    -- ... (shared setup) ...
    if portable.IS_SERVER then
        if self.face_target then
            entity.skill_ctrl:try_segment_face_target()
        end
        update_bone_collider_info(context, entity, self.anim)
        return {}
    end
    -- ... (client-side: play animation visually) ...
end
```
- **Why it matters:** The `update_bone_collider_info` call is inside the `IS_SERVER` branch of `AnimationNode:start()`. The CLIENT never reads `anim_bone_colliders` — it relies entirely on the C++ engine's `BoneCollisionNotify` event.
- **Evidence Confidence:** 5/5 — Direct code.

---

### Evidence 5.5 — Client-Side Collision Control: Engine-Driven, Not Lua-Driven

Investigation of all client-side collision activation mechanisms:

| Mechanism | What it controls | Where timing is defined |
|-----------|-----------------|------------------------|
| `BoneCollisionBase:start()` | Subscribes to `E_BONE_COLLISION` event | Runs when actionline graph executes — timing from timeline data |
| `DynamicCollisionBone:start()` | Adds collision shapes to TARGET's skeleton | Runs when actionline node executes — timing from timeline data |
| `SetEnableColliderQuery(bool)` | Enables/disables entity as collision target | Set at skeleton ready (disabled for player) |
| `EVENT_CUE_COLLISTION` (128) | Animation cue — defined but NOT handled in Lua | Processed internally by C++ engine |
| `CollisionDelay` graph variable | Particle/bullet collision delay | Set via `SetVariable()` at particle launch |
| C++ animation graph states | Activates/deactivates collision shapes (C1/C2/C3) | **Binary animation asset** — authored in engine graph editor |

- **Key Finding:** `EVENT_CUE_COLLISTION` (cue 128) is defined in `cue_consts.lua` but has **no handler** in `AnimBase.COMMON_CUE_EVENT_HANDLER_MAP`. It is processed entirely within the C++ engine. This is likely the mechanism by which the animation graph activates collision shapes at specific keyframes within the animation asset.
- **Evidence Confidence:** 5/5 — Exhaustive search of all collision-related mechanisms.

---

### Evidence 5.6 — `GetAnimationDuration` API

- **Source:** `hexm/client/entities/local/component/anim.lua` lines 2178-2182
- **Excerpt:**
```lua
function Anim:get_animation_duration(anim_name)
    if self._actor_cxx then
        return self._actor_cxx:GetAnimationDuration(anim_name)
    end
end
```
- **Why it matters:** The C++ `ActorComponent` exposes `GetAnimationDuration(anim_name)` which returns the total length of an animation asset. This is available on the CLIENT and could be used to compute ratios (e.g., collision-to-duration ratio), but does NOT give the specific keyframe time when collision shapes activate.
- **Evidence Confidence:** 5/5 — Direct API definition.

---

### Evidence 5.7 — Refined Timing Cross-Reference (Static Index vs Measured)

Using `al_static_index.json` (8110 indexed skills) to refine the timing decomposition. The index provides `time` = absolute time from skill start when the BoneCollision node activates, accounting for timeline arm time + animation trans_time.

**Decomposition formula:**
```
actual_bone_hit = index.time + animation_collision_delay
                  ^^^^^^^^^^   ^^^^^^^^^^^^^^^^^^^^^^^^^
                  COMPUTABLE   NOT COMPUTABLE from data
                  (al_static_index.json)
```

Where `index.time = timeline_arm_time + trans_time` (computed from DirObject actionline data).

**Cross-reference table:**

| Skill | Collider | index.time | trans_time | Measured Hit (Δ from E_SKILL_START) | animation_collision_delay | Samples |
|-------|----------|------------|------------|-------------------------------------|--------------------------|---------|
| 77031107 | C2 | 0.500s | 0.5s | 0.987s | **0.487s** | 4 (±0.006) |
| 77031107 | C3 | 0.500s | 0.5s | 1.290s | **0.790s** | 4 (±0.007) |
| 77031106 | C1 | 0.504s | 0.5s | 0.901s | **0.397s** | 1 |
| 77031106 | C2 | 2.076s | 0.5s | 2.119s | **0.043s** | 1 |
| 77031106 | C3 | 2.076s | 0.5s | 2.419s | **0.343s** | 1 |
| 77031105 | C1 | 0.500s | 0.5s | 0.738s | **0.238s** | 1 |
| 77031105 | C2 | 1.590s | 0.5s | 1.689s | **0.099s** | 1 |
| 77031201 | C1 | 1.117s | 0.0s | 1.553s | **0.436s** | 1 |
| 77031201 | C2 | 1.117s | 0.0s | 2.038s | **0.921s** | 1 |

**Relationship to prior `animation_reach_time`:**
```
animation_reach_time = trans_time + animation_collision_delay
                       ^^^^^^^^^   ^^^^^^^^^^^^^^^^^^^^^^^^^
                       KNOWN       The true unknown
                       (from DirObject AnimationNode)
```

This means the static index ALREADY accounts for the `trans_time`, reducing the unknown component by 0.0–0.5s per event.

- **Evidence Confidence:** 5/5 — Direct correlation with 9 data points, 4-sample variance verified.

---

### Evidence 5.8 — Server `ts` Value Reconstruction

The server's `anim_bone_colliders.ts` field stores the full `animation_reach_time` (including trans_time), then applies a tolerance reduction:

```lua
ts = ts - math.max(0.1, ts * 0.2)  -- reduce by 20%, min 0.1s
if ts < 0.1 then ts = 0 end
```

Reverse-engineering what `ts` would be for our measured values:

| Animation | Collider | Measured animation_reach_time | Estimated raw ts | After tolerance (server validation min_ts) |
|-----------|----------|------------------------------|------------------|--------------------------------------------|
| skill_77031107 | C2 | 0.987s | ~0.987s | 0.987 - max(0.1, 0.197) = **0.790s** |
| skill_77031107 | C3 | 1.290s | ~1.290s | 1.290 - max(0.1, 0.258) = **1.032s** |
| skill_77031106_1 | C1 | 0.897s | ~0.897s | 0.897 - max(0.1, 0.179) = **0.718s** |
| skill_77031105_1 | C1 | 0.738s | ~0.738s | 0.738 - max(0.1, 0.148) = **0.590s** |

The server allows bone hits to be reported up to ~20% earlier than the expected time. This is the anti-cheat tolerance window.

- **Evidence Confidence:** 4/5 — Reconstructed from code logic; actual `ts` values not directly observed.

---

### 5.2 Conclusions (Score ≥3 only)

#### 1. The game DOES compute and store `animation_reach_time` — as `G.datam.anim_bone_colliders[anim_name][collider].ts`

**Score: 5/5.** Direct code evidence. The server uses this for anti-cheat validation of bone collision timing. The `ts` field is the pre-computed time from animation start to expected collision overlap, per animation asset and per collider name.

#### 2. The data IS accessible from the client — but contains PLAYER skills only

**Score: 5/5 (REVISED from prior conclusion).** Runtime dump confirms `G.datam.anim_bone_colliders` is a `BinDataObject` iterable from client Lua. However, it contains only ~315 player skill animation entries. NPC/boss skill animations are NOT included — the server does not need client-side timing validation for NPC attacks (NPC attacks are server-authoritative).

#### 3. The timing decomposes into three layers, two of which are computable

**Score: 5/5.**

```
actual_bone_hit_time = timeline_arm_time + trans_time + animation_collision_delay
                       ^^^^^^^^^^^^^^^^^   ^^^^^^^^^   ^^^^^^^^^^^^^^^^^^^^^^^^^
                       Layer 1: EXACT      Layer 2:    Layer 3: NOT COMPUTABLE
                       (from DirObject     EXACT       (binary animation asset)
                        timeline data)     (from DirObject
                                           AnimationNode)
```

The `al_static_index.json` provides `index.time` = Layer 1 + Layer 2, leaving only `animation_collision_delay` as the unknown.

#### 4. `animation_collision_delay` ranges from 0.04s to 0.92s and is constant per animation+collider

**Score: 5/5.** Nine data points from traces show values ranging from 0.043s to 0.921s. The 4-sample test of skill 77031107 shows ±6ms variance, confirming frame-deterministic behavior.

#### 5. Collision shape activation is driven by C++ `EVENT_CUE_COLLISTION` (cue 128), processed internally by the engine

**Score: 4/5.** `EVENT_CUE_COLLISTION = 128` is defined in `cue_consts.lua` but has no Lua handler in `COMMON_CUE_EVENT_HANDLER_MAP`. It's processed by the C++ `ActorComponent` during animation graph evaluation. This is the mechanism that activates named collision shapes (C1, C2, C3) at specific keyframes within the animation asset.

#### 6. Architecture diagram: collision timing data flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│  ANIMATION ASSET (.graph binary)                                        │
│  Authored in engine skeleton/graph editor                               │
│                                                                         │
│  Contains:                                                              │
│    - Bone transform keyframes                                           │
│    - Collision shape placement (capsules/spheres on bones)               │
│    - Collision activation cues (EVENT_CUE_COLLISTION = 128)             │
│      at specific keyframe times within the animation                    │
│                                                                         │
│  Build time → exports "anim_bone_colliders" data table                  │
│    {anim_name → [{name="C1", ts=0.987}, {name="C2", ts=1.290}]}       │
│                                                                         │
└────────────┬──────────────────────────┬─────────────────────────────────┘
             │                          │
    ┌────────▼────────┐       ┌────────▼────────┐
    │   SERVER         │       │   CLIENT         │
    │                  │       │                  │
    │  G.datam.        │       │  C++ engine      │
    │  anim_bone_      │       │  evaluates       │
    │  colliders       │       │  animation graph │
    │  (binary table)  │       │  every frame     │
    │                  │       │                  │
    │  Used by:        │       │  Fires           │
    │  update_bone_    │       │  cue 128 at      │
    │  collider_info() │       │  authored time   │
    │  → anti-cheat    │       │  → activates     │
    │  validation via  │       │  collision shape  │
    │  check_is_       │       │  → physics check │
    │  speed_up()      │       │  → BoneCollision │
    │                  │       │  Notify fired    │
    └──────────────────┘       └──────────────────┘

    The server has ts values          The client computes overlap
    per anim+collider.                at runtime via physics.
    NOT accessible from               NOT predictable without
    client Lua.                        measurement or ts data.
```

---

### Evidence 5.9 — Runtime Dump Confirms Client Accessibility (PLAYER-ONLY)

- **Source:** Runtime dump via `for k, v in pairs(G.datam.anim_bone_colliders) do print(...) end`
- **Excerpt (first line + sample):**
```
[BinDataObject, table_name: anim_bone_colliders, enable_iteration: true]

key: skill_2300042_2 - value: [{ts: 0.25279653272727, name: C1}]
key: skill_2300057 - value: [{ts: 0.78922605, name: C1}, {ts: 1.3884218872727, name: C2}, ...]
key: skill_20801105 - value: [{ts: 0.633082026, name: C1}, {ts: 1.000122459, name: C10}, ...]
key: skill_20202102_5 - value: [{ts: 0.040742481, name: C1}, {ts: 0.283202343, name: C2}, ...]
```
- **Why it matters:** `G.datam.anim_bone_colliders` IS accessible from the client as a `BinDataObject` with `enable_iteration: true`. The dump yielded **~315 entries** (all player skill animations). Each entry maps an animation name to an array of `{ts, name}` collider timing records.

**CRITICAL LIMITATION:** The table contains **only player skill animations** — no NPC/boss skill animations (e.g., `skill_77031107`, `skill_77031106_1`). This is because `update_bone_collider_info()` is gated by `if not entity.tag:is_player() then return end` — the server only validates timing for player attacks. NPC attack timing is server-authoritative and does not require client-side anti-cheat validation.

- **Evidence Confidence:** 5/5 — Direct runtime observation.

---

### Evidence 5.10 — Sample `ts` Values Cross-Referenced with Player Skill Data

Selected entries from the dump showing `ts` values for player skills:

| Animation Name | Colliders | ts Values |
|---------------|-----------|-----------|
| `skill_2300042_2` | C1 | 0.253s |
| `skill_2300046` | C1, C2 | 0.444s, 0.444s |
| `skill_2300057` | C1-C6 | 0.789s, 1.388s, 1.586s, 1.909s, 2.111s, 2.781s |
| `skill_20101101` | C1-C6 | 0.232s, 0.523s, 0.756s, 1.037s, 1.374s, 1.640s |
| `skill_20801105` | C1,C10-C13,C20-C22,C30 | 0.633s → 1.800s |
| `skill_2300062` | C1, C2 | 3.300s, 8.416s |

Note: `ts` values are highly precise (sub-microsecond), confirming they are pre-computed from animation asset keyframe data at build time.

- **Evidence Confidence:** 5/5 — Direct runtime data.

---

### 5.3 Unknown / Missing Evidence

- **NPC/boss `animation_reach_time` data:** NOT in `anim_bone_colliders` — the table only contains player skill animations. NPC skill collision timing remains obtainable only via runtime measurement (auto-recording E_SKILL_START → ON_BONE_HIT deltas).
- **`EVENT_CUE_COLLISTION` (128) processing:** Confirmed to exist with no Lua handler. How the C++ engine processes it (enable collision shape? set collision radius? activate named collider?) is inferred but not directly observed.
- **`animation_collision_delay` for phase 2 animations:** Values like 0.043s and 0.099s for phase 2 colliders suggest the collision shape is already very close to the target when the phase begins (the NPC is already in attack posture from phase 1).

---

### 5.4 Revised Prediction Formula

```
time_to_hit = index_time[skill_id][collider] + animation_collision_delay[anim_name][collider]
              ──────────────────────────────   ─────────────────────────────────────────────────
              FROM al_static_index.json        FROM runtime measurement (constant per anim+collider)
              (8110 skills indexed)             OR from G.datam.anim_bone_colliders (server-only)
```

For server calcpoint skills:
```
time_to_hit = index_time[skill_id][attack] + processing_overhead (~0.05-0.09s)
              ──────────────────────────────   ────────────────────────────────────
              FROM al_static_index.json        Constant overhead (frame scheduling)
```

---

### 5.5 Next Scoped Search Steps

1. ~~Attempt to dump `G.datam.anim_bone_colliders` at runtime~~ **DONE** — confirmed accessible, ~315 player skill entries. NPC entries absent.
2. Build runtime auto-measurement system for NPC skills: hook `SyncSkill:skill` + `ON_BONE_HIT`, correlate with `al_static_index.json` data to auto-compute `animation_collision_delay` per NPC animation+collider.
3. Investigate whether NPC collision timing data exists in a separate table (search `G.datam` for tables keyed by NPC animation names like `skill_77031107`).
4. Trace `DamageManager:process_calcpoint` → `BehitWithoutAnim` → `E_BEHIT_BEGAN` to map the full damage pipeline.
5. Investigate `skill_speed` scaling — search for where `anim_variables.skill_speed` modifies timing.
6. Use `GetAnimationDuration` on NPC skeleton to get animation lengths, cross-reference with measured collision timing to find potential ratio-based estimation.
7. Explore whether NPC `_actor_cxx` exposes collision keyframe timing through any C++ API (e.g., query collision cue times from the animation graph).
