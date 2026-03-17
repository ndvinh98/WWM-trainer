# AutoLoot Interaction Error 3 Analysis

## Question / Scope

Why does `autoloot.lua` fail with `err=3` on `start_back` for entity `abZiz+pDE3q/czVY` (way=42004401, no=4500190)?
What is the correct interaction method for `server_process=3` (CLIENT_FIRST) entities?

## Evidence

### Evidence 1: server_process Constants

- **Source**: `hexm/common/consts/interact_component_consts.lua:147-179`
- **Excerpt**:
  ```lua
  _M.PROGRESS_NORMAL = 0
  _M.PROGRESS_LOCAL = 1
  _M.PROGRESS_CALL_RESULT = 2
  _M.PROGRESS_CLIENT_FIRST = 3

  function _M.process_need_call_start(process_type)
      return process_type == _M.PROGRESS_NORMAL
  end

  function _M.process_need_call_result(process_type)
      return process_type == _M.PROGRESS_NORMAL
          or process_type == _M.PROGRESS_CALL_RESULT
          or process_type == _M.PROGRESS_CLIENT_FIRST
  end

  function _M.process_need_wait_result_back(process_type)
      return process_type ~= _M.PROGRESS_CLIENT_FIRST
  end

  function _M.process_need_call_end(process_type)
      return process_type == _M.PROGRESS_NORMAL
  end
  ```
- **Why it matters**: For `server_process=3` (CLIENT_FIRST): START must NOT be called, RESULT must be called, don't wait for result_back, END must NOT be called.
- **Evidence Confidence**: 5/5

### Evidence 2: Server Rejects START for Non-NORMAL server_process

- **Source**: `hexm/common/base/active_interact_handlers/server_active_interact_base.lua:113-129`
- **Excerpt**:
  ```lua
  local server_process = G.datam.active_interact_way
      :get(active_way_no, {})
      :get("server_process", interact_component_consts.PROGRESS_NORMAL)
  if not interact_component_consts.process_need_call_start(server_process) then
      self.logger:error("[%s] - Interact: [rpc_request_active_interact_start] server_process err. %s %s", ...)
      return self:active_interact_call_client("rpc_request_active_interact_start_back", errcode.ERR_INVALID_PARA, ldata, {})
  end
  ```
- **Why it matters**: The server explicitly returns `ERR_INVALID_PARA` (err=3) when START is called for a way with `server_process != 0`. This is exactly the error seen in the log.
- **Evidence Confidence**: 5/5

### Evidence 3: ERR_INVALID_PARA = 3

- **Source**: `hexm/common/errcode.lua:15`
- **Excerpt**: `_M.ERR_INVALID_PARA = 3`
- **Why it matters**: Confirms err=3 in the start_back is ERR_INVALID_PARA, matching the server_process rejection path.
- **Evidence Confidence**: 5/5

### Evidence 4: Way Data Shows server_process=3

- **Source**: Script debug log (`Scripts/logs/script_debug.txt`)
- **Excerpt**:
  ```
  way_data={..., server_process=3, enable_position_raycast=1, enable_battle_state=1, position_raycast_config_no=10, ...}
  ```
- **Why it matters**: Confirms way 42004401 is a CLIENT_FIRST interaction with battle state and position raycast requirements (archery/bow-hit interaction).
- **Evidence Confidence**: 5/5

### Evidence 5: Client Storyline Skips START for Non-NORMAL

- **Source**: `Sunshine/Storyline/StorylineNode/ClientNode/InteractProcessNodes.lua:317-341`
- **Excerpt**:
  ```lua
  if interact_component_consts.process_need_call_start(owner:active_interact_process_type()) then
      -- ... calls rpc_request_active_interact_start, waits for start_back ...
  else
      owner:set_storyline_blackboard_value("interact_process_server_start_back_data", {})
      return { __out__ = "success" }
  end
  ```
- **Why it matters**: The game's own client code skips the START RPC entirely for non-NORMAL server_process types and immediately proceeds to the next phase.
- **Evidence Confidence**: 5/5

### Evidence 6: Server RESULT Handler Accepts CLIENT_FIRST

- **Source**: `hexm/common/base/active_interact_handlers/server_active_interact_base.lua:228-260`
- **Excerpt**:
  ```lua
  -- In rpc_request_active_interact_result:
  if not interact_component_consts.process_need_call_result(server_process) then
      return errcode.ERR_INVALID_PARA  -- Only rejects PROGRESS_LOCAL (1)
  end
  -- For CLIENT_FIRST: process_need_call_start(3) is false,
  -- so the "now_step != START" check is skipped entirely
  ```
