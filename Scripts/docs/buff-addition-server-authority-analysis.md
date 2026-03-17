# Buff Addition and Server Authority Analysis

## 1. Question / Scope

Analyze the buff addition flow around:

- `G.main_player:add_buff(...)`
- `BuffBase:add_buff(...)`
- `self.fake_server:call_real_syn("add_buff", ...)`

Focus on:

- how buff add requests move between local entity, fake server, and server RPC
- which cases are handled locally vs server-authoritatively
- why some buffs cannot be added purely client-side

This report does **not** include bypass instructions.

---

## 2. Evidence

### 2.1 Local entity `add_buff` delegates to fake server when present

**Source:** `Scripts/source_decompiled/hexm/client/entities/local/common_members/buff_base.lua`

**Excerpt:**
```lua
function BuffBase:add_buff(buff_no, fromid, kwargs)
    if self.fake_server then
        self.fake_server:call_real_syn("add_buff", buff_no, fromid, kwargs)
    else
        ...
        G.net:call_server_with_token("buff", "rpc_clientify_call_buff", "add_buff", self.id, {
            buff_no,
            fromid,
            data,
        })
    end
end
```

**Why it matters:**
The local entity does not directly instantiate the visible buff object here. It either forwards into the fake server path or sends an authenticated RPC toward the server path.

**Evidence Confidence:** 5/5

---

### 2.2 Fake server synchronous call is only a local method dispatch

**Source:** `Scripts/source_decompiled/hexm/client/fake_server/entities/base_entity.lua`

**Excerpt:**
```lua
function FakeBaseEntity:call_real_syn(method, ...)
    if self:is_deactived() then
        return
    end
    ...
    self[method](self, ...)
end
```

**Why it matters:**
`call_real_syn` is not a server bypass primitive. It is only a synchronous local dispatch onto the fake-server entity method.

**Evidence Confidence:** 5/5

---

### 2.3 Fake server buff add still sends a tokenized server RPC

**Source:** `Scripts/source_decompiled/hexm/client/fake_server/entities/common_members/buff_base.lua`

**Excerpt:**
```lua
function BuffWithServer:add_buff(buff_no, fromid, kwargs)
    ...
    if buff_consts.is_client_buff(sys_d) then
        local err, sys_d = self.buff:_check_can_add(buff_no, fromid, kwargs)
        if err ~= buff_consts.ERR_OK then
            return nil
        end
        kwargs._nocheck = 1
        res = MockBuffHandler(buff_no, sys_d, fromid, kwargs)
        self.buff:control_try_enter(res.ID, sys_d, res.data, false, kwargs:get("reason"), kwargs)
    end
    if not G.SERVER_CALC_DMG or kwargs:get("reason") ~= "behit" or not self.tag:is_boss() then
        G.net:call_server_with_token("buff", "rpc_clientify_call_buff", "add_buff", self.id, {
            buff_no,
            fromid,
            kwargs,
        })
    end
    return res
end
```

**Why it matters:**
Even when fake-server logic exists, buff addition remains tied to `rpc_clientify_call_buff` for authoritative handling. The fake-server path may create temporary/local handling for eligible client buffs, but it still calls the server RPC.

**Evidence Confidence:** 5/5

---

### 2.4 Only certain buff configs qualify as client-local buff handling

**Source:** `Scripts/source_decompiled/hexm/common/consts/buff_consts.lua`

**Excerpt:**
```lua
_M.TH_FAKE_MODE_LOCAL = { ["buff_control_type"] = 0 }

function _M.is_client_buff(sys_d)
    for k, default in pairs(_M.TH_FAKE_MODE_LOCAL) do
        if sys_d:get(k, default) ~= default then
            return true
        end
    end
    return false
end
```

**Why it matters:**
The client/fake-server local path is gated by buff config. A buff is considered a "client buff" only when configured values differ from this local fake-mode baseline. This means local handling is selective, not universal.

