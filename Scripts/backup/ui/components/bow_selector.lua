-- ============================================================
-- UI_REFACTORED/COMPONENTS/BOW_SELECTOR.LUA - Bow Selector
-- ============================================================
-- Refactored to use universal ItemSelector
-- ~70% smaller than original
--
-- Usage:
--   local BowSelector = dofile("ui/components/bow_selector.lua")
--   BowSelector.show({ on_select = function(bow) ... end })

local BowSelector = {}

-- Reference libs via Reg
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Utils = Reg.get("Utils")

-- Load centralized logging config
local LogConfig = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\ui\\log_config.lua", "LogConfig")

local function _log(msg)
    if LogConfig then
        LogConfig.log("BowSelector", msg)
    end
end

-- Load dependencies
local ItemSelector = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\ui\\components\\item_selector.lua", "ItemSelector")

-- Singleton instance name
local INSTANCE_NAME = "VAR_BOW_SELECTOR"

-- ============================================================
-- DATA PROVIDER
-- ============================================================

function BowSelector.load_bows()
    local bow_list = {}
    local WeaponSkins = nil

    -- Try loading WeaponSkins module
    pcall(
        function()
            WeaponSkins = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\actions\\weapon_skins.lua", "WeaponSkins")
        end
    )

    -- Get all weapons and filter for bows
    if WeaponSkins and WeaponSkins.get_weapon_list then
        local all_weapons = WeaponSkins.get_weapon_list()
        if all_weapons and #all_weapons > 0 then
            -- Filter by subtype_name field (discovered in weapon_skin_data.lua)
            for _, weapon in ipairs(all_weapons) do
                local subtype_name = weapon.subtype_name or ""
                if subtype_name == "Bow" then
                    bow_list[#bow_list + 1] = weapon
                end
            end
            _log("Loaded " .. #bow_list .. " bows from " .. #all_weapons .. " total weapons")
            return bow_list, WeaponSkins
        end
    end

    _log("WARNING: No bow data found")
    return {}, WeaponSkins
end

-- ============================================================
-- SHOW SELECTOR
-- ============================================================

function BowSelector.show(config)
    config = config or {}

    -- Load bow data
    local bows, WeaponSkins = BowSelector.load_bows()

    -- Use universal ItemSelector
    return ItemSelector.show(
        {
            title = "Bow Selector",
            items = bows,
            get_display_name = function(bow)
                return bow.name or "Unknown"
            end,
            get_id = function(bow)
                return bow.item_no
            end, -- FIX: Bows use item_no, not bow_id
            on_apply = function(bow)
                if not WeaponSkins then return false end
                -- Disable prior hooks before applying new bow skin
                if WeaponSkins.is_enabled and WeaponSkins.is_enabled() then
                    WeaponSkins.disable()
                end
                _log("Applying bow weapon skin: " .. bow.item_no)
                local ok, err = WeaponSkins.apply(bow.item_no)
                if not ok then
                    _log("Failed to apply bow " .. tostring(bow.item_no) .. ": " .. tostring(err))
                end
                return ok
            end,
            on_select = function(bow, success)
                if config.on_select then
                    config.on_select(bow, success, WeaponSkins)
                end
            end,
            on_close = config.on_close,
            instance_name = INSTANCE_NAME,
            enable_search = true,
            empty_message = "No bows available",
            empty_hint = "G.datam.guise_items may not be loaded yet"
        }
    )
end

-- ============================================================
-- CLOSE SELECTOR
-- ============================================================

function BowSelector.close()
    ItemSelector.close(INSTANCE_NAME)
end

return BowSelector
