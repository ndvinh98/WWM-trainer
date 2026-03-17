-- ============================================================
-- ANTICHEAT_BYPASS.LUA - Anti-Cheat Bypass & Network Monitor
-- ============================================================
-- Covers all anticheat layers identified in the engine analysis:
--   1. SA-log telemetry pipeline (BaseLog, SALogHandler, drpf_config)
--   2. ACSDK remote service integration (imp_anticheat)
--   3. Client-side inspection: player, common entity, PVP (imp_inspection, imp_pvp_log)
--   4. Combat damage consistency checker (damage_stats_manager)
--   5. Native anticheat hooks (MHexAC, MQSec) via Engine
--   6. Space-gated inspection enablement (SpaceTag)
--   7. Trace telemetry
--   8. QData log pipeline
-- ============================================================

local AntiCheatBypass = {}

-- ============================================================
-- DEPENDENCIES
-- ============================================================
local Reg = _G.Reg
local Logger = Reg.lib("Logger")
local Constants = Reg.lib("Constants")
local Serialize = Reg.lib("Serialize")
local Cocos = Reg.lib("Cocos")
local _state = Reg.state("lib.anticheat_bypass")
_state.is_enabled = _state.is_enabled or false
_state.logging = _state.logging or false
_state.intercepted_logs = _state.intercepted_logs or {}
_state.originals = _state.originals or {}
_state.cached_modules = _state.cached_modules or {}

local function _log(msg)
	if _state.logging then
		-- Logger.log("[AntiCheat] " .. msg)
	end
end

-- ============================================================
-- SAVE / RESTORE HELPERS
-- ============================================================
-- Record the current rawget value before overwriting so it can be
-- restored later.  Safe to call with any non-nil table.
local function _save_orig(tbl, key)
	_state.originals[#_state.originals + 1] = {
		tbl = tbl,
		key = key,
		val = rawget(tbl, key),
	}
end

-- Walk the snapshot list in reverse and put every value back.
-- Clears the list and resets is_enabled so enable() can run again.
local function restore_originals()
	local n = #_state.originals
	_log("[Restore] Restoring " .. n .. " original values")
	for i = n, 1, -1 do
		local e = _state.originals[i]
		rawset(e.tbl, e.key, e.val)
	end
	_state.originals = {}
	_state.is_enabled = false
	_log("[Restore] Done — all patches removed")
end

-- ============================================================
-- MODULE REGISTRATION
-- ============================================================
local function register_orig_module(module_name)
	if _state.cached_modules[module_name] then
		return _state.cached_modules[module_name]
	end

	local module = portable.safe_import(module_name)
	if module then
		_state.cached_modules[module_name] = module
	else
		_log("Failed to import module '" .. module_name .. "'")
	end

	return module
end

-- ============================================================
-- REPLACEMENT BUILDERS
-- ============================================================
local NOOP = function() end

-- Returns false (used for check functions that gate anticheat activation)
local RETURN_FALSE = function()
	return false
end

-- Build the replacement function based on spec options
-- spec.replace_with  → custom function (used as-is)
-- spec.log_calls     → wraps replacement to log each call with method name + args summary
local function make_replacement(spec, method_name)
	local base = spec.replace_with or NOOP
	if not spec.log_calls then
		return base
	end
	local prefix = "[Intercept] " .. spec.path .. ":" .. (spec.class or "?") .. "." .. method_name
	return function(self_arg, ...)
		if _state.logging then
			local args = { ... }
			if #args > 0 then
				_log(prefix .. " args=" .. Serialize.dump_value(args))
			else
				_log(prefix)
			end
		end
		return base(self_arg, ...)
	end
end

