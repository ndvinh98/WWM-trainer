local ActionBase = _G.Reg.lib("ActionBase")
local SyncObserver = ActionBase:extend("actions.sync_observer")

local MODULE_CLIENT_ENTITY = "client.ClientEntity"
local MODULE_SYNC_HANDLER = "hexm.client.entities.local.sync.sync_handler"
local MODULE_LISTENABLE = "hexm.client.util.listenable"

function SyncObserver:define_state()
	return {
		persistent = {
			log_enabled = true,
		},
		transient = {
			seen_events = {},
			event_counts = { inbound_rpc = {}, inbound_sync = {} },
			INDEX2RPC = nil,
			SyncEvent = nil,
			cmsgpack = nil,
			events_module = nil,
			inbound_methods_ignore = {
				["chat_receive_pack_message_list"] = true,
				["equip_auto_repair_cb"] = true,
			},
		},
	}
end

function SyncObserver:define_hooks()
	return {
		entity_method = {
			spec = MODULE_CLIENT_ENTITY .. ":ClientEntity:entity_method",
			post_exec = function(self_action, args, results, traceback)
				self_action:_on_entity_method(args)
			end,
		},
		do_sync = {
			spec = MODULE_SYNC_HANDLER .. ":SyncHandler:do_sync",
			post_exec = function(self_action, args, results, traceback)
				self_action:_on_inbound_do_sync(args)
			end,
		},
		listenable = {
			spec = MODULE_LISTENABLE .. ":Listenable:_notify_declared_additional_listens",
			post_exec = function(self_action, args, results, traceback)
				self_action:_intercept_listenable(args)
			end,
		},
	}
end

function SyncObserver:_get_cmsgpack()
	if not self.state.cmsgpack then
		local ok, m = pcall(portable.safe_import, "cmsgpack")
		if ok and m then self.state.cmsgpack = m end
	end
	return self.state.cmsgpack
end

function SyncObserver:_get_events()
	if not self.state.events_module then
		local ok, m = pcall(portable.safe_import, "hexm.client.consts.events")
		if ok and m then self.state.events_module = m end
	end
	return self.state.events_module
end

function SyncObserver:_get_sync_event()
	if self.state.SyncEvent then return self.state.SyncEvent end
	local ok, mod = pcall(portable.safe_import, "hexm.common.consts.sync_consts")
	if ok and mod then
		self.state.SyncEvent = mod.SyncEvent or mod.SE
	end
	return self.state.SyncEvent
end

function SyncObserver:_resolve_event_name(event_id)
	local SE = self:_get_sync_event()
	if not SE then return nil end
	local ok, name = pcall(function() return SE:get_name(event_id) end)
	if ok and name then return name end
	return nil
end

function SyncObserver:_format_event(event_id)
	local name = self:_resolve_event_name(event_id)
	if name then return name .. "(" .. tostring(event_id) .. ")" end
	return "UNKNOWN(" .. tostring(event_id) .. ")"
end

function SyncObserver:_format_event_detail(event_id)
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

function SyncObserver:_try_unpack(packed)
	local cmsgpack = self:_get_cmsgpack()
	if not cmsgpack then return packed end
	local ok, decoded = pcall(cmsgpack.unpack, packed)
	if ok then return decoded end
	return packed
end

function SyncObserver:_get_key_by_value(tbl, value)
	for k, v in pairs(tbl) do
		if v == value then return k end
	end
	return nil
end

