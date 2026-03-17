# Autoloot Failure Analysis: Entity `ins_entity1234530290_interact_comp` (No.4500117, comp_no 430038)

## Question / Scope

Why does autoloot fail for entities with multi-status interact chains (specifically status 43003801 → 43003802)?
The entity appears to stop responding to RPCs after the first interaction, remains visible but non-targetable.

---

## Evidence

### E1 — Entity Identification

- **Source**: Trace `interact_comp_handler_base_anon_233548_006.json`
- **Excerpt**: `self=<instof InteractComEntity at 2087617423952>(sid.1234530290)(No.4500117)`
- **Why it matters**: Confirms entity `ins_entity1234530290_interact_comp` is No.4500117, sid.1234530290 in the trace session.
- **Confidence**: 5/5

---

### E2 — Status 43003801: Interactive State

- **Source**: `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.interact_comp_status.json`
- **Excerpt**: `{"default_id": 1, "active_ways": [43003801], "trace_icon": "map_icon_96_box_lock", "status_id": 43003801, "trace_distance": 15}`
- **Why it matters**: Status 43003801 has `active_ways=[43003801]` — the interact button is visible. This is the initial interactable state.
- **Confidence**: 5/5

---

### E3 — Status 43003802: Terminal / Destroy State

- **Source**: `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.interact_comp_status.json`
- **Excerpt**: `{"status_id": 43003802, "destroy_status": 1, "out_aoi_destroy": 1}`
- **Why it matters**:
  - `destroy_status: 1` = entity is "spent" / terminal state.
  - `out_aoi_destroy: 1` = entity only despawns when player leaves AOI — it remains VISIBLE until then.
  - **NO `active_ways` field** — no interact button shown. Entity cannot be re-targeted.
- **Confidence**: 5/5

---

### E4 — Status Transition: 43003801 → 43003802 (One-Way)

- **Source**: `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.interact_comp_status_transition.json`
- **Excerpt**:
  ```json
  {"conditions": [{"change_id": 43003801, "change_way": [43003801], "status_id": 43003801, "change_status_id": 43003802}]}
  ```
- **Why it matters**: Only one transition exists: 43003801 → 43003802 when `active_way_no=43003801`. **No transition exists for status 43003802** — after the entity reaches 43003802, it is permanently stuck there until AOI cleanup.
- **Confidence**: 5/5

---

### E5 — Autoloot Scan 1 Succeeded (Status Transition Confirmed)

- **Source**: `Scripts/logs/script_debug.txt` (Scan 1 → Scan 2)
- **Excerpt**:
  - Scan 1 (t=3676.131): status=43003801, sends RPC `rpc_request_active_interact_result_and_end` with `way_no=43003801, comp_id=430038, _direct=true`.
  - Scan 2 (t=3677.130): entity now at `status_no=43003802`, `sync_ex: {transit_status_to_43003802: aWHEttFIAUazfw08}`.
- **Why it matters**: The status transition 43003801 → 43003802 was triggered by autoloot's first RPC. The fake-server code processed it correctly: `interact_result_trigger_interact_comp_status_change` called `get_status_change_no(43003801, CHANGE_WAY_ACTIVE_INTERACT, 43003801)` = 43003802 ✓.
- **Confidence**: 5/5

---

### E6 — Autoloot Scan 2 Is Invalid (No active_ways, No Transition)

- **Source**: `Scripts/logs/script_debug.txt` + E3 + E4
- **Excerpt**: Scan 2 sends RPC with `way_no=43003802, comp_id=430038` — but status 43003802 has no `active_ways` and no status transition defined.
- **Why it matters**:
  - `get_status_change_no(43003802, CHANGE_WAY_ACTIVE_INTERACT, 43003802)` returns `nil` (E4).
  - `interact_result_trigger_interact_comp_status_change` does nothing.
  - Entity stays at 43003802 indefinitely (until AOI leave).
  - `HandlerNormal:handle_result` still calls `rpc_client_collect_handler_normal` for 43003802 → **possible duplicate loot dispatch or server-side rejection**.
- **Confidence**: 5/5

---

### E7 — `active_interact_call_server` Routes Correctly for Server Entities

