local function probe_print(...)
    local parts = { "[report_sa_log_probe]" }
    for i = 1, select("#", ...) do
        parts[#parts + 1] = tostring(select(i, ...))
    end
    print(table.concat(parts, " | "))
end

local function merge(dst, src)
    if not src then
        return
    end
    for k, v in pairs(src) do
        dst[k] = v
    end
end

local traceback = debug and debug.traceback or function(err)
    return tostring(err)
end

local function safe_call(label, fn)
    local ok, a, b, c = xpcall(fn, traceback)
    if ok then
        probe_print(label, "ok", a, b, c)
    else
        probe_print(label, "err", a)
    end
    return ok, a, b, c
end

probe_print("BEGIN")

local G = rawget(_G, "G") or require("hexm.client.G")
local sdk = G and G.sdk_manager
if not sdk then
    probe_print("sdk_manager_missing")
    return
end

local handler = sdk.sa_log_handler
local patch_utils = require("patch.patch_utils")
local drpf_config = require("patch.sa_log_comp.drpf_config")

probe_print("sdk_manager", sdk, "report_sa_log", sdk.report_sa_log)
probe_print("drpf_gate_before", drpf_config.check_can_report_drpf())

local interesting_ops = {
    "Load",
    "Cheat",
    "acsdk_cheat_check",
    "inspection_check_speed",
    "inspection_check_trans2",
    "pve_dmg_inspection",
    "__probe_invalid__",
}

if handler and handler.operators then
    for _, op in ipairs(interesting_ops) do
        probe_print("operator", op, handler.operators[op] ~= nil, handler.operators[op])
    end
else
    probe_print("handler_or_operators_missing", handler)
end

safe_call("get_log_dict_Cheat", function()
    local d = sdk:get_log_dict("Cheat")
    probe_print(
        "get_log_dict_Cheat_data",
        "type=" .. tostring(d.type),
        "project=" .. tostring(d.project),
        "source=" .. tostring(d.source),
        "account_id=" .. tostring(d.account_id),
        "role_id=" .. tostring(d.role_id),
        "server=" .. tostring(d.server)
    )
end)

safe_call("get_log_dict_acsdk_cheat_check", function()
    local d = sdk:get_log_dict("acsdk_cheat_check")
    probe_print(
        "get_log_dict_acsdk_data",
        "type=" .. tostring(d.type),
        "account_id=" .. tostring(d.account_id),
        "role_id=" .. tostring(d.role_id),
        "avatar_id=" .. tostring(d.avatar_id),
        "server=" .. tostring(d.server),
        "os_name=" .. tostring(d.os_name)
    )
end)

safe_call("get_log_dict_pve_dmg_inspection", function()
    local d = sdk:get_log_dict("pve_dmg_inspection")
    probe_print("get_log_dict_pve_dmg_inspection_data", d)
end)

local original_gate = drpf_config.check_can_report_drpf
drpf_config.check_can_report_drpf = function(...)
    local original_result = original_gate(...)
    probe_print("gate_check", "original=" .. tostring(original_result), "forced=true")
    return true
end

local original_handler_log = handler and handler.log or nil
if handler and original_handler_log then
    function handler:log(operation, kwargs)
        local has_operator = self.operators and self.operators[operation] ~= nil
        probe_print("handler_log", operation, "has_operator=" .. tostring(has_operator))
        return original_handler_log(self, operation, kwargs)
    end
end

local wrapped_ops = {}
local wrap_targets = {
    "Cheat",
    "acsdk_cheat_check",
    "inspection_check_speed",
}

if handler and handler.operators then
    for _, op in ipairs(wrap_targets) do
        local obj = handler.operators[op]
        if obj and obj.log then
            wrapped_ops[op] = obj.log
            obj.log = function(self, kwargs)
                probe_print("operator_log_enter", op, "kwargs_type=" .. type(kwargs))
                local info_dict = self:get_dict()
                merge(info_dict, self:get_base_changeable_data())
                if kwargs then
                    merge(info_dict, kwargs)
                    self:filter_key(info_dict)
                end
                local allowed = self:check_can_report(info_dict)
                probe_print("operator_log_allowed", op, allowed)
                if not allowed then
                    return nil
                end
                local msg = patch_utils.rjson_encode(info_dict)
                probe_print("operator_log_json", op, msg)
                return msg
            end
        else
            probe_print("operator_wrap_missing", op, obj)
        end
    end
end

safe_call("report_Cheat", function()
    sdk:report_sa_log("Cheat", {
        cheat_type = "probe_distance",
        probe_id = "report_sa_log_probe",
        type = "user_supplied_type",
        project = "user_proj",
        source = "user_src",
    })
end)

safe_call("report_acsdk_cheat_check", function()
    sdk:report_sa_log("acsdk_cheat_check", {
        ac_info = {
            operation = "ProbeAC",
            ret_code = 999,
            report_id = "probe-report-id",
        },
        probe_extra = "acsdk",
    })
end)

safe_call("report_inspection_check_speed", function()
    sdk:report_sa_log("inspection_check_speed", {
        info = { reason = "probe_runtime" },
        space_id = -1,
        space_type = -1,
        type = "probe_inner_type",
    })
end)

safe_call("report_pve_dmg_inspection", function()
    sdk:report_sa_log("pve_dmg_inspection", {
        reason = "probe_pve",
    })
end)

safe_call("report_invalid", function()
    sdk:report_sa_log("__probe_invalid__", {
        reason = "probe_invalid",
    })
end)

for op, original_log in pairs(wrapped_ops) do
    handler.operators[op].log = original_log
end
if handler and original_handler_log then
    handler.log = original_handler_log
end
drpf_config.check_can_report_drpf = original_gate

probe_print("END")
