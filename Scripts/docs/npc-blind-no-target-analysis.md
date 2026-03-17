# Question / Scope

How to block both of these behaviors with high implementation confidence:

1. Prevent NPCs from targeting / entering combat with the player
2. Prevent NPCs from seeing / recognizing the player

Scope is limited to authoritative sources only:
- `Scripts/source_decompiled/`
- `Scripts/data/DirObject/`

No implementation in this report.

---

# Evidence

## Evidence 1 — NPC aggro on player is gated by the player's aggro-reverse state
- Source: `Scripts/source_decompiled/hexm/common/base/aggro/aggro_forward.lua:129`
- Excerpt:
  ```lua
  function AggroForward:add_aggro_by_id(eid, num, not_from_chain)
  ```
  and
  ```lua
  if entity.tag:is_player() and not entity:get_aggro_reverse():is_aggro_reverse_enabled() then
      return false
  end
  ```
- Why it matters:
  This is the direct combat-targeting gate for standard NPC aggro. If the player's aggro reverse is disabled, NPCs refuse to add the player into aggro.
- Evidence Confidence: 5/5

## Evidence 2 — Ecology / animal aggro uses the same gate
- Source: `Scripts/source_decompiled/hexm/common/base/aggro/aggro_forward.lua:218`
- Excerpt:
  ```lua
  function AggroForward:add_aggro_by_id_ecology(eid, level_diff)
  ```
  and
  ```lua
  if entity and entity.tag:is_view_as_player() and not entity:get_aggro_reverse():is_aggro_reverse_enabled() then
      return false
  end
  ```
- Why it matters:
  Blocking normal aggro alone is not enough. Ecology/animal aggro also checks the player's aggro reverse state.
- Evidence Confidence: 5/5

## Evidence 3 — Existing game code already disables player aggro reverse for a "leave battle" effect
- Source: `Scripts/source_decompiled/hexm/common/combat/buff/members/buff_clear_aggro_reverse.lua:27`
- Excerpt:
  ```lua
  if 1 == param and self.owner.tag:is_view_as_player() then
      self.owner:get_aggro_reverse():push_aggro_reverse_enabled("buff" .. self.ID, false, 10)
      self.owner:clear_aggro_reverse("buff")
  end
  ```
- Why it matters:
  This proves the intended engine-supported way to suppress being targeted is:
  1. disable aggro reverse on the player
  2. clear existing reverse aggro
- Evidence Confidence: 5/5

## Evidence 4 — Existing fake-server player combat GM path also disables aggro reverse and clears current hate
- Source: `Scripts/source_decompiled/hexm/client/fake_server/entities/player_avatar_members/imp_combat.lua:20`
- Excerpt:
  ```lua
  function Combat:set_super_gm_ob(enable)
      if enable then
          self.ignore_alert = true
          self._aggro_reverse:push_aggro_reverse_enabled("gm", false, 1000)
          self:clear_aggro_reverse()
      else
          self.ignore_alert = false
          self._aggro_reverse:pop_aggro_reverse_enabled("gm")
      end
  end
  ```
- Why it matters:
  There is already a shipped high-priority player-side toggle pattern for anti-targeting. It disables aggro reverse and clears current attackers.
- Evidence Confidence: 5/5

## Evidence 5 — Clearing reverse aggro actively removes the player from NPC aggro tables
- Source: `Scripts/source_decompiled/hexm/common/base/aggro_reverse_base.lua:34`
- Excerpt:
  ```lua
  function AggroReverseBase:clear_aggro_reverse(reason)
      local haters = self._aggro_reverse:get_haters()
      for _, eid in pairs(haters) do
          local entity = self.space:get_entity(eid)
          if entity then
              entity:call_real_syn("del_from_aggro_table", self.id, reason)
          end
          self:del_aggro_reverse(eid)
      end
  end
  ```
- Why it matters:
  Disabling new aggro is not enough. This function is the authoritative cleanup path for existing NPCs already targeting the player.
- Evidence Confidence: 5/5

## Evidence 6 — NPC target selection prioritizes hatred target, then aggro, then alert/watch sources
- Source: `Scripts/source_decompiled/hexm/common/AI/npc_ai.lua:242`
- Excerpt:
  ```lua
  if 0 == source then
      if bool(self.entity:prop_get({"aggro_table", "hatred_target"})) then
          return self.entity:prop_get({"aggro_table", "hatred_target"})
      end
      source_map = self.entity:get_aggro_forward():get_aggro_table():get_table()
  else
      if 1 == source then
          source_map = self.entity:get_alert_map()
      else
          if 2 == source then
              source_map = self.entity.watch_map
  ```
