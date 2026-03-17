# Question / Scope

Analyze how the game's anticheat engine works using only authoritative sources in `Scripts/source_decompiled` and `Scripts/data/DirObject`, with focus on `anti_cheating`, `sa_log_comp`, `imp_inspection`, `imp_anticheat`, and `acsdk`.

# Evidence

- Source: `Scripts/source_decompiled/hexm/client/engine/engine.lua`
  Excerpt: `if not self._is_windows or not MHexAC then return end` and `self._mqsec_loaded = 1 == MQSec.LoadQSec()`
  Why it matters: The engine only enables the local native anticheat hooks when `MHexAC` is present on Windows, and it optionally loads a second native module, `MQSec`.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/engine/engine.lua`
  Excerpt: `MHexAC.SetCheckVkDownInvalidCallback(function(make_code, virtual_code)` and `ret = MHexAC.GetText("kernel32.dll", "QueryPerformanceCounter", 12)`
  Why it matters: `MHexAC` is not a passive library. The client uses it for low-level input callbacks and for reading code bytes from Windows timing APIs, which is consistent with hook/tamper detection.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/manager/sdk_comp/imp_anticheat.lua`
  Excerpt: `self._acc_mgr:SetupACSDK(game_id, secret_key, acsdk_host)` and `self._acc_mgr:CallACSDK(scriptId)`
  Why it matters: There is a separate ACSDK service layer. The client initializes it through the account manager, then periodically calls it after setup succeeds.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/patch/unisdk_consts.lua`
  Excerpt: `_M.ACSDK_HOST = "acsdk.gameyw.netease.com"` and `_M.ACSDK_GAME_ID = "android_h72"` / `"ios_h72"` / `"h72"`
  Why it matters: ACSDK is environment-specific. Host, secret, and game ID change by region and platform, so this is a deployed remote anticheat service rather than a local-only checker.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/manager/sdk_comp/imp_anticheat.lua`
  Excerpt: `self._acc_mgr:SetACSDKExtraParams(info_list)` and `self:report_sa_log("acsdk_cheat_check", ac_info)`
  Why it matters: ACSDK setup/call results are wrapped in the SA log pipeline, and the client sends account/device/session context alongside ACSDK operations.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/patch/sa_log_comp/drpf_config.lua`
  Excerpt: `_M.acsdk_info_key = { "server", "os_ver", "role_name", "ip", "app_channel", "avatar_id", "account_id", "role_id", "engine_ver", "udid", "os_name" }`
  Why it matters: The SA log layer explicitly defines the base metadata attached to ACSDK cheat-check reports.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/patch/sa_log_comp/base_log.lua`
  Excerpt: `local msg = patch_utils.rjson_encode(info_dict)` and `self.accountMgr:DRPF(msg)`
  Why it matters: `sa_log_comp` is the serialization/upload path. It packages the anticheat report into DRPF JSON and pushes it through the account manager.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/patch/sa_log_comp/drpf_config.lua`
  Excerpt: `inspection_check_speed2 = {}`, `inspection_check_other = {}`, `inspection_check_trans2 = {}`, `inspection_check_speed = {}`, `inspection_check_rawinput = {}`, `inspection_check_pvp_speed_stack = {}`, `inspection_check_teleport = {}`, `inspection_check_global_speed = {}`, `inspection_check_invincible = {}`
  Why it matters: The SA log pipeline is explicitly provisioned to accept the inspection-related anticheat operations.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/inspection/imp_inspection.lua`
  Excerpt: `self:_do_check_cheat_info()` is scheduled by `EngineTimerMgr.add_repeat_timer(0, 1, -1, ...)`
  Why it matters: The main player anticheat inspection runs continuously once per second while enabled, so this is an active runtime monitor rather than a one-shot scan.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/inspection/imp_inspection.lua`
  Excerpt: `G.sdk_manager:report_sa_log("inspection_check_speed", log_info)`, `G.sdk_manager:report_sa_log("inspection_check_speed2", log_info)`, `G.sdk_manager:report_sa_log("inspection_check_other", log_info)`, `G.sdk_manager:report_sa_log("inspection_check_global_speed", log_info)`, `G.sdk_manager:report_sa_log("inspection_check_invincible", log_info)`, `G.sdk_manager:report_sa_log("inspection_check_pvp_speed_stack", log_info)`
  Why it matters: The self-inspection layer checks multiple cheat classes: speed manipulation, delta-time anomalies, animation/charctrl anomalies, global timer tampering, invincibility state, and PVP speed-stack abuse.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/inspection/imp_inspection.lua`
  Excerpt: `G.engine:add_rawinput_check_callback("inspection_check_rawinput", ...)` and `G.net:call_server("rpc_on_inspection_check_log", "inspection_video_urls", { ["video_urls"] = self._wait_log_inspection_video_urls })`
  Why it matters: The inspection layer combines native input checks with evidence capture. On suspicious events it can record local video, upload it, and send the resulting URLs back to the server.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/common_members/inspection/imp_inspection.lua`
  Excerpt: `data.inspection_check_reason = "check_other"` / `"check_monster"` in derived classes, and `G.sdk_manager:report_sa_log("inspection_check_trans2", log_info)`
  Why it matters: `imp_inspection` is not only for the local player. The client also inspects other avatars and boss NPCs for movement/collision/speed anomalies and reports them with reason tags.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/space_common.lua`
  Excerpt: `SpaceTag:check_enable_inspection()`, `SpaceTag:check_enable_pvp_network_detect()`, and `SpaceTag:check_enable_pvp_teleport_detect()` all check hardcoded `NEED_*` space-type sets
  Why it matters: Anticheat inspection is space-gated. The runtime checks are enabled only for selected space types, especially PVP and some high-risk modes.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/inspection/imp_inspection.lua`
  Excerpt: `client:set_netstats_enabled(true, 10, 15, 50, 15, 10000000, 20, 15, 50, 15, 10000000, 10)` and later `G.sdk_manager:report_sa_log("pvp_network", info)`
  Why it matters: PVP anticheat includes a network-observation branch that collects RTT, retransmit, drop-window, and send/receive stats and uploads them as a separate signal.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/inspection/imp_inspection.lua`
  Excerpt: `if 5 == self._pvp_cheat_teleport_count then ... G.sdk_manager:report_sa_log("inspection_check_teleport", log_info)`
  Why it matters: PVP teleport detection is a dedicated branch. The client watches repeated idle-position jumps and escalates after a threshold.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/combat/anti_cheating/damage_stats_manager.lua`
  Excerpt: `DamageStatsManager():begin_damage_statistics(...)`, `process_damage_statistics(...)`, `end_damage_statistics(...)`, then `self:check_stage_id_consistency(damage_stats_info)` and `self:check_damage_recompute(damage_stats_info)`
  Why it matters: There is a separate combat anticheat subsystem that tags a damage flow with `anti_cheating_id`, records begin/process/end snapshots, and validates consistency plus recomputed damage output.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/common/combat/anti_cheating/damage_stats_manager.lua`
  Excerpt: `G.sdk_manager:report_sa_log("pve_dmg_inspection", { ["reason"] = "check_stage_id", ... })` and `G.sdk_manager:report_sa_log("pve_dmg_inspection", { ["reason"] = "check_dmg_recompute", ... })`
  Why it matters: Combat anticheat is intended to raise SA-log events when damage stage IDs disagree or when recomputed formula results diverge from the recorded damage.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/patch/sa_log_handler.lua` and `Scripts/source_decompiled/patch/sa_log_comp/drpf_config.lua`
  Excerpt: `for clz_name, all_keys in pairs(drpf_config.operationKeys) do self.operators[clz_name] = get_handler(clz_name, all_keys) end` and `function SALogHandler:log(operation, kwargs) if self.operators[operation] then ... end end`
  Why it matters: SA-log operations only exist if they are declared in `drpf_config.operationKeys`. A missing operation name is silently ignored by `SALogHandler:log`.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/patch/sa_log_comp/drpf_config.lua` and scoped search over `Scripts/source_decompiled/patch`
  Excerpt: `acsdk_cheat_check = {}` exists, but no `pve_dmg_inspection` entry is present in the current `patch` log configuration scope
  Why it matters: The combat anticheat path appears to generate `pve_dmg_inspection` events, but the current client SA-log registry does not expose that operation. This suggests the combat signal is currently not wired into the DRPF uploader in the visible Lua layer.
  Evidence Confidence: 4/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/interact/imp_active_interact.lua`
  Excerpt: `G.sdk_manager:report_sa_log("Cheat", msg)` when active interaction is outside the allowed distance
  Why it matters: Anticheat is broader than the inspection files. There are smaller gameplay-specific cheat reports that feed the same SA-log system.
  Evidence Confidence: 4/5

# Conclusions

- The game's anticheat is a layered system, not a single module. It combines native runtime checks (`MHexAC`, optional `MQSec`), a remote ACSDK service, client-side inspection scripts, and SA-log / RPC evidence transport. Evidence Confidence: 5/5

- `imp_anticheat.lua` is the ACSDK integration layer. It initializes ACSDK with platform/region-specific credentials, attaches base account/device metadata, and periodically calls ACSDK after login. Evidence Confidence: 5/5

- `sa_log_comp` is primarily the telemetry transport layer for anticheat-related events. It defines accepted operation names, attaches common metadata, serializes reports to DRPF JSON, and sends them through the account manager. Evidence Confidence: 5/5

- `imp_inspection.lua` is the main client runtime detector. It performs continuous local checks for speed hacks, delta-time manipulation, rawinput anomalies, global timer tampering, invincibility state, PVP teleport behavior, PVP network abnormalities, and speed-stack misuse; it can also capture and upload video evidence. Evidence Confidence: 5/5

- Inspection is space-gated and risk-targeted. The client only enables the heavier runtime checks in selected space types, especially PVP and related competitive modes. Evidence Confidence: 5/5

- The combat-side `anti_cheating` subsystem is a separate PvE damage-consistency checker that records damage pipeline snapshots and recomputes formulas, but its `pve_dmg_inspection` log path appears unwired in the visible SA-log registry. Evidence Confidence: 4/5

# Unknown / Missing Evidence

- Server-side handlers for `rpc_on_inspection_check_log` and `rpc_on_inspection_check_data` were not found in the current investigation scope. Enforcement and punishment logic therefore remain unknown.

- Native implementations of `MHexAC`, `MQSec`, and ACSDK are outside the Lua scope. The Lua layer proves integration points and usage, but not the exact native detection logic.

- Targeted scoped searches in `Scripts/data/DirObject` for `acsdk`, `anticheat`, `inspection_video_name`, `enable_inspection`, `pvp_network_detect`, and `teleport_detect` did not produce a reliable configuration mapping in the current scope. The visible enablement logic appears hardcoded in `space_common.lua`.

- It is still possible that `pve_dmg_inspection` is handled outside the visible Lua SA-log registry, but that path was not found in the current scoped review.

# Next Scoped Search Steps

- Search server-side authoritative Lua for handlers of `rpc_on_inspection_check_log` and `rpc_on_inspection_check_data` to find actual enforcement logic.

- Search native binding surfaces for `MHexAC`, `MQSec`, `SetupACSDK`, `CallACSDK`, and `GetACSDKReportID` to identify exact return-code semantics and escalation behavior.

- Trace how `MAccount:GetAccountManager():DRPF(...)` is transmitted on the wire to determine whether different anticheat operations land in distinct backend pipelines.
