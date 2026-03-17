local SyncObserver = {}
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Utils = Reg.get("Utils")
local HookInterceptor = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\lib\\hook_interceptor.lua", "HookInterceptor")
local cmsgpack = Utils.safe_import("cmsgpack")
local events = Utils.safe_import("hexm.client.consts.events")
-- ============================================================
-- CONFIGURATION
-- ============================================================

SyncObserver.CONFIG = {
	LOG_ENABLED = true,
	-- Bone collision callback is contact-time; auto-parry here is usually too late online.
}

-- ============================================================
-- STATE
-- ============================================================

local _enabled = false
local _interceptor = nil
local _INDEX2RPC = nil
local _SyncEvent = nil
local _cmsgpack = nil
local _seen_events = {}
local _event_counts = { inbound_rpc = {}, inbound_sync = {} }
local _INBOUND_METHODS_IGNORE = {
	["chat_receive_pack_message_list"] = true,
	["equip_auto_repair_cb"] = true,
}

-- predict_behit POC state
local _predictions = {} -- npc_id -> {skill_id, anim, anim_start_ts, hits=[{collider, ts, predicted_time}]}
local _abc_cache = nil -- G.datam.anim_bone_colliders
local _DateTimeManager = nil
local _npc_learned = {} -- anim_name -> {hit_key -> {ts_sum, count, ts_avg}}
local _al_static = nil -- al_static_index.json (lazy-loaded)
local USEFUL_NPC_EVENTS = {
	E_SKILL_ANIM_BEGIN_CLIENT = true,
	E_GD_SIGNAL = true,
	E_BONE_COLLISION = true,
	E_BEHIT_BEGAN = true,
	E_DAMAGE_BEHIT_BEGAN = true,
	E_BE_PARRY = true,
	E_SKILL_START = true,
	E_SKILL_RELEASE = true,
	E_SKILL_END = true,
}

-- ============================================================
-- LOGGING
-- ============================================================

-- local function _log(msg)
-- 	if not SyncObserver.CONFIG.LOG_ENABLED then
-- 		return
-- 	end
-- 	if Logger then
-- 		Logger.log("[SyncObs] " .. msg, SyncObserver.CONFIG.LOG_FILE)
-- 	end
-- end

local function _log(fmt, ...)
	-- Format message if extra params exist
	local msg
	if select("#", ...) > 0 then
		msg = string.format(fmt, ...)
	else
		msg = fmt
	end

	Logger.log(string.format("%s", msg))
end
-- ============================================================
-- SYNC EVENT RESOLUTION via SyncEvent:get_name()
-- ============================================================

local function _get_sync_event()
	if _SyncEvent then
		return _SyncEvent
	end
	local ok, mod = pcall(Utils.safe_import, "hexm.common.consts.sync_consts")
	if ok and mod then
		_SyncEvent = mod.SyncEvent or mod.SE
	end
	return _SyncEvent
end

local function _resolve_event_name(event_id)
	local SE = _get_sync_event()
	if not SE then
		return nil
	end
	local ok, name = pcall(function()
		return SE:get_name(event_id)
	end)
	if ok and name then
		return name
	end
	return nil
end

local function _format_event(event_id)
	local name = _resolve_event_name(event_id)
	if name then
		return name .. "(" .. tostring(event_id) .. ")"
	end
	return "UNKNOWN(" .. tostring(event_id) .. ")"
end

-- Richer event info via SyncEvent:get_value_by_id() -> {func_name, module_name, cls_name, sync_pkg}
local function _format_event_detail(event_id)
	event_id = tonumber(event_id) or event_id
	local SE = _get_sync_event()
	if not SE then
		return _format_event(event_id)
	end
	local ok, data = pcall(function()
		return SE:get_value_by_id(event_id)
	end)
	if ok and data then
		local func = ""
		local cls = ""
		pcall(function()
			func = data:get("func_name", "?")
		end)
		pcall(function()
			cls = data:get("cls_name", "?")
		end)
		local name = _resolve_event_name(event_id) or "?"
		return name .. "(" .. tostring(event_id) .. ") [" .. cls .. ":" .. func .. "]"
	end
	return _format_event(event_id)
