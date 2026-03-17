# Question / Scope

Consolidated buff-system analysis covering:

- buff application and server authority
- client-local / fake-server buff handling
- `has_fake_need` and `has_anti_need`
- current limits of `_buff_anti_records` / `_buff_anti_on_check` tracing
- effect/behavior decoding from buff data
- duration and stacking behavior
- supplemental current-status summary from `Scripts/data/buffs_dump.csv`

This report consolidates the prior buff-focused notes in `Scripts/docs/`, especially:

- `buff-addition-server-authority-analysis.md`
- `player-buff-application-paths-analysis.md`
- `buff-effect-behavior-analysis.md`
- `buff-anti-fake-need-analysis.md`
- `buff-system-analysis-21001002.md`

# Evidence

## Evidence 1
- Source: `Scripts/source_decompiled/hexm/client/entities/local/common_members/buff_base.lua`
- Excerpt:
  - `function BuffBase:add_buff(buff_no, fromid, kwargs)`
  - `if self.fake_server then`
  - `self.fake_server:call_real_syn("add_buff", buff_no, fromid, kwargs)`
  - `else`
  - `G.net:call_server_with_token("buff", "rpc_clientify_call_buff", "add_buff", self.id, { ... })`
- Why it matters:
  - Normal player buff addition is not a pure local create path. It routes into fake-server handling when available or sends a tokenized server buff RPC.
- Evidence Confidence: 5/5

## Evidence 2
- Source: `Scripts/source_decompiled/hexm/client/fake_server/entities/common_members/buff_base.lua`
- Excerpt:
  - `function BuffWithServer:add_buff(buff_no, fromid, kwargs)`
  - `if buff_consts.is_client_buff(sys_d) then`
  - `local err, sys_d = self.buff:_check_can_add(buff_no, fromid, kwargs)`
  - `res = MockBuffHandler(buff_no, sys_d, fromid, kwargs)`
  - `self.buff:control_try_enter(res.ID, sys_d, res.data, false, kwargs:get("reason"), kwargs)`
  - `G.net:call_server_with_token("buff", "rpc_clientify_call_buff", "add_buff", self.id, { ... })`
- Why it matters:
  - Even in fake-server mode, a local pre-enter path exists only for a subset of buffs and the code still usually sends the authoritative server RPC afterward.
- Evidence Confidence: 5/5

## Evidence 3
- Source: `Scripts/source_decompiled/hexm/common/consts/buff_consts.lua`
- Excerpt:
  - `_M.TH_FAKE_MODE_LOCAL = { ["buff_control_type"] = 0 }`
  - `function _M.is_client_buff(sys_d)`
  - `if sys_d:get(k, default) ~= default then`
  - `return true`
  - `end`
- Why it matters:
  - In current authoritative code, the strict `is_client_buff` gate is driven by `buff_control_type`. That means "client buff" in the fake-server pre-enter sense is selective, not universal.
- Evidence Confidence: 5/5

## Evidence 4
- Source: `Scripts/source_decompiled/hexm/common/combat/buff/imp_buff.lua`
- Excerpt:
  - `if`
  - `show_type == buff_consts.SHOW_SERVER_ONLY`
  - `and space`
  - `and space:mode_is_single()`
  - `and sys_d:get("has_fake_need")`
  - `then`
  - `show_type = buff_consts.SHOW_ALL_CLIENTS`
- Why it matters:
  - `has_fake_need` affects sync/display policy by forcing otherwise server-only buff presentation to clients in single-mode cases.
- Evidence Confidence: 5/5

## Evidence 5
- Source: `Scripts/source_decompiled/hexm/client/fake_server/entities/common_members/buff_base.lua`
- Excerpt:
  - `local function buff_need_fake_logic(sys_d)`
  - `if sys_d:get("has_fake_need") then return true end`
  - `local conf_res = sys_d:get("buff_add_resource")`
  - `if conf_res and attr_consts.is_local_res(conf_res[2]) then return true end`
  - `if BuffAddShieldCharged.should_enable(sys_d) then return true end`
  - `...`
  - `if buff_need_fake_logic(sys_d) then`
  - `bh = self.buff:_add_buff_handler(buff, sys_d, true, { ["duration"] = -1 })`
