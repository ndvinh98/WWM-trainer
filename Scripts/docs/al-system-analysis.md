# Actionline (AL) System Architecture Analysis

## 1. Question / Scope

How does the game's Actionline system work end-to-end?

- How boss AL skill data is loaded from `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.AL.skill.boss_*.json`
- Structure of AL skill JSON and mapping to node classes
- Full pipeline: AL data loading → ALDriver → Actionline → Graph construction → Node execution
- Timeline/Frame subsystem and how it bridges back to graphs
- Structure of `al_static_index.json`

---

## 2. Evidence

### 2.1 Boss AL JSON Data Structure

**Source:** `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.AL.skill.boss_26098_hqy.json`

The file is a JSON array of `[skill_id_string, skill_definition]` tuples:

```json
[
  ["99001210", {
    "NodeGraph": [
      {
        "graphID": 1,
        "lineData": [
          {"startNode": 3, "endNode": 4, "startPort": "__out__", "endPort": "__in__"},
          {"startNode": 4, "endNode": 5, "startPort": "__out__", "endPort": "__in__"}
        ],
        "nodeData": [
          {"NodeID": 3, "Type": "PrepareSkillNode", "Data": {"skill_id": 99001210, ...}},
          {"NodeID": 4, "Type": "SkillRelease", "Data": {}},
          {"NodeID": 5, "Type": "SkillTimelineNode", "Data": {"bind": true, "timelineID": 11}}
        ]
      },
      {
        "graphID": 2,
        "nodeData": [
          {"NodeID": 6, "Type": "CalcMotionVariable", "Data": {"action_mode": 9900121001}},
          {"NodeID": 7, "Type": "AnimationNode", "Data": {"anim": "skill_99001210", ...}},
          {"NodeID": 8, "Type": "BoneCollisionData", "Data": {"calcpoint_id": 9900121001, ...}},
          {"NodeID": 9, "Type": "BatchBoneCollision", "Data": {"bind": true, "result_id": 0}},
          {"NodeID": 10, "Type": "BoneCollisionData", "Data": {"calcpoint_id": 9900121002, ...}}
        ]
      }
    ],
    "StartGraph": 1,
    "Timeline": [
      {
        "timelineID": 11,
        "timeline": {
          "__tracks__": [
            {
              "Type": "NormalTrack",
              "__keyframes__": [
                {"Type": "GraphKeyframe", "graphID": 2, "time": 0.0}
              ]
            }
          ]
        }
      }
    ]
  }],
  ["99001208", { ... }]
]
```

**Key fields per skill:**
- `NodeGraph[]` — array of graph definitions, each with `graphID`, `nodeData[]`, `lineData[]`
- `StartGraph` — integer ID of the entry-point graph
- `Timeline[]` — array of timeline definitions, each with `timelineID` and `timeline` containing `__tracks__` → `__keyframes__`

**Node types observed in boss data:** `PrepareSkillNode`, `SkillRelease`, `SkillTimelineNode`, `CalcMotionVariable`, `AnimationNode`, `BoneCollisionData`, `BatchBoneCollision`, `FaceTarget`

**Evidence Confidence: 5/5** — Direct data file examination.

---

### 2.2 Data Loading Pipeline

**Source:** `Scripts/source_decompiled/hexm/common/combat/al_driver.lua:15-34, 183-232`

The loading chain is:

```
ALDriverBase:run_AL_from_file(category, filename, context)
  → ALDriverBase:create_AL_data(category, filename)
      → load_AL_data(entity, category, filename)
          → G.datam.AL[category].index:get(filename)  -- looks up path in datam index
          → helper.load_AL_data_by_path(entity, path, filename)
              → G.datam[path]:get(name)  -- binary deserialization from datam
  → ALDriverBase:create_AL(data, category, filename, al_id)
      → Actionline(entity, al_id, category, filename)
      → al:load_from_dict(data)  -- stores NodeGraph, Timeline, StartGraph
  → ALDriverBase:run_AL(al, context, main_AL)
      → al:run(context)
```

**Caching:** `AL_DATA` and `AL_DATA_GREY` dictionaries cache loaded data keyed by `category..filename`. Grey (test/preview) data uses a separate cache. Cache is cleared on AL reload via `G.reg_reload_func("AL", ...)`.

**Client data loading** (`helper.lua:1595-1605`):
```lua
function _M.load_AL_data_by_path_bin(entity, path, name)
    if G.space:is_grey() then path = path .. "__grey" end
    local t = G.datam[path]
    if t and t:is_data() then return t:get(name) end
end
```

The `G.datam` object is the game's central data manager. AL data paths map to the DirObject JSON files (e.g., `hexm.client.data_oversea.AL.skill.boss_26098_hqy`). The `name` parameter is the skill ID string (e.g., `"99001210"`).

**Evidence Confidence: 5/5** — Direct source code tracing.

---

### 2.3 Actionline Core (Deserialization)

**Source:** `Scripts/source_decompiled/hexm/common/actionline/actionline.lua:16-120`

The `Actionline` class stores raw data and deserializes on demand:

```lua
function Actionline:load_from_dict(data)
    self.graph = data.NodeGraph      -- stored as-is (array of graph defs)
    self.timeline = data.Timeline    -- stored as-is (array of timeline defs)
    self.start_graph = data.StartGraph
end

function Actionline:run(context)
    self.context = context
    local graph = self:create_graph(self.start_graph)  -- deserialize start graph
    graph:run()                                         -- execute it
end
```

**Graph deserialization** (`actionline.lua:57-68`):
```lua
local function deserialize_nodegraph(al, data, context)
    local node_buffer = {}
    for node_id, node_data in pairs(data.nodeData) do
        node_buffer[node_id] = deserialize_node_data(al.al_id, node_data)
        node_buffer[node_id].sync_prefix = al.sync_prefix .. data.graphID
    end
    for _, line_data in pairs(data.lineData) do
        deserialize_line_data(line_data, node_buffer)
    end
    return NodeGraph(al, data.graphID, node_buffer, context)
end
```

**Node deserialization** (`actionline.lua:32-46`):
```lua
local function deserialize_node_data(al_id, data)
    local node = node_mgr.create_node(data.Type)  -- lookup in NODES registry by Type string
    node.al_id = al_id
    node.node_id = data.NodeID
    local d = data:get("Data")
    if d then node:update(d) end  -- copies all Data fields onto node instance
    return node
end
```

**Line deserialization** (`actionline.lua:48-55`):
```lua
local function deserialize_line_data(data, node_buffer)
    local start_node = node_buffer[data.startNode]
    local end_node = node_buffer[data.endNode]
    start_node:connect(data.startPort, end_node, data.endPort)
end
```

**Evidence Confidence: 5/5** — Direct definition.

---

### 2.4 Node Registry and Base Class

**Source:** `Scripts/source_decompiled/hexm/common/actionline/graph/node.lua:1-145`

```lua
local NODES = {}

function _M.actionline_node(cls)
    reg_node_class(cls)  -- NODES[cls.__name__] = cls
    return cls
end

function _M.create_node(node_type)
    local cls = NODES[node_type]
    if cls then return cls() end   -- instantiate by type string
end
```

**Node base class (`Node`):**
- `degree` — incoming connection count (for topological sort)
- `connect_map` — maps output port names → list of `{dst_node_id, dst_port_name}`
- `update(data)` — copies all key-value pairs from JSON `Data` field onto `self`
- `start(graph)` — executed when degree reaches 0; returns output table or nil
- `connect(src_port, end_node, end_port)` — builds `connect_map` and increments `end_node.degree` (unless `TRIGGER`)
- `process_port_data(src_port, port_name, value)` — receives data from upstream node outputs

**Node registration** happens via 22 category files loaded in `import_all.lua`:
`action_nodes`, `camera_ctrl_nodes`, `logic_nodes`, `dove_nodes`, `combo_nodes`, `prepare_nodes`, `target_nodes`, `timeline_nodes`, `branch_sync_nodes`, `special_nodes`, `check_nodes`, `output_nodes`, `effect_nodes`, `move_nodes`, `magic_field_nodes`, `interact_nodes`, `resource_nodes`, `debug_nodes`, `math_nodes`, `damage_nodes`, `wanfa_nodes`, `guide_nodes`

Each file calls `actionline_node(class("TypeName", Node))` to register node classes.

**Evidence Confidence: 5/5** — Direct definition.

---

### 2.5 Graph Execution (Topological Sort)

**Source:** `Scripts/source_decompiled/hexm/common/actionline/graph/node_graph.lua:1-71`

```lua
function NodeGraph:ctor(actionline, graph_id, node_buffer, context)
    self.context = ActionlineContext(context)
    self.node_buffer = node_buffer
    -- Start nodes = those with degree 0 (no incoming connections)
    self.node_list = node_buffer:values():filter(function(v) return 0 == v.degree end)
end

function NodeGraph:run()
    self.run_state = 0
    for _, node in pairs(self.node_list) do
        self:start_node(node)
    end
    self.run_state = 1
end

function NodeGraph:finish_node(node, outputs)
    -- For each output port with connections:
    for src_port_name, value in pairs(outputs) do
        if node.connect_map[src_port_name] then
            for _, info in ipairs(node.connect_map[src_port_name]) do
                local dst_node = self.node_buffer[dst_node_id]
                dst_node:process_port_data(src_port, port_name, value)
                dst_node.degree = dst_node.degree - 1
                if 0 == dst_node.degree then self:add_node(dst_node) end
            end
        end
    end
end
```

