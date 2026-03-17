local SyncObserver = {}
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Utils = Reg.get("Utils")
local HookInterceptor = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\lib\\hook_interceptor.lua", "HookInterceptor")
local cmsgpack = Utils.safe_import("cmsgpack")
local events = Utils.safe_import("hexm.client.consts.events")
local Parry = Utils.safe_dofile(Constants.SCRIPTS_ROOT .. "\\actions\\parry_v2.lua", "Parry")

-- ============================================================
-- CONFIGURATION
-- ============================================================

SyncObserver.CONFIG = {
	LOG_ENABLED = true,
	-- Bone collision callback is contact-time; auto-parry here is usually too late online.
	AUTO_PARRY_ON_BONE_HIT = true,
	-- Persist NPC learned timings to data/npc_learned.json (load on enable, save on disable).
	SAVE_NPC_LEARNED = true
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
local _event_counts = {inbound_rpc = {}, inbound_sync = {}}
local _INBOUND_METHODS_IGNORE = {
	["chat_receive_pack_message_list"] = true,
	["equip_auto_repair_cb"] = true
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
	E_SKILL_END = true
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
	local ok, name =
		pcall(
		function()
			return SE:get_name(event_id)
		end
	)
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
	local ok, data =
		pcall(
		function()
			return SE:get_value_by_id(event_id)
		end
	)
	if ok and data then
		local func = ""
		local cls = ""
		pcall(
			function()
				func = data:get("func_name", "?")
			end
		)
		pcall(
			function()
				cls = data:get("cls_name", "?")
			end
		)
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

local function _get_entity_info(entity)
	if not entity then
		return "nil"
	end
	local parts = {}
	local ok, id =
		pcall(
		function()
			return entity.id
		end
	)
	if ok then
		table.insert(parts, "id=" .. tostring(id))
	end
	local ok2, no =
		pcall(
		function()
			return entity.no
		end
	)
	if ok2 and no then
		table.insert(parts, "no=" .. tostring(no))
	end
	if #parts == 0 then
		return tostring(entity)
	end
	return table.concat(parts, ",")
end

local function _get_owner_info(sync_handler)
	if not sync_handler then
		return "?"
	end
	local ok, owner =
		pcall(
		function()
			return sync_handler._owner
		end
	)
	if ok and owner then
		return _get_entity_info(owner)
	end
	return "?"
end

local function _load_al_static()
	if _al_static then
		return _al_static
	end
	local path = Constants.SCRIPTS_ROOT .. "\\data\\al_static_index.json"
	local ok, data =
		pcall(
		function()
			local f = io.open(path, "r")
			if not f then
				return nil
			end
			local raw = f:read("*a")
			f:close()
			local cjson = require("cjson")
			return cjson.decode(raw)
		end
	)
	if ok and data then
		_al_static = data
	else
		_log("PREDICT | failed to load al_static_index.json")
	end
	return _al_static
end

local NPC_LEARNED_PATH = nil -- set once from Constants

local function _is_pairable(v)
	local t = type(v)
	return t == "table" or t == "dict" or t == "list"
end

local function _safe_map_get(obj, key)
	if not _is_pairable(obj) then
		return nil
	end
	local ok, val =
		pcall(
		function()
			return obj[key]
		end
	)
	return ok and val or nil
end

local function _to_plain_table(v)
	if not _is_pairable(v) then
		return v
	end
	local out = {}
	for k, child in pairs(v) do
		out[k] = _to_plain_table(child)
	end
	return out
end

local function _path_npc_learned()
	if NPC_LEARNED_PATH then
		return NPC_LEARNED_PATH
	end
	NPC_LEARNED_PATH = Constants.SCRIPTS_ROOT .. "\\data\\npc_learned.json"
	return NPC_LEARNED_PATH
end

local function _load_npc_learned()
	local path = _path_npc_learned()
	local ok, data =
		pcall(
		function()
			local f = io.open(path, "r")
			if not f then
				_log("PREDICT | npc_learned.json not found at %s", path)
				return nil
			end
			local raw = f:read("*a")
			f:close()
			local cjson = require("cjson")
			return cjson.decode(raw)
		end
	)
	if ok then
		_log("PREDICT | loaded npc_learned from %s", path)
		return _to_plain_table(data)
	end
	if not ok then
		_log("PREDICT | failed to load npc_learned.json: %s", tostring(data))
	end
	return nil
end

-- Build a JSON-serialisable copy (cjson only supports string keys and number/string/table values).
local function _table_for_json(t)
	if t == nil then
		return nil
	end
	if not _is_pairable(t) then
		return t
	end
	local out = {}
	for k, v in pairs(t) do
		local key = type(k) == "string" and k or tostring(k)
		if _is_pairable(v) then
			out[key] = _table_for_json(v)
		elseif type(v) == "number" or type(v) == "string" or type(v) == "boolean" then
			out[key] = v
		end
	end
	return out
end

local function _sanitize_json_number(v, default)
	local n = tonumber(v)
	if not n or n ~= n or n == math.huge or n == -math.huge then
		return default or 0
	end
	return n
end

local function _sanitize_npc_learned_entry(entry)
	if not _is_pairable(entry) then
		return nil
	end

	local ts_sum = _sanitize_json_number(_safe_map_get(entry, "ts_sum"), 0)
	local count = _sanitize_json_number(_safe_map_get(entry, "count"), 0)
	local ts_avg = _sanitize_json_number(_safe_map_get(entry, "ts_avg"), 0)

	if count > 0 then
		ts_avg = ts_sum / count
	end

	return {
		ts_sum = ts_sum,
		count = count,
		ts_avg = ts_avg
	}
end

local function _npc_learned_for_json(src)
	local out = {}
	if not _is_pairable(src) then
		return out
	end

	for anim_key, anim_table in pairs(src) do
		if _is_pairable(anim_table) then
			local anim_out = {}
			local has_entries = false

			for hit_key, entry in pairs(anim_table) do
				local clean_entry = _sanitize_npc_learned_entry(entry)
				if clean_entry then
					anim_out[tostring(hit_key)] = clean_entry
					has_entries = true
				end
			end

			if has_entries then
				out[tostring(anim_key)] = anim_out
			end
		end
	end

	return out
end

local function _sorted_string_keys(t)
	local keys = {}
	for k in pairs(t) do
		keys[#keys + 1] = tostring(k)
	end
	table.sort(keys)
	return keys
end

local function _json_escape_string(s)
	s = tostring(s)
	s = s:gsub("\\", "\\\\")
	s = s:gsub('"', '\\"')
	s = s:gsub("\b", "\\b")
	s = s:gsub("\f", "\\f")
	s = s:gsub("\n", "\\n")
	s = s:gsub("\r", "\\r")
	s = s:gsub("\t", "\\t")
	return '"' .. s .. '"'
end

local function _json_encode_number(v)
	local n = _sanitize_json_number(v, 0)
	return string.format("%.17g", n)
end

local function _sort_hits_by_ts(hits)
	table.sort(
		hits,
		function(a, b)
			if a.ts == b.ts then
				return tostring(a.collider) < tostring(b.collider)
			end
			return a.ts < b.ts
		end
	)
	return hits
end

local function _encode_npc_learned_json(src)
	local clean = _npc_learned_for_json(src)
	local parts = {"{"}
	local anim_keys = _sorted_string_keys(clean)

	for i, anim_key in ipairs(anim_keys) do
		if i > 1 then
			parts[#parts + 1] = ","
		end
		parts[#parts + 1] = _json_escape_string(anim_key)
		parts[#parts + 1] = ":{"

		local anim_table = clean[anim_key]
		local hit_keys = _sorted_string_keys(anim_table)
		for j, hit_key in ipairs(hit_keys) do
			if j > 1 then
				parts[#parts + 1] = ","
			end
			local entry = anim_table[hit_key]
			parts[#parts + 1] = _json_escape_string(hit_key)
			parts[#parts + 1] = ":{"
			parts[#parts + 1] = '"count":'
			parts[#parts + 1] = _json_encode_number(entry.count)
			parts[#parts + 1] = ',"ts_avg":'
			parts[#parts + 1] = _json_encode_number(entry.ts_avg)
			parts[#parts + 1] = ',"ts_sum":'
			parts[#parts + 1] = _json_encode_number(entry.ts_sum)
			parts[#parts + 1] = "}"
		end

		parts[#parts + 1] = "}"
	end

	parts[#parts + 1] = "}"
	return table.concat(parts)
end

local function _save_npc_learned()
	if not SyncObserver.CONFIG.SAVE_NPC_LEARNED then
		return
	end
	local path = _path_npc_learned()
	local ok, err =
		pcall(
		function()
			local raw = _encode_npc_learned_json(_npc_learned)
			local f = io.open(path, "w")
			if not f then
				return "io.open failed"
			end
			f:write(raw)
			f:close()
		end
	)
	if ok then
		_log("PREDICT | saved npc_learned to %s", path)
	else
		_log("PREDICT | failed to save npc_learned.json: %s", tostring(err))
	end
end

local function _get_static_attack_times(skill_id)
	local idx = _load_al_static()
	if not idx then
		return nil
	end
	local entry = idx["skills"][tostring(skill_id)]
	if not entry or not entry["events"] then
		_log("PREDICT | no static data for skill_id=%s", tostring(skill_id))
		return nil
	end
	local hits = {}
	for i, ev in pairs(entry["events"]) do
		if ev["node_type"] == "Attack" then
			-- Use node_id + calcpoint_id as key (matches runtime key)
			local name = string.format("Attack_n%s_cp%s", tostring(ev["node_id"]), tostring(ev["calcpoint_id"]))
			local calc_d = G.datam.calcpoint:get(ev["calcpoint_id"])
			hits[#hits + 1] = {collider = name, ts = ev["time"], calc_d = calc_d}
		end
	end
	if #hits == 0 then
		return nil
	end
	return hits
end

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
	pcall(
		function()
			methodname = _INDEX2RPC:get(index, md5)
		end
	)
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

	local entity_info = "?"
	pcall(
		function()
			entity_info = _get_entity_info(entity)
		end
	)

	-- Try to resolve sync event name from first arg if it's a number
	local event_label = ""
	pcall(
		function()
			if args and args[1] then
				local event_id = args[1]
				if type(event_id) == "number" then
					event_label = _format_event(event_id)
				else
					event_label = tostring(event_id)
				end
			end
		end
	)

	-- Decode msgpack-packed args (args[2]=packed_args, args[3]=packed_kwargs)

	-- check length
	local e_args = tostring(args)
	local e_kwargs = ""
	if methodname == "client_sync" then
		local ok2, v2 =
			pcall(
			function()
				return args[2]
			end
		)
		if ok2 and v2 then
			e_args = tostring(_try_unpack(v2))
		end
		local ok3, v3 =
			pcall(
			function()
				return args[3]
			end
		)
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
				rpc_tag ..
					"| batch_client_sync[" ..
						i ..
							"] | " ..
								_format_event(event_id) ..
									" | eid=[" .. entity_info .. "] | args=" .. tostring(packed_args) .. " | kwargs=" .. tostring(packed_kwargs)
			)
		end
		return
	end

	_log(
		rpc_tag ..
			"| " ..
				methodname ..
					" | " .. event_label .. " | eid=[" .. entity_info .. "] | args=" .. (e_args) .. " | kwargs=" .. e_kwargs
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
	local owner_info = _get_owner_info(handler)

	_event_counts.inbound_sync[event_label] = (_event_counts.inbound_sync[event_label] or 0) + 1

	local key = "IN|" .. event_label
	local is_new = not _seen_events[key]
	if is_new then
		_seen_events[key] = true
	end
	local sync_tag = is_new and "IN*" or "IN "

	_log(
		sync_tag ..
			"| " ..
				event_label ..
					" | owner=[" .. owner_info .. "] | args=" .. Utils.dump_value(args) .. " | kwargs=" .. Utils.dump_value(kwargs)
	)
end

local function _get_key_by_value(tbl, val)
	if not tbl then
		return nil
	end
	for k, v in pairs(tbl) do
		if v == val then
			return tostring(k)
		end
	end
	return nil
end

local function _safe_get(obj, key, default)
	if obj == nil then
		return default
	end
	local ok, value =
		pcall(
		function()
			return obj[key]
		end
	)
	if ok and value ~= nil then
		return value
	end
	local ok_getter, getter =
		pcall(
		function()
			return obj.get
		end
	)
	if ok_getter and type(getter) == "function" then
		local ok_get, value_get =
			pcall(
			function()
				return getter(obj, key, default)
			end
		)
		if ok_get then
			return value_get
		end
	end
	return default
end

local function _intercept_listenable(spec, args, results, traceback)
	local entity = args[1]
	local ins_str = tostring(entity)
	local channel = args[2]
	local event = args[3]
	local event_data = args[4]
	local event_str = tostring(event)
	local ev_name = _get_key_by_value(events, event) or "N/A"

	if ins_str:find("PlayerAvatar") and ev_name == "E_DAMAGE_BEHIT_BEGAN" then
		local ctx = _safe_get(event_data, "context", nil)
		local dmg = _safe_get(event_data, "damage", nil)
		local dmg_num = tonumber(dmg) or 0
		local calcpoint_id = _safe_get(event_data, "calcpoint_id", nil)
		local parry_tag = _safe_get(event_data, "parry_tag", nil)
		local defence_flag = _safe_get(event_data, "defence_flag", nil)
		local flag = _safe_get(event_data, "flag", nil)
		local fromer_id = _safe_get(event_data, "fromer_id", nil)
		local skill_id = _safe_get(event_data, "skill_id", nil)
		if not skill_id and ctx then
			skill_id = _safe_get(ctx, "skill_id", nil)
		end
		_log("================================================")
		local attacker = G.space:get_entity(fromer_id)
		local anim = attacker.skill_driver:get_ex_data("cur_anim")
		local anim_start_ts = attacker.skill_driver:get_ex_data("cur_anim_start_ts")
		local curr_segment = attacker.skill_driver.cur_skill_segment

		_log(
			"CLIENT_EVENT | >>>>>>>>> Player DAMAGE skill_ex=%s ex_anim=%s curr_segment=%s cp=%s dmg=%s from=%s data=%s",
			tostring(skill_id),
			tostring(anim),
			tostring(curr_segment),
			tostring(calcpoint_id),
			tostring(dmg),
			tostring(fromer_id),
			Utils.dump_value(event_data)
		)
		_log("================================================")
	end

	-- -- === NPC only ===
	if not ins_str:find("Npc") then
		return
	end
	-- if ev_name == "E_SKILL_START" then
	-- 	local skill = entity.skill_driver.cur_skill
	-- 	local difficulty = G.main_player.skill_ctrl:get_difficulty()
	-- 	local skill_id = entity.skill_driver.cur_skill.skill_id
	-- 	local skill_d = G.datam.skills:get(tonumber(skill_id))
	-- 	local huajie = _safe_get(skill_d, "huajie", nil)
	-- 	local is_parriable = huajie ~= nil
	-- 	_log("CLIENT_EVENT | >>>>>>>>> NPC Skill Start: %s is_parriable=%s skill_d=%s difficulty=%s", tostring(skill_id), tostring(is_parriable), Utils.dump_value(skill), tostring(difficulty))

	-- 	local static_hits = _get_static_attack_times(skill_id)
	-- 	if static_hits then
	-- 		for _, h in ipairs(static_hits) do

	-- 			local parry_period = _safe_get(h.calc_d, "huajie_period", nil)
	-- 			if parry_period then
	-- 				parry_period = tonumber(parry_period[difficulty - 1]) / 2 - 0.05
	-- 			else
	-- 				parry_period = 0.125
	-- 			end
	-- 			_log(" \tStatic Attack Event | skill=%s collider=%s ts=%.4f parry_period=%.4f", tostring(skill_id), tostring(h.collider), h.ts, parry_period)

	-- 			Utils.delay_call(
	-- 				h.ts - parry_period,
	-- 				function()
	-- 					_log(
	-- 						" \tStatic Attack Event Callback | skill=%s collider=%s | trigger parry",
	-- 						tostring(skill_id),
	-- 						tostring(h.collider)
	-- 					)
	-- 					if is_parriable then
	-- 						G.main_player:try_use_parry()
	-- 					else
	-- 						Parry.trigger_dash()
	-- 					end
	-- 				end
	-- 			)
	-- 		end
	-- 	else
	-- 		_log(" \tNo static attack data for skill_id=%s", tostring(skill_id))
	-- 	end
	-- end

	local should_log_npc_event = USEFUL_NPC_EVENTS[tostring(ev_name)] == true
	-- end
	if should_log_npc_event then
		_log("CLIENT_EVENT | >>>>>>>>> NPC Event: " .. ev_name .. " - Code: " .. event_str)
	end
end

local function _ensure_predict_deps()
	if not _DateTimeManager then
		pcall(
			function()
				_DateTimeManager = require("hexm.common.datetime_manager").DateTimeManager
			end
		)
	end
	if not _abc_cache then
		pcall(
			function()
				_abc_cache = G.datam.anim_bone_colliders
			end
		)
	end
	return _DateTimeManager ~= nil
end

local function _try_predict_behit(skill_driver)
	if not _ensure_predict_deps() then
		return
	end

	local entity = skill_driver.entity
	if not entity then
		return
	end

	local anim = skill_driver:get_ex_data("cur_anim")
	if not anim or #anim == 0 then
		return
	end

	local anim_start_ts = skill_driver:get_ex_data("cur_anim_start_ts")
	if not anim_start_ts then
		return
	end

	local skill_id = "?"
	pcall(
		function()
			skill_id = skill_driver.cur_skill.skill_id
		end
	)

	local now = _DateTimeManager:now()
	local hits = {}
	local source = "?"

	-- Source 1: runtime-learned NPC timing (from prior on_bone_hit/Attack observations)
	-- Always prefer learned data over static data
	local anim_key = tostring(anim)
	local learned_table = _safe_map_get(_npc_learned, anim_key)
	if learned_table then
		for hit_key, data in pairs(learned_table) do
			local ts_sum = tonumber(_safe_map_get(data, "ts_sum")) or 0
			local count = tonumber(_safe_map_get(data, "count")) or 0
			if count > 0 then
				local collider = tostring(hit_key)
				local ts_avg = ts_sum / count
				hits[#hits + 1] = {
					collider = collider,
					ts = ts_avg,
					predicted_time = anim_start_ts + ts_avg,
					source = collider:find("^Attack_") and "learned_attack" or "learned_bone"
				}
			end
		end
		if #hits > 0 then
			source = "learned"
			_sort_hits_by_ts(hits)
		end
	end

	-- Source 2: al_static_index.json Attack event times (first-encounter fallback)
	-- if #hits == 0 then
	-- 	local static_hits = _get_static_attack_times(skill_id)
	-- 	if static_hits then
	-- 		source = "al_static"
	-- 		for _, h in ipairs(static_hits) do
	-- 			h.predicted_time = anim_start_ts + h.ts
	-- 			hits[#hits + 1] = h
	-- 		end
	-- 		_sort_hits_by_ts(hits)
	-- 	end
	-- end

	if #hits == 0 then
		_log("PREDICT | skill=%s anim=%s | NO DATA from any source", tostring(skill_id), anim)
		return
	end

	for _, h in ipairs(hits) do
		_log(
			"PREDICT [%s] | skill=%s anim=%s collider=%s | ts=%.4f | hit_in=%.3fs",
			h.source or source,
			tostring(skill_id),
			anim,
			tostring(h.collider),
			h.ts,
			h.predicted_time - now
		)
		Utils.delay_call(
			h.predicted_time - now - 0.175,
			function()
				_log(
					"PREDICT CALLBACK [%s] | skill=%s anim=%s collider=%s | trigger parry",
					h.source or source,
					tostring(skill_id),
					anim,
					tostring(h.collider)
				)
				G.main_player:try_use_parry()
			end
		)
	end

	local eid = nil
	pcall(
		function()
			eid = entity.id
		end
	)
	if eid then
		_predictions[eid] = {
			skill_id = skill_id,
			anim = anim,
			anim_start_ts = anim_start_ts,
			hits = hits,
			source = source
		}
	end
end

local function _intercept_set_ex_data(spec, args, results, traceback)
	local self = args[1]
	local key = args[2]
	local value = args[3]
	if key == "cur_anim_start_ts" then
		_log(
			"EX_DATA_SET | key=%s value=%s | curr_skill_segment=%s cur_skill=%s identifier=%s ex_data=%s",
			tostring(key),
			tostring(value),
			tostring(self.cur_skill_segment),
			tostring(self.cur_skill.skill_id),
			tostring(self.identifier),
			tostring(self.ex_data)
		)
		pcall(
			function()
				local entity = self.entity
				if entity and entity.tag and entity.tag:is_npc() then
					_try_predict_behit(self)
				end
			end
		)
	end
end

local function _intercept_on_bone_hit(spec, args, results, traceback)
	local self = args[1]
	local graph = args[2]
	local d = args[3]
	local context = graph.context
	local info = context.bone_colliders
	local entity = context.entity
	for _, result in pairs(d.results) do
		local actor = result.actor
		local cld_name = result.colliderName
		local cld = self.colliders_data:get(cld_name)
		_log("================================================")
		_log(
			"ON_BONE_HIT | actor=%s colliderData=%s rsHitPos=%s rsHitNormal=%s rsHitDir=%s rsHitBone=%s",
			Utils.dump_value(actor.eid),
			Utils.dump_value(cld),
			Utils.dump_value(result.hitPos),
			Utils.dump_value(result.hitNormal),
			Utils.dump_value(result.hitDir),
			Utils.dump_value(result.boneName)
		)
		_log("================================================")

		-- Utils.dump_instance(result)
	end
	-- learn + verify
	pcall(
		function()
			if not _DateTimeManager then
				return
			end
			local now = _DateTimeManager:now()
			local eid = entity.id
			local anim = nil
			local anim_start_ts = nil
			pcall(
				function()
					anim = entity.skill_driver:get_ex_data("cur_anim")
					anim_start_ts = entity.skill_driver:get_ex_data("cur_anim_start_ts")
				end
			)
			if not anim or not anim_start_ts then
				return
			end
			local actual_dt = now - anim_start_ts
			local anim_key = tostring(anim)

			for _, result in pairs(d.results) do
				local cname = result.colliderName
				if cname and anim then
					local ckey = tostring(cname)
					local anim_table = _safe_map_get(_npc_learned, anim_key)
					if not anim_table then
						anim_table = {}
						_npc_learned[anim_key] = anim_table
					end
					local entry = _safe_map_get(anim_table, ckey)
					if not entry then
						entry = {ts_sum = 0, count = 0, ts_avg = 0}
						anim_table[ckey] = entry
					end
					entry.ts_sum = (tonumber(entry.ts_sum) or 0) + actual_dt
					entry.count = (tonumber(entry.count) or 0) + 1
					entry.ts_avg = entry.ts_sum / entry.count
					_log(
						"LEARN [BoneCollision] | anim=%s collider=%s | observed_dt=%.4f avg=%.4f (n=%d)",
						anim,
						cname,
						actual_dt,
						entry.ts_avg,
						entry.count
					)
				end
			end

			local pred = _predictions[eid]
			if pred and pred.anim == anim then
				for _, result in pairs(d.results) do
					local cname = result.colliderName
					for _, p in ipairs(pred.hits) do
						if p.collider == cname then
							local err_ms = (actual_dt - p.ts) * 1000
							_log(
								"PREDICT_VERIFY [%s] | anim=%s collider=%s | predicted_ts=%.4f actual_dt=%.4f | error=%.1fms %s",
								p.source or pred.source,
								pred.anim,
								cname,
								p.ts,
								actual_dt,
								err_ms,
								math.abs(err_ms) < 50 and "OK" or (math.abs(err_ms) < 100 and "~" or "MISS")
							)
							break
						end
					end
				end
			end
		end
	)
end

local function _intercept_do_attack(spec, args, results, traceback)
	_log("ATTACK_HOOK | Called with %d args", #args)

	local self = args[1] -- Attack node instance
	local graph = args[2]
	local context = args[3]
	local entity = args[4]
	local attacker = args[5]

	_log("ATTACK_HOOK | self=%s entity=%s attacker=%s", tostring(self), tostring(entity), tostring(attacker))

	-- Extract node_id and calcpoint_id from Attack node
	local node_id = nil
	local calcpoint_id = nil
	local ok_extract, err_extract =
		pcall(
		function()
			node_id = self.node_id
			calcpoint_id = self.calcpoint_id
		end
	)

	if not ok_extract then
		_log("ATTACK_HOOK | ERROR extracting node_id/calcpoint_id: %s", tostring(err_extract))
		return
	end

	_log("ATTACK_HOOK | node_id=%s calcpoint_id=%s", tostring(node_id), tostring(calcpoint_id))

	if not node_id or not calcpoint_id then
		_log("ATTACK_HOOK | SKIP: node_id or calcpoint_id is nil")
		return
	end

	-- Use node_id + calcpoint_id as key (calcpoint_id is unique per attack)
	local attack_key = string.format("Attack_n%s_cp%s", tostring(node_id), tostring(calcpoint_id))
	_log("ATTACK_HOOK | attack_key=%s", attack_key)

	-- Learn + verify (same logic as on_bone_hit)
	local ok, err =
		pcall(
		function()
			if not _DateTimeManager then
				_log("ATTACK_HOOK | SKIP: _DateTimeManager not available")
				return
			end

			local now = _DateTimeManager:now()
			local eid = entity.id
			_log("ATTACK_HOOK | now=%.4f eid=%s", now, tostring(eid))

			local anim = nil
			local anim_start_ts = nil

			-- Get anim info from entity's skill_driver
			local ok_anim, err_anim =
				pcall(
				function()
					anim = entity.skill_driver:get_ex_data("cur_anim")
					anim_start_ts = entity.skill_driver:get_ex_data("cur_anim_start_ts")
				end
			)

			if not ok_anim then
				_log("ATTACK_HOOK | ERROR getting anim data: %s", tostring(err_anim))
				return
			end

			_log("ATTACK_HOOK | anim=%s anim_start_ts=%s", tostring(anim), tostring(anim_start_ts))

			if not anim or not anim_start_ts then
				_log("ATTACK_HOOK | SKIP: anim or anim_start_ts is nil")
				return
			end

			local actual_dt = now - anim_start_ts
			local anim_key = tostring(anim)

			_log("ATTACK_HOOK | actual_dt=%.4f anim_key=%s", actual_dt, anim_key)

			-- Learn timing (handle dict object from cjson.decode with pcall)
			local ok_learn, err_learn =
				pcall(
				function()
					local anim_table = _safe_map_get(_npc_learned, anim_key)
					if not anim_table then
						anim_table = {}
						_npc_learned[anim_key] = anim_table
					end
					local entry = _safe_map_get(anim_table, attack_key)
					if not entry then
						entry = {ts_sum = 0, count = 0, ts_avg = 0}
						anim_table[attack_key] = entry
					end
					entry.ts_sum = (tonumber(entry.ts_sum) or 0) + actual_dt
					entry.count = (tonumber(entry.count) or 0) + 1
					entry.ts_avg = entry.ts_sum / entry.count

					_log(
						"LEARN [Attack] | anim=%s attack=%s | observed_dt=%.4f avg=%.4f (n=%d)",
						anim,
						attack_key,
						actual_dt,
						entry.ts_avg,
						entry.count
					)
				end
			)

			if not ok_learn then
				_log("ATTACK_HOOK | ERROR in learning: %s", tostring(err_learn))
				return
			end

			-- Verify prediction
			local pred = _predictions[eid]
			if pred and pred.anim == anim then
				for _, p in ipairs(pred.hits) do
					if p.collider == attack_key then
						local err_ms = (actual_dt - p.ts) * 1000
						_log(
							"PREDICT_VERIFY [%s] | anim=%s attack=%s | predicted_ts=%.4f actual_dt=%.4f | error=%.1fms %s",
							p.source or pred.source,
							pred.anim,
							attack_key,
							p.ts,
							actual_dt,
							err_ms,
							math.abs(err_ms) < 50 and "OK" or (math.abs(err_ms) < 100 and "~" or "MISS")
						)
						break
					end
				end
			end
		end
	)

	if not ok then
		_log("ATTACK_HOOK | ERROR in learn/verify: %s", tostring(err))
	end
end

local function _try_enable_nofify()
	local entities_map = G.space and G.space._entities_map
	if not entities_map then
		return false
	end
	local npc_list = entities_map["Npc"]:values()
	if not npc_list then
		_log("ERROR: No NPCs found in entities_map")
		return false
	end

	for _, npc in pairs(npc_list) do
		if npc and npc.anim then
			_log("Register call back for NPC anim: " .. tostring(npc))
			npc.anim:bind_physics_collision_notify(
				function(result)
					_log("Physics collision notify for NPC: " .. Utils.dump_value(result, {pretty = true}))
				end
			)
			npc.anim:bind_collision_notify(
				function(result)
					_log("Bone collision notify for NPC: " .. Utils.dump_value(result, {pretty = true}))
				end
			)
		end
	end
	G.main_player.anim:bind_physics_collision_notify(
		function(result)
			_log("Physics collision notify for Player: " .. Utils.dump_value(result))
		end
	)
	G.main_player.anim:bind_collision_notify(
		function(result)
			_log("Bone collision notify for Player: " .. Utils.dump_value(result))
		end
	)
end

local function _intercept_set_enable_collider_query(spec, args, results, traceback, orig_function)
	local self = args[1]
	local enable = args[2]
	_log("Always enable collider query")
	return orig_function(self, true)
end

-- ============================================================
-- PUBLIC API
-- ============================================================

function SyncObserver.enable()
	if _enabled then
		return false, "Already enabled"
	end
	-- _try_enable_nofify()

	_seen_events = {}
	_event_counts = {inbound_rpc = {}, inbound_sync = {}}
	_SyncEvent = nil
	_INDEX2RPC = nil
	_predictions = {}
	_abc_cache = nil
	_DateTimeManager = nil
	_npc_learned = {}
	_al_static = nil

	-- Always try to load seed data so npc_learned.json is used when present; save on disable is gated by SAVE_NPC_LEARNED.
	local loaded = _load_npc_learned()
	if loaded then
		_npc_learned = loaded
	else
		_log("PREDICT | failed to load npc_learned from %s", _path_npc_learned())
	end

	local SYNC_MOD = "hexm.client.entities.local.sync.sync_handler"

	_interceptor =
		HookInterceptor.create(
		{
			-- {
			-- 	spec = "client.ClientEntity:ClientEntity:entity_method",
			-- 	post_exec = _on_entity_method
			-- },
			-- {
			-- 	spec = SYNC_MOD .. ":SyncHandler:do_sync",
			-- 	post_exec = _on_inbound_do_sync
			-- },
			{
				spec = "hexm.client.util.listenable:Listenable:_notify_declared_additional_listens",
				post_exec = _intercept_listenable
			},
			{
				spec = "hexm.common.combat.skill_driver:SkillDriver:set_ex_data",
				post_exec = _intercept_set_ex_data
			},
			{
				spec = "hexm.common.actionline.nodes.logic_nodes:BoneCollision:on_bone_hit",
				post_exec = _intercept_on_bone_hit
			},
			{
				spec = "hexm.common.actionline.nodes.logic_nodes:BatchBoneCollision:on_bone_hit",
				post_exec = _intercept_on_bone_hit
			},
			{
				spec = "hexm.client.entities.local.component.anim:Anim:set_enable_collider_query",
				override_orig_function = true,
				post_exec = _intercept_set_enable_collider_query
			},
			{
				spec = "hexm.common.actionline.nodes.logic_nodes:Attack:do_attack",
				post_exec = _intercept_do_attack
			}
			-- {
			-- 	spec = "hexm.common.actionline.nodes.logic_nodes:Attack:ctor",
			-- }
		},
		{
			enable_traceback = false
		}
	)

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
		table.insert(sorted_rpc, {name = name, count = count})
	end
	table.sort(
		sorted_rpc,
		function(a, b)
			return a.count > b.count
		end
	)
	for _, entry in ipairs(sorted_rpc) do
		_log("  RPC  " .. entry.name .. ": " .. entry.count .. " calls")
	end

	_log("--- INBOUND SYNC EVENTS (Client to Server) ---")
	local sorted_sync = {}
	for name, count in pairs(_event_counts.inbound_sync) do
		table.insert(sorted_sync, {name = name, count = count})
	end
	table.sort(
		sorted_sync,
		function(a, b)
			return a.count > b.count
		end
	)
	for _, entry in ipairs(sorted_sync) do
		_log("  IN   " .. entry.name .. ": " .. entry.count .. " calls")
	end
	_log("Skills learned: " .. Utils.dump_value(_npc_learned))

	_save_npc_learned()

	_log("=== END SUMMARY ===")

	if _interceptor then
		_interceptor:unhook_all()
		_interceptor = nil
	end

	_enabled = false
	_log("Disabled")
	return true
end

function SyncObserver.is_enabled()
	return _enabled
end

function SyncObserver.get_status()
	return {
		is_enabled = _enabled,
		unique_events = _seen_events,
		event_counts = _event_counts
	}
end

return SyncObserver
