-- ============================================================
-- UI_REFACTORED/COMPONENTS/INPUT.LUA - Text Input UI Component
-- ============================================================
-- Refactored to use Theme and Dialog component
-- Prerequisites: Bootstrap must be loaded first
--
-- Usage:
--   local Input = dofile("ui/components/input.lua")
--   Input.show({ title = "Enter Value", ... })

local Input = {}

-- Reference libs via Reg
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")

-- Load Theme (loaded by bootstrap or dofile)
local _ok_theme, Theme = pcall(dofile, Constants.SCRIPTS_ROOT .. "\\ui\\lib\\theme.lua")
if not _ok_theme then Theme = nil end

-- Load Dialog component
local _ok_dialog, Dialog = pcall(dofile, Constants.SCRIPTS_ROOT .. "\\ui\\components\\dialog.lua")
if not _ok_dialog then Dialog = nil end

local function _log(msg)
    if Logger then
        Logger.log("[Input] " .. msg)
    end
end

-- Default input styling (uses Theme where possible)
Input.DEFAULTS = {
    dialog_width = 1000,
    dialog_height = 350,
    input_width = 920,
    input_height = 80,
    font_size = 32,
    placeholder = "Enter value...",
    max_length = 300
}

-- Helper to create input field (EditBox or TextField fallback)
local function create_input_field(container, config)
    local INPUT_W = config.input_width or Input.DEFAULTS.input_width
    local INPUT_H = config.input_height or Input.DEFAULTS.input_height
    local default_value = config.default_value or ""
    local placeholder = config.placeholder or Input.DEFAULTS.placeholder

    local inputField = nil
    local useEditBox = false

    -- Try EditBox first (better text handling)
    pcall(
        function()
            if ccui.EditBox then
                inputField = ccui.EditBox:create(cc.size(INPUT_W - 20, INPUT_H - 10), ccui.Scale9Sprite:create())
                if inputField then
                    useEditBox = true
                end
            end
        end
    )

    if useEditBox and inputField then
        inputField:setPosition(cc.p(INPUT_W / 2, INPUT_H / 2))
        inputField:setFontSize(Input.DEFAULTS.font_size)
        inputField:setFontColor(Theme.to_c3b(Theme.COLORS.INPUT_TEXT))
        inputField:setPlaceHolder(placeholder)
        inputField:setPlaceholderFontColor(Theme.to_c3b(Theme.COLORS.INPUT_PLACEHOLDER))
        inputField:setText(default_value)
        inputField:setMaxLength(Input.DEFAULTS.max_length)
        inputField:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
        container:addChild(inputField)
    else
        -- Fallback to TextField
        inputField = ccui.TextField:create()
        inputField:setPlaceHolder(placeholder)
        inputField:setFontSize(Input.DEFAULTS.font_size)
        inputField:setFontName("Arial")
        inputField:setTextColor(Theme.to_c3b(Theme.COLORS.INPUT_TEXT))
        inputField:setPlaceHolderColor(Theme.to_c3b(Theme.COLORS.INPUT_PLACEHOLDER))
        inputField:setString(default_value)
        inputField:setAnchorPoint(cc.p(0, 0.5))
        inputField:setPosition(cc.p(10, INPUT_H / 2))
        inputField:setContentSize(cc.size(INPUT_W - 20, INPUT_H - 10))
        inputField:setMaxLengthEnabled(true)
        inputField:setMaxLength(Input.DEFAULTS.max_length)
        inputField:setTouchEnabled(true)
        container:addChild(inputField)
    end

    return inputField, useEditBox
end