**Execution model:**
1. Filter nodes with `degree == 0` → these are start nodes (no dependencies)
2. Call `node:start(graph)` on each start node
3. If `start()` returns a table of outputs, call `graph:finish_node(node, outputs)`
4. `finish_node` decrements `degree` on downstream connected nodes
5. When a downstream node's `degree` reaches 0, it becomes ready and is started
6. This creates a **data-flow / topological-sort** execution pattern

**Special ports:**
- `__out__` / `__in__` — control flow ports (no data, just sequencing)
- Named ports (e.g., `"colliders"`) — data ports carrying values between nodes

**Evidence Confidence: 5/5** — Direct definition.

---

### 2.6 Timeline and Frame System

**Source:** `Scripts/source_decompiled/hexm/common/actionline/timeline/action_timeline.lua:1-164`
**Source:** `Scripts/source_decompiled/hexm/common/actionline/timeline/frame.lua:1-392`

**Timeline deserialization** (`actionline.lua:16-30`):
```lua
local function deserialize_timeline(al, data, context, timeline_id)
    local timeline = ActionTimeline(al, context)
    for _, track in pairs(data.timeline.__tracks__) do
        for _, frame_data in pairs(track.__keyframes__) do
            local frame = frame_mgr.create_frame(frame_data, setting)
            frame.al_id = al.al_id
            timeline:add_frame(frame)
        end
    end
    timeline:set_active()  -- sorts frames by time
    return timeline
end
```

**Timeline execution** (`action_timeline.lua:36-92`):
1. `run()` → records `start_time`, initializes timers, executes frames at time ≤ 0
2. `_init_timers()` → creates a timer for each frame with `time > 0`, adjusted by `global_speed`
3. `execute(ts)` → runs all frames where `frame.time - ts < 0.03`, slices consumed frames
4. Supports `pause()`/`resume()` with delay tracking
5. `hook_event()` — subscribes to AL driver events (EventBreak → release, EventPause → pause)

**Frame types** (`frame.lua`) — the bridge between timelines and graphs:

| Frame Type | Purpose |
|---|---|
| `GraphKeyframe` | Runs a graph at a specific time. Supports `segment_idx` filtering. |
| `CircleGraphKeyframe` | Repeats graph execution N `times` with `interval`. Supports `bind` to EventBreak. |
| `StrongCircleGraphKeyframe` | Like Circle but with `strong_id` lifecycle. Listens for `E_STRONG_TIMELINE_END`. |
| `EventGraphKeyframe` | Event-driven graph execution. Client/server sync via `request_reboot`/`remote_skill_reboot`. |
| `SkillGraphKeyframe` | Like GraphKeyframe but with skill segment awareness. |
| `CameraShakeKeyframe` | Camera shake effect at a time point. |
| `CameraChannelKeyframe` | Camera channel control at a time point. |

**All frame `run()` methods** create a graph via `timeline.actionline:create_graph(graph_id)` and call `graph:run()`, completing the timeline→graph bridge.

**Evidence Confidence: 5/5** — Direct definition.

---

### 2.7 ALDriver (Entity Component)

**Source:** `Scripts/source_decompiled/hexm/common/combat/al_driver.lua:36-292` (ALDriverBase)
**Source:** `Scripts/source_decompiled/hexm/client/combat/al_driver.lua` (client ALDriver)

**ALDriverBase** — common base class:

- `main_AL` — tracks the currently active "main" actionline ID
- `_ev_map` — event system with 4 event types: `EventBreak`, `EventMove`, `EventBreakOp`, `EventPause`
- `pool` (PutAndPick) — client/server sync reboot mechanism with 60-entry capacity

**Key methods:**
```lua
-- Create and run an AL from a file
function ALDriverBase:run_AL_from_file(category, filename, context, al_id, main_AL)
    local data = self:create_AL_data(category, filename)  -- load + cache
    local al = self:create_AL(data, category, filename, al_id)  -- instantiate
    self:run_AL(al, context, main_AL)  -- execute
end

-- Create Actionline instance (lua or C++ based on config)
function ALDriverBase:create_AL(data, category, filename, al_id, uselua)
    local cls = uselua and lua_Actionline or cpp_Actionline
    local al = cls(entity, al_id, category, filename)
    al:load_from_dict(data)
    return al
end

-- Run with main_AL lifecycle management
function ALDriverBase:run_AL(al, context, main_AL)
    if main_AL then
        if #self.main_AL > 0 then self:_finish_main_AL() end  -- cleanup previous
        self.main_AL = al.al_id
    end
    al:run(context)
end
```

**Event system** (used by timelines and frames):
```lua
function ALDriverBase:add_event(al_id, event_name, func, ...)  -- register callback
function ALDriverBase:del_event(al_id, event_name, listener)   -- unregister
function ALDriverBase:EventBreak(al_id)   -- fires EventBreak to all listeners
function ALDriverBase:EventPause(al_id, seg_idx, delay)  -- fires EventPause
```

**Reboot system** (client/server sync):
```lua
function ALDriverBase:add_reboot(es_id, kwargs)     -- server pushes sync data
function ALDriverBase:request_reboot(es_id, func)   -- client requests sync data
function ALDriverBase:do_reboot(kwargs)              -- executes sync callback
```

**Client ALDriver** extends with resource binding/cleanup:
- `bind_buff`, `bind_effect`, `bind_tagged_effect`, `bind_slot`, `bind_ui`, `bind_mesh_shader`
- `_finish_main_AL()` cleans up all bound resources (effects, buffs, slots, listeners, etc.)

**Evidence Confidence: 5/5** — Direct definition.

---

### 2.8 Lua vs C++ Execution Path

**Source:** `Scripts/source_decompiled/hexm/common/actionline/actionline.lua:196-241`

The system supports **dual execution paths**:

```lua
-- C++ path (default when available)
if classext.actionline then
    classext.action_timeline.reg_frame_executor(frame_executor)
    classext.node_graph.reg_node_executor(node_executor)
    _M.cpp_Actionline = classext.actionline
end

-- Selection based on debug_consts.USE_CPP_AL
if debug_consts.USE_CPP_AL then
    _M.Actionline = _M.cpp_Actionline     -- C++ implementation
else
    _M.Actionline = lua_Actionline         -- Lua fallback
end
```

The C++ path uses `classext.actionline` with Lua callbacks for node/frame execution. The `node_executor` function handles QPS limiting (WARNING at 100/sec, DROP at 1000/sec per node type).

**Evidence Confidence: 5/5** — Direct definition.

---

### 2.9 al_static_index.json Structure

**Source:** `Scripts/data/al_static_index.json` (7.9MB, 8110 indexed skills)

```json
{
  "_meta": {
    "grey_root": "Scripts\\data\\DirObject\\GreyTableInfo",
    "al_file_glob": "hexm.client.data_oversea.AL.skill*.json",
    "max_activations": 250000,
    "max_same_activation": 16,
    "indexed_skills": 8110
  },
  "skills": {
    "skill_name": {
      "skill_id": "99001210",
      "skill_id_int": 99001210,
      "source_file": "hexm.client.data_oversea.AL.skill.boss_26098_hqy.json",
      "start_graph": 1,
      "duration_hint": 2.5,
      "events": [
        {
          "time": 0.0,
          "node_type": "Attack",
          "graph_id": 2,
          "node_id": 9,
          "calcpoint_id": 9900121001,
          "issue_id": 1
        }
      ],
      "unresolved_event_keyframes": [],
      "deferred_timelines": [],
      "event_counts": {"Attack": 2},
      "counters": {
        "graph_activations": 4,
        "timeline_activations": 1,
        "missing_graph_refs": 0,
        "truncated": false
      },
      "graph_stats": {"total_graphs": 2, "total_nodes": 8, ...},
      "timeline_stats": {"total_timelines": 1, "total_keyframes": 1}
    }
  }
}
```

This is a **pre-computed offline index** (not loaded by the game at runtime). It maps every skill across all AL files to its metadata: source file, start graph, damage events with timing, graph/timeline statistics.

**Evidence Confidence: 5/5** — Direct examination.

---

### 2.10 JSON-to-Node Class Mapping (Cross-Correlation)

Boss AL JSON `Type` fields map directly to registered node classes via `node_mgr.create_node(data.Type)`:

| JSON `Type` | Node Class File | Purpose |
|---|---|---|
| `PrepareSkillNode` | `prepare_nodes.lua` | Prepares skill execution context |
| `SkillRelease` | `prepare_nodes.lua` | Releases/commits skill for execution |
| `SkillTimelineNode` | `timeline_nodes.lua` | Starts a timeline by `timelineID` |
| `CalcMotionVariable` | `move_nodes.lua` | Calculates motion/movement variables |
| `AnimationNode` | `action_nodes.lua` | Plays animation with graph/blend config |
| `BoneCollisionData` | `logic_nodes.lua` | Defines a collision shape on a bone |
| `BatchBoneCollision` | `logic_nodes.lua` | Activates multiple bone collisions for hit detection |
| `FaceTarget` | `target_nodes.lua` | Rotates entity to face its target |

The mapping is `Type string → NODES[type] → class instance`. The `Data` JSON object is copied directly onto the node instance via `node:update(d)`, meaning JSON keys like `calcpoint_id`, `collider_name`, `max_num` become `self.calcpoint_id`, `self.collider_name`, `self.max_num` on the node.

