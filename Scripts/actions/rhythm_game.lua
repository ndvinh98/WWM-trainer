-- Scripts/actions/rhythm_game.lua
local ActionBase = _G.Reg.lib("ActionBase")

local RhythmGame = ActionBase:extend("actions.rhythm_game")

-- ── Constants ──
local NOTE_RESULT_PERFECT = 5

function RhythmGame:define_state()
	return {
		persistent = { auto_perfect = false, enable_logging = true },
		transient = {},
	}
end

function RhythmGame:define_hooks()
	return {
		auto_perfect_result = {
			spec = "hexm.client.consts.rhythm_game_consts:note_result_by_time_with_column",
			override_orig_function = true,
			post_exec = function(self_action, original, diff, column_name_idx, is_key, mode)
				if self_action.state.enable_logging then
					self_action:log(
						string.format(
							"[HOOK] note_result_by_time_with_column(diff=%.3f, col=%s, is_key=%s, mode=%s) → PERFECT",
							diff or 0,
							tostring(column_name_idx),
							tostring(is_key),
							tostring(mode)
						)
					)
				end
				return NOTE_RESULT_PERFECT, 0
			end,
		},
	}
end

-- ── Lifecycle ──

function RhythmGame:on_enable()
	self:log("Module enabled")
	if self.state.auto_perfect then
		self:_apply_auto_perfect(true)
	end
end

function RhythmGame:on_disable()
	self:_apply_auto_perfect(false)
	self.state.auto_perfect = false
	self:log("Module disabled")
end

function RhythmGame:on_reload()
	self:log("Module reloaded, auto_perfect=" .. tostring(self.state.auto_perfect))
	if self.state.auto_perfect then
		self:_apply_auto_perfect(true)
	end
end

-- ── Internal ──

function RhythmGame:_apply_auto_perfect(enabled)
	-- G in game code = require("hexm.client.G"), NOT Lua's _G
	local game_G = G or (portable and portable.import_G and portable.import_G())
	if not game_G then
		self:log("ERROR: Cannot access game G object")
		return
	end

	if enabled then
		-- Hook scoring to always return PERFECT
		self:hook("auto_perfect_result")
		-- Enable game's built-in auto-play flag (dropdown_rhythm_game_player.lua:290)
		-- This makes the game auto-trigger _rhythm_game_note_input for each note
		game_G.RHYTHM_GAME_AUTO_PLAY = true
		self:log("Hooks ON + G.RHYTHM_GAME_AUTO_PLAY = true (on game G object)")
	else
		self:unhook("auto_perfect_result")
		game_G.RHYTHM_GAME_AUTO_PLAY = nil
		self:log("Hooks OFF + G.RHYTHM_GAME_AUTO_PLAY = nil")
	end
end

-- ── Public API ──

function RhythmGame:set_auto_perfect(enabled)
	self.state.auto_perfect = enabled
	self:_apply_auto_perfect(enabled)
	self:log("Auto-Perfect: " .. (enabled and "ON" or "OFF"))
end

return RhythmGame:new()