end

local function _try_unpack(packed)
	local ok, decoded = pcall(cmsgpack.unpack, packed)
	if ok then
		return decoded
	end
	return packed
end

-- ============================================================
-- HELPERS
-- ============================================================

-- ============================================================
-- HOOK CALLBACK: INBOUND SERVER RPCs (ClientEntity:entity_method)
-- ALL server->client RPCs go through this method.
-- ============================================================

local function _on_entity_method(parsed, call_args, results, traceback)
	-- call_args: [1]=self(entity), [2]=md5, [3]=index, [4]=args(parameters)
	local entity = call_args[1]
	local md5 = call_args[2]
	local index = call_args[3]
	local args = call_args[4]

	-- Lazy-load INDEX2RPC
	if not _INDEX2RPC then
		local ok, mod = pcall(require, "common.RpcIndex")
		if ok and mod then
			_INDEX2RPC = mod.INDEX2RPC
		end
		if not _INDEX2RPC then
			_log("ERROR: RpcIndex module not found, cannot resolve RPC method names")
			return
		end
	end

	-- Resolve method name from index
	local methodname = nil
	pcall(function()
		methodname = _INDEX2RPC:get(index, md5)
	end)
	if not methodname then
		_log("WARNING: Unrecognized RPC index " .. tostring(index) .. " with MD5 " .. tostring(md5))
		return
	end

	if _INBOUND_METHODS_IGNORE[methodname] then
		return
	end

	-- Track counts
	_event_counts.inbound_rpc[methodname] = (_event_counts.inbound_rpc[methodname] or 0) + 1

	-- Track first occurrence
	local key = "RPC|" .. methodname
	local is_new = not _seen_events[key]
	if is_new then
		_seen_events[key] = true
	end
	local rpc_tag = is_new and "OUT*" or "OUT "

	local entity_info = tostring(entity)

	-- Try to resolve sync event name from first arg if it's a number
	local event_label = ""
	pcall(function()
		if args and args[1] then
			local event_id = args[1]
			if type(event_id) == "number" then
				event_label = _format_event(event_id)
			else
				event_label = tostring(event_id)
			end
		end
	end)

	-- Decode msgpack-packed args (args[2]=packed_args, args[3]=packed_kwargs)

	-- check length
	local e_args = tostring(args)
	local e_kwargs = ""
	if methodname == "client_sync" then
		local ok2, v2 = pcall(function()
			return args[2]
		end)
		if ok2 and v2 then
			e_args = tostring(_try_unpack(v2))
		end
		local ok3, v3 = pcall(function()
			return args[3]
		end)
		if ok3 and v3 then
			e_kwargs = tostring(_try_unpack(v3))
		end
	end
	if methodname == "batch_client_sync" then
		for i, raw in pairs(args) do
			local unpacked = raw:unpack()
			local event_id, packed_args, packed_kwargs = unpacked[1], unpacked[2], unpacked[3]
			packed_args = _try_unpack(packed_args)
			packed_kwargs = _try_unpack(packed_kwargs)
			_log(
				rpc_tag
					.. "| batch_client_sync["
					.. i
					.. "] | "
					.. _format_event(event_id)
					.. " | eid=["
					.. entity_info
					.. "] | args="
					.. tostring(packed_args)
					.. " | kwargs="
					.. tostring(packed_kwargs)
			)
		end
		return
	end

	_log(
		rpc_tag
			.. "| "
			.. methodname
			.. " | "
			.. event_label
			.. " | eid=["
			.. entity_info
			.. "] | args="
			.. e_args
			.. " | kwargs="
			.. e_kwargs
	)
end

-- ============================================================
-- HOOK CALLBACK: INBOUND SYNC (SyncHandler:do_sync)
-- After RPC dispatch, sync events land here with decoded args.
-- ============================================================

