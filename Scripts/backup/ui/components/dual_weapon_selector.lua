-- ============================================================
-- UI_REFACTORED/COMPONENTS/DUAL_WEAPON_SELECTOR.LUA - Dual Weapon Selector
-- ============================================================
-- Refactored to use universal DualSelector
-- Allows selecting two weapons (left hand + right hand)
--
-- Usage:
--   local DualWeaponSelector = dofile("ui/components/dual_weapon_selector.lua")
--   DualWeaponSelector.show({ on_select = function(left, right) ... end })

local DualWeaponSelector = {}

-- Reference libs via Reg
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Utils = Reg.get("Utils")

-- Load centralized logging config
local LogConfig = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\ui\\log_config.lua", "LogConfig")

local function _log(msg)
    if LogConfig then
        LogConfig.log("DualWeaponSelector", msg)
    end
end

-- Load dependencies
local DualSelector = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\ui\\components\\dual_selector.lua", "DualSelector")

-- Singleton instance name
local INSTANCE_NAME = "VAR_DUAL_WEAPON_SELECTOR"

-- ============================================================
-- DATA PROVIDER
-- ============================================================

function DualWeaponSelector.load_weapons()
    local WeaponSkins = nil

    -- Try loading WeaponSkins module
    pcall(
        function()
            WeaponSkins = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\actions\\weapon_skins.lua", "WeaponSkins")
        end
    )

    if not WeaponSkins then
        _log("ERROR: Could not load WeaponSkins module")
        return nil, {}, {}, {}, {}
    end

    -- Get all weapon skins
    local all_weapon_skins = WeaponSkins.get_weapon_list()
    if not all_weapon_skins then
        _log("ERROR: Could not load weapon skin list")
        return WeaponSkins, {}, {}, {}, {}
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

    -- Filter weapon skins by kungfu compatibility (matching working version logic)
    local main_weapons = {}
    local secondary_weapons = {}

    for _, weapon in ipairs(all_weapon_skins) do
        local compatible_kongfu = WeaponSkins.get_weapon_data(weapon.item_no)
        if compatible_kongfu and compatible_kongfu.compatible_kongfu then
            -- Check if weapon is compatible with main kungfu
            if kungfu_ids[1] then
                for _, kongfu_info in ipairs(compatible_kongfu.compatible_kongfu) do
                    if kongfu_info.kongfu_id == kungfu_ids[1] then
                        main_weapons[#main_weapons + 1] = weapon
                        break
                    end
                end
            end

            -- Check if weapon is compatible with secondary kungfu
            if kungfu_ids[2] then
                for _, kongfu_info in ipairs(compatible_kongfu.compatible_kongfu) do
                    if kongfu_info.kongfu_id == kungfu_ids[2] then
                        secondary_weapons[#secondary_weapons + 1] = weapon
                        break
                    end
                end
            end
        end
    end

    _log("Loaded " .. #main_weapons .. " main weapons, " .. #secondary_weapons .. " secondary weapons")
    _log("Kungfu IDs: " .. table.concat(kungfu_ids, ", "))

    return WeaponSkins, main_weapons, secondary_weapons, kungfu_ids, all_weapon_skins
end

-- ============================================================
-- SHOW SELECTOR
-- ============================================================

function DualWeaponSelector.show(config)
    config = config or {}

    -- Load weapon data with correct filtering
    local WeaponSkins, main_weapons, secondary_weapons, kungfu_ids, all_weapons = DualWeaponSelector.load_weapons()

    if not WeaponSkins then
        _log("ERROR: Could not load weapon data")
        return nil
    end

    -- Use universal DualSelector with separate lists for each kungfu
    return DualSelector.show(
        {
            title = "Dual Weapon Skin Selector",
            left = {
                title = "Main Weapon Skins" .. (kungfu_ids[1] and (" (Kungfu: " .. kungfu_ids[1] .. ")") or ""),
                items = main_weapons,
                get_display_name = function(weapon)
                    local stars = string.rep("★", weapon.star or 1)
                    return (weapon.name or "Unknown") .. " [" .. weapon.item_no .. "] " .. stars
                end,
                get_id = function(weapon)
                    return weapon.item_no
                end,
                empty_message = "No compatible weapon skins"
            },
            right = {
                title = "Secondary Weapon Skins" .. (kungfu_ids[2] and (" (Kungfu: " .. kungfu_ids[2] .. ")") or ""),
                items = secondary_weapons,
                get_display_name = function(weapon)
                    local stars = string.rep("★", weapon.star or 1)
                    return (weapon.name or "Unknown") .. " [" .. weapon.item_no .. "] " .. stars
                end,
                get_id = function(weapon)
                    return weapon.item_no
                end,
                empty_message = "No compatible weapon skins"
            },
            on_apply = function(left_weapon, right_weapon)
                -- Disable prior hooks before applying
                if WeaponSkins.is_enabled and WeaponSkins.is_enabled() then
                    WeaponSkins.disable()
                end

                local main_success = false
                if left_weapon then
                    _log("Applying main weapon skin: " .. left_weapon.item_no)
                    main_success = WeaponSkins.apply(left_weapon.item_no)
                end

                local secondary_success = false
                if right_weapon then
                    _log("Applying secondary weapon skin: " .. right_weapon.item_no)
                    secondary_success = WeaponSkins.apply(right_weapon.item_no)
                end

                return main_success or secondary_success
            end,
            on_select = function(left_weapon, right_weapon, success)
                if config.on_select then
                    config.on_select(left_weapon, right_weapon, success, WeaponSkins)
                end
            end,
            on_close = config.on_close,
            instance_name = INSTANCE_NAME,
            enable_search = true
        }
    )
end

-- ============================================================
-- CLOSE SELECTOR
-- ============================================================

function DualWeaponSelector.close()
    DualSelector.close(INSTANCE_NAME)
end

return DualWeaponSelector