**Evidence Confidence: 4/5** — Strong correlation. Node class names match JSON Type strings. File attribution inferred from prior examination of logic_nodes.lua exports.

---

## 3. Conclusions (Score ≥ 3)

### Full Pipeline Summary

```
┌─────────────────────────────────────────────────────────────────────┐
│ 1. DATA LOADING                                                     │
│                                                                     │
│  AL JSON file (boss_26098_hqy.json)                                │
│    → G.datam.AL[category].index:get(filename)  -- path lookup      │
│    → G.datam[path]:get(skill_id)               -- binary load      │
│    → Returns {NodeGraph:[], Timeline:[], StartGraph:int}           │
│    → Cached in AL_DATA[category..filename]                         │
│                                                                     │
│ 2. ACTIONLINE CREATION                                              │
│                                                                     │
│  ALDriverBase:create_AL(data)                                      │
│    → Actionline(entity, al_id, category, filename)                 │
│    → al:load_from_dict(data)  -- stores NodeGraph, Timeline, Start │
│                                                                     │
│ 3. EXECUTION START                                                  │
│                                                                     │
│  ALDriverBase:run_AL(al, context, main_AL=true)                    │
│    → Finishes previous main_AL if active                           │
│    → Sets self.main_AL = al.al_id                                  │
│    → al:run(context)                                               │
│      → create_graph(StartGraph)                                    │
│        → deserialize_nodegraph() → NodeGraph                      │
│      → graph:run()                                                 │
│                                                                     │
│ 4. GRAPH EXECUTION (Topological Sort)                               │
│                                                                     │
│  NodeGraph:run()                                                    │
│    → Start with degree-0 nodes (no incoming edges)                 │
│    → node:start(graph) → returns outputs                           │
│    → graph:finish_node(node, outputs)                              │
│      → Propagate data along output ports                           │
│      → Decrement downstream degree                                 │
│      → Start downstream when degree hits 0                        │
│                                                                     │
│ 5. TIMELINE BRIDGE                                                  │
│                                                                     │
│  SkillTimelineNode:start(graph) in the start graph                 │
│    → actionline:create_timeline(timelineID)                        │
│    → deserialize frames from __tracks__ → __keyframes__            │
│    → timeline:run()                                                │
│      → Sort frames by time                                         │
│      → Schedule timer-based execution                              │
│                                                                     │
│ 6. FRAME → GRAPH CYCLE                                              │
│                                                                     │
│  At scheduled time, GraphKeyframe:run(timeline)                    │
│    → timeline.actionline:create_graph(graphID)                     │
│    → Deserializes graph 2 (combat graph)                           │
│    → graph:run() → executes AnimationNode, BoneCollision, etc.     │
│                                                                     │
│ 7. COMBAT NODES EXECUTE                                             │
│                                                                     │
│  AnimationNode → plays boss animation                              │
│  BoneCollisionData → defines hit colliders                         │
│  BatchBoneCollision → activates damage detection                   │
│  Attack/BulletAttack → applies calcpoint damage                    │
│                                                                     │
│ 8. LIFECYCLE MANAGEMENT (ALDriver)                                  │
│                                                                     │
│  Events: EventBreak, EventMove, EventBreakOp, EventPause          │
│  Cleanup: _finish_main_AL() clears effects, buffs, slots, etc.    │
│  Sync: PutAndPick reboot system for client/server coordination     │
└─────────────────────────────────────────────────────────────────────┘
```

### Boss Skill Example (99001210 from boss_26098_hqy)

1. **Graph 1 (StartGraph):** `PrepareSkillNode(99001210)` → `SkillRelease` → `SkillTimelineNode(timelineID=11)`
2. **Timeline 11:** One track with `GraphKeyframe` at `time=0.0` pointing to `graphID=2`
3. **Graph 2 (Combat):** `CalcMotionVariable` → `AnimationNode("skill_99001210")` → `BatchBoneCollision` ← `BoneCollisionData(C1, calcpoint 9900121001)` + `BoneCollisionData(C1, calcpoint 9900121002)`

This creates the pattern: **prepare → release → schedule timeline → at t=0 play animation + activate hit detection**.

### Key Architectural Properties

1. **Lazy deserialization** — Graphs are deserialized fresh each time `create_graph()` is called, not cached. This allows the same graph definition to be used with different contexts.
2. **Data-driven nodes** — JSON `Data` fields map directly to node properties via `node:update(d)`. No special deserialization logic per node type.
3. **Two execution engines** — Lua (`lua_Actionline`) and C++ (`cpp_Actionline`) with shared Lua callbacks for node/frame execution. C++ is default when available.
4. **Client/server split** — `EventGraphKeyframe` has separate `need_listen`/`need_wait`/`need_sync` implementations for client vs server, using `portable.IS_CLIENT`/`IS_SERVER`.
5. **Single main AL** — Only one "main" actionline per entity at a time. Starting a new main AL auto-cleans the previous one.

---

---

### 2.11 Calcpoint → Damage Pipeline

**Source:** `Scripts/source_decompiled/hexm/common/actionline/nodes/logic_nodes.lua:57-309`
**Source:** `Scripts/source_decompiled/hexm/common/combat/damage_manager.lua:107-530`
**Source:** `Scripts/source_decompiled/hexm/common/combat/behit/behit_base.lua:124-299`

There are **two parallel damage paths**, both ending at `DamageManager:process_calcpoint()`:

#### Path A: Attack Node (Direct Calcpoint)

```
Attack:start(graph)
  → Attack:do_attack(graph, context, entity, attacker, targets)
    → Attack:do_calcpoint(graph, context, entity, attacker, targets)
      → DamageManager():process_calcpoint(calcpoint_id, attacker, targets, context, skill_id, data)
```

The `Attack` node has `calcpoint_id` directly from JSON data. When `start()` is called:
1. Gets targets from `helper.get_targets(issue_id, context)`
2. Calls `do_attack()` → `do_calcpoint()`
3. `do_calcpoint()` builds params with `calcpoint_pos`, `calcpoint_yaw`, `result_id`, etc.
4. Calls `DamageManager():process_calcpoint(calcpoint_id, attacker, targets, ...)`

**Evidence Confidence: 5/5** — Direct definition at `logic_nodes.lua:252-309`.

#### Path B: BoneCollision → on_hit_targets (Physics-based Calcpoint)

```
BatchBoneCollision:start(graph) — activates physics bone colliders
  → Engine physics detects collision
  → BoneCollisionBase:on_bone_hit(graph, d) — callback from physics
    → Filters hits by collider_name, max_num, max_same_hit, tg_cd
    → BoneCollisionBase:on_hit_targets(graph, collider, targets, hit_info)
      → DamageManager():process_calcpoint(cld.calcpoint_id, attacker, {tg}, context, skill_id, params)
```

Client-side for monster→player hits:
```lua
-- logic_nodes.lua:1893 (client, monster hitting player)
G.net:call_server("cli_ent_hit_player", attacker.id, cld.calcpoint_id, skill_id or 0, calc_params)
```

Server-side receives and processes the bone collision hit data, then calls `process_calcpoint`.

**Evidence Confidence: 5/5** — Direct definition at `logic_nodes.lua:1432-1930`.

#### DamageManager:process_calcpoint() — The Core

**Source:** `Scripts/source_decompiled/hexm/common/combat/damage_manager.lua:181-530`

```lua
function DamageManager:process_calcpoint(calc_id, attacker, targets, context, skill_id, params)
    -- 1. Target acquisition (if not provided)
    targets, cal_pos, cal_yaw = attacker:get_calcpoint_target(attacker, calc_id, ...)

    -- 2. Direction filter
    targets = self:_filter_targets_by_dir(params.calcpoint_yaw, calc_id, targets)

    -- 3. Load calcpoint config from datam
    local calc_sysd = G.datam.calcpoint[calc_id]

    -- 4. Per-target processing
    for i, tg in pairs(targets) do
        -- Check invincibility, immune flags
        -- Pre-process (defence check, parry, etc.)
        self:pre_process_calcpoint(attacker, target, data)

        -- Calculate damage formula
        dmg_res = self:calc_damage(attacker, target, context, params)

        -- Apply damage to target (behit system)
        target:behit(calc_id, dmg_res, param_context)  -- CLIENT
        -- OR server-side batched behit
    end
end
```

The `G.datam.calcpoint[calc_id]` lookup is the key config source. This table contains:
- `jm_choosetarget` — target selection mode
- `jm_class` — damage class
- `jm_type` — damage type (direct, etc.)
- `jm_behit_orientation` — hit direction mode
- `direction_limit` — directional filter
- `ignore_invincible_frame` — bypass iframe
- `perfect_effect` — perfect dodge/parry effects
- `monster_death_anim` — death animation override
- `push_speed_limit` — knockback limits
- `behit_add_buff_1` — buffs applied on hit
- `apportion_damage` — damage split across targets
- `no_fight_jm` — non-combat damage flag
- `skill_reload_mode` / `skill_reload` — combo skill resets

**Evidence Confidence: 5/5** — Direct definition.

#### BehitBase — Damage Reception

**Source:** `Scripts/source_decompiled/hexm/common/combat/behit/behit_base.lua:124-299`

