-- ============================================================
-- UI_REFACTORED/COMPONENTS/ITEM_SELECTOR.LUA - Universal Item Selector
-- ============================================================
-- Enhanced universal selector using theme.lua and ui_utils.lua
-- Can be used for suits, effects, weapons, or any list-based selection
--
-- Usage:
--   local ItemSelector = dofile("ui/components/item_selector.lua")
--   ItemSelector.show({
--       title = "Select Item",
--       items = { {...}, {...} },
--       get_display_name = function(item) return item.name end,
--       on_apply = function(item) return true end,
--   })

local ItemSelector = {}

-- Reference libs via Reg
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")

local function _log(msg)
    if Logger then
        Logger.log("[ItemSelector] " .. msg)
    end
end

local Theme = Reg.get("Theme")
if not Theme then
    local ok; ok, Theme = pcall(dofile, Constants.SCRIPTS_ROOT .. "\\ui\\lib\\theme.lua")
    if not ok then Theme = nil end
end
local UIUtils = Reg.get("UIUtils")
if not UIUtils then
    local ok; ok, UIUtils = pcall(dofile, Constants.SCRIPTS_ROOT .. "\\ui\\lib\\ui_utils.lua")
    if not ok then UIUtils = nil end
end

-- ============================================================
-- ITEM SELECTOR
-- ============================================================

