-- ============================================================
-- GM_PANEL.LUA - GM Panel & Translator
-- ============================================================
-- Prerequisites: Bootstrap must be loaded first

local GMPanel = {}

-- Reference libs via Reg (loaded once by bootstrap)
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Utils = Reg.get("Utils")
local Hooks = Reg.get("Hooks")

local function _log(msg)
	Logger.log("[GM] " .. msg)
end

-- Config
local DICT_PATH = Constants.SCRIPTS_ROOT .. "\\data\\gm_dict.txt"
local ENABLE_TRANSLATION = true
local ENABLE_CAPTURE = false

-- State
local TRANSLATIONS = {}
local WRITTEN_KEYS = {}

-- Hook IDs
local HOOK_TEXT_SET_TEXT = "gm_text_set_text"
local HOOK_GM_BEFORE_CREATE = "gm_before_create"
local HOOK_CHECK_NEED_GM = "gm_check_need_gm"

-- Module paths
local MODULE_TEXT = "hexm.client.ui.base.text"
local MODULE_GM_SHORTCUT = "hexm.client.ui.windows.gm.gm_shortcut_window"
local MODULE_UI_MANAGER = "hexm.client.ui.manager.ui_manager"
local MODULE_GM_DECORATOR = "hexm.client.debug.hex.gm_decorator"

-- String helpers
local function escape(s)
	return s:gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub('"', '\\"')
end

local function unescape(s)
	s = s:gsub("\\\\", "\0")
	s = s:gsub("\\n", "\n")
	s = s:gsub("\\r", "\r")
	s = s:gsub('\\"', '"')
	s = s:gsub("\0", "\\")
	return s
end

local function normalize_translation_quotes(s)
	if s:find('"', 1, true) then
		s = s:gsub('"', "'")
	end
	return s
end

local function load_dict()
	_log("load_dict: Opening " .. DICT_PATH)
	local f = io.open(DICT_PATH, "r")
	if not f then
		_log("load_dict: FAILED to open dict file")
		return
	end
	local count = 0
	for line in f:lines() do
		local key, val = line:match('%["(.-)"%]%s*=%s*"(.-)"')
		if key then
			WRITTEN_KEYS[key] = true
			if val ~= "" then
				val = normalize_translation_quotes(val)
				TRANSLATIONS[unescape(key)] = unescape(val)
				count = count + 1
			end
		end
	end
	f:close()
	_log("load_dict: Loaded " .. count .. " translations")
end

local function register_string(s)
	if not ENABLE_CAPTURE or type(s) ~= "string" or s == "" then
		return
	end
	local esc = escape(s)
	if WRITTEN_KEYS[esc] then
		return
	end
	WRITTEN_KEYS[esc] = true
	local f = io.open(DICT_PATH, "a")
	if f then
		f:write(string.format('["%s"] = "",\n', esc))
		f:close()
	end
end

local function translate(s)
	if not ENABLE_TRANSLATION then
		return s
	end
	return TRANSLATIONS[s] or s
end

local function enable_translator()
	_log("enable_translator: Starting...")

	if Hooks.is_hooked(HOOK_TEXT_SET_TEXT) then
		_log("enable_translator: Already installed, skipping")
		return
	end

	load_dict()
	_log("enable_translator: Loaded translations")

	-- Hook Text.set_text using override_exec for full control with error handling
	local ok, err = Hooks.hook_method(HOOK_TEXT_SET_TEXT, MODULE_TEXT, "Text", "set_text", {
		override_exec = function(orig, self, s, unable)
			local success, call_err = pcall(function()
				register_string(s)
				local translated = translate(s)
				if translated == s then
					_log("set_text: No translation for: " .. tostring(s))
				end
				orig(self, translated, unable)
			end)
			if not success then
				_log("set_text ERROR: " .. tostring(call_err))
				orig(self, s, unable)
			end
		end,
	})

	if ok then
		_log("enable_translator: Hook installed successfully")
	else
		_log("enable_translator: FAILED - " .. tostring(err))
	end
end

local function disable_translator()
	Hooks.unhook(HOOK_TEXT_SET_TEXT)
	_log("Translator disabled")
end

function GMPanel.open()
	_log("Opening GM Panel...")

	local ok, err = pcall(function() 
		-- local GmWindow = require("hexm.client.ui.windows.gm.gm_window").GmWindow
		-- G.ui_manager:get_or_load_window(GmWindow)

		-- local GmSkipWindow = require("hexm.client.ui.windows.gm.gm_skip_window").GmSkipWindow
		-- local win = G.ui_manager:get_or_load_window(GmSkipWindow)
		-- local screen_size = G.ui_manager:get_screen_size()
		-- win:auto_set_win_pos_by_world_pos({
		-- 	x = screen_size.width / 2,
		-- 	y = screen_size.height,
		-- })
		local GmShortcutWindow = require("hexm.client.ui.windows.gm.gm_shortcut_window").GmShortcutWindow
		G.ui_manager:get_or_load_window(GmShortcutWindow)

	end)
	if not ok then
		_log("Failed to open GM Panel: " .. tostring(err))
		return false
	end

	return true
end

function GMPanel.close()
	disable_translator()
	return true
end

function GMPanel.set_translation(enabled)
	ENABLE_TRANSLATION = enabled
end

function GMPanel.set_capture(enabled)
	ENABLE_CAPTURE = enabled
end

return GMPanel