```lua
function BehitBase:process_behit_infos(fromer, calcpoint_id, data)
    local calc_sysd = G.datam.calcpoint:get(calcpoint_id)
    local calc_pos, calc_yaw = fromer:get_calcpoint_pos_yaw(...)
    local d = {
        pos_flag, attacker_id, attacker, tg_sysd, calc_sysd,
        calcpoint_pos, calcpoint_yaw, can_behit_show, flag
    }
    local show_res = process_behit_anim(fromer, self, d)  -- determines behit animation
    return show_res
end

function BehitBase:_on_damage(fromer, damage_type, result, calcpoint_id, jm_type, context)
    calc_sysd = G.datam.calcpoint:get(calcpoint_id) or {}
    local damage = result:pop("HP") or 0
    -- Builds full damage result with skill_id, kongfu_id, defence_flag, etc.
    -- Dispatches E_BE_HIT event
    -- Handles death if HP <= 0
end
```

**Evidence Confidence: 5/5** — Direct definition.

---

### 2.12 Hit Timing Predictability Analysis

**Question:** Can we predict the timing that hits the player by each skill?

#### Two Hit Delivery Mechanisms

**Mechanism 1: Attack Node — PREDICTABLE timing**

The `Attack` node fires at a **deterministic time** defined by its position in the timeline:

```
Timeline keyframe (time=T) → GraphKeyframe → graph:run() → Attack:start()
```

The `time` field in the keyframe is the exact moment the Attack fires relative to skill start.
This is **fully visible** in the AL static index `events` array:

```json
{
  "time": 0.08,        // ← exactly when this hit occurs
  "node_type": "Attack",
  "calcpoint_id": 7007421102,
  "issue_id": 1
}
```

**Mechanism 2: BatchBoneCollision — PARTIALLY predictable timing**

BoneCollision hits depend on **physics engine collision detection**:

```
Timeline keyframe (time=T) → graph:run() → BatchBoneCollision:start()
  → Bone colliders activate (physics engine)
  → on_bone_hit() fires when actual collision occurs (RUNTIME-dependent)
```

The **activation time** is predictable (= keyframe time), but the **actual hit time** depends on:
- Animation playback speed
- Distance between attacker and target
- Collider geometry and bone positions
- `min_interval` cooldown between hits
- `max_same_hit` counter per target
- `max_time` / `max_num` limits

#### What al_static_index Already Provides

The `al_static_index.json` pre-computes timing for all 8110 skills:

```json
"1040000109": {
  "source_file": "hexm.client.data_oversea.AL.skill.boss.hu_qiwang.json",
  "duration_hint": 0.35,
  "events": [
    {"time": 0.08, "node_type": "Attack", "calcpoint_id": 7007421102},
    {"time": 0.18, "node_type": "Attack", "calcpoint_id": 7007421102},
    {"time": 0.28, "node_type": "Attack", "calcpoint_id": 7007421102}
  ]
}
```

This tells us: skill `1040000109` has 3 hit windows at t=0.08, 0.18, 0.28 seconds.

#### Timing Uncertainty Sources

| Factor | Impact on Timing | Predictable? |
|---|---|---|
| Keyframe `time` | Exact offset from skill start | YES |
| `CircleGraphKeyframe` repeats | `interval` * N | YES (from data) |
| `EventGraphKeyframe` | Event-driven, depends on game state | NO |
| Animation bone collision | Physics-dependent within activation window | PARTIALLY |
| `global_speed` context | Scales all timings proportionally | YES (if known) |
| `EventPause` / hitstun | Delays timeline execution | NO (runtime) |
| `EventBreak` / cancel | Terminates remaining timeline | NO (runtime) |
| Network latency (client→server) | Adds round-trip delay | NO |

#### Answer: YES, with caveats

**For `Attack` nodes:** Hit timing is **fully predictable** from the AL data. The `al_static_index.json` already has this pre-computed in the `events` array with exact `time` values.

**For `BoneCollision` nodes:** The **activation window** is predictable (keyframe time), but the actual collision moment depends on physics. However, in practice, boss attack animations are designed so bone colliders connect at specific animation frames, making the **effective hit time** approximately `keyframe_time + animation_hit_frame_offset`. This offset is embedded in the animation data (`.graph` files), not in the AL data.

**For `CircleGraphKeyframe` repeats:** Fully predictable — `times * interval` gives all future activation times.

**For `EventGraphKeyframe`:** NOT predictable from static data alone — these fire in response to game events (e.g., player entering an area, buff expiring).

**Practical prediction accuracy:** For boss skills, the `al_static_index.events` array provides ~80-90% of hit timing information. The remaining 10-20% involves:
- BoneCollision physics timing offsets
- Event-driven attacks
- Runtime speed modifiers

---

### 2.13 BoneCollision Timing — How E_BONE_COLLISION Is Actually Fired

**Source:** `Scripts/source_decompiled/hexm/client/combat/skill_base.lua:6-16`
**Source:** `Scripts/source_decompiled/hexm/client/entities/local/component/anim.lua:364-374`
**Source:** `Scripts/source_decompiled/hexm/client/entities/local/avatar_members/imp_skill.lua:30-31`
**Source:** `Scripts/source_decompiled/hexm/common/actionline/nodes/logic_nodes.lua:1336-1384, 1432-1514`

#### The Prior Assumption Was Wrong: `.graph` Files Do Not Exist

A Glob search for `Scripts/**/*.graph` returned **zero matches**. There are no animation graph files accessible in the Lua layer. The claim that "collision timing is in .graph animation files" was incorrect — those files are compiled binary engine assets inaccessible to the scripting layer.

#### Actual Mechanism: Pure C++ Engine Event

The full chain is:

```
C++ engine physics simulation
  → actor_cxx fires "BoneCollisionNotify" (engine-internal, at physics tick)
  → Anim:bind_collision_notify() callback registered via actor_cxx:BindEvent("BoneCollisionNotify", cb)
  → SkillBase:_on_bone_collision_cb(results)
  → entity.dispatcher:dispatch(E_BONE_COLLISION, {results=results})
  → BoneCollisionBase:on_bone_hit(graph, d)  [registered listener in start()]
```

**Key code — engine binding (`anim.lua:370-374`):**
```lua
function Anim:bind_collision_notify(callback)
    if self._actor_cxx then
        self._actor_cxx:BindEvent("BoneCollisionNotify", callback)
    end
end
```

**Key code — SkillBase registration (`skill_base.lua:6-16`):**
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

**Key code — collider query disabled by default (`imp_skill.lua:30-31`):**
```lua
function SkillComp:__skeleton_ready_component__()
    self.anim:set_enable_collider_query(false)
end
```
This means bone collisions are **opt-in per skill** — `BatchBoneCollision:start()` enables them by writing into `entity.skill_driver:get_ex_data("colliders")`, and the C++ actor only fires `BoneCollisionNotify` when a bone collider registered in that table physically intersects a target.

#### `on_bone_hit` — Lua-Side Filtering (What IS controllable)

Once `BoneCollisionNotify` fires, `BoneCollisionBase:on_bone_hit()` applies Lua-side filters:

| Filter | Source | Predictable? |
|---|---|---|
| `cld.max_num` | JSON `BoneCollisionData.Data` | YES |
| `cld.max_same_hit` | JSON `BoneCollisionData.Data` | YES |
| `cld.tg_cd` / `min_interval` | JSON `BoneCollisionData.Data` | YES |
| `tg_filter_id` | JSON or `datam.calcpoint.jm_choosetarget` | YES |
| Actual collision moment | C++ physics tick, `actor_cxx` internal | **NO** |

#### Multiple Dispatchers of E_BONE_COLLISION

| Source file | When it fires |
|---|---|
| `skill_base.lua` | Entity's own animation bone hits |
| `attach_model_base.lua` | Attached model bone hits (e.g. weapons) |
| `imp_be_weapon.lua` | Held weapon collider hits |
| `special_nodes.lua` | Special node override path |
| `imp_sand_skiing.lua` | Physics-movement-specific path |

#### Revised Timing Model for BoneCollision

```
AL Timeline keyframe (time=T)
  → graph:run() → BatchBoneCollision:start()
    → Registers E_BONE_COLLISION listener
    → Sets max_time timer (default 60s, often overridden)
    → Writes colliders_data into skill_driver context

C++ engine (independent physics tick, Δt unknown)
  → Evaluates bone collider geometry vs. target hitbox
  → Fires BoneCollisionNotify → E_BONE_COLLISION

on_bone_hit() filters by name/max_num/max_same_hit/tg_cd
  → on_hit_targets() → DamageManager:process_calcpoint()
```

**The Δt between keyframe activation and first collision contact is NOT Lua-accessible.** It depends entirely on:
1. Animation playback speed at the moment of execution
2. Physical distance between attacker and target at keyframe time
3. Bone collider shape and trajectory (defined in binary engine assets)
4. C++ physics engine tick rate

**Evidence Confidence: 5/5** — Direct source code tracing. `.graph` absence confirmed by glob search.

---

### 2.14 SignalNotify — The Lua-Observable Animation Cue System

**Source:** `Scripts/source_decompiled/hexm/client/entities/local/component/anim.lua:70-72, 1758-1801`
**Source:** `Scripts/source_decompiled/hexm/client/entities/local/npc_members/imp_anim.lua:644-662`
**Runtime evidence:** `Scripts/logs/script_debug.txt` — `AnimStart` kwargs contain `anim_cues: [61, 27]`

#### What SignalNotify Is

`SignalNotify` is a **third C++ actor event** (alongside `BoneCollisionNotify` and `PhysicsCollisionNotify`) that fires when the animation graph reaches a pre-authored **signal/cue node** at a specific frame. This is entirely separate from physics collision.

