-- Probe: Check GUIHUO detection using correct APIs
local function log(msg) print("[PROBE] " .. tostring(msg)) end
local function safe(fn, fallback)
    local ok, val = pcall(fn)
    return ok and val or fallback
end

local mp = G.main_player

log(">>> TEST 1: _curr_region_game")
local crg = safe(function() return mp._curr_region_game end, nil)
log("  type=" .. type(crg))
if crg then
    local count = 0
    pcall(function()
        for game_id, game_obj in pairs(crg) do
            count = count + 1
            local gt = safe(function()
                local cfg = G.datam.region_game_config:get(game_id, {})
                return cfg.type
            end, "?")
            local cls = safe(function() return game_obj.__cname__ end, "?")
            local server_loaded = safe(function() return game_obj.server_loaded end, "?")
            log(string.format("  id=%s type=%s class=%s server_loaded=%s", tostring(game_id), tostring(gt), tostring(cls), tostring(server_loaded)))
        end
    end)
    log("  total active=" .. count)
end

log(">>> TEST 2: get_all_running_region_game_id_by_type(8)")
local type8_ids = safe(function()
    return mp:get_all_running_region_game_id_by_type(8)
end, nil)
log("  result type=" .. type(type8_ids))
if type8_ids then
    pcall(function()
        for i, gid in pairs(type8_ids) do
            log("  found game_id=" .. tostring(gid))
        end
    end)
end

log(">>> TEST 3: Nearby type-8 from config (datam)")
local player_pos = safe(function() return mp:get_position() end, nil)
log("  player_pos=" .. tostring(player_pos))
pcall(function()
    for game_id, cfg in pairs(G.datam.region_game_config) do
        local gt = cfg.type
        if gt == 8 then
            local pos = cfg.position
            if pos and player_pos then
                local dx = player_pos.x - pos[1]
                local dy = player_pos.y - pos[2]
                local dz = player_pos.z - pos[3]
                local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                if dist < 50 then
                    log(string.format("  NEARBY game_id=%s dist=%.1f", tostring(game_id), dist))
                    -- Check if it's in _curr_region_game
                    local in_curr = safe(function() return crg:contains(game_id) end, false)
                    log("    in _curr_region_game=" .. tostring(in_curr))
                    -- Try to get custom config
                    local custom_cfg = safe(function()
                        return mp:get_region_game_custom_config(game_id)
                    end, nil)
                    log("    custom_config type=" .. type(custom_cfg))
                    if custom_cfg then
                        local ghost_list = safe(function()
                            return custom_cfg:get("t_ghostfire_no_list")
                        end, nil)
                        log("    t_ghostfire_no_list=" .. tostring(ghost_list))
                        if ghost_list then
                            pcall(function()
                                for idx, sid in pairs(ghost_list) do
                                    local entity = safe(function() return G.space:get_entity_by_serial_no(sid) end, nil)
                                    local epos = entity and safe(function() return entity:get_position() end, nil)
                                    log(string.format("      sid=%s entity=%s pos=%s", tostring(sid), tostring(entity ~= nil), tostring(epos)))
                                end
                            end)
                        end
                    end
                end
            end
        end
    end
end)