- Why it matters:
  To fully stop NPC behavior, it is not enough to block aggro alone. NPC AI can choose from alert and watch-derived sources too.
- Evidence Confidence: 5/5

## Evidence 7 — Player sight-reverse state is the direct gate for NPC sight checks
- Source: `Scripts/source_decompiled/hexm/common/base/sight/sight_base.lua:283`
- Excerpt:
  ```lua
  if entity.tag:is_view_as_player() then
      if portable.IS_CLIENT then
          local le = G.space:get_entity(entity.id)
          if le and le.get_sight_reverse_enable and not le:get_sight_reverse_enable(self._sight_class_type) then
              return false
          end
  ```
- Why it matters:
  This is the direct "NPC cannot see player" gate in sight validation.
- Evidence Confidence: 5/5

## Evidence 8 — Sight-reverse is a real stack-based player capability with per-sight-type and global control
- Source: `Scripts/source_decompiled/hexm/common/base/sight_manager_reverse_base.lua:14`
- Excerpt:
  ```lua
  function SightManagerReverseBase:push_sight_reverse_enable(reason, sight_type, is_enable, priority)
      if not sight_type then
          for st, stack in pairs(self._sight_reverse_flag_stacks) do
              stack:push_flag(reason, { ["sight_type"] = st, ["is_enable"] = is_enable }, priority)
          end
          return
      end
  ```
- Why it matters:
  This confirms a single global toggle can disable all sight types by passing `nil` for `sight_type`.
- Evidence Confidence: 5/5

