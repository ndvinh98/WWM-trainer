-- ============================================================
-- COCOS.LUA - Cocos2d-x helper functions
-- ============================================================
-- Functions not available in the game runtime.

local Cocos = {}

function Cocos.get_running_scene()
	local ok, scene = pcall(function()
		return cc.Director:getInstance():getRunningScene()
	end)
	if ok and scene then
		return scene
	end
	return nil
end

function Cocos.delay_call(delay_seconds, func)
	local scene = Cocos.get_running_scene()
	if not scene then
		return false
	end

	local action = cc.Sequence:create({
		cc.DelayTime:create(delay_seconds),
		cc.CallFunc:create(func),
	})
	scene:runAction(action)
	return true
end

function Cocos.create_empty_proxy()
	local proxy = {}
	local mt = {
		__index = function()
			return proxy
		end,
		__newindex = function() end,
		__call = function()
			return proxy
		end,
		__tostring = function()
			return "EmptyProxy"
		end,
		__len = function()
			return 0
		end,
	}
	setmetatable(proxy, mt)
	return proxy
end

return Cocos
