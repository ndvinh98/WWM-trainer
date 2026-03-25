-- Scripts/tests/probe.lua — scratch file
-- Probe: try bait controller approach + bait change while in fish state

local function log(msg) print("[PROBE] " .. tostring(msg)) end
local function safe(fn, fallback)
    local ok, val = pcall(fn)
    if not ok then return fallback, val end
    return val, nil
end

log(">>> 1: Get ALL stuff_nos from bait controller")
local bait_ctrl_mod = safe(function()
    return portable.safe_import("hexm.client.ui.windows.skill_v2.icon_controllers.pc.pc_fishing_choose_bait_controller")
end, nil)
if bait_ctrl_mod and bait_ctrl_mod.PcFishingChooseBaitController then
    local cls = bait_ctrl_mod.PcFishingChooseBaitController
    -- Check if _get_all_stuff_nos is a static method or needs instance
    log("  _get_all_stuff_nos type=" .. type(cls._get_all_stuff_nos))
    -- Try calling it (might need self)
    local ok1, r1 = pcall(function() return cls:_get_all_stuff_nos() end)
    log("  cls:_get_all_stuff_nos(): ok=" .. tostring(ok1) .. " result=" .. tostring(r1))
    local ok2, r2 = pcall(function() return cls._get_all_stuff_nos() end)
    log("  cls._get_all_stuff_nos(): ok=" .. tostring(ok2) .. " result=" .. tostring(r2))
end

log(">>> 2: Direct bait set via server entity property")
local se = safe(function() return G.net:get_avatar() end, nil)
if se then
    local curr = safe(function() return se:get_fish_choose_bait_no() end, nil)
    log("  current bait_no=" .. tostring(curr))

    -- Check if there's a set method on fishing property
    pcall(function()
        for k, v in next, se do
            local ks = tostring(k)
            if ks:lower():find("bait") then
                log(string.format("  se.%s = %s [%s]", ks, tostring(v), type(v)))
            end
        end
    end)

    -- Try direct property set
    local target = (curr == 102024) and 102023 or 102024
    log("  Trying to set bait to " .. target)

    -- Maybe fish_bait is a property we can set
    local ok3, err3 = pcall(function()
        se.choose_bait_no = target
    end)
    log("  se.choose_bait_no=" .. target .. ": ok=" .. tostring(ok3) .. " err=" .. tostring(err3))

    local ok4, err4 = pcall(function()
        se.fish_choose_bait_no = target
    end)
    log("  se.fish_choose_bait_no=" .. target .. ": ok=" .. tostring(ok4) .. " err=" .. tostring(err4))

    -- Check after
    local after = safe(function() return se:get_fish_choose_bait_no() end, nil)
    log("  AFTER bait_no=" .. tostring(after))
end

log(">>> 3: Search for 'choose_bait' in imp_fishing decompiled code method list")
local imp_fishing = safe(function()
    return portable.safe_import("hexm.client.entities.local.player_avatar_members.gameplays.imp_fishing")
end, nil)
if imp_fishing then
    pcall(function()
        for k, v in next, imp_fishing do
            if type(v) == "function" and type(k) == "string" then
                local kl = k:lower()
                if kl:find("bait") or kl:find("choose") then
                    log("  imp_fishing." .. k .. " [function]")
                end
            end
        end
    end)
end

log(">>> 4: Check server avatar (se.server) for set_* bait methods")
if se and se.server then
    -- Enumerate ALL methods with 'bait' or 'choose' or 'fish_choose'
    local methods_found = {}
    pcall(function()
        -- Check direct
        for k, v in next, se.server do
            if type(k) == "string" then
                local kl = k:lower()
                if kl:find("bait") or kl:find("choose") then
                    methods_found[#methods_found+1] = k .. " [" .. type(v) .. "]"
                end
            end
        end
    end)
    -- Also check metatable chain
    pcall(function()
        local obj = se.server
        local visited = {}
        for d = 0, 5 do
            local mt = getmetatable(obj)
            if not mt then break end
            if visited[tostring(mt)] then break end
            visited[tostring(mt)] = true
            local idx = mt.__index
            if type(idx) == "table" then
                for k, v in next, idx do
                    if type(k) == "string" then
                        local kl = k:lower()
                        if kl:find("bait") or kl:find("choose") then
                            methods_found[#methods_found+1] = k .. " [" .. type(v) .. "] d=" .. d
                        end
                    end
                end
                obj = idx
            else
                break
            end
        end
    end)
    for _, m in ipairs(methods_found) do
        log("  se.server." .. m)
    end
end

log(">>> 5: Test the start_fishing_game_btn_end approach — bait_no comes from get_fish_choose_bait_no()")
-- The bait is sent with the throw in start_fishing_game_btn_end
-- So we need to change what get_fish_choose_bait_no() returns
-- Maybe we can hook it!
log("  Idea: hook se:get_fish_choose_bait_no() to return the best bait")

log(">>> PROBE COMPLETE")