- **Why it matters**: The server accepts RESULT calls for CLIENT_FIRST without requiring a prior START. The `_direct` flag check is also bypassed because `process_need_call_start(3)` is false.
- **Evidence Confidence**: 5/5

### Evidence 7: ride_skill_collect_nearby_collections Misses This Entity

- **Source**: `hexm/client/entities/local/player_avatar_members/imp_ride_skill.lua:154-163`
- **Excerpt**:
  ```lua
  function PlayerAvatarMember:ride_skill_collect_nearby_collections(distance)
      local entities = G.space:get_entities_in_range(self:get_position(), distance, tag_consts.new_tags.TAG_BASE_COLLECT)
  ```
- **Why it matters**: Filters by `TAG_BASE_COLLECT`. The entity has `TAG_RARE_COLLECT` + `TAG_COLLECT_STROKE` but NOT `TAG_BASE_COLLECT`, so it's excluded from the ride-skill collect path.
- **Evidence Confidence**: 5/5

### Evidence 8: rpc_simulate_request_active_interact_result Alternative

- **Source**: `hexm/common/base/active_interact_handlers/server_active_interact_base.lua:586-622`
- **Excerpt**:
  ```lua
  function ServerActiveInteractBase:rpc_simulate_request_active_interact_result(simulate_type, comp_eid, active_way_no, kwargs)
      kwargs._direct = true
      -- For RIDE_SKILL, TELEKINESIS, WUSHI, ENTER_SCOPE: need_direct_result = true
      if need_direct_result then
          self:rpc_request_active_interact_result(comp_eid, active_way_no, kwargs)
      end
  end
  ```
- **Why it matters**: `rpc_simulate_request_active_interact_result` with simulate_type=2 (RIDE_SKILL) sets `_direct=true` and calls `rpc_request_active_interact_result` directly. This is an alternative RPC path that bypasses START entirely.
- **Evidence Confidence**: 4/5

## Conclusions

### 1. Root Cause (Confidence: 5/5)

The autoloot script unconditionally calls `rpc_request_active_interact_start` for all entities. For way 42004401, `server_process=3` (PROGRESS_CLIENT_FIRST), the server explicitly rejects the START call and returns `ERR_INVALID_PARA` (err=3). The START RPC is only valid for `server_process=0` (PROGRESS_NORMAL).

### 2. Correct Interaction Flow per server_process Type (Confidence: 5/5)

| server_process | Constant | START | RESULT | Wait Result Back | END |
|---|---|---|---|---|---|
| 0 | PROGRESS_NORMAL | Yes | Yes | Yes | Yes |
| 1 | PROGRESS_LOCAL | No | No | N/A | No |
| 2 | PROGRESS_CALL_RESULT | No | Yes | Yes | No |
| 3 | PROGRESS_CLIENT_FIRST | No | Yes | No | No |

For CLIENT_FIRST (server_process=3):
- **Skip** `rpc_request_active_interact_start` entirely
- **Call** `rpc_request_active_interact_result` directly with `client_result=true`, `need_result_back=false`
- **Skip** `rpc_request_active_interact_end`

### 3. Two Viable Fix Approaches (Confidence: 4/5)

**Approach A — Direct RESULT call**: Read `server_process` from `G.datam.active_interact_way:get(way_no):get("server_process")`. If != 0, skip START and call `rpc_request_active_interact_result` directly with:
```lua
{
    way_info = { way_no = way_no, comp_id = comp_id },
    client_No = entity_no,
    target_eid = entity_id,
    client_serial_id = serial_id,
    comp_position = pos,
    client_result = true,
    need_result_back = false, -- for CLIENT_FIRST
}
```

**Approach B — Simulate RPC**: Call `rpc_simulate_request_active_interact_result` with `simulate_type=2` (RIDE_SKILL):
```lua
G.net:call_server("rpc_simulate_request_active_interact_result", 2, entity_id, way_no, {
    client_No = entity_no,
    target_eid = entity_id,
    way_info = { way_no = way_no, comp_id = comp_id },
    client_result = true,
    client_comp_pos = { px, py, pz },
})
```

## Unknown / Missing Evidence

- The exact server-side validation inside `check_result()` for way 42004401 is not visible — the handler implementation is not in decompiled source. It may require additional conditions like battle state or positional data.
- Whether PROGRESS_LOCAL (1) entities can be handled at all from client-side scripting.
- Whether the simulate path has additional anti-cheat checks compared to the direct RESULT path.

## Next Scoped Search Steps

1. Search for the specific handler registered for way_group_id=420044 to understand any custom `check_result` logic.
2. Check if `enable_battle_state=1` requires the player to actually be in combat state for the server to accept the RESULT.
3. Investigate `position_raycast_config_no=10` to understand if the server validates raycast data.