- Why it matters:
  - `has_fake_need` is a direct switch for local fake-server buff logic, grouped with other clearly local-simulation cases such as local resources and charged shields.
- Evidence Confidence: 5/5

## Evidence 6
- Source: `Scripts/source_decompiled/hexm/common/combat/buff/imp_buff.lua`
- Excerpt:
  - `function BaseMember:_buff_anti_on_check(event, data)`
  - `for bno, bid in pairs(self._buff_anti_records) do`
  - `local it = self.buff.buffs:get(bid)`
  - `if it and it.sys_d:get("has_anti_need") then`
  - `rm_buffs:append(it.ID)`
  - `end`
  - `self._buff_anti_records:clear()`
  - `if #rm_buffs > 0 then self.buff:remove_buffs(rm_buffs, event) end`
- Why it matters:
  - `has_anti_need` marks buffs that are eligible for removal by the anti-check cleanup path.
- Evidence Confidence: 4/5

## Evidence 7
- Source: `Scripts/source_decompiled/hexm/common/combat/buff/buff_comp.lua` and `Scripts/source_decompiled/hexm/common/combat/buff/buff_funcs.lua`
- Excerpt:
  - `if owner._buff_anti_clear and kwargs:get("anti_clear") then owner._buff_anti_clear[bid] = true end`
  - `if self.owner and self.owner._buff_anti_clear then self.owner._buff_anti_clear:pop(buffid) end`
- Why it matters:
  - There is a separate `anti_clear` bookkeeping path, but it is distinct from the direct `has_anti_need` check found above.
- Evidence Confidence: 3/5

## Evidence 8
- Source: `Scripts/source_decompiled/hexm/common/combat/buff/factory.lua` and `Scripts/source_decompiled/hexm/common/combat/buff/members/import.lua`
- Excerpt:
  - `function BuffHandlerFactory:get_components(uid, sys_d, is_partial)`
  - `if it.should_enable(sys_d) then out_arr:append(it) end`
  - `require("hexm.common.combat.buff.members.buff_attribute")`
  - `require("hexm.common.combat.buff.members.buff_add_shield")`
  - `require("hexm.common.combat.buff.members.buff_lifesteal").BuffHandlerMember`
  - `require("hexm.common.combat.buff.members.buff_passive")`
- Why it matters:
  - Buff behavior is assembled from enabled handler modules. A buff row can therefore have multiple behavior families at once, not a single fixed type.
- Evidence Confidence: 5/5

## Evidence 9
- Source: `Scripts/source_decompiled/hexm/common/combat/buff/members/buff_passive.lua`
- Excerpt:
  - `function PassiveLogic.should_enable(sysd)`
  - `return sysd:get("passive_effect")`
  - `if G.datam.buff_passive_data:get(passive_id) then`
  - `buff_passive_misc.reg_passive_logic(self, passive_id)`
- Why it matters:
  - A large portion of buff behavior is indirect through `passive_effect` and `buff_passive_data`, not just direct fields on the buff row.
- Evidence Confidence: 5/5

## Evidence 10
- Source: `Scripts/source_decompiled/hexm/common/combat/buff/buff_comp.lua` and `Scripts/source_decompiled/hexm/common/combat/buff/members/buff_duration.lua`
- Excerpt:
  - `local duration = kwargs:get("duration") or sys_d:get("buff_maxtime", 20)`
  - `if duration >= 0 and duration < buff_consts.MIN_DURATION then return buff_consts.ERR_ADD_ARG_DURATION, nil end`
  - `if duration >= 0 then self:add_k_callback(K_TMR, duration, 0, "_on_duration_end") end`
  - `_on_duration_end -> self.comp:remove_buffs({ self.data.ID }, "duration", buff_consts.RTYPE_TIME_END)`
