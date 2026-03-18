-- ============================================================
-- ANTICHEAT_BYPASS.LUA - Anti-Cheat Bypass & Network Monitor
-- ============================================================
-- ActionBase module covering all anticheat layers:
--   1. SA-log telemetry pipeline (BaseLog, SALogHandler, drpf_config)
--   2. ACSDK remote service integration (imp_anticheat)
--   3. Client-side inspection: player, common entity, PVP
--   4. Combat damage consistency checker (damage_stats_manager)
--   5. Native anticheat hooks (MHexAC, MQSec) via Engine
--   6. Space-gated inspection enablement (SpaceTag)
--   7. Trace telemetry
--   8. QData log pipeline
--
-- Hook strategy:
--   Category A: 39 static hooks in define_hooks() via HookManager
--   Category B: Dynamic patch_all hooks registered at runtime in on_enable()
--   Category C: Non-hookable patches (debug flags, native globals, fields)
-- ============================================================

local ActionBase = _G.Reg.lib("ActionBase")
local Serialize = _G.Reg.lib("Serialize")
local Cocos = _G.Reg.lib("Cocos")

local ACB = ActionBase:extend("actions.anticheat_bypass")

-- ── Constants (scalar / small closures per IMPLEMENT.md exception) ──

local NOOP = function() end

local RETURN_FALSE = function()
	return false
end

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

local MAX_FLAG_DEPTH = 10

-- Modules that need patch_all (all methods replaced with NOOP)
local PATCH_ALL_TARGETS = {
	{
		module_path = "hexm.client.entities.local.player_avatar_members.inspection.imp_inspection",
		class_name = "PlayerAvatarMember",
		prefix = "imp_insp_player",
	},
	{
		module_path = "hexm.client.entities.local.common_members.inspection.imp_inspection",
		class_name = "CommonImpInspection",
		prefix = "imp_insp_common",
	},
	{
		module_path = "hexm.client.entities.local.player_avatar_members.inspection.imp_pvp_log",
		class_name = "PlayerAvatarMember",
		prefix = "pvp_log_player",
	},
	{
		module_path = "hexm.client.entities.local.player_avatar_members.inspection.imp_pvp_log",
		class_name = "SkillLogListener",
		prefix = "pvp_log_skill",
	},
}

-- ── State ──

function ACB:define_state()
	return {
		persistent = {
			is_enabled = false,
			logging = false,
			patch_once = true, -- if true, disable() preserves hooks
			reload_protected = true, -- survive Reg.reload_all() without deactivation
		},
		transient = {
			intercepted_logs = {}, -- captured SA-log payloads
			native_originals = {}, -- Category C: {tbl, key, val} for MHexAC/MQSec
			field_originals = {}, -- Category C: {tbl, key, val} for TRACE_LIST/_report_drpf
			dynamic_hook_names = {}, -- Category B: names of dynamically registered hooks
		},
	}
end

-- ── Hooks (Category A: 39 static hooks) ──

