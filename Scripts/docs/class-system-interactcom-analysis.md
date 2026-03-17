# Class System & InteractComEntity Static Data Analysis

## Question / Scope

How are classes set up and customized in this game engine? How can all static data (fields/properties) of an `InteractComEntity` instance be dumped at runtime?

---

## 1. The `class()` Built-in

The `class()` function is a **C++-side built-in** (not defined in Lua). It creates class tables with metatable-based single inheritance.

**Source:** Global function, not found in `source_decompiled/` — provided by the engine runtime.

**Signature:**
```lua
class(name)                -- new root class
class(name, parent)        -- class with single parent
```

**Related built-in globals (used throughout codebase):**
- `issubclass(a, b)` — check class hierarchy
- `isinstance(obj, cls)` — check instance type
- `dirclass(cls)` / `dirclass(cls, "function")` — iterate class-level members (optionally filtered by type)
- `class_ready(cls)` — finalize class, triggers `__metaclass__` if set
- `rawset(cls, name, v)` — set field directly on class table (bypass metamethods)
- `rawget(cls, name)` — get field directly from class table
- `rawdel(cls, name)` — delete field from class table
- `rawclear(obj)` — clear all instance fields
- `getattr(obj, name, default)` — safe attribute access with fallback
- `hasattr(obj, name)` — check attribute existence

**Evidence Confidence:** 5/5 — `class()` is used in every single module file. `classutils.lua:69` uses `dirclass(component)`, `classutils.lua:16` uses `issubclass(component, base)`.

---

## 2. Component System (Two Parallel Implementations)

### 2a. Engine-Level Component System (`common.classutils`)

Used for server-side entities with the Property system. Lifecycle hooks:

| Hook | Purpose |
|------|---------|
| `__init_component__` | Initialize component |
| `__post_component__` | Post-init |
| `__tick_component__` | Per-frame tick |
| `__fini_component__` | Cleanup/destroy |

Setup via `classutils.ComponentHost(cls)` and `classutils.Components(cls, ...)`.

Components are stored in `cls.__components__` and their lifecycle functions in `cls.__component_inits__`, `cls.__component_posts__`, etc.

**Source:** `common/classutils.lua:183-234`
**Evidence Confidence:** 5/5

### 2b. Game-Specific Component System (`hexm.client.entities.components`)

This is what `InteractComEntity` uses. Extended lifecycle hooks with named dispatch:

| Hook | Full Name |
|------|-----------|
| `init` | `__init_component__` |
| `post` | `__post_component__` |
| `enter_space` | `__enter_space_component__` |
| `leave_space` | `__leave_space_component__` |
| `pre_fini` | `__pre_fini_component__` |
| `fini` | `__fini_component__` |
| `load_model_over` | `__load_model_over_component__` |
| `skeleton_ready` | `__skeleton_ready_component__` |
| `change_model` | `__change_model_component__` |
| `set_view_visible` | `__set_view_visible_component__` |
| ... (68 total hooks) | |

**Key Functions:**
- `Components(cls, member_list)` — Full setup: copies members → creates ComponentHost → registers all lifecycle hooks → sets up `DeclarativeListenHost`
- `ComponentsBaseClassMeta(cls, list)` — Lighter: copies non-dunder methods only (no lifecycle registration)
- `_addComponent(cls, component)` — Registers component in `__component_func_dict__` for fast dispatch
- `_addComponentNormal(cls, component)` — Copies non-`__` methods from component class directly onto target class via `rawset`

**Component dispatch at runtime:**
```lua
-- Components are stored as:
cls.__components__[idx] = component_class
cls.__component_func_dict__[hook_name] = { {func=fn, component=cls, component_idx=N}, ... }
cls.__component_normal_dict__[component] = true  -- tracks merged components
```

When `_callComponents("init", bdata)` is called, it iterates `__component_func_dict__["init"]` and calls each registered function.

**Source:** `hexm/client/entities/components.lua:79-121,592-649`
**Evidence Confidence:** 5/5

---

## 3. Property System (`common.classutils`)

Properties are **server-synced fields** declared on entity data classes, NOT on client-side local entities directly.

