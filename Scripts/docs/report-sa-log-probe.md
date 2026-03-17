# Question / Scope

Probe the runtime behavior of `G.sdk_manager:report_sa_log(...)` and compare it with the visible Lua implementation in `patch/sa_log_handler.lua` and `patch/sa_log_comp/base_log.lua`.

# Evidence

- Source: `Scripts/source_decompiled/patch/sa_log_handler.lua`
  Excerpt: `function SALogHandler:log(operation, kwargs) if self.operators[operation] then ... self.operators[operation]:log(kwargs) end end`
  Why it matters: `report_sa_log` only does work when `operation` is registered in `drpf_config.operationKeys`. Unregistered operations are silently ignored.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/patch/sa_log_handler.lua`
  Excerpt: `function SALogHandler:get_dict(operation, kwargs) local info = self.operators[operation]:get_dict()`
  Why it matters: `get_log_dict` has no nil guard. If `operation` is not registered, it will error instead of silently no-oping.
  Evidence Confidence: 5/5

- Source: `Scripts/logs/script_debug.txt`
  Excerpt: `[report_sa_log_probe] | drpf_gate_before | true`
  Why it matters: In the current live session, DRPF reporting is already enabled. Valid `report_sa_log` calls are upload-eligible without any extra local toggle.
  Evidence Confidence: 5/5

- Source: `Scripts/logs/script_debug.txt`
  Excerpt: `[report_sa_log_probe] | operator | Cheat | true`, `acsdk_cheat_check | true`, `inspection_check_speed | true`, `pve_dmg_inspection | false`
  Why it matters: The live handler registry matches the source analysis: common anticheat ops are registered, but `pve_dmg_inspection` is not.
  Evidence Confidence: 5/5

- Source: `Scripts/logs/script_debug.txt`
  Excerpt: `[report_sa_log_probe] | get_log_dict_pve_dmg_inspection | err | patch/sa_log_handler.lua:39: attempt to index a nil value`
  Why it matters: The runtime confirms the code-path difference between `get_log_dict` and `report_sa_log` for missing operations.
  Evidence Confidence: 5/5

- Source: `Scripts/logs/script_debug.txt`
  Excerpt: `[report_sa_log_probe] | handler_log | pve_dmg_inspection | has_operator=false` followed by `[report_sa_log_probe] | report_pve_dmg_inspection | ok | nil | nil | nil`
  Why it matters: `report_sa_log("pve_dmg_inspection", ...)` returns normally and does not throw, but it also does not produce a log payload because the operator is missing.
  Evidence Confidence: 5/5

- Source: `Scripts/logs/script_debug.txt`
  Excerpt: `[report_sa_log_probe] | handler_log | __probe_invalid__ | has_operator=false` followed by `[report_sa_log_probe] | report_invalid | ok | nil | nil | nil`
  Why it matters: Arbitrary invalid operation names are silently ignored in the same way as `pve_dmg_inspection`.
  Evidence Confidence: 5/5

- Source: `Scripts/logs/script_debug.txt`
  Excerpt: `operator_log_json | Cheat | {... "_source":"user_src", "_project":"user_proj", "source":"netease_p1", "project":"h72naxx2gb", "_type":"user_supplied_type", "type":"Cheat", ...}`
  Why it matters: `report_sa_log` canonicalizes `type`, `project`, and `source` to engine-controlled values, while preserving caller-supplied conflicting values under `_type`, `_project`, and `_source`.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/patch/sa_log_comp/base_log.lua`
  Excerpt: `if kwargs.type ~= self.operation then kwargs._type = kwargs.type kwargs.type = self.operation end` and similar logic for `project` / `source`
  Why it matters: The runtime payload rewrite matches the implementation exactly.
  Evidence Confidence: 5/5

- Source: `Scripts/logs/script_debug.txt`
  Excerpt: `operator_log_json | Cheat | {"udid":...,"device_model":...,"role_id":"4103400764",...}` versus `operator_log_json | acsdk_cheat_check | {"account_id":...,"avatar_id":...,"role_id":"4103400764","server":10410,...}`
  Why it matters: Different operation types carry different base dictionaries. `Cheat` / inspection ops use the broader common-key set, while `acsdk_cheat_check` uses the narrower ACSDK info-key set.
  Evidence Confidence: 5/5

- Source: `Scripts/logs/script_debug.txt`
  Excerpt: `[report_sa_log_probe] | report_Cheat | ok | nil | nil | nil`, `[report_sa_log_probe] | report_acsdk_cheat_check | ok | nil | nil | nil`, `[report_sa_log_probe] | report_inspection_check_speed | ok | nil | nil | nil`
  Why it matters: `report_sa_log` does not return the encoded payload. Its observable return is `nil` in both successful and ignored cases.
  Evidence Confidence: 4/5

# Conclusions

- `G.sdk_manager:report_sa_log(operation, kwargs)` is a registry-driven dispatcher. If `operation` is registered, it builds a payload and submits it through the SA-log pipeline; if not, it silently does nothing. Evidence Confidence: 5/5

- `G.sdk_manager:get_log_dict(operation)` behaves differently: it requires a registered operation and will error on missing ones. Evidence Confidence: 5/5

- In the current live session, SA-log reporting is enabled (`drpf_gate_before = true`), so valid anticheat log operations are active. Evidence Confidence: 5/5

- The payload builder forcibly normalizes `type`, `project`, and `source`, preventing callers from spoofing those top-level identifiers directly. The original caller-provided values are preserved in `_type`, `_project`, and `_source`. Evidence Confidence: 5/5

- `Cheat` and `inspection_check_speed` use the broad common telemetry envelope, while `acsdk_cheat_check` uses a smaller ACSDK-specific envelope. Evidence Confidence: 5/5

- `pve_dmg_inspection` is still not registered in the live SA-log handler, so combat anticheat calls to `report_sa_log("pve_dmg_inspection", ...)` currently no-op at this Lua layer. Evidence Confidence: 5/5

# Unknown / Missing Evidence

- This probe intercepted payload construction locally and did not observe the real backend response path, so server-side acceptance or rejection of each payload shape remains unknown.

- Native and backend semantics of `MAccount:GetAccountManager():DRPF(...)` remain outside the current probe scope.

- The probe did not test every registered SA-log operation; it focused on `Cheat`, `acsdk_cheat_check`, `inspection_check_speed`, and missing-op behavior.

# Next Scoped Search Steps

- Probe `MAccount:GetAccountManager():DRPF(...)` directly with a temporary wrapper if backend call timing or invocation count matters.

- Search server-side handlers for any consequences attached to specific SA-log operation names versus RPC-based inspection reports.

- If needed, run one more runtime probe that wraps `BaseLog:check_can_report(...)` and `MAccount:GetAccountManager():DRPF(...)` without replacing payload emission, to confirm the exact production call chain.
