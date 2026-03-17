-- ============================================================
-- UI_REFACTORED/LIB/UI_UTILS.LUA - Common UI Utilities
-- ============================================================
-- Reusable UI helper functions to eliminate code duplication
-- Prerequisites: Bootstrap must be loaded first

local UIUtils = {}

-- Reference libs via Reg
local Reg = _G.Reg
local Logger = Reg.get("Logger")

local function _log(msg)
    if Logger then Logger.log("[UIUtils] " .. msg) end
end

-- ============================================================
-- SCENE MANAGEMENT
-- ============================================================

--[[
    Get the running scene and window size safely

    @return scene, size - Scene node and size table { width, height }
    Returns nil, nil if no scene is available
]]
function UIUtils.get_safe_scene()
    local scene = nil
    local size = nil

    -- Get running scene
    pcall(function()
        scene = cc.Director:getInstance():getRunningScene()
    end)

    if not scene then
        _log("ERROR: No running scene available")
        return nil, nil
    end

    -- Get window size
    pcall(function()
        size = cc.Director:getInstance():getWinSize()
    end)

    -- Fallback to default size
    if not size then
        size = { width = 1920, height = 1080 }
    end

    return scene, size
end

-- ============================================================
-- DRAGGING BEHAVIOR
-- ============================================================

--[[
    Make a node draggable by a handle

    @param target_node - The node to move when dragging
    @param handle_node - The node that receives touch events
    @return cleanup_func - Function to remove drag behavior

    Usage:
        local cleanup = UIUtils.make_draggable(dialog, titleBar)
        -- Later: cleanup() to remove
]]
function UIUtils.make_draggable(target_node, handle_node)
    if not target_node or not handle_node then
        _log("ERROR: make_draggable requires target_node and handle_node")
        return function() end
    end

    local isDragging = false
    local dragOffset = cc.p(0, 0)

    handle_node:setTouchEnabled(true)

    local listener = function(sender, eventType)
        if eventType == 0 then  -- Touch began
            local touch = sender:getTouchBeganPosition()
            local pos = target_node:getPosition()
            dragOffset = cc.p(touch.x - pos.x, touch.y - pos.y)
            isDragging = true
        elseif eventType == 1 and isDragging then  -- Touch moved
            local touch = sender:getTouchMovePosition()
            target_node:setPosition(cc.p(touch.x - dragOffset.x, touch.y - dragOffset.y))
        elseif eventType == 2 or eventType == 3 then  -- Touch ended or cancelled
            isDragging = false
        end
    end

    handle_node:addTouchEventListener(listener)

    -- Return cleanup function
    return function()
        isDragging = false
        pcall(function()
            handle_node:setTouchEnabled(false)
        end)
    end
end

-- ============================================================
-- OVERLAY CREATION
-- ============================================================

--[[
    Create a full-screen overlay

    @param config - Configuration table:
        - z_order: number (default: 99998)
        - blocking: boolean - Block touches outside dialog (default: true)
        - scene: node - Scene to add overlay to (optional, auto-detected)
        - bg_color: table { r, g, b } (optional)
        - opacity: number (optional)
    @return overlay, cleanup - Overlay node and cleanup function
]]
function UIUtils.create_overlay(config)
    config = config or {}

    local scene = config.scene
    local size = nil

    -- Auto-detect scene if not provided
    if not scene then
        scene, size = UIUtils.get_safe_scene()
        if not scene then
            _log("ERROR: Cannot create overlay without scene")
            return nil, function() end
        end
    else
        -- Get size manually
        pcall(function()
            size = cc.Director:getInstance():getWinSize()
        end)
        if not size then
            size = { width = 1920, height = 1080 }
        end
    end

    local z_order = config.z_order or 99998
    local blocking = config.blocking ~= false  -- default true

    -- Create overlay
    local overlay = ccui.Layout:create()
    overlay:setContentSize(cc.size(size.width, size.height))
    overlay:setPosition(cc.p(0, 0))
    overlay:setTouchEnabled(blocking)

    -- Apply background if specified
    if config.bg_color then
        overlay:setBackGroundColorType(1)
        overlay:setBackGroundColor(cc.c3b(
            config.bg_color.r,
            config.bg_color.g,
            config.bg_color.b
        ))
        overlay:setBackGroundColorOpacity(config.opacity or 150)
    end

    scene:addChild(overlay, z_order)

    -- Cleanup function
    local cleanup = function()
        pcall(function()
            overlay:removeFromParent()
        end)
    end

    return overlay, cleanup
end

-- ============================================================
-- TITLE BAR CREATION
-- ============================================================