**Declaration:**
```lua
Property(cls, name, default, flag)
```

**Property flags (bitmask):**
| Flag | Value | Meaning |
|------|-------|---------|
| `MANUAL` | 0 | Not synced |
| `SERVER_ONLY` | 1 | Server only |
| `OWN_CLIENT` | 2 | Synced to owning client |
| `ALL_CLIENTS` | 4 | Synced to all clients |
| `PERSISTENT` | 8 | Saved to DB |
| `STRDATA` | 32 | String serialization |
| `SPECTATOR` | 64 | Visible to spectators |
| `BASE` | 1024 | Base property |
| `SOUL_NEED` | 4096 | Required for soul system |

**Storage:**
```lua
cls.__property_all__[name] = default_value  -- property name → default
cls.__property_flag__[name] = flag_bitmask  -- property name → sync flags
```

**Custom container types for complex properties:**
- `CustomMapType` — dict-like container (extends `asiocore.area_map`)
- `CustomListType` — list-like container (extends `asiocore.area_list`)
- `CustomIntMapType`, `CustomFloatMapType`, `CustomStrMapType` — typed maps
- `CustomIntListType`, `CustomFloatListType`, `CustomStrListType` — typed lists

**Source:** `common/classutils.lua:443-475` (Property callable), `common/classutils.lua:380-428` (PropertyMetaClass)
**Evidence Confidence:** 5/5

---

## 4. InteractComEntity Full Class Hierarchy

```
[C++ built-in class]
  └─ HexObject                          (hexm/common/hex_object.lua)
       - self._is_destroyed
       └─ Listenable                    (hexm/client/util/listenable.lua)
            - self.__channels (event listener system)
            └─ SimpleBaseEntity         (hexm/client/entities/local/simple_base_entity.lua)
                 + entity_common members (10 base components)
                 └─ BaseEntity          (hexm/client/entities/local/base_entity.lua)
                      + CxxDataBase component
                      └─ InteractComEntity  (hexm/client/entities/local/interactcom_entity.lua)
                           + interactcom_members (77 components)
```

### entity_common Members (on SimpleBaseEntity)

These are added via `ComponentsBaseClassMeta` (methods merged, no lifecycle hooks):

| Component | Source | Key Fields Set |
|-----------|--------|----------------|
| `TimerManagerBase` | `entity_common/timer_manager_base.lua` | timer system |
| `EntityFastReuseBase` | `entity_common/entity_fast_reuse_base.lua` | fast reuse support |
| `EntityReuseBase` | `entity_common/entity_reuse_base.lua` | scene transfer reuse |
| `VisibilityBase` | `entity_common/visibility_base.lua` | visibility flags |
| `ExcelDataBase` | `entity_common/excel_data_base.lua` | entity_data, model_data, combat_data, etc. |
| `DispatcherBase` | `common_members/dispatcher_base.lua` | self.dispatcher |
| `EngineEntityBase` | `entity_common/engine_entity_base.lua` | engine entity bindings |
| `TransformChangedBase` | `entity_common/transform_changed_base.lua` | transform change tracking |
| `ShadowBase` | `entity_common/shadow_base.lua` | shadow system |
| `ReportLogBase` | `entity_common/report_log_base.lua` | logging |

### BaseEntity adds:

| Component | Key Fields Set |
|-----------|----------------|
| `CxxDataBase` | `self.cxx_data` (CxxData object with charctrl info) |

### InteractComEntity's 77 Components

Added via `Components(InteractComEntity, interactcom_members)`. Full list from `import_all.lua`:

