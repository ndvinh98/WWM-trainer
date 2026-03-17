local ActionBase = _G.Reg.lib("ActionBase")
local Constants = _G.Reg.lib("Constants")

local DumpStaticData = ActionBase:extend("actions.dump_static_data")

local FSUtils = dofile(Constants.LIB_ROOT .. "\\fs_utils.lua")

local OUTPUT_DIRS = {
	grey = Constants.DATA_ROOT .. "\\DirObject\\GreyTableInfo",
	cache = Constants.DATA_ROOT .. "\\DirObject\\DirObject_Cache",
	weak_cache = Constants.DATA_ROOT .. "\\DirObject\\DirObject_WeakCache",
}

function DumpStaticData:define_state()
	return {
		persistent = {},
		transient = {},
	}
end

function DumpStaticData:define_hooks()
	return {}
end

function DumpStaticData:_load_dir_object()
	local ok, dir_object = pcall(portable.safe_import, "hexm.common.data.dir_object")
	if ok and dir_object then
		return dir_object
	end
	return nil
end

function DumpStaticData:_load_json()
	local ok, rapidjson = pcall(portable.safe_import, "rapidjson")
	if ok and rapidjson then
		return rapidjson
	end
	return nil
end

function DumpStaticData:_resolve_datam_path(module_path)
	if not G or not G.datam then
		return nil, "G.datam not available"
	end

	local datam_path = tostring(module_path):gsub("^hexm%.client%.data_oversea%.", "")
	local obj = G.datam
	for part in datam_path:gmatch("[^.]+") do
		obj = obj and obj[part] or nil
		if not obj then
			return nil, "Path not found: " .. tostring(part)
		end
	end
	return obj
end

function DumpStaticData:_write_json_file(kind, name, payload)
	local rapidjson = self:_load_json()
	if not rapidjson or not rapidjson.encode then
		return false, "rapidjson not available"
	end

	local output_dir = self:get_output_dir(kind)
	if not output_dir or not FSUtils.ensure_dir(output_dir) then
		return false, "Failed to create output directory"
	end

	local output_path = self:get_output_path(kind, name)
	local file, err = io.open(output_path, "w")
	if not file then
		return false, err
	end

	file:write(rapidjson.encode(payload, { pretty = true, sort_keys = true }))
	file:close()
	return true, output_path
end

function DumpStaticData:get_output_dir(kind)
	return OUTPUT_DIRS[kind]
end

function DumpStaticData:get_output_path(kind, name)
	local base_dir = OUTPUT_DIRS[kind]
	if not base_dir or not name or name == "" then
		return nil
	end
	return base_dir .. "\\" .. tostring(name) .. ".json"
end

function DumpStaticData:dump_grey_table()
	local dir_object = self:_load_dir_object()
	if not dir_object or not dir_object.DirObject or not dir_object.DirObject.GreyTableInfo then
		return false, "GreyTableInfo not available"
	end

	local items_ok, grey_items = pcall(function()
		return dir_object.DirObject.GreyTableInfo:items()
	end)
	if not items_ok or not grey_items then
		return false, "Failed to get grey table items"
	end

	local success_count = 0
	local fail_count = 0
	for _, entry in ipairs(grey_items) do
		local module_path = entry[1] or entry[0]
		local enabled = entry[2] or entry[1]
		if type(module_path) == "string" and enabled then
			local data_obj = self:_resolve_datam_path(module_path)
			if data_obj and type(data_obj.items) == "function" then
				local ok, payload = pcall(function()
					return data_obj:items()
				end)
				if ok and payload then
					local write_ok = self:_write_json_file("grey", module_path, payload)
					if write_ok then
						success_count = success_count + 1
					else
						fail_count = fail_count + 1
					end
				else
					fail_count = fail_count + 1
				end
			else
				fail_count = fail_count + 1
			end
		end
	end

	self:log(string.format("[DumpStaticData] GreyTableInfo: %d success, %d failed", success_count, fail_count))
	return true, success_count, fail_count
end

function DumpStaticData:dump_dir_object_cache()
	local dir_object = self:_load_dir_object()
	if not dir_object or not dir_object.DirObject or not dir_object.DirObject.DirObject_Cache then
		return false, "DirObject_Cache not available"
	end

	local keys_ok, keys = pcall(function()
		return dir_object.DirObject.DirObject_Cache:keys()
	end)
	if not keys_ok or not keys then
		return false, "Failed to get DirObject_Cache keys"
	end

	local success_count = 0
	local fail_count = 0
	for _, key in ipairs(keys) do
		if type(key) == "string" then
			local obj_ok, data_obj = pcall(function()
				return dir_object.DirObject.DirObject_Cache:get(key)
			end)
			if obj_ok and data_obj and type(data_obj.items) == "function" then
				local items_ok, payload = pcall(function()
					return data_obj:items()
				end)
				if items_ok and payload then
					local write_ok = self:_write_json_file("cache", key, payload)
					if write_ok then
						success_count = success_count + 1
					else
						fail_count = fail_count + 1
					end
				else
					fail_count = fail_count + 1
				end
			else
				fail_count = fail_count + 1
			end
		else
			fail_count = fail_count + 1
		end
	end

	self:log(string.format("[DumpStaticData] DirObject_Cache: %d success, %d failed", success_count, fail_count))
	return true, success_count, fail_count
end

function DumpStaticData:dump_dir_object_weak_cache()
	local dir_object = self:_load_dir_object()
	if not dir_object or not dir_object.DirObject or not dir_object.DirObject.DirObject_WeakCache then
		return false, "DirObject_WeakCache not available"
	end

	local success_count = 0
	local fail_count = 0
	for key, value in pairs(dir_object.DirObject.DirObject_WeakCache) do
		if type(key) == "string" and value and type(value.items) == "function" then
			local items_ok, payload = pcall(function()
				return value:items()
			end)
			if items_ok and payload then
				local write_ok = self:_write_json_file("weak_cache", key, payload)
				if write_ok then
					success_count = success_count + 1
				else
					fail_count = fail_count + 1
				end
			else
				fail_count = fail_count + 1
			end
		elseif type(key) == "string" then
			fail_count = fail_count + 1
		end
	end

	self:log(string.format("[DumpStaticData] DirObject_WeakCache: %d success, %d failed", success_count, fail_count))
	return true, success_count, fail_count
end

return DumpStaticData:new()