- Why it matters:
  - Duration defaults to `buff_maxtime`, can be overridden by kwargs, is validated, and timed buffs get an expiry callback while permanent buffs do not.
- Evidence Confidence: 5/5

## Evidence 11
- Source: `Scripts/source_decompiled/hexm/common/combat/buff/members/buff_duration.lua`
- Excerpt:
  - `local conf_duration_mode = self.sys_d:get("buff_sameadd_freshen_mode")`
  - `if conf_duration_mode == buff_consts.REFRESH_DURATION_MODE_EXTEND then`
  - `duration = self.sys_d:get("buff_sameadd_freshen_param", 0) + self.data.duration`
  - `local buff_sameadd_freshen_max = self.sys_d:get("buff_sameadd_freshen_max")`
- Why it matters:
  - Refreshing a buff is configurable. In extend mode, refresh adds time and can be capped by `buff_sameadd_freshen_max`. Outside extend mode, refresh only replaces duration when the new duration is actually stronger/newer.
- Evidence Confidence: 5/5

## Evidence 12
- Source: `Scripts/source_decompiled/hexm/common/combat/buff/members/buff_refresh.lua`
- Excerpt:
  - `if self.sys_d:contains("buff_sameadd_max") then self:_check_stack(add_charge, charge_level, fromid) end`
  - `local conf_max_charge = self.sys_d.buff_sameadd_max`
  - `charge_level = math.min(conf_max_charge, charge_level)`
  - `self.data.charge_level = charge_level`
  - `self:_callComponents("stack")`
- Why it matters:
  - Stack growth is explicit. `add_charge` / `charge_level` feed into `charge_level`, and `buff_sameadd_max` clamps the maximum.
- Evidence Confidence: 5/5

## Evidence 13
- Source: `Scripts/source_decompiled/hexm/common/combat/buff/members/buff_sameadd_buff.lua`
- Excerpt:
  - `function BuffHandlerMember.should_enable(sys_d) return sys_d:get("buff_sameadd_addelse") end`
  - `for _, it in pairs(conf_v) do`
  - `local need_charge, add_buff_no, add_charge, add_target, is_destroy_self = it:unpack()`
  - `if need_charge == curr_charge then`
  - `self:add_buff_inherit(add_buff_no, nil, { ["add_charge"] = add_charge, ... })`
- Why it matters:
  - Some stacks trigger additional buffs at threshold charges. Stacking is therefore not just a number; it can drive chained buff creation.
- Evidence Confidence: 5/5

## Evidence 14
- Source: `Scripts/data/DirObject/GreyTableInfo/hexm.client.data_oversea.buff.json`
- Excerpt:
  - `"buff_maxtime": -1.0`
  - `"buff_sameadd_max": 10`
  - `"buff_sameadd_addelse": [`
  - `"buff_sameadd_freshen_mode": 2`
- Why it matters:
  - The authoritative buff data actually uses the duration, stack-cap, threshold-stack, and refresh-mode fields described by the code paths above.
- Evidence Confidence: 5/5

## Evidence 15
- Source: `Scripts/source_decompiled/hexm/client/net/network_comp/net_call_rpc.lua`
- Excerpt:
  - `function NetCallRpc:call_server_with_token(tag, rpc_method, ...)`
  - `avatar.server[rpc_method](avatar.server, token, ...)`
  - `return true`
- Why it matters:
  - `call_server_with_token(...)` only confirms the RPC was dispatched through the client network stub. It does not itself decode an "accepted/rejected buff add" result.
- Evidence Confidence: 5/5