--[[
    Create a standard title bar

    @param config - Configuration table:
        - width: number (required)
        - height: number (default: 80)
        - title: string (default: "")
        - bg_color: table { r, g, b } (required)
        - text_color: table { r, g, b } (optional, default: white)
        - font_size: number (optional, default: 44)
        - draggable: boolean (default: false)
        - target_node: node - Node to drag if draggable is true
    @return title_bar, title_text, cleanup
]]
function UIUtils.create_title_bar(config)
    config = config or {}

    if not config.width or not config.bg_color then
        _log("ERROR: create_title_bar requires width and bg_color")
        return nil, nil, function() end
    end

    local width = config.width
    local height = config.height or 80
    local title = config.title or ""
    local bg_color = config.bg_color
    local text_color = config.text_color or { r = 255, g = 255, b = 255 }
    local font_size = config.font_size or 44

    -- Create title bar
    local titleBar = ccui.Layout:create()
    titleBar:setContentSize(cc.size(width, height))
    titleBar:setBackGroundColorType(1)
    titleBar:setBackGroundColor(cc.c3b(bg_color.r, bg_color.g, bg_color.b))
    titleBar:setBackGroundColorOpacity(255)

    -- Create title text
    local titleText = ccui.Text:create(title, "Arial", font_size)
    titleText:setTextColor(cc.c3b(text_color.r, text_color.g, text_color.b))
    titleText:setPosition(cc.p(width / 2, height / 2))
    titleBar:addChild(titleText)

    -- Make draggable if requested
    local cleanup_drag = function() end
    if config.draggable and config.target_node then
        cleanup_drag = UIUtils.make_draggable(config.target_node, titleBar)
    end

    return titleBar, titleText, cleanup_drag
end

-- ============================================================
-- SCROLL LIST CREATION
-- ============================================================