**Evidence Confidence:** 5/5

---

### 2.5 Extra fake logic only exists for specific buff features

**Source:** `Scripts/source_decompiled/hexm/client/fake_server/entities/common_members/buff_base.lua`

**Excerpt:**
```lua
local function buff_need_fake_logic(sys_d)
    if sys_d:get("has_fake_need") then
        return true
    end
    local conf_res = sys_d:get("buff_add_resource")
    if conf_res and attr_consts.is_local_res(conf_res[2]) then
        return true
    end
    if BuffAddShieldCharged.should_enable(sys_d) then
        return true
    end
    return false
end
```

**Why it matters:**
Fake/local post-processing is limited to explicitly marked cases such as `has_fake_need`, local resource interactions, or shield-related behavior. This is strong evidence that not all buffs are meant to be simulated fully on the client.

**Evidence Confidence:** 4/5

---

### 2.6 Server call uses per-tag HOTP-style token generation

**Source:** `Scripts/source_decompiled/hexm/client/net/network.lua`

**Excerpt:**
```lua
self._hotps = {
    ["buff"] = hotp.Hotp(),
    ["boss_fight"] = hotp.Hotp(),
}
```

**Source:** `Scripts/source_decompiled/hexm/client/net/network_comp/net_call_rpc.lua`

**Excerpt:**
```lua
function NetCallRpc:call_server_with_token(tag, rpc_method, ...)
    local hh = self._hotps:get(tag)
    ...
    local token = hh:gen(G.dtm:now_int())
    avatar.server[rpc_method](avatar.server, token, ...)
    return true
end
```

**Why it matters:**
Buff RPCs are not sent raw. They are wrapped in a tokenized call path keyed by the `buff` channel. This supports the conclusion that the server path is intended to validate or at least gate buff operations via authenticated RPC flow.

**Evidence Confidence:** 5/5

---

### 2.7 Fake server is only created in single-mode contexts

**Source:** `Scripts/source_decompiled/hexm/client/entities/local/common_members/fake_server.lua`

**Excerpt:**
```lua
function FakeServer:check_create_fake_server()
    return G.space:is_in_single_mode()
end
```

```lua
function FakeServer:_create_fake_server_if_needed(bdata)
    if self:check_create_fake_server(bdata) then
        self:_create_fake_server(bdata)
    end
end
```

**Why it matters:**
The fake-server system is conditional. It is created only in single-mode contexts, which indicates the fake-server path is a controlled simulation layer, not a universal replacement for authoritative server behavior.

**Evidence Confidence:** 5/5

---

### 2.8 Buff add validation exists before actual insertion

**Source:** `Scripts/source_decompiled/hexm/common/combat/buff/buff_comp.lua`

**Excerpt:**
```lua
function BuffComp:_check_can_add(buff_no, fromid, kwargs)
    if not self._is_ready then
        return buff_consts.ERR_ADD_NOT_READY, nil
    end
    local sys_d = self:get_sys_d(buff_no, kwargs:get("level"))
    if not sys_d then
        return buff_consts.ERR_ADD_SYS_D, nil
    end
    ...
    if not ignore_dead and self.owner:is_dead() and 0 == sys_d:get("dead_addbuff", 0) then
        return buff_consts.ERR_ADD_DEAD, nil
    end
    ...
    local err = self:check_immune(buff_no, sys_d, fromid)
    if 0 ~= err then
        return err, nil
    end
    ...
    local err = self:check_enter_control(sys_d)
    if 0 ~= err then
        self:_control_immune_tip(fromid)
        return err, nil
    end
    return buff_consts.ERR_OK, sys_d
end
```

**Why it matters:**
Buff adds are gated by readiness, config existence, death-state rules, immunity, control-state entry checks, and duration validation before insertion proceeds.

**Evidence Confidence:** 5/5

---

### 2.9 Actual add path still performs validation unless `_nocheck` is already set by controlled code