function SyncObserver:_on_entity_method(call_args)
	local entity = call_args[1]
	local md5 = call_args[2]
	local index = call_args[3]
	local args = call_args[4]

	if not self.state.INDEX2RPC then
		local ok, mod = pcall(require, "common.RpcIndex")
		if ok and mod then self.state.INDEX2RPC = mod.INDEX2RPC end
		if not self.state.INDEX2RPC then
			self:log("ERROR: RpcIndex module not found")
			return
		end
	end

	local methodname = nil
	pcall(function() methodname = self.state.INDEX2RPC:get(index, md5) end)
	if not methodname then return end
	if self.state.inbound_methods_ignore[methodname] then return end

	self.state.event_counts.inbound_rpc[methodname] = (self.state.event_counts.inbound_rpc[methodname] or 0) + 1

	local key = "RPC|" .. methodname
	local is_new = not self.state.seen_events[key]
	if is_new then self.state.seen_events[key] = true end
	local rpc_tag = is_new and "OUT*" or "OUT "

	local entity_info = tostring(entity)
	local event_label = ""
	pcall(function()
		if args and args[1] then
			local event_id = args[1]
			if type(event_id) == "number" then
				event_label = self:_format_event(event_id)
			else
				event_label = tostring(event_id)
			end
		end
	end)

	local e_args = tostring(args)
	local e_kwargs = ""
	if methodname == "client_sync" then
		local ok2, v2 = pcall(function() return args[2] end)
		if ok2 and v2 then e_args = tostring(self:_try_unpack(v2)) end
		local ok3, v3 = pcall(function() return args[3] end)
		if ok3 and v3 then e_kwargs = tostring(self:_try_unpack(v3)) end
	end
	if methodname == "batch_client_sync" then
		for i, raw in pairs(args) do
			local unpacked = raw:unpack()
			local event_id, packed_args, packed_kwargs = unpacked[1], unpacked[2], unpacked[3]
			packed_args = self:_try_unpack(packed_args)
			packed_kwargs = self:_try_unpack(packed_kwargs)
			self:log(rpc_tag .. "| batch_client_sync[" .. i .. "] | "
				.. self:_format_event(event_id) .. " | eid=[" .. entity_info
				.. "] | args=" .. tostring(packed_args) .. " | kwargs=" .. tostring(packed_kwargs))
		end
		return
	end

	self:log(rpc_tag .. "| " .. methodname .. " | " .. event_label
		.. " | eid=[" .. entity_info .. "] | args=" .. e_args .. " | kwargs=" .. e_kwargs)
end

function SyncObserver:_on_inbound_do_sync(call_args)
	local handler = call_args[1]
	local sync_id = call_args[2]
	local args = call_args[3]
	local kwargs = call_args[4]

	local Serialize = _G.Reg.lib("Serialize")
	local event_label = self:_format_event_detail(sync_id)
	local owner_info = tostring(handler)

	self.state.event_counts.inbound_sync[event_label] = (self.state.event_counts.inbound_sync[event_label] or 0) + 1

	local key = "IN|" .. event_label
	local is_new = not self.state.seen_events[key]
	if is_new then self.state.seen_events[key] = true end
	local sync_tag = is_new and "IN*" or "IN "

	self:log(sync_tag .. "| " .. event_label .. " | owner=[" .. owner_info
		.. "] | args=" .. Serialize.dump_value(args) .. " | kwargs=" .. Serialize.dump_value(kwargs))
end

function SyncObserver:_intercept_listenable(args)
	local entity = args[1]
	local ins_str = tostring(entity)
	local channel = args[2]
	local event = args[3]
	local event_data = args[4]
	local event_str = tostring(event)
	local events = self:_get_events()
	local ev_name = events and self:_get_key_by_value(events, event) or "N/A"

	if ins_str:find("LocalSpace") then return end
	if ev_name ~= "E_ENTITY_ADD_BUFF" then return end

	local Serialize = _G.Reg.lib("Serialize")
	self:log(string.format("CLIENT_EVENT | [%s] Ch: %s Ev: %s Code: %s Data: %s",
		ins_str, channel, ev_name, event_str, Serialize.dump_value(event_data)))
end

function SyncObserver:enable()
	self.state.seen_events = {}
	self.state.event_counts = { inbound_rpc = {}, inbound_sync = {} }
	self:hook("entity_method")
	self:hook("do_sync")
	self:hook("listenable")
	self.state.is_enabled = true
	self:log("Enabled")
	return true
end

function SyncObserver:disable()
	self:_print_summary()
	self:unhook("entity_method")
	self:unhook("do_sync")
	self:unhook("listenable")
	self.state.is_enabled = false
	self:log("Disabled")
	return true
end

function SyncObserver:is_enabled()
	return self.state.is_enabled == true
end

function SyncObserver:_print_summary()
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

	self:log("=== END SUMMARY ===")
end

return SyncObserver:new()
