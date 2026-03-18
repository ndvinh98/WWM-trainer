-- ============================================================
-- UI_REFACTORED/MENU.LUA - Config-Driven Tab Menu
-- ============================================================
-- Refactored menu system using Theme and UIUtils
-- All styling from theme.lua, all actions via menu_controller.lua
--
-- Usage:
--   local Menu = dofile("ui/menu.lua")
--   Menu.show()
--
-- Prerequisites: Bootstrap must be loaded first

local Menu = {}

-- ============================================================
-- DEPENDENCIES
-- ============================================================

local Reg = _G.Reg
local Constants = Reg.lib("Constants")
local Logger = Reg.lib("Logger")
local Theme = Reg.lib("Theme")
local UIUtils = Reg.lib("UIUtils")
local MENU_STATE = Reg.state("ui.menu")
MENU_STATE.item_states = MENU_STATE.item_states or {}

local _SCRIPTS_ROOT = Constants.SCRIPTS_ROOT

if not Theme then
	local ok_theme
	ok_theme, Theme = pcall(dofile, _SCRIPTS_ROOT .. "\\ui\\lib\\theme.lua")
	if not ok_theme then
		Theme = nil
	end
end

if not UIUtils then
	local ok_uiutils
	ok_uiutils, UIUtils = pcall(dofile, _SCRIPTS_ROOT .. "\\ui\\lib\\ui_utils.lua")
	if not ok_uiutils then
		UIUtils = nil
	end
end

local ok_mc, MenuConfig = pcall(dofile, _SCRIPTS_ROOT .. "\\ui\\menu_config.lua")
if not ok_mc then MenuConfig = { TABS = {} } end
MENU_STATE.config = MenuConfig

local ok_ui, UIInput = pcall(dofile, _SCRIPTS_ROOT .. "\\ui\\components\\input.lua")
if not ok_ui then UIInput = nil end

local function _log(msg)
	if Logger then
		Logger.log("[Menu] " .. msg)
	end
end

-- ============================================================
-- EXPOSE CONFIG
-- ============================================================
Menu.TABS = MenuConfig.TABS

-- ============================================================
-- STATE
-- ============================================================
Menu.state = {
	current_tab = 1,
	item_states = {},
	panel = nil,
	is_minimized = false,
	log_collapsed = true, -- log panel collapsed by default
	log_widget = nil,
	refresh_action = nil,
	-- UI elements
	content_area = nil,
	tab_bar = nil,
	log_section = nil,
	title_bar = nil,
	title_text = nil,
	btn_minimize = nil,
	btn_close = nil,
	btn_clear = nil,
	log_title = nil,
	saved_panel_h = nil,
	current_panel_w = nil,
	current_panel_h = nil,
	-- Tab UI elements (for resize)
	tab_btns = {},
	tab_bgs = {},
	-- Toggle buttons (for resize)
	toggle_buttons = {},
	-- For resize
	is_resizing = false,
	resize_handle = nil,
	cleanup_drag = nil,
}

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

function Menu.get_state(id)
	local state = MENU_STATE.item_states
	if state[id] ~= nil then
		return state[id]
	end
	return false
end

function Menu.set_state(id, value)
	local state = MENU_STATE.item_states
	state[id] = value
	Menu.state.item_states[id] = value
end

-- Helper to resolve dynamic labels
function Menu.get_label(item)
	if type(item.label) == "function" then
		return item.label()
	end
	return item.label or ""
end

-- Sorting priority for item types
local ITEM_TYPE_PRIORITY = {
	toggle = 1,
	custom = 2,
	cycle = 3,
	action = 4,
	input = 5,
	input_persistent = 6,
}

-- Sort items by type
function Menu.sort_items_by_type(items)
	local sorted = {}
	for i, item in ipairs(items) do
		sorted[i] = item
	end
	table.sort(sorted, function(a, b)
		local p_a = ITEM_TYPE_PRIORITY[a.type] or 99
		local p_b = ITEM_TYPE_PRIORITY[b.type] or 99
		if p_a ~= p_b then
			return p_a < p_b
		end
		local label_a = type(a.label) == "function" and a.label() or (a.label or "")
		local label_b = type(b.label) == "function" and b.label() or (b.label or "")
		return label_a < label_b
	end)
	return sorted
end