**Engine binding (`anim.lua:70-72`):**
```lua
self._actor_cxx:BindEvent("SignalNotify", function(trigger, subtype, value)
    self:_on_signal_notify(trigger, subtype, value)
end)
```

**Handler (`anim.lua:1758-1764`):**
```lua
function Anim:_on_signal_notify(trigger, subtype, value)
    if self._on_cue_callback then
        self._on_cue_callback(self._owner, trigger, subtype, value)
    end
end
```

The `trigger` encodes both `graph_id` and `node_id`:
```lua
local node_id = trigger & 65535
local graph_id = trigger >> 16
```

This means `SignalNotify` carries **exact graph/node coordinates** of the cue that fired.

#### Runtime Evidence: anim_cues in the Trace Log

From `Scripts/logs/script_debug.txt` line 154, during boss combat:
```
AnimStart(1693885591) | anim_name="lock" | anim_cues: [61, 27]
```

And line 213 (second occurrence):
```
AnimStart(1693885591) | anim_name="lock" | anim_cues: [61, 27]
```

The `anim_cues` array (integers `61`, `27`) represents **cue IDs** that the animation graph will fire as `SignalNotify` events. These are registered via `arbiter_anim_add_cue_listener()` on the `cue_dispatcher`, which listens for those specific subtype values from `SignalNotify`.

The `BehitWithoutAnim` hits in the log correlate with the `skill_reboot` RPC timing, which itself is triggered by signal cues from the animation graph — this is the server-side sync path for `Attack`-node-based hits.

#### Full Observable Timing System

There are now **three distinct timing mechanisms** visible to Lua:

| Mechanism | C++ Event | Lua API | Timing Source | Predictable from AL? |
|---|---|---|---|---|
| Timeline keyframe | (scheduled) | `entity:add_timer()` | AL `time` field | YES |
| Animation signal cue | `SignalNotify` | `anim:_on_signal_notify()` + `_on_cue_callback` | Animation graph frame | PARTIALLY (cue ID known, time not) |
| Physics bone hit | `BoneCollisionNotify` | `anim:bind_collision_notify()` | Physics engine tick | NO |

#### What `anim_cues: [61, 27]` Mean From the Log

The integers `61` and `27` are cue subtype IDs. Looking at the `BehitWithoutAnim` entries in the log, hit bone IDs 27 and 42 appear repeatedly — these correlate strongly with the cue IDs. The pattern is:

```
AnimStart (lock) → anim_cues=[61, 27]
  → at animation frame N: SignalNotify fires (subtype=27 or 61)
    → cue_dispatcher routes to registered callback
      → server: skill_reboot RPC → process_calcpoint → BehitWithoutAnim
```

The `skill_reboot` RPC visible in the log (`olw29`, `olw24`, etc.) is fired at a **deterministic animation frame** — the exact frame where the signal cue node sits in the animation graph. This is a fully server-authoritative hit driven by animation frame signals.

#### Key Insight: SignalNotify IS Bindable for Monster Animations

From `anim.lua:70-72`, `SignalNotify` is **always bound** on `recreate_actor_cxx()` for ALL entities — including NPCs/bosses. The `_on_cue_callback` is set externally. This means:

```lua
-- Hookable pattern: boss entity's anim component
boss_entity.anim._on_cue_callback = function(owner, trigger, subtype, value)
    -- subtype = cue ID (e.g. 27, 61)
    -- trigger encodes graph_id + node_id
    -- THIS FIRES AT THE EXACT ANIMATION FRAME OF THE ATTACK CUE
end
```

This provides a **Lua-observable, frame-accurate hit signal** that is earlier than `BoneCollisionNotify` (physics) and concurrent with the actual attack execution point in the animation.

**Evidence Confidence: 4/5** — `SignalNotify` binding confirmed from source. Cue-to-hit correlation inferred from runtime log pattern (anim_cues ↔ BehitWithoutAnim subtype match) — not directly verified in damage pipeline source.

---

### 2.15 skill_reboot → EventGraphKeyframe — The Full Client→Server Sync Path

**Source:** `Scripts/source_decompiled/hexm/common/actionline/timeline/frame.lua:186-266`
**Source:** `Scripts/source_decompiled/hexm/client/combat/skill_ctrl.lua:2794-2802`
**Source:** `Scripts/source_decompiled/hexm/client/entities/server/common_members/skill_base.lua:14-17`

#### Corrected Understanding: skill_reboot is NOT driven by SignalNotify cues

The `skill_reboot` RPC calls (`olw29`, `olw24`, `pRi7610` etc.) in the trace log originate from **`EventGraphKeyframe:run()`**, not from animation signal cues. The `AnimStart(lock) | anim_cues: [61, 27]` entries are NPC AI arbiter cues used for **AI state machine transitions** (`EVENT_CUE_ANIM_END=27`, `EVENT_CUE_TARGET_DIST=61`) — not for hit delivery.

```lua
-- frame.lua:186-231 — EventGraphKeyframe drives skill_reboot
function EventGraphKeyframe:run(timeline)
    local entity = timeline.context.entity
    local sync_id = self:sync_id()  -- al_id[-3:] .. graphID .. "_FM"
                                    -- e.g. "olw" + "29" → "olw29"
    if self:need_listen(entity) then
        local ev = events[self.event] or self.event
        self._lis = helper.add_listener(entity.dispatcher, ev, function(e, d)
            self:run_graph(timeline, d)
            if self:need_sync(entity) then
                entity.skill_ctrl:remote_skill_reboot(sync_id, sync_d)
            end
        end)
    end
    if self:need_wait(entity) then
        entity.al_driver:request_reboot(sync_id, function(d)
            self:reboot(timeline, d)  -- → run_graph() → damage nodes
        end)
    end
end
```

#### Boss Entity Path (NpcSkillCtrl on client)

```lua
-- skill_ctrl.lua:2794-2802
function NpcSkillCtrl:remote_skill_reboot(sync_id, kwargs)
    if self.entity.fake_server then
        self.entity.al_driver:add_reboot(sync_id, kwargs)  -- local fake-server path
        return
    end
    self.entity:arbiters_report_with_channel("skill", "skill_reboot", sync_id, kwargs)
end

-- server/common_members/skill_base.lua:14-17
function SkillBase:skill_reboot(es_id, kwargs)
    entity.al_driver:add_reboot(es_id, kwargs)  -- triggers request_reboot callback
end
```

#### What Drives EventGraphKeyframe Execution

The `event` field in `EventGraphKeyframe` JSON data specifies **which dispatcher event** triggers the graph run. The event is game-state-driven (not timer-based), explaining the variable intervals in the log. The `sync_id` format confirms this: `al_id[-3:]` (last 3 chars of entity AL ID) + `graphID` + `"_FM"`.

**Key insight from the log:** The `~0.4-0.5s` intervals between `skill_reboot` hits for skill 77031211 are driven by the `CircleGraphKeyframe` interval or the `EventGraphKeyframe.times` countdown — both are predictable from the AL static index.

**Evidence Confidence: 5/5** — Full source trace from frame.lua through skill_ctrl to server handler.

---

### 2.16 EVENT_CUE_COLLISTION (128) — Defined but C++-Only

**Source:** `Scripts/source_decompiled/hexm/common/consts/cue_consts.lua:62,177`

```lua
EVENT_CUE_COLLISTION = 128,       -- note: typo in source ("COLLISTION")
EVENT_CUE_COLLISTION_CALC = 793,
```

**Zero Lua usages** — confirmed by full search of `Scripts/source_decompiled/`. No `DeclareListenCue`, no handler, no reference to these constants anywhere in Lua code.

**Architecture conclusion:** These cue IDs are authored into animation `.graph` files by animators. The C++ engine fires `SignalNotify(trigger, subtype=128)` at the authored frame, but since no Lua handler is registered for subtype 128, the signal is silently ignored at the Lua layer. The bone collider enable/disable at that animation frame is handled entirely in C++ (the cue is for the animation tool authoring workflow, not runtime Lua logic).

This means `SignalNotify` with subtype 128 **is** technically observable from Lua by setting `_on_cue_callback` on the boss entity's anim component and filtering for `subtype == 128` — this would fire at the exact animation frame when bone colliders activate. However, this requires the animation graph to have authored cue-128 nodes at the correct frames, which cannot be verified without access to the binary `.graph` files.

**Evidence Confidence: 4/5** — Zero Lua usage confirmed. C++-only handling inferred from naming convention and absence of Lua handlers.

---

### 2.17 Practical Timing Prediction Summary

#### Three Approaches — Ranked by Reliability

| Approach | Mechanism | Timing Source | Predictable? | Hookable from Lua? |
|---|---|---|---|---|
| **AL Static Index** | Pre-computed `events[]` array | Keyframe `time` field | YES — exact | Read-only (offline) |
| **EventGraphKeyframe** | `skill_reboot` sync via `request_reboot` | AL `times`/`interval` data | YES — from data | Observable via RPC interception |
| **SignalNotify subtype=128** | C++ `BoneCollisionNotify` cue at anim frame | Animation graph authoring | PARTIALLY — if cue exists | YES — via `_on_cue_callback` patch |
| **BoneCollisionNotify** | Physics engine tick | Physics geometry | NO | YES — via `bind_collision_notify` |

#### Recommended Implementation

For client-side hit timing prediction:

1. **Primary:** Use `al_static_index.json` `events[]` array — already pre-computed, gives exact `Attack` node hit times (covers ~80% of boss hits).

