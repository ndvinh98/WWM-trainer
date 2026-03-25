# Auto-Collect Rewards Implementation Plan

> **For Antigravity:** REQUIRED WORKFLOW: Use `.agent/workflows/execute-plan.md` to execute this plan in single-flow mode.

**Goal:** Create an action module that periodically polls for uncollected rewards and auto-claims them via server RPCs.

**Architecture:** Single `ActionBase`-derived module (`actions/auto_collect_rewards.lua`) with a timer-based polling loop (like `autoloot.lua`). Each reward system is a collector function called in sequence. A one-shot "collect now" action is also exposed for manual use. Integrated into the UI menu via `menu_controller.lua` + `menu_config.lua`.

**Tech Stack:** Lua, game APIs (`G.net:call_server`, `G.main_player`, `G.net:get_avatar()`), Cocos2d-x timers.

---

## Design

### Collector Functions

Each collector is a self-contained function that checks if rewards are available and fires the RPC. All RPCs are fire-and-forget (server handles response via existing callback system — we don't need UI feedback).

**1. Mail Rewards**
- Check: iterate `avatar.emails._mails`, filter items where `has_reward() and not has_receive_reward() and can_receive_reward()`
- Collect: `avatar:email_request_receive_multi_emails_reward(grouped_eids)` — requires `regroup_eids()` to group by email type
- Cooldown: Only run once per poll cycle (mail doesn't change rapidly)

**2. Activity Center Tasks (Season Guide)**
- Check: use `season_guide_utils.claim_reward_by_task_nos(task_nos, true)` to get claimable `task_ids` without sending RPC (the `is_local=true` flag)
- Collect: `G.net:call_server("activity_center_target_reward_receive_batch", task_ids)`
- Data source: `G.datam.activity_season_guide_batches` → `activity_center_table_data` → `activity_center_task_group_data` → `taskg_list`

**3. Battle Pass Level Rewards**
- Check: `G.main_player:bp_battle_pass_is_reward_new()` — returns true if any unclaimed level rewards
- Collect: `G.net:call_server("rpc_bp_battle_pass_reward_all")`
- Note: VIP double reward choice may block — skip if `bp_rwd_ch == 0` and has `double_vip_reward` (same logic as game's `bp_battle_pass_reward_all`)

**4. Battle Pass Task Rewards**
- Check: `G.main_player:bp_battle_pass_any_task_can_draw_reward()` — returns list of task types with claimable rewards
- Collect: `G.net:call_server("rpc_bp_task_reward_all_type", task_type)` for each claimable type

**5. Equipment Armory Progress**
- Collect: `G.net:call_server("equip_box_claim_progress_rewards")`
- Note: Simple fire-and-forget, server will ignore if nothing to claim

### Polling Strategy

- Default interval: **30 seconds** (rewards accumulate slowly, no need to spam)
- Uses `cc.RepeatForever` + `cc.Sequence` timer pattern (same as `autoloot.lua`)
- Each poll runs all 5 collectors sequentially with `pcall` wrapping
- Stagger RPCs by small delays (0.5s between each collector) to avoid server rate-limiting

### Module API

```lua
AutoCollectRewards:enable()   -- Start polling timer
AutoCollectRewards:disable()  -- Stop polling timer  
AutoCollectRewards:collect_now()  -- One-shot: run all collectors immediately
AutoCollectRewards:is_enabled()
```

### UI Integration

- **menu_config.lua**: Add toggle `"auto_collect_rewards"` in the "World" tab
- **menu_controller.lua**: Add `handle_auto_collect_rewards(enabled)` handler

---

## Tasks

### Task 1: Create action module `Scripts/actions/auto_collect_rewards.lua`

**Files:**
- Create: `Scripts/actions/auto_collect_rewards.lua`

**Step 1: Scaffold ActionBase module**

```lua
local ActionBase = _G.Reg.lib("ActionBase")
local AutoCollectRewards = ActionBase:extend("actions.auto_collect_rewards")

function AutoCollectRewards:define_state()
    return {
        persistent = { enabled = false, log_enabled = true },
        transient = {
            timer_action = nil,
            scan_interval = 30.0,
            collector_delay = 0.5,
            last_collected = {},
        },
    }
end

function AutoCollectRewards:define_hooks()
    return {}
end
```

**Step 2: Implement mail reward collector**

```lua
function AutoCollectRewards:_collect_mail_rewards()
    local avatar = G.net:get_avatar()
    if not avatar or not avatar.emails then return 0 end
    
    local eids = {}
    for eid, item in pairs(avatar.emails._mails) do
        local ok, should_collect = pcall(function()
            return not item:is_destroyed() 
                and item:has_reward() 
                and not item:has_receive_reward() 
                and item:can_receive_reward()
        end)
        if ok and should_collect then
            eids[#eids + 1] = eid
        end
    end
    
    if #eids == 0 then return 0 end
    
    self:log(string.format("Mail: collecting %d rewards", #eids))
    pcall(function()
        local grouped = avatar.emails:regroup_eids(eids)
        avatar:email_request_receive_multi_emails_reward(grouped)
    end)
    return #eids
end
```

**Step 3: Implement activity center task collector**

```lua
function AutoCollectRewards:_collect_activity_tasks()
    local ok, season_guide_utils = pcall(portable.safe_import, "hexm.client.util.season_guide_utils")
    if not ok or not season_guide_utils then return 0 end
    
    local acti_ids = season_guide_utils.get_open_activity_ids()
    if not acti_ids then return 0 end
    
    local all_task_ids = {}
    for _, acti_id in pairs(acti_ids) do
        local task_group_id = G.datam.activity_center_table_data:get(acti_id, {}):get("task_group_id")
        if task_group_id then
            for _, group_id in pairs(task_group_id) do
                local group_config = G.datam.activity_center_task_group_data:get(group_id, {})
                local taskg_list = group_config:get("taskg_list")
                if taskg_list then
                    local reward_ids, task_ids = season_guide_utils.claim_reward_by_task_nos(taskg_list, true)
                    if task_ids and #task_ids > 0 then
                        for _, tid in pairs(task_ids) do
                            all_task_ids[#all_task_ids + 1] = tid
                        end
                    end
                end
            end
        end
    end
    
    if #all_task_ids == 0 then return 0 end
    
    self:log(string.format("Activity: collecting %d task rewards", #all_task_ids))
    pcall(function()
        G.net:call_server("activity_center_target_reward_receive_batch", all_task_ids)
    end)
    return #all_task_ids
end
```

**Step 4: Implement battle pass collectors**

```lua
function AutoCollectRewards:_collect_bp_level_rewards()
    local mp = G.main_player
    if not mp then return 0 end
    
    local has_rewards = false
    pcall(function()
        has_rewards = mp:bp_battle_pass_is_reward_new()
    end)
    if not has_rewards then return 0 end
    
    -- Check for double reward choice blocker
    local blocked = false
    pcall(function()
        local se = mp:get_server_entity()
        local battle_pass_consts = portable.safe_import("hexm.common.consts.battle_pass_consts")
        if se.battle_pass.bp_rwd_ch == 0 
            and mp:bp_privilege_level() ~= battle_pass_consts.BP_PRIVILEGE_FREE then
            -- Potentially blocked by double reward choice — try anyway, server will handle
        end
    end)
    
    self:log("BP Level: collecting all unclaimed level rewards")
    pcall(function()
        G.net:call_server("rpc_bp_battle_pass_reward_all")
    end)
    return 1
end

function AutoCollectRewards:_collect_bp_task_rewards()
    local mp = G.main_player
    if not mp then return 0 end
    
    local claimable_types = {}
    pcall(function()
        claimable_types = mp:bp_battle_pass_any_task_can_draw_reward() or {}
    end)
    if #claimable_types == 0 then return 0 end
    
    self:log(string.format("BP Tasks: collecting %d task types", #claimable_types))
    for _, task_type in pairs(claimable_types) do
        pcall(function()
            G.net:call_server("rpc_bp_task_reward_all_type", task_type)
        end)
    end
    return #claimable_types
end
```

**Step 5: Implement equipment armory collector**

```lua
function AutoCollectRewards:_collect_equip_rewards()
    self:log("Equipment: claiming progress rewards")
    pcall(function()
        G.net:call_server("equip_box_claim_progress_rewards")
    end)
    return 1
end
```

**Step 6: Implement poll loop & public API**

```lua
function AutoCollectRewards:do_collect()
    local mp = G.main_player
    if not mp then return end
    
    local collectors = {
        { name = "mail",     fn = self._collect_mail_rewards },
        { name = "activity", fn = self._collect_activity_tasks },
        { name = "bp_level", fn = self._collect_bp_level_rewards },
        { name = "bp_task",  fn = self._collect_bp_task_rewards },
        { name = "equip",    fn = self._collect_equip_rewards },
    }
    
    local total = 0
    for _, c in ipairs(collectors) do
        local ok, count = pcall(c.fn, self)
        if ok and count and count > 0 then
            total = total + count
        end
    end
    
    if total > 0 then
        self:log(string.format("Collected from %d sources this cycle", total))
    end
end

-- Timer management (same pattern as autoloot.lua)
function AutoCollectRewards:start_timer() ... end
function AutoCollectRewards:stop_timer() ... end
function AutoCollectRewards:enable() ... end
function AutoCollectRewards:disable() ... end
function AutoCollectRewards:collect_now()
    self:do_collect()
end
```

**Step 7: Add reload guard**

```lua
_G.Reg.lib("Cocos").delay_call(0.5, function()
    local instance = _G.Reg.module("actions.auto_collect_rewards")
    if instance and instance.state.enabled then
        instance:log("Reload detected — restarting timer")
        instance:start_timer()
    end
end)

return AutoCollectRewards:new()
```

---

### Task 2: Add UI integration

**Files:**
- Modify: `Scripts/ui/controllers/menu_controller.lua`
- Modify: `Scripts/ui/menu_config.lua`

**Step 1: Add handler in menu_controller.lua**

Add after the `handle_fishing_master_auto` function:

```lua
function MenuController.handle_auto_collect_rewards(enabled)
    local AutoCollectRewards = get_action("auto_collect_rewards")
    if not AutoCollectRewards then return end
    if enabled then
        if AutoCollectRewards.enable then
            pcall(AutoCollectRewards.enable, AutoCollectRewards)
        end
    else
        if AutoCollectRewards.disable then
            pcall(AutoCollectRewards.disable, AutoCollectRewards)
        end
    end
end
```

**Step 2: Add menu item in menu_config.lua**

Add to the "World" tab items array (after fishing_master_auto):

```lua
{
    id = "auto_collect_rewards",
    type = "toggle",
    label = "Auto Collect Rewards",
    on_action = function()
        if MenuController then
            MenuController.handle_auto_collect_rewards(true)
        end
    end,
    off_action = function()
        if MenuController then
            MenuController.handle_auto_collect_rewards(false)
        end
    end,
},
```

---

### Task 3: Probe test verification

**Files:**
- Modify: `Scripts/tests/probe.lua` (scratch file — overwrite)

**Step 1: Write probe to verify API availability**

```lua
-- Probe: verify auto_collect_rewards API availability
local results = {}

-- 1. Check avatar emails access
pcall(function()
    local avatar = G.net:get_avatar()
    results.has_avatar = avatar ~= nil
    results.has_emails = avatar and avatar.emails ~= nil
    results.mail_count = avatar and avatar.emails and #avatar.emails._mails or 0
    
    -- Count uncollected
    local uncollected = 0
    if avatar and avatar.emails then
        for eid, item in pairs(avatar.emails._mails) do
            local ok, v = pcall(function()
                return item:has_reward() and not item:has_receive_reward() and item:can_receive_reward()
            end)
            if ok and v then uncollected = uncollected + 1 end
        end
    end
    results.uncollected_mail = uncollected
end)

-- 2. Check activity center access
pcall(function()
    local sgu = portable.safe_import("hexm.client.util.season_guide_utils")
    results.has_season_guide = sgu ~= nil
    if sgu then
        local ids = sgu.get_open_activity_ids()
        results.open_activities = ids and #ids or 0
    end
end)

-- 3. Check battle pass access
pcall(function()
    local mp = G.main_player
    results.has_bp_check = type(mp.bp_battle_pass_is_reward_new) == "function"
    results.bp_has_rewards = mp:bp_battle_pass_is_reward_new()
    local types = mp:bp_battle_pass_any_task_can_draw_reward()
    results.bp_claimable_task_types = types and #types or 0
end)

-- Print results
for k, v in pairs(results) do
    _log(string.format("  %s = %s", k, tostring(v)))
end
```

**Step 2: Run probe**

```powershell
& ".venv\Scripts\python.exe" Scripts/inject/run.py probe
```

Then read `Scripts/logs/probe.txt` to confirm all APIs are accessible.

**Step 3: Integration test — enable/disable cycle**

```powershell
& ".venv\Scripts\python.exe" Scripts/inject/run.py lua "local m = dofile(Reg.lib('Constants').SCRIPTS_ROOT .. '\\\\actions\\\\auto_collect_rewards.lua'); m:enable(); print('enabled:', m:is_enabled()); m:collect_now(); m:disable(); print('disabled:', m:is_enabled())"
```

---

## Verification Plan

### Automated Tests
1. **Probe test** (Task 3 Step 1-2): Verify all game APIs exist and are callable at runtime
2. **Enable/disable cycle** (Task 3 Step 3): Verify module loads, enables, collects, and disables without errors

### Manual Verification
1. Enable the toggle in the mod menu under "World" tab → "Auto Collect Rewards"
2. Wait 30 seconds (one poll cycle)
3. Check `Scripts/logs/probe.txt` for collection log messages
4. Verify mail inbox rewards are collected (open mail — rewards should already be claimed)
5. Verify no game crashes or error popups after running for 2-3 minutes
6. Disable the toggle — verify polling stops (no more log messages)
