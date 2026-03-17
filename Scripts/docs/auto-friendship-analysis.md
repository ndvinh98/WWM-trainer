# Auto Friendship Analysis

## 1. Question / Scope
Determine whether there is a technically scriptable path for auto friendship with NPCs by analyzing the linkage between AI NPC chat, gifting, and `npc_amity` progression using only:
- `Scripts/source_decompiled/`
- `Scripts/data/DirObject/`

## 2. Evidence

### Evidence 1 — `npc_amity` is a real persistent avatar system
- **Source:** `Scripts/source_decompiled/hexm/common/property_define/avatar/npc_amity.lua`
- **Excerpt:**
  - `Property(NPCAmity, "npc_amity_value", CustomIntMapType, _M._property_flag)`
  - `Property(NPCAmity, "npc_amity_level", CustomIntMapType, Property.OWN_CLIENT)`
  - `Property(NPCAmity, "npc_amity_story", NPCAmityStory, _M._property_flag)`
- **Why it matters:** Friendship/progress is not just UI text; the player avatar has persistent per-relation amity value/level/story state.
- **Evidence Confidence:** 5/5

### Evidence 2 — Amity levels and gift-related amity event are explicitly defined
- **Source:** `Scripts/source_decompiled/hexm/common/consts/npc_amity_consts.lua`
- **Excerpt:**
  - `_M.AMITY_LEVEL_STRANGE = 1`
  - `_M.AMITY_LEVEL_INTIMATE_FRIEND = 5`
  - `_M.AMITY_LEVEL_FRIENDSHIP_LIFE_DEAD = 6`
  - `_M.NPC_AMITY_EVENT_SEND_GIFT = "npc_amity_send_gift"`
- **Why it matters:** The friendship system has fixed level progression and explicitly names send-gift as an amity event.
- **Evidence Confidence:** 5/5

### Evidence 3 — Amity value and level are updated from server-side notifications
- **Source:** `Scripts/source_decompiled/hexm/client/entities/server/player_avatar_members/imp_consumption_clip.lua`
- **Excerpt:**
  - `function PlayerAvatarMember:npc_amity_value_change(d)`
  - `G.gui_dispatcher:dispatch(event_consts.E_NPC_AMITY_VALUE_CHANGED, d)`
  - `local cur_value = v_var_data:get("new")`
  - `local npc_relation_id = lv_var_data:get("npc_relation_id")`
- **Why it matters:** Amity progression is not computed only on the client. The client reacts to server-fed change payloads containing new values and relation IDs.
- **Evidence Confidence:** 5/5

### Evidence 4 — Smart AI NPC chat is a real client/server subsystem
- **Source:** `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/chat/imp_npc_chat.lua`
- **Excerpt:**
  - `G.net:call_server("rpc_ai_chat_start", aid, { ... })`
  - `G.net:call_server("rpc_chat_send", pid, data)`
  - `G.net:call_server("rpc_chat_ai_chat", msg)`
- **Why it matters:** Auto-chat behavior is technically scriptable because the game exposes direct RPC entry points for starting and sending chat.
- **Evidence Confidence:** 5/5

### Evidence 5 — Locked vs unlocked AI NPCs use different talk IDs
- **Source:** `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/chat/imp_npc_chat.lua`
- **Excerpt:**
  - `function PlayerAvatarMember:get_default_chat_talk_type(aid)`
  - `if self:is_smart_ai_npc_unlock(aid) then return npc_chat_consts.CHAT_TYPE_CHAT else return npc_chat_consts.CHAT_TYPE_FRIEND end`
  - `local tid_name = npc_chat_consts.get_talk_id_name(chat_type)`
  - `local tid = data:get(tid_name)`
- **Why it matters:** There is a distinct pre-unlock / friendship-stage conversation path (`CHAT_TYPE_FRIEND`) versus normal chat (`CHAT_TYPE_CHAT`). This is strong evidence that chat behavior changes with friendship/unlock state.
- **Evidence Confidence:** 5/5

### Evidence 6 — `friend_talk_id` and `chat_talk_id` are explicit config fields
- **Source:**
  - `Scripts/source_decompiled/hexm/client/consts/npc_chat_consts.lua`
  - `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.smart_ai_npc_data.json`
- **Excerpt:**
  - `[_M.CHAT_TYPE_CHAT] = "chat_talk_id"`
  - `[_M.CHAT_TYPE_FRIEND] = "friend_talk_id"`
  - JSON examples include both:
    - `"friend_talk_id": 4395`
    - `"chat_talk_id": 4396`