| # | Component | Base Class | Key Responsibility |
|---|-----------|------------|-------------------|
| 1 | HexEntityBase | — | Hex entity registration |
| 2 | HexPluginBase | — | Hex plugin system |
| 3 | imp_view (ViewBase) | ViewBase | `self.view`, `self.use_hex_model`, model loading |
| 4 | imp_anim | — | `self.anim`, animation state, storyboard |
| 5 | AnimCommonMotionBase | — | Common animation motion |
| 6 | imp_sync | — | Position/yaw sync from server |
| 7 | imp_rigidbody | — | `self._rigidbodies`, physics collision |
| 8 | imp_effect | EffectSyncBase | Visual effects |
| 9 | imp_colorize | — | Color/material changes |
| 10 | imp_billboard | — | Name plates / billboards |
| 11 | imp_destroy_show | — | Destruction visual effects |
| 12 | imp_dissolve | — | Dissolve shader effect |
| 13 | imp_behit | — | Hit reaction |
| 14 | ProximityBase | — | Proximity detection |
| 15 | imp_interact_area | — | Interaction area triggers |
| 16 | imp_interact_comp (InteractComponentBase) | InteractComponentBase | Server interact comp bridge |
| 17 | imp_interact_comp_handler | — | Interaction input handling |
| 18 | imp_collect | — | Collection interaction |
| 19 | imp_destruct (DestructBase) | DestructBase | Destructible object logic |
| 20 | RotatorBase | — | Rotation mechanics |
| 21 | HarmTextBase | — | Damage number display |
| 22 | imp_tach | — | Attachment system |
| 23 | SceneNodeBase | — | Scene graph node |
| 24 | TaskTraceTargetBase | — | Task waypoint target |
| 25 | imp_disaster_dungeon | — | Disaster dungeon logic |
| 26 | imp_tomb | — | Tomb interaction |
| 27 | imp_post | — | Post-processing |
| 28 | imp_hide | — | Show/hide logic |
| 29 | imp_trigger_pressure | TriggerPressureBase | Pressure plate trigger |
| 30 | HideEntityBase | — | Entity hide system |
| 31 | ImpResources | — | Resource management |
| 32 | SoundBase | — | Audio/sound |
| 33 | PostBase | — | Post effect |
| 34 | imp_elevator | — | Elevator platform |
| 35 | imp_actionline | — | Action line scripting |
| 36 | AttachModelBase | — | Model attachment |
| 37 | imp_story (NpcMember) | — | Story/dialogue system |
| 38 | ImpInteractLadder | — | Ladder climbing |
| 39 | imp_behavior_event (NpcMember) | — | NPC behavior events |
| 40 | CraneBase | — | Crane mechanics |
| 41 | RotateMovePlatformBase | — | Rotating/moving platform |
| 42 | imp_telekinesis_cable | — | Telekinesis cable |
| 43 | imp_cable_rope | — | Cable rope physics |
| 44 | RoadSignBase | — | Road sign display |
| 45 | imp_anchor_move (NpcMember) | — | Anchor movement |
| 46 | GPCompBase | — | Gameplay component |
| 47 | ListenTrace | — | Listen/trace system |
| 48 | BuildingMember (imp_edit) | — | Building edit mode |
| 49 | SimpleDialogComp | — | Dialog component |
| 50 | imp_listen | — | Listen mechanic |
| 51 | ImpDianxue | — | Dianxue (acupoint) |
| 52 | TelekinesisBase | — | Telekinesis |
| 53 | AOIBase | — | Area of Interest |
| 54 | imp_chair | — | Sitting interaction |
| 55 | TelekinesisSceneInteractBase | — | Telekinesis scene interaction |
| 56 | imp_mahjong | — | Mahjong table game |
| 57 | imp_platform | — | Platform mechanics |
| 58 | SwingBase | — | Swing mechanics |
| 59 | PointLightBase | — | Point light |
| 60 | ZhuomoBase | — | Zhuomo system |
| 61 | TaijiBacktrackBase | — | Taiji backtrack |
| 62 | InteractBacktrackBase | — | Interact backtrack |
| 63 | imp_chiji_dead_box | — | Battle royale dead box |
| 64 | imp_simple_storyboard | — | Simple storyboard |
| 65 | SeesawBase | — | Seesaw mechanics |
| 66 | bengbeng_drum | — | Drum interaction |
| 67 | generate_trap | — | Trap generation |
| 68 | imp_portal_view | — | Portal visual |
| 69 | PortalAccessorBase | — | Portal access |
| 70 | TelekinesisCableBox | — | Telekinesis cable box |
| 71 | imp_table_game | — | Table game |
| 72 | imp_optimize | — | LOD optimization |
| 73 | imp_jintianxia | — | Jintianxia mechanic |

