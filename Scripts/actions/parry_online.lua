-- ============================================================
-- PARRY_ONLINE.LUA - Online Parry System with NPC Learning
-- ============================================================
-- Migrated from parry_v2.lua to ActionBase pattern.
-- Provides: NPC attack timing learning, prediction, auto-parry.

local ActionBase = _G.Reg.lib("ActionBase")
local ParryOnline = ActionBase:extend("actions.parry_online")

-- ============================================================
-- MODULE SPECS
-- ============================================================

local MODULE_LISTENABLE = "hexm.client.util.listenable"
local MODULE_SKILL_DRIVER = "hexm.common.combat.skill_driver"
local MODULE_BONE_COLLISION = "hexm.common.actionline.nodes.logic_nodes"
local MODULE_ANIM = "hexm.client.entities.local.component.anim"

-- ============================================================
-- STATE
-- ============================================================

function ParryOnline:define_state()
	return {
		persistent = {
			log_enabled = true,
			auto_parry_on_bone_hit = true,
			save_npc_learned = true,
		},
		transient = {
			predictions = {},
			npc_learned = {},
			abc_cache = nil,
			DateTimeManager = nil,
			al_static = nil,
			events_module = nil,
			cmsgpack = nil,
			seen_events = {},
			event_counts = { inbound_rpc = {}, inbound_sync = {} },
			INDEX2RPC = nil,
			SyncEvent = nil,
			inbound_methods_ignore = {
				["chat_receive_pack_message_list"] = true,
				["equip_auto_repair_cb"] = true,
			},
		},
	}
end

-- ============================================================
-- USEFUL NPC EVENTS
-- ============================================================

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
-- HOOKS
-- ============================================================

function ParryOnline:define_hooks()
	return {
		listenable = {
			spec = MODULE_LISTENABLE .. ":Listenable:_notify_declared_additional_listens",
			post_exec = function(self_action, args, results, traceback)
				self_action:_intercept_listenable(args)
			end,
		},
		set_ex_data = {
			spec = MODULE_SKILL_DRIVER .. ":SkillDriver:set_ex_data",
			post_exec = function(self_action, args, results, traceback)
				self_action:_intercept_set_ex_data(args)
			end,
		},
		on_bone_hit = {
			spec = MODULE_BONE_COLLISION .. ":BoneCollision:on_bone_hit",
			post_exec = function(self_action, args, results, traceback)
				self_action:_intercept_on_bone_hit(args)
			end,
		},
		on_bone_hit_batch = {
			spec = MODULE_BONE_COLLISION .. ":BatchBoneCollision:on_bone_hit",
			post_exec = function(self_action, args, results, traceback)
				self_action:_intercept_on_bone_hit(args)
			end,
		},
		set_enable_collider_query = {
			spec = MODULE_ANIM .. ":Anim:set_enable_collider_query",
			override_orig_function = true,
			post_exec = function(self_action, args, results, traceback, orig_function)
				self_action:log("Always enable collider query")
				return orig_function(args[1], true)
			end,
		},
		do_attack = {
			spec = MODULE_BONE_COLLISION .. ":Attack:do_attack",
			post_exec = function(self_action, args, results, traceback)
				self_action:_intercept_do_attack(args)
			end,
		},
	}
end

-- ============================================================
-- LAZY LOADERS
-- ============================================================

function ParryOnline:_get_events()
	if not self.state.events_module then
		local ok, m = pcall(portable.safe_import, "hexm.client.consts.events")
		if ok and m then self.state.events_module = m end
	end
	return self.state.events_module
end

function ParryOnline:_get_cmsgpack()
	if not self.state.cmsgpack then
		local ok, m = pcall(portable.safe_import, "cmsgpack")
		if ok and m then self.state.cmsgpack = m end
	end
	return self.state.cmsgpack
end

function ParryOnline:_get_sync_event()
	if self.state.SyncEvent then return self.state.SyncEvent end
	local ok, mod = pcall(portable.safe_import, "hexm.common.consts.sync_consts")
	if ok and mod then
		self.state.SyncEvent = mod.SyncEvent or mod.SE
	end
	return self.state.SyncEvent
end