- **Why it matters:** Data confirms the code path above is backed by per-NPC configuration. Friendship-stage dialogue is data-driven and potentially targetable by script.
- **Evidence Confidence:** 5/5

### Evidence 7 — Smart AI NPC config contains gift metadata and score classification
- **Source:**
  - `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.smart_ai_npc_data.json`
  - `Scripts/source_decompiled/hexm/common/consts/npc_companion_consts.lua`
- **Excerpt:**
  - JSON examples include:
    - `"gift_type": 1`
    - `"gift_score": 1`
  - Code:
    - `local gift_type = G.datam.smart_ai_npc_data:get(ai_npc_sid, {}):get("gift_type")`
    - `for sid, data in pairs(G.datam.ai_npc_gift_data) do ... if score >= range[1] and score <= range[2] then return sid, reward end`
- **Why it matters:** Gift outcome/reward logic is explicitly keyed off AI NPC metadata and score ranges, showing gifting is a formal subsystem tied to companion NPCs.
- **Evidence Confidence:** 4/5

### Evidence 8 — Gift score bands exist in data
- **Source:** `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.ai_npc_gift_data.json`
- **Excerpt:**
  - `"gift_1_range": [1, 9]`
  - `"gift_1_range": [100, 99999]`
  - `"gift_2_range": [1, 4]`
  - `"gift_2_range": [50, 99999]`
- **Why it matters:** Gift evaluation is table-driven with ranges, which supports the existence of server-validated gift scoring rather than simple client-side increments.
- **Evidence Confidence:** 4/5

### Evidence 9 — Chat endings and chat events can directly open gift interactions
- **Source:**
  - `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/chat/npc_chat_event_handler.lua`
  - `Scripts/source_decompiled/hexm/client/consts/npc_chat_consts.lua`
  - `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/chat/imp_npc_chat.lua`
- **Excerpt:**
  - `if event_id == npc_chat_consts.CHAT_EVENT_GIFT then local res = npc_chat_consts.handle_chat_interact_gift(self.entity)`
  - `if ending_type == npc_chat_consts.CHAT_ENDING_GIFT then ... npc_chat_consts.handle_chat_interact_gift(entity)`
  - `function _M.handle_chat_interact_gift(entity)` opens gift UI or triggers interact `420`
- **Why it matters:** Chat is concretely linked to gifting. A chat session can end in or trigger a gift flow.
- **Evidence Confidence:** 5/5

### Evidence 10 — Gift results shown in chat come from server-owned companion gift state
- **Source:**
  - `Scripts/source_decompiled/hexm/common/property_define/avatar/companion_npc.lua`
  - `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/chat/imp_npc_chat.lua`
- **Excerpt:**
  - `Property(AiGift, "gifted_ts", 0, _property_own_flag)`
  - `Property(AiGift, "sp_gifting_npc", SpGiftingNpc, _property_own_flag)`
  - `Property(AiGift, "gifting_npc", GiftingNpc, _property_own_flag)`
  - `local gift = self:get_server_entity().companion_npc.gift`
  - `local gid = gift.gifting_npc:get(aid, 0)`
  - `self:_send_npc_gift_all()`
- **Why it matters:** Gift follow-up shown in the chat UI is driven by authoritative avatar companion gift state, not fabricated locally by the chat window.
- **Evidence Confidence:** 5/5

### Evidence 11 — Unlock state is separate and server-owned
- **Source:**
  - `Scripts/source_decompiled/hexm/common/property_define/avatar/companion_npc.lua`
  - `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/imp_npc_companion.lua`
- **Excerpt:**
  - `Property(CompanionNpcProp, "unlock_bit", UnlockBit, _property_own_flag)`
  - `return npc_companion_consts.is_smart_ai_npc_unlock(G.net:get_avatar(), smart_npc_no)`
  - `G.net:call_server("rpc_unlock_smart_ai_npc", smart_npc_no)`
- **Why it matters:** Unlock/friend availability is not a local boolean. A script can request actions, but server state decides whether the NPC is unlocked.
- **Evidence Confidence:** 5/5

### Evidence 12 — Some gift interactions are gated by current amity level/value
- **Source:** `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/imp_consumption_wanfa.lua`
- **Excerpt:**
  - `local amity_level = G.net:get_avatar().npc_amity.npc_amity_level:get(relation_no) or 1`
  - `local amity_value = G.net:get_avatar().npc_amity.npc_amity_value:get(relation_no) or 0`
  - `local refuse_gift_levels = amity_sys_d:get("refuse_gift", {})`
  - `if amity_value >= amity_value_max then ...`
