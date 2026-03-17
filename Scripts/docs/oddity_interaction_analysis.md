# Question / Scope

How oddities are interacted with, with emphasis on the hinted keys and the concrete `region_game_config[800009]` entry (`Mantis - Mercyheart Town Cave`).

# Evidence

- Source: `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.region_game_config.json:5349`
  Excerpt: `800009` has `type: 19`, `space: 501`, `online_award_type: 2017`, `flow_id: 800009`, `__rel_ins_serial_id_d: { "1632020009": 1 }`, and the position from the user snippet.
  Why it matters: This puts the oddity inside the region-game system, not just a generic collectable row.
  Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.region_game_type_config.json:241`
  Excerpt: type `19` maps to `client_handler: "region_game_server.RegionGameServerTanglang"` with serial records `serial_id`, `dialognpc_id`, `survey_id`.
  Why it matters: The Mantis oddity uses a dedicated region-game handler (`Tanglang`), which implies a puzzle/task flow before final completion.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/consts/region_game_consts.lua:30`
  Excerpt: `_M.REGION_GAME_CHEST_FLY = 19`.
  Why it matters: Confirms the internal type name for oddity type `19`.
  Evidence Confidence: 4/5

- Source: `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.region_game_custom_config.json:4885`
  Excerpt: `800009` has `reward_id: 217335`, `trace_distance: 70`, `serial_id: 1632020009`, `interact_no: 31005201`.
  Why it matters: This is the per-oddity config that binds the region-game entry to a specific world serial and the first interact action.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/gameplays/region_game/region_game_server.lua:244`
  Excerpt: `RegionGameServerTanglang:on_server_game_loaded()` sets `target_sid = self:get_custom_config("serial_id")`, and `on_interact_add_marker()` checks `data:get("interact_no") == self:get_custom_config("interact_no")` before calling `add_qizhen_chase_marker(self.target_sid, distance)`.
  Why it matters: For this oddity, the first interact does not directly collect the reward. It starts the Tanglang flow and adds a qizhen chase marker for the target serial.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/interact/imp_active_interact.lua:2721`
  Excerpt: active-interact result events include `interact_no = self:get_cur_active_interact_way_no()`, then dispatch `E_ACTIVE_INTERACT_RESULT`.
  Why it matters: Explains how the Tanglang handler learns that `31005201` fired and can react by adding the chase marker.
  Evidence Confidence: 4/5