function ACB:define_hooks()
	return {
		-- ── DRPF config ──────────────────────────────────────────
		drpf_check_can_report = {
			spec = "patch.sa_log_comp.drpf_config:check_can_report_drpf",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return false
			end,
		},

		-- ── SA Log Handler ───────────────────────────────────────
		sa_handler_log = {
			spec = "patch.sa_log_handler:SALogHandler:log",
			override_orig_function = true,
			post_exec = function(self_action, original, self_target, operation, kwargs)
				if self_action.state.logging then
					self_action:log("[SALogHandler] log(" .. tostring(operation) .. ")")
				end
			end,
		},
		sa_handler_get_dict = {
			spec = "patch.sa_log_handler:SALogHandler:get_dict",
			override_orig_function = true,
			post_exec = function(self_action, original, self_target, operation, kwargs)
				if self_action.state.logging then
					self_action:log("[SALogHandler] get_dict(" .. tostring(operation) .. ")")
				end
				return {}
			end,
		},
		sa_handler_call_drpf_func = {
			spec = "patch.sa_log_handler:SALogHandler:call_drpf_func",
			override_orig_function = true,
			post_exec = function(self_action, original, self_target, operation, func)
				if self_action.state.logging then
					self_action:log("[SALogHandler] call_drpf_func(" .. tostring(operation) .. ")")
				end
			end,
		},

		-- ── QData Handler ────────────────────────────────────────
		qdata_log_qdata = {
			spec = "hexm.client.net.qdata_log_handler:QdataLogHandler:log_qdata",
			override_orig_function = true,
			post_exec = function(self_action, original, self_target, ...)
				if self_action.state.logging then
					self_action:log("[QData] log_qdata")
				end
			end,
		},
		qdata_post_to_qdata = {
			spec = "hexm.client.net.qdata_log_handler:QdataLogHandler:post_to_qdata",
			override_orig_function = true,
			post_exec = function(self_action, original, self_target, ...)
				if self_action.state.logging then
					self_action:log("[QData] post_to_qdata")
				end
			end,
		},
		qdata_update_hex_sdk_params = {
			spec = "hexm.client.net.qdata_log_handler:QdataLogHandler:update_hex_sdk_params",
			override_orig_function = true,
			post_exec = function(self_action, original, self_target, ...)
				if self_action.state.logging then
					self_action:log("[QData] update_hex_sdk_params")
				end
			end,
		},

		-- ── Space gates ──────────────────────────────────────────
		space_check_enable_inspection = {
			spec = "hexm.common.space_common:SpaceTag:check_enable_inspection",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return false
			end,
		},
		space_check_enable_pvp_log = {
			spec = "hexm.common.space_common:SpaceTag:check_enable_pvp_log",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return false
			end,
		},
		space_check_enable_pvp_speed_stack = {
			spec = "hexm.common.space_common:SpaceTag:check_enable_pvp_speed_stack",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return false
			end,
		},
		space_check_enable_pvp_network_detect = {
			spec = "hexm.common.space_common:SpaceTag:check_enable_pvp_network_detect",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return false
			end,
		},
		space_check_enable_pvp_teleport_detect = {
			spec = "hexm.common.space_common:SpaceTag:check_enable_pvp_teleport_detect",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return false
			end,
		},

		-- ── Engine inspection ────────────────────────────────────
		engine_init_inspection_check = {
			spec = "hexm.client.engine.engine:Engine:_init_inspection_check",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return nil
			end,
		},
		engine_add_rawinput_check_callback = {
			spec = "hexm.client.engine.engine:Engine:add_rawinput_check_callback",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return nil
			end,
		},
		engine_remove_rawinput_check_callback = {
			spec = "hexm.client.engine.engine:Engine:remove_rawinput_check_callback",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return nil
			end,
		},
		engine_on_rawinput_check_callback = {
			spec = "hexm.client.engine.engine:Engine:_on_rawinput_check_callback",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return nil
			end,
		},
		engine_set_rawinput_check_makecode_mask = {
			spec = "hexm.client.engine.engine:Engine:set_rawinput_check_makecode_mask",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return nil
			end,
		},

		-- ── ACSDK SdkManager ─────────────────────────────────────
		-- NOTE: The game's Components() mixin copies methods from
		-- imp_anticheat.SdkManagerMember onto SdkManager at startup
		-- via rawset(). We hook SdkManager directly (the live target).
		-- If the mixin re-runs after our hooks activate, it would
		-- overwrite them. _cancel_acsdk_timers() guards against
		-- re-init by setting acsdk_info_has_inited = false.
		acsdk_setup = {
			spec = "hexm.client.manager.sdk_manager:SdkManager:setup_acsdk",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return nil
			end,
		},
		acsdk_real_setup = {
			spec = "hexm.client.manager.sdk_manager:SdkManager:real_setup_acsdk",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return nil
			end,
		},
		acsdk_on_finish_setup = {
			spec = "hexm.client.manager.sdk_manager:SdkManager:on_finish_setup_acsdk",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return nil
			end,
		},
		acsdk_start_normal_tick = {
			spec = "hexm.client.manager.sdk_manager:SdkManager:start_normal_call_acsdk_tick",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return nil
			end,
		},
		acsdk_start_anti_frame_tick = {
			spec = "hexm.client.manager.sdk_manager:SdkManager:start_anti_frame_call_acsdk_tick",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return nil
			end,
		},
		acsdk_on_normal_tick = {
			spec = "hexm.client.manager.sdk_manager:SdkManager:on_normal_call_acsdk_tick",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return nil
			end,
		},
		acsdk_on_anti_frame_tick = {
			spec = "hexm.client.manager.sdk_manager:SdkManager:on_anti_frame_call_acsdk_tick",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return nil
			end,
		},
		acsdk_on_finish_call = {
			spec = "hexm.client.manager.sdk_manager:SdkManager:on_finish_call_acsdk",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return nil
			end,
		},

		-- ── Damage stats manager ─────────────────────────────────
		dmg_check_need_stats = {
			spec = "hexm.common.combat.anti_cheating.damage_stats_manager:DamageStatsManager:_check_need_stats",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return false
			end,
		},
		dmg_begin = {
			spec = "hexm.common.combat.anti_cheating.damage_stats_manager:DamageStatsManager:begin_damage_statistics",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return nil
			end,
		},
		dmg_process = {
			spec = "hexm.common.combat.anti_cheating.damage_stats_manager:DamageStatsManager:process_damage_statistics",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return nil
			end,
		},
		dmg_end = {
			spec = "hexm.common.combat.anti_cheating.damage_stats_manager:DamageStatsManager:end_damage_statistics",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return nil
			end,
		},
		dmg_check_stage_id = {
			spec = "hexm.common.combat.anti_cheating.damage_stats_manager:DamageStatsManager:check_stage_id_consistency",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return nil
			end,
		},
		dmg_check_recompute = {
			spec = "hexm.common.combat.anti_cheating.damage_stats_manager:DamageStatsManager:check_damage_recompute",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return nil
			end,
		},

		-- ── BaseLog / ScriptLog / acsdk_cheat_check ──────────────
		baselog_log = {
			spec = "patch.sa_log_comp.base_log:BaseLog:log",
			override_orig_function = true,
			post_exec = function(self_action, original, self_target, kwargs)
				local operation = self_target and self_target.operation or "unknown"
				if self_action.state.logging then
					self_action:log("[SA-Log BLOCKED] op=" .. operation)
				end
				local logs = self_action.state.intercepted_logs
				logs[#logs + 1] = { operation = operation, kwargs = kwargs, time = os.clock() }
				if #logs > 200 then
					table.remove(logs, 1)
				end
			end,
		},
		baselog_check_can_report = {
			spec = "patch.sa_log_comp.base_log:BaseLog:check_can_report",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return false
			end,
		},
		scriptlog_check_can_report = {
			spec = "patch.sa_log_comp.base_log:ScriptLog:check_can_report",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return false
			end,
		},
		acsdk_cheat_check_can_report = {
			spec = "patch.sa_log_comp.base_log:acsdk_cheat_check:check_can_report",
			override_orig_function = true,
			post_exec = function(self_action, original, ...)
				return false
			end,
		},

		-- ── SDK SA Log (imp_sa_log) ──────────────────────────────
		sdk_report_sa_log = {
			spec = "hexm.client.manager.sdk_comp.imp_sa_log:SdkManagerMember:report_sa_log",
			override_orig_function = true,
			post_exec = function(self_action, original, self_target, operation, kwargs)
				if self_action.state.logging then
					self_action:log("[SDK] report_sa_log(" .. tostring(operation) .. ")")
				end
			end,
		},
		sdk_report_script_log = {
			spec = "hexm.client.manager.sdk_comp.imp_sa_log:SdkManagerMember:report_script_log",
			override_orig_function = true,
			post_exec = function(self_action, original, self_target, log_type, kwargs)
				if self_action.state.logging then
					self_action:log("[SDK] report_script_log(" .. tostring(log_type) .. ")")
				end
			end,
		},
		sdk_report_qdata_log = {
			spec = "hexm.client.manager.sdk_comp.imp_sa_log:SdkManagerMember:report_qdata_log",
			override_orig_function = true,
			post_exec = function(self_action, original, self_target, operation, kwargs)
				if self_action.state.logging then
					self_action:log("[SDK] report_qdata_log(" .. tostring(operation) .. ")")
				end
			end,
		},
		sdk_report_time_status = {
			spec = "hexm.client.manager.sdk_comp.imp_sa_log:SdkManagerMember:report_time_status",
			override_orig_function = true,
			post_exec = function(self_action, original, self_target, reason)
				if self_action.state.logging then
					self_action:log("[SDK] report_time_status(" .. tostring(reason) .. ")")
				end
			end,
		},
	}
end

-- ── Lifecycle overrides ──
-- Override enable/disable to support force parameter.
-- Default (force=nil/false): hooks are preserved across disable/re-enable.
-- force=true: full teardown on disable, full re-apply on enable.

function ACB:enable(force)
	if not force and self:is_hooked("drpf_check_can_report") then
		self.state.is_enabled = true
		self:log("Already patched, skipping re-apply (use enable(true) to force)")
		return true
	end
	return ActionBase.enable(self)
end

function ACB:disable(force)
	if not force and self.state.patch_once then
		self.state.is_enabled = false
		self:log("Disabled (hooks preserved, patch_once=true). Use disable(true) to fully remove.")
		return true
	end
	return ActionBase.disable(self)
end

function ACB:on_enable()
	self:log("=== Enabling anticheat bypass ===")

	-- Category C: Non-hookable items
	self:_apply_debug_flags()
	self:_neutralize_native_anticheat()
	self:_patch_fields()

	-- Category B: Dynamic patch_all hooks (guard against re-registration)
	self:_register_dynamic_hooks()

	-- Category A + B: Activate all registered hooks
	self:hook_all()

	-- One-off: cancel running ACSDK timers + guard against mixin re-init
	self:_cancel_acsdk_timers()

	-- Verify patches
	self:verify_patches()

	self:log("=== Anticheat bypass enabled ===")
end

function ACB:on_disable()
	-- Only reached via disable(true) — full teardown
	self:_restore_native_originals()
	self:_restore_field_originals()
	self.state.dynamic_hook_names = {}
	self:log("=== Anticheat bypass fully removed ===")
end

-- ── Private: Category C — Debug flags (fire-and-forget, no restore) ──

function ACB:_apply_debug_flags()
	local visited = setmetatable({}, { __mode = "k" })

	local function walk(tbl, path, depth)
		if depth > MAX_FLAG_DEPTH or visited[tbl] then
			return
		end
		visited[tbl] = true
		for k, _ in next, tbl do
			local ok, v = pcall(rawget, tbl, k)
			if ok and type(k) == "string" and FLAGS_TO_SET[k] ~= nil then
				rawset(tbl, k, FLAGS_TO_SET[k])
			end
			if type(v) == "table" then
				walk(v, path .. tostring(k) .. ".", depth + 1)
			end
		end
	end

	local ROOT = rawget(_G, "DUMP_ROOT") or package.loaded
	local ROOT_NAME = rawget(_G, "DUMP_ROOT_NAME") or "ROOT"
	walk(ROOT, ROOT_NAME .. ".", 0)
	self:log("[Flags] Debug flags applied")
end

-- ── Private: Category C — Native anticheat (MHexAC / MQSec) ──

function ACB:_neutralize_native_anticheat()
	local originals = self.state.native_originals

	-- MHexAC
	if _G.MHexAC then
		if _G.MHexAC.SetCheckVkDownInvalidCallback then
			pcall(_G.MHexAC.SetCheckVkDownInvalidCallback, nil)
			self:log("[Native] MHexAC.SetCheckVkDownInvalidCallback(nil)")
		end

		if _G.MHexAC.SetRawInputCheckVKMask then
			originals[#originals + 1] = {
				tbl = _G.MHexAC,
				key = "SetRawInputCheckVKMask",
				val = rawget(_G.MHexAC, "SetRawInputCheckVKMask"),
			}
			_G.MHexAC.SetRawInputCheckVKMask = function(...)
				if self.state.logging then
					self:log("[Native] MHexAC.SetRawInputCheckVKMask blocked")
				end
			end
		end

		if _G.MHexAC.GetText then
			local orig_GetText = rawget(_G.MHexAC, "GetText")
			originals[#originals + 1] = { tbl = _G.MHexAC, key = "GetText", val = orig_GetText }
			_G.MHexAC.GetText = function(dll, func, size)
				if self.state.logging then
					self:log(
						"[Native] MHexAC.GetText("
							.. tostring(dll)
							.. ", "
							.. tostring(func)
							.. ", "
							.. tostring(size)
							.. ") → forwarded"
					)
				end
				return orig_GetText(dll, func, size)
			end
		end

		self:log("[Native] MHexAC hooks neutralized")
	else
		self:log("[Native] MHexAC not present")
	end

	-- MQSec
	if _G.MQSec then
		if _G.MQSec.UnLoadQSec then
			pcall(_G.MQSec.UnLoadQSec)
			self:log("[Native] MQSec unloaded")
		end
		originals[#originals + 1] = {
			tbl = _G.MQSec,
			key = "LoadQSec",
			val = rawget(_G.MQSec, "LoadQSec"),
		}
		_G.MQSec.LoadQSec = function()
			if self.state.logging then
				self:log("[Native] MQSec.LoadQSec blocked")
			end
			return 0
		end
		if _G.MQSec.TN1OO00OO then
			originals[#originals + 1] = {
				tbl = _G.MQSec,
				key = "TN1OO00OO",
				val = rawget(_G.MQSec, "TN1OO00OO"),
			}
			_G.MQSec.TN1OO00OO = NOOP
		end
		self:log("[Native] MQSec neutralized")
	else
		self:log("[Native] MQSec not present")
	end
end

function ACB:_restore_native_originals()
	local originals = self.state.native_originals
	for i = #originals, 1, -1 do
		local e = originals[i]
		rawset(e.tbl, e.key, e.val)
	end
	self.state.native_originals = {}
end

-- ── Private: Category C — Field replacements ──

function ACB:_patch_fields()
	local originals = self.state.field_originals

	-- Trace telemetry fields
	local trace_mod = portable.safe_import("hexm.client.trace")
	if trace_mod then
		for _, field in ipairs({ "TRACE_LIST", "TRACE_COUNTS", "TRACE_CACHE" }) do
			originals[#originals + 1] = { tbl = trace_mod, key = field, val = rawget(trace_mod, field) }
			rawset(trace_mod, field, Cocos.create_empty_proxy())
		end
		self:log("Patched hexm.client.trace (3 fields)")
	end

	-- drpf_config._report_drpf cached value
	local drpf_mod = portable.safe_import("patch.sa_log_comp.drpf_config")
	if drpf_mod then
		originals[#originals + 1] = {
			tbl = drpf_mod,
			key = "_report_drpf",
			val = rawget(drpf_mod, "_report_drpf"),
		}
		rawset(drpf_mod, "_report_drpf", false)
		self:log("Patched drpf_config._report_drpf → false")
	end
end

function ACB:_restore_field_originals()
	local originals = self.state.field_originals
	for i = #originals, 1, -1 do
		local e = originals[i]
		rawset(e.tbl, e.key, e.val)
	end
	self.state.field_originals = {}
end

-- ── Private: Category B — Dynamic patch_all hooks ──
-- Guards against re-registration on second enable(): if the hook
-- name is already known (from a prior enable cycle), skip
-- HookManager.register() and just re-activate via self:hook().

function ACB:_register_dynamic_hooks()
	local HookManager = _G.Reg.lib("HookManager")
	local known = {}
	for _, name in ipairs(self.state.dynamic_hook_names) do
		known[name] = true
	end
	local total = 0

	for _, target in ipairs(PATCH_ALL_TARGETS) do
		local mod = portable.safe_import(target.module_path)
		if not mod then
			self:log("[Dynamic] Module not found: " .. target.module_path)
			goto continue
		end

		local ok, cls = pcall(rawget, mod, target.class_name)
		if not ok or not cls then
			self:log("[Dynamic] Class not found: " .. target.class_name .. " in " .. target.module_path)
			goto continue
		end

		local count = 0
		for k, v in next, cls do
			if type(v) == "function" then
				local hook_name = target.prefix .. "_" .. k
				local spec = target.module_path .. ":" .. target.class_name .. ":" .. k

				if not known[hook_name] then
					-- First time: register the hook
					HookManager.register(self._name, hook_name, {
						spec = spec,
						override_orig_function = true,
						post_exec = function(self_action, original, self_target, ...)
							if self_action.state.logging then
								self_action:log("[Intercept] " .. spec .. " blocked")
							end
							return nil
						end,
					})
					self.state.dynamic_hook_names[#self.state.dynamic_hook_names + 1] = hook_name
				end
				-- Activate (hook_all will handle this, but track for logging)
				count = count + 1
			end
		end

		self:log(
			"[Dynamic] Registered " .. target.module_path .. ":" .. target.class_name .. " (" .. count .. " methods)"
		)
		total = total + count

		::continue::
	end

	self:log("[Dynamic] Total dynamic hooks: " .. total)
end

-- ── Private: Cancel ACSDK timers + mixin re-init guard ──

function ACB:_cancel_acsdk_timers()
	if _G.G and _G.G.sdk_manager then
		pcall(function()
			_G.G.sdk_manager:cancel_tick_acsdk_timer()
			self:log("[ACSDK] Cancelled live ACSDK timers via G.sdk_manager")
		end)
		-- Guard against Components() mixin re-running setup_acsdk
		pcall(function()
			_G.G.sdk_manager.acsdk_info_has_inited = false
		end)
	else
		self:log("[ACSDK] G.sdk_manager not available, timers not cancelled")
	end
end

-- ── Private: Verification helpers ──

function ACB:_verify_check(results, label, fn, expected_return)
	local ok, result = pcall(fn)
	if not ok then
		self:log("[Verify] FAIL " .. label .. " | error: " .. tostring(result))
		results[label] = "FAIL(error): " .. tostring(result)
		return false
	end
	if expected_return ~= nil and result ~= expected_return then
		self:log(
			"[Verify] FAIL " .. label .. " | expected=" .. tostring(expected_return) .. " got=" .. tostring(result)
		)
		results[label] = "FAIL(wrong): expected=" .. tostring(expected_return) .. " got=" .. tostring(result)
		return false
	end
	self:log("[Verify] PASS " .. label)
	results[label] = "PASS"
	return true
end

-- ── Public API ──

function ACB:verify_patches()
	self:log("[Verify] === Running patch verification ===")
	local results = {}
	local pass, fail = 0, 0

	local function check(label, fn, expected_return)
		if self:_verify_check(results, label, fn, expected_return) then
			pass = pass + 1
		else
			fail = fail + 1
		end
	end

	-- 1. DRPF upload gate
	local drpf_mod = portable.safe_import("patch.sa_log_comp.drpf_config")
	if drpf_mod then
		check("drpf_config.check_can_report_drpf() → false", function()
			return drpf_mod.check_can_report_drpf()
		end, false)
		check("drpf_config._report_drpf cached == false", function()
			return rawget(drpf_mod, "_report_drpf")
		end, false)
	end

	-- 2. SALogHandler intercept
	local handler_mod = portable.safe_import("patch.sa_log_handler")
	if handler_mod then
		local SALogHandler = rawget(handler_mod, "SALogHandler")
		if SALogHandler then
			check("SALogHandler.log is patched (no upload on call)", function()
				SALogHandler.log({ operation = "__acb_verify__" }, "__verify_op__", {})
			end)
			check("SALogHandler.get_dict returns empty table", function()
				local r = SALogHandler.get_dict({ operation = "__acb_verify__" }, "__verify_op__", {})
				assert(type(r) == "table", "expected table, got " .. type(r))
			end)
		end
	end

	-- 3. BaseLog family
	local base_log_mod = portable.safe_import("patch.sa_log_comp.base_log")
	if base_log_mod then
		for _, cls_name in ipairs({ "BaseLog", "ScriptLog", "acsdk_cheat_check" }) do
			local cls = rawget(base_log_mod, cls_name)
			if cls and rawget(cls, "check_can_report") then
				check(cls_name .. ".check_can_report() → false", function()
					return cls.check_can_report({ operation = "__acb_verify__" })
				end, false)
			end
		end
	end

	-- 4. SpaceTag inspection gates
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
				end
			end
		end
	end

	-- 5. SdkManager ACSDK tick methods
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
					check("SdkManager." .. m .. " is NOOP", function()
						fn({})
					end)
				end
			end
		end
	end

	-- 6. QdataLogHandler
	local qdata_mod = portable.safe_import("hexm.client.net.qdata_log_handler")
	if qdata_mod then
		local QdataLogHandler = rawget(qdata_mod, "QdataLogHandler")
		if QdataLogHandler then
			for _, m in ipairs({ "log_qdata", "post_to_qdata" }) do
				local fn = rawget(QdataLogHandler, m)
				if fn then
					check("QdataLogHandler." .. m .. " is patched", function()
						fn({})
					end)
				end
			end
		end
	end

	-- 7. DamageStatsManager
	local dmg_mod = portable.safe_import("hexm.common.combat.anti_cheating.damage_stats_manager")
	if dmg_mod then
		local DamageStatsManager = rawget(dmg_mod, "DamageStatsManager")
		if DamageStatsManager and rawget(DamageStatsManager, "_check_need_stats") then
			check("DamageStatsManager._check_need_stats() → false", function()
				return DamageStatsManager._check_need_stats({})
			end, false)
		end
	end

	self:log(("[Verify] === Done: %d passed, %d failed ==="):format(pass, fail))
	return results, pass, fail
end

function ACB:get_intercepted_logs()
	return self.state.intercepted_logs
end

function ACB:clear_intercepted_logs()
	self.state.intercepted_logs = {}
end

function ACB:get_log_summary()
	local logs = self.state.intercepted_logs
	local by_op = {}
	for _, entry in ipairs(logs) do
		by_op[entry.operation] = (by_op[entry.operation] or 0) + 1
	end
	return by_op
end

function ACB:set_logging(enabled)
	self.state.logging = enabled ~= false
	self:log("Logging " .. (self.state.logging and "enabled" or "disabled"))
end

function ACB:get_logging()
	return self.state.logging
end

function ACB:set_patch_once(enabled)
	self.state.patch_once = enabled ~= false
	self:log("Patch-once " .. (self.state.patch_once and "enabled" or "disabled"))
end

function ACB:get_patch_once()
	return self.state.patch_once
end

return ACB:new()