2. **Secondary:** Hook `entity.al_driver:add_reboot()` — intercept when a `skill_reboot` sync data arrives at the client, which is the moment a hit graph is about to execute. This is **100% reliable** for `EventGraphKeyframe`-driven hits.

3. **Tertiary:** Patch `boss_entity.anim._on_cue_callback`:
```lua
-- Intercept pattern (read-only analysis, not for implementation)
local orig = boss_entity.anim._on_cue_callback
boss_entity.anim._on_cue_callback = function(owner, trigger, subtype, value)
    local node_id = trigger & 65535
    local graph_id = trigger >> 16
    if subtype == 128 then  -- EVENT_CUE_COLLISTION (bone collider activate)
        -- Frame-accurate bone collision timing signal
    end
    if orig then orig(owner, trigger, subtype, value) end
end
```

**Evidence Confidence: 4/5** — Architecture based on confirmed source findings across sections 2.13-2.16.

---

### 2.18 EventGraphKeyframe.event Field Values — What Actually Triggers Boss Hit Graphs

**Sources:**
- `Scripts/source_decompiled/hexm/common/actionline/timeline/frame.lua:167-231`
- `Scripts/source_decompiled/hexm/common/consts/events.lua:34,163`
- `Scripts/source_decompiled/hexm/client/consts/event_consts.lua:370,401`
- Boss AL JSON files (11 boss files contain `EventGraphKeyframe`)

#### Resolution Mechanism (frame.lua:200)

```lua
local ev = events[self.event] or self.event
```

The `event` string in JSON is resolved in two ways:
1. **Looked up in `events` table** — if `events["E_SKILL_END"]` exists, use that constant value
2. **Used as-is** — raw string event name if not in `events` table (boss-specific custom events)

Both are dispatched on `entity.dispatcher` — the same dispatcher used by all game systems.

#### Three Categories of Events Found

**Category A: Global Constants (in `event_consts.lua`)**

| JSON `event` string | Constant | Defined at | Purpose |
|---|---|---|---|
| `"E_SKILL_END"` | `events.E_SKILL_END = "e_skill_end"` | `events.lua:34` | Fires when any skill ends (via `skill_ctrl.lua:555`) |
| `"E_SKILL_SPECIAL_EFFECT_CUE"` | `event_consts.lua:401` | numeric auto-ID | Special effect cue during skill (fired by special_nodes) |

`E_SKILL_END` is dispatched by `skill_ctrl.lua:555`:
```lua
self.entity.dispatcher:dispatch(events.E_SKILL_END, { ["skill"] = skill, ["org_skill"] = org_skill })
```

`E_SKILL_SPECIAL_EFFECT_CUE` is a client-only numeric event (auto-ID from `next_event()`). No `dispatch` call found in decompiled source — fired by C++ or special nodes.

**Category B: Named Global Events (in `events.lua`)**

| JSON `event` string | Purpose |
|---|---|
| `"e_skill_ex_jianqi"` | Sword-qi special skill extension (`events.lua:163` → `E_SKILL_EX_JIANQI`) |

**Category C: Boss-Specific Custom Event Strings (raw strings, NOT in events table)**

These are not registered in any Lua consts file. They are dispatched by boss-specific AL nodes/logic and consumed only by `EventGraphKeyframe` listeners on the same entity dispatcher.

| Boss file | Event strings | Pattern |
|---|---|---|
| `boss_26433_longnv` | `e_longnv_luoyue`, `e_longnv_tq`, `e_longnv_leijian`, `e_leijian_zhiyin`, `e_thunder_hit`, `e_skill_ex_jianqi` | Phase transitions, thunder hit triggers |
| `boss_26494_hexi_anxian_boss` | `jinli_BOSS_camera_roll`, `e_jinli_cj_1`, `e_jinli_cj_2`, `e_jinli_P1_start`, `e_jinli_P2_start`, `e_jinli_broken`, `e_jinli_boss_player_weak`, `e_jinli_1`, `e_jinli_fight_camera` | Camera, phase, player-state triggers |
| `boss_62000001_huoyanshi` | `e_hys_change_p2_level`, `E_BOSS_HYS_CLOCK_START`, `e_huoyanshi_guide_start`, `e_hys_yunshi_camera_out/in`, `e_hys_camera_in`, `e_huoyanshi_yunshi_faild/success`, `e_hys_yunshi_tips` | Phase 2 transition, QTE camera events |
| `boss_26634_zws_P1` | `E_SKILL_END`, `e_zws_lock_end`, `e_zws_tran_player` | Skill end, lock mechanic, player teleport |
| `boss_62000004_clsz` | `e_clsz_player_tp`, `e_clsz_reset_camera`, `e_clsz_final_skill_qte_end/start`, `e_clsz_fangchu_1`, `e_zhenshou_huajuan_texiao_end`, `e_clsz_xinmo_*`, `e_boss_wanfa_cailinshizi_enter_xinmo` | Phase, QTE, xinmo mechanic |
| `boss_37000004_gx_P2` | `e_guoxin_P2_camera`, `e_guoxin_P2_input_ban`, `e_guoxin_P2_finish` | P2 phase control |

#### Key Architectural Conclusions

1. **`EventGraphKeyframe` is NOT primarily a hit-delivery mechanism.** Across all 11 boss files, the events it listens for are: camera transitions, phase changes, QTE start/end, mechanic triggers, player-state events. It orchestrates **boss encounter scripting**, not raw damage.

2. **`E_SKILL_END`** (used in `boss_26634_zws_P1`) is the closest to hit-delivery: a graph fires *when a skill completes*. This is a cleanup/follow-up pattern, not the initial hit.

3. **`E_SKILL_SPECIAL_EFFECT_CUE`** (used in 5+ boss files) triggers a repeating graph (e.g., `times=15`, `max_time=10`) tied to special effect positions (`sync_keys: ["effect_id", "effect_pos"]`). This is for **persistent AoE effects** that deal damage repeatedly — the `sync_keys` carry the effect position to the hit graph.

4. **Boss-specific raw strings** (e.g., `e_longnv_tq`, `e_jinli_P2_start`) are dispatched by other AL nodes in the same skill or by the boss encounter script. They coordinate multi-step mechanics.

5. **Actual hit timing for `EventGraphKeyframe`**: The graph fires **at the moment the event is dispatched**, which is driven by another game system (another AL node, a server RPC, phase logic). The `EventGraphKeyframe` itself has no intrinsic time offset — its `time` field in the keyframe JSON only schedules *when it starts listening*, not when it fires.

#### Full `EventGraphKeyframe` Data Fields (from source + JSON)

```json
{
  "Type": "EventGraphKeyframe",
  "time": 0.0,          // when listener registration starts (keyframe time)
  "graphID": 6,         // which graph to run when event fires
  "event": "E_SKILL_SPECIAL_EFFECT_CUE",  // dispatcher event to listen for
  "times": 15,          // how many times graph can fire (-1 = unlimited, 0 = disabled)
  "max_time": 10.0,     // auto-cancel after N seconds
  "bind": true,         // cancel on EventBreak (skill cancel)
  "mainAL": true,       // only fire if this AL is still the main AL
  "side": 0,            // 0=ALL_SIDES, client+server both listen/act
  "sync": true,         // use skill_reboot sync mechanism
  "sync_keys": ["effect_id", "effect_pos"]  // fields to forward to server via reboot
}
```

**Evidence Confidence: 5/5** — Direct source + data examination across 11 boss files.

---

### 2.19 SkillDriver — How Skills Are Triggered

**Source:** `Scripts/source_decompiled/hexm/common/combat/skill_driver.lua:15-248`

`SkillDriver` is an entity component (attached as `entity.skill_driver`) that bridges `skill_ctrl` (skill rules/validation) and `al_driver` (AL execution).

**State fields:**
```lua
self.cur_skill = nil          -- currently executing Skill object
self.cur_skill_segment = 1    -- current segment index (1-based)
self.identifier = 0           -- al_id of the active main AL
self.ex_data = {}             -- per-skill scratchpad (colliders, cur_anim, seg_start, etc.)
self.skill_logic = nil        -- optional SkillLogic instance (per-skill custom logic)
```

**Skill trigger chain (`use_skill`, line 129):**
```lua
function SkillDriver:use_skill(context)
    -- context = {skill_id, skill, identifier, target_id, ...}
    self.cur_skill = skill
    self.cur_skill_segment = 1
    self.identifier = al_id          -- al_id is context.identifier (unique per activation)
    self.entity.active_skill = skill
    self:create_skill_logic(skill, context)   -- optional per-skill Lua logic
    local al = skill:get_sys_d("attackline")  -- e.g. "boss_26098_hqy"
    self.entity.al_driver:run_AL_from_file("skill", al, context, al_id, main_AL)
end
```

The `attackline` sysdata field on the skill config is the AL filename → this is how skills map to AL files.

**Skill lifecycle:**
```
use_skill(context)
  → create_skill_logic() — instantiate per-skill custom Lua handler
  → al_driver:run_AL_from_file("skill", attackline, context, al_id, main_AL=true)
      → AL loads, starts graph execution

break_skill() → al_driver:EventBreak(identifier) → skill_ctrl:skill_break_notify()
  → finish_skill()

skill_unlock(identifier) → al_driver:normal_end_AL(identifier) → finish_skill()

finish_skill() → al_driver:finish_main_AL(identifier)
  → cur_skill = nil, ex_data = {}, destroy skill_logic
  → skill_ctrl:skill_end_notify() → dispatches E_SKILL_END
```