## Evidence 9 — There is already a built-in GM/debug toggle that disables NPC sight globally on the player
- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/imp_sight_manager_reverse.lua:16`
- Excerpt:
  ```lua
  function PlayerAvatarMember:change_npc_sight_enable()
      if G.GM_NPC_SIGHT_ENABLE then
          self:pop_sight_reverse_enable("GM_NPC_SIGHT_ENABLE")
      else
          self:push_sight_reverse_enable("GM_NPC_SIGHT_ENABLE", nil, false, 999)
      end
  end
  ```
- Why it matters:
  This is direct evidence that the game already supports an all-sight-types off switch for the player.
- Evidence Confidence: 5/5

## Evidence 10 — The GM sight flag exists and defaults to enabled
- Source: `Scripts/source_decompiled/hexm/client/G.lua:191`
- Excerpt:
  ```lua
  _M.GM_NPC_SIGHT_ENABLE = true
  ```
- Why it matters:
  The debug-side feature in Evidence 9 is real, wired, and intended to be toggled.
- Evidence Confidence: 4/5

## Evidence 11 — NPC watch behavior is separate from combat aggro and can be disabled by AI config
- Source: `Scripts/source_decompiled/hexm/client/entities/local/npc_members/imp_watch.lua:25`
- Excerpt:
  ```lua
  local ai_data = self:get_ai_data()
  if ai_data and ai_data:get("disable_watch") then
      self._entity_disable_watch = bool(ai_data:get("disable_watch"))
  end
  ```
  and
  ```lua
  if self._entity_disable_watch then
      return
  end
  ```
- Why it matters:
  This is a config-side "don't visually watch targets" flag, but it is narrower than the full sight-reverse gate.
- Evidence Confidence: 4/5

## Evidence 12 — Real data contains AI entries with `disable_watch = 1`
- Source: `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.entity_ai.json:5308`
- Excerpt:
  ```json
  [
      99000043,
      {
          "disable_watch": 1,
          "ai_strid": 99000043,
          "id": 99000043,
          "ai_bfsm": "common/AI/common_btree.se"
      }
  ]
  ```
- Why it matters:
  Confirms `disable_watch` is not dead code.
- Evidence Confidence: 4/5

## Evidence 13 — NPC alert gain on player is separately gated by player alert-reverse state
- Source: `Scripts/source_decompiled/hexm/common/base/alert_base.lua:218`
- Excerpt:
  ```lua
  if num > 0 and entity and not entity:prop_get({
      "alert_reverse_enabled",
  }) then
      return
  end
  if entity and entity.ignore_alert then
      return cur_value
  end
  ```
- Why it matters:
  Blocking sight alone is not enough. NPC alert accumulation toward the player has its own gate.
- Evidence Confidence: 5/5

## Evidence 14 — Player alert-reverse is a real stack-based system
- Source: `Scripts/source_decompiled/hexm/common/base/alert_reverse_base.lua:14`
- Excerpt:
  ```lua
  self._alert_reverse_enable_flag_proxy = FlagStackProxy(function(enable)
      self:_on_alert_reverse_enabled_changed(enable)
  end, { ["flag"] = "init", ["args"] = true })
  ```
  and
  ```lua
  function AlertReverseBase:push_alert_reverse_enabled(reason, enabled, priority)
      self._alert_reverse_enable_flag_proxy:push_flag(reason, enabled, priority)
  end
  ```
- Why it matters:
  There is a supported player-side toggle for disabling alert accrual independently of aggro and sight.
- Evidence Confidence: 5/5

## Evidence 15 — Clearing reverse alert actively removes the player from NPC alert tables
- Source: `Scripts/source_decompiled/hexm/common/base/alert_reverse_base.lua:55`
- Excerpt:
  ```lua
  function AlertReverseBase:clear_reverse_alert_table()
      local eid_list = self:prop_get({"reverse_alert_table"}):keys()
      for _, eid in pairs(eid_list) do
          local entity = self.space:get_entity(eid)
          if entity then
              entity:call_real_syn("remove_alert_by_id", self.id)
          end
      end
  end
  ```
- Why it matters:
  A reliable toggle must also clean existing alert state, not just suppress future alert increases.
- Evidence Confidence: 5/5

## Evidence 16 — Dialog leave-battle path combines all three player-side suppressors: sight, aggro, and alert cleanup
- Source: `Scripts/source_decompiled/hexm/client/entities/local/common_members/dialogs_base.lua:666`
- Excerpt:
  ```lua
  self.fake_server:push_can_choose_by_target(false, reason, priority)
  self:push_sight_reverse_enable(reason, nil, false, priority)
  self.fake_server:clear_aggro_reverse()
  self.fake_server:clear_reverse_alert_table()
  aggro_reverse:push_aggro_reverse_enabled(reason, false, priority)
  ```
- Why it matters:
  This is the strongest multi-system reference pattern found in current scope. It shows the engine itself combines these controls to make the player effectively untargetable/unnoticed during dialog leave-battle.
- Evidence Confidence: 5/5

## Evidence 17 — Existing code also supports disabling alert-reverse for scripted scenarios
- Source: `Scripts/source_decompiled/hexm/common/base/guanqia_npc_base.lua:274`
- Excerpt:
  ```lua
  for pid, avt in pairs(e.space.avatars) do
      if pid ~= p.id then
          avt:push_alert_reverse_enabled("guanqia_npc_trace", false)
      end
  end
  ```
- Why it matters:
  Confirms `push_alert_reverse_enabled()` is live gameplay logic, not dead support code.
- Evidence Confidence: 4/5

## Evidence 18 — Existing GM anti-target path suppresses alert through `ignore_alert`
- Source: `Scripts/source_decompiled/hexm/client/fake_server/entities/player_avatar_members/imp_combat.lua:20`
- Excerpt:
  ```lua
  self.ignore_alert = true
  ```
  Cross-reference source: `Scripts/source_decompiled/hexm/common/base/alert_base.lua:223`
  ```lua
  if entity and entity.ignore_alert then
      return cur_value
  end
  ```
- Why it matters:
  This is another proven anti-alert mechanism, but unlike `push_alert_reverse_enabled`, it appears specific to the fake-server player combat GM path.
- Evidence Confidence: 4/5

## Evidence 19 — Stealth / disguise modifies detectability, but is not required for a hard toggle
- Source: `Scripts/source_decompiled/hexm/common/base/sight/sight_base.lua:98`
- Excerpt:
  ```lua
  local stealthy_no = G.STEALTHY_NO or entity:buff_get_flag("hide_no")
  if stealthy_no and self:get_hide_influence_type() then
      return G.datam.stealthy_sight_config_data:get(stealthy_no)
  end
  ```
  and source: `Scripts/source_decompiled/hexm/common/base/sight/sight_base.lua:307`
  ```lua
  target_rate = target_rate * stealthy_config:get("sight_var" .. self:get_hide_influence_type(), 1.0)
  ```
  and source: `Scripts/source_decompiled/hexm/common/base/sight/sight_extension.lua:206`
  ```lua
  value = value * stealthy_config:get("alert_var" .. self:get_hide_influence_type(), 1.0)
  ```
- Why it matters:
  Stealth/hide affects recognition and alert intensity, but current evidence shows it is a soft multiplier system. It is not the simplest or strongest path for a guaranteed on/off anti-NPC toggle.
- Evidence Confidence: 4/5

---

# Conclusions

## Conclusion 1 — There is enough evidence to implement a reliable player-side toggle for both "no target" and "no see"
The strongest authoritative pattern is a combination of:
1. Disable player aggro reverse
2. Clear existing reverse aggro
3. Disable player sight reverse globally for all sight types
4. Disable player alert reverse
5. Clear existing reverse alert table

Primary evidence:
- `Scripts/source_decompiled/hexm/common/base/aggro/aggro_forward.lua:139`
- `Scripts/source_decompiled/hexm/common/base/sight/sight_base.lua:286`
- `Scripts/source_decompiled/hexm/common/base/alert_base.lua:218`
- `Scripts/source_decompiled/hexm/client/entities/local/common_members/dialogs_base.lua:691`

Evidence Confidence: 5/5

## Conclusion 2 — The closest existing engine-proven reference for the full behavior is the dialog leave-battle path
The dialog path already combines:
- target-selection suppression via aggro reverse disable
- current aggro cleanup
- sight suppression
- current alert cleanup
- choose-by-target suppression

Primary evidence:
- `Scripts/source_decompiled/hexm/client/entities/local/common_members/dialogs_base.lua:691`

Evidence Confidence: 5/5

## Conclusion 3 — A hard anti-NPC toggle should rely on aggro/sight/alert reverse systems, not on `disable_watch` or stealth config
- `disable_watch` only suppresses watch behavior for specific NPC AI configs.
- stealth/hide config scales detection/alert but is not a guaranteed hard off-switch.

Primary evidence:
- `Scripts/source_decompiled/hexm/client/entities/local/npc_members/imp_watch.lua:25`
- `Scripts/source_decompiled/hexm/common/base/sight/sight_base.lua:307`
- `Scripts/source_decompiled/hexm/common/base/sight/sight_extension.lua:206`

Evidence Confidence: 4/5

## Conclusion 4 — The minimum high-confidence toggle behavior set is:
### Enable toggle
- player local: `push_sight_reverse_enable(reason, nil, false, priority)`
- player fake_server: `get_aggro_reverse():push_aggro_reverse_enabled(reason, false, priority)`
- player fake_server: `clear_aggro_reverse(reason)`
- player/fake_server alert side: `push_alert_reverse_enabled(reason, false, priority)`
- player/fake_server alert side: `clear_reverse_alert_table()`

### Disable toggle
- undo the pushed flag(s)
- allow systems to repopulate naturally

This is the smallest evidence-backed set that addresses both requested behaviors.

Evidence Confidence: 5/5

---

# Unknown / Missing Evidence

1. The exact runtime ownership split between local player member and fake-server player member for calling `push_alert_reverse_enabled()` was not fully traced in current scope.
2. `push_can_choose_by_target(false, reason, priority)` appears in the dialog path and may further reduce lock/selection behavior, but current scope does not prove it is required for the user's requested 1+2 behaviors.
3. The backing data file for `G.datam.stealthy_sight_config_data` was not located in current `DirObject` search scope. The code usage is authoritative, but config-file location remains unresolved.
4. No direct "appearance recognition memory" subsystem was found. In current scope, "recognize appearance" maps best to sight validity, alert accrual, disguise/guise checks, and stealth influence.

---

# Next Scoped Search Steps

1. Trace where `push_alert_reverse_enabled()` is exposed on the player object used by runtime scripts, to pin exact call site for implementation.
2. Trace where `push_can_choose_by_target()` is defined and decide whether it should be included in a final anti-NPC toggle.
3. Verify the concrete module export path for player local/fake-server components that own:
   - `push_sight_reverse_enable`
   - `push_alert_reverse_enabled`
   - `get_aggro_reverse`
   - `clear_aggro_reverse`
   - `clear_reverse_alert_table`
4. If implementation is requested next, use the dialog leave-battle flow as the primary reference pattern, not stealth config or NPC `disable_watch`.
