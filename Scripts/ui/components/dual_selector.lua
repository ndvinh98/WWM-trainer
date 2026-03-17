-- ============================================================
-- UI_REFACTORED/COMPONENTS/DUAL_SELECTOR.LUA - Dual List Selector
-- ============================================================
-- Generic dual-list selector for showing two item lists side-by-side
-- Handles synchronized selection and application
--
-- Usage:
--   local DualSelector = dofile("ui/components/dual_selector.lua")
--   DualSelector.show({
--       title = "Dual Selector",
--       left = { title, items, get_display_name, get_id },
--       right = { title, items, get_display_name, get_id },
--       on_apply = function(left_item, right_item) ... end
--   })

local DualSelector = {}

-- Reference libs via Reg
local Reg = _G.Reg
local Constants = Reg.lib("Constants")
local Theme = Reg.lib("Theme")
local UIUtils = Reg.lib("UIUtils")
local DUAL_SELECTOR_STATE = Reg.state("ui.dual_selector")
DUAL_SELECTOR_STATE.memory = DUAL_SELECTOR_STATE.memory or {}
DUAL_SELECTOR_STATE.instances = DUAL_SELECTOR_STATE.instances or {}

local ok_lc, LogConfig = pcall(dofile, Constants.SCRIPTS_ROOT .. "\\ui\\log_config.lua")
if not ok_lc then LogConfig = nil end

local function _log(msg)
    if LogConfig then
        LogConfig.log("DualSelector", msg)
    end
end

-- ============================================================
-- DUAL SELECTOR CORE
-- ============================================================

