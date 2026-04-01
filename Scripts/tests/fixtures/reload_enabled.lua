local ActionBase = _G.Reg.lib("ActionBase")

local ReloadEnabled = ActionBase:extend("tests.fixtures.reload_enabled")

function ReloadEnabled:define_state()
	return {
		persistent = { enabled = false, log_enabled = true },
		transient = { timer_started = false },
	}
end

function ReloadEnabled:define_hooks()
	return {}
end

function ReloadEnabled:enable()
	if self.state.enabled then
		return true
	end
	self.state.enabled = true
	self.state.timer_started = true
	self:log("Enabled")
	return true
end

function ReloadEnabled:disable()
	if not self.state.enabled then
		return true
	end
	self.state.enabled = false
	self.state.timer_started = false
	self:log("Disabled")
	return true
end

function ReloadEnabled:is_enabled()
	return self.state.enabled
end

return ReloadEnabled:new()