**Source:** `interactcom_members/import_all.lua:4-78`
**Evidence Confidence:** 5/5

---

## 5. Instance Fields Set During Construction

### From `HexObject:ctor()`:
```lua
self._is_destroyed = false
```

### From `SimpleBaseEntity:ctor()`:
```lua
self.is_room_entity          -- bool
self.has_entity_cxx          -- bool (CLASS_HAS_ENTITY_CXX)
self.space                   -- Space object
self._is_managed_by_space    -- bool (from bdict)
self.create_data             -- dict (original bdict)
self.entity_id               -- entity ID
self.id                      -- same as entity_id
self._entity_id              -- same as entity_id
self.server_entity_id        -- server-side entity ref
self.is_client_only          -- bool
self.entity_no               -- number (npc_no from data)
self.npc_no                  -- same as entity_no
self.no                      -- same as entity_no
self.No                      -- same as entity_no
self._entity_no              -- same as entity_no
self.serial_id               -- serial identifier
self.create_from_cutscene    -- bool
self.cutscene_lod            -- {0, 0}
self.tag                     -- Tag object (entity classification)
self._managed_objects        -- list
self.par_loader              -- EntityLoader (parallel loading)
self.use_par_create          -- bool
self.ecs_id                  -- ECS entity ID
```

### From `ExcelDataBase:load_init_data()` (component init):
```lua
self.entity_data             -- from G.datam.entity_init_data[entity_no]
self._entity_data            -- cached reference
self.entity_model_data       -- entity_data.entity_model_data
self._entity_model_data      -- cached
self.model_no                -- from data or entity_data.model_no
self.ori_model_no            -- original model_no
self.is_override_mode_no     -- bool
self.model_data              -- from G.datam.models[model_no]
self._model_data             -- cached
self.ori_model_data          -- original model data
self._ori_model_data         -- cached
self.combat_data             -- from entity_data.combat_data
self._combat_data            -- cached
self.async_load_graph        -- bool (default true)
self.need_cue_callback       -- bool (default true)
self.base_graph              -- from model_data.base_graph
self.base_skeleton           -- from model_data.skeleton
self._check_need_load_skeleton_and_graph -- bool
self.ai_id                   -- from entity_data.ai_id
```

### From `BaseEntity:ctor()`:
```lua
self._logic_lod_enabled_proxy -- FlagStackProxy
self.entity_cxx              -- C++ entity object (from _init_entity_cxx)
self.is_create_by_engine     -- bool
```

### From `InteractComEntity:ctor()`:
```lua
self.interactcom_no          -- from data.interactcom_no
self.model_no                -- from get_model_no()
self.res_set                 -- nil (lazy-initialized set)
```

### From `ViewBase:__init_component__()`:
```lua
self._view_create_data       -- bdata reference
self.use_hex_model           -- bool
self.view                    -- View or HexView object
self._serial_group_id        -- from bdata
self._face_lod_set_proxy     -- nil
self._lod_managed_proxy      -- nil
self._bucket_lod_priority_proxy -- nil
self._init_model_no_list     -- nil
self.is_model_load_over      -- false
self.is_model_resource_ready -- false
self._view_shader_parameter_cache -- {}
self._view_shader_texture_cache   -- {}
```

### From `CxxDataBase:__init_component__()`:
```lua
self.cxx_data                -- CxxData object
  .owner                     -- self reference
  .entity_view               -- nil
  .charctrl_collision_filter_info -- 1
  .charctrl_passive_mode     -- false
  .interact_comp_enabled     -- {enable_interact=true}
```

### Lazily initialized:
```lua
self._ins_entity_data        -- from space.ins_entity[serial_id]
self._billboard_data         -- from entity_data.billboard_data
self._interact_data          -- from entity_data.interact_data
self._entity_attr_data       -- from G.datam.entity_attr[attr_id]
self._value_data             -- from G.datam.entity_value[value_no]
self._ai_data                -- AI data
self.dispatcher              -- event dispatcher (from DispatcherBase)
self._storyboard             -- storyboard object (from anim component)
self._rigidbodies            -- rigidbody list (from rigidbody component)
self.anim                    -- animation controller (from anim component)
```