--[[
    Show a scrollable item selector dialog

    @param config - Configuration table:
        - title: string - Dialog title
        - items: array - Array of item data
        - get_display_name: function(item) - Extract display name
        - get_id: function(item) - Extract unique ID
        - on_apply: function(item) - Called when item clicked (return true for success)
        - on_select: function(item, success) - Called after on_apply
        - on_close: function() - Called when dialog closed
        - empty_message: string - Message when no items
        - empty_hint: string - Hint when no items
        - status_hint: string - Initial status text
        - instance_name: string - Reg key for singleton (default: "VAR_ITEM_SELECTOR")
        - enable_search: boolean - Enable search bar (default: false)
        - dialog_width: number - Override dialog width
        - dialog_height: number - Override dialog height

    @return selector_api
]]
function ItemSelector.show(config)
    config = config or {}

    -- Configuration
    local title = config.title or "Select Item"
    local items = config.items or {}
    local get_display_name = config.get_display_name or function(item)
            return tostring(item.name or item.id)
        end
    local get_id = config.get_id or function(item)
            return item.id
        end
    local on_apply = config.on_apply or function(item)
            return true
        end
    local on_select = config.on_select or function()
        end
    local on_close = config.on_close or function()
        end
    local empty_message = config.empty_message or "No items found!"
    local empty_hint = config.empty_hint or ""
    local status_hint = config.status_hint or "Click an item to apply"
    local instance_name = config.instance_name or "VAR_ITEM_SELECTOR"
    local enable_search = config.enable_search or false

    -- Selection memory: restore last selected item
    local memory_key = "LAST_SELECTED_" .. instance_name
    local last_selected_id = Reg.get(memory_key)

    if last_selected_id then
        _log("Selection memory: Restoring last selected ID = " .. tostring(last_selected_id))
    else
        _log("Selection memory: No previous selection found")
    end

    -- Dialog dimensions
    local DIALOG_W = config.dialog_width or Theme.DIMENSIONS.DIALOG_W
    local DIALOG_H = config.dialog_height or Theme.DIMENSIONS.DIALOG_H

    -- Close existing if open (singleton pattern)
    if Reg.get(instance_name) then
        pcall(
            function()
                Reg.get(instance_name):removeFromParent()
            end
        )
        Reg.del(instance_name)
    end

    -- Get scene and size
    local scene, size = UIUtils.get_safe_scene()
    if not scene then
        _log("ERROR: No running scene")
        return nil
    end

    -- Create overlay
    local overlay, cleanup_overlay =
        UIUtils.create_overlay(
        {
            scene = scene,
            z_order = Theme.Z_ORDER.DIALOG,
            blocking = false -- Non-blocking for selectors
        }
    )

    if not overlay then
        _log("ERROR: Failed to create overlay")
        return nil
    end

    Reg.set(instance_name, overlay)

    -- Create dialog box (bottom-right position)
    local dialog = ccui.Layout:create()
    dialog:setContentSize(cc.size(DIALOG_W, DIALOG_H))
    dialog:setPosition(cc.p(size.width - DIALOG_W - 20, 20))
    dialog:setBackGroundColorType(1)
    Theme.apply_bg(dialog, Theme.BG.DIALOG, Theme.OPACITY.DIALOG)
    dialog:setTouchEnabled(true)
    dialog:setClippingEnabled(true)
    overlay:addChild(dialog)

    -- Create draggable title bar
    local titleBar, titleText, cleanup_drag =
        UIUtils.create_title_bar(
        {
            width = DIALOG_W,
            height = Theme.DIMENSIONS.TITLE_BAR_H,
            title = title,
            bg_color = Theme.BG.TITLE,
            text_color = Theme.COLORS.TEXT_WHITE,
            font_size = Theme.FONTS.TITLE_LARGE,
            draggable = true,
            target_node = dialog
        }
    )

    titleBar:setPosition(cc.p(0, DIALOG_H - Theme.DIMENSIONS.TITLE_BAR_H))
    dialog:addChild(titleBar)

    -- Status label
    local selectedItem = nil
    local statusLabel = UIUtils.create_text(status_hint, Theme.FONTS.STATUS, Theme.COLORS.STATUS_HINT)
    statusLabel:setPosition(cc.p(DIALOG_W / 2, DIALOG_H - Theme.DIMENSIONS.TITLE_BAR_H - 35))
    dialog:addChild(statusLabel)

    -- Search bar area (if enabled)
    local searchY = DIALOG_H - Theme.DIMENSIONS.TITLE_BAR_H - 70
    local searchField = nil
    local filteredItems = items

    if enable_search then
        -- Search input container
        local searchContainer = ccui.Layout:create()
        searchContainer:setContentSize(cc.size(DIALOG_W - 40, 60))
        searchContainer:setPosition(cc.p(20, searchY - 60))
        searchContainer:setBackGroundColorType(1)
        Theme.apply_bg(searchContainer, Theme.BG.INPUT, Theme.OPACITY.INPUT)
        dialog:addChild(searchContainer)

        -- Search text field
        searchField = ccui.TextField:create()
        searchField:setPlaceHolder("Search...")
        searchField:setFontSize(Theme.FONTS.NORMAL)
        searchField:setFontName("Arial")
        searchField:setTextColor(Theme.to_c3b(Theme.COLORS.TEXT))
        searchField:setPlaceHolderColor(Theme.to_c3b(Theme.COLORS.TEXT_DARK_GRAY))
        searchField:setAnchorPoint(cc.p(0, 0.5))
        searchField:setPosition(cc.p(10, 30))
        searchField:setContentSize(cc.size(DIALOG_W - 60, 50))
        searchField:setMaxLengthEnabled(true)
        searchField:setMaxLength(100)
        searchField:setTouchEnabled(true)
        searchContainer:addChild(searchField)

        searchY = searchY - 70 -- Adjust for search bar
    end

    -- Calculate list area
    local LIST_W = DIALOG_W - 40
    local LIST_Y_START = 100
    local LIST_H = (enable_search and searchY or (DIALOG_H - Theme.DIMENSIONS.TITLE_BAR_H - 70)) - LIST_Y_START

    -- Filter function
    local function filter_items(search_text)
        if not search_text or search_text == "" then
            return items
        end

        local filtered = {}
        local search_lower = search_text:lower()

        for _, item in ipairs(items) do
            local display_name = get_display_name(item)
            local item_id = tostring(get_id(item))

            if display_name:lower():find(search_lower, 1, true) or item_id:lower():find(search_lower, 1, true) then
                filtered[#filtered + 1] = item
            end
        end

        return filtered
    end

    -- Scroll list variables
    local scrollView = nil
    local itemButtons = {}
    local itemBgs = {}

    -- Function to rebuild list
    local function rebuild_list(items_to_show)
        -- Remove old scroll view
        if scrollView then
            pcall(
                function()
                    scrollView:removeFromParent()
                end
            )
        end

        -- Create scroll list using UIUtils
        scrollView, itemButtons, itemBgs =
            UIUtils.create_scroll_list(
            dialog,
            items_to_show,
            {
                list_width = LIST_W,
                list_height = LIST_H,
                item_height = Theme.DIMENSIONS.ITEM_H,
                position = {x = 20, y = LIST_Y_START},
                get_display_name = get_display_name,
                get_id = get_id,
                bg_list = Theme.BG.LIST,
                bg_item_normal = Theme.BG.ITEM_NORMAL,
                bg_item_hover = Theme.BG.ITEM_HOVER,
                bg_item_selected = Theme.BG.ITEM_SELECTED,
                text_color = Theme.COLORS.TEXT,
                text_color_selected = Theme.COLORS.TEXT_SELECTED,
                font_size = Theme.FONTS.ITEM,
                on_item_click = function(item, index, btn, bg)
                    selectedItem = item

                    -- Apply item
                    local displayName = get_display_name(item)
                    local itemId = get_id(item)
                    _log("Applying: " .. displayName .. " [" .. tostring(itemId) .. "]")

                    -- Save selection to memory
                    _log("Saving selection to memory: " .. memory_key .. " = " .. tostring(itemId))
                    Reg.set(memory_key, itemId)

                    local success = on_apply(item)

                    -- Update status
                    if success then
                        statusLabel:setString("Applied: " .. displayName .. " ✓")
                        Theme.apply_text_color(statusLabel, Theme.COLORS.STATUS_SUCCESS)
                    else
                        statusLabel:setString("Failed: " .. displayName)
                        Theme.apply_text_color(statusLabel, Theme.COLORS.STATUS_ERROR)
                    end

                    -- Callback
                    pcall(on_select, item, success)
                end,
                initial_selection_id = last_selected_id -- Restore last selection
            }
        )

        -- Show empty message if no items
        if #items_to_show == 0 then
            local emptyText = UIUtils.create_text(empty_message, Theme.FONTS.SUBTITLE, Theme.COLORS.STATUS_ERROR)
            emptyText:setPosition(cc.p(LIST_W / 2, LIST_H / 2 + 20))
            scrollView:addChild(emptyText)

            if empty_hint ~= "" then
                local hintText = UIUtils.create_text(empty_hint, Theme.FONTS.SMALL, Theme.COLORS.TEXT_GRAY)
                hintText:setPosition(cc.p(LIST_W / 2, LIST_H / 2 - 20))
                scrollView:addChild(hintText)
            end
        end
    end

    -- Initial list build
    rebuild_list(filteredItems)

    -- Search event listener
    if enable_search and searchField then
        searchField:addEventListener(
            function(sender, eventType)
                if
                    eventType == ccui.TextFiledEventType.detachWithIME or
                        eventType == ccui.TextFiledEventType.insertText or
                        eventType == ccui.TextFiledEventType.deleteBackward
                 then
                    local search_text = searchField:getString() or ""
                    filteredItems = filter_items(search_text)
                    rebuild_list(filteredItems)
                end
            end
        )
    end

    -- Close button
    local btnClose =
        UIUtils.create_button(
        {
            text = "Close",
            width = Theme.DIMENSIONS.BTN_W,
            height = Theme.DIMENSIONS.BTN_H,
            font_size = Theme.FONTS.BUTTON,
            text_color = Theme.COLORS.CLOSE,
            on_click = function()
                ItemSelector.close(instance_name)
                pcall(on_close)
            end
        }
    )
    btnClose:setPosition(cc.p(DIALOG_W / 2, 40))
    dialog:addChild(btnClose)

    _log("Opened " .. title .. " with " .. #items .. " items" .. (enable_search and " (search enabled)" or ""))

    -- Return API
    return {
        overlay = overlay,
        dialog = dialog,
        close = function()
            ItemSelector.close(instance_name)
            pcall(on_close)
        end,
        get_selected = function()
            return selectedItem
        end,
        refresh = function(new_items)
            items = new_items or items
            filteredItems = enable_search and filter_items(searchField and searchField:getString() or "") or items
            rebuild_list(filteredItems)
        end
    }
end

-- ============================================================
-- CLOSE SELECTOR
-- ============================================================

function ItemSelector.close(instance_name)
    instance_name = instance_name or "VAR_ITEM_SELECTOR"

    if Reg.get(instance_name) then
        pcall(
            function()
                Reg.get(instance_name):removeFromParent()
            end
        )
        Reg.del(instance_name)
        _log("Closed " .. instance_name)
    end
end

return ItemSelector