--[[
    Show an input dialog (closes on submit/cancel)

    @param config - Configuration table:
        - title: string - Dialog title
        - default_value: string - Initial input value
        - placeholder: string - Placeholder text
        - helper_text: string - Helper text below input
        - on_submit: function(value) - Called with input value
        - on_cancel: function - Called when cancelled
        - save_history: boolean - Save input to history (default: true)
        - history_key: string - History key (default: title)

    @return dialog_api
]]
function Input.show(config)
    config = config or {}
    local title = config.title or "Enter Value"

    -- History support
    local history_key = config.history_key or title
    local save_history = config.save_history ~= false

    local history_value = save_history and Reg.get("INPUT_HISTORY_" .. history_key) or nil
    local default_value = history_value or config.default_value or ""

    local placeholder = config.placeholder or Input.DEFAULTS.placeholder
    local helper_text = config.helper_text or ""
    local on_submit_original = config.on_submit or function()
        end
    local on_cancel = config.on_cancel or function()
        end

    -- Wrap on_submit to save to history
    local on_submit = function(value)
        if save_history and value and value ~= "" then
            Reg.set("INPUT_HISTORY_" .. history_key, value)
            _log("Saved input history: " .. history_key .. " = " .. value)
        end
        on_submit_original(value)
    end

    -- Create base dialog
    local dlg =
        Dialog and
        Dialog.create(
            {
                title = title,
                width = Input.DEFAULTS.dialog_width,
                height = Input.DEFAULTS.dialog_height
            }
        )

    if not dlg then
        _log("ERROR: Could not create dialog")
        return nil
    end

    local width = dlg.width
    local height = dlg.height
    local INPUT_W = Input.DEFAULTS.input_width
    local INPUT_H = Input.DEFAULTS.input_height

    -- Input container with background
    local inputContainer = ccui.Layout:create()
    inputContainer:setContentSize(cc.size(INPUT_W, INPUT_H))
    inputContainer:setPosition(cc.p((width - INPUT_W) / 2, height - 160))
    Theme.apply_bg(inputContainer, Theme.BG.INPUT, 255)
    inputContainer:setClippingEnabled(true)
    dlg.add_child(inputContainer)

    -- Create input field
    local inputField, useEditBox =
        create_input_field(
        inputContainer,
        {
            input_width = INPUT_W,
            input_height = INPUT_H,
            default_value = default_value,
            placeholder = placeholder
        }
    )

    -- Helper text
    if helper_text ~= "" then
        local helperLabel = ccui.Text:create(helper_text, "Arial", 24)
        helperLabel:setTextColor(Theme.to_c4b(Theme.COLORS.HELPER_TEXT))
        helperLabel:setPosition(cc.p(width / 2, height - 200))
        dlg.add_child(helperLabel)
    end

    -- Get input value helper
    local function get_value()
        local value = ""
        if useEditBox then
            pcall(
                function()
                    value = inputField:getText() or ""
                end
            )
        else
            pcall(
                function()
                    value = inputField:getString() or ""
                end
            )
        end
        return value
    end

    -- Button dimensions
    local BTN_W = 220
    local BTN_H = 70
    local BTN_SPACING = 60

    -- Cancel button
    local btnCancel = ccui.Button:create()
    btnCancel:setTitleText("Cancel")
    btnCancel:setTitleFontSize(38)
    btnCancel:setTitleColor(Theme.to_c3b(Theme.COLORS.CANCEL_BTN))
    btnCancel:setScale9Enabled(true)
    btnCancel:setContentSize(cc.size(BTN_W, BTN_H))
    btnCancel:setPosition(cc.p(width / 2 - BTN_W / 2 - BTN_SPACING / 2, 60))
    dlg.add_child(btnCancel)

    btnCancel:addTouchEventListener(
        function(sender, eventType)
            if eventType == 2 then
                dlg.close()
                on_cancel()
                _log("Input cancelled")
            end
        end
    )

    -- Submit button
    local btnSubmit = ccui.Button:create()
    btnSubmit:setTitleText("Submit")
    btnSubmit:setTitleFontSize(38)
    btnSubmit:setTitleColor(Theme.to_c3b(Theme.COLORS.SUBMIT_BTN))
    btnSubmit:setScale9Enabled(true)
    btnSubmit:setContentSize(cc.size(BTN_W, BTN_H))
    btnSubmit:setPosition(cc.p(width / 2 + BTN_W / 2 + BTN_SPACING / 2, 60))
    dlg.add_child(btnSubmit)

    btnSubmit:addTouchEventListener(
        function(sender, eventType)
            if eventType == 2 then
                local value = get_value()
                dlg.close()
                on_submit(value)
                _log("Input submitted: " .. value)
            end
        end
    )

    _log("Input dialog opened: " .. title)

    -- Extend dialog API
    dlg.get_value = get_value
    dlg.set_value = function(new_value)
        if useEditBox then
            pcall(
                function()
                    inputField:setText(new_value or "")
                end
            )
        else
            pcall(
                function()
                    inputField:setString(new_value or "")
                end
            )
        end
    end

    return dlg
end

