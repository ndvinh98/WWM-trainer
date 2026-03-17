# Question / Scope

How many distinct oddity/qizhen types exist, what are their English names, and how does each type get interacted with programmatically? Can they be auto-collected?

# Evidence

## Phase 1: Identifying All Qizhen Types

- Source: `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.spaces.*.map_gameplay_data.json`
  Excerpt: Marker type `132` (`QIZHEN_TRACE`) lists 786 serial IDs across spaces s1, s2, s501, s502.
  Why it matters: These are ALL world entities registered as qizhen/oddity markers.
  Evidence Confidence: 5/5

- Source: Cross-reference of `map_gameplay_data[132].sids` → entity `relate_wanfa_no` → `region_game_config[game_id].type`
  Excerpt: 782 out of 786 sids mapped to 19 distinct game types.
  Why it matters: This is the authoritative count of qizhen type variants.
  Evidence Confidence: 5/5

## Phase 2: Type-to-Name Mapping

- Source: `region_game_config[*].name` resolved via `translate_words_map_en.json`
  Evidence Confidence: 5/5

| Type | Count | English Name | Const Name |
|------|-------|-------------|------------|
| 19 | 30 | **Mantis** (Ironwing Mantis) | `REGION_GAME_CHEST_FLY` |
| 25 | 30 | **Airborne Chest / Throat-cutting Mushroom** | `REGION_GAME_KZBX` |
| 27 | 31 | **Crate Pile / Stone Pile / Jar Pile** (destructible) | `REGION_GAME_PSBX` |
| 29 | 30 | **Soultaker Lotus** (Enchanting Lotus / Baimulian) | `REGION_GAME_QZBML` |
| 33 | 32 | **Beehive / Honeycomb** (Fengwo) | `REGION_GAME_Fengwo` |
| 46 | 59 | **Bird's Nest / Swallow's Nest** (Yanwo) | `REGION_GAME_YANWO` |
| 53 | 66 | **Suspicious Mouse / Peculiar Rat** (Chase Mouse) | `REGION_GAME_CHASE_MOUSE` |
| 55 | 60 | **Golden Toad** (Jinchan) | — (no named const, uses storyline) |
| 60 | 63 | **Kaifeng** (Yuguizhi / Jade Twig bird) | — (uses storyline) |
| 63 | 32 | **Thunderous Fluff** (Leigongxu) | — (uses storyline+client) |
| 69 | 54 | **Udumbara Flower** (Youtanpoluohua) | — (uses storyline) |
| 70 | 31 | **Shadowdart Flying Catfish** (Nianyu / Catfish) | — (uses client handler) |
| 71 | 46 | **Jade Rabbit** (Feitianwuyuetu) | `REGION_GAME_FEI_TIAN_WU_YUE_TU` |
| 77 | 30 | **Kunshan Azure Bird** (Qingniao) | `REGION_GAME_KUN_SHAN_QING_NIAO` |
| 79 | 20 | **Nine-Colored Deer** (Jiuselu) | — (uses storyline) |
| 92 | 34 | **Darksteel Armor / Mystic Gold Armor** (Xuanjinjia) | — (uses storyline) |
| 93 | 26 | **Bamboo Ray / Bamboo Wenyao** (Zhuwenyao) | — (uses storyline) |
| 94 | 36 | **Dangkang Pottery / Pottery Swine** (DKT) | — (uses client handler) |
| 110 | 36 | **Jade Cicada** (Yumingchan) | — (uses storyline) |

Total: **19 distinct qizhen types**, **782 world instances**.

## Phase 3: Handler Architecture

- Source: `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.region_game_type_config.json`
  Evidence Confidence: 5/5

Each type resolves through one of three handler paths:

### Path A: Dedicated Client Handler (`client_handler` field)
| Type | Handler Class | Interaction Mechanism |
|------|--------------|----------------------|
| 19 (Mantis) | `RegionGameServerTanglang` | Listen for `interact_no` from custom config, adds chase marker, waits for AI interact events |
| 25 (Airborne Chest) | `RegionGameServerKZBX` | Distance detection to `t_reward_serial_no`, auto-completes on touch via `notify_server("touched")` |
| 29 (Soultaker Lotus) | `RegionGameServerBML` | Listens `E_INTERACT_COMPONENT_STATUS_CHANGED`, tracks butterfly guide effects |
| 70 (Catfish) | `RegionGameServerNYFN` | Taiji backtrack events on stone entity, path effects |
| 71 (Jade Rabbit) | `RegionGameServerFTWYT` | Listens for rabbit entity removal events, plays gotten effects |
| 77 (Azure Bird) | `RegionGameServerKSQN` | Distance-based bird detection, proximity check, attach point system |
| 94 (Pottery Swine) | `RegionGameServerDKT` | Collision box detection on DKT entity, dispatches collision events |