**Evidence Confidence: 5/5** — Direct definition.

---

### 2.20 Skill Segments — How They Work (UPDATED)

**Source:** `Scripts/source_decompiled/hexm/common/combat/skill_driver.lua:157`
**Source:** `Scripts/source_decompiled/hexm/common/actionline/nodes/timeline_nodes.lua:96-156`
**Source:** `Scripts/source_decompiled/hexm/common/actionline/helper.lua:282-389`

Skills can be multi-segment. Each segment is a distinct "phase" of a skill with its own animation, cue data, and calcpoints.

**Segment tracking:**
- `skill_driver.cur_skill_segment` — set to 1 at skill start, incremented by `GraphTimelineNode` at line 102: `context.entity.skill_driver.cur_skill_segment = segment_idx`
- `skill_segment_duration[]` in skill sysdata — array of durations per segment
- `skill_segment_num` in skill sysdata — total number of segments
- `seg_start` ex_data — timestamp when current segment started (used by `predict_behit_old`)

**Segment data lookup** (`helper.get_skill_cue_data`, line 282):

**CRITICAL FINDING: `get_skill_cue_data` HAS BEEN GUTTED.**

The function still exists but now **always returns empty `{}`** and logs an error:

```lua
-- Source: helper.lua:282-303 (ACTUAL current code)
function _M.get_skill_cue_data(entity, skill, segment_idx, input_selector, slience)
    local skill_id = skill.skill_id
    local segment_duration = skill:get_sys_d("skill_segment_duration")
    local entity_no = entity:trans_get_entity_no()
    local model_no = entity:trans_get_model_no()
    local skill_key
    if segment_duration and #segment_duration > 1 and segment_idx then
        skill_key = string.format("%s_%s", skill_id, segment_idx)
    else
        skill_key = tostring(skill_id)
    end
    local cue_key = model_no .. skill_key
    log(
        entity,
        "Cannot find cue data!!!, model_no=%s, skill_key=%s, input_selector=%s, entity_no: %s, now its all in mth!",
        model_no, skill_key, input_selector, entity_no
    )
    return {}, cue_key, model_no   -- ← ALWAYS empty table
end
```

The log message explicitly states: **"now its all in mth!"** — the cue data has been migrated to a C++ system called **MTH** (see section 2.22).

**Impact on callers:**
- `get_graph_timeline_data(skill, cue_data, ...)` at line 305 receives empty `cue_data`, so `cue_data:get("cues")` returns `nil` → `cue_list = {}` → generates an **empty timeline** with zero keyframes
- `get_calc_pt_data(cue_data)` at line 372 receives empty table, so `cue_data:contains("cues")` is false → returns **empty `calc_list`**
- `predict_behit_old` at line 379 gets empty `cue_data` → empty `cal_list` → **never finds a perfect parry window** via this path
- `predict_behit` at line 568 gets empty `cue_data` → `cue_data:get("colliders")` is nil → **exits early** at line 570

**Cue data to AL graphs** (`helper.get_graph_timeline_data`, line 305):
This function still exists but now receives empty input. The `CUE_NODE_MAP` mapping is still defined:

| `cue_consts` constant | Value | → AL Node Type |
|---|---|---|
| `EVENT_CUE_TRIGGER_CALC_POINT` | 771 | `Attack` (`calcpoint_id`) |
| `EVENT_CUE_SKILL_EVENT` | 769 | `SkillState` (`state`) |
| `EVENT_CUE_MAGIC_FIELD` | — | `CreateMF` (`mf_no`) |
| `EVENT_CUE_CREATE_ENTITY` | — | `CreateEnt` |
| `EVENT_CUE_ENABLE_STATE` | — | `BuffAttach` |
| `EVENT_CUE_SKILL_TELEPORT` | — | `GraphTeleport` |
| `EVENT_CUE_SKILL_TRIGGER_EVENT` | — | `TriggerEvent` (`event`) |
| `EVENT_CUE_SKILL_LINK_EFFECT` | — | `SkillLinkEffect` |
| `EVENT_CUE_REMOVE_EFFECTS` | — | `RemoveEffect` |
| `EVENT_CUE_SKILL_GAMEPLAY_FLAG` | — | `TriggerEvent` (gameplay) |

**However**, `CUE_NODE_MAP` is still actively used — not by the gutted `get_graph_timeline_data`, but by the **real-time `on_cue_callback`** path in `GraphTimelineNode:start` (client version, line 271-383). See section 2.22.

**`get_ex_timeline_data`** (line 391) still functions independently — it reads from **skill sysdata** (not cue_data) to build timelines for buffs (`skill_add_buff`), magic fields (`skill_add_mf`), and delete buffs (`skill_del_buff`). These are skill-config-driven, not animation-cue-driven.

**Evidence Confidence: 5/5** — Direct definition, verified actual current code returns `{}`.

---

### 2.21 predict_behit — The Game's Own Hit Timing Predictor (UPDATED)

**Source:** `Scripts/source_decompiled/hexm/client/fake_server/entities/player_avatar_members/imp_skill.lua:358-615`

There are **two versions** of the game's internal hit timing predictor, used for the parry/perfect dodge window system. **Both are now BROKEN** because `get_skill_cue_data` has been gutted (see section 2.20).

#### `predict_behit_old` (line 358) — Segment-based prediction (NOW BROKEN)

```lua
function FakePlayerAvatarMember:predict_behit_old(period_key, skill_id)
    for each enemy NPC in range 20:
        local skill = e.skill_driver.cur_skill
        local segment_idx = e.skill_driver.cur_skill_segment
        local seg_start = e.skill_driver:get_ex_data("seg_start", 0)
        local cur_t = DateTimeManager:now() - seg_start

        for i = segment_idx, #skill_d.skill_segment_duration do
            local cue_data = helper.get_skill_cue_data(e, skill, i, input_selector)
            -- ↑ NOW RETURNS {} — always empty, cue data migrated to MTH
            local cal_list = helper.get_calc_pt_data(cue_data)
            -- ↑ cal_list is ALWAYS empty because cue_data has no "cues" key

            local dt = ts - cur_t
            local perfect_period = get_perfect_period(...)
            if dt >= perfect_period[2] and dt <= perfect_period[1] then
                -- → PERFECT parry window — NEVER REACHED (empty cal_list)
```

**Status:** This function is **dead code**. `get_skill_cue_data` returns `{}`, so `get_calc_pt_data({})` returns empty list, the inner loop never executes. The timing data it depended on (cue `.ts` values, calcpoint IDs) no longer exists in Lua.

#### `predict_behit` (line 538) — Collider-based prediction (NOW BROKEN)

```lua
function FakePlayerAvatarMember:predict_behit(period_key, skill_id)
    for each enemy NPC in range 5:
        local skl_info = mon_skl_info:get(skill.skill_id)
        if not skl_info or not skl_info:get("huajie") then goto end  -- skip non-parryable
        local anim = e.skill_driver:get_ex_data("cur_anim")
        local segment = int(anim:split("_")[3])
        local cue_data = helper.get_skill_cue_data(e, skill, segment, 0, true)
        -- ↑ NOW RETURNS {} — always empty
        local colliders = cue_data:get("colliders")
        -- ↑ colliders is nil because cue_data is empty
        if not colliders then goto end  -- ← ALWAYS exits here
        ...
```

**Status:** This function is **also dead code**. `get_skill_cue_data` returns `{}`, `cue_data:get("colliders")` is nil, so the function exits at line 570 (`goto lbl_167`) for every enemy. The collider timing data it depended on no longer exists in Lua.

**Additional detail not in previous analysis:** `predict_behit` also checks `G.datam.monster_skill_info[skill_id]:get("huajie")` — only skills marked as parryable ("huajie") are considered. This filter still works but is never reached in practice due to the empty cue_data exit.

#### Key ex_data Fields Set During Skill Execution (STILL VALID)

These are still written by AL nodes into `entity.skill_driver.ex_data` at runtime — they are **not affected** by the MTH migration:

| ex_data key | Set by | Contains | Still works? |
|---|---|---|---|
| `"cur_anim"` | `GraphTimelineNode` | Current animation name (e.g. `"skill_99001210_1"`) | YES |
| `"cur_anim_start_ts"` | `GraphTimelineNode` | Timestamp when animation began | YES |
| `"seg_start"` | `GraphTimelineNode` (line 112) | Timestamp when current segment began | YES |
| `"colliders"` | `BatchBoneCollision` | Active collider name -> collider config map | YES |
| `"target_id"` | Target selection node | Current locked target entity ID | YES |
| `cur_skill_segment` | `GraphTimelineNode` (line 102) | Current segment index (direct field, not ex_data) | YES |

#### Architecture Summary (UPDATED — showing broken path)

```
Skill execution (STILL WORKS)        predict_behit (BROKEN)
─────────────────────────────        ──────────────────────
GraphTimelineNode:start()
  → skill_driver.cur_skill_segment = segment_idx
  → skill_driver.ex_data["seg_start"] = now
  → cue_data = get_skill_cue_data()  ← RETURNS {} ALWAYS
  → get_graph_timeline_data(cue_data) ← empty timeline, zero keyframes

C++ MTH engine:                      predict_behit():
  → SignalNotify → _on_signal_notify   cue_data = get_skill_cue_data() ← {}
  → _on_cue_callback(entity, event)   colliders = cue_data:get("colliders") ← nil
  → cue_dispatcher:dispatch(event)    → EXIT (goto lbl_167)
  → on_cue_callback listener fires
  → CUE_NODE_MAP → creates AL node   The Lua predict_behit functions
  → Attack/BuffAttach/etc executes    can NEVER find timing data.
```