**Source:** `Scripts/source_decompiled/hexm/common/combat/buff/buff_comp.lua`

**Excerpt:**
```lua
function BuffComp:_add_buff(buff_no, fromid, kwargs)
    ...
    if not kwargs:pop("_nocheck") then
        local err
        err, sys_d = self:_check_can_add(buff_no, fromid, kwargs)
        if err ~= buff_consts.ERR_OK then
            self._last_err = err
            return
        end
        duration = kwargs.duration
    else
        sys_d = self:get_sys_d(buff_no, level)
        duration = kwargs:get("duration") or sys_d:get("buff_maxtime") or 20
        kwargs.duration = duration
    end
    ...
end
```

**Why it matters:**
Skipping validation requires `_nocheck`, but the observed code only sets `_nocheck` inside the controlled fake-server client-buff path after `_check_can_add` has already succeeded. This is not evidence of a general unrestricted add path.

**Evidence Confidence:** 5/5

---

### 2.10 Gameplay systems call `call_real_syn("add_buff", ...)` as part of internal action execution

**Source:** `Scripts/source_decompiled/hexm/common/actionline/nodes/logic_nodes.lua`

**Excerpt:**
```lua
target:call_real_syn("add_buff", self.buff_id, entity.id, d)
```

**Source:** `Scripts/source_decompiled/hexm/common/actionline/nodes/special_nodes.lua`

**Excerpt:**
```lua
real_tg:call_real_syn("add_buff", xuewei_buff, entity.id, { ["reason"] = "dianxue" })
```

**Why it matters:**
Internal gameplay systems use the same method path during actionline execution. This indicates the call chain is part of normal scripted gameplay resolution, not a hidden unrestricted debug path.

**Evidence Confidence:** 4/5

---

## 3. Conclusions

1. `BuffBase:add_buff` is a routing layer, not the final authority. It either forwards to `self.fake_server:call_real_syn(...)` or sends `rpc_clientify_call_buff("add_buff", ...)` through the network layer.
**Confidence:** 5/5

2. `call_real_syn` does not itself bypass the server. It only invokes a local method on the fake-server entity.
**Confidence:** 5/5

3. Even inside the fake-server buff flow, the authoritative path still includes `G.net:call_server_with_token("buff", "rpc_clientify_call_buff", ...)`.
**Confidence:** 5/5

4. Local/fake handling exists only for specific buff categories determined by buff config and helper predicates such as `is_client_buff(...)` and `buff_need_fake_logic(...)`.
**Confidence:** 5/5

5. Some buffs remain effectively server-handled because the client-side fake path is selective and because the standard add flow is wrapped in a tokenized RPC channel plus buff validation checks.
**Confidence:** 5/5

6. The observed architecture supports the idea that some buff effects may appear locally for responsiveness or local-resource behavior, while authoritative buff existence and synchronization remain server-controlled.
**Confidence:** 4/5

---

## 4. Unknown / Missing Evidence

1. The server-side implementation of `rpc_clientify_call_buff` was not located in the current investigation scope, so server validation details are not confirmed here.
2. The exact acceptance rules on the server for buff RPC tokens were not traced beyond client-side HOTP generation.
3. No direct evidence was collected for a legitimate debug/admin pathway that universally forces arbitrary buff insertion.

---

## 5. Next Scoped Search Steps

1. Search server-side authoritative code for `rpc_clientify_call_buff` implementation and token validation.
2. Correlate specific buff IDs that fail to add with `Scripts/data/DirObject/` buff config fields such as:
   - `buff_control_type`
   - `has_fake_need`
   - `buff_add_resource`
   - `buff_shield_calc_id`
   - `buff_shield_calc_hp`
3. Trace `check_immune(...)`, `check_enter_control(...)`, and `buff_active_space(...)` to explain exact rejection reasons for specific buff numbers.
4. If a concrete buff ID is known, investigate that buff’s config-to-code path directly instead of reasoning from the generic add flow.
