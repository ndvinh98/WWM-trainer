-- ============================================================
-- UI_REFACTORED/COMPONENTS/DIALOG.LUA - Modal Dialog Component
-- ============================================================
-- Refactored version using theme.lua and ui_utils.lua
-- Prerequisites: Bootstrap must be loaded first
--
-- Usage:
--   local Dialog = dofile("ui/components/dialog.lua")
--   local dlg = Dialog.create({ title = "My Dialog", ... })

local Dialog = {}

-- Reference libs via Reg
local Reg = _G.Reg
local Constants = Reg.lib("Constants")
local Logger = Reg.lib("Logger")
local DIALOG_STATE = Reg.state("ui.dialog")

local function _log(msg)
    if Logger then
        Logger.log("[Dialog] " .. msg)
    end
end

-- Load refactored dependencies
local _ok_theme, Theme = pcall(dofile, Constants.SCRIPTS_ROOT .. "\\ui\\lib\\theme.lua")
if not _ok_theme then Theme = nil end
local _ok_uiutils, UIUtils = pcall(dofile, Constants.SCRIPTS_ROOT .. "\\ui\\lib\\ui_utils.lua")
if not _ok_uiutils then UIUtils = nil end

-- ============================================================
-- DIALOG CREATION
-- ============================================================

--[[
    Create a modal dialog

    @param config - Configuration table:
        - title: string - Dialog title
        - width, height: number - Dialog size
        - on_close: function - Called when dialog is closed
        - blocking: boolean - If true, overlay blocks clicks (default: true)
        - draggable: boolean - If true, title bar can drag dialog (default: false)
        - position: string - "center", "bottom-right", "custom" (default: "center")
        - custom_pos: { x, y } - Custom position if position = "custom"

    @return dialog_api - Table with methods:
        - overlay: Layout - The overlay node
        - dialog: Layout - The dialog box node
        - title_bar: Layout - The title bar node
        - title_text: Text - The title text widget
        - close: function - Close the dialog
        - add_child: function(node) - Add child to dialog
        - set_title: function(title) - Update title text
]]
function Dialog.create(config)
    config = config or {}

    local title = config.title or "Dialog"
    local width = config.width or Theme.DIMENSIONS.DIALOG_W
    local height = config.height or Theme.DIMENSIONS.DIALOG_H
    local on_close = config.on_close or function()
        end
    local blocking = config.blocking ~= false -- default true
    local draggable = config.draggable or false
    local position = config.position or "center"

    -- Get scene and size
    local scene, size = UIUtils.get_safe_scene()
    if not scene then
        _log("ERROR: No running scene found")
        return nil
    end

    -- Create overlay
    local overlay, cleanup_overlay =
        UIUtils.create_overlay(
        {
            scene = scene,
            z_order = Theme.Z_ORDER.DIALOG,
            blocking = blocking,
            bg_color = blocking and Theme.BG.OVERLAY or nil,
            opacity = blocking and Theme.OPACITY.OVERLAY_BLOCKING or Theme.OPACITY.OVERLAY_NON_BLOCKING
        }
    )

    if not overlay then
        _log("ERROR: Failed to create overlay")
        return nil
    end

    -- Store reference for singleton pattern
    DIALOG_STATE.current = overlay

    -- Calculate dialog position
    local dialog_x, dialog_y
    if position == "center" then
        dialog_x = (size.width - width) / 2
        dialog_y = (size.height - height) / 2
    elseif position == "bottom-right" then
        dialog_x = size.width - width - 20
        dialog_y = 20
    elseif position == "custom" and config.custom_pos then
        dialog_x = config.custom_pos.x
        dialog_y = config.custom_pos.y
    else
        -- Default to center
        dialog_x = (size.width - width) / 2
        dialog_y = (size.height - height) / 2
    end

    -- Create dialog box
    local dialog = ccui.Layout:create()
    dialog:setContentSize(cc.size(width, height))
    dialog:setPosition(cc.p(dialog_x, dialog_y))
    dialog:setBackGroundColorType(1)
    Theme.apply_bg(dialog, Theme.BG.DIALOG, Theme.OPACITY.DIALOG)
    dialog:setTouchEnabled(true)
    dialog:setClippingEnabled(true)
    overlay:addChild(dialog)

    -- Create title bar using UIUtils
    local titleBar, titleText, cleanup_drag =
        UIUtils.create_title_bar(
        {
            width = width,
            height = Theme.DIMENSIONS.TITLE_BAR_H,
            title = title,
            bg_color = Theme.BG.TITLE,
            text_color = Theme.COLORS.TEXT_WHITE,
            font_size = Theme.FONTS.TITLE_LARGE,
            draggable = draggable,
            target_node = dialog
        }
    )

    -- Position title bar at top of dialog
    titleBar:setPosition(cc.p(0, height - Theme.DIMENSIONS.TITLE_BAR_H))
    dialog:addChild(titleBar)

    -- Close function
    local function close()
        -- Cleanup dragging if enabled
        if cleanup_drag then
            cleanup_drag()
        end

        -- Cleanup overlay
        if cleanup_overlay then
            cleanup_overlay()
        end

        -- Remove from Reg
        DIALOG_STATE.current = nil

        -- Call user callback
        on_close()

        _log("Dialog closed: " .. title)
    end

    _log("Dialog opened: " .. title)

    -- Return API
    return {
        overlay = overlay,
        dialog = dialog,
        title_bar = titleBar,
        title_text = titleText,
        title_bar_height = Theme.DIMENSIONS.TITLE_BAR_H,
        width = width,
        height = height,
        close = close,
        -- Helper to add children to dialog
        add_child = function(node)
            dialog:addChild(node)
        end,
        -- Helper to update title
        set_title = function(new_title)
            pcall(
                function()
                    titleText:setString(new_title)
                end
            )
        end,
        -- Helper to get content area info
        get_content_area = function()
            return {
                x = 0,
                y = 0,
                width = width,
                height = height - Theme.DIMENSIONS.TITLE_BAR_H
            }
        end
    }
