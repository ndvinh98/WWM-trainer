-- ============================================================
-- UI_REFACTORED/COMPONENTS/DUAL_EFFECT_SELECTOR.LUA - Dual Effect Selector
-- ============================================================
-- Refactored to use universal DualSelector
-- Allows selecting two effects (left hand + right hand)
--
-- Usage:
--   local DualEffectSelector = dofile("ui/components/dual_effect_selector.lua")
--   DualEffectSelector.show({ on_select = function(left, right) ... end })

local DualEffectSelector = {}

-- Reference libs via Reg
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Utils = Reg.get("Utils")

-- Load centralized logging config
local LogConfig = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\ui\\log_config.lua", "LogConfig")

local function _log(msg)
    if LogConfig then
        LogConfig.log("DualEffectSelector", msg)
    end
end

-- Load dependencies
_log("Loading DualSelector from: " .. Constants.SCRIPTS_ROOT .. "\\ui\\components\\dual_selector.lua")
local DualSelector, load_err =
    Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\ui\\components\\dual_selector.lua", "DualSelector")

if not DualSelector then
    _log("ERROR: Failed to load DualSelector module: " .. tostring(load_err))
else
    _log("✓ DualSelector loaded successfully")
end

-- Singleton instance name
local INSTANCE_NAME = "VAR_DUAL_EFFECT_SELECTOR"

-- ============================================================
-- DATA PROVIDER
-- ============================================================

function DualEffectSelector.load_effects()
    local Effects = nil

    -- Try loading Effects module
    pcall(
        function()
            Effects = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\actions\\effects.lua", "Effects")
        end
    )

    if not Effects then
        _log("ERROR: Could not load Effects module")
        return nil, {}, {}, {}
    end

    -- Get player's kungfu IDs
    local mp = Utils.get_main_player()
    local kungfu_ids = {}

    if mp then
        -- Get primary kungfu (active/main)
        pcall(
            function()
                if mp.enchant_get_kongfu_id then
                    local primary = mp:enchant_get_kongfu_id()
                    if primary then
                        kungfu_ids[#kungfu_ids + 1] = primary
                        _log("Primary kungfu: " .. primary)
                    end
                end
            end
        )

        -- Get secondary kungfu (sub/inactive)
        pcall(
            function()
                if mp.get_sub_kongfu then
                    local secondary = mp:get_sub_kongfu()
                    if secondary then
                        kungfu_ids[#kungfu_ids + 1] = secondary
                        _log("Secondary kungfu: " .. secondary)
                    end
                end
            end
        )
    end

    -- Get effect lists for each kungfu (let the module handle filtering)
    local main_effects = Effects.get_effect_list(kungfu_ids[1])
    local secondary_effects = Effects.get_effect_list(kungfu_ids[2])

    _log("Loaded " .. #main_effects .. " main effects, " .. #secondary_effects .. " secondary effects")
    _log("Kungfu IDs: " .. table.concat(kungfu_ids, ", "))

    return Effects, main_effects, secondary_effects, kungfu_ids
end

-- ============================================================
-- SHOW SELECTOR
-- ============================================================

function DualEffectSelector.show(config)
    config = config or {}

    -- Load effect data with correct filtering
    local Effects, main_effects, secondary_effects, kungfu_ids = DualEffectSelector.load_effects()

    if not Effects then
        _log("ERROR: Could not load effect data")
        return nil
    end
    -- Use universal DualSelector with separate lists for each kungfu
    local ok, err =
        pcall(
        function()
            DualSelector.show(
                {
                    title = "Dual Effect Selector",
                    left = {
                        title = "Main Weapon Effects" ..
                            (kungfu_ids[1] and (" (Kungfu: " .. kungfu_ids[1] .. ")") or ""),
                        items = main_effects,
                        get_display_name = function(effect)
                            return (effect.name or "Unknown") .. " [" .. effect.effect_id .. "]"
                        end,
                        get_id = function(effect)
                            return effect.effect_id or effect.id
                        end,
                        empty_message = "No effects available"
                    },
                    right = {
                        title = "Secondary Weapon Effects" ..
                            (kungfu_ids[2] and (" (Kungfu: " .. kungfu_ids[2] .. ")") or ""),
                        items = secondary_effects,
                        get_display_name = function(effect)
                            return (effect.name or "Unknown") .. " [" .. effect.effect_id .. "]"
                        end,
                        get_id = function(effect)
                            return effect.effect_id or effect.id
                        end,
                        empty_message = "No effects available"
                    },
                    on_apply = function(left_effect, right_effect)
                        -- Disable prior hooks before applying
                        if Effects.is_enabled and Effects.is_enabled() then
                            Effects.disable()
                        end

                        local main_success = false
                        if left_effect and kungfu_ids[1] then
                            _log(
                                "Applying main effect: kungfu " ..
                                    kungfu_ids[1] .. " -> effect " .. left_effect.effect_id
                            )
                            main_success = Effects.enable_single(left_effect.effect_id, kungfu_ids[1])
                        end

                        local secondary_success = false
                        if right_effect and kungfu_ids[2] then
                            _log(
                                "Applying secondary effect: kungfu " ..
                                    kungfu_ids[2] .. " -> effect " .. right_effect.effect_id
                            )
                            secondary_success = Effects.enable_single(right_effect.effect_id, kungfu_ids[2])
                        end

                        return main_success or secondary_success
                    end,
                    on_select = function(left_effect, right_effect, success)
                        if config.on_select then
                            config.on_select(left_effect, right_effect, success, Effects)
                        end
                    end,
                    on_close = config.on_close,
                    instance_name = INSTANCE_NAME,
                    enable_search = true
                }
            )
        end
    )
    if not ok then
        _log("ERROR: Failed to show DualEffectSelector: " .. tostring(err))
        return nil
    end
end

-- ============================================================
-- CLOSE SELECTOR
-- ============================================================

function DualEffectSelector.close()
    DualSelector.close(INSTANCE_NAME)
end

return DualEffectSelector
