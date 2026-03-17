-- ============================================================
-- UI_REFACTORED/COMPONENTS/SUIT_SELECTOR.LUA - Suit Selector
-- ============================================================
-- Refactored to use universal ItemSelector
-- ~70% smaller than original (120 LOC vs 400+ LOC)
--
-- Usage:
--   local SuitSelector = dofile("ui/components/suit_selector.lua")
--   SuitSelector.show({ on_select = function(suit) ... end })

local SuitSelector = {}

-- Reference libs via Reg
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Utils = Reg.get("Utils")

local function _log(msg)
    if Logger then
        Logger.log("[SuitSelector] " .. msg)
    end
end

-- Load dependencies
local ItemSelector = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\ui\\components\\item_selector.lua", "ItemSelector")

-- Singleton instance name
local INSTANCE_NAME = "VAR_SUIT_SELECTOR"

-- State for persistent selection
local STATE_NAME = "SUIT_SELECTION_STATE"
if not Reg.has(STATE_NAME) then
    Reg.set(STATE_NAME, {suit_no = nil})
end

-- ============================================================
-- DATA PROVIDER
-- ============================================================

--[[
    Load suit data from SuitSkins module

    @return suits, data_module - Array of suits and the data module reference
]]
function SuitSelector.load_suits()
    local SuitSkins = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\actions\\suit_skins.lua", "SuitSkins")
    if not SuitSkins then
        _log("WARNING: SuitSkins action not loaded")
        return {}, nil
    end

    local suit_list = SuitSkins.get_suit_list()
    if suit_list and #suit_list > 0 then
        _log("Loaded " .. #suit_list .. " suits")
        return suit_list, SuitSkins
    end

    _log("WARNING: No suit data found")
    return {}, SuitSkins
end

-- ============================================================
-- SHOW SELECTOR
-- ============================================================

--[[
    Show suit selector dialog

    @param config - Configuration table:
        - on_select: function(suit, success, data_module) - Called after selection
        - on_close: function() - Called when dialog closed

    @return selector_api
]]
function SuitSelector.show(config)
    config = config or {}

    -- Load suit data
    local suits, SuitSkins = SuitSelector.load_suits()

    -- Use universal ItemSelector
    return ItemSelector.show(
        {
            title = "Suit Selector",
            items = suits,
            get_display_name = function(suit)
                return suit.name or "Unknown"
            end,
            get_id = function(suit)
                return suit.suit_no
            end,
            on_apply = function(suit)
                if not SuitSkins then return false end
                -- Disable prior hooks before applying new suit
                if SuitSkins.is_enabled and SuitSkins.is_enabled() then
                    SuitSkins.disable()
                end
                local ok, err = SuitSkins.apply(suit.suit_no)
                if not ok then
                    _log("Failed to apply suit " .. tostring(suit.suit_no) .. ": " .. tostring(err))
                end
                return ok
            end,
            on_select = function(suit, success)
                -- Save to persistent state
                local state = Reg.get(STATE_NAME)
                state.suit_no = suit.suit_no

                if config.on_select then
                    config.on_select(suit, success, SuitSkins)
                end
            end,
            on_close = config.on_close,
            instance_name = INSTANCE_NAME,
            enable_search = true, -- Enable search functionality
            empty_message = "No suits available",
            empty_hint = "G.datam.guise_suit_config may not be loaded yet"
        }
    )
end

-- ============================================================
-- CLOSE SELECTOR
-- ============================================================

function SuitSelector.close()
    ItemSelector.close(INSTANCE_NAME)
end

return SuitSelector