### Path B: Common Storyline (`common_storyline` field, no client_handler)
| Type | Storyline | Server Logic |
|------|-----------|-------------|
| 33 (Beehive) | `common/region_game/xi_yu_feng_wo` | `xi_yu_feng_wo` |
| 46 (Bird's Nest) | `common/region_game/com_yanwo_wanfa` | `yan_wo_wan_fa` |
| 55 (Golden Toad) | `common/region_game/com_jinchan_wanfa` | `qi_zhen_jin_chan` |
| 60 (Kaifeng/Bird) | `common/region_game/com_yuguizhi_wanfa` | `qi_qiao_yu_gui_zhi` |
| 63 (Thunderous Fluff) | `common/region_game/com_leigongxu_wanfa` + client `.ets` | `qi_qiao_lei_gong_xu_dan` |
| 69 (Udumbara) | `common/region_game/com_youtanpoluohua_wanfa` | `youtanpoluohua` |
| 79 (Nine-Colored Deer) | via `gameplay_storyline: client/wanfa/weijiemi/jiuselu_client` | — |
| 92 (Darksteel Armor) | `common/region_game/com_xuanjinjia` | — |
| 93 (Bamboo Ray) | via `gameplay_storyline: client/wanfa/weijiemi/zhuwenyao_client` | — |
| 110 (Jade Cicada) | `common/region_game/com_yumingchan` | — |

### Path C: Custom Server + Common Handler
| Type | Common Handler Class |
|------|---------------------|
| 19 (Mantis) | `RegionGameHandlerTanglang` (from `region_game_consts.get_common_handler_cls_by_type`) |
| 27 (Crate Pile) | `RegionGameHandlerDestruceXishuai` |
| 53 (Chase Mouse) | `RegionGameHandlerChaseMouse` |
| 29 (Soultaker Lotus) | `RegionGameHandlerBaiMuLian` |

- Source: `Scripts/source_decompiled/hexm/common/consts/region_game_consts.lua:414-438`
  Evidence Confidence: 5/5

## Phase 4: Per-Type Auto-Interaction Feasibility

- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/gameplays/region_game/region_game_server.lua`
  Evidence Confidence: 5/5

### Type 25 — Airborne Chest / KZBX (EASIEST to auto-collect)
- Handler: `RegionGameServerKZBX`
- Flow: On `on_server_game_loaded()`, gets `t_reward_serial_no` position, adds distance detection at 2.5m. On touch → `notify_server("touched")` → game completes.
- **Auto-collect**: Walk within 2.5m of target serial. The game handler does the rest automatically.

### Type 19 — Mantis / Tanglang
- Handler: `RegionGameServerTanglang`
- Flow: Gets `serial_id` and `interact_no` from custom config. On mobile, listens for `E_ACTIVE_INTERACT_RESULT` matching `interact_no`, then adds chase marker. The actual completion is driven by AI/server storyline events.
- **Auto-collect**: Must `trigger_active_interact` with the correct `active_way_no` from interact component status. Multi-step: initial interact → chase → final interact.

### Type 27 — Crate Pile / PSBX (Destructible)
- Handler: `RegionGameHandlerDestruceXishuai` (common handler)
- Config keys: `broken_id`, `ins_entity_cricket_id`, `create_entity_id`, `listen_no`
- Flow: Destroy breakable objects, then interact with revealed entity.
- **Auto-collect**: Requires combat/attack on breakable objects first, then interact.

### Type 29 — Soultaker Lotus / BML
- Handler: `RegionGameServerBML` + `RegionGameHandlerBaiMuLian`
- Flow: Listens `E_INTERACT_COMPONENT_STATUS_CHANGED` for `t_qizhen_id`, tracks butterfly guide effects. Multi-step state progression via interact component.
- **Auto-collect**: Follow guide effects, interact at each state. Complex multi-step.

### Type 33 — Beehive / Fengwo
- Storyline: `common/region_game/xi_yu_feng_wo`
- Config: `t_bee_id`, `t_jibing`, `t_debuff`, `t_distance`
- Flow: Server-driven storyline with bee entities.
- **Auto-collect**: Storyline-driven, needs proximity + correct interaction with bees.

### Type 46 — Bird's Nest / Yanwo
- Storyline: `common/region_game/com_yanwo_wanfa`
- Config: `t_yanwo_serial_no`, `t_yan_serial_no`, `t_yanwo_state`
- Flow: Server-driven with state-based progression.
- **Auto-collect**: Walk near nest, interact through states. Storyline managed.

### Type 53 — Chase Mouse
- Common Handler: `RegionGameHandlerChaseMouse`
- Config: `create_entity_id` (list), `broken_id`, `mouse_speed`, `reward_mouse_id`
- Flow: Break object to spawn mice, chase and catch them. State tracked by `completed_mouse_idx_list`.
- **Auto-collect**: Must break objects and physically catch spawned mouse entities. Very hard to automate cleanly.

### Type 55 — Golden Toad / Jinchan
- Storyline: `common/region_game/com_jinchan_wanfa`
- Config: `serial_id`, `reward_id`
- Flow: Server storyline with single serial target.
- **Auto-collect**: Walk to serial position, storyline handles the rest. Potentially simple if storyline auto-progresses on proximity.

### Type 60 — Kaifeng / Yuguizhi (Jade Twig Bird)
- Storyline: `common/region_game/com_yuguizhi_wanfa`
- Config: `serial_id`, `twig_id`, `bird_speed*`, `bird_fly`, `bird_run`
- Flow: Chase a bird entity at various speeds.
- **Auto-collect**: Must physically follow bird entity. Hard to automate without movement control.

### Type 63 — Thunderous Fluff / Leigongxu
- Storyline: `common/region_game/com_leigongxu_wanfa` + client ETS
- Config: `serial_id` (list), `seed_id`, `seed_speed`
- Flow: Chase seed entities.
- **Auto-collect**: Similar to bird chase but with seeds. Requires movement.

### Type 69 — Udumbara Flower
- Storyline: `common/region_game/com_youtanpoluohua_wanfa`
- Config: `flower_ins_id`, `true_flower_ins_id`, `fake_flower_ins_id`, `light_ins_id`, `limit_time`
- Flow: Timed puzzle — find real flower among fakes using light.
- **Auto-collect**: Must identify `true_flower_ins_id` and interact with it within time limit.

### Type 70 — Shadowdart Catfish / NYFN
- Handler: `RegionGameServerNYFN`
- Flow: Uses taiji backtrack on `stone_ins_id`, fish path effects. Listens `E_TAIJI_BACKTRACK_*` events.
- **Auto-collect**: Must trigger taiji backtrack ability on specific stone. Requires specific skill usage.

### Type 71 — Jade Rabbit / FTWYT
- Handler: `RegionGameServerFTWYT`
- Config: `rabbit_ins_id`, `trap_ins_id`, `pipa_ins_id`, `gameplay_type`
- Flow: Listens for rabbit entity removal. Plays effect when rabbit is caught.
- **Auto-collect**: Rabbit trapping gameplay. Requires specific entity interaction.

### Type 77 — Kunshan Azure Bird / KSQN
- Handler: `RegionGameServerKSQN`
- Config: `qingniao_ins_id` (list), `check_distance`
- Flow: Distance-based bird detection at `check_distance` (default 2m). Creates bird entities, checks proximity alternating left/right.
- **Auto-collect**: Walk close to each bird in sequence. Distance-based, potentially automatable with movement.

### Type 79 — Nine-Colored Deer / Jiuselu
- Storyline: `client/wanfa/weijiemi/jiuselu_client`
- Config: `deer_ins_id`, `jiuselu_cloud`, `jiuselu_tree`, camera refs
- Flow: Client-side storyline with camera/visual puzzle elements.
- **Auto-collect**: Complex visual puzzle, very hard to automate.

### Type 92 — Darksteel Armor / Xuanjinjia
- Storyline: `common/region_game/com_xuanjinjia`
- Config: `xjj_ins_entity`, `hole_list`, `difficulty_level`
- Flow: Puzzle with holes of varying difficulty.
- **Auto-collect**: Puzzle-based, difficulty varies. Potentially scriptable if puzzle solution is known.

### Type 93 — Bamboo Ray / Zhuwenyao
- Storyline: `client/wanfa/weijiemi/zhuwenyao_client`
- Config: `zwy_list`, `zwy_ins_entity`, `zwy_speed`, `waterlevel`, `ins_navipoint_id`
- Flow: Chase entity in water at various speeds.
- **Auto-collect**: Speed-based chase in water. Hard to automate.

### Type 94 — Pottery Swine / DKT
- Handler: `RegionGameServerDKT`
- Config: `dkt_ins_entity`, `collision_box_*`, `ins_trap_id_list`, `explosion_item`
- Flow: Collision detection box on pottery entity. Player touches collision box → dispatches event → AI reacts.
- **Auto-collect**: Walk into collision box near the entity. Potentially simple proximity trigger.

### Type 110 — Jade Cicada / Yumingchan
- Storyline: `common/region_game/com_yumingchan`
- Config: `ymc_ins_entity`, `tree_no`, `bb_tree_max`
- Flow: Server storyline with tree interaction.
- **Auto-collect**: Storyline-driven tree interaction.

## Phase 5: Common Entry Points for Automation

- Source: `Scripts/source_decompiled/hexm/common/consts/region_game_consts.lua:224-266`
  Excerpt: `region_game_need_create(game_id)` checks: not locked, correct level, not finished (or replay allowed).
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/consts/region_game_consts.lua:600-612`
  Excerpt: `get_game_id_by_sid(sid)` returns `relate_wanfa_no[2]` when `relate_wanfa_no[1] == 1`.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/gameplays/region_game/region_game_server_base.lua:121-131`
  Excerpt: `notify_server(event, data)` either dispatches locally (run_local) or calls `region_game_process_notify_server()`.
  Evidence Confidence: 5/5

# Conclusions (Score >=3 only)

1. There are **19 distinct qizhen/oddity types** across 782 world instances.

2. **Automation feasibility tiers:**

   **Tier 1 — Auto-collectable via proximity (walk near):**
   - Type 25 (Airborne Chest): distance detect → auto-complete on touch (2.5m)
   - Type 94 (Pottery Swine): collision box → auto-event on proximity
   - Type 77 (Azure Bird): distance check per bird, sequential approach

   **Tier 2 — Auto-collectable via interact trigger:**
   - Type 19 (Mantis): `trigger_active_interact(interact_no)` → chase → final interact
   - Type 46 (Bird's Nest): state-based interact progression via storyline
   - Type 55 (Golden Toad): storyline with single serial target
   - Type 110 (Jade Cicada): storyline with tree entity

   **Tier 3 — Requires physical gameplay (movement/chase):**
   - Type 53 (Chase Mouse): break objects + chase mice
   - Type 60 (Kaifeng Bird): chase flying bird at speed
   - Type 63 (Thunderous Fluff): chase seeds
   - Type 93 (Bamboo Ray): water chase
   - Type 70 (Catfish): requires taiji backtrack skill
   - Type 71 (Jade Rabbit): trapping gameplay

   **Tier 4 — Requires puzzle/combat:**
   - Type 27 (Crate Pile): destroy objects + interact
   - Type 29 (Soultaker Lotus): multi-step interact component progression + butterfly guide
   - Type 33 (Beehive): bee interaction with debuffs
   - Type 69 (Udumbara): timed flower identification puzzle
   - Type 79 (Nine-Colored Deer): visual/camera puzzle
   - Type 92 (Darksteel Armor): hole puzzle

3. The core auto-collect loop for ALL types would be:
   ```
   for each nearby entity with qizhen marker:
     sid → get_game_id_by_sid(sid) → game_id
     if region_game_need_create(game_id): it's available
     type = region_game_config[game_id].type
     dispatch to type-specific handler
   ```

4. The server completion path for all types goes through `region_game_process_notify_server(game_id, data)` — the common handler or storyline handles rewards.

5. For storyline-based types, the `RegionGameServer` base automatically starts the storyline on `on_server_game_loaded()` via `start_client_st()`. The storyline runs as a template and progress is notified to the server.

# Unknown / Missing Evidence

- Exact storyline scripts (`.ets` files and storyline template logic) are not in decompiled scope. The exact sequence of interact steps within storylines is opaque.
- `RegionGameHandlerTanglang` common handler source was not found in decompiled files — only referenced in `region_game_consts.lua`.
- Exact reward settlement path after `notify_server` completion is server-side and not fully traceable from client code alone.
- The 4 unmapped sids (786 - 782) could not be resolved to game_ids — possibly orphaned or cross-space references.

# Next Scoped Search Steps

1. For Tier 1/2 types, trace the exact `trigger_active_interact` flow to build automated interaction sequences.
2. Search for storyline template scripts to understand auto-progression for storyline-based types.
3. Investigate `region_game_process_notify_server` to map the exact server events that trigger completion for each type.
4. Check if any types support `simulate_get_reward` through the interact component handler chain.