-- ============================================================
-- PATCHING ENGINE
-- ============================================================
local function patch_modules(specs)
	for _, spec in ipairs(specs) do
		local target_module = _state.cached_modules[spec.path] or register_orig_module(spec.path)
		if not target_module then
			_log("Module not found: " .. spec.path)
			goto continue
		end

		-- Patch table fields with empty proxies
		if spec.fields then
			for _, field in ipairs(spec.fields) do
				_save_orig(target_module, field)
				rawset(target_module, field, Cocos.create_empty_proxy())
			end
			_log("Patched " .. spec.path .. " (" .. #spec.fields .. " fields)")
		end

		-- Patch class methods
		if spec.class then
			local ok, cls = pcall(rawget, target_module, spec.class)
			if ok and cls then
				if spec.patch_all then
					local count = 0
					for k, v in next, cls do
						if type(v) == "function" then
							_save_orig(cls, k)
							rawset(cls, k, make_replacement(spec, k))
							count = count + 1
						end
					end
					_log("Patched " .. spec.path .. ":" .. spec.class .. " (all " .. count .. " methods)")
				elseif spec.methods then
					for method, replacement in pairs(spec.methods) do
						if type(method) == "number" then
							-- Array-style: { "method_name" } → use default replacement
							_save_orig(cls, replacement)
							rawset(cls, replacement, make_replacement(spec, replacement))
						else
							-- Dict-style: { method_name = custom_fn } → use specific replacement
							_save_orig(cls, method)
							rawset(cls, method, replacement)
							_log("Patched " .. spec.path .. ":" .. spec.class .. "." .. method .. " (custom)")
						end
					end
					local count = 0
					for _ in pairs(spec.methods) do
						count = count + 1
					end
					_log("Patched " .. spec.path .. ":" .. spec.class .. " (" .. count .. " methods)")
				end
			else
				_log("Class not found: " .. spec.path .. ":" .. spec.class)
			end
		end

		-- Patch standalone functions in module table
		if spec.functions then
			for func_name, replacement in pairs(spec.functions) do
				if type(func_name) == "number" then
					_save_orig(target_module, replacement)
					rawset(target_module, replacement, NOOP)
				else
					_save_orig(target_module, func_name)
					rawset(target_module, func_name, replacement)
				end
			end
			local count = 0
			for _ in pairs(spec.functions) do
				count = count + 1
			end
			_log("Patched " .. spec.path .. " (" .. count .. " functions)")
		end

		::continue::
	end
end

-- ============================================================
-- DEBUG FLAGS
-- ============================================================
local FLAGS_TO_SET = {
	DEBUG = true,
	DISABLE_ACSDK = true,
	ENABLE_DEBUG_PRINT = true,
	ENABLE_FORCE_SHOW_GM = true,
	DEBUG_OPEN_COMBAT_MONITOR = true,
	FORCE_OPEN_DEBUG_SHORTCUT = true,
	GM_IS_OPEN_GUIDE = true,
	GM_USE_PUBLISH = true,
	acsdk_info_has_inited = false,
}

local MAX_DEPTH = 10
local visited = setmetatable({}, { __mode = "k" })

local function modify_flags(tbl, path, depth)
	if depth > MAX_DEPTH or visited[tbl] then
		return
	end
	visited[tbl] = true
	for k, _ in next, tbl do
		local ok, v = pcall(rawget, tbl, k)
		if ok and type(k) == "string" and FLAGS_TO_SET[k] ~= nil then
			rawset(tbl, k, FLAGS_TO_SET[k])
			_log("[Flag] " .. path .. k .. " = " .. tostring(FLAGS_TO_SET[k]))
		end
		if type(v) == "table" then
			modify_flags(v, path .. tostring(k) .. ".", depth + 1)
		end
	end
end

local function apply_debug_flags()
	local ROOT = rawget(_G, "DUMP_ROOT") or package.loaded
	local ROOT_NAME = rawget(_G, "DUMP_ROOT_NAME") or "ROOT"
	modify_flags(ROOT, ROOT_NAME .. ".", 0)
end

-- ============================================================
-- SA-LOG INTERCEPTOR (captures payloads instead of uploading)
-- ============================================================
local function make_sa_log_interceptor()
	return function(self, kwargs)
		local operation = self and self.operation or "unknown"
		if _state.logging then
			_log("[SA-Log BLOCKED] op=" .. operation .. " | " .. Serialize.dump_value(kwargs))
		end

		-- Store for later inspection
		local entry = {
			operation = operation,
			kwargs = kwargs,
			time = os.clock(),
		}
		local logs = _state.intercepted_logs
		logs[#logs + 1] = entry
		-- Cap stored logs
		if #logs > 200 then
			table.remove(logs, 1)
		end
	end
end

-- ============================================================
-- DRPF UPLOAD BLOCKER
-- ============================================================
local function make_drpf_blocker()
	return function()
		return false
	end
end

-- ============================================================
-- SPACE INSPECTION GATE OVERRIDE
-- Returns false for all inspection-enable checks so the runtime
-- never activates the heavier anticheat monitors.
-- ============================================================
local function patch_space_inspection_gates()
	local space_mod = _state.cached_modules["hexm.common.space_common"] or register_orig_module("hexm.common.space_common")
	if not space_mod then
		_log("space_common not found, skipping space gate patches")
		return
	end

	local ok, SpaceTag = pcall(rawget, space_mod, "SpaceTag")
	if not ok or not SpaceTag then
		_log("SpaceTag not found in space_common")
		return
	end

	local gate_methods = {
		"check_enable_inspection",
		"check_enable_pvp_log",
		"check_enable_pvp_speed_stack",
		"check_enable_pvp_network_detect",
		"check_enable_pvp_teleport_detect",
	}

	local patched = 0
	for _, method in ipairs(gate_methods) do
		if type(rawget(SpaceTag, method)) == "function" then
			_save_orig(SpaceTag, method)
			rawset(SpaceTag, method, function(self)
				_log("[SpaceGate] " .. method .. " → false")
				return false
			end)
			patched = patched + 1
		end
	end
	_log("Patched SpaceTag (" .. patched .. " inspection gates → false)")
end

-- ============================================================
-- NATIVE ANTICHEAT NEUTRALIZATION (MHexAC / MQSec)
-- ============================================================
local function neutralize_native_anticheat()
	-- MHexAC: null out callbacks and reading functions
	if _G.MHexAC then
		local orig = {}
		for k, v in pairs(_G.MHexAC) do
			if type(v) == "function" then
				orig[k] = v
			end
		end

		-- Disable keyboard monitoring callback
		if _G.MHexAC.SetCheckVkDownInvalidCallback then
			pcall(_G.MHexAC.SetCheckVkDownInvalidCallback, nil)
			_log("[Native] MHexAC.SetCheckVkDownInvalidCallback(nil)")
		end

		-- Replace rawinput mask setter with noop
		if _G.MHexAC.SetRawInputCheckVKMask then
			_save_orig(_G.MHexAC, "SetRawInputCheckVKMask")
			_G.MHexAC.SetRawInputCheckVKMask = function(...)
				_log("[Native] MHexAC.SetRawInputCheckVKMask blocked")
			end
		end

		-- Replace GetText (used for reading kernel32.dll timing API bytes)
		if _G.MHexAC.GetText then
			_save_orig(_G.MHexAC, "GetText")
			local orig_GetText = rawget(_G.MHexAC, "GetText") -- snapshot before overwrite below
			_G.MHexAC.GetText = function(dll, func, size)
				_log(
					"[Native] MHexAC.GetText("
						.. tostring(dll)
						.. ", "
						.. tostring(func)
						.. ", "
						.. tostring(size)
						.. ") → forwarded"
				)
				-- Forward so game doesn't crash, but log the access
				return orig_GetText(dll, func, size)
			end
		end

		_log("[Native] MHexAC hooks neutralized")
	else
		_log("[Native] MHexAC not present (non-Windows or not loaded)")
	end

	-- MQSec: unload if loaded
	if _G.MQSec then
		if _G.MQSec.UnLoadQSec then
			pcall(_G.MQSec.UnLoadQSec)
			_log("[Native] MQSec unloaded")
		end
		-- Replace LoadQSec so it can't be reloaded
		_save_orig(_G.MQSec, "LoadQSec")
		_G.MQSec.LoadQSec = function()
			_log("[Native] MQSec.LoadQSec blocked")
			return 0 -- indicates failure
		end
		if _G.MQSec.TN1OO00OO then
			_save_orig(_G.MQSec, "TN1OO00OO")
			_G.MQSec.TN1OO00OO = NOOP
		end
		_log("[Native] MQSec neutralized")
	else
		_log("[Native] MQSec not present")
	end
end

-- ============================================================
-- ENGINE INSPECTION INIT PATCH
-- ============================================================
local function patch_engine_inspection()
	local engine_mod = _state.cached_modules["hexm.client.engine.engine"] or register_orig_module("hexm.client.engine.engine")
	if not engine_mod then
		_log("Engine module not found, skipping engine patches")
		return
	end

	local ok, Engine = pcall(rawget, engine_mod, "Engine")
	if not ok or not Engine then
		_log("Engine class not found")
		return
	end

	local engine_methods = {
		"_init_inspection_check",
		"add_rawinput_check_callback",
		"remove_rawinput_check_callback",
		"_on_rawinput_check_callback",
		"set_rawinput_check_makecode_mask",
	}

	for _, method in ipairs(engine_methods) do
		if type(rawget(Engine, method)) == "function" then
			_save_orig(Engine, method)
			rawset(Engine, method, function(self, ...)
				_log("[Engine] " .. method .. " blocked")
			end)
		end
	end
	_log("Patched Engine (" .. #engine_methods .. " inspection methods)")
end

-- ============================================================
-- DRPF CONFIG PATCH (kill the reporting gate at source)
-- ============================================================
local function patch_drpf_config()
	local drpf_mod = portable.safe_import("patch.sa_log_comp.drpf_config")
	if not drpf_mod then
		_log("drpf_config not found, skipping")
		return
	end

	-- Override check_can_report_drpf to always return false
	_save_orig(drpf_mod, "check_can_report_drpf")
	rawset(drpf_mod, "check_can_report_drpf", function()
		return false
	end)
	-- Also set the cached value
	_save_orig(drpf_mod, "_report_drpf")
	rawset(drpf_mod, "_report_drpf", false)
	_log("Patched drpf_config.check_can_report_drpf → false")
end

-- ============================================================
-- SA LOG HANDLER PATCH (intercept at handler level)
-- ============================================================
local function patch_sa_log_handler()
	local handler_mod = portable.safe_import("patch.sa_log_handler")
	if not handler_mod then
		_log("sa_log_handler not found, skipping")
		return
	end

	local ok, SALogHandler = pcall(rawget, handler_mod, "SALogHandler")
	if not ok or not SALogHandler then
		_log("SALogHandler class not found")
		return
	end

	-- Replace log to intercept all SA-log operations
	_save_orig(SALogHandler, "log")
	rawset(SALogHandler, "log", function(self, operation, kwargs)
		if _state.logging then
			_log("[SALogHandler] log(" .. tostring(operation) .. ") kwargs=" .. Serialize.dump_value(kwargs))
		end
	end)

	-- Replace get_dict to log access
	_save_orig(SALogHandler, "get_dict")
	rawset(SALogHandler, "get_dict", function(self, operation, kwargs)
		if _state.logging then
			_log("[SALogHandler] get_dict(" .. tostring(operation) .. ") kwargs=" .. Serialize.dump_value(kwargs))
		end
		return {}
	end)

	-- Replace call_drpf_func
	_save_orig(SALogHandler, "call_drpf_func")
	rawset(SALogHandler, "call_drpf_func", function(self, operation, func)
		if _state.logging then
			_log("[SALogHandler] call_drpf_func(" .. tostring(operation) .. ", " .. tostring(func) .. ")")
		end
	end)

	_log("Patched SALogHandler (log, call_drpf_func)")
end

-- ============================================================
-- QDATA LOG HANDLER PATCH
-- ============================================================
local function patch_qdata_handler()
	local qdata_mod = portable.safe_import("hexm.client.net.qdata_log_handler")
	if not qdata_mod then
		_log("qdata_log_handler not found, skipping")
		return
	end

	local ok, QdataLogHandler = pcall(rawget, qdata_mod, "QdataLogHandler")
	if ok and QdataLogHandler then
		local methods_to_noop = {
			"log_qdata",
			"post_to_qdata",
			"update_hex_sdk_params",
		}
		for _, method in ipairs(methods_to_noop) do
			if type(rawget(QdataLogHandler, method)) == "function" then
				local m = method -- capture for closure
				_save_orig(QdataLogHandler, m)
				rawset(QdataLogHandler, method, function(self, ...)
					if _state.logging then
						_log("[QData] " .. m .. " args=" .. Serialize.dump_value({ ... }))
					end
				end)
			end
		end
		_log("Patched QdataLogHandler (" .. #methods_to_noop .. " methods)")
	end
end

-- ============================================================
-- ACSDK PATCH ON HOST CLASS (SdkManager)
-- ============================================================
-- The Components() mixin system (simple_component.lua:_addComponent) copies all
-- methods from imp_anticheat.SdkManagerMember onto SdkManager at startup via
-- rawset(cls, name, v). Patching imp_anticheat.SdkManagerMember is therefore
-- ineffective: the live G.sdk_manager instance resolves methods through SdkManager,
-- which already holds the original copied functions.
-- Fix: patch SdkManager directly and cancel already-running timers.
local function patch_acsdk_sdk_manager()
	local sdk_manager_mod = portable.safe_import("hexm.client.manager.sdk_manager")
	if not sdk_manager_mod then
		_log("[ACSDK] sdk_manager module not found, skipping")
		return
	end

	local ok, SdkManager = pcall(rawget, sdk_manager_mod, "SdkManager")
	if not ok or not SdkManager then
		_log("[ACSDK] SdkManager class not found, skipping")
		return
	end

	local acsdk_methods = {
		"setup_acsdk",
		"real_setup_acsdk",
		"on_finish_setup_acsdk",
		"start_normal_call_acsdk_tick",
		"start_anti_frame_call_acsdk_tick",
		"on_normal_call_acsdk_tick",
		"on_anti_frame_call_acsdk_tick",
		"on_finish_call_acsdk",
	}

	local patched = 0
	for _, method in ipairs(acsdk_methods) do
		if type(rawget(SdkManager, method)) == "function" then
			local m = method
			_save_orig(SdkManager, m)
			rawset(SdkManager, m, function(self, ...)
				if _state.logging then
					_log("[ACSDK] " .. m .. " blocked on SdkManager")
				end
			end)
			patched = patched + 1
		end
	end
	_log("[ACSDK] Patched SdkManager (" .. patched .. " ACSDK methods)")

	-- Cancel already-running tick timers on the live instance
	if _G.G and _G.G.sdk_manager then
		pcall(function()
			_G.G.sdk_manager:cancel_tick_acsdk_timer()
			_log("[ACSDK] Cancelled live ACSDK timers via G.sdk_manager")
		end)
	else
		_log("[ACSDK] G.sdk_manager not available, timers not cancelled")
	end
end

-- ============================================================
-- PATCH VERIFICATION
-- ============================================================
-- Imports the actual live module objects and calls their patched entry-points
-- to confirm each bypass layer is in effect. Logs PASS/FAIL per check.
-- A FAIL usually means the patch ran against the wrong table (e.g. component
-- class vs. host class) or the module was not loaded at patch time.

local function _verify_check(results, label, fn, expected_return)
	local ok, result = pcall(fn)
	if not ok then
		_log("[Verify] FAIL " .. label .. " | error: " .. tostring(result))
		results[label] = "FAIL(error): " .. tostring(result)
		return false
	end
	if expected_return ~= nil and result ~= expected_return then
		_log(
			"[Verify] FAIL "
				.. label
				.. " | expected="
				.. tostring(expected_return)
				.. " got="
				.. tostring(result)
		)
		results[label] = "FAIL(wrong): expected=" .. tostring(expected_return) .. " got=" .. tostring(result)
		return false
	end
	_log("[Verify] PASS " .. label)
	results[label] = "PASS"
	return true
end

local function run_verify_patches()
	_log("[Verify] === Running patch verification ===")
	local results = {}
	local pass, fail = 0, 0

	local function check(label, fn, expected_return)
		if _verify_check(results, label, fn, expected_return) then
			pass = pass + 1
		else
			fail = fail + 1
		end
	end

	-- ── 1. DRPF upload gate ──────────────────────────────────────────────────
	-- patch_drpf_config() overrides check_can_report_drpf → always false
	local drpf_mod = portable.safe_import("patch.sa_log_comp.drpf_config")
	if drpf_mod then
		check("drpf_config.check_can_report_drpf() → false", function()
			return drpf_mod.check_can_report_drpf()
		end, false)
		check("drpf_config._report_drpf cached == false", function()
			return rawget(drpf_mod, "_report_drpf")
		end, false)
	else
		_log("[Verify] SKIP drpf_config (module not found)")
	end

	-- ── 2. SALogHandler intercept ────────────────────────────────────────────
	-- patch_sa_log_handler() replaces log/get_dict/call_drpf_func with NOOPs.
	-- Original SALogHandler.log uploads to the SA telemetry backend.
	-- Original SALogHandler.get_dict builds and returns a live payload dict.
	local handler_mod = portable.safe_import("patch.sa_log_handler")
	if handler_mod then
		local SALogHandler = rawget(handler_mod, "SALogHandler")
		if SALogHandler then
			-- log: patched → NOOP (no throw, no upload)
			check("SALogHandler.log is patched (no upload on call)", function()
				SALogHandler.log({ operation = "__acb_verify__" }, "__verify_op__", {})
			end)
			-- get_dict: patched → returns empty table, not a live payload
			check("SALogHandler.get_dict returns empty table", function()
				local r = SALogHandler.get_dict({ operation = "__acb_verify__" }, "__verify_op__", {})
				assert(type(r) == "table", "expected table, got " .. type(r))
			end)
		else
			_log("[Verify] SKIP SALogHandler (class not found in module)")
		end
	else
		_log("[Verify] SKIP sa_log_handler (module not found)")
	end

	-- ── 3. BaseLog family: check_can_report → false ──────────────────────────
	-- Original BaseLog.check_can_report eventually calls drpf_config.check_can_report_drpf.
	-- Our patch replaces it with RETURN_FALSE on the class directly.
	local base_log_mod = portable.safe_import("patch.sa_log_comp.base_log")
	if base_log_mod then
		for _, cls_name in ipairs({ "BaseLog", "ScriptLog", "acsdk_cheat_check" }) do
			local cls = rawget(base_log_mod, cls_name)
			if cls and rawget(cls, "check_can_report") then
				check(cls_name .. ".check_can_report() → false", function()
					return cls.check_can_report({ operation = "__acb_verify__" })
				end, false)
			else
				_log("[Verify] SKIP " .. cls_name .. ".check_can_report (not found)")
			end
		end
	else
		_log("[Verify] SKIP base_log (module not found)")
	end

	-- ── 4. SpaceTag inspection gates → false ─────────────────────────────────
	-- patch_space_inspection_gates() replaces these so the heavier
	-- runtime inspection monitors are never activated.
	local space_mod = portable.safe_import("hexm.common.space_common")
	if space_mod then
		local SpaceTag = rawget(space_mod, "SpaceTag")
		if SpaceTag then
			for _, gate in ipairs({ "check_enable_inspection", "check_enable_pvp_log" }) do
				local fn = rawget(SpaceTag, gate)
				if fn then
					check("SpaceTag." .. gate .. "() → false", function()
						return fn({})
					end, false)
				else
					_log("[Verify] SKIP SpaceTag." .. gate .. " (not found on class)")
				end
			end
		else
			_log("[Verify] SKIP SpaceTag (not found in space_common)")
		end
	else
		_log("[Verify] SKIP space_common (module not found)")
	end

	-- ── 5. SdkManager ACSDK tick methods → NOOP ──────────────────────────────
	-- patch_acsdk_sdk_manager() patches these directly on SdkManager (not the
	-- imp_anticheat component class). The originals call self._acc_mgr:CallACSDK()
	-- which would index nil on a dummy self, causing an error.
	-- If no error occurs on a plain {} self, our NOOP is confirmed active.
	local sdk_mgr_mod = portable.safe_import("hexm.client.manager.sdk_manager")
	if sdk_mgr_mod then
		local SdkManager = rawget(sdk_mgr_mod, "SdkManager")
		if SdkManager then
			for _, m in ipairs({
				"on_normal_call_acsdk_tick",
				"on_anti_frame_call_acsdk_tick",
				"on_finish_setup_acsdk",
				"on_finish_call_acsdk",
			}) do
				local fn = rawget(SdkManager, m)
				if fn then
					-- Dummy self has no _acc_mgr: original would error, NOOP succeeds.
					check("SdkManager." .. m .. " is NOOP (dummy self, no native call)", function()
						fn({})
					end)
				else
					_log("[Verify] SKIP SdkManager." .. m .. " (not found on class)")
				end
			end
		else
			_log("[Verify] SKIP SdkManager (class not found in module)")
		end
	else
		_log("[Verify] SKIP sdk_manager (module not found)")
	end

	-- ── 6. QdataLogHandler methods → NOOP ───────────────────────────────────
	-- patch_qdata_handler() replaces log_qdata/post_to_qdata/update_hex_sdk_params.
	-- Original log_qdata calls self:post_to_qdata which sends an HTTP request;
	-- calling with a bare {} self would error deep inside. Our NOOP succeeds.
	local qdata_mod = portable.safe_import("hexm.client.net.qdata_log_handler")
	if qdata_mod then
		local QdataLogHandler = rawget(qdata_mod, "QdataLogHandler")
		if QdataLogHandler then
			for _, m in ipairs({ "log_qdata", "post_to_qdata" }) do
				local fn = rawget(QdataLogHandler, m)
				if fn then
					check("QdataLogHandler." .. m .. " is patched (no HTTP on dummy self)", function()
						fn({})
					end)
				else
					_log("[Verify] SKIP QdataLogHandler." .. m .. " (not found)")
				end
			end
		else
			_log("[Verify] SKIP QdataLogHandler (class not found)")
		end
	else
		_log("[Verify] SKIP qdata_log_handler (module not found)")
	end

	-- ── 7. DamageStatsManager._check_need_stats → false ─────────────────────
	-- Patched with RETURN_FALSE so begin_damage_statistics exits immediately.
	-- Original accesses attacker/target entity data; dummy args would crash it.
	local dmg_mod = portable.safe_import("hexm.common.combat.anti_cheating.damage_stats_manager")
	if dmg_mod then
		local DamageStatsManager = rawget(dmg_mod, "DamageStatsManager")
		if DamageStatsManager and rawget(DamageStatsManager, "_check_need_stats") then
			check("DamageStatsManager._check_need_stats() → false", function()
				return DamageStatsManager._check_need_stats({})
			end, false)
		else
			_log("[Verify] SKIP DamageStatsManager._check_need_stats (not found)")
		end
	else
		_log("[Verify] SKIP damage_stats_manager (module not found)")
	end

	_log(("[Verify] === Done: %d passed, %d failed ==="):format(pass, fail))
	return results, pass, fail
end

-- ============================================================
-- PUBLIC API
-- ============================================================
function AntiCheatBypass.enable()
	if _state.is_enabled then
		-- Script was reloaded while already active — restore originals first
		-- so patches are cleanly re-applied against unmodified functions.
		_log("=== Already enabled — restoring originals before re-enabling ===")
		restore_originals()
	end

	_log("=== Enabling anticheat bypass ===")

	-- Phase 1: Debug flags
	apply_debug_flags()

	-- Phase 2: Native anticheat neutralization
	neutralize_native_anticheat()

	-- Phase 3: DRPF reporting gate (kills all SA-log uploads at config level)
	patch_drpf_config()

	-- Phase 4: SA-log handler intercept (backup layer)
	patch_sa_log_handler()

	-- Phase 5: QData telemetry
	patch_qdata_handler()

	-- Phase 6: Space-gated inspection checks → always false
	patch_space_inspection_gates()

	-- Phase 7: Engine-level inspection init
	patch_engine_inspection()

	-- Phase 8: ACSDK neutralization on SdkManager host class
	-- (must be before patch_modules since it handles imp_anticheat separately)
	patch_acsdk_sdk_manager()

	-- Phase 9: Module-level patches (classes and methods)
	patch_modules({
		-- Trace telemetry fields
		{
			path = "hexm.client.trace",
			fields = { "TRACE_LIST", "TRACE_COUNTS", "TRACE_CACHE" },
		},

		-- Combat damage anticheat
		{
			path = "hexm.common.combat.anti_cheating.damage_stats_manager",
			class = "DamageStatsManager",
			methods = {
				_check_need_stats = RETURN_FALSE,
				begin_damage_statistics = NOOP,
				process_damage_statistics = NOOP,
				end_damage_statistics = NOOP,
				check_stage_id_consistency = NOOP,
				check_damage_recompute = NOOP,
			},
			log_calls = false,
		},

		-- BaseLog: intercept the log method with our capturing interceptor
		{
			path = "patch.sa_log_comp.base_log",
			class = "BaseLog",
			methods = {
				log = make_sa_log_interceptor(),
				check_can_report = RETURN_FALSE,
			},
			log_calls = false,
		},

		-- Also patch the ScriptLog subclass
		{
			path = "patch.sa_log_comp.base_log",
			class = "ScriptLog",
			methods = {
				check_can_report = RETURN_FALSE,
			},
			log_calls = false,
		},

		-- acsdk_cheat_check subclass
		{
			path = "patch.sa_log_comp.base_log",
			class = "acsdk_cheat_check",
			methods = {
				check_can_report = RETURN_FALSE,
			},
			log_calls = false,
		},

		-- Player inspection (speed, delta-time, rawinput, invincibility, teleport, etc.)
		{
			path = "hexm.client.entities.local.player_avatar_members.inspection.imp_inspection",
			class = "PlayerAvatarMember",
			patch_all = true,
			log_calls = true,
		},

		-- Common entity inspection (other avatars, boss NPCs)
		{
			path = "hexm.client.entities.local.common_members.inspection.imp_inspection",
			class = "CommonImpInspection",
			patch_all = true,
			log_calls = true,
		},

		-- PVP log: PlayerAvatarMember
		{
			path = "hexm.client.entities.local.player_avatar_members.inspection.imp_pvp_log",
			class = "PlayerAvatarMember",
			patch_all = true,
			log_calls = true,
		},

		-- PVP log: SkillLogListener (monitors skill timing)
		{
			path = "hexm.client.entities.local.player_avatar_members.inspection.imp_pvp_log",
			class = "SkillLogListener",
			patch_all = true,
			log_calls = true,
		},

		-- SA-log component in sdk_manager (report_sa_log, report_script_log, report_qdata_log)
		{
			path = "hexm.client.manager.sdk_comp.imp_sa_log",
			class = "SdkManagerMember",
			methods = {
				report_sa_log = function(self, operation, kwargs)
					if _state.logging then
						_log("[SDK] report_sa_log(" .. tostring(operation) .. ") kwargs=" .. Serialize.dump_value(kwargs))
					end
				end,
				report_script_log = function(self, log_type, kwargs)
					if _state.logging then
						_log(
							"[SDK] report_script_log(" .. tostring(log_type) .. ") kwargs=" .. Serialize.dump_value(kwargs)
						)
					end
				end,
				report_qdata_log = function(self, operation, kwargs)
					if _state.logging then
						_log(
							"[SDK] report_qdata_log(" .. tostring(operation) .. ") kwargs=" .. Serialize.dump_value(kwargs)
						)
					end
				end,
				report_time_status = function(self, reason)
					if _state.logging then
						_log("[SDK] report_time_status(" .. tostring(reason) .. ")")
					end
				end,
			},
			log_calls = false,
		},
	})

	_state.is_enabled = true
	_log("=== Anticheat bypass enabled ===")

	-- Verify all patches are in effect immediately after enabling
	run_verify_patches()
end

-- Retrieve captured SA-log payloads for inspection
function AntiCheatBypass.get_intercepted_logs()
	return _state.intercepted_logs
end

-- Clear captured logs
function AntiCheatBypass.clear_intercepted_logs()
	_state.intercepted_logs = {}
end

-- Get summary of what's been intercepted
function AntiCheatBypass.get_log_summary()
	local logs = _state.intercepted_logs
	local by_op = {}
	for _, entry in ipairs(logs) do
		by_op[entry.operation] = (by_op[entry.operation] or 0) + 1
	end
	return by_op
end

-- Undo all patches and return every function/field to its original value.
-- After this call, enable() may be called again for a clean re-apply.
function AntiCheatBypass.disable()
	if not _state.is_enabled then
		_log("Not enabled, nothing to restore")
		return
	end
	restore_originals()
end

-- Re-run verification on demand (useful after hot-reload or manual patching)
function AntiCheatBypass.verify_patches()
	return run_verify_patches()
end

function AntiCheatBypass.is_enabled()
	return _state.is_enabled
end

function AntiCheatBypass.set_logging(enabled)
	_state.logging = enabled ~= false
	_log("Logging " .. (_state.logging and "enabled" or "disabled"))
end

function AntiCheatBypass.get_logging()
	return _state.logging
end

return AntiCheatBypass