--[[
    Create a scrollable list of items with buttons

    @param parent - Parent node to add scroll view to
    @param items - Array of item data
    @param config - Configuration table:
        - list_width: number (required)
        - list_height: number (required)
        - item_height: number (default: 80)
        - position: { x, y } (default: { 0, 0 })
        - get_display_name: function(item) -> string
        - get_id: function(item) -> any
        - on_item_click: function(item, index, btn, bg)
        - bg_list: table { r, g, b }
        - bg_item_normal: table { r, g, b }
        - bg_item_hover: table { r, g, b }
        - bg_item_selected: table { r, g, b }
        - text_color: table { r, g, b }
        - text_color_selected: table { r, g, b }
        - font_size: number
        - enable_multi_select: boolean (default: false)
    @return scroll_view, item_buttons, item_backgrounds
]]
function UIUtils.create_scroll_list(parent, items, config)
    config = config or {}
    items = items or {}

    if not parent or not config.list_width or not config.list_height then
        _log("ERROR: create_scroll_list requires parent, list_width, and list_height")
        return nil, {}, {}
    end

    local list_w = config.list_width
    local list_h = config.list_height
    local item_h = config.item_height or 80
    local pos = config.position or { x = 0, y = 0 }

    local get_display_name = config.get_display_name or function(item) return tostring(item.name or item.id or item) end
    local get_id = config.get_id or function(item) return item.id or item end
    local on_item_click = config.on_item_click or function() end

    -- Colors with defaults
    local bg_list = config.bg_list or { r = 15, g = 15, b = 25 }
    local bg_normal = config.bg_item_normal or { r = 30, g = 30, b = 50 }
    local bg_hover = config.bg_item_hover or { r = 50, g = 50, b = 80 }
    local bg_selected = config.bg_item_selected or { r = 40, g = 80, b = 40 }
    local text_color = config.text_color or { r = 200, g = 200, b = 255 }
    local text_color_selected = config.text_color_selected or { r = 100, g = 255, b = 100 }
    local font_size = config.font_size or 28
    local initial_selection_id = config.initial_selection_id  -- ID to pre-select

    -- Create scroll view
    local scrollView = ccui.ScrollView:create()
    scrollView:setContentSize(cc.size(list_w, list_h))
    scrollView:setPosition(cc.p(pos.x, pos.y))
    scrollView:setDirection(1)  -- Vertical
    scrollView:setBounceEnabled(true)
    scrollView:setClippingEnabled(true)
    scrollView:setBackGroundColorType(1)
    scrollView:setBackGroundColor(cc.c3b(bg_list.r, bg_list.g, bg_list.b))
    scrollView:setBackGroundColorOpacity(255)
    parent:addChild(scrollView)

    -- Calculate inner container size
    local innerH = #items * item_h
    if innerH < list_h then innerH = list_h end
    scrollView:setInnerContainerSize(cc.size(list_w, innerH))

    local item_buttons = {}
    local item_backgrounds = {}
    local selected_indices = {}

    -- Create item buttons
    for i, item in ipairs(items) do
        local displayName = get_display_name(item)
        local itemId = get_id(item)
        local btnY = innerH - (i - 0.5) * item_h

        -- Truncate long names
        if #displayName > 50 then
            displayName = displayName:sub(1, 47) .. "..."
        end

        -- Button background
        local btnBg = ccui.Layout:create()
        btnBg:setContentSize(cc.size(list_w - 20, item_h - 10))
        btnBg:setAnchorPoint(cc.p(0.5, 0.5))
        btnBg:setPosition(cc.p(list_w / 2, btnY))
        btnBg:setBackGroundColorType(1)
        btnBg:setBackGroundColor(cc.c3b(bg_normal.r, bg_normal.g, bg_normal.b))
        btnBg:setBackGroundColorOpacity(255)
        scrollView:addChild(btnBg)
        item_backgrounds[i] = btnBg

        -- Button
        local btn = ccui.Button:create()
        btn:setTitleText(displayName .. " [" .. tostring(itemId) .. "]")
        btn:setTitleFontSize(font_size)
        btn:setTitleColor(cc.c3b(text_color.r, text_color.g, text_color.b))
        btn:setScale9Enabled(true)
        btn:setContentSize(cc.size(list_w - 20, item_h - 10))
        btn:setAnchorPoint(cc.p(0.5, 0.5))
        btn:setPosition(cc.p((list_w - 20) / 2, (item_h - 10) / 2))
        btnBg:addChild(btn)
        item_buttons[i] = btn

        -- Touch handler
        btn:addTouchEventListener(function(sender, eventType)
            if eventType == 0 then  -- Hover
                btnBg:setBackGroundColor(cc.c3b(bg_hover.r, bg_hover.g, bg_hover.b))
            elseif eventType == 2 then  -- Click
                -- Handle selection
                if config.enable_multi_select then
                    selected_indices[i] = not selected_indices[i]
                else
                    -- Reset all
                    for j = 1, #item_backgrounds do
                        item_backgrounds[j]:setBackGroundColor(cc.c3b(bg_normal.r, bg_normal.g, bg_normal.b))
                        item_buttons[j]:setTitleColor(cc.c3b(text_color.r, text_color.g, text_color.b))
                    end
                    selected_indices = { [i] = true }
                end

                -- Update this item
                if selected_indices[i] then
                    btnBg:setBackGroundColor(cc.c3b(bg_selected.r, bg_selected.g, bg_selected.b))
                    sender:setTitleColor(cc.c3b(text_color_selected.r, text_color_selected.g, text_color_selected.b))
                else
                    btnBg:setBackGroundColor(cc.c3b(bg_normal.r, bg_normal.g, bg_normal.b))
                    sender:setTitleColor(cc.c3b(text_color.r, text_color.g, text_color.b))
                end

                -- Callback
                on_item_click(item, i, sender, btnBg)

            elseif eventType == 3 then  -- Cancelled
                if selected_indices[i] then
                    btnBg:setBackGroundColor(cc.c3b(bg_selected.r, bg_selected.g, bg_selected.b))
                else
                    btnBg:setBackGroundColor(cc.c3b(bg_normal.r, bg_normal.g, bg_normal.b))
                end
            end
        end)

        -- Highlight initial selection if provided
        if initial_selection_id and itemId == initial_selection_id then
            selected_indices[i] = true
            btnBg:setBackGroundColor(cc.c3b(bg_selected.r, bg_selected.g, bg_selected.b))
            btn:setTitleColor(cc.c3b(text_color_selected.r, text_color_selected.g, text_color_selected.b))
        end
    end

    return scrollView, item_buttons, item_backgrounds
end

-- ============================================================
-- BUTTON HELPERS
-- ============================================================

--[[
    Create a standard button

    @param config - Configuration table:
        - text: string
        - width: number
        - height: number
        - font_size: number
        - text_color: table { r, g, b }
        - on_click: function
    @return button
]]
function UIUtils.create_button(config)
    config = config or {}

    local btn = ccui.Button:create()
    btn:setTitleText(config.text or "")
    btn:setTitleFontSize(config.font_size or 32)
    btn:setTitleColor(cc.c3b(
        config.text_color and config.text_color.r or 255,
        config.text_color and config.text_color.g or 255,
        config.text_color and config.text_color.b or 255
    ))
    btn:setScale9Enabled(true)
    btn:setContentSize(cc.size(config.width or 180, config.height or 60))

    if config.on_click then
        btn:addTouchEventListener(function(sender, eventType)
            if eventType == 2 then  -- Click
                config.on_click(sender)
            end
        end)
    end

    return btn
end

-- ============================================================
-- TEXT HELPERS
-- ============================================================

--[[
    Create a text label

    @param text - Text content
    @param font_size - Font size
    @param color - Color table { r, g, b }
    @return text_node
]]
function UIUtils.create_text(text, font_size, color)
    font_size = font_size or 32
    color = color or { r = 255, g = 255, b = 255 }

    local textNode = ccui.Text:create(text or "", "Arial", font_size)
    textNode:setTextColor(cc.c3b(color.r, color.g, color.b))

    return textNode
end

return UIUtils
