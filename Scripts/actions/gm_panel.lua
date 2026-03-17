-- Scripts/actions/gm_panel.lua
local ActionBase = _G.Reg.lib("ActionBase")

local GMPanel = ActionBase:extend("actions.gm_panel")

-- Config
local Constants = _G.Reg.lib("Constants")
local DICT_PATH = Constants.SCRIPTS_ROOT .. "\\data\\gm_dict.txt"

-- Module paths
local MODULE_TEXT = "hexm.client.ui.base.text"
local MODULE_GM_SHORTCUT = "hexm.client.ui.windows.gm.gm_shortcut_window"

-- ============================================================
-- String helpers (local closures)
-- ============================================================

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

-- ============================================================
-- STATE
-- ============================================================

function GMPanel:define_state()
	return {
		persistent = {
			translation_enabled = true,
			capture_enabled = false,
		},
		transient = {
			translations = {},
			written_keys = {},
		},
	}
end

-- ============================================================
-- HOOKS
-- ============================================================

function GMPanel:define_hooks()
	return {
		text_set_text = {
			spec = MODULE_TEXT .. ":Text:set_text",
			override_orig_function = true,
			post_exec = function(self_action, original, self_text, s, unable)
				local success, call_err = pcall(function()
					self_action:_register_string(s)
					local translated = self_action:_translate(s)
					if translated == s then
						self_action:log("set_text: No translation for: " .. tostring(s))
					end
					original(self_text, translated, unable)
				end)
				if not success then
					self_action:log("set_text ERROR: " .. tostring(call_err))
					original(self_text, s, unable)
				end
			end,
		},
	}
end

-- ============================================================
-- DICT MANAGEMENT
-- ============================================================

function GMPanel:_load_dict()
	self:log("load_dict: Opening " .. DICT_PATH)
	local f = io.open(DICT_PATH, "r")
	if not f then
		self:log("load_dict: FAILED to open dict file")
		return
	end
	local count = 0
	for line in f:lines() do
		local key, val = line:match('%["(.-)"%]%s*=%s*"(.-)"')
		if key then
			self.state.written_keys[key] = true
			if val ~= "" then
				val = normalize_translation_quotes(val)
				self.state.translations[unescape(key)] = unescape(val)
				count = count + 1
			end
		end
	end
	f:close()
	self:log("load_dict: Loaded " .. count .. " translations")
end

function GMPanel:_register_string(s)
	if not self.state.capture_enabled or type(s) ~= "string" or s == "" then
		return
	end
	local esc = escape(s)
	if self.state.written_keys[esc] then
		return
	end
	self.state.written_keys[esc] = true
	local f = io.open(DICT_PATH, "a")
	if f then
		f:write(string.format('["%s"] = "",\n', esc))
		f:close()
	end
end

function GMPanel:_translate(s)
	if not self.state.translation_enabled then
		return s
	end
	return self.state.translations[s] or s
end

-- ============================================================
-- PUBLIC API
-- ============================================================

function GMPanel:enable_translator()
	self:log("enable_translator: Starting...")

	if self:is_hooked("text_set_text") then
		self:log("enable_translator: Already installed, skipping")
		return
	end

	self:_load_dict()
	self:log("enable_translator: Loaded translations")

	self:hook("text_set_text")
	self:log("enable_translator: Hook installed")
end

function GMPanel:disable_translator()
	self:unhook("text_set_text")
	self:log("Translator disabled")
end

function GMPanel:open()
	self:log("Opening GM Panel...")

	local ok, err = pcall(function()
		local GmShortcutWindow = require(MODULE_GM_SHORTCUT).GmShortcutWindow
		G.ui_manager:get_or_load_window(GmShortcutWindow)
	end)
	if not ok then
		self:log("Failed to open GM Panel: " .. tostring(err))
		return false
	end

	return true
end

function GMPanel:close()
	self:disable_translator()
	return true
end

function GMPanel:set_translation(enabled)
	self.state.translation_enabled = enabled
end

function GMPanel:set_capture(enabled)
	self.state.capture_enabled = enabled
end

return GMPanel:new()
