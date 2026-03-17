-- ============================================================
-- UI_REFACTORED/COMPONENTS/WEAPON_SELECTOR.LUA - Weapon Selector
-- ============================================================
-- Refactored to use universal ItemSelector
-- ~70% smaller than original
--
-- Usage:
--   local WeaponSelector = dofile("ui/components/weapon_selector.lua")
--   WeaponSelector.show({ on_select = function(weapon) ... end })

local WeaponSelector = {}

-- Reference libs via Reg
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Utils = Reg.get("Utils")

local function _log(msg)
    if Logger then
        Logger.log("[WeaponSelector] " .. msg)
    end
end

-- Load dependencies
local ItemSelector = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\ui\\components\\item_selector.lua", "ItemSelector")

-- Singleton instance name
local INSTANCE_NAME = "VAR_WEAPON_SELECTOR"

-- ============================================================
-- DATA PROVIDER
-- ============================================================

function WeaponSelector.load_weapons()
    local weapon_list = {}
    local WeaponSkins = nil

    -- Try loading WeaponSkins module
    pcall(
        function()
            WeaponSkins = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\actions\\weapon_skins.lua", "WeaponSkins")
        end
    )

    if WeaponSkins and WeaponSkins.get_weapon_list then
        local list_data = WeaponSkins.get_weapon_list()
        if list_data and #list_data > 0 then
            _log("Loaded " .. #list_data .. " weapons via WeaponSkins module")
            return list_data, WeaponSkins
        end
    end

    _log("WARNING: No weapon data found")
    return {}, WeaponSkins
end

-- ============================================================
-- SHOW SELECTOR
-- ============================================================

function WeaponSelector.show(config)
    config = config or {}

    -- Load weapon data
    local weapons, WeaponSkins = WeaponSelector.load_weapons()

    -- Use universal ItemSelector
    return ItemSelector.show(
        {
            title = "Weapon Selector",
            items = weapons,
            get_display_name = function(weapon)
                return weapon.name or "Unknown"
            end,
            get_id = function(weapon)
                return weapon.weapon_id or weapon.id
            end,
            on_apply = function(weapon)
                return true -- Caller handles application
            end,
            on_select = function(weapon, success)
                if config.on_select then
                    config.on_select(weapon, success, WeaponSkins)
                end
            end,
            on_close = config.on_close,
            instance_name = INSTANCE_NAME,
            enable_search = true,
            empty_message = "No weapons available"
        }
    )
end

-- ============================================================
-- CLOSE SELECTOR
-- ============================================================

function WeaponSelector.close()
    ItemSelector.close(INSTANCE_NAME)
end

return WeaponSelector