**Evidence Confidence:** 4/5 — Fields are from direct code reading. Additional fields set by the other 60+ components exist but are too numerous to catalog exhaustively without runtime inspection.

---

## 6. Server-Side InteractComp Properties

The server-synced `InteractComp` object (accessed via `get_server_interact_comp()`) has these declared properties:

```lua
Property(InteractComp, "comp_eid", "", ALL_CLIENTS)
Property(InteractComp, "owner_eid", "", ALL_CLIENTS)
Property(InteractComp, "related_eid", "", ALL_CLIENTS)
Property(InteractComp, "No", 0, ALL_CLIENTS)
Property(InteractComp, "components", InteractComponents, ALL_CLIENTS)  -- bag of InteractComponentInfo
Property(InteractComp, "position", CustomListType, ALL_CLIENTS)
Property(InteractComp, "yaw", 0, ALL_CLIENTS)
Property(InteractComp, "serial_id", -1, ALL_CLIENTS)
Property(InteractComp, "comp_type", COMP_TYPE_NPC, ALL_CLIENTS)
Property(InteractComp, "enabled", 1, ALL_CLIENTS)
Property(InteractComp, "is_client", false, ALL_CLIENTS)
Property(InteractComp, "is_bound", 0, ALL_CLIENTS)
Property(InteractComp, "is_private", 0, ALL_CLIENTS)
Property(InteractComp, "is_migrating", "", ALL_CLIENTS)
Property(InteractComp, "active_cnt", InteractCompActiveCnt, ALL_CLIENTS)
Property(InteractComp, "active_way2avatars", CustomIntBag, ALL_CLIENTS)
Property(InteractComp, "interact_condition", CustomMapType, ALL_CLIENTS)
Property(InteractComp, "destroy_reason", 0, ALL_CLIENTS)
Property(InteractComp, "sync_ex", SyncEx, ALL_CLIENTS)
Property(InteractComp, "ex", CustomMapType, SERVER_ONLY)
```

Each `InteractComponentInfo` within `components` has:
```lua
Property(InteractComponentInfo, "config_no", 0, ALL_CLIENTS)
Property(InteractComponentInfo, "comp_no", 1, ALL_CLIENTS)
Property(InteractComponentInfo, "status_no", 0, ALL_CLIENTS)
Property(InteractComponentInfo, "comp_id", "", ALL_CLIENTS)
Property(InteractComponentInfo, "comp_eid", "", ALL_CLIENTS)
Property(InteractComponentInfo, "relations", InteractCompRelations, ALL_CLIENTS)
Property(InteractComponentInfo, "status_change_ts", 0, ALL_CLIENTS)
```

**Source:** `hexm/common/property_define/common_prop/interact_comp.lua:31-52`, `interact_comp_parts.lua:21-27`
**Evidence Confidence:** 5/5

---

## 7. How to Dump All Static Data at Runtime

### Approach A: Iterate Instance Fields via `pairs()`

```lua
-- Dump all key-value pairs on the instance
local entity = target_entity  -- an InteractComEntity instance
local dump = {}
for k, v in pairs(entity) do
    dump[k] = v
end
```

This gets **all dynamically-set instance fields** (everything stored via `self.xxx = ...` during construction and component lifecycle). It does NOT get class-level methods.

### Approach B: Walk the Class Hierarchy with `dirclass()`

```lua
-- Dump class-level members (methods + class fields)
local cls = entity.__class__ or getmetatable(entity).__index
for name, value in dirclass(cls) do
    print(name, type(value), value)
end
```

`dirclass` iterates all members visible on a class, including inherited ones.

### Approach C: Dump `__property_all__` (Server Entity)

