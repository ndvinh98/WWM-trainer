-- ============================================================
-- BUTTON.LUA - Toggle Button UI Component
-- ============================================================
-- Prerequisites: Bootstrap must be loaded first
-- Usage:
--   local Button = require("ui.components.button") or dofile()
--   local btn = Button.create(parent, config)

local Button = {}

-- Reference libs via Reg (loaded once by bootstrap)
local Reg = _G.Reg
local Logger = Reg.lib("Logger")
local BUTTON_STATE = Reg.state("ui.button")
BUTTON_STATE.states = BUTTON_STATE.states or {}

local function _log(msg)
    if Logger then Logger.log("[Button] " .. msg) end
end

-- Default button styling
Button.DEFAULTS = {
    width = 400,
    height = 60,
    font_size = 36,
    color_on = { r = 100, g = 255, b = 100 },
    color_off = { r = 255, g = 255, b = 255 },
    prefix_on = "[✓] ",
    prefix_off = "[ ] ",
    suffix_on = " ON",
    suffix_off = " OFF",
}

--[[
    Create a toggle button

    @param parent - Parent UI node to add button to
    @param config - Configuration table:
        - id: string - Unique identifier
        - label: string - Display text
        - x, y: number - Position
        - width, height: number - Size (optional, uses defaults)
        - state: boolean - Initial state
        - on_action: function - Called when toggled ON
        - off_action: function - Called when toggled OFF
        - on_toggle: function(state, btn) - Called on any toggle (alternative to on/off actions)

    @return button, state_ref
]]
function Button.create(parent, config)
    if not parent then
        _log("ERROR: No parent provided")
        return nil
    end

    config = config or {}
    local id = config.id or "button"
    local label = config.label or "Button"
    local x = config.x or 0
    local y = config.y or 0
    local width = config.width or Button.DEFAULTS.width
    local height = config.height or Button.DEFAULTS.height
    local font_size = config.font_size or Button.DEFAULTS.font_size

    -- State tracking
    local state = config.state or false

    -- Create button widget
    local btn = ccui.Button:create()
    btn:setTitleFontSize(font_size)
    btn:setScale9Enabled(true)
    btn:setContentSize(cc.size(width, height))
    btn:setPosition(cc.p(x, y))
    parent:addChild(btn)

    -- Update button appearance based on state
    local function update_appearance()
        local prefix = state and Button.DEFAULTS.prefix_on or Button.DEFAULTS.prefix_off
        local suffix = state and Button.DEFAULTS.suffix_on or Button.DEFAULTS.suffix_off
        local color = state and Button.DEFAULTS.color_on or Button.DEFAULTS.color_off

        pcall(function()
            btn:setTitleText(prefix .. label .. suffix)
            btn:setTitleColor(cc.c3b(color.r, color.g, color.b))
        end)
    end

    -- Initial appearance
    update_appearance()

    -- Touch handler
    btn:addTouchEventListener(function(sender, eventType)
        if eventType == 0 then  -- Touch began
            pcall(function() sender:setScale(0.95) end)
        elseif eventType == 2 then  -- Touch ended
            pcall(function() sender:setScale(1.0) end)

            -- Toggle state
            state = not state
            update_appearance()

            -- Save state globally if id provided
            if id then
                BUTTON_STATE.states[id] = state
            end

            -- Call appropriate action
            if config.on_toggle then
                pcall(config.on_toggle, state, sender)
            elseif state and config.on_action then
                pcall(config.on_action, sender)
            elseif not state and config.off_action then
                pcall(config.off_action, sender)
            end

            _log(id .. " toggled: " .. (state and "ON" or "OFF"))
        elseif eventType == 3 then  -- Touch cancelled
            pcall(function() sender:setScale(1.0) end)
        end
    end)

    -- Return button and state accessor
    local state_ref = {
        get = function() return state end,
        set = function(new_state)
            state = new_state
            update_appearance()
        end,
        toggle = function()
            state = not state
            update_appearance()
            return state
        end
    }

    return btn, state_ref
end

--[[
    Create a simple action button (no toggle, just executes action)

    @param parent - Parent UI node
    @param config - Configuration table:
        - label: string - Display text
        - x, y: number - Position
        - width, height: number - Size
        - action: function - Called when clicked

    @return button
]]
function Button.create_action(parent, config)
    if not parent then return nil end

    config = config or {}
    local label = config.label or "Action"
    local x = config.x or 0
    local y = config.y or 0
    local width = config.width or Button.DEFAULTS.width
    local height = config.height or Button.DEFAULTS.height
    local font_size = config.font_size or Button.DEFAULTS.font_size

    local btn = ccui.Button:create()
    btn:setTitleText(label)
    btn:setTitleFontSize(font_size)
    btn:setTitleColor(cc.c3b(255, 255, 255))
    btn:setScale9Enabled(true)
    btn:setContentSize(cc.size(width, height))
    btn:setPosition(cc.p(x, y))
    parent:addChild(btn)

    btn:addTouchEventListener(function(sender, eventType)
        if eventType == 0 then
            pcall(function() sender:setScale(0.95) end)
        elseif eventType == 2 then
            pcall(function() sender:setScale(1.0) end)
            if config.action then
                pcall(config.action, sender)
            end
        elseif eventType == 3 then
            pcall(function() sender:setScale(1.0) end)
        end
    end)

    return btn
end

return Button