--[[
    Show a persistent input dialog (stays open, shows status)

    @param config - Configuration table:
        - title: string - Dialog title
        - default_value: string - Initial input value
        - placeholder: string - Placeholder text
        - helper_text: string - Helper text
        - button_label: string - Submit button label (default: "Run")
        - on_submit: function(value, status_callback) - Called with value and status updater
        - on_close: function - Called when dialog is closed
        - blocking: boolean - Block interaction with background (default: false)
        - save_history: boolean - Save input to history (default: true)

    @return dialog_api
]]
function Input.show_persistent(config)
    config = config or {}
    local title = config.title or "Enter Value"

    -- History support
    local history_key = config.history_key or title
    local save_history = config.save_history ~= false

    local history_value = save_history and Reg.get("INPUT_HISTORY_" .. history_key) or nil
    local default_value = history_value or config.default_value or ""

    local helper_text = config.helper_text or ""
    local placeholder = config.placeholder or "Enter value..."
    local button_label = config.button_label or "Run"
    local on_submit_original = config.on_submit or function()
        end
    local on_close_callback = config.on_close or function()
        end

    -- Wrap on_submit to save to history
    local on_submit = function(value, status_callback)
        if save_history and value and value ~= "" then
            Reg.set("INPUT_HISTORY_" .. history_key, value)
            _log("Saved input history: " .. history_key .. " = " .. value)
        end
        on_submit_original(value, status_callback)
    end

    -- Create base dialog (draggable, non-blocking by default)
    local dlg =
        Dialog and
        Dialog.create(
            {
                title = title,
                width = Input.DEFAULTS.dialog_width + 100,
                height = Input.DEFAULTS.dialog_height + 120,
                on_close = on_close_callback,
                blocking = config.blocking,
                draggable = true
            }
        )

    if not dlg then
        _log("ERROR: Could not create dialog")
        return nil
    end

    local width = dlg.width
    local height = dlg.height
    local TITLE_BAR_H = dlg.title_bar_height or 80
    local INPUT_W = Input.DEFAULTS.input_width
    local INPUT_H = Input.DEFAULTS.input_height

    -- Input container with background
    local inputContainer = ccui.Layout:create()
    inputContainer:setContentSize(cc.size(INPUT_W, INPUT_H))
    inputContainer:setPosition(cc.p((width - INPUT_W) / 2, height - TITLE_BAR_H - INPUT_H - 20))
    Theme.apply_bg(inputContainer, Theme.BG.INPUT, 255)
    dlg.add_child(inputContainer)

    -- Create input field
    local inputField, useEditBox =
        create_input_field(
        inputContainer,
        {
            input_width = INPUT_W,
            input_height = INPUT_H,
            default_value = default_value,
            placeholder = placeholder
        }
    )

    -- Helper text
    if helper_text ~= "" then
        local helperLabel = ccui.Text:create(helper_text, "Arial", 24)
        helperLabel:setTextColor(Theme.to_c4b(Theme.COLORS.HELPER_TEXT))
        helperLabel:setPosition(cc.p(width / 2, height - TITLE_BAR_H - INPUT_H - 50))
        dlg.add_child(helperLabel)
    end

    -- Status text
    local statusText = ccui.Text:create("Ready", "Arial", 28)
    statusText:setTextColor(Theme.to_c4b(Theme.COLORS.STATUS_HINT))
    statusText:setPosition(cc.p(width / 2, height - TITLE_BAR_H - INPUT_H - 80))
    dlg.add_child(statusText)

    local function update_status(msg)
        pcall(
            function()
                statusText:setString(msg or "")
            end
        )
    end

    local function get_value()
        local value = ""
        if useEditBox then
            pcall(
                function()
                    value = inputField:getText() or ""
                end
            )
        else
            pcall(
                function()
                    value = inputField:getString() or ""
                end
            )
        end
        return value
    end

    -- Buttons
    local BTN_W = 180
    local BTN_H = 60
    local BTN_SPACING = 40

    local btnClose = ccui.Button:create()
    btnClose:setTitleText("Close")
    btnClose:setTitleFontSize(32)
    btnClose:setTitleColor(Theme.to_c3b(Theme.COLORS.CANCEL_BTN))
    btnClose:setScale9Enabled(true)
    btnClose:setContentSize(cc.size(BTN_W, BTN_H))
    btnClose:setPosition(cc.p(width / 2 - BTN_W / 2 - BTN_SPACING / 2, 50))
    dlg.add_child(btnClose)

    btnClose:addTouchEventListener(
        function(sender, eventType)
            if eventType == 2 then
                dlg.close()
            end
        end
    )

    local btnRun = ccui.Button:create()
    btnRun:setTitleText(button_label)
    btnRun:setTitleFontSize(32)
    btnRun:setTitleColor(Theme.to_c3b(Theme.COLORS.SUBMIT_BTN))
    btnRun:setScale9Enabled(true)
    btnRun:setContentSize(cc.size(BTN_W, BTN_H))
    btnRun:setPosition(cc.p(width / 2 + BTN_W / 2 + BTN_SPACING / 2, 50))
    dlg.add_child(btnRun)

    btnRun:addTouchEventListener(
        function(sender, eventType)
            if eventType == 2 then
                local value = get_value()
                on_submit(value, update_status)
            end
        end
    )

    dlg.get_value = get_value
    dlg.set_value = function(new_value)
        if useEditBox then
            pcall(
                function()
                    inputField:setText(new_value or "")
                end
            )
        else
            pcall(
                function()
                    inputField:setString(new_value or "")
                end
            )
        end
    end
    dlg.set_status = update_status

    return dlg
end

return Input