## Evidence 16
- Source: `Scripts/source_decompiled/hexm/client/entities/server/common_members/buff_base.lua`
- Excerpt:
  - `self._buff_dispatch_listener = self.data_dispatcher:add_by_cbname("Buff", self, "_handle_buff_data_event")`
  - `if action == event_consts.E_DATA_ACTION_INSERT then`
  - `local_entity:handle_add_buff(buff_id, new_buff)`
  - `elseif action == event_consts.E_DATA_ACTION_DELETE then`
  - `local_entity:handle_del_buff(buff_id, old_buff)`
  - `elseif action == event_consts.E_DATA_ACTION_MODIFY / UPDATE then`
  - `local_entity:handle_buff_modify_property(...) / handle_buff_update_value(...)`
- Why it matters:
  - The client's authoritative confirmation path is the synchronized `Buff` data channel. When the server-side buff bag changes, the client receives insert/update/delete events and turns those into local buff state changes.
- Evidence Confidence: 5/5

## Evidence 17
- Source: `Scripts/source_decompiled/hexm/client/entities/local/common_members/buff_base.lua`
- Excerpt:
  - `function BuffBase:handle_add_buff(buff_id, new_buff)`
  - `self._buffs[buff_id] = buff`
  - `self:dispatch_common(event_consts.E_ENTITY_ADD_BUFF, buff_data)`
  - `if self.tag:is_main_player() then`
  - `G.gui_dispatcher:dispatch(event_consts.E_MAIN_PLAYER_ADD_BUFF, buff_data)`
- Why it matters:
  - Once synced buff data reaches the local entity, the client marks the buff as locally present and broadcasts the gameplay/UI events that other systems treat as "buff applied".
- Evidence Confidence: 5/5

## Evidence 18
- Source: `Scripts/source_decompiled/hexm/client/entities/local/buff/buff.lua` and `Scripts/source_decompiled/hexm/client/ui/models/buff/entity_buff_model.lua`
- Excerpt:
  - `function Buff:get_server_buff()`
  - `server_buff = owner.fake_server:get_buff_data(self.id)`
  - `server_buff = server_owner:get_buff_data(self.id)`
  - `if not buff_obj:get_server_buff() then`
  - `else all_buffs:append({ ... end_ts = buff_obj:get_server_buff():get_end_ts(), ... })`
- Why it matters:
  - UI/model consumers explicitly read back through synchronized buff data. A local buff object without backing server/fake-server buff data is not treated as a fully confirmed visible buff by these consumers.
- Evidence Confidence: 5/5

## Evidence 19
- Source: `Scripts/source_decompiled/hexm/client/fake_server/entities/common_members/buff_base.lua`
- Excerpt:
  - `if buff_consts.is_client_buff(sys_d) then`
  - `local err, sys_d = self.buff:_check_can_add(buff_no, fromid, kwargs)`
  - `res = MockBuffHandler(buff_no, sys_d, fromid, kwargs)`
  - `self.buff:control_try_enter(res.ID, sys_d, res.data, false, kwargs:get("reason"), kwargs)`
  - `G.net:call_server_with_token("buff", "rpc_clientify_call_buff", "add_buff", self.id, { ... })`
- Why it matters:
  - There is one important exception: some client-buff/control cases can enter a local predicted path immediately before authoritative sync arrives. Even then, the code still usually sends the server RPC afterward.
- Evidence Confidence: 5/5

## Evidence 20
- Source: `Scripts/source_decompiled/hexm/client/fake_server/entities/player_avatar_members/imp_buff.lua`
- Excerpt:
  - `function FakePlayerAvatarMember:_buff_resync_server_buffs()`
  - `local se_data = se and (se.buffs_data.ac_buffs:get(bid) or se.buffs_data.oc_buffs:get(bid))`
  - `if se_data then buff.data = se_data else self:on_server_rm_buff(bid, buff.data) end`
- Why it matters:
  - Fake/local buff handlers are reconciled against server buff data. This reinforces that long-term validity is decided by synchronized buff state, not by the original send call alone.
- Evidence Confidence: 4/5

# Conclusions