- Source: `Scripts/source_decompiled/hexm/client/consts/map_marker_consts.lua:104`
  Excerpt: `QIZHEN_TRACE = 132`, `QIZHEN_CHASE_TRACE = 210`, `QIZHEN_SUBMIT = 135`.
  Why it matters: Oddities have a dedicated marker family, confirming they are a first-class subsystem (`qizhen`).
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/map_marker_plugins/map_plugin_config.lua:83`
  Excerpt: marker plugins map `QIZHEN_TRACE` to `QizhenTracePlugin` and `QIZHEN_CHASE_TRACE` to `QizhenChasePlugin`.
  Why it matters: The map/UI layer has explicit oddity tracing and chase-marker support.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/map_marker_plugins/map_plugins/qizhen_trace_plugin.lua:63`
  Excerpt: `load_ins_entity_marker()` reads `map_gameplay_data[self.sys_no].sids`, converts each `sid` to a `game_id` via `region_game_consts.get_game_id_by_sid`, and shows markers only when `region_game_need_create(...)` is true.
  Why it matters: Oddity traces are loaded from map gameplay data and are tied to region-game state, cooldown, and block logic.
  Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.spaces.s501.map_gameplay_data.json:498`
  Excerpt: entry `132` contains a `sids` list that includes `1632020009`.
  Why it matters: The Mantis serial is explicitly part of the `QIZHEN_TRACE` marker dataset for space `501`.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/consts/region_game_consts.lua:600`
  Excerpt: `get_game_id_by_sid()` returns `relate_wanfa_no[2]` when the serial's `relate_wanfa_no[1] == 1`.
  Why it matters: This is the code path that resolves serial `1632020009` back to game `800009`.
  Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.spaces.s501.entity.json:1007286`
  Excerpt: serial `1632020009` has `map_wanfa_no: [132]`, `relate_wanfa_no: [1, 800009]`, `listen_no: 26`, `listen_bone`, and `npc_no: 4900122`.
  Why it matters: The world instance is linked both to the qizhen marker system and to the `800009` region-game flow; it also carries listen-trace data.
  Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.entity.json:606699`
  Excerpt: entity `4900122` has `qizhen_trace_config: 1`, `interact_config: [310052]`, and `base_tag: 41001`.
  Why it matters: The oddity target is an interactable qizhen entity with a specific interact component chain.
  Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/DirObject_Cache/hexm.client.data_oversea.entity_tags.json:483`
  Excerpt: base tag `41001` is `TAG_NPC`.
  Why it matters: For this oddity, the target is not a `TAG_BASE_COLLECT` node. That makes `ride_skill_collect_nearby_collections()` a weak fit for the Mantis case.
  Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.interact_comp_index.json:3467`
  Excerpt: component `310052` has statuses `310052001..310052004`, defaulting to `310052001`.
  Why it matters: The oddity interaction is stateful and progresses through multiple component states.
  Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.interact_comp_status.json:37388`
  Excerpt: status `310052001` exposes active way `31005201`.
  Why it matters: This is the initial interact that the custom config points at.
  Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.active_interact_way.json:85120`
  Excerpt: active way `31005201` has `trigger_event: "E_AI_START_INTERACT"`, `finish_interact_hide: 1`, `max_interact_time: 1`.
  Why it matters: The first oddity interact is an AI/event trigger, not a direct collect reward handler.
  Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.interact_comp_status.json:32939`
  Excerpt: status `310052003` has `listen_disappear: 1`, `modelid: 2011`, and an effect.
  Why it matters: This strongly suggests the oddity flow includes a listening/clue phase that changes presentation before the final interact.
  Evidence Confidence: 4/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/common_members/listen_trace.lua:92`
  Excerpt: when `interact_comp_status[status_no].listen_disappear == 1`, the listener trace is stopped.
  Why it matters: Confirms that the `listen_disappear` flag on `310052003` actively changes oddity guidance behavior.
  Evidence Confidence: 4/5