- **Why it matters:** Gift-related branches consult current amity state and can lock/refuse options. This suggests progression has gates and caps, not endless blind repetition.
- **Evidence Confidence:** 4/5

### Evidence 13 — Error codes explicitly constrain amity gifting
- **Source:** `Scripts/source_decompiled/hexm/common/errcode.lua`
- **Excerpt:**
  - `ERR_NPC_AMITY_LEVEL_CANNOT_SEND_GIFT = 70180`
  - `ERR_NPC_AMITY_GIFT_NUM_NOT_ENOUGH = 70181`
  - `ERR_NPC_AMITY_GIFT_NOT_SUITABLE = 70182`
- **Why it matters:** The amity gift path has hard validation for level, quantity, and suitability. This is strong evidence against a trivial client-only “set to 100%” path.
- **Evidence Confidence:** 4/5

### Evidence 14 — Concrete mapping exists from AI NPC `aid` to amity relation ID through NPC/entity data
- **Source:**
  - `Scripts/source_decompiled/hexm/common/consts/npc_companion_consts.lua`
  - `Scripts/source_decompiled/hexm/common/misc/consumption_wanfa_misc.lua`
  - `Scripts/source_decompiled/hexm/client/ui/windows/side_page_v2/item_controllers/common/common_title.lua`
- **Excerpt:**
  - `npc_companion_consts.get_npc_no(smart_npc_no)` resolves smart AI NPC to `npc_no` using `entity_id` or `ins_entity_id`
  - `return G.datam.entity_attr:get(G.datam.entity:get(npc_no, {}):get("attr_id", 0), {}):get("npc_relationship_id")`
  - `local relation_id = G.datam.entity_attr:get(G.datam.entity:get(npc_no, {}):get("attr_id", 0), {}):get("npc_relationship_id")`
- **Why it matters:** This provides the missing deterministic relation mapping chain:
  - `aid -> npc_no -> entity.attr_id -> entity_attr.npc_relationship_id`
  This is enough to design target-specific automation against actual amity relation records.
- **Evidence Confidence:** 5/5

### Evidence 15 — Global smart companion system unlock is gated by unlock condition `394`
- **Source:**
  - `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.companion_ai_npc_config.json`
  - `Scripts/source_decompiled/hexm/common/consts/npc_companion_consts.lua`
  - `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.red_point_unlock_config.json`
  - `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.common_condition.json`
  - `Scripts/source_decompiled/hexm/common/consts/unlock_condition_consts.lua`
- **Excerpt:**
  - `"unlock_id": 394`
  - `local unlock_id = G.datam.companion_ai_npc_config[1]:get("unlock_id")`
  - `if not unlock_condition_consts.check_sys_unlock_by_id(unlock_id, avt, false) then`
  - unlock config `394 -> sta_common_condition_id 140211`
  - common condition `140211` includes `"lv_limit": 1`
- **Why it matters:** The companion chat/friend system has a global gate before individual NPC unlocks. This specific gate is weak (`lv_limit = 1`), so it is unlikely to block implementation in normal gameplay.
- **Evidence Confidence:** 4/5

### Evidence 16 — Friend-dialog entries are explicitly configured to terminate into gift flow
- **Source:**
  - `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.ai_npc_dialog_level.json`
  - `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/chat/imp_npc_chat.lua`
  - `Scripts/source_decompiled/hexm/client/consts/npc_chat_consts.lua`
- **Excerpt:**
  - dialog `4395` contains:
    - `"multi_ending": [[1, "smart_290", 1]]`
    - `"multi_ending_wanfa_type": [[0, 1]]`
  - dialog `3155` contains `"result_tag"` and `"multi_ending_wanfa_type"`
  - runtime code reads `local ending_type = data:get("multi_ending_wanfa_type")`
  - if `ending_type == npc_chat_consts.CHAT_ENDING_GIFT` then `npc_chat_consts.handle_chat_interact_gift(entity)`
  - `CHAT_ENDING_GIFT = 1`
- **Why it matters:** This is direct config-to-code proof that at least some friendship-stage dialogs are supposed to end by opening the gift interaction flow.
- **Evidence Confidence:** 5/5