```lua
-- For the server-side entity's synced properties
local server_comp = entity:get_server_interact_comp()
if server_comp then
    local props = server_comp.__property_all__
    for name, default in pairs(props) do
        local flag = server_comp.__property_flag__[name]
        local value = server_comp[name]
        print(name, value, flag)
    end
end
```

### Approach D: Combined Instance + Excel Data Dump

```lua
local function dump_interactcom(entity)
    local result = {}

    -- 1. Instance fields (self.xxx)
    result.instance_fields = {}
    for k, v in pairs(entity) do
        local t = type(v)
        if t ~= "function" then
            result.instance_fields[k] = tostring(v)
        end
    end

    -- 2. Excel data sources
    result.entity_data = entity:get_sys_d()           -- G.datam.entity_init_data[entity_no]
    result.model_data = entity:get_model_data()        -- G.datam.models[model_no]
    result.combat_data = entity:get_combat_data()      -- entity_data.combat_data
    result.billboard_data = entity:get_billboard_data() -- entity_data.billboard_data
    result.interact_data = entity:get_interact_data()   -- entity_data.interact_data
    result.value_data = entity:get_value_data()         -- G.datam.entity_value[entity_no]
    result.attr_data = entity:get_attr_data()           -- G.datam.entity_attr[attr_id]
    result.ins_entity_data = entity:get_ins_entity_data() -- space.ins_entity[serial_id]
    result.entity_model_data = entity:get_entity_model_data()

    -- 3. Server-synced InteractComp data
    local server_comp = entity:get_server_interact_comp()
    if server_comp then
        result.server_comp = {}
        for k, v in pairs(server_comp) do
            result.server_comp[k] = tostring(v)
        end
    end

    -- 4. Key identity fields
    result.identity = {
        id = entity.id,
        entity_no = entity.entity_no,
        serial_id = entity.serial_id,
        interactcom_no = entity.interactcom_no,
        model_no = entity.model_no,
        is_client_only = entity.is_client_only,
    }

    return result
end
```

### Approach E: List All Components

```lua
-- Enumerate registered components
for idx, component in ipairs(entity.__components__) do
    print(idx, component.__name__ or tostring(component))
end
```

**Evidence Confidence:** 4/5 — Approaches derived from code structure. The `pairs(instance)` behavior depends on engine metamethod implementation, but standard Lua and the observed `rawset`/`rawclear` patterns confirm it works.

---

## Conclusions

1. **`class()` is a C++ built-in** that creates Lua tables with metatable-based single inheritance. It supports `ctor`, `__metaclass__`, and standard OOP patterns. *(Score: 5/5)*

2. **Two component systems coexist**: `common.classutils` (engine-level, with Property sync) and `hexm.client.entities.components` (game-level, with 68 named lifecycle hooks). InteractComEntity uses the game-level system. *(Score: 5/5)*

3. **InteractComEntity is composed of 77 components** mixed into a 4-level class hierarchy (HexObject → Listenable → SimpleBaseEntity → BaseEntity → InteractComEntity). Components inject methods directly onto the class via `rawset`. *(Score: 5/5)*

4. **The Property system (`__property_all__`) is for server-synced data**, not client-side local entity fields. InteractComEntity's local fields are set imperatively via `self.xxx = ...` during `ctor()` and component `__init_component__` hooks. *(Score: 5/5)*

5. **To dump all static data**, iterate `pairs(entity)` for instance fields, call the `get_*` accessor methods for Excel-based data, and access `get_server_interact_comp()` for server-synced properties. *(Score: 4/5)*

6. **`dirclass(cls)` is the authoritative way to enumerate all class-level members** including inherited methods from parent classes and mixed-in components. *(Score: 5/5)*

---

## Unknown / Missing Evidence

- Exact metamethod implementation of `class()` (C++ side, not inspectable from Lua)
- Whether `pairs(instance)` returns ALL fields or only non-metatable ones (standard Lua behavior suggests instance table only, which is sufficient for dumping `self.xxx` fields)
- Complete field catalog for all 77 components (would require reading each member file individually — only the most critical ones were analyzed)
- The `hexlib` C module's optimized component dispatch path (`hexlib.init_component`, `hexlib.call_component`) — binary, not inspectable