- Source: `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.interact_comp_status.json:46772`
  Excerpt: status `310052004` exposes active way `31005202`.
  Why it matters: There is a later/final interact state after the initial `31005201`.
  Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.active_interact_way.json:24371`
  Excerpt: active way `31005202` has `trigger_event: "E_AI_WANFA"`, `finish_interact_hide: 1`, `result_play_sound_no`, and `max_interact_time: 1`.
  Why it matters: The later interact is still a scripted gameplay event, reinforcing that this oddity is region-game driven instead of plain collection-handler pickup.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/misc/interact_misc.lua:117`
  Excerpt: `get_all_possible_active_ways(entity_no)` collects direct active ways plus those from interact component statuses, relations, and special couplings.
  Why it matters: This is the generic path that surfaces oddity interactions once the entity's component state changes.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/ui/windows/interact/interact_handler/normal_interact_handler.lua:38`
  Excerpt: the button handler calls `G.main_player:trigger_active_interact(...)`.
  Why it matters: Oddity button presses ultimately go through the normal active-interact pipeline unless a special handler overrides it.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/interact/imp_active_interact.lua:1106`
  Excerpt: `trigger_active_interact()` performs lock/distance/usable checks, locks the target, and starts the active-interact process.
  Why it matters: This is the runtime gate for manual oddity interaction.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/base/active_interact_handlers/server_active_interact_base.lua:406`
  Excerpt: `_active_interact_do_result()` calls `interact_result_trigger_interact_comp_status_change(...)` and relation-change handling.
  Why it matters: Active-interact results are what advance interact-component state, which is how multi-step oddities can unlock later ways.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/imp_ride_skill.lua:152`
  Excerpt: `ride_skill_collect_nearby_collections()` scans nearby entities with `TAG_BASE_COLLECT` and calls `interact_comp_handler_simulate_get_reward(SIMULATE_INTERACT_TYPE_RIDE_SKILL)`.
  Why it matters: This shortcut only applies to collect-tag entities.
  Evidence Confidence: 5/5

- Source: `Scripts/data/DirObject/DirObject_Cache/hexm.client.data_oversea.active_interact_way.json:2360`
  Excerpt: active way `70001` uses `program_handler: "collection_handler.CollectionHandler"`.
  Why it matters: There is a separate generic collection-handler path in the game, so some oddities or collectibles can be plain collect nodes.
  Evidence Confidence: 4/5

- Source: `Scripts/data/DirObject/DirObject_Cache/hexm.client.data_oversea.active_interact_way.json:78981`
  Excerpt: active way `60000100` uses `CollectionHandler`, has `award_id`, `max_interact_time: 1`, and `del_entity: 1`.
  Why it matters: This is the direct reward-and-delete collection pattern that ride-skill simulation is built for.
  Evidence Confidence: 4/5

- Source: `Scripts/source_decompiled/hexm/client/ui/windows/interact/interact_handler/collection_handler.lua:8`
  Excerpt: `CollectionHandler` subclasses `NormalInteractHandler`.
  Why it matters: Even generic collection nodes still resolve through the same active-interact framework; they are just a different handler branch from the `Tanglang` oddity.
  Evidence Confidence: 4/5

- Source: `Scripts/source_decompiled/hexm/common/tag.lua:527`
  Excerpt: `is_collect()` is true only when the entity has `TAG_BASE_COLLECT`.
  Why it matters: Reinforces why the ride-skill collect path does not match the Mantis oddity entity (`TAG_NPC`).
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/imp_ride_skill.lua:463`
  Excerpt: `ride_skill_get_kill_reward(entity_id_list)` only calls `interact_misc.horse_try_auto_pickup(entity_id_list)`.
  Why it matters: This path is for kill-reward entities, not for the `800009` region-game oddity.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/misc/interact_misc.lua:1949`
  Excerpt: `horse_try_auto_pickup()` only sends `rpc_npc_stuff_kill_reward` for entities where `local_entity:if_kill_reward()` is true.
  Why it matters: Confirms the kill-reward shortcut is unrelated to the Mantis oddity flow.
  Evidence Confidence: 5/5

# Conclusions (Score >=3 only)

1. `800009` (`Mantis - Mercyheart Town Cave`) is an oddity/qizhen region-game entry, not just a plain collection node.

2. This oddity's interaction path is:
   `region_game_config[800009]` -> type `19` (`Tanglang`) -> `region_game_custom_config[800009]` -> world serial `1632020009` -> entity `4900122` -> interact component `310052` -> initial active way `31005201` -> chase/listen/state progression -> later active way `31005202`.

3. The first interact for this oddity is a scripted AI/gameplay trigger (`E_AI_START_INTERACT`), and a later interact is another scripted gameplay trigger (`E_AI_WANFA`); neither of the exposed `3100520x` ways is a generic `CollectionHandler` reward button.

4. The marker side of oddities is explicitly implemented as `qizhen`:
   `QIZHEN_TRACE` markers load from `map_gameplay_data[132]`, `get_game_id_by_sid()` resolves the serial back to game `800009`, and `RegionGameServerTanglang` adds a `QIZHEN_CHASE_TRACE` marker after the first interact fires.

5. The user-suggested keys split into two buckets:
   `trigger_active_interact`, `get_interact_comp`, `get_all_possible_active_ways`, and interact-component status handling are directly relevant.
   `ride_skill_collect_nearby_collections` and `ride_skill_get_kill_reward` are not a good match for the Mantis oddity, because its entity is `TAG_NPC`, not `TAG_BASE_COLLECT`, and it is not a kill-reward node.

# Unknown / Missing Evidence

- No authoritative decompiled file for the server/game handler behind type `19` (`Tanglang`) was present in current scope, so the exact internal step that moves `310052001 -> ... -> 310052004` was not directly verified.
- No direct `interact_comp_status_transition` row for `310052` was found in current scope. The state changes appear to be driven by region-game/server logic rather than a generic transition table.
- The final reward payout path for `reward_id: 217335` was not directly traced in decompiled code in this pass, though the reward is clearly attached to `region_game_custom_config[800009]`.

# Next Scoped Search Steps

1. Search for additional decompiled assets or generated storyline files for Tanglang/type `19` server logic.
2. Trace `reward_id 217335` through reward/settlement handlers to confirm the exact completion RPC/result path.
3. Inspect other qizhen entries that do use `CollectionHandler` to separate "pure collect" oddities from region-game oddities.