function Menu.read_log_tail(max_lines)
	max_lines = max_lines or Theme.DIMENSIONS.LOG_MAX_LINES
	local log_path = Constants.SCRIPTS_ROOT .. "\\logs\\script_debug.txt"

	local lines = {}
	local file = io.open(log_path, "r")
	if file then
		for line in file:lines() do
			lines[#lines + 1] = line
		end
		file:close()
	else
		-- Log file doesn't exist yet
		return "(Log file not found - will appear after first log)"
	end

	if #lines == 0 then
		return "(No logs yet)"
	end

	local start_idx = math.max(1, #lines - max_lines + 1)
	local result = {}
	for i = start_idx, #lines do
		result[#result + 1] = lines[i]
	end

	-- Truncate file to keep only the last max_lines (clear stale logs)
	if #lines > max_lines then
		pcall(function()
			local wf = io.open(log_path, "w")
			if wf then
				for _, line in ipairs(result) do
					wf:write(line .. "\n")
				end
				wf:close()
			end
		end)
	end

	return table.concat(result, "\n")
end

function Menu.clear_log()
	local log_path = Constants.SCRIPTS_ROOT .. "\\logs\\script_debug.txt"
	local file = io.open(log_path, "w")
	if file then
		file:write("=== LOG CLEARED ===\n")
		file:close()
		_log("Log cleared")
	end
end

function Menu.calculate_panel_height()
	local max_items = 0
	for _, tab in ipairs(Menu.TABS) do
		if #tab.items > max_items then
			max_items = #tab.items
		end
	end
	local base = Theme.DIMENSIONS.TITLE_BAR_H + Theme.DIMENSIONS.TAB_BAR_H
	local items = max_items * (Theme.DIMENSIONS.TOGGLE_H + Theme.DIMENSIONS.TOGGLE_SPACING)
	return base + items + Theme.DIMENSIONS.MARGIN * 2 + Theme.DIMENSIONS.LOG_PANEL_H
end

-- ============================================================
-- ITEM HANDLERS
-- ============================================================

function Menu.handle_toggle(item, btn, btnBg)
	local state = not Menu.get_state(item.id)
	Menu.set_state(item.id, state)

	if state and item.on_action then
		local ok, err = pcall(item.on_action, btn)
		if not ok then
			_log("Error in on_action for " .. item.id .. ": " .. tostring(err))
		end
	elseif not state and item.off_action then
		local ok, err = pcall(item.off_action, btn)
		if not ok then
			_log("Error in off_action for " .. item.id .. ": " .. tostring(err))
		end
	end

	Menu.update_button(btn, btnBg, item, state)
	_log(item.id .. " -> " .. (state and "ON" or "OFF"))
end

function Menu.handle_action(item, btn)
	if item.action then
		local ok, err = pcall(item.action)
		if not ok then
			_log("Error in action for " .. item.id .. ": " .. tostring(err))
		end
	end
	_log(item.id .. " triggered")
end

function Menu.handle_cycle(item, btn, btnBg)
	local index = Menu.get_state(item.id) or 1
	index = index + 1
	if index > #item.values then
		index = 1
	end
	Menu.set_state(item.id, index)

	local value = item.values[index]
	local label = item.labels and item.labels[index] or tostring(value)

	if item.action then
		pcall(item.action, value)
	end

	local is_on = index > 1
	local prefix = is_on and "● " or "○ "
	pcall(function()
		btn:setTitleText(prefix .. label)
		btn:setTitleColor(Theme.to_c3b(is_on and Theme.COLORS.ON or Theme.COLORS.OFF))
		local bg = is_on and Theme.BG.BTN_ACTIVE or Theme.BG.BTN_NORMAL
		if btnBg then
			Theme.apply_bg(btnBg, bg, 255)
		end
	end)

	_log(item.id .. " -> " .. label)
end

function Menu.handle_input(item, btn)
	if not UIInput then
		return
	end

	UIInput.show({
		title = Menu.get_label(item),
		default_value = item.default_value or "",
		placeholder = item.placeholder,
		on_submit = function(value)
			if item.action then
				pcall(item.action, value)
			end
		end,
	})
end

function Menu.handle_input_persistent(item, btn)
	if not UIInput then
		_log("UIInput not available for " .. item.id)
		return
	end

	UIInput.show_persistent({
		title = Menu.get_label(item),
		default_value = item.default_value or "",
		placeholder = item.placeholder or "",
		helper_text = item.helper_text or "",
		button_label = item.button_label or "Run",
		blocking = item.blocking,
		on_submit = function(value, status_cb)
			if item.action then
				local ok, err = pcall(item.action, value, status_cb)
				if not ok then
					_log("Error in action for " .. item.id .. ": " .. tostring(err))
				end
			end
		end,
		on_close = function()
			if item.on_close then
				local ok, err = pcall(item.on_close)
				if not ok then
					_log("Error in on_close for " .. item.id .. ": " .. tostring(err))
				end
			end
		end,
	})
end

function Menu.handle_custom(item, btn, btnBg)
	if item.handler then
		local state = not Menu.get_state(item.id)
		Menu.set_state(item.id, state)
		pcall(item.handler, state, item, Menu)
		Menu.update_button(btn, btnBg, item, state)
	end
end

-- Update button appearance
function Menu.update_button(btn, btnBg, item, state)
	local prefix = state and "● " or "○ "
	local color = state and Theme.COLORS.ON or Theme.COLORS.OFF
	local bg = state and Theme.BG.BTN_ACTIVE or Theme.BG.BTN_NORMAL

	local label = item.label
	if type(label) == "function" then
		label = label()
	end

	pcall(function()
		btn:setTitleText(prefix .. label)
		btn:setTitleColor(Theme.to_c3b(color))
		if btnBg then
			Theme.apply_bg(btnBg, bg, 255)
		end
	end)
end

-- Update minimize button icon
function Menu.update_minimize_icon()
	if Menu.state.btn_minimize then
		pcall(function()
			local icon = Menu.state.is_minimized and "▲" or "▼"
			Menu.state.btn_minimize:setTitleText(icon)
		end)
	end
end

-- ============================================================
-- MENU BUILDER
-- ============================================================

function Menu.create(scene)
	_log("=== Menu.create() START ===")

	-- Check dependencies
	if not Theme then
		_log("ERROR: Theme not loaded")
		return nil
	end
	_log("✓ Theme loaded")

	if not UIUtils then
		_log("ERROR: UIUtils not loaded")
		return nil
	end
	_log("✓ UIUtils loaded")

	if not Menu.TABS or #Menu.TABS == 0 then
		_log("ERROR: Menu.TABS not loaded or empty")
		return nil
	end
	_log("✓ Menu.TABS loaded (" .. #Menu.TABS .. " tabs)")

	-- Use UIUtils for scene detection
	_log("Getting scene...")
	scene, size = UIUtils.get_safe_scene()
	if not scene then
		_log("ERROR: No scene available")
		return nil
	end
	_log("✓ Scene obtained: " .. size.width .. "x" .. size.height)

	_log("Calculating panel dimensions...")
	local PANEL_H = Menu.calculate_panel_height()
	local PANEL_W = Theme.DIMENSIONS.PANEL_W
	Menu.state.saved_panel_h = PANEL_H
	Menu.state.current_panel_w = PANEL_W
	Menu.state.current_panel_h = PANEL_H
	_log("✓ Panel dimensions: " .. PANEL_W .. "x" .. PANEL_H)

	-- Main panel
	_log("Creating main panel...")
	local panel = ccui.Layout:create()
	panel:setContentSize(cc.size(PANEL_W, PANEL_H))
	panel:setPosition(cc.p(20, 20))
	Theme.apply_bg(panel, Theme.BG.PANEL, Theme.OPACITY.PANEL)
	scene:addChild(panel, Theme.Z_ORDER.MENU)
	Menu.state.panel = panel
	_log("✓ Main panel created and added to scene")

	-- Title bar with drag support (using UIUtils)
	_log("Creating title bar...")
	local titleBar = ccui.Layout:create()
	titleBar:setContentSize(cc.size(PANEL_W, Theme.DIMENSIONS.TITLE_BAR_H))
	titleBar:setPosition(cc.p(0, PANEL_H - Theme.DIMENSIONS.TITLE_BAR_H))
	Theme.apply_bg(titleBar, Theme.BG.TITLE, 255)
	panel:addChild(titleBar)
	Menu.state.title_bar = titleBar

	local titleText = ccui.Text:create("⚔ WWM Kuro Trainer ⚔", "Arial", 40)
	titleText:setTextColor(Theme.to_c4b(Theme.COLORS.TITLE))
	titleText:setPosition(cc.p(PANEL_W / 2, Theme.DIMENSIONS.TITLE_BAR_H / 2))
	titleBar:addChild(titleText)
	Menu.state.title_text = titleText
	_log("✓ Title bar created with text")

	-- Use UIUtils.make_draggable instead of inline drag logic
	_log("Making panel draggable...")
	Menu.state.cleanup_drag = UIUtils.make_draggable(panel, titleBar)
	_log("✓ Panel is now draggable")

	-- Minimize button
	_log("Creating buttons...")
	local btnMinimize = ccui.Button:create()
	btnMinimize:setTitleText("▼")
	btnMinimize:setTitleFontSize(48)
	btnMinimize:setTitleColor(Theme.to_c3b(Theme.COLORS.MINIMIZE))
	btnMinimize:setPosition(cc.p(PANEL_W - 140, Theme.DIMENSIONS.TITLE_BAR_H / 2))
	titleBar:addChild(btnMinimize)
	Menu.state.btn_minimize = btnMinimize

	btnMinimize:addTouchEventListener(function(sender, eventType)
		if eventType == 2 then
			Menu.toggle_minimize()
		end
	end)

	-- Close button
	local closeBg = ccui.Layout:create()
	closeBg:setContentSize(cc.size(60, 60))
	closeBg:setAnchorPoint(cc.p(0.5, 0.5))
	closeBg:setPosition(cc.p(PANEL_W - 50, Theme.DIMENSIONS.TITLE_BAR_H / 2))
	Theme.apply_bg(closeBg, Theme.BG.CLOSE_BTN, 200)
	titleBar:addChild(closeBg)

	local btnClose = ccui.Button:create()
	btnClose:setTitleText("✕")
	btnClose:setTitleFontSize(44)
	btnClose:setTitleColor(Theme.to_c3b(Theme.COLORS.CLOSE))
	btnClose:setPosition(cc.p(30, 30))
	closeBg:addChild(btnClose)
	Menu.state.btn_close = btnClose
	Menu.state.btn_close_bg = closeBg

	btnClose:addTouchEventListener(function(sender, eventType)
		if eventType == 2 then
			Menu.hide()
		end
	end)
	_log("✓ Buttons created (minimize, close)")

	-- Tab bar
	_log("Creating tab bar...")
	local tabBar = ccui.Layout:create()
	tabBar:setContentSize(cc.size(PANEL_W, Theme.DIMENSIONS.TAB_BAR_H))
	tabBar:setPosition(cc.p(0, PANEL_H - Theme.DIMENSIONS.TITLE_BAR_H - Theme.DIMENSIONS.TAB_BAR_H))
	Theme.apply_bg(tabBar, Theme.BG.TAB_BAR, 255)
	panel:addChild(tabBar)
	Menu.state.tab_bar = tabBar
	_log("✓ Tab bar created")

	-- Content area
	_log("Creating content area...")
	local max_items = 0
	for _, tab in ipairs(Menu.TABS) do
		if #tab.items > max_items then
			max_items = #tab.items
		end
	end
	local contentH = max_items * (Theme.DIMENSIONS.TOGGLE_H + Theme.DIMENSIONS.TOGGLE_SPACING)
		+ Theme.DIMENSIONS.MARGIN * 2

	local contentArea = ccui.Layout:create()
	contentArea:setContentSize(cc.size(PANEL_W, contentH))
	contentArea:setPosition(cc.p(0, Theme.DIMENSIONS.LOG_PANEL_H))
	contentArea:setClippingEnabled(true)
	panel:addChild(contentArea)
	Menu.state.content_area = contentArea
	_log("✓ Content area created (max_items: " .. max_items .. ", height: " .. contentH .. ")")

	-- Tab buttons storage
	local tabBtns = {}
	local tabBgs = {}

	-- Build toggles for a tab
	_log("Setting up buildToggles function...")
	local function buildToggles(tabIndex, silent)
		for _, container in ipairs(Menu.state.toggle_buttons or {}) do
			pcall(function()
				container:removeFromParent()
			end)
		end
		Menu.state.toggle_buttons = {}

		local tab = Menu.TABS[tabIndex]
		if not tab then
			return
		end

		local items = Menu.sort_items_by_type(tab.items)
		local currentW = Menu.state.current_panel_w or PANEL_W
		local btnW = currentW - Theme.DIMENSIONS.MARGIN * 2

		local contentSize = contentArea:getContentSize()
		local contentH = contentSize.height
		local y = contentH - Theme.DIMENSIONS.MARGIN - Theme.DIMENSIONS.TOGGLE_H / 2

		for i, item in ipairs(items) do
			local state = Menu.get_state(item.id) or false

			-- Button container
			local btnContainer = ccui.Layout:create()
			btnContainer:setContentSize(cc.size(btnW, Theme.DIMENSIONS.TOGGLE_H))
			btnContainer:setAnchorPoint(cc.p(0.5, 0.5))
			btnContainer:setPosition(cc.p(currentW / 2, y))

			local bgColor = state and Theme.BG.BTN_ACTIVE or Theme.BG.BTN_NORMAL
			Theme.apply_bg(btnContainer, bgColor, 255)
			contentArea:addChild(btnContainer)

			-- Button
			local btn = ccui.Button:create()
			btn:setTitleFontSize(40)
			btn:setScale9Enabled(true)
			btn:setContentSize(cc.size(btnW, Theme.DIMENSIONS.TOGGLE_H))
			btn:setAnchorPoint(cc.p(0.5, 0.5))
			btn:setPosition(cc.p(btnW / 2, Theme.DIMENSIONS.TOGGLE_H / 2))
			btnContainer:addChild(btn)

			-- Set appearance based on type
			if item.type == "cycle" then
				local index = type(state) == "number" and state or 1
				local label = item.labels and item.labels[index] or Menu.get_label(item)
				local is_on = index > 1
				local prefix = is_on and "● " or "○ "
				btn:setTitleText(prefix .. label)
				btn:setTitleColor(Theme.to_c3b(is_on and Theme.COLORS.ON or Theme.COLORS.OFF))
				if is_on then
					Theme.apply_bg(btnContainer, Theme.BG.BTN_ACTIVE, 255)
				end
			elseif item.type == "action" then
				btn:setTitleText("▶ " .. Menu.get_label(item))
				btn:setTitleColor(Theme.to_c3b(Theme.COLORS.ACTION))
			elseif item.type == "input" or item.type == "input_persistent" then
				btn:setTitleText("✎ " .. Menu.get_label(item))
				btn:setTitleColor(Theme.to_c3b(Theme.COLORS.INPUT))
			else
				Menu.update_button(btn, btnContainer, item, state)
			end

			-- Touch handler
			btn:addTouchEventListener(function(sender, eventType)
				local currentState = Menu.get_state(item.id) or false
				local normalBg = currentState and Theme.BG.BTN_ACTIVE or Theme.BG.BTN_NORMAL

				if eventType == 0 then
					pcall(function()
						Theme.apply_bg(btnContainer, Theme.BG.BTN_HOVER, 255)
						sender:setScale(0.98)
					end)
				elseif eventType == 2 then
					pcall(function()
						sender:setScale(1.0)
					end)

					if item.type == "toggle" then
						Menu.handle_toggle(item, sender, btnContainer)
					elseif item.type == "action" then
						Menu.handle_action(item, sender)
						pcall(function()
							Theme.apply_bg(btnContainer, normalBg, 255)
						end)
					elseif item.type == "cycle" then
						Menu.handle_cycle(item, sender, btnContainer)
					elseif item.type == "input" then
						Menu.handle_input(item, sender)
						pcall(function()
							Theme.apply_bg(btnContainer, normalBg, 255)
						end)
					elseif item.type == "input_persistent" then
						Menu.handle_input_persistent(item, sender)
						pcall(function()
							Theme.apply_bg(btnContainer, normalBg, 255)
						end)
					elseif item.type == "custom" then
						Menu.handle_custom(item, sender, btnContainer)
					end
				elseif eventType == 3 then
					pcall(function()
						sender:setScale(1.0)
						Theme.apply_bg(btnContainer, normalBg, 255)
					end)
				end
			end)

			Menu.state.toggle_buttons[#Menu.state.toggle_buttons + 1] = btnContainer
			y = y - (Theme.DIMENSIONS.TOGGLE_H + Theme.DIMENSIONS.TOGGLE_SPACING)
		end

		if not silent then
			_log("Tab: " .. tab.name .. " (" .. #items .. " items)")
		end
	end

	Menu.state.buildToggles = buildToggles
	_log("✓ buildToggles function ready")

	-- Create tab buttons
	_log("Creating tab buttons...")
	local tabW = PANEL_W / #Menu.TABS
	for i, tab in ipairs(Menu.TABS) do
		_log("  Creating tab " .. i .. ": " .. (tab.name or "unnamed"))
		local tabBg = ccui.Layout:create()
		tabBg:setContentSize(cc.size(tabW - 8, Theme.DIMENSIONS.TAB_BAR_H - 16))
		tabBg:setPosition(cc.p((i - 1) * tabW + 4, 8))
		Theme.apply_bg(tabBg, { r = 40, g = 40, b = 60 }, 255)
		tabBar:addChild(tabBg)
		tabBgs[i] = tabBg

		local tabBtn = ccui.Button:create()
		tabBtn:setTitleText(tab.name)
		tabBtn:setTitleFontSize(36)
		tabBtn:setScale9Enabled(true)
		tabBtn:setContentSize(cc.size(tabW - 8, Theme.DIMENSIONS.TAB_BAR_H - 16))
		tabBtn:setAnchorPoint(cc.p(0, 0))
		tabBtn:setPosition(cc.p(0, 0))
		tabBg:addChild(tabBtn)
		tabBtns[i] = tabBtn

		tabBtn:addTouchEventListener(function(sender, eventType)
			if eventType == 2 then
				Menu.state.current_tab = i
				MENU_STATE.current_tab = i

				for j, tb in ipairs(tabBtns) do
					local isActive = (j == i)
					local c = isActive and Theme.COLORS.TAB_ACTIVE or Theme.COLORS.TAB_INACTIVE
					local bgC = isActive and Theme.BG.TAB_ACTIVE or { r = 40, g = 40, b = 60 }
					pcall(function()
						tb:setTitleColor(Theme.to_c3b(c))
						Theme.apply_bg(tabBgs[j], bgC, 255)
					end)
				end

				buildToggles(i, false)
			end
		end)
	end

	Menu.state.tab_btns = tabBtns
	Menu.state.tab_bgs = tabBgs
	_log("✓ Tab buttons created (" .. #tabBtns .. " tabs)")

	-- Log panel
	_log("Creating log panel...")
	local logSection = ccui.Layout:create()
	logSection:setContentSize(cc.size(PANEL_W - 20, Theme.DIMENSIONS.LOG_PANEL_H - 10))
	logSection:setPosition(cc.p(10, 5))
	Theme.apply_bg(logSection, Theme.BG.LOG, 255)
	logSection:setClippingEnabled(true)
	panel:addChild(logSection)
	Menu.state.log_section = logSection

	-- Log title with collapse toggle
	local logCollapseBtn = ccui.Button:create()
	logCollapseBtn:setTitleText("▶")
	logCollapseBtn:setTitleFontSize(36)
	logCollapseBtn:setTitleColor(Theme.to_c3b(Theme.COLORS.LOG_TITLE))
	logCollapseBtn:setPosition(cc.p(25, Theme.DIMENSIONS.LOG_PANEL_H - 35))
	logSection:addChild(logCollapseBtn)

	local logTitle = ccui.Text:create("Log Output", "Arial", 36)
	logTitle:setTextColor(Theme.to_c4b(Theme.COLORS.LOG_TITLE))
	logTitle:setAnchorPoint(cc.p(0, 0.5))
	logTitle:setPosition(cc.p(50, Theme.DIMENSIONS.LOG_PANEL_H - 35))
	logSection:addChild(logTitle)
	Menu.state.log_title = logTitle

	-- Clear log button
	local btnClear = ccui.Button:create()
	btnClear:setTitleText("Clear")
	btnClear:setTitleFontSize(32)
	btnClear:setTitleColor(Theme.to_c3b(Theme.COLORS.CLEAR_BTN))
	btnClear:setPosition(cc.p(PANEL_W - 120, Theme.DIMENSIONS.LOG_PANEL_H - 35))
	logSection:addChild(btnClear)
	Menu.state.btn_clear = btnClear

	btnClear:addTouchEventListener(
	    function(sender, eventType)
	        if eventType == 2 then
	            Menu.clear_log()
	        end
	    end
	)

	-- Log text (word wrap via width-only constraint, auto-height for tail-f)
	local logVisibleH = Theme.DIMENSIONS.LOG_PANEL_H - 80
	local logTextW = PANEL_W - 50

	-- Clipping container so text never overlaps the title
	local logTextContainer = ccui.Layout:create()
	logTextContainer:setContentSize(cc.size(PANEL_W - 30, logVisibleH))
	logTextContainer:setPosition(cc.p(5, 5))
	logTextContainer:setClippingEnabled(true)
	logSection:addChild(logTextContainer)

	local logText = ccui.Text:create("Loading...", "Arial", 36)
	logText:setTextColor(Theme.to_c4b(Theme.COLORS.LOG_TEXT))
	logText:setTextAreaSize(cc.size(logTextW, 0)) -- width for word wrap, 0 = auto-height
	logText:setAnchorPoint(cc.p(0, 0)) -- bottom-left anchor
	logText:setPosition(cc.p(5, 0)) -- start at bottom of container
	logTextContainer:addChild(logText)
	Menu.state.log_widget = logText

	-- Default: collapsed (hide text + clear button)
	logTextContainer:setVisible(false)
	btnClear:setVisible(false)

	-- Collapse toggle handler
	logCollapseBtn:addTouchEventListener(function(sender, eventType)
	    if eventType == 2 then
	        Menu.state.log_collapsed = not Menu.state.log_collapsed
	        local collapsed = Menu.state.log_collapsed
	        pcall(function()
	            logCollapseBtn:setTitleText(collapsed and "▶" or "▼")
	            logTextContainer:setVisible(not collapsed)
	            btnClear:setVisible(not collapsed)
	        end)
	    end
	end)
	Menu.state.log_collapse_btn = logCollapseBtn
	_log("Log panel created (collapsed by default)")

	-- Resize handle
	_log("Creating resize handle...")
	local resizeHandle = ccui.Layout:create()
	local handleSize = Theme.DIMENSIONS.RESIZE_HANDLE_SIZE or 40
	resizeHandle:setContentSize(cc.size(handleSize, handleSize))
	resizeHandle:setPosition(cc.p(PANEL_W - handleSize, 0))
	Theme.apply_bg(resizeHandle, Theme.BG.RESIZE_HANDLE, 200)
	resizeHandle:setTouchEnabled(true)
	panel:addChild(resizeHandle)
	Menu.state.resize_handle = resizeHandle

	local resizeText = ccui.Text:create("⤡", "Arial", 28)
	resizeText:setTextColor(Theme.to_c4b(Theme.COLORS.RESIZE_GRIP))
	resizeText:setPosition(cc.p(handleSize / 2, handleSize / 2))
	resizeHandle:addChild(resizeText)

	-- Resize handling
	local resizeStart = cc.p(0, 0)
	local startPanelW = PANEL_W
	local startPanelH = PANEL_H

	resizeHandle:addTouchEventListener(
	    function(sender, eventType)
	        if eventType == 0 then
	            resizeStart = sender:getTouchBeganPosition()
	            startPanelW = Menu.state.current_panel_w or PANEL_W
	            startPanelH = Menu.state.current_panel_h or PANEL_H
	            Menu.state.is_resizing = true
	        elseif eventType == 1 and Menu.state.is_resizing then
	            local touch = sender:getTouchMovePosition()
	            local dx = touch.x - resizeStart.x
	            local dy = touch.y - resizeStart.y

	            local newW =
	                math.max(
	                Theme.DIMENSIONS.PANEL_MIN_W or 800,
	                math.min(Theme.DIMENSIONS.PANEL_MAX_W or 2000, startPanelW + dx)
	            )

	            local minH =
	                Theme.DIMENSIONS.TITLE_BAR_H + Theme.DIMENSIONS.TAB_BAR_H + 200 + Theme.DIMENSIONS.LOG_PANEL_H
	            local maxH = 2000
	            local newH = math.max(minH, math.min(maxH, startPanelH + dy))

	            Menu.resize_visual(newW, newH)
	        elseif eventType == 2 then
	            Menu.state.is_resizing = false
	            Menu.resize_full(Menu.state.current_panel_w, Menu.state.current_panel_h)
	        elseif eventType == 3 then
	            Menu.state.is_resizing = false
	        end
	    end
	)
	_log("✓ Resize handle created")

	-- Log refresh (tail -f: newest lines always visible at bottom)
	_log("Setting up log refresh...")
	local lastLogContent = ""
	local function refreshLog()
	    if not Menu.state.log_widget then return end
	    if Menu.state.log_collapsed then return end -- skip when collapsed
	    local content = Menu.read_log_tail(50)
	    if content == lastLogContent then return end -- skip if unchanged
	    lastLogContent = content
	    pcall(function()
	        Menu.state.log_widget:setString(content or "(No logs)")
	        -- Reposition so newest lines (bottom) are always visible
	        local textH = logVisibleH
	        pcall(function()
	            textH = Menu.state.log_widget:getVirtualRendererSize().height
	        end)
	        if textH > logVisibleH then
	            -- Text overflows: anchor bottom of text to bottom of container
	            Menu.state.log_widget:setPosition(cc.p(5, 0))
	        else
	            -- Text fits: position at top of container
	            Menu.state.log_widget:setPosition(cc.p(5, logVisibleH - textH))
	        end
	    end)
	end

	_log("Creating refresh action (interval: " .. tostring(Theme.DIMENSIONS.LOG_REFRESH_INTERVAL) .. ")...")
	local ok_action, err_action =
	    pcall(
	    function()
	        Menu.state.refresh_action =
	            cc.RepeatForever:create(
	            cc.Sequence:create(
	                {
	                    cc.DelayTime:create(Theme.DIMENSIONS.LOG_REFRESH_INTERVAL or 1.0),
	                    cc.CallFunc:create(refreshLog)
	                }
	            )
	        )
	    end
	)

	if not ok_action then
	    _log("ERROR creating refresh action: " .. tostring(err_action))
	else
	    _log("✓ Refresh action created")
	end

	_log("Running refresh action on scene...")
	local ok_run, err_run =
	    pcall(
	    function()
	        scene:runAction(Menu.state.refresh_action)
	    end
	)

	if not ok_run then
	    _log("ERROR running refresh action: " .. tostring(err_run))
	else
	    _log("✓ Log refresh scheduled")
	end

	-- Initialize tab (restore saved or default to 1)
	local init_tab = 1
	local saved = MENU_STATE.current_tab
	if type(saved) == "number" and saved >= 1 and saved <= #Menu.TABS then
		init_tab = saved
	end
	Menu.state.current_tab = init_tab
	MENU_STATE.current_tab = init_tab
	_log("Initializing tab " .. init_tab .. "...")
	pcall(function()
		tabBtns[init_tab]:setTitleColor(Theme.to_c3b(Theme.COLORS.TAB_ACTIVE))
		Theme.apply_bg(tabBgs[init_tab], Theme.BG.TAB_ACTIVE, 255)
	end)
	local ok, err = pcall(function()
		buildToggles(init_tab, false)
	end)
	if not ok then
		_log("ERROR building tab " .. init_tab .. " toggles: " .. tostring(err))
	else
		_log("✓ Tab " .. init_tab .. " initialized with " .. #Menu.TABS[init_tab].items .. " items")
	end

	_log("Refreshing log...")
	local log_ok, log_err = pcall(refreshLog)
	if not log_ok then
		_log("ERROR refreshing log: " .. tostring(log_err))
	end

	_log("=== Menu.create() SUCCESS ===")
	return panel
end

-- ============================================================
-- RESIZE FUNCTIONS
-- ============================================================

function Menu.resize_visual(newW, newH)
	if not Menu.state.panel then
		return
	end

	Menu.state.current_panel_w = newW
	Menu.state.current_panel_h = newH or Menu.state.current_panel_h
	local PANEL_H = Menu.state.current_panel_h

	pcall(function()
		Menu.state.panel:setContentSize(cc.size(newW, PANEL_H))

		if Menu.state.title_bar then
			Menu.state.title_bar:setContentSize(cc.size(newW, Theme.DIMENSIONS.TITLE_BAR_H))
			Menu.state.title_bar:setPosition(cc.p(0, PANEL_H - Theme.DIMENSIONS.TITLE_BAR_H))
			if Menu.state.title_text then
				Menu.state.title_text:setPosition(cc.p(newW / 2, Theme.DIMENSIONS.TITLE_BAR_H / 2))
			end
			if Menu.state.btn_minimize then
				Menu.state.btn_minimize:setPosition(cc.p(newW - 140, Theme.DIMENSIONS.TITLE_BAR_H / 2))
			end
			if Menu.state.btn_close_bg then
				Menu.state.btn_close_bg:setPosition(cc.p(newW - 50, Theme.DIMENSIONS.TITLE_BAR_H / 2))
			end
		end

		if Menu.state.tab_bar then
			Menu.state.tab_bar:setContentSize(cc.size(newW, Theme.DIMENSIONS.TAB_BAR_H))
			Menu.state.tab_bar:setPosition(cc.p(0, PANEL_H - Theme.DIMENSIONS.TITLE_BAR_H - Theme.DIMENSIONS.TAB_BAR_H))

			local tabW = newW / #Menu.TABS
			for i, tabBg in ipairs(Menu.state.tab_bgs) do
				if tabBg then
					tabBg:setContentSize(cc.size(tabW - 8, Theme.DIMENSIONS.TAB_BAR_H - 16))
					tabBg:setPosition(cc.p((i - 1) * tabW + 4, 8))
					local tabBtn = Menu.state.tab_btns[i]
					if tabBtn then
						tabBtn:setContentSize(cc.size(tabW - 8, Theme.DIMENSIONS.TAB_BAR_H - 16))
					end
				end
			end
		end

		if Menu.state.content_area then
			local contentH = PANEL_H
				- Theme.DIMENSIONS.TITLE_BAR_H
				- Theme.DIMENSIONS.TAB_BAR_H
				- Theme.DIMENSIONS.LOG_PANEL_H
			Menu.state.content_area:setContentSize(cc.size(newW, contentH))
			Menu.state.content_area:setPosition(cc.p(0, Theme.DIMENSIONS.LOG_PANEL_H))

			local btnW = newW - Theme.DIMENSIONS.MARGIN * 2
			local startY = contentH - Theme.DIMENSIONS.MARGIN - Theme.DIMENSIONS.TOGGLE_H / 2

			for i, container in ipairs(Menu.state.toggle_buttons or {}) do
				if container then
					local newY = startY - (i - 1) * (Theme.DIMENSIONS.TOGGLE_H + Theme.DIMENSIONS.TOGGLE_SPACING)
					container:setContentSize(cc.size(btnW, Theme.DIMENSIONS.TOGGLE_H))
					container:setPosition(cc.p(newW / 2, newY))

					local children = container:getChildren()
					if children and #children > 0 then
						local btn = children[1]
						if btn then
							btn:setContentSize(cc.size(btnW, Theme.DIMENSIONS.TOGGLE_H))
							btn:setPosition(cc.p(btnW / 2, Theme.DIMENSIONS.TOGGLE_H / 2))
						end
					end
				end
			end
		end

		if Menu.state.log_section then
			local logW = newW - 20
			local logH = Theme.DIMENSIONS.LOG_PANEL_H - 10
			Menu.state.log_section:setContentSize(cc.size(logW, logH))

			if Menu.state.btn_clear then
				Menu.state.btn_clear:setPosition(cc.p(newW - 120, Theme.DIMENSIONS.LOG_PANEL_H - 35))
			end

			if Menu.state.log_widget then
				Menu.state.log_widget:setTextAreaSize(cc.size(newW - 50, Theme.DIMENSIONS.LOG_PANEL_H - 80))
			end
		end

		if Menu.state.resize_handle then
			local handleSize = Theme.DIMENSIONS.RESIZE_HANDLE_SIZE or 40
			Menu.state.resize_handle:setPosition(cc.p(newW - handleSize, 0))
		end
	end)
end

function Menu.resize_full(newW, newH)
	Menu.resize_visual(newW, newH)

	if Menu.state.buildToggles then
		Menu.state.buildToggles(Menu.state.current_tab, true)
	end
end

-- ============================================================
-- PUBLIC API
-- ============================================================

function Menu.show(scene)
	MENU_STATE.api = Menu
	if Menu.state.panel then
		pcall(function()
			Menu.state.panel:setVisible(true)
		end)
	else
		Menu.create(scene)
	end
end

function Menu.hide()
	MENU_STATE.api = nil
	-- Cleanup function
	if Menu.state.cleanup_drag then
		pcall(Menu.state.cleanup_drag)
		Menu.state.cleanup_drag = nil
	end

	if Menu.state.panel then
		pcall(function()
			Menu.state.panel:removeFromParent()
		end)
		Menu.state.panel = nil
	end
	if Menu.state.refresh_action then
		pcall(function()
			local scene = cc.Director:getInstance():getRunningScene()
			if scene then
				scene:stopAction(Menu.state.refresh_action)
			end
		end)
		Menu.state.refresh_action = nil
	end
	_log("Menu hidden")
end

function Menu.toggle_minimize()
	if not Menu.state.panel then
		return
	end

	Menu.state.is_minimized = not Menu.state.is_minimized

	pcall(function()
		if Menu.state.is_minimized then
			if Menu.state.tab_bar then
				Menu.state.tab_bar:setVisible(false)
			end
			if Menu.state.content_area then
				Menu.state.content_area:setVisible(false)
			end
			if Menu.state.log_section then
				Menu.state.log_section:setVisible(false)
			end
			if Menu.state.resize_handle then
				Menu.state.resize_handle:setVisible(false)
			end

			Menu.state.panel:setContentSize(cc.size(Menu.state.current_panel_w, Theme.DIMENSIONS.TITLE_BAR_H))
			Menu.state.title_bar:setPosition(cc.p(0, 0))

			_log("Minimized")
		else
			if Menu.state.tab_bar then
				Menu.state.tab_bar:setVisible(true)
			end
			if Menu.state.content_area then
				Menu.state.content_area:setVisible(true)
			end
			if Menu.state.log_section then
				Menu.state.log_section:setVisible(true)
			end
			if Menu.state.resize_handle then
				Menu.state.resize_handle:setVisible(true)
			end

			local PANEL_H = Menu.state.current_panel_h or Menu.state.saved_panel_h
			Menu.state.panel:setContentSize(cc.size(Menu.state.current_panel_w, PANEL_H))
			Menu.state.title_bar:setPosition(cc.p(0, PANEL_H - Theme.DIMENSIONS.TITLE_BAR_H))

			if Menu.state.tab_bar then
				Menu.state.tab_bar:setPosition(
					cc.p(0, PANEL_H - Theme.DIMENSIONS.TITLE_BAR_H - Theme.DIMENSIONS.TAB_BAR_H)
				)
			end

			_log("Restored")
		end
	end)

	Menu.update_minimize_icon()
end

function Menu.is_visible()
	return Menu.state.panel ~= nil
end

return Menu
