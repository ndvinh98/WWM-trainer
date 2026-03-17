# Question / Scope

Analyze the current ways buffs can be applied to the player, with focus on:

- the old `hexm.client.ui.windows.gm.gm_combat.combat_train_action` route
- the current `G.main_player:add_buff(...)` route and its restrictions
- built-in gameplay systems that still add buffs to the player

Scope is limited to authoritative sources only:

- `Scripts/source_decompiled/`
- `Scripts/data/DirObject/`

# Evidence

## Evidence 1: The old GM combat-train route is still referenced as a debug-only UI path

- Source: `Scripts/source_decompiled/hexm/client/ui/handlers/ui_gm_combat_train_handler.lua`
- Excerpt:
  - `if not G.DEBUG then return end`
  - `if 1078 ~= spaceno and 1073 ~= spaceno then return end`
  - `local CombatTrainWindow = require("hexm.client.ui.windows.gm.gm_combat.combat_train_window").CombatTrainWindow`
- Why it matters: the combat-train window was a debug-only path tied to specific spaces, not a normal gameplay API.
- Evidence Confidence: 4/5

- Source: `Scripts/source_decompiled/hexm/client/manager/input/input_handler.lua`
- Excerpt:
  - `require("hexm.client.ui.windows.gm.gm_combat.combat_train_action").kill_all_npc()`
- Why it matters: current code still contains direct references to the old GM combat-train action module family.
- Evidence Confidence: 4/5

## Evidence 2: `G.main_player:add_buff(...)` is a transport/router, not a free local injector

- Source: `Scripts/source_decompiled/hexm/client/entities/local/common_members/buff_base.lua`
- Excerpt:
  - `function BuffBase:add_buff(buff_no, fromid, kwargs)`
  - `if self.fake_server then self.fake_server:call_real_syn("add_buff", buff_no, fromid, kwargs)`
  - `G.net:call_server_with_token("buff", "rpc_clientify_call_buff", "add_buff", self.id, { buff_no, fromid, data })`
  - `if G.space and G.space:get_space_tag():is_watch_play_boss_space() then return end`
  - `portable.on_traceback(msg)`
- Why it matters: calling `add_buff` on the local player does not directly create a buff handler on the client. It either routes into fake-server logic, sends a tokenized server buff RPC, or logs/fails outside supported spaces.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/common_members/buff_base.lua`
- Excerpt:
  - `if kwargs:get("duration") then data.duration = kwargs.duration end`
  - `if kwargs:get("charge_level") then data.charge_level = kwargs.charge_level end`
  - `data.reason = kwargs and kwargs:get("reason") or "local_call"`
- Why it matters: in the non-fake-server branch, only `duration`, `charge_level`, and `reason` are forwarded. Other add parameters are dropped on this path.
- Evidence Confidence: 5/5

## Evidence 3: Fake-server buff routes only exist when the space creates a fake server

- Source: `Scripts/source_decompiled/hexm/client/entities/local/common_members/fake_server.lua`
- Excerpt:
  - `function FakeServer:check_create_fake_server()`
  - `return G.space:is_in_single_mode()`
- Why it matters: the stronger fake-server route only exists in single-mode contexts by default.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/fake_server/entities/player_avatar_members/imp_buff.lua`
- Excerpt:
  - `local FakePlayerAvatarMember = class("FakePlayerAvatarMember", buff_base.BuffWithServer)`
  - `self.buff._is_ready = true`
- Why it matters: the player fake-server entity uses `BuffWithServer`, so it exposes a real buff component path when fake-server mode exists.
- Evidence Confidence: 5/5

## Evidence 4: `fake_server:add_buff(...)` is stronger than `G.main_player:add_buff(...)`, but still guarded

