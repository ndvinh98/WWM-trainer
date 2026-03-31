-- Probe: Lowest-level freeze solve — storyline process event or direct server RPC
local function log(msg) print("[PROBE] " .. tostring(msg)) end
local ClassUtils = require("common.classutils")

local mp = G.main_player
local event_consts = require("hexm.client.consts.event_consts")

local game_ids = mp:get_all_running_region_game_id_by_type(10)
if not game_ids or #game_ids == 0 then
    log("No active freeze game")
    return
end
local game_id = game_ids[1]
log("game_id=" .. tostring(game_id))

-- Check initial state
log("Games running BEFORE: " .. tostring(#game_ids))

-- ── APPROACH 1: Direct server RPC ──
log(">>> APPROACH 1: region_game_process_notify_server")
local ok1, err1 = pcall(function()
    local avatar = G.net:get_avatar()
    log("  avatar=" .. tostring(avatar) .. " type=" .. type(avatar))
    log("  has method=" .. tostring(avatar.region_game_process_notify_server ~= nil))

    -- Try with CustomMapType (server RPC expects dict)
    local data = ClassUtils.CustomMapType({ event = "completed" })
    avatar:region_game_process_notify_server(game_id, data)
    log("  RPC sent with CustomMapType")
end)
log("  ok=" .. tostring(ok1) .. " err=" .. tostring(err1))

-- Check if game ended
pcall(function()
    local still = mp:get_all_running_region_game_id_by_type(10)
    log("  Games running AFTER RPC: " .. tostring(still and #still or 0))
end)

-- If still running, try plain table
if ok1 then
    pcall(function()
        local still = mp:get_all_running_region_game_id_by_type(10)
        if still and #still > 0 then
            log(">>> Retry with to_valid_dict()")
            local data2 = ClassUtils.CustomMapType({ event = "completed" }):to_valid_dict()
            log("  data2 type=" .. type(data2))
            G.net:get_avatar():region_game_process_notify_server(game_id, data2)
        end
    end)
end

-- ── APPROACH 2: Dispatch storyline process event ──
log(">>> APPROACH 2: E_REGION_GAME_STORYLINE_PROCESS dispatch")
pcall(function()
    local still = mp:get_all_running_region_game_id_by_type(10)
    if still and #still > 0 then
        local E = event_consts.E_REGION_GAME_STORYLINE_PROCESS
        log("  E_REGION_GAME_STORYLINE_PROCESS=" .. tostring(E))

        -- Create data as CustomMapType (has :get method)
        local kwargs = ClassUtils.CustomMapType({ event = "completed" })
        local data = ClassUtils.CustomMapType({
            game_id = game_id,
            kwargs = kwargs,
        })
        mp.dispatcher:dispatch(E, data)
        log("  Dispatched with CustomMapType")
    end
end)

pcall(function()
    local still = mp:get_all_running_region_game_id_by_type(10)
    log("  Games running AFTER dispatch: " .. tostring(still and #still or 0))
end)

log(">>> PROBE COMPLETE")