1. Server validation remains the default buff-add authority path. `BuffBase:add_buff(...)` routes into fake-server handling when available or sends `rpc_clientify_call_buff`, and even fake-server add still usually calls the server RPC. Evidence Confidence: 5/5
2. Not all buffs are "client-only" in the same sense. The strict `is_client_buff` gate currently marks only buffs whose `buff_control_type` differs from the fake-mode baseline. `has_fake_need` is different: it requests local fake-server processing/display support, but does not by itself prove a server-bypass authority path. Evidence Confidence: 5/5
3. `has_fake_need` is a local-simulation/display flag. It is used both to expose otherwise server-only buffs to the client in single-mode and to decide whether a synchronized buff should spawn a real fake/local buff handler. Evidence Confidence: 5/5
4. `has_anti_need` marks buffs removable by `_buff_anti_on_check`, but the broader lifecycle for `_buff_anti_records` and the dispatcher/caller for `_buff_anti_on_check` was not found in current investigation scope. Evidence Confidence: 4/5
5. Buff behavior is multi-component. Direct fields enable handler modules, while `passive_effect` delegates into `buff_passive_data`; this is why a single buff can mix attack, defense, recovery, utility, and stacking behavior. Evidence Confidence: 5/5
6. Duration and stack behavior are highly configurable. `buff_maxtime` defines baseline duration, refresh can extend or replace duration depending on mode, `buff_sameadd_max` clamps stack count, and `buff_sameadd_addelse` can spawn follow-up buffs at charge thresholds. Evidence Confidence: 5/5
7. After `call_server_with_token(...)`, the client normally knows a buff is really applied only when synchronized `Buff` data inserts or updates land and trigger `handle_add_buff(...)` / `handle_buff_update_value(...)`. The RPC return itself is only a send-success signal. Evidence Confidence: 5/5
8. A narrow predicted exception exists for strict `is_client_buff(...)` cases. Those can create immediate local control/fake handlers before server sync, but they are still reconciled against authoritative buff data afterward. Evidence Confidence: 5/5

# Unknown / Missing Evidence

- `_buff_anti_records` initialization and write sites were not found in `Scripts/source_decompiled/hexm/` during the broader search.
- No direct event/dispatcher binding for `_buff_anti_on_check` was found in current investigation scope.
- The separate `anti_clear` path appears related by name but is not directly linked to `has_anti_need` in the located code.

# Supplemental Current Dump Snapshot

The following is a convenience summary from the generated runtime dump `Scripts/data/buffs_dump.csv`. It is useful for status review, but the authoritative logic conclusions above come from source/code and DirObject data.

- Total buff rows in current dump: `7030`
- Rows with non-zero `control_type` in dump: `187`
  - These are the best current proxy for the strict `is_client_buff` fake-server pre-enter gate, because code uses `buff_control_type` as the only `TH_FAKE_MODE_LOCAL` discriminator.
- Rows with `has_fake_need = 1`: `3722`
- Rows with both non-zero `control_type` and `has_fake_need = 1`: `41`
  - This supports the code distinction that `has_fake_need` and strict client-buff pre-enter are not the same thing.
- Duration snapshot from dump:
  - `3596` infinite
  - `3415` timed
  - `19` blank / unresolved
  - `0` instant

Supplemental stack snapshot from authoritative buff JSON:

- Rows with `buff_sameadd_max`: `2733`
- Rows with `buff_sameadd_max > 1`: `503`
- Rows with `buff_sameadd_addelse`: `105`
- Rows with `buff_sameadd_freshen_mode`: `1150`
  - Mode `1`: `1065`
  - Mode `2` (`REFRESH_DURATION_MODE_EXTEND`): `85`

# Next Scoped Search Steps

1. Trace `_buff_anti_records` by widening beyond direct string matches, including constructor/init patterns and reflective callback registration paths.
2. Trace producer sites for `kwargs:get("anti_clear")` to confirm whether that mechanism overlaps with the `has_anti_need` family or is entirely separate.
3. If needed, extend the CSV again with stack-oriented columns such as `stack_max`, `refresh_mode`, and `threshold_add_buffs` for faster config review.