- Source: `Scripts/source_decompiled/hexm/client/fake_server/entities/common_members/buff_base.lua`
- Excerpt:
  - `function BuffWithServer:add_buff(buff_no, fromid, kwargs)`
  - `local sys_d = buff_misc.get_buff_sys_d(buff_no)`
  - `if buff_consts.is_client_buff(sys_d) then`
  - `local err, sys_d = self.buff:_check_can_add(buff_no, fromid, kwargs)`
  - `self.buff:control_try_enter(res.ID, sys_d, res.data, false, kwargs:get("reason"), kwargs)`
  - `G.net:call_server_with_token("buff", "rpc_clientify_call_buff", "add_buff", self.id, { buff_no, fromid, kwargs })`
- Why it matters: fake-server add can locally pre-enter some buffs, but it still validates the buff and still usually sends the same tokenized server RPC.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/consts/buff_consts.lua`
- Excerpt:
  - `_M.TH_FAKE_MODE_LOCAL = { ["buff_control_type"] = 0 }`
  - `function _M.is_client_buff(sys_d) ... if sys_d:get(k, default) ~= default then return true end`
- Why it matters: the local pre-enter path is conditional. It is not a blanket "force add any buff locally" path.
- Evidence Confidence: 4/5

## Evidence 5: Real buff application is blocked by readiness, death, immunity, duration, and control checks

- Source: `Scripts/source_decompiled/hexm/common/combat/buff/buff_comp.lua`
- Excerpt:
  - `if not self._is_ready then return buff_consts.ERR_ADD_NOT_READY, nil end`
  - `if not ignore_dead and self.owner:is_dead() and 0 == sys_d:get("dead_addbuff", 0) then return buff_consts.ERR_ADD_DEAD, nil end`
  - `local err = self:check_immune(buff_no, sys_d, fromid)`
  - `if duration >= 0 and duration < buff_consts.MIN_DURATION then return buff_consts.ERR_ADD_ARG_DURATION, nil end`
  - `local err = self:check_enter_control(sys_d)`
- Why it matters: even internal add paths do not blindly succeed. Buff application is validated before the handler is created.
- Evidence Confidence: 5/5

## Evidence 6: Buffs can also be rejected by space restrictions and default persistence rules

- Source: `Scripts/source_decompiled/hexm/common/combat/buff/buff_comp.lua`
- Excerpt:
  - `local buff_active_space = sys_d:get("buff_active_space")`
  - `if not buff_misc.buff_active_space(buff_active_space, space_tag, space_no) then return end`
  - `local conf = sys_d:get("buff_destroy_owner")`
  - `persistent = conf and #conf >= 4 and conf[4] or 0`
- Why it matters: a valid buff row can still fail to apply in the current space, and persistence can fall back to buff config.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/misc/buff_misc.lua`
- Excerpt:
  - `if 1 == active_type then if not space_tag:is_homeworld_space() and not space_tag:is_main_world() then return false end`
  - `if 2 == active_type then if not equip_misc.is_equip_pvp_space(space_tag, space_no) then return false end`
  - `if 3 == active_type then if not space_tag:is_boss_online_space() then return false end`
  - `if 4 == active_type and equip_misc.is_equip_pvp_space(space_tag, space_no) then return false end`
- Why it matters: `buff_active_space` is a concrete gate used during add.
- Evidence Confidence: 5/5

## Evidence 7: There are current server-stub helper routes that can feed player fake-server buff adds

- Source: `Scripts/source_decompiled/hexm/client/entities/server/player_avatar_members/imp_buff.lua`
- Excerpt:
  - `function PlayerAvatarMember:rpc_fake_add_buff(buff_no, fromid, add_charge)`
  - `local fe = self:get_local_entity().fake_server`
  - `fe.buff:add_buff(buff_no, fromid, { ["add_charge"] = add_charge })`
- Why it matters: there is still a built-in server-to-client stub path that can apply buffs through the player's fake-server buff component.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/entities/server/player_avatar_members/imp_dungeon.lua`
- Excerpt:
  - `function PlayerAvatarMember:rpc_dungeon_add_buff_list(buff_list)`
  - `for _, buff_no in pairs(buff_list) do local_entity.fake_server:add_buff(buff_no, self.id) end`
- Why it matters: dungeon systems still have a dedicated buff-grant route for the player.
- Evidence Confidence: 5/5

