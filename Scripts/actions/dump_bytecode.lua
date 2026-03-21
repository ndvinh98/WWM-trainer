local ActionBase = _G.Reg.lib("ActionBase")
local Constants = _G.Reg.lib("Constants")

local DumpBytecode = ActionBase:extend("actions.dump_bytecode")

local FSUtils = dofile(Constants.LIB_ROOT .. "\\fs_utils.lua")
local STATE = _G.Reg.state("actions.dump_bytecode.async")

function DumpBytecode:define_state()
	return {
		persistent = {log_enabled = true},
		transient = {
			_is_running = false,
		},
	}
end

function DumpBytecode:define_hooks()
	return {}
end

function DumpBytecode:_get_running_scene()
	local cocos = _G.Reg and _G.Reg.lib("Cocos")
	if not cocos or not cocos.get_running_scene then
		return nil
	end
	return cocos.get_running_scene()
end

function DumpBytecode:_get_engine_searcher()
	return package.searchers and package.searchers[2] or nil
end

function DumpBytecode:_get_state()
	return STATE.job
end

function DumpBytecode:_set_state(state)
	STATE.job = state
end

function DumpBytecode:_clear_state()
	STATE.job = nil
	self.state._is_running = false
end

function DumpBytecode:_build_module_list()
	local modules = {}
	for name, mod in pairs(package.loaded) do
		if type(name) == "string" and mod ~= nil and name ~= "_G" and name ~= "package" then
			modules[#modules + 1] = name
		end
	end
	table.sort(modules)
	return modules
end

function DumpBytecode:get_output_dir()
	return Constants.LUA_DEBUGGING_ROOT
end

function DumpBytecode:get_output_path_for_module(module_path)
	return FSUtils.get_module_output_path(module_path, self:get_output_dir(), ".luac")
end

function DumpBytecode:dump_all_async(options)
	if self.state._is_running then
		return false, "Already running"
	end

	options = options or {}

	local engine_searcher = self:_get_engine_searcher()
	if not engine_searcher then
		return false, "No engine searcher"
	end

	local scene = self:_get_running_scene()
	if not scene then
		return false, "No running scene"
	end

	local output_dir = options.output_dir or self:get_output_dir()
	FSUtils.ensure_dir(output_dir)

	local state = {
		running = true,
		modules = self:_build_module_list(),
		current_index = 1,
		total = 0,
		count = 0,
		errors = 0,
		skipped = 0,
		start_time = os.clock(),
		batch_size = options.batch_size or 5,
		delay_sec = (options.delay_ms or 50) / 1000,
		output_dir = output_dir,
		skip_existing = options.skip_existing ~= false, -- default true
		action_ref = nil,
		on_progress = options.on_progress or function() end,
		on_complete = options.on_complete or function() end,
	}
	state.total = #state.modules
	self:_set_state(state)

	local function stop_internal()
		local current = self:_get_state()
		if not current then
			return
		end

		if current.action_ref then
			local active_scene = self:_get_running_scene()
			if active_scene then
				active_scene:stopAction(current.action_ref)
			end
		end

		self:_clear_state()
	end

	local function process_batch()
		local current = self:_get_state()
		if not current or not current.running then
			return
		end

		local batch_end = math.min(current.current_index + current.batch_size - 1, current.total)
		for i = current.current_index, batch_end do
			local module_name = current.modules[i]
			current.on_progress(i, current.total, module_name)

			local ok, err = pcall(function()
				local output_path = FSUtils.get_module_output_path(module_name, current.output_dir, ".luac")

				-- Skip if file already exists on disk
				if current.skip_existing and output_path and FSUtils.path_exists(output_path) then
					current.skipped = current.skipped + 1
					return
				end

				local loader = engine_searcher(module_name)
				if type(loader) ~= "function" then
					current.skipped = current.skipped + 1
					return
				end

				local dump_ok, bytecode = pcall(string.dump, loader)
				if not dump_ok or not bytecode or #bytecode == 0 then
					current.skipped = current.skipped + 1
					return
				end

				FSUtils.ensure_parent_dir(output_path)

				local file = io.open(output_path, "wb")
				if not file then
					current.errors = current.errors + 1
					return
				end

				file:write(bytecode)
				file:close()
				current.count = current.count + 1
			end)

			if not ok then
				current.errors = current.errors + 1
				self:log("[BytecodeDump] ERROR: " .. tostring(module_name) .. " - " .. tostring(err))
			end
		end

		current.current_index = batch_end + 1
		if current.current_index > current.total then
			current.running = false
			self:log(
				string.format(
					"[BytecodeDump] Complete: %d dumped, %d skipped, %d errors",
					current.count,
					current.skipped,
					current.errors
				)
			)
			current.on_complete(current.count, current.errors)
			stop_internal()
		end
	end

	local action = cc.RepeatForever:create(cc.Sequence:create({
		cc.DelayTime:create(state.delay_sec),
		cc.CallFunc:create(process_batch),
	}))
	scene:runAction(action)
	state.action_ref = action

	self.state._is_running = true
	self:log("[BytecodeDump] Started")
	process_batch()
	return true
end

function DumpBytecode:stop_dump()
	local state = self:_get_state()
	if not state then
		return false, "Not running"
	end

	if state.action_ref then
		local scene = self:_get_running_scene()
		if scene then
			scene:stopAction(state.action_ref)
		end
	end

	self:_clear_state()
	return true
end

function DumpBytecode:is_running()
	local state = self:_get_state()
	local running = state ~= nil and state.running == true
	self.state._is_running = running
	return running
end

function DumpBytecode:get_progress()
	local state = self:_get_state()
	if not state then
		return nil
	end

	return {
		running = state.running,
		current = state.current_index - 1,
		total = state.total,
		count = state.count,
		skipped = state.skipped,
		errors = state.errors,
		elapsed = os.clock() - state.start_time,
	}
end

return DumpBytecode:new()
