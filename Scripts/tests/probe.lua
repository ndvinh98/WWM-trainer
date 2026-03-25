-- Probe: verify auto_collect_rewards API availability
-- Run: & ".venv\Scripts\python.exe" Scripts/inject/run.py probe
-- Read: Scripts/logs/probe.txt

local results = {}

-- 1. Check avatar emails access
pcall(function()
    local avatar = G.net:get_avatar()
    results.has_avatar = avatar ~= nil
    results.has_emails = avatar and avatar.emails ~= nil
    
    if avatar and avatar.emails then
        local count = 0
        local uncollected = 0
        for eid, item in pairs(avatar.emails._mails) do
            count = count + 1
            local ok, v = pcall(function()
                return item:has_reward() and not item:has_receive_reward() and item:can_receive_reward()
            end)
            if ok and v then uncollected = uncollected + 1 end
        end
        results.mail_count = count
        results.uncollected_mail = uncollected
        
        -- Check regroup_eids exists
        results.has_regroup = type(avatar.emails.regroup_eids) == "function"
        results.has_email_request = type(avatar.email_request_receive_multi_emails_reward) == "function"
    end
end)

-- 2. Check activity center access
pcall(function()
    local sgu = require("hexm.client.util.season_guide_utils")
    results.has_season_guide = sgu ~= nil
    if sgu then
        local ids = sgu.get_open_activity_ids()
        results.open_activities = ids and #ids or 0
        results.has_claim_fn = type(sgu.claim_reward_by_task_nos) == "function"
    end
end)

-- 3. Check battle pass access
pcall(function()
    local mp = G.main_player
    results.has_bp_is_reward_new = type(mp.bp_battle_pass_is_reward_new) == "function"
    results.has_bp_any_task = type(mp.bp_battle_pass_any_task_can_draw_reward) == "function"
    
    local ok1, v1 = pcall(function() return mp:bp_battle_pass_is_reward_new() end)
    results.bp_has_level_rewards = ok1 and tostring(v1) or "err: " .. tostring(v1)
    
    local ok2, v2 = pcall(function() return mp:bp_battle_pass_any_task_can_draw_reward() end)
    results.bp_claimable_task_types = ok2 and (v2 and #v2 or 0) or "err: " .. tostring(v2)
end)

-- 4. Check call_server availability
pcall(function()
    results.has_call_server = type(G.net.call_server) == "function"
end)

-- Print results
_log("=== Auto-Collect Rewards Probe ===")
for k, v in pairs(results) do
    _log(string.format("  %s = %s", k, tostring(v)))
end
_log("=== Probe Complete ===")