end

-- ============================================================
-- CONFIRMATION DIALOG
-- ============================================================

--[[
    Create a confirmation dialog with OK/Cancel buttons

    @param config - Configuration table:
        - title: string - Dialog title
        - message: string - Message text
        - on_confirm: function - Called when OK clicked
        - on_cancel: function - Called when Cancel clicked
        - ok_text: string - OK button text (default: "OK")
        - cancel_text: string - Cancel button text (default: "Cancel")

    @return dialog_api
]]
function Dialog.confirm(config)
    config = config or {}

    local message = config.message or "Are you sure?"
    local on_confirm = config.on_confirm or function()
        end
    local on_cancel = config.on_cancel or function()
        end
    local ok_text = config.ok_text or "OK"
    local cancel_text = config.cancel_text or "Cancel"

    -- Create base dialog
    local dlg =
        Dialog.create(
        {
            title = config.title or "Confirm",
            width = config.width or Theme.DIMENSIONS.DIALOG_SMALL_W,
            height = config.height or Theme.DIMENSIONS.DIALOG_SMALL_H,
            blocking = true,
            position = "center"
        }
    )

    if not dlg then
        return nil
    end

    local width = dlg.width
    local height = dlg.height
    local content_area = dlg.get_content_area()

    -- Message text
    local msgText = UIUtils.create_text(message, Theme.FONTS.NORMAL, {r = 200, g = 200, b = 200})
    msgText:setPosition(cc.p(width / 2, content_area.height / 2 + 30))
    dlg.add_child(msgText)

    -- Button dimensions
    local BTN_W = Theme.DIMENSIONS.BTN_W
    local BTN_H = Theme.DIMENSIONS.BTN_H
    local BTN_SPACING = Theme.DIMENSIONS.BTN_SPACING

    -- Cancel button
    local btnCancel =
        UIUtils.create_button(
        {
            text = cancel_text,
            width = BTN_W,
            height = BTN_H,
            font_size = Theme.FONTS.BUTTON_SMALL,
            text_color = Theme.COLORS.CANCEL,
            on_click = function()
                dlg.close()
                on_cancel()
            end
        }
    )
    btnCancel:setPosition(cc.p(width / 2 - BTN_W / 2 - BTN_SPACING / 2, 60))
    dlg.add_child(btnCancel)

    -- OK button
    local btnOk =
        UIUtils.create_button(
        {
            text = ok_text,
            width = BTN_W,
            height = BTN_H,
            font_size = Theme.FONTS.BUTTON_SMALL,
            text_color = Theme.COLORS.SUBMIT,
            on_click = function()
                dlg.close()
                on_confirm()
            end
        }
    )
    btnOk:setPosition(cc.p(width / 2 + BTN_W / 2 + BTN_SPACING / 2, 60))
    dlg.add_child(btnOk)

    return dlg
end

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

--[[
    Close any open dialog
]]
function Dialog.close_current()
    if DIALOG_STATE.current then
        pcall(
            function()
                DIALOG_STATE.current:removeFromParent()
            end
        )
        DIALOG_STATE.current = nil
        _log("Current dialog closed")
    end
end

return Dialog