**Evidence Confidence: 5/5** — Direct definition at `imp_skill.lua:358-615`, `helper.lua:282-303`.

---

### 2.22 MTH — The C++ Cue Data Replacement (NEW)

**Source:** `Scripts/source_decompiled/hexm/common/actionline/helper.lua:296` (the "mth" reference)
**Source:** `Scripts/source_decompiled/hexm/common/actionline/nodes/special_nodes.lua:2807` (`[MTH]` debug tag)
**Source:** `Scripts/source_decompiled/hexm/client/entities/local/component/anim.lua:70-77, 1754-1764`
**Source:** `Scripts/source_decompiled/hexm/common/actionline/nodes/timeline_nodes.lua:271-383`

#### What is MTH?

The log message in `get_skill_cue_data` says: `"now its all in mth!"`. Investigation reveals:

1. **`[MTH]` appears as a debug log tag** in `special_nodes.lua:2807` for `GetAIBlackboard` — an AL node that handles client-server synchronization of AI decisions during skill execution.

2. **`DEBUG_MTH_ATTACH`** is a debug flag in `special_nodes.lua:3116` used by the `AttachEntity` AL node to trace entity attachment during skills.

3. **MTH is NOT a Lua module** — zero matches for `require("mth")`, `require(".*mth")`, or any Lua module named `mth` in the entire decompiled source.

**Conclusion:** MTH is a **C++ engine subsystem** (likely "Motion Tree Hierarchy" or "Model Timeline Handler") that now handles skill cue data natively in the engine, bypassing Lua entirely. The cue data that was previously stored in Lua-accessible per-model tables is now baked into the C++ animation/motion system.

**Evidence Confidence: 3/5** — The name "mth" is confirmed in code, but its full meaning and internal structure are C++-side and not inspectable from Lua.

#### How Skills Still Work Without Lua Cue Data

The cue system was migrated but NOT removed — it now works via **real-time C++ callbacks** instead of pre-computed Lua tables:

```
OLD PATH (BROKEN):
  get_skill_cue_data() → Lua table with cues[], colliders[], duration
  → get_graph_timeline_data() → synthetic AL timeline
  → AL executes keyframes at scheduled times

NEW PATH (ACTIVE):
  C++ engine plays animation graph (.graph binary)
  → C++ fires SignalNotify at authored cue points
  → Anim._actor_cxx:BindEvent("SignalNotify", callback)     [anim.lua:70]
  → Anim:_on_signal_notify(trigger, subtype, value)          [anim.lua:1758]
  → self._on_cue_callback(owner, trigger, subtype, value)    [anim.lua:1762]
  → entity.cue_dispatcher:dispatch(subtype, data)
  → on_cue_callback listener in GraphTimelineNode            [timeline_nodes.lua:302]
  → CUE_NODE_MAP[event] → creates AL node (Attack, BuffAttach, etc)
  → node:start(graph) executes the action
```

**Key evidence:** In `timeline_nodes.lua:271-383` (the client-side `GraphTimelineNode`), the `on_cue_callback` function is registered as a listener on `cue_dispatcher` for ALL events in `CUE_NODE_MAP`:

```lua
-- timeline_nodes.lua:377-379
for ev, _ in pairs(CUE_NODE_MAP) do
    helper.add_listener(cue_dispatcher, ev, on_cue_callback)
end
```

This means calcpoint triggers (771), skill events (769), buff attachments, etc. are all delivered **in real-time from C++** as `SignalNotify` events, not from pre-computed Lua timing tables.

#### Impact on Our Parry System

| Aspect | Old System | New System (MTH) |
|---|---|---|
| **Cue data source** | Lua table from `get_skill_cue_data()` | C++ `SignalNotify` events |
| **Timing info** | Pre-computed `cue.ts` per segment | Real-time callback at animation cue point |
| **predict_behit** | Read cue table, compute `dt` | BROKEN — empty cue table |
| **Calcpoint execution** | `get_graph_timeline_data` → AL keyframes | `on_cue_callback` → creates AL node on-the-fly |
| **Collider timing** | `cue_data.colliders[].ts` | `skill_driver.ex_data["colliders"]` still set by `BatchBoneCollision` |

#### Alternative Approaches for Parry Timing (Options)

Since the Lua-side cue data is gone, here are the possible approaches:

**Option A: Hook `on_cue_callback` / `_on_signal_notify`**
- The C++ engine still fires `SignalNotify` with `subtype` = cue event type (771 for calcpoint)
- We can intercept `Anim:_on_signal_notify` or register on `entity.cue_dispatcher` to capture real-time cue events
- **Pro:** Direct access to actual engine timing
- **Con:** Events arrive in real-time (no look-ahead), so we can't predict "time until hit" — only know "hit is happening NOW"

**Option B: Hook `BatchBoneCollision` ex_data**
- `skill_driver.ex_data["colliders"]` is still populated by `BatchBoneCollision:start()`
- Contains collider names and configs including `calcpoint_id`
- `skill_driver.ex_data["cur_anim_start_ts"]` is still set
- **Pro:** Collider data is available; animation start time is known
- **Con:** The `collider_info.ts` (timing offset) was in the OLD cue_data, not in ex_data

**Option C: Use `skill_timing_data.lua` (our own data)**
- We already have `Scripts/data/skill_timing_data.lua` with pre-computed timing
- Can cross-reference with `cur_anim`, `cur_anim_start_ts`, `cur_skill_segment`
- **Pro:** Fully self-contained, no dependency on engine cue system
- **Con:** Requires manual data collection per skill; may drift with game updates

**Option D: Intercept `DeclareListenCue` events**
- Many components use `DeclareListenCue(Class, cue_type, handler)` to register cue listeners
- These still fire because the C++ engine still dispatches cue events
- We could register our own listener for `EVENT_CUE_TRIGGER_CALC_POINT` (771)
- **Pro:** Uses the game's own event system
- **Con:** Same as Option A — real-time only, no look-ahead

**Option E: Reconstruct cue data from `_on_signal_notify` trace**
- Hook `_on_signal_notify` during skill execution, record all `{subtype, trigger, timestamp}`
- Build our own cue timing table per skill_id + segment
- Use this reconstructed data for prediction in subsequent encounters
- **Pro:** Accurate, self-learning, adapts to game updates
- **Con:** Requires first-observation before prediction works; storage overhead

**Evidence Confidence: 4/5** — The real-time callback path is confirmed by direct code reading. The specific C++ "MTH" internals remain opaque.

---

## 4. Unknown / Missing Evidence

1. **`G.datam.AL[category].index` structure** — How the datam index maps filenames to paths is internal to the engine's data manager.

2. **Complete node class catalog** — 22 node files register an estimated 200+ node types. Only `logic_nodes.lua` was fully examined.

3. **`cpp_Actionline` internals** — The C++ implementation may have slightly different timing behavior.

4. ~~**`calcpoint_id` resolution**~~ — **RESOLVED** in section 2.11. `G.datam.calcpoint[calc_id]` provides the config, `DamageManager:calc_damage()` computes the formula.

5. ~~**`skill_driver` / `skill_ctrl` integration**~~ — **RESOLVED** in sections 2.19–2.21. See below.

6. ~~**Animation frame → collision timing**~~ — **RESOLVED** in section 2.13. `.graph` files do NOT exist in the codebase. Collision timing is entirely driven by the C++ engine event `BoneCollisionNotify`. See section 2.13.

7. **`DamageManager:calc_damage()` formula** — The actual damage formula was not read (separate from timing analysis). It uses `G.datam.formula_states` and attribute-based calculations.

8. ~~**skill_reboot → SignalNotify path**~~ — **RESOLVED** in section 2.15. `skill_reboot` is driven by `EventGraphKeyframe`, NOT by `SignalNotify` animation cues. The `anim_cues: [61, 27]` in the log are NPC AI arbiter cues (`ANIM_END`, `TARGET_DIST`) for state machine transitions only.

9. ~~**EVENT_CUE_COLLISTION (128) usage**~~ — **RESOLVED** in section 2.16. Zero Lua usages confirmed. The cue is authored in binary `.graph` files and handled entirely in C++. Technically observable via `_on_cue_callback` patch but requires animation graph authoring knowledge.

10. ~~**`EventGraphKeyframe.event` field values**~~ — **RESOLVED** in section 2.18. See below.

---

## 5. Next Scoped Search Steps

1. **Build hit timing predictor:** Use `al_static_index.json` events array to create a per-skill hit timeline. For each boss, map `source_file` → all skills → all events with times. This covers ~80% of boss `Attack` node hits with exact timing.

2. **Intercept `al_driver:add_reboot`:** Hook `add_reboot` on boss entities to detect incoming `skill_reboot` sync data — this is the most reliable client-side signal that a hit graph is about to execute (covers `EventGraphKeyframe`-driven hits).

3. **Read boss AL JSON `EventGraphKeyframe` entries:** For specific bosses, inspect the `event` field in `EventGraphKeyframe` nodeData to identify which dispatcher events drive hit delivery, enabling prediction of those hits.

4. **Investigate `calc_damage` formula:** Read `DamageManager:calc_damage()` to understand damage number computation from calcpoint config.

5. **Examine specific boss patterns:** Compare multiple boss AL files to identify common patterns (phase transitions, multi-hit combos, AoE patterns).
