-- ============================================================
-- UI_REFACTORED/LIB/THEME.LUA - Centralized UI Theme
-- ============================================================
-- Single source of truth for all UI styling (colors, dimensions, z-orders)
-- Prerequisites: Bootstrap must be loaded first

local Reg = _G.Reg
local Theme = {}

-- ============================================================
-- COLOR DEFINITIONS
-- ============================================================
Theme.COLORS = {
    -- Text colors
    TEXT = {r = 200, g = 200, b = 255},
    TEXT_SELECTED = {r = 100, g = 255, b = 100},
    TEXT_WHITE = {r = 255, g = 255, b = 255},
    TEXT_GRAY = {r = 150, g = 150, b = 150},
    TEXT_DARK_GRAY = {r = 100, g = 100, b = 100},
    -- Status colors
    STATUS_SUCCESS = {r = 100, g = 255, b = 100},
    STATUS_ERROR = {r = 255, g = 150, b = 150},
    STATUS_HINT = {r = 150, g = 200, b = 255},
    STATUS_WARNING = {r = 255, g = 200, b = 100},
    -- Button/Action colors
    ACTION = {r = 180, g = 180, b = 255},
    INPUT = {r = 255, g = 200, b = 100},
    CLOSE = {r = 255, g = 200, b = 200},
    MINIMIZE = {r = 255, g = 220, b = 100},
    SUBMIT = {r = 150, g = 255, b = 150},
    SUBMIT_BTN = {r = 150, g = 255, b = 150},
    CANCEL = {r = 255, g = 150, b = 150},
    CANCEL_BTN = {r = 255, g = 150, b = 150},
    CLEAR_BTN = {r = 255, g = 180, b = 180},
    -- Log colors
    LOG_TITLE = {r = 180, g = 180, b = 200},
    LOG_TEXT = {r = 150, g = 255, b = 150},
    -- Input field colors
    INPUT_TEXT = {r = 200, g = 255, b = 200},
    INPUT_PLACEHOLDER = {r = 100, g = 100, b = 100},
    HELPER_TEXT = {r = 120, g = 120, b = 150},
    -- Resize grip
    RESIZE_GRIP = {r = 180, g = 180, b = 200},
    -- Tab colors
    TAB_ACTIVE = {r = 100, g = 255, b = 100},
    TAB_INACTIVE = {r = 150, g = 150, b = 150},
    -- Toggle state colors
    ON = {r = 100, g = 255, b = 100},
    OFF = {r = 220, g = 220, b = 220},
    -- Title colors
    TITLE = {r = 150, g = 255, b = 150}
}

-- ============================================================
-- BACKGROUND COLORS
-- ============================================================
Theme.BG = {
    -- Panel backgrounds
    PANEL = {r = 20, g = 20, b = 35},
    DIALOG = {r = 35, g = 35, b = 55},
    TITLE = {r = 50, g = 50, b = 80},
    TAB_BAR = {r = 25, g = 25, b = 45},
    TAB_ACTIVE = {r = 50, g = 80, b = 50},
    LOG = {r = 15, g = 15, b = 25},
    -- List backgrounds
    LIST = {r = 15, g = 15, b = 25},
    ITEM_NORMAL = {r = 30, g = 30, b = 50},
    ITEM_HOVER = {r = 50, g = 50, b = 80},
    ITEM_SELECTED = {r = 40, g = 80, b = 40},
    -- Button backgrounds
    BTN_NORMAL = {r = 40, g = 40, b = 60},
    BTN_HOVER = {r = 60, g = 60, b = 90},
    BTN_ACTIVE = {r = 40, g = 80, b = 40},
    -- Input backgrounds
    INPUT = {r = 15, g = 15, b = 25},
    -- Overlay
    OVERLAY = {r = 0, g = 0, b = 0},
    -- Close button
    CLOSE_BTN = {r = 120, g = 40, b = 40},
    -- Resize handle
    RESIZE_HANDLE = {r = 80, g = 80, b = 120}
}

-- ============================================================
-- OPACITY VALUES
-- ============================================================
Theme.OPACITY = {
    PANEL = 240,
    DIALOG = 250,
    TITLE = 255,
    OVERLAY_BLOCKING = 150,
    OVERLAY_NON_BLOCKING = 0,
    BUTTON = 255,
    LIST = 255,
    INPUT = 255,
    RESIZE_HANDLE = 200,
    CLOSE_BTN = 200
}

-- ============================================================
-- DIMENSIONS
-- ============================================================
Theme.DIMENSIONS = {
    -- Panel dimensions
    PANEL_W = 1400,
    PANEL_MIN_W = 800,
    PANEL_MAX_W = 2000,
    -- Dialog dimensions
    DIALOG_W = 900,
    DIALOG_H = 900,
    DIALOG_SMALL_W = 800,
    DIALOG_SMALL_H = 400,
    -- Component heights
    TITLE_BAR_H = 80,
    TAB_BAR_H = 80,
    TOGGLE_H = 90,
    ITEM_H = 80,
    LOG_PANEL_H = 400,
    -- Button dimensions
    BTN_W = 220,
    BTN_H = 70,
    BTN_SMALL_W = 180,
    BTN_SMALL_H = 60,
    -- Input dimensions
    INPUT_W = 920,
    INPUT_H = 80,
    -- Spacing
    MARGIN = 30,
    TOGGLE_SPACING = 16,
    BTN_SPACING = 40,
    ITEM_SPACING = 10,
    -- Other
    RESIZE_HANDLE_SIZE = 40,
    CLOSE_BTN_SIZE = 60,
    -- Log panel settings
    LOG_REFRESH_INTERVAL = 0.01, -- seconds between log updates (faster refresh)
    LOG_MAX_LINES = 50 -- max lines to show in log tail
}

-- ============================================================
-- FONT SIZES
-- ============================================================
Theme.FONTS = {
    TITLE = 40,
    TITLE_LARGE = 48,
    SUBTITLE = 36,
    NORMAL = 32,
    BUTTON = 38,
    BUTTON_SMALL = 32,
    SMALL = 24,
    TINY = 20,
    ITEM = 28,
    STATUS = 32,
    HELPER = 24
}

-- ============================================================
-- Z-ORDER CONSTANTS
-- ============================================================
Theme.Z_ORDER = {
    MENU = 9999,
    DIALOG = 99999,
    OVERLAY = 99998
}

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

-- Convert color table to cc.c3b
function Theme.to_c3b(color)
    return cc.c3b(color.r, color.g, color.b)
end

-- Convert color table to cc.c4b with alpha
function Theme.to_c4b(color, alpha)
    alpha = alpha or 255
    return cc.c4b(color.r, color.g, color.b, alpha)
end

-- Apply color to node background
function Theme.apply_bg(node, color, opacity)
    opacity = opacity or 255
    pcall(
        function()
            node:setBackGroundColorType(1) -- 1 = solid color
            node:setBackGroundColor(Theme.to_c3b(color))
            node:setBackGroundColorOpacity(opacity)
        end
    )
end

-- Apply text color to node
function Theme.apply_text_color(node, color)
    pcall(
        function()
            node:setTextColor(Theme.to_c3b(color))
        end
    )
end

-- Apply title color to button
function Theme.apply_title_color(node, color)
    pcall(
        function()
            node:setTitleColor(Theme.to_c3b(color))
        end
    )
end

if Reg then
    Reg.set_lib("Theme", Theme)
end

return Theme
