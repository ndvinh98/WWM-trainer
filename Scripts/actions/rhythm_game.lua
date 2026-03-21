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
			post_exec = function(self_action, original, ...)
				return NOTE_RESULT_PERFECT, 0
			end,
		},
	}
end

-- ── Lifecycle ──

function RhythmGame:on_enable()
	if self.state.auto_perfect then
		self:hook("auto_perfect_result")
	end
end

function RhythmGame:on_disable()
	self:unhook("auto_perfect_result")
	self.state.auto_perfect = false
end

function RhythmGame:on_reload()
	if self.state.auto_perfect then
		self:hook("auto_perfect_result")
	end
end

-- ── Public API ──

function RhythmGame:set_auto_perfect(enabled)
	self.state.auto_perfect = enabled
	if enabled then
		self:hook("auto_perfect_result")
	else
		self:unhook("auto_perfect_result")
	end
	self:log("Auto-Perfect: " .. (enabled and "ON" or "OFF"))
end

return RhythmGame:new()
