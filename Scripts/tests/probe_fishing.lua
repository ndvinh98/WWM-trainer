-- Scripts/tests/probe.lua — Fishing Probe 4: StateGamePlayFishing & sub-states
-- No boilerplate needed: probe_runner.lua handles logging setup

local function log(msg) print("[PROBE] " .. tostring(msg)) end
local function safe(fn, fallback)
    local ok, val = pcall(fn)
    if not ok then return fallback, val end
    return val, nil
end

local function dump_class_methods(cls, label, max)
    max = max or 50
    local count = 0
    log("  " .. label .. " methods:")
    pcall(function()
        for k, v in pairs(cls) do
            count = count + 1
            if count > max then
                log("    ... (truncated)")
                return
            end
            log(string.format("    .%s = %s", tostring(k), type(v)))
        end
    end)
    if count == 0 then log("    (empty)") end
    return count
end

-- ============================================================
log(">>> TEST 1: Load StateGamePlayFishing")
-- ============================================================
local base_path = "hexm.client.entities.local.player_avatar_members.states.gameplay_state"
local fishing_state_mod = safe(function()
    return require(base_path .. ".gameplay_fishing.state_gameplay_fishing")
end, nil)
log("  state_gameplay_fishing module type=" .. type(fishing_state_mod))

if fishing_state_mod then
    -- Find the class in the module
    pcall(function()
        for k, v in pairs(fishing_state_mod) do
            log(string.format("  module[%s] = %s", tostring(k), type(v)))
        end
    end)

    local StateClass = safe(function() return fishing_state_mod.StateGamePlayFishing end, nil)
    log("  StateGamePlayFishing type=" .. type(StateClass))
    if StateClass then
        dump_class_methods(StateClass, "StateGamePlayFishing")
    end
end

-- ============================================================
log(">>> TEST 2: Search for fishing sub-state files in the gameplay_fishing folder")
-- ============================================================
local sub_state_names = {
    "fishing_core", "fishing_wait", "fishing_anim",
    "fishing_game_leave", "fishing_throw",
    "fishing_hook", "fishing_drag", "fishing_play",
    "sub_state_fishing_core", "sub_state_fishing_wait",
    "state_fishing_core", "state_fishing_wait",
    "state_fishing_anim", "state_fishing_game_leave",
    "fishing_idle", "fishing_prepare",
}

for _, name in ipairs(sub_state_names) do
    local mod = safe(function()
        return require(base_path .. ".gameplay_fishing." .. name)
    end, nil)
    if mod then
        log("  FOUND: gameplay_fishing." .. name .. " type=" .. type(mod))
        pcall(function()
            for k, v in pairs(mod) do
                if type(v) == "class" or type(v) == "table" then
                    log(string.format("    [%s] = %s", tostring(k), type(v)))
                end
            end
        end)
    end
end

-- ============================================================
log(">>> TEST 3: Search package.loaded for gameplay_fishing modules")
-- ============================================================
local count = 0
for k, v in pairs(package.loaded) do
    if type(k) == "string" and k:find("gameplay_fishing") then
        count = count + 1
        log(string.format("  loaded[%s] = %s", k, type(v)))
    end
end
log("  gameplay_fishing modules in package.loaded: " .. count)

-- ============================================================
log(">>> TEST 4: Check the gameplay_sub_state base class")
-- ============================================================
local gss = safe(function()
    return require(base_path .. ".gameplay_state_base.gameplay_sub_state")
end, nil)
log("  gameplay_sub_state module type=" .. type(gss))
if gss then
    pcall(function()
        for k, v in pairs(gss) do
            log(string.format("  module[%s] = %s", tostring(k), type(v)))
            if type(v) == "class" then
                dump_class_methods(v, k, 20)
            end
        end
    end)
end

-- ============================================================
log(">>> TEST 5: Check the gameplay_state base class") 
-- ============================================================
local gs = safe(function()
    return require(base_path .. ".gameplay_state_base.gameplay_state")
end, nil)
log("  gameplay_state module type=" .. type(gs))
if gs then
    pcall(function()
        for k, v in pairs(gs) do
            log(string.format("  module[%s] = %s", tostring(k), type(v)))
            if type(v) == "class" then
                dump_class_methods(v, k, 20)
            end
        end
    end)
end

-- ============================================================
log(">>> TEST 6: Try to discover how rpc_fishing_hooked dispatches data")
-- ============================================================
-- The key question: what data does rpc_fishing_hooked pass to E_FISH_HOOK_BACK?
-- From source: self:get_local_entity().dispatcher:dispatch(event_consts.E_FISH_HOOK_BACK, data_back)
-- We need to hook rpc_fishing_hooked to see the data_back shape
-- For now, let's inspect: does fish_start_press_window do anything with fish data?

local fspw_class = safe(function()
    return require("hexm.client.ui.windows.fish.fish_start_press_window").FishStartPressWindow
end, nil)
if fspw_class then
    log("  FishStartPressWindow ctor signature: exists")
    -- Try to read the ctor
    local ctor = safe(function() return fspw_class.ctor end, nil)
    log("  ctor type=" .. type(ctor))
end

-- ============================================================
log(">>> TEST 7: Try more window patterns")
-- ============================================================
local window_patterns = {
    "hexm.client.ui.windows.fish.fish_game_pc_window",
    "hexm.client.ui.windows.fish.fish_game_mobile_window",
    "hexm.client.ui.windows.fish.fishing_prepare_side_window",
    "hexm.client.ui.windows.fish.fish_game_result_window",
    "hexm.client.ui.windows.fish.fish_game_new_result_window",
    "hexm.client.ui.windows.fish.fish_game_hud_window",
    "hexm.client.ui.windows.fish.fish_progress_window",
    "hexm.client.ui.windows.fish.fish_drag_window",
}

for _, path in ipairs(window_patterns) do
    local mod = safe(function() return require(path) end, nil)
    if mod then
        log("  FOUND: " .. path)
        pcall(function()
            for k, v in pairs(mod) do
                log(string.format("    [%s] = %s", tostring(k), type(v)))
            end
        end)
    end
end

-- Also search package.loaded for fish windows
count = 0
for k, v in pairs(package.loaded) do
    if type(k) == "string" and k:find("fish") and k:find("window") then
        count = count + 1
        log(string.format("  loaded_window[%s] = %s", k, type(v)))
    end
end
log("  fish window modules loaded: " .. count)

log(">>> PROBE 4 COMPLETE")