local function _on_inbound_do_sync(parsed, call_args, results, traceback)
	local handler = call_args[1]
	local sync_id = call_args[2]
	local args = call_args[3]
	local kwargs = call_args[4]

	local event_label = _format_event_detail(sync_id)
	local owner_info = tostring(handler)

	_event_counts.inbound_sync[event_label] = (_event_counts.inbound_sync[event_label] or 0) + 1

	local key = "IN|" .. event_label
	local is_new = not _seen_events[key]
	if is_new then
		_seen_events[key] = true
	end
	local sync_tag = is_new and "IN*" or "IN "

	_log(
		sync_tag
			.. "| "
			.. event_label
			.. " | owner=["
			.. owner_info
			.. "] | args="
			.. Utils.dump_value(args)
			.. " | kwargs="
			.. Utils.dump_value(kwargs)
	)
end

local function _intercept_listenable(spec, args, results, traceback)
	local entity = args[1]
	local ins_str = tostring(entity)
	local channel = args[2]
	local event = args[3]
	local event_data = args[4]
	local event_str = tostring(event)
	local ev_name = Utils.get_key_by_value(events, event) or "N/A"
	local IGNORE_ENT = {
		["LocalSpace"] = true,
	}

	for ent_name, _ in pairs(IGNORE_ENT) do
		if ins_str:find(ent_name) then
			return
		end
	end
	if ev_name ~= "E_ENTITY_ADD_BUFF" then
		return
	end

	_log(
		string.format(
			"CLIENT_EVENT | >>>>>>>>> [%s] Channel: %s - Event: %s - Code: %s - Data: %s",
			ins_str,
			channel,
			ev_name,
			event_str,
			Utils.dump_value(event_data)
		)
	)
	_log(debug.traceback())
end

-- ============================================================
-- PUBLIC API
-- ============================================================

function SyncObserver.enable()
	if _enabled then
		return false, "Already enabled"
	end
	_seen_events = {}
	_event_counts = { inbound_rpc = {}, inbound_sync = {} }

	local SYNC_MOD = "hexm.client.entities.local.sync.sync_handler"

	_interceptor = HookInterceptor.create({
		{
			spec = "client.ClientEntity:ClientEntity:entity_method",
			post_exec = _on_entity_method,
		},
		{
			spec = SYNC_MOD .. ":SyncHandler:do_sync",
			post_exec = _on_inbound_do_sync,
		},
		{
			spec = "hexm.client.util.listenable:Listenable:_notify_declared_additional_listens",
			post_exec = _intercept_listenable,
		},
	})

	if not _interceptor or not _interceptor:is_active() then
		_log("ERROR: Failed to hook sync methods")
		return false, "Hook failed"
	end

	_enabled = true
	_log("Enabled - observing server RPCs + inbound sync (do_sync)")
	return true
end

function SyncObserver.disable()
	if not _enabled then
		return false, "Not enabled"
	end

	_log("=== SESSION SUMMARY ===")

	_log("--- OUTBOUND SYNC EVENTS (Server to Client) ---")
	local sorted_rpc = {}
	for name, count in pairs(_event_counts.inbound_rpc) do
		table.insert(sorted_rpc, { name = name, count = count })
	end
	table.sort(sorted_rpc, function(a, b)
		return a.count > b.count
	end)
	for _, entry in ipairs(sorted_rpc) do
		_log("  RPC  " .. entry.name .. ": " .. entry.count .. " calls")
	end

	_log("--- INBOUND SYNC EVENTS (Client to Server) ---")
	local sorted_sync = {}
	for name, count in pairs(_event_counts.inbound_sync) do
		table.insert(sorted_sync, { name = name, count = count })
	end
	table.sort(sorted_sync, function(a, b)
		return a.count > b.count
	end)
	for _, entry in ipairs(sorted_sync) do
		_log("  IN   " .. entry.name .. ": " .. entry.count .. " calls")
	end

	_log("=== END SUMMARY ===")

	if _interceptor then
		_interceptor:unhook_all()
		_interceptor = nil
	end

	_enabled = false
	_log("Disabled")
	return true
end

return SyncObserver