### Evidence 17 — Companion AI config and chat code define practical automation timing constraints
- **Source:**
  - `Scripts/data/DirObject/DirObject_WeakCache/hexm.client.data_oversea.companion_ai_npc_config.json`
  - `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/chat/imp_npc_chat.lua`
- **Excerpt:**
  - `"chat_cd": 2`
  - `return G.DateTimeManager:now() < self._npc_chat_msg_ts + G.datam.companion_ai_npc_config:get(1):get("chat_cd", 2)`
  - `"time_out": 20`
- **Why it matters:** A real automation routine must respect built-in pacing. The chat subsystem already enforces a 2-second message cooldown, which is a concrete implementation constraint.
- **Evidence Confidence:** 4/5

## 3. Conclusions

1. **Auto-chatting AI NPCs is technically scriptable.**
   - Evidence: direct RPC calls exist for starting/sending chat in `imp_npc_chat.lua`.
   - Confidence: **5/5**

2. **There is a real friendship progression split between “friend” talk and normal chat talk.**
   - Evidence: locked AI NPCs default to `CHAT_TYPE_FRIEND`, unlocked ones default to `CHAT_TYPE_CHAT`; config contains both `friend_talk_id` and `chat_talk_id`.
   - Confidence: **5/5**

3. **We now have a concrete deterministic mapping from target AI NPC to amity relation record.**
   - Evidence: `npc_companion_consts.get_npc_no(aid)` resolves the NPC number; `entity -> attr_id -> entity_attr.npc_relationship_id` resolves the amity relation ID.
   - Confidence: **5/5**

4. **Chat is concretely linked to gifting, and some friendship dialogs are explicitly configured to terminate into gift flow.**
   - Evidence: chat events/endings can open gift interactions; dialog config uses `multi_ending_wanfa_type = 1`; runtime code routes ending type `1` to `handle_chat_interact_gift`.
   - Confidence: **5/5**

5. **Amity progression appears server-authoritative, not purely client-side.**
   - Evidence: amity changes arrive as server-side notifications and unlock state is stored in avatar properties / unlock RPCs.
   - Confidence: **5/5**

6. **A practical automation path likely exists for “auto friendship progression” by driving the legitimate chat -> ending -> gift loop while monitoring relation state, but not for arbitrary client-side forced 100% completion.**
   - Evidence: RPC chat path exists; talk IDs and relation mapping are derivable; gift endings are data-configured; amity/gift systems have validation, cooldowns, and suitability checks.
   - Confidence: **5/5**

7. **The global smart companion feature gate is probably not the main blocker for implementation.**
   - Evidence: global unlock uses `unlock_id = 394`, which maps to common condition `140211`, and current visible condition data only shows `lv_limit = 1`.
   - Confidence: **4/5**

8. **The most likely implementation blocker is per-NPC progression logic and server-side suitability/limit checks, not inability to identify or address the target relation record.**
   - Evidence: relation mapping is now known, while explicit amity gift error codes and gift-state properties remain authoritative.
   - Confidence: **4/5**

## 4. Unknown / Missing Evidence

1. **Direct proof that sending chat text alone increases `npc_amity_value` was not found in current scope.**
   - The code shows chat flow and amity flow, but not the exact server handler mapping `rpc_chat_send`/`rpc_chat_ai_chat` to `npc_amity_value_change`.

2. **Exact per-NPC amity relation data tables were not directly located in current DirObject search scope.**
   - The runtime clearly uses `G.datam.npc_amity_relation_data`, but the backing JSON/object file was not located yet.

3. **Daily/weekly caps for friendship progress were not fully identified.**
   - Gift refresh timing exists in `npc_companion_consts.GIFT_REFRESH_TS`, but the exact amity gain limit logic was not located.

4. **Server rules deciding when an individual NPC becomes unlocked were not directly found.**
   - Client can request `rpc_unlock_smart_ai_npc`, but per-NPC eligibility beyond global system unlock remains unresolved in current scope.

## 5. Next Scoped Search Steps

1. Locate the backing data for:
   - `G.datam.npc_amity_relation_data`
   - `G.datam.npc_amity_level`
   - goal: inspect level thresholds, refusal levels, and any NPC-specific progression tuning.

2. Search decompiled code for the authoritative progression trigger path behind:
   - `npc_amity_value_change`
   - `npc_amity_send_gift`
   - `gifting_npc`
   - `rpc_unlock_smart_ai_npc`
   - goal: identify the real server-fed event that increments amity and flips unlock bits.