function ParryOnline:_ensure_predict_deps()
	if not self.state.DateTimeManager then
		pcall(function()
			self.state.DateTimeManager = portable.safe_import("hexm.common.datetime_manager").DateTimeManager
		end)
	end
	if not self.state.abc_cache then
		pcall(function()
			self.state.abc_cache = G.datam.anim_bone_colliders
		end)
	end
	return self.state.DateTimeManager ~= nil
end

-- ============================================================
-- HELPERS
-- ============================================================

function ParryOnline:_get_key_by_value(tbl, val)
	if not tbl then return nil end
	for k, v in pairs(tbl) do
		if v == val then return tostring(k) end
	end
	return nil
end

function ParryOnline:_safe_get(obj, key, default)
	if obj == nil then return default end
	local ok, value = pcall(function() return obj[key] end)
	if ok and value ~= nil then return value end
	local ok_getter, getter = pcall(function() return obj.get end)
	if ok_getter and type(getter) == "function" then
		local ok_get, value_get = pcall(function() return getter(obj, key, default) end)
		if ok_get then return value_get end
	end
	return default
end

function ParryOnline:_is_pairable(v)
	local t = type(v)
	return t == "table" or t == "dict" or t == "list"
end

function ParryOnline:_safe_map_get(obj, key)
	if not self:_is_pairable(obj) then return nil end
	local ok, val = pcall(function() return obj[key] end)
	return ok and val or nil
end

function ParryOnline:_to_plain_table(v)
	if not self:_is_pairable(v) then return v end
	local out = {}
	for k, child in pairs(v) do
		out[k] = self:_to_plain_table(child)
	end
	return out
end

function ParryOnline:_sort_hits_by_ts(hits)
	table.sort(hits, function(a, b)
		if a.ts == b.ts then return tostring(a.collider) < tostring(b.collider) end
		return a.ts < b.ts
	end)
	return hits
end

function ParryOnline:_resolve_event_name(event_id)
	local SE = self:_get_sync_event()
	if not SE then return nil end
	local ok, name = pcall(function() return SE:get_name(event_id) end)
	if ok and name then return name end
	return nil
end

function ParryOnline:_format_event(event_id)
	local name = self:_resolve_event_name(event_id)
	if name then return name .. "(" .. tostring(event_id) .. ")" end
	return "UNKNOWN(" .. tostring(event_id) .. ")"
end

function ParryOnline:_format_event_detail(event_id)
	event_id = tonumber(event_id) or event_id
	local SE = self:_get_sync_event()
	if not SE then return self:_format_event(event_id) end
	local ok, data = pcall(function() return SE:get_value_by_id(event_id) end)
	if ok and data then
		local func, cls = "", ""
		pcall(function() func = data:get("func_name", "?") end)
		pcall(function() cls = data:get("cls_name", "?") end)
		local name = self:_resolve_event_name(event_id) or "?"
		return name .. "(" .. tostring(event_id) .. ") [" .. cls .. ":" .. func .. "]"
	end
	return self:_format_event(event_id)
end

function ParryOnline:_try_unpack(packed)
	local cmsgpack = self:_get_cmsgpack()
	if not cmsgpack then return packed end
	local ok, decoded = pcall(cmsgpack.unpack, packed)
	if ok then return decoded end
	return packed
end

-- ============================================================
-- NPC LEARNED DATA PERSISTENCE
-- ============================================================

local NPC_LEARNED_PATH = nil

function ParryOnline:_path_npc_learned()
	if NPC_LEARNED_PATH then return NPC_LEARNED_PATH end
	local Constants = _G.Reg.lib("Constants")
	NPC_LEARNED_PATH = Constants.SCRIPTS_ROOT .. "\\data\\npc_learned.json"
	return NPC_LEARNED_PATH
end

function ParryOnline:_sanitize_json_number(v, default)
	local n = tonumber(v)
	if not n or n ~= n or n == math.huge or n == -math.huge then return default or 0 end
	return n
end

function ParryOnline:_sanitize_npc_learned_entry(entry)
	if not self:_is_pairable(entry) then return nil end
	local ts_sum = self:_sanitize_json_number(self:_safe_map_get(entry, "ts_sum"), 0)
	local count = self:_sanitize_json_number(self:_safe_map_get(entry, "count"), 0)
	local ts_avg = self:_sanitize_json_number(self:_safe_map_get(entry, "ts_avg"), 0)
	if count > 0 then ts_avg = ts_sum / count end
	return { ts_sum = ts_sum, count = count, ts_avg = ts_avg }