## Evidence 8: Xinfa and passive skills are a built-in player buff producer

- Source: `Scripts/source_decompiled/hexm/common/base/ai_avatar/xinfa_base.lua`
- Excerpt:
  - `local skill_id = xinfa:passive_skill()`
  - `self.skill_ctrl:add_passive_skill(skill_id, { ["level"] = xinfa.level })`
- Why it matters: Xinfa do not add player buffs directly. They first enable passive skills.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/combat/skill_ctrl.lua`
- Excerpt:
  - `if 0 == sysd:get("condition", 0) then`
  - `local buffs = sysd:get("buff_id")`
  - `self.entity:add_buff(bid, self.entity.id, { ["duration"] = -1, ["persistent"] = false, ["reason"] = "enable_passive_skill", ["ignore_dead"] = true })`
- Why it matters: passive-skill config field `buff_id` is a real built-in path that grants player buffs, including Xinfa-derived passives.
- Evidence Confidence: 5/5

## Evidence 9: Skills, hits, and behit processing can add buffs to the player or target

- Source: `Scripts/source_decompiled/hexm/common/base/calcpoint_base.lua`
- Excerpt:
  - `entity:add_buff(it[1], entity.id, { ["reason"] = "attack other", ["add_charge"] = charge_lv, ["skill_id"] = skill_id, ["damage"] = damage, ["persistent"] = 0 })`
  - `for _, buff_no in pairs(buffs) do owner:add_buff(buff_no, owner.id) end`
- Why it matters: combat hit processing directly adds buffs based on combat calculations and configured buff lists.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/combat/behit/behit_base.lua`
- Excerpt:
  - `local buff_handler = target:add_buff(buff_no, attacker_id, kwargs)`
  - `local spl_add_buff_info = calc_sysd:get("behit_extra_add_buff_1", {})`
- Why it matters: behit config can grant target buffs during hit resolution through data fields like `behit_extra_add_buff_1`.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/combat/skill_logics/rapid_dianxue.lua`
- Excerpt:
  - `cur_target:add_buff(buff_id, self.entity.id, { ["buff_target"] = self.last_target.id })`
- Why it matters: some active skill logic scripts directly apply buffs as part of their custom behavior.
- Evidence Confidence: 4/5

## Evidence 10: Buff systems themselves can spawn more buffs

- Source: `Scripts/source_decompiled/hexm/common/misc/buff_passive_misc.lua`
- Excerpt:
  - `function _M._sub_effect_add_buff(buff, target, buff_id, fromid, kwargs)`
  - `if portable.IS_CLIENT then target:add_buff(buff_id, fromid, kwargs) else target:call_real_syn("add_buff", buff_id, fromid, kwargs) end`
- Why it matters: buff passive effects are an explicit buff-to-buff application route.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/combat/buff/members/buff_sameadd_buff.lua`
- Excerpt:
  - `if 1 == add_target then self:add_buff_inherit(add_buff_no, nil, { ["add_charge"] = add_charge, ["reason"] = string.format("trigger by No.%s", self.No) })`
  - `if 2 == add_target then fromer:add_buff(add_buff_no, self.owner.id, { ["skill_id"] = self.data.skill_id })`
- Why it matters: stacking/threshold buff config can automatically apply follow-up buffs to owner or source.
- Evidence Confidence: 5/5

## Evidence 11: Interactions and treasure-box style world systems can grant player buffs from data

- Source: `Scripts/source_decompiled/hexm/common/base/active_interact_handlers/handler_normal.lua`
- Excerpt:
  - `local buffs = act_board.sys_d:get("get_buff", {})`
  - `avatar:add_buff(buff_no, avatar.id, { ["reason"] = "active interact apply buff" })`
  - `fake_server:add_buff(buff_no, avatar.id, { ["reason"] = "active interact apply buff" })`
