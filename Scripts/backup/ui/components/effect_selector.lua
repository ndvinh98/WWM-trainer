-- ============================================================
-- UI_REFACTORED/COMPONENTS/EFFECT_SELECTOR.LUA - Effect Selector
-- ============================================================
-- Refactored to use universal ItemSelector
-- ~70% smaller than original
--
-- Usage:
--   local EffectSelector = dofile("ui/components/effect_selector.lua")
--   EffectSelector.show({ on_select = function(effect) ... end })

local EffectSelector = {}

-- Reference libs via Reg
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Utils = Reg.get("Utils")

local function _log(msg)
    if Logger then
        Logger.log("[EffectSelector] " .. msg)
    end
end

-- Load dependencies
local ItemSelector = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\ui\\components\\item_selector.lua", "ItemSelector")

-- Singleton instance name
local INSTANCE_NAME = "VAR_EFFECT_SELECTOR"

-- ============================================================
-- DATA PROVIDER
-- ============================================================

function EffectSelector.load_effects()
    local effect_list = {}
    local Effects = nil

    -- Try loading Effects module
    pcall(
        function()
            Effects = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\actions\\effects.lua", "Effects")
        end
    )

    if Effects and Effects.get_effect_list then
        local list_data = Effects.get_effect_list()
        if list_data and #list_data > 0 then
            _log("Loaded " .. #list_data .. " effects via Effects module")
            return list_data, Effects
        end
    end

    _log("WARNING: No effect data found")
    return {}, Effects
end

-- ============================================================
-- SHOW SELECTOR
-- ============================================================

function EffectSelector.show(config)
    config = config or {}

    -- Load effect data
    local effects, Effects = EffectSelector.load_effects()

    -- Use universal ItemSelector
    return ItemSelector.show(
        {
            title = "Effect Selector",
            items = effects,
            get_display_name = function(effect)
                return effect.name or "Unknown"
            end,
            get_id = function(effect)
                return effect.effect_id or effect.id
            end,
            on_apply = function(effect)
                return true -- Caller handles application
            end,
            on_select = function(effect, success)
                if config.on_select then
                    config.on_select(effect, success, Effects)
                end
            end,
            on_close = config.on_close,
            instance_name = INSTANCE_NAME,
            enable_search = true,
            empty_message = "No effects available"
        }
    )
end

-- ============================================================
-- CLOSE SELECTOR
-- ============================================================

function EffectSelector.close()
    ItemSelector.close(INSTANCE_NAME)
end

return EffectSelector