3. Build one worked example for a known AI NPC with `friend_talk_id` and `chat_talk_id`:
   - `aid -> npc_no -> relation_id -> dialog id -> gift ending`
   - goal: raise confidence enough to implement target-specific automation safely.

4. If traces become available later, trace:
   - `rpc_ai_chat_start`
   - `rpc_chat_send`
   - `npc_amity_value_change`
   - goal: prove the runtime chain from chat/gift action to amity increment.

## 4. Unknown / Missing Evidence

1. **Direct proof that sending chat text alone increases `npc_amity_value` was not found in current scope.**
   - The code shows chat flow and amity flow, but not the exact server handler mapping `rpc_chat_send`/`rpc_chat_ai_chat` to `npc_amity_value_change`.

2. **Direct mapping between AI NPC `aid` and `npc_amity_relation_id` was not found in current scope.**
   - `npc_companion_consts.get_npc_no()` maps smart AI NPC → actual NPC/entity number.
   - `amity_relation_to_entity` / `npc_amity_relation_data` are referenced in code, but matching JSON/config files were not located inside current DirObject search scope.

3. **Daily/weekly caps for friendship progress were not fully identified.**
   - Gift refresh timing exists in `npc_companion_consts.GIFT_REFRESH_TS`, but the exact amity gain limit logic was not located.

4. **Server rules deciding when an NPC becomes unlocked were not directly found.**
   - Client can request `rpc_unlock_smart_ai_npc`, but eligibility conditions beyond local checks remain unresolved in current scope.

## 5. Next Scoped Search Steps

1. Find the exact config/data backing:
   - `G.datam.npc_amity_relation_data`
   - `G.datam.amity_relation_to_entity`
   - goal: map AI NPC `aid` / `npc_no` → amity relation ID.

2. Search server/client decompiled handlers for:
   - `npc_amity_send_gift`
   - `npc_amity_value_change`
   - `rpc_unlock_smart_ai_npc`
   - goal: identify exact triggers that increment amity and exact unlock rules.

3. Inspect dialog-level / dialog-param data referenced by:
   - `friend_talk_id`
   - `chat_talk_id`
   - `ai_npc_dialog_level`
   - goal: determine whether specific friend-chat endings always branch into gift or unlock behavior.

4. If traces become available later, trace:
   - `rpc_ai_chat_start`
   - `rpc_chat_send`
   - `npc_amity_value_change`
   - goal: prove the runtime chain from chat/gift action to amity increment.

## 4. Unknown / Missing Evidence

1. **Direct proof that sending chat text alone increases `npc_amity_value` was not found in current scope.**
   - The code shows chat flow and amity flow, but not the exact server handler mapping `rpc_chat_send`/`rpc_chat_ai_chat` to `npc_amity_value_change`.

2. **Direct mapping between AI NPC `aid` and `npc_amity_relation_id` was not found in current scope.**
   - `npc_companion_consts.get_npc_no()` maps smart AI NPC → actual NPC/entity number.
   - `amity_relation_to_entity` / `npc_amity_relation_data` are referenced in code, but matching JSON/config files were not located inside current DirObject search scope.

3. **Daily/weekly caps for friendship progress were not fully identified.**
   - Gift refresh timing exists in `npc_companion_consts.GIFT_REFRESH_TS`, but the exact amity gain limit logic was not located.

4. **Server rules deciding when an NPC becomes unlocked were not directly found.**
   - Client can request `rpc_unlock_smart_ai_npc`, but eligibility conditions beyond local checks remain unresolved in current scope.

## 5. Next Scoped Search Steps

1. Find the exact config/data backing:
   - `G.datam.npc_amity_relation_data`
   - `G.datam.amity_relation_to_entity`
   - goal: map AI NPC `aid` / `npc_no` → amity relation ID.

2. Search server/client decompiled handlers for:
   - `npc_amity_send_gift`
   - `npc_amity_value_change`
   - `rpc_unlock_smart_ai_npc`
   - goal: identify exact triggers that increment amity and exact unlock rules.

3. Inspect dialog-level / dialog-param data referenced by:
   - `friend_talk_id`
   - `chat_talk_id`
   - `ai_npc_dialog_level`
   - goal: determine whether specific friend-chat endings always branch into gift or unlock behavior.

4. If traces become available later, trace:
   - `rpc_ai_chat_start`
   - `rpc_chat_send`
   - `npc_amity_value_change`
   - goal: prove the runtime chain from chat/gift action to amity increment.
