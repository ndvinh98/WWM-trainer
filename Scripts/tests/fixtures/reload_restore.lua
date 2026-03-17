local ActionBase = _G.Reg.lib("ActionBase")

local ReloadRestore = ActionBase:extend("tests.fixtures.reload_restore")

function ReloadRestore:define_state()
	return {
		persistent = { marker = 0 },
		transient = {},
	}
end

function ReloadRestore:define_hooks()
	return {
		test_hook = {
			spec = "hexm.client.ui.base.text:Text:set_text",
			post_exec = function() end,
		},
	}
end

return ReloadRestore:new()