--[[
    Show dual selector dialog with two lists side-by-side

    @param config - Configuration table:
        - title: string - Dialog title
        - left: { title, items, get_display_name, get_id, empty_message }
        - right: { title, items, get_display_name, get_id, empty_message }
        - on_apply: function(left_item, right_item) - Apply both selections
        - on_select: function(left_item, right_item, success) - Called after apply
        - on_close: function() - Called when dialog closed
        - instance_name: string - Unique instance identifier
        - enable_search: boolean - Enable search for both lists (default: true)

    @return selector_api
]]
function DualSelector.show(config)
    _log("=== DualSelector.show() START ===")
    config = config or {}
    local title = config.title or "Dual Selector"
    local left_config = config.left or {}
    local right_config = config.right or {}
    local on_apply = config.on_apply or function()
            return true
        end
    local on_select = config.on_select or function()
        end
    local on_close = config.on_close or function()
        end
    local instance_name = config.instance_name or "VAR_DUAL_SELECTOR"
    local enable_search = config.enable_search ~= false

    _log("Title: " .. title)
    _log("Left items: " .. #(left_config.items or {}))
    _log("Right items: " .. #(right_config.items or {}))

    -- Selection memory keys
    local left_memory_key = "LAST_SELECTED_LEFT_" .. instance_name
    local right_memory_key = "LAST_SELECTED_RIGHT_" .. instance_name
    local last_left_id = DUAL_SELECTOR_STATE.memory[left_memory_key]
    local last_right_id = DUAL_SELECTOR_STATE.memory[right_memory_key]

    if last_left_id then
        _log("Left selection memory: " .. tostring(last_left_id))
    end
    if last_right_id then
        _log("Right selection memory: " .. tostring(last_right_id))
    end

    -- Close existing instance
    if DUAL_SELECTOR_STATE.instances[instance_name] then
        local existing = DUAL_SELECTOR_STATE.instances[instance_name]
        if existing and existing.close then
            pcall(existing.close)
        end
        DUAL_SELECTOR_STATE.instances[instance_name] = nil
        _log("Closed existing instance")
    end

    -- Get scene
    _log("Getting scene...")
    local scene, size = UIUtils.get_safe_scene()
    if not scene then
        _log("ERROR: No scene available")
        return nil
    end
    _log("✓ Scene: " .. size.width .. "x" .. size.height)

    -- Dialog dimensions
    _log("Calculating dimensions...")
    local DIALOG_W = 1400 -- Increased from 1000
    local DIALOG_H = 1000
    local TITLE_BAR_H = Theme.DIMENSIONS.TITLE_BAR_H
    local BUTTON_H = Theme.DIMENSIONS.BTN_H
    local MARGIN = 20
    local LIST_W = (DIALOG_W - MARGIN * 3) / 2 -- Two lists side-by-side

    -- Calculate available vertical space
    -- Total height - title bar - button area - margins - status text area
    local AVAILABLE_HEIGHT = DIALOG_H - TITLE_BAR_H - BUTTON_H - (MARGIN * 4) - 60
    local LIST_H = AVAILABLE_HEIGHT -- Use all available space
    local SEARCH_H = 60

    _log("Dialog: " .. DIALOG_W .. "x" .. DIALOG_H)
    _log("Title: " .. TITLE_BAR_H .. ", Available: " .. AVAILABLE_HEIGHT .. ", List: " .. LIST_H)
    _log("List W: " .. LIST_W)

    -- Create overlay (transparent, non-blocking)
    _log("Creating overlay...")
    local overlay = ccui.Layout:create()
    overlay:setContentSize(cc.size(size.width, size.height))
    overlay:setPosition(cc.p(0, 0))
    overlay:setTouchEnabled(false) -- Don't block touches
    scene:addChild(overlay, Theme.Z_ORDER.DIALOG)
    _log("✓ Transparent overlay created")

    local cleanup_overlay = function()
        pcall(
            function()
                if overlay then
                    overlay:removeFromParent()
                end
            end
        )
    end

    -- Create dialog (positioned at right-bottom like working version, not centered)
    _log("Creating dialog panel...")
    local dialog = ccui.Layout:create()
    dialog:setContentSize(cc.size(DIALOG_W, DIALOG_H))
    dialog:setPosition(cc.p(size.width - DIALOG_W - 20, 20)) -- Right bottom with margin
    dialog:setTouchEnabled(true) -- Make dialog itself blocking
    dialog:setSwallowTouches(false) -- Allow child elements to receive touches
    Theme.apply_bg(dialog, Theme.BG.DIALOG, Theme.OPACITY.DIALOG)
    overlay:addChild(dialog)
    _log("✓ Dialog panel created at position (" .. (size.width - DIALOG_W - 20) .. ", 20)")

    -- Create title bar
    _log("Creating title bar...")
    local titleBar, titleText, cleanup_drag =
        UIUtils.create_title_bar(
        {
            width = DIALOG_W,
            height = TITLE_BAR_H,
            title = title,
            bg_color = Theme.BG.TITLE,
            draggable = true,
            target_node = dialog
        }
    )
    titleBar:setPosition(cc.p(0, DIALOG_H - TITLE_BAR_H))
    dialog:addChild(titleBar)
    _log("✓ Title bar created at Y=" .. (DIALOG_H - TITLE_BAR_H))

    -- State for selections
    _log("Initializing selection state...")
    local left_selected = nil
    local right_selected = nil
    local left_selected_btn = nil
    local right_selected_btn = nil
    local left_selected_bg = nil
    local right_selected_bg = nil
    _log("✓ Selection state ready")

    -- Helper to create single list panel
    _log("Setting up list panel creator...")
    local function create_list_panel(panel_config, x_pos)
        _log("  Creating list panel at x=" .. x_pos)
        local panel_title = panel_config.title or "List"
        local items = panel_config.items or {}
        local get_display_name = panel_config.get_display_name or function(item)
                return tostring(item)
            end
        local get_id = panel_config.get_id or function(item)
                return item.id
            end
        local empty_message = panel_config.empty_message or "No items"

        _log("  Panel: " .. panel_title .. " with " .. #items .. " items")

        -- Container for this list
        _log("  Creating container layout...")
        local container = ccui.Layout:create()
        container:setContentSize(cc.size(LIST_W, LIST_H))
        -- Position from bottom: margin + button area + margin + status text area
        local container_y = MARGIN + BUTTON_H + MARGIN + 60
        container:setPosition(cc.p(x_pos, container_y))
        dialog:addChild(container)
        _log("  ✓ Container created at Y=" .. container_y .. ", size=" .. LIST_W .. "x" .. LIST_H)

        -- List title
        _log("  Creating list title...")
        local listTitle = ccui.Text:create(panel_title, "Arial", 28)
        listTitle:setPosition(cc.p(LIST_W / 2, LIST_H - 20))
        listTitle:setTextColor(Theme.to_c4b(Theme.COLORS.TEXT))
        container:addChild(listTitle)
        _log("  ✓ List title created")

        local search_offset = enable_search and (SEARCH_H + MARGIN) or 0
        local scroll_height = LIST_H - 50 - search_offset
        _log("  Scroll height: " .. scroll_height .. ", search_offset: " .. search_offset)

        -- Search field (if enabled)
        local searchField = nil
        local filtered_items = items

        if enable_search then
            _log("  Creating search field...")
            searchField = ccui.TextField:create()
            searchField:setPlaceHolder("Search...")
            searchField:setFontSize(24)
            searchField:setTextColor(Theme.to_c4b(Theme.COLORS.INPUT_TEXT))
            searchField:setMaxLength(50)
            searchField:setContentSize(cc.size(LIST_W - 40, SEARCH_H))
            searchField:setPosition(cc.p(LIST_W / 2, LIST_H - 70))
            container:addChild(searchField)
            _log("  ✓ Search field created at Y=" .. (LIST_H - 70))
        end

        -- Scroll view for items
        _log("  Creating scroll view...")
        local scrollView = ccui.ScrollView:create()
        scrollView:setContentSize(cc.size(LIST_W, scroll_height))
        scrollView:setPosition(cc.p(0, 0))
        scrollView:setDirection(1) -- 1 = Vertical
        scrollView:setBounceEnabled(true)
        scrollView:setClippingEnabled(true)
        Theme.apply_bg(scrollView, Theme.BG.LIST, 255)
        container:addChild(scrollView)
        _log("  ✓ Scroll view created, size=" .. LIST_W .. "x" .. scroll_height)

        local itemButtons = {}
        local itemBgs = {}

        -- Render items function
        local function render_items(items_to_show, on_item_click_callback)
            _log("  Rendering " .. #items_to_show .. " items...")
            _log("  Click callback provided: " .. tostring(on_item_click_callback ~= nil))

            -- Clear existing items
            scrollView:removeAllChildren()
            itemButtons = {}
            itemBgs = {}

            if #items_to_show == 0 then
                _log("  No items to show, displaying empty message")
                local emptyText = ccui.Text:create(empty_message, "Arial", 24)
                emptyText:setPosition(cc.p(LIST_W / 2, scroll_height / 2))
                emptyText:setTextColor(Theme.to_c4b(Theme.COLORS.STATUS_HINT))
                scrollView:addChild(emptyText)
                return
            end

            -- Calculate inner height and ensure items are positioned from top
            local innerHeight = math.max(#items_to_show * Theme.DIMENSIONS.ITEM_H, scroll_height)
            scrollView:setInnerContainerSize(cc.size(LIST_W, innerHeight))
            _log("  Inner container size: " .. LIST_W .. "x" .. innerHeight)

            for i, item in ipairs(items_to_show) do
                local display_name = get_display_name(item)
                local item_id = get_id(item)

                -- Item background - position from top to bottom
                local itemBg = ccui.Layout:create()
                itemBg:setContentSize(cc.size(LIST_W - 10, Theme.DIMENSIONS.ITEM_H - 5))
                -- Align from top: first item at (innerHeight - ITEM_H), second at (innerHeight - 2*ITEM_H), etc.
                local y_pos = innerHeight - (i * Theme.DIMENSIONS.ITEM_H)
                itemBg:setPosition(cc.p(5, y_pos))
                Theme.apply_bg(itemBg, Theme.BG.ITEM_NORMAL, 255)
                scrollView:addChild(itemBg)

                -- Item button
                local itemBtn = ccui.Button:create()
                itemBtn:setContentSize(cc.size(LIST_W - 10, Theme.DIMENSIONS.ITEM_H - 5))
                itemBtn:setTitleText(display_name)
                itemBtn:setTitleFontSize(24)
                itemBtn:setTitleColor(Theme.to_c3b(Theme.COLORS.TEXT))
                itemBtn:setScale9Enabled(true)
                itemBtn:setPosition(cc.p((LIST_W - 10) / 2, (Theme.DIMENSIONS.ITEM_H - 5) / 2))
                itemBg:addChild(itemBtn)

                -- IMMEDIATELY attach click handler (same as UIUtils.create_scroll_list pattern)
                if on_item_click_callback then
                    itemBtn:addTouchEventListener(
                        function(sender, eventType)
                            on_item_click_callback(item, i, sender, itemBg, eventType)
                        end
                    )
                end

                itemButtons[i] = itemBtn
                itemBgs[i] = itemBg
            end

            _log("  ✓ Rendered " .. #items_to_show .. " items")
            _log("  Final itemButtons array length: " .. #itemButtons)
            _log("  Final itemBgs array length: " .. #itemBgs)
            return itemButtons, itemBgs
        end

        -- Return panel API (render will be called later with click handler)
        return {
            container = container,
            scrollView = scrollView,
            searchField = searchField,
            itemButtons = itemButtons,
            itemBgs = itemBgs,
            filtered_items = filtered_items,
            render_items = render_items,
            items = items,
            get_display_name = get_display_name
        }
    end

    -- Create left and right panels
    _log("Creating left panel...")
    local left_panel = create_list_panel(left_config, MARGIN)
    _log("Creating right panel...")
    local right_panel = create_list_panel(right_config, MARGIN + LIST_W + MARGIN)

    -- Left panel click handler (with immediate application)
    local function on_left_item_click(item, i, sender, bg, eventType)
        _log("  LEFT ITEM " .. i .. " EVENT: " .. tostring(eventType))

        if eventType == 0 then -- BEGAN
            _log("  → Left item " .. i .. " touch BEGAN")
            Theme.apply_bg(bg, Theme.BG.ITEM_HOVER, 255)
        elseif eventType == 2 then -- ENDED (click completed)
            _log("  → Left item " .. i .. " touch ENDED - SELECTING & APPLYING")

            -- Deselect previous
            if left_selected_bg then
                Theme.apply_bg(left_selected_bg, Theme.BG.ITEM_NORMAL, 255)
            end
            if left_selected_btn then
                left_selected_btn:setTitleColor(Theme.to_c3b(Theme.COLORS.TEXT))
            end

            -- Select current
            left_selected = item
            left_selected_btn = sender
            left_selected_bg = bg
            Theme.apply_bg(bg, Theme.BG.ITEM_SELECTED, 255)
            sender:setTitleColor(Theme.to_c3b(Theme.COLORS.TEXT_SELECTED))

            -- Save to memory
            local item_id = left_config.get_id(item)
            _log("  → Saving left selection to memory...")
            _log("     Memory key: " .. left_memory_key)
            _log("     Item ID: " .. tostring(item_id) .. " (type: " .. type(item_id) .. ")")
            DUAL_SELECTOR_STATE.memory[left_memory_key] = item_id
            local verify = DUAL_SELECTOR_STATE.memory[left_memory_key]
            _log("     Verification read: " .. tostring(verify) .. " (type: " .. type(verify) .. ")")
            _log("     Match: " .. tostring(verify == item_id))

            -- IMMEDIATE APPLICATION when both sides are selected
            if right_selected then
                _log("  → Both sides selected - applying immediately...")
                local success = false
                local ok, err =
                    pcall(
                    function()
                        success = on_apply(left_selected, right_selected)
                    end
                )

                if not ok then
                    _log("  → ERROR in on_apply: " .. tostring(err))
                end

                if success then
                    _log("  → ✓ Application successful")
                    statusText:setString("✓ Applied successfully!")
                    statusText:setTextColor(Theme.to_c4b(Theme.COLORS.STATUS_SUCCESS))
                else
                    _log("  → ✗ Application failed")
                    statusText:setString("✗ Application failed")
                    statusText:setTextColor(Theme.to_c4b(Theme.COLORS.STATUS_ERROR))
                end

                pcall(on_select, left_selected, right_selected, success)
            else
                statusText:setString("Left selected - now select right side")
                statusText:setTextColor(Theme.to_c4b(Theme.COLORS.STATUS_HINT))
            end

            _log("  → Selection complete!")
        elseif eventType == 3 then -- CANCELED
            _log("  → Left item " .. i .. " touch CANCELED")
            if left_selected ~= item then
                Theme.apply_bg(bg, Theme.BG.ITEM_NORMAL, 255)
            end
        end
    end

    -- Right panel click handler (with immediate application)
    local function on_right_item_click(item, i, sender, bg, eventType)
        _log("  RIGHT ITEM " .. i .. " EVENT: " .. tostring(eventType))

        if eventType == 0 then -- BEGAN
            _log("  → Right item " .. i .. " touch BEGAN")
            Theme.apply_bg(bg, Theme.BG.ITEM_HOVER, 255)
        elseif eventType == 2 then -- ENDED (click completed)
            _log("  → Right item " .. i .. " touch ENDED - SELECTING & APPLYING")

            -- Deselect previous
            if right_selected_bg then
                Theme.apply_bg(right_selected_bg, Theme.BG.ITEM_NORMAL, 255)
            end
            if right_selected_btn then
                right_selected_btn:setTitleColor(Theme.to_c3b(Theme.COLORS.TEXT))
            end

            -- Select current
            right_selected = item
            right_selected_btn = sender
            right_selected_bg = bg
            Theme.apply_bg(bg, Theme.BG.ITEM_SELECTED, 255)
            sender:setTitleColor(Theme.to_c3b(Theme.COLORS.TEXT_SELECTED))

            -- Save to memory
            local item_id = right_config.get_id(item)
            _log("  → Saving right selection to memory...")
            _log("     Memory key: " .. right_memory_key)
            _log("     Item ID: " .. tostring(item_id) .. " (type: " .. type(item_id) .. ")")
            DUAL_SELECTOR_STATE.memory[right_memory_key] = item_id
            local verify = DUAL_SELECTOR_STATE.memory[right_memory_key]
            _log("     Verification read: " .. tostring(verify) .. " (type: " .. type(verify) .. ")")
            _log("     Match: " .. tostring(verify == item_id))

            -- IMMEDIATE APPLICATION when both sides are selected
            if left_selected then
                _log("  → Both sides selected - applying immediately...")
                local success = false
                local ok, err =
                    pcall(
                    function()
                        success = on_apply(left_selected, right_selected)
                    end
                )

                if not ok then
                    _log("  → ERROR in on_apply: " .. tostring(err))
                end

                if success then
                    _log("  → ✓ Application successful")
                    statusText:setString("✓ Applied successfully!")
                    statusText:setTextColor(Theme.to_c4b(Theme.COLORS.STATUS_SUCCESS))
                else
                    _log("  → ✗ Application failed")
                    statusText:setString("✗ Application failed")
                    statusText:setTextColor(Theme.to_c4b(Theme.COLORS.STATUS_ERROR))
                end

                pcall(on_select, left_selected, right_selected, success)
            else
                statusText:setString("Right selected - now select left side")
                statusText:setTextColor(Theme.to_c4b(Theme.COLORS.STATUS_HINT))
            end

            _log("  → Selection complete!")
        elseif eventType == 3 then -- CANCELED
            _log("  → Right item " .. i .. " touch CANCELED")
            if right_selected ~= item then
                Theme.apply_bg(bg, Theme.BG.ITEM_NORMAL, 255)
            end
        end
    end

    -- Status text (create BEFORE memory restoration so it can be updated)
    _log("Creating status text...")
    local status_y = MARGIN + BUTTON_H + 15
    local statusText = ccui.Text:create("Select items from both lists", "Arial", 24)
    statusText:setPosition(cc.p(DIALOG_W / 2, status_y))
    statusText:setTextColor(Theme.to_c4b(Theme.COLORS.STATUS_HINT))
    dialog:addChild(statusText)
    _log("✓ Status text created at Y=" .. status_y)

    -- Initial render with click handlers
    _log("Initial render of left panel...")
    local left_btns, left_bgs = left_panel.render_items(left_panel.filtered_items, on_left_item_click)
    left_panel.itemButtons = left_btns or {}
    left_panel.itemBgs = left_bgs or {}
    _log("Initial render of right panel...")
    local right_btns, right_bgs = right_panel.render_items(right_panel.filtered_items, on_right_item_click)
    right_panel.itemButtons = right_btns or {}
    right_panel.itemBgs = right_bgs or {}

    -- Restore previous selections from memory
    _log("=== MEMORY RESTORATION DEBUG ===")
    _log("Left memory key: " .. left_memory_key)
    _log("Right memory key: " .. right_memory_key)
    _log("Last left ID: " .. tostring(last_left_id))
    _log("Last right ID: " .. tostring(last_right_id))
    _log("Left panel items count: " .. #left_panel.filtered_items)
    _log("Right panel items count: " .. #right_panel.filtered_items)
    _log("Left panel itemButtons count: " .. #left_panel.itemButtons)
    _log("Right panel itemButtons count: " .. #right_panel.itemButtons)
    _log("Left panel itemBgs count: " .. #left_panel.itemBgs)
    _log("Right panel itemBgs count: " .. #right_panel.itemBgs)

    if last_left_id then
        _log("Attempting to restore left selection from memory: " .. tostring(last_left_id))
        local found = false
        for i, item in ipairs(left_panel.filtered_items) do
            local item_id = left_config.get_id(item)
            _log("  Checking left item " .. i .. ": ID=" .. tostring(item_id) .. " (type: " .. type(item_id) .. ")")
            if item_id == last_left_id then
                _log("  ✓ MATCH! Found left item at index " .. i)
                found = true
                left_selected = item
                left_selected_btn = left_panel.itemButtons[i]
                left_selected_bg = left_panel.itemBgs[i]
                _log("  Button exists: " .. tostring(left_selected_btn ~= nil))
                _log("  Background exists: " .. tostring(left_selected_bg ~= nil))
                if left_selected_bg then
                    Theme.apply_bg(left_selected_bg, Theme.BG.ITEM_SELECTED, 255)
                    _log("  Applied selected background")
                end
                if left_selected_btn then
                    left_selected_btn:setTitleColor(Theme.to_c3b(Theme.COLORS.TEXT_SELECTED))
                    _log("  Applied selected text color")
                end
                break
            end
        end
        if not found then
            _log("  ✗ WARNING: Could not find left item with ID " .. tostring(last_left_id))
        end
    else
        _log("No left selection to restore (last_left_id is nil)")
    end

    if last_right_id then
        _log("Attempting to restore right selection from memory: " .. tostring(last_right_id))
        local found = false
        for i, item in ipairs(right_panel.filtered_items) do
            local item_id = right_config.get_id(item)
            _log("  Checking right item " .. i .. ": ID=" .. tostring(item_id) .. " (type: " .. type(item_id) .. ")")
            if item_id == last_right_id then
                _log("  ✓ MATCH! Found right item at index " .. i)
                found = true
                right_selected = item
                right_selected_btn = right_panel.itemButtons[i]
                right_selected_bg = right_panel.itemBgs[i]
                _log("  Button exists: " .. tostring(right_selected_btn ~= nil))
                _log("  Background exists: " .. tostring(right_selected_bg ~= nil))
                if right_selected_bg then
                    Theme.apply_bg(right_selected_bg, Theme.BG.ITEM_SELECTED, 255)
                    _log("  Applied selected background")
                end
                if right_selected_btn then
                    right_selected_btn:setTitleColor(Theme.to_c3b(Theme.COLORS.TEXT_SELECTED))
                    _log("  Applied selected text color")
                end
                break
            end
        end
        if not found then
            _log("  ✗ WARNING: Could not find right item with ID " .. tostring(last_right_id))
        end
    else
        _log("No right selection to restore (last_right_id is nil)")
    end
    _log("=== END MEMORY RESTORATION DEBUG ===")

    -- Update initial status based on restored selections
    if left_selected and right_selected then
        statusText:setString("Previous selections restored")
        statusText:setTextColor(Theme.to_c4b(Theme.COLORS.STATUS_HINT))

        -- Auto-apply restored selections
        _log("Auto-applying restored selections...")
        local success = false
        local ok, err =
            pcall(
            function()
                success = on_apply(left_selected, right_selected)
            end
        )

        if not ok then
            _log("ERROR auto-applying: " .. tostring(err))
        end

        if success then
            statusText:setString("✓ Previous selections restored and applied")
            statusText:setTextColor(Theme.to_c4b(Theme.COLORS.STATUS_SUCCESS))
        end
    elseif left_selected then
        statusText:setString("Left restored - now select right side")
        statusText:setTextColor(Theme.to_c4b(Theme.COLORS.STATUS_HINT))
    elseif right_selected then
        statusText:setString("Right restored - now select left side")
        statusText:setTextColor(Theme.to_c4b(Theme.COLORS.STATUS_HINT))
    end

    -- Search handler for left panel
    if left_panel.searchField then
        _log("Setting up left search handler")
        left_panel.searchField:addEventListener(
            function(sender, eventType)
                if
                    eventType == ccui.TextFiledEventType.insert_text or
                        eventType == ccui.TextFiledEventType.delete_backward
                 then
                    local search_text = left_panel.searchField:getString():lower()
                    _log("Left search: '" .. search_text .. "'")

                    if search_text == "" then
                        left_panel.filtered_items = left_panel.items
                    else
                        left_panel.filtered_items = {}
                        for _, item in ipairs(left_panel.items) do
                            local display_name = left_panel.get_display_name(item):lower()
                            if display_name:find(search_text, 1, true) then
                                left_panel.filtered_items[#left_panel.filtered_items + 1] = item
                            end
                        end
                    end

                    _log("Left search found " .. #left_panel.filtered_items .. " items")
                    local left_btns, left_bgs = left_panel.render_items(left_panel.filtered_items, on_left_item_click)
                    left_panel.itemButtons = left_btns or {}
                    left_panel.itemBgs = left_bgs or {}
                end
            end
        )
    end

    -- Search handler for right panel
    if right_panel.searchField then
        _log("Setting up right search handler")
        right_panel.searchField:addEventListener(
            function(sender, eventType)
                if
                    eventType == ccui.TextFiledEventType.insert_text or
                        eventType == ccui.TextFiledEventType.delete_backward
                 then
                    local search_text = right_panel.searchField:getString():lower()
                    _log("Right search: '" .. search_text .. "'")

                    if search_text == "" then
                        right_panel.filtered_items = right_panel.items
                    else
                        right_panel.filtered_items = {}
                        for _, item in ipairs(right_panel.items) do
                            local display_name = right_panel.get_display_name(item):lower()
                            if display_name:find(search_text, 1, true) then
                                right_panel.filtered_items[#right_panel.filtered_items + 1] = item
                            end
                        end
                    end

                    _log("Right search found " .. #right_panel.filtered_items .. " items")
                    local right_btns, right_bgs =
                        right_panel.render_items(right_panel.filtered_items, on_right_item_click)
                    right_panel.itemButtons = right_btns or {}
                    right_panel.itemBgs = right_bgs or {}
                end
            end
        )
    end

    -- Buttons at bottom
    _log("Creating buttons...")
    local button_y = MARGIN + BUTTON_H / 2

    -- Apply button
    local applyBtn = ccui.Button:create()
    applyBtn:setContentSize(cc.size(200, BUTTON_H))
    applyBtn:setTitleText("Apply")
    applyBtn:setTitleFontSize(28)
    applyBtn:setTitleColor(Theme.to_c3b(Theme.COLORS.ACTION))
    applyBtn:setScale9Enabled(true)
    applyBtn:setPosition(cc.p(DIALOG_W / 2 - 110, button_y))
    applyBtn:setTouchEnabled(true)
    applyBtn:setSwallowTouches(false)
    Theme.apply_bg(applyBtn, Theme.BG.BTN_NORMAL, 255)
    dialog:addChild(applyBtn)
    _log("  Apply button created and added to dialog")

    -- Close button
    local closeBtn = ccui.Button:create()
    closeBtn:setContentSize(cc.size(200, BUTTON_H))
    closeBtn:setTitleText("Close")
    closeBtn:setTitleFontSize(28)
    closeBtn:setTitleColor(Theme.to_c3b(Theme.COLORS.TEXT))
    closeBtn:setScale9Enabled(true)
    closeBtn:setPosition(cc.p(DIALOG_W / 2 + 110, button_y))
    closeBtn:setTouchEnabled(true)
    closeBtn:setSwallowTouches(false)
    Theme.apply_bg(closeBtn, Theme.BG.BTN_NORMAL, 255)
    dialog:addChild(closeBtn)
    _log("  Close button created and added to dialog")
    _log("✓ Buttons created at Y=" .. button_y)

    -- Cleanup function
    local function cleanup()
        _log("Cleaning up DualSelector...")
        pcall(
            function()
                if cleanup_drag then
                    cleanup_drag()
                end
                if cleanup_overlay then
                    cleanup_overlay()
                end
            end
        )
        DUAL_SELECTOR_STATE.instances[instance_name] = nil
        _log("✓ Cleanup complete")
    end

    -- Apply button handler
    _log("Setting up Apply button listener...")
    applyBtn:addTouchEventListener(
        function(sender, eventType)
            _log("APPLY BUTTON EVENT: " .. tostring(eventType))

            if eventType == 0 then -- BEGAN
                _log("  → Apply button touch BEGAN")
            elseif eventType == 2 then -- ENDED (click completed)
                _log("  → Apply button touch ENDED - APPLYING")

                if not left_selected or not right_selected then
                    _log(
                        "  → Missing selection - left=" ..
                            tostring(left_selected ~= nil) .. ", right=" .. tostring(right_selected ~= nil)
                    )
                    statusText:setString("Please select from BOTH lists")
                    statusText:setTextColor(Theme.to_c4b(Theme.COLORS.STATUS_ERROR))
                    return
                end

                -- Apply selections
                _log("  → Applying selections...")
                local success = false
                local ok, err =
                    pcall(
                    function()
                        success = on_apply(left_selected, right_selected)
                    end
                )

                if not ok then
                    _log("  → ERROR in on_apply: " .. tostring(err))
                end

                -- Update status
                if success then
                    _log("  → ✓ Application successful")
                    statusText:setString("✓ Applied successfully!")
                    statusText:setTextColor(Theme.to_c4b(Theme.COLORS.STATUS_SUCCESS))
                else
                    _log("  → ✗ Application failed")
                    statusText:setString("✗ Application failed")
                    statusText:setTextColor(Theme.to_c4b(Theme.COLORS.STATUS_ERROR))
                end

                -- Callback
                pcall(on_select, left_selected, right_selected, success)
            elseif eventType == 1 then -- MOVED
                _log("  → Apply button touch MOVED")
            elseif eventType == 3 then -- CANCELED
                _log("  → Apply button touch CANCELED")
            else
                _log("  → Apply button UNKNOWN event: " .. tostring(eventType))
            end
        end
    )
    _log("✓ Apply button listener attached")

    -- Close button handler
    _log("Setting up Close button listener...")
    closeBtn:addTouchEventListener(
        function(sender, eventType)
            _log("CLOSE BUTTON EVENT: " .. tostring(eventType))

            if eventType == 2 then -- ENDED (click completed)
                _log("  → Close button CLICKED - CLOSING")
                pcall(on_close)
                cleanup()
            elseif eventType == 0 then -- BEGAN
                _log("  → Close button touch BEGAN")
            elseif eventType == 1 then -- MOVED
                _log("  → Close button touch MOVED")
            elseif eventType == 3 then -- CANCELED
                _log("  → Close button touch CANCELED")
            else
                _log("  → Close button UNKNOWN event type: " .. tostring(eventType))
            end
        end
    )
    _log("✓ Close button listener attached")

    -- Hook into menu close to auto-cleanup
    _log("Checking for menu instance to hook cleanup...")
    local MenuInstance = Reg.state("ui.menu").api
    if MenuInstance then
        _log("  Menu instance found: " .. tostring(MenuInstance))
        _log("  Menu.close function: " .. tostring(MenuInstance.close))

        -- Store original close
        local original_close = MenuInstance.close

        -- Replace with wrapper that cleans up DualSelector first
        MenuInstance.close = function()
            _log("  !!! MENU CLOSE CALLED - Cleaning up DualSelector first !!!")

            -- Clean up DualSelector
            local ok, err = pcall(cleanup)
            if not ok then
                _log("  ERROR cleaning up DualSelector: " .. tostring(err))
            end

            -- Call original menu close
            if original_close then
                _log("  Calling original menu.close()")
                local ok2, err2 = pcall(original_close)
                if not ok2 then
                    _log("  ERROR calling original menu.close(): " .. tostring(err2))
                end
            else
                _log("  WARNING: No original menu.close() to call")
            end
        end

        _log("  ✓ Menu close hook installed")
    else
        _log("  WARNING: No menu instance found - cannot hook auto-cleanup")
    end

    _log("=== DualSelector.show() COMPLETE ===")

    -- API
    local api = {
        close = cleanup,
        get_left_selection = function()
            return left_selected
        end,
        get_right_selection = function()
            return right_selected
        end
    }

    -- Register instance
    DUAL_SELECTOR_STATE.instances[instance_name] = api

    return api
end

-- ============================================================
-- CLOSE SELECTOR
-- ============================================================

function DualSelector.close(instance_name)
    instance_name = instance_name or "VAR_DUAL_SELECTOR"
    local instance = DUAL_SELECTOR_STATE.instances[instance_name]
    if instance and instance.close then
        pcall(instance.close)
    end
end

return DualSelector