end

function ParryOnline:_npc_learned_for_json(src)
	local out = {}
	if not self:_is_pairable(src) then return out end
	for anim_key, anim_table in pairs(src) do
		if self:_is_pairable(anim_table) then
			local anim_out = {}
			local has_entries = false
			for hit_key, entry in pairs(anim_table) do
				local clean_entry = self:_sanitize_npc_learned_entry(entry)
				if clean_entry then
					anim_out[tostring(hit_key)] = clean_entry
					has_entries = true
				end
			end
			if has_entries then out[tostring(anim_key)] = anim_out end
		end
	end
	return out
end

function ParryOnline:_sorted_string_keys(t)
	local keys = {}
	for k in pairs(t) do keys[#keys + 1] = tostring(k) end
	table.sort(keys)
	return keys
end

function ParryOnline:_json_escape_string(s)
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

function ParryOnline:_json_encode_number(v)
	local n = self:_sanitize_json_number(v, 0)
	return string.format("%.17g", n)
end

function ParryOnline:_encode_npc_learned_json(src)
	local clean = self:_npc_learned_for_json(src)
	local parts = { "{" }
	local anim_keys = self:_sorted_string_keys(clean)
	for i, anim_key in ipairs(anim_keys) do
		if i > 1 then parts[#parts + 1] = "," end
		parts[#parts + 1] = self:_json_escape_string(anim_key)
		parts[#parts + 1] = ":{"
		local anim_table = clean[anim_key]
		local hit_keys = self:_sorted_string_keys(anim_table)
		for j, hit_key in ipairs(hit_keys) do
			if j > 1 then parts[#parts + 1] = "," end
			local entry = anim_table[hit_key]
			parts[#parts + 1] = self:_json_escape_string(hit_key)
			parts[#parts + 1] = ":{"
			parts[#parts + 1] = '"count":'
			parts[#parts + 1] = self:_json_encode_number(entry.count)
			parts[#parts + 1] = ',"ts_avg":'
			parts[#parts + 1] = self:_json_encode_number(entry.ts_avg)
			parts[#parts + 1] = ',"ts_sum":'
			parts[#parts + 1] = self:_json_encode_number(entry.ts_sum)
			parts[#parts + 1] = "}"
		end
		parts[#parts + 1] = "}"
	end
	parts[#parts + 1] = "}"
	return table.concat(parts)
end

function ParryOnline:_load_npc_learned()
	local path = self:_path_npc_learned()
	local ok, data = pcall(function()
		local f = io.open(path, "r")
		if not f then return nil end
		local raw = f:read("*a")
		f:close()
		local cjson = portable.safe_import("cjson")
		return cjson.decode(raw)
	end)
	if ok and data then
		self:log(string.format("PREDICT | loaded npc_learned from %s", path))
		return self:_to_plain_table(data)
	end
	self:log(string.format("PREDICT | failed to load npc_learned.json: %s", tostring(data)))
	return nil
end

function ParryOnline:_save_npc_learned()
	if not self.state.save_npc_learned then return end
	local path = self:_path_npc_learned()
	local ok, err = pcall(function()
		local raw = self:_encode_npc_learned_json(self.state.npc_learned)
		local f = io.open(path, "w")
		if not f then return "io.open failed" end
		f:write(raw)
		f:close()
	end)
	if ok then
		self:log(string.format("PREDICT | saved npc_learned to %s", path))
	else
		self:log(string.format("PREDICT | failed to save npc_learned.json: %s", tostring(err)))
	end
end

function ParryOnline:_load_al_static()
	if self.state.al_static then return self.state.al_static end
	local Constants = _G.Reg.lib("Constants")
	local path = Constants.SCRIPTS_ROOT .. "\\data\\al_static_index.json"
	local ok, data = pcall(function()
		local f = io.open(path, "r")
		if not f then return nil end
		local raw = f:read("*a")
		f:close()
		local cjson = portable.safe_import("cjson")
		return cjson.decode(raw)
	end)
	if ok and data then
		self.state.al_static = data
	else
		self:log("PREDICT | failed to load al_static_index.json")
	end
	return self.state.al_static
end

-- ============================================================
-- HOOK CALLBACKS
-- ============================================================

function ParryOnline:_intercept_listenable(args)
	local entity = args[1]
	local ins_str = tostring(entity)
	local event = args[3]
	local event_data = args[4]
	local event_str = tostring(event)
	local events = self:_get_events()
	local ev_name = events and self:_get_key_by_value(events, event) or "N/A"

	if ins_str:find("PlayerAvatar") and ev_name == "E_DAMAGE_BEHIT_BEGAN" then
		local Serialize = _G.Reg.lib("Serialize")
		local ctx = self:_safe_get(event_data, "context", nil)
		local dmg = self:_safe_get(event_data, "damage", nil)
		local calcpoint_id = self:_safe_get(event_data, "calcpoint_id", nil)
		local fromer_id = self:_safe_get(event_data, "fromer_id", nil)
		local skill_id = self:_safe_get(event_data, "skill_id", nil)
		if not skill_id and ctx then
			skill_id = self:_safe_get(ctx, "skill_id", nil)
		end
		local attacker = G.space:get_entity(fromer_id)
		local anim, curr_segment
		pcall(function()
			anim = attacker.skill_driver:get_ex_data("cur_anim")
			curr_segment = attacker.skill_driver.cur_skill_segment
		end)
		self:log(string.format(
			"PLAYER DAMAGE skill=%s anim=%s seg=%s cp=%s dmg=%s from=%s data=%s",
			tostring(skill_id), tostring(anim), tostring(curr_segment),
			tostring(calcpoint_id), tostring(dmg), tostring(fromer_id),
			Serialize.dump_value(event_data)
		))
	end

	if not ins_str:find("Npc") then return end

	if USEFUL_NPC_EVENTS[tostring(ev_name)] then
		self:log("NPC EVENT " .. ev_name .. " code=" .. event_str)
	end
end

function ParryOnline:_intercept_set_ex_data(args)
	local skill_driver = args[1]
	local key = args[2]
	local value = args[3]
	if key == "cur_anim_start_ts" then
		self:log(string.format(
			"EX_DATA_SET | key=%s value=%s | curr_skill_segment=%s cur_skill=%s identifier=%s",
			tostring(key), tostring(value),
			tostring(skill_driver.cur_skill_segment),
			tostring(skill_driver.cur_skill.skill_id),
			tostring(skill_driver.identifier)
		))
		pcall(function()
			local entity = skill_driver.entity
			if entity and entity.tag and entity.tag:is_npc() then
				self:_try_predict_behit(skill_driver)
			end
		end)
	end
end

function ParryOnline:_intercept_on_bone_hit(args)
	local bone_node = args[1]
	local graph = args[2]
	local d = args[3]
	local context = graph.context
	local entity = context.entity
	local Serialize = _G.Reg.lib("Serialize")

	for _, result in pairs(d.results) do
		self:log(string.format(
			"ON_BONE_HIT | actor=%s colliderData=%s rsHitPos=%s rsHitNormal=%s rsHitDir=%s rsHitBone=%s",
			Serialize.dump_value(result.actor.eid),
			Serialize.dump_value(bone_node.colliders_data:get(result.colliderName)),
			Serialize.dump_value(result.hitPos),
			Serialize.dump_value(result.hitNormal),
			Serialize.dump_value(result.hitDir),
			Serialize.dump_value(result.boneName)
		))
	end

	-- Learn + verify
	pcall(function()
		if not self.state.DateTimeManager then return end
		local now = self.state.DateTimeManager:now()
		local eid = entity.id
		local anim, anim_start_ts
		pcall(function()
			anim = entity.skill_driver:get_ex_data("cur_anim")
			anim_start_ts = entity.skill_driver:get_ex_data("cur_anim_start_ts")
		end)
		if not anim or not anim_start_ts then return end
		local actual_dt = now - anim_start_ts
		local anim_key = tostring(anim)

		for _, result in pairs(d.results) do
			local cname = result.colliderName
			if cname and anim then
				local ckey = tostring(cname)
				local anim_table = self:_safe_map_get(self.state.npc_learned, anim_key)
				if not anim_table then
					anim_table = {}
					self.state.npc_learned[anim_key] = anim_table
				end
				local entry = self:_safe_map_get(anim_table, ckey)
				if not entry then
					entry = { ts_sum = 0, count = 0, ts_avg = 0 }
					anim_table[ckey] = entry
				end
				entry.ts_sum = (tonumber(entry.ts_sum) or 0) + actual_dt
				entry.count = (tonumber(entry.count) or 0) + 1
				entry.ts_avg = entry.ts_sum / entry.count
				self:log(string.format(
					"LEARN [BoneCollision] | anim=%s collider=%s | observed_dt=%.4f avg=%.4f (n=%d)",
					anim, cname, actual_dt, entry.ts_avg, entry.count
				))
			end
		end

		local pred = self.state.predictions[eid]
		if pred and pred.anim == anim then
			for _, result in pairs(d.results) do
				local cname = result.colliderName
				for _, p in ipairs(pred.hits) do
					if p.collider == cname then
						local err_ms = (actual_dt - p.ts) * 1000
						self:log(string.format(
							"PREDICT_VERIFY [%s] | anim=%s collider=%s | predicted=%.4f actual=%.4f | error=%.1fms %s",
							p.source or pred.source, pred.anim, cname, p.ts, actual_dt, err_ms,
							math.abs(err_ms) < 50 and "OK" or (math.abs(err_ms) < 100 and "~" or "MISS")
						))
						break
					end
				end
			end
		end
	end)
end

function ParryOnline:_intercept_do_attack(args)
	local attack_node = args[1]
	local entity = args[4]

	local node_id, calcpoint_id
	local ok_extract = pcall(function()
		node_id = attack_node.node_id
		calcpoint_id = attack_node.calcpoint_id
	end)
	if not ok_extract or not node_id or not calcpoint_id then return end

	local attack_key = string.format("Attack_n%s_cp%s", tostring(node_id), tostring(calcpoint_id))

	pcall(function()
		if not self.state.DateTimeManager then return end
		local now = self.state.DateTimeManager:now()
		local eid = entity.id
		local anim, anim_start_ts
		pcall(function()
			anim = entity.skill_driver:get_ex_data("cur_anim")
			anim_start_ts = entity.skill_driver:get_ex_data("cur_anim_start_ts")
		end)
		if not anim or not anim_start_ts then return end
		local actual_dt = now - anim_start_ts
		local anim_key = tostring(anim)

		-- Learn timing
		local anim_table = self:_safe_map_get(self.state.npc_learned, anim_key)
		if not anim_table then
			anim_table = {}
			self.state.npc_learned[anim_key] = anim_table
		end
		local entry = self:_safe_map_get(anim_table, attack_key)
		if not entry then
			entry = { ts_sum = 0, count = 0, ts_avg = 0 }
			anim_table[attack_key] = entry
		end
		entry.ts_sum = (tonumber(entry.ts_sum) or 0) + actual_dt
		entry.count = (tonumber(entry.count) or 0) + 1
		entry.ts_avg = entry.ts_sum / entry.count
		self:log(string.format(
			"LEARN [Attack] | anim=%s attack=%s | observed_dt=%.4f avg=%.4f (n=%d)",
			anim, attack_key, actual_dt, entry.ts_avg, entry.count
		))

		-- Verify prediction
		local pred = self.state.predictions[eid]
		if pred and pred.anim == anim then
			for _, p in ipairs(pred.hits) do
				if p.collider == attack_key then
					local err_ms = (actual_dt - p.ts) * 1000
					self:log(string.format(
						"PREDICT_VERIFY [%s] | anim=%s attack=%s | predicted=%.4f actual=%.4f | error=%.1fms %s",
						p.source or pred.source, pred.anim, attack_key, p.ts, actual_dt, err_ms,
						math.abs(err_ms) < 50 and "OK" or (math.abs(err_ms) < 100 and "~" or "MISS")
					))
					break
				end
			end
		end
	end)
end

-- ============================================================
-- PREDICTION ENGINE
-- ============================================================

function ParryOnline:_try_predict_behit(skill_driver)
	if not self:_ensure_predict_deps() then return end

	local entity = skill_driver.entity
	if not entity then return end

	local anim = skill_driver:get_ex_data("cur_anim")
	if not anim or #anim == 0 then return end

	local anim_start_ts = skill_driver:get_ex_data("cur_anim_start_ts")
	if not anim_start_ts then return end

	local skill_id = "?"
	pcall(function() skill_id = skill_driver.cur_skill.skill_id end)

	local now = self.state.DateTimeManager:now()
	local hits = {}
	local source = "?"

	-- Source: runtime-learned NPC timing
	local anim_key = tostring(anim)
	local learned_table = self:_safe_map_get(self.state.npc_learned, anim_key)
	if learned_table then
		for hit_key, data in pairs(learned_table) do
			local ts_sum = tonumber(self:_safe_map_get(data, "ts_sum")) or 0
			local count = tonumber(self:_safe_map_get(data, "count")) or 0
			if count > 0 then
				local ts_avg = ts_sum / count
				hits[#hits + 1] = {
					collider = tostring(hit_key),
					ts = ts_avg,
					predicted_time = anim_start_ts + ts_avg,
					source = tostring(hit_key):find("^Attack_") and "learned_attack" or "learned_bone",
				}
			end
		end
		if #hits > 0 then
			source = "learned"
			self:_sort_hits_by_ts(hits)
		end
	end

	if #hits == 0 then
		self:log(string.format("PREDICT | skill=%s anim=%s | NO DATA", tostring(skill_id), anim))
		return
	end

	local Cocos = _G.Reg.lib("Cocos")
	for _, h in ipairs(hits) do
		self:log(string.format(
			"PREDICT [%s] | skill=%s anim=%s collider=%s | ts=%.4f | hit_in=%.3fs",
			h.source or source, tostring(skill_id), anim, tostring(h.collider),
			h.ts, h.predicted_time - now
		))
		local delay = h.predicted_time - now - 0.175
		if delay > 0 then
			Cocos.delay_call(delay, function()
				self:log(string.format(
					"PREDICT CALLBACK [%s] | skill=%s anim=%s collider=%s | trigger parry",
					h.source or source, tostring(skill_id), anim, tostring(h.collider)
				))
				G.main_player:try_use_parry()
			end)
		end
	end

	local eid
	pcall(function() eid = entity.id end)
	if eid then
		self.state.predictions[eid] = {
			skill_id = skill_id,
			anim = anim,
			anim_start_ts = anim_start_ts,
			hits = hits,
			source = source,
		}
	end
end

-- ============================================================
-- LIFECYCLE
-- ============================================================

function ParryOnline:enable()
	self.state.seen_events = {}
	self.state.event_counts = { inbound_rpc = {}, inbound_sync = {} }
	self.state.predictions = {}
	self.state.abc_cache = nil
	self.state.DateTimeManager = nil
	self.state.npc_learned = {}
	self.state.al_static = nil

	-- Load seed data
	local loaded = self:_load_npc_learned()
	if loaded then
		self.state.npc_learned = loaded
	end

	self:hook("listenable")
	self:hook("set_ex_data")
	self:hook("on_bone_hit")
	self:hook("on_bone_hit_batch")
	self:hook("set_enable_collider_query")
	self:hook("do_attack")

	self.state.is_enabled = true
	self:log("Enabled - observing NPC attacks + prediction system")
	return true
end

function ParryOnline:disable()
	self:_print_summary()
	self:_save_npc_learned()

	self:unhook_all()

	self.state.is_enabled = false
	self:log("Disabled")
	return true
end

function ParryOnline:is_enabled()
	return self.state.is_enabled == true
end

function ParryOnline:_print_summary()
	local Serialize = _G.Reg.lib("Serialize")
	self:log("=== SESSION SUMMARY ===")

	local sorted_rpc = {}
	for name, count in pairs(self.state.event_counts.inbound_rpc) do
		table.insert(sorted_rpc, { name = name, count = count })
	end
	table.sort(sorted_rpc, function(a, b) return a.count > b.count end)
	for _, entry in ipairs(sorted_rpc) do
		self:log("  RPC  " .. entry.name .. ": " .. entry.count .. " calls")
	end

	local sorted_sync = {}
	for name, count in pairs(self.state.event_counts.inbound_sync) do
		table.insert(sorted_sync, { name = name, count = count })
	end
	table.sort(sorted_sync, function(a, b) return a.count > b.count end)
	for _, entry in ipairs(sorted_sync) do
		self:log("  IN   " .. entry.name .. ": " .. entry.count .. " calls")
	end

	self:log("Skills learned: " .. Serialize.dump_value(self.state.npc_learned))
	self:log("=== END SUMMARY ===")
end

return ParryOnline:new()