- Why it matters: interaction config field `get_buff` is a built-in buff grant path for the player.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/base/interact_comp/interact_trans/interact_trans_base.lua`
- Excerpt:
  - `local buff_no = G.datam.hexi_box_config:get(box_level, {}):get("player_buff")`
  - `self:add_buff(buff_no, box_eid, { ["reason"] = "hexi_treasure_box" })`
- Why it matters: treasure-box style interactions also grant player buffs through `player_buff` data.
- Evidence Confidence: 5/5

## Evidence 12: AI, actionline, and local gameplay modules can still apply player buffs

- Source: `Scripts/source_decompiled/hexm/common/AI/nodes/common_action_nodes/combat_nodes.lua`
- Excerpt:
  - `self.owner.entity:add_buff(int(buff_id), self.owner.entity.id, params)`
  - `target_entity:add_buff(int(buff_id), self.owner.entity.id, params)`
- Why it matters: AI nodes have a generic "apply buff" capability for self and targets.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/actionline/nodes/special_nodes.lua`
- Excerpt:
  - `if portable.IS_CLIENT then entity = entity.fake_server end`
  - `entity:add_buff(self.buff_no, entity.id, { ["charge_level"] = charge_lv })`
- Why it matters: actionline nodes can add buffs directly, and on client they explicitly switch to fake-server.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/gameplays/imp_special_training.lua`
- Excerpt:
  - `if self.space and self.space:get_space_tag():is_client_space() then`
  - `for _, buff_no in pairs(G.datam.special_training_consts[1]:get("buff_no")) do self:add_buff(buff_no) end`
- Why it matters: local gameplay modules still add player buffs from gameplay config such as `special_training_consts.buff_no`.
- Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/imp_trap.lua`
- Excerpt:
  - `G.net:call_server("region_game_local_client_add_buff", -1, 1005001, region_game_consts.REGION_GAME_FEI_TIAN_WU_YUE_TU)`
  - `self:add_buff(1005001, self.id, { ["reason"] = "is_happy_rabbit_trap" })`
- Why it matters: trap and region-game logic use both server-assisted and direct local player buff routes.
- Evidence Confidence: 5/5

# Conclusions

- The old `gm_combat` combat-train route is still referenced by current debug code, but it is not a normal gameplay path. In current authoritative scope, it behaves as a stale/debug module family rather than the supported player buff API. Evidence score: 4/5.
- `G.main_player:add_buff(...)` is not a local "force apply any buff" call. It routes into fake-server logic if available, otherwise it sends `rpc_clientify_call_buff`, and outside supported spaces it only traces/returns. Evidence score: 5/5.
- The non-fake-server `G.main_player:add_buff(...)` path only forwards `duration`, `charge_level`, and `reason`. If you need other add parameters, this route does not preserve them. Evidence score: 5/5.
- The fake-server route is only available by default in single-mode spaces. Even there, buff add still goes through validation and usually still issues the tokenized buff RPC. Evidence score: 5/5.
- Current built-in ways that apply buffs to the player include:
  - passive skills, including Xinfa-derived passives through `passive_skills.buff_id`
  - combat hit/behit processing and custom skill logic
  - buff passive effects and buff-to-buff chaining
  - interaction systems through fields like `get_buff` and `player_buff`
  - AI/actionline nodes and local gameplay modules such as special training and traps
  Evidence score: 5/5.

# Unknown / Missing Evidence

- The actual implementation files for `hexm.client.ui.windows.gm.gm_combat.combat_train_action` and `hexm.client.ui.windows.gm.gm_combat.combat_train_window` were not found in the current authoritative client tree. Current scope only confirms surviving references.
- The server-side handler behind `rpc_clientify_call_buff` was not identified in current client-side scope.
- No current authoritative GM command for arbitrary "add buff" injection was found in this scoped pass.

# Next Scoped Search Steps

- Trace the server or packed-side implementation behind `rpc_clientify_call_buff` to determine whether it enforces extra whitelist rules.
- Enumerate player-targeted `add_buff` producers by subsystem if you want a full file-by-file index instead of route families.
- Verify whether specific target buffs are addable through `G.main_player:add_buff(...)` in your current space by checking each buff's `buff_active_space`, `dead_addbuff`, immunity, and control flags.