- **Source**: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/interact/imp_active_interact.lua:256`
- **Excerpt**:
  ```lua
  function PlayerAvatarActiveInteract:active_interact_call_server(rpc_method, comp_eid, active_way_no, kwargs)
      if self.space:check_is_client_interact_comp(comp_eid) then
          self.space:push_rpc(...)   -- fake server (client entity)
      else
          G.net:call_server(...)     -- real server (server entity)
      end
  end
  ```
- **Why it matters**: For `is_client_comp=false` (server) entities, the real game uses `G.net:call_server`. Autoloot uses `G.net:get_avatar():rpc_request_active_interact_result_and_end(...)` which routes through the **fake server** — but the fake server still calls `G.net:call_server("rpc_client_collect_handler_normal", ...)` via `HandlerNormal._forward_result_to_server` (handler_normal.lua:206). So the loot dispatch does reach the real server.
- **Confidence**: 4/5

---

### E8 — `_direct=true` Bypasses START Step Only

- **Source**: `Scripts/source_decompiled/hexm/common/base/active_interact_handlers/server_active_interact_base.lua:228`
- **Excerpt**: With `_direct=true`, the step check for `ACTIVE_INTERACT_STEP_START` is skipped. The handler still processes `check_result`, `_active_interact_do_result`, and the END RPC.
- **Why it matters**: The `_direct=true` flag is sufficient to bypass the START handshake for these entity types. Autoloot's approach is valid for skipping the START step.
- **Confidence**: 4/5

---

### E9 — Entity Remains Visible After Interaction (Expected)

- **Source**: E3 (`out_aoi_destroy: 1`)
- **Why it matters**: The entity staying visible after a successful 43003801 interaction is **expected game behavior** — it only despawns when the player leaves the AOI zone. Autoloot incorrectly treats this as "entity still needs interaction" and retries.
- **Confidence**: 5/5

---

### E10 — Autoloot Uses `cur_status_no` as `way_no`

- **Source**: `Scripts/logs/script_debug.txt` + `Scripts/actions/autoloot.lua`
- **Excerpt**: Scan 2 sends `active_way_no=43003802` = the entity's current status_no after transition.
- **Why it matters**: Autoloot re-scans entities already at `destroy_status=43003802` and attempts a second RPC using the current status as `way_no`. This is wrong — status 43003802 has no `active_ways` and no valid interaction.
- **Confidence**: 5/5

---

## Root Cause Summary

The interaction chain for entity comp_no 430038 is **one-shot**:

```
Player Action         Entity Status     Active Ways       Result
─────────────────────────────────────────────────────────────────
Initial state      →  43003801          [43003801]        Interact button shown
Click (way 43003801)→  43003801          [43003801]        Send RPC result_and_end(43003801)
Server processes   →  43003802          none (terminal)   Status transition done, loot sent
Entity stays AOI   →  43003802          none              Visible but non-interactive (destroy_status=1)
Player leaves AOI  →  (despawned)        —                 Out-of-AOI cleanup
```

**What autoloot does wrong**:
1. **Scan 1** (way_no=43003801): **CORRECT** — triggers the transition and loot distribution.
2. **Scan 2** (way_no=43003802): **WRONG** — entity is already at terminal state, no transition defined, no active_ways. The second RPC does nothing useful (and risks duplicate loot dispatch).
3. **Re-scan loop**: Autoloot keeps seeing the entity (it hasn't despawned) and keeps attempting interaction because it doesn't check `destroy_status`.

---

## Fix Required

In `Scripts/actions/autoloot.lua`, add a check to **skip entities whose current status has `destroy_status=1`** (or equivalently, has no `active_ways`):

```lua
-- In the entity scan loop, before sending RPC:
local status_data = G.datam.interact_comp_status:get(cur_status_no, {})
if status_data:get("destroy_status") == 1 then
    -- Entity already spent, skip
    return
end
local active_ways = status_data:get("active_ways")
if not active_ways or #active_ways == 0 then
    -- No interactive ways in current status, skip
    return
end
```

Additionally, the cache key should include `cur_status_no` (not just entity/serial/comp IDs) so that entities that successfully transitioned are not re-attempted on subsequent scans during the same session.

---

## Unknown / Requires Further Investigation

- **Did `rpc_client_collect_handler_normal` actually distribute loot for 43003801?** We cannot confirm from client-side traces alone since the real server response is not captured. The status transition succeeding suggests the RPC was processed, but loot distribution is server-authoritative.
- **Does `way_info.param` (key selection from kaisuo UI) affect server-side loot validation?** The fake-server handler (`HandlerNormal.check_result`) ignores `param`, but the real server's `rpc_client_collect_handler_normal` handler might require a valid key param. Without server-side code, this cannot be confirmed.
- **Scan 2's duplicate `rpc_client_collect_handler_normal` for 43003802** — whether the real server accepts or rejects this is unknown.

---

## Next Scoped Search Steps (if needed)

1. Search `rpc_client_collect_handler_normal` handler in server-side Lua (if available) to check param validation.
2. Search `interact_comp_status:get("destroy_status")` usage in `autoloot.lua` to see if any check already exists.
3. Verify cache key logic in autoloot to confirm `cur_status_no` is not already part of the key.
