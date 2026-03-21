-- Debug script: Inject into game to diagnose dump_bytecode issues
-- Usage: dofile('C:/temp/Where Winds Meet/Scripts/tests/debug_dump_bytecode.lua')

local _ROOT = "C:\\temp\\Where Winds Meet\\Scripts"
local LOG_PATH = _ROOT .. "\\logs\\debug_dump_bytecode.txt"

local _output = {}
local function _log(msg)
	local line = tostring(msg)
	_output[#_output + 1] = line
	print(line)
end

local function _flush()
	local f = io.open(LOG_PATH, "w")
	if f then
		f:write(table.concat(_output, "\n") .. "\n")
		f:close()
	end
end

_log("=== DEBUG DUMP BYTECODE ===")
_log("Time: " .. os.date("%Y-%m-%d %H:%M:%S"))

-- Step 1: Check Reg
_log("\n--- Step 1: Check _G.Reg ---")
_log("_G.Reg = " .. tostring(_G.Reg))
if not _G.Reg then
	_log("FATAL: _G.Reg is nil, cannot proceed")
	_flush()
	return
end

-- Step 2: Load the module
_log("\n--- Step 2: Load dump_bytecode module ---")
local Constants = _G.Reg.lib("Constants")
_log("Constants = " .. tostring(Constants))
_log("Constants.SCRIPTS_ROOT = " .. tostring(Constants and Constants.SCRIPTS_ROOT))
_log("Constants.LUA_DEBUGGING_ROOT = " .. tostring(Constants and Constants.LUA_DEBUGGING_ROOT))

local path = Constants.SCRIPTS_ROOT .. "\\actions\\dump_bytecode.lua"
_log("Loading from: " .. path)
local load_ok, load_err = pcall(dofile, path)
_log("Load result: ok=" .. tostring(load_ok) .. " err=" .. tostring(load_err))

local Dump = _G.Reg.module("actions.dump_bytecode")
_log("Module from Reg: " .. tostring(Dump))

if not Dump then
	_log("FATAL: dump_bytecode module not registered")
	_flush()
	return
end

-- Step 3: Check key methods
_log("\n--- Step 3: Check methods ---")
_log("dump_all_async = " .. tostring(Dump.dump_all_async))
_log("stop_dump = " .. tostring(Dump.stop_dump))
_log("is_running = " .. tostring(Dump.is_running))
_log("state = " .. tostring(Dump.state))
_log("state._is_running = " .. tostring(Dump.state and Dump.state._is_running))

-- Step 4: Check package.searchers / package.loaders
_log("\n--- Step 4: Check engine searcher ---")
_log("package.searchers = " .. tostring(package.searchers))
_log("package.loaders = " .. tostring(package.loaders))

if package.searchers then
	_log("package.searchers count = " .. #package.searchers)
	for i, s in ipairs(package.searchers) do
		_log("  searchers[" .. i .. "] = " .. type(s) .. " " .. tostring(s))
	end
elseif package.loaders then
	_log("package.loaders count = " .. #package.loaders)
	for i, s in ipairs(package.loaders) do
		_log("  loaders[" .. i .. "] = " .. type(s) .. " " .. tostring(s))
	end
else
	_log("WARNING: Neither package.searchers nor package.loaders exist!")
end

local searcher = Dump:_get_engine_searcher()
_log("_get_engine_searcher() = " .. tostring(searcher))

-- Step 5: Check running scene
_log("\n--- Step 5: Check running scene ---")
local Cocos = _G.Reg.lib("Cocos")
_log("Cocos = " .. tostring(Cocos))
if Cocos then
	_log("Cocos.get_running_scene = " .. tostring(Cocos.get_running_scene))
	if Cocos.get_running_scene then
		local scene_ok, scene = pcall(Cocos.get_running_scene)
		_log("get_running_scene: ok=" .. tostring(scene_ok) .. " scene=" .. tostring(scene))
	end
end

local scene = Dump:_get_running_scene()
_log("_get_running_scene() = " .. tostring(scene))

-- Step 6: Check cc globals for action creation
_log("\n--- Step 6: Check cc globals ---")
_log("cc = " .. tostring(cc))
if cc then
	_log("cc.RepeatForever = " .. tostring(cc.RepeatForever))
	_log("cc.Sequence = " .. tostring(cc.Sequence))
	_log("cc.DelayTime = " .. tostring(cc.DelayTime))
	_log("cc.CallFunc = " .. tostring(cc.CallFunc))
end

-- Step 7: Check module list
_log("\n--- Step 7: Build module list ---")
local modules = Dump:_build_module_list()
_log("Module count: " .. #modules)
if #modules > 0 then
	_log("First 10:")
	for i = 1, math.min(10, #modules) do
		_log("  " .. modules[i])
	end
end

-- Step 8: Actually call dump_all_async
_log("\n--- Step 8: Call dump_all_async ---")
local progress_count = 0
local complete_called = false

local call_ok, result, err_msg = pcall(Dump.dump_all_async, Dump, {
	batch_size = 3,
	delay_ms = 100,
	on_progress = function(current, total, name)
		progress_count = progress_count + 1
		if progress_count <= 5 then
			_log("[PROGRESS] " .. current .. "/" .. total .. " " .. tostring(name))
		end
	end,
	on_complete = function(count, errors)
		complete_called = true
		_log("[COMPLETE] count=" .. tostring(count) .. " errors=" .. tostring(errors))
	end,
})

_log("pcall ok = " .. tostring(call_ok))
_log("result = " .. tostring(result))
_log("err_msg = " .. tostring(err_msg))
_log("progress callbacks received so far = " .. progress_count)
_log("complete_called = " .. tostring(complete_called))

-- Step 9: Check state after call
_log("\n--- Step 9: Post-call state ---")
_log("is_running = " .. tostring(Dump:is_running()))
local progress = Dump:get_progress()
if progress then
	_log("progress.running = " .. tostring(progress.running))
	_log("progress.current = " .. tostring(progress.current))
	_log("progress.total = " .. tostring(progress.total))
	_log("progress.count = " .. tostring(progress.count))
	_log("progress.skipped = " .. tostring(progress.skipped))
	_log("progress.errors = " .. tostring(progress.errors))
else
	_log("progress = nil (not running)")
end

_log("\n=== DONE ===")
_flush()
_log("Results saved to: " .. LOG_PATH)
