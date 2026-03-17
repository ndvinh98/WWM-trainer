-- ============================================================
-- UI/COMPONENTS/XINFA_SELECTOR.LUA - Xinfa Passive Buff Selector
-- ============================================================
-- Uses universal ItemSelector to show xinfa list with buff info.
-- Follows same pattern as suit_selector.lua.
--
-- Usage:
--   local XinfaSelector = dofile("ui/components/xinfa_selector.lua")
--   XinfaSelector.show({ on_select = function(xinfa, success, data_module) ... end })

local XinfaSelector = {}

-- Reference libs via Reg
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Utils = Reg.get("Utils")

local function _log(msg)
    if Logger then
        Logger.log("[XinfaSelector] " .. msg)
    end
end

-- Load dependencies
local ItemSelector = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\ui\\components\\item_selector.lua", "ItemSelector")

-- Singleton instance name
local INSTANCE_NAME = "VAR_XINFA_SELECTOR"

-- Star labels for display
local STAR_LABELS = {
    [1] = "[*]",
    [2] = "[**]",
    [3] = "[***]",
    [4] = "[****]",
    [5] = "[*****]",
}

-- ============================================================
-- DATA PROVIDER
-- ============================================================

function XinfaSelector.load_xinfa()
    local XinfaBuffs = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\actions\\xinfa_buffs.lua", "XinfaBuffs")
    if not XinfaBuffs then
        _log("WARNING: XinfaBuffs action not loaded")
        return {}, nil
    end

    local xinfa_list = XinfaBuffs.get_list()
    if xinfa_list and #xinfa_list > 0 then
        _log("Loaded " .. #xinfa_list .. " xinfa entries")
        return xinfa_list, XinfaBuffs
    end

    _log("WARNING: No xinfa data found")
    return {}, XinfaBuffs
end

-- ============================================================
-- SHOW SELECTOR
-- ============================================================

function XinfaSelector.show(config)
    config = config or {}

    local xinfa_list, XinfaBuffs = XinfaSelector.load_xinfa()

    return ItemSelector.show(
        {
            title = "Xinfa Passive Buffs",
            items = xinfa_list,
            get_display_name = function(xinfa)
                local star = STAR_LABELS[xinfa.star] or ""
                local buffs = xinfa.buff_count or 0
                return string.format("%s %s (%d buffs)", star, xinfa.name or "Unknown", buffs)
            end,
            get_id = function(xinfa)
                return xinfa.xinfa_id
            end,
            on_apply = function(xinfa)
                if not XinfaBuffs then return false end
                local ok, applied, total = XinfaBuffs.apply(xinfa.xinfa_id)
                if ok then
                    _log(string.format("Applied %s: %d/%d buffs", xinfa.name, applied or 0, total or 0))
                else
                    _log("Failed to apply xinfa " .. tostring(xinfa.xinfa_id) .. ": " .. tostring(applied))
                end
                return ok
            end,
            on_select = function(xinfa, success)
                if config.on_select then
                    config.on_select(xinfa, success, XinfaBuffs)
                end
            end,
            on_close = function()
                if config.on_close then
                    config.on_close()
                end
            end,
            instance_name = INSTANCE_NAME,
            enable_search = true,
            status_hint = "Click to apply passive buffs",
            empty_message = "No xinfa with passive buffs found",
            empty_hint = "G.datam.xinfa / passive_skills may not be loaded yet"
        }
    )
end

-- ============================================================
-- CLOSE SELECTOR
-- ============================================================

function XinfaSelector.close()
    ItemSelector.close(INSTANCE_NAME)
end

return XinfaSelector
