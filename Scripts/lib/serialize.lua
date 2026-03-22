-- ============================================================
-- SERIALIZE.LUA - Value serialization: game types → plain Lua → strings
-- ============================================================
-- Extracted from utils.lua — only contains custom logic not in the runtime.

local _ROOT = "C:\\temp\\Where Winds Meet\\Scripts"
local inspect = dofile(_ROOT .. "\\lib\\inspect.lua")

local Serialize = {}

-- ────────────────────────────────────────────────────────────
-- Type checking helpers
-- ────────────────────────────────────────────────────────────

function Serialize.is_pairable(obj)
	if obj == nil then
		return false
	end
	local t = type(obj)
	if t == "table" then
		return true
	end
	if t == "userdata" then
		local ok = pcall(function()
			for _ in pairs(obj) do
				break
			end
		end)
		return ok
	end
	-- Engine types: list, dict, instance
	if t == "list" or t == "dict" or t == "instance" then
		return true
	end
	return false
end

function Serialize.is_instance_like(obj)
	if obj == nil then
		return false
	end
	local t = type(obj)
	return t == "instance" or t == "class" or t == "userdata"
end

-- ────────────────────────────────────────────────────────────
-- Normalization: convert game types to plain Lua tables
-- ────────────────────────────────────────────────────────────

local function _normalize(val, depth, max_depth, seen)
	depth = depth or 0
	max_depth = max_depth or 5
	seen = seen or {}

	if depth > max_depth then
		return "<max_depth>"
	end
	if val == nil then
		return nil
	end

	local t = type(val)

	-- Plain types pass through
	if t == "string" or t == "number" or t == "boolean" then
		return val
	end

	-- Cycle detection for reference types
	if
		t == "table"
		or t == "list"
		or t == "dict"
		or t == "instance"
		or t == "class"
		or t == "tuple"
		or t == "userdata"
	then
		if seen[val] then
			return "<cycle>"
		end
		seen[val] = true
	end

	-- dict → plain table
	if t == "dict" then
		local result = {}
		local ok, _ = pcall(function()
			if val.keys and val.get then
				for _, k in ipairs(val:keys()) do
					local v = val:get(k)
					result[_normalize(k, depth + 1, max_depth, seen)] = _normalize(v, depth + 1, max_depth, seen)
				end
			elseif val.items then
				for _, pair in ipairs(val:items()) do
					result[_normalize(pair[1], depth + 1, max_depth, seen)] =
						_normalize(pair[2], depth + 1, max_depth, seen)
				end
			end
		end)
		if not ok then
			pcall(function()
				for k, v in pairs(val) do
					result[_normalize(k, depth + 1, max_depth, seen)] = _normalize(v, depth + 1, max_depth, seen)
				end
			end)
		end
		return result
	end

	-- list / tuple → plain array
	if t == "list" or t == "tuple" then
		local result = {}
		local ok, _ = pcall(function()
			if val.tolist then
				local lst = val:tolist()
				for i, v in ipairs(lst) do
					result[i] = _normalize(v, depth + 1, max_depth, seen)
				end
			else
				for i = 1, #val do
					result[i] = _normalize(val[i], depth + 1, max_depth, seen)
				end
			end
		end)
		if not ok then
			pcall(function()
				for i, v in pairs(val) do
					result[i] = _normalize(v, depth + 1, max_depth, seen)
				end
			end)
		end
		return "[" .. table.concat(result, ", ") .. "]"
	end

	-- instance / class → best-effort extraction
	if t == "instance" or t == "class" then
		local result = { __type = t }
		pcall(function()
			result.tostring = tostring(val)
			if val.__cname__ then
				result.__class = val.__cname__
			end
			if val.todict then
				local d = val:todict()
				for k, v in pairs(d) do
					result[tostring(k)] = _normalize(v, depth + 1, max_depth, seen)
				end
			end
		end)
		return result
	end

	-- userdata → try tostring
	if t == "userdata" then
		local ok, s = pcall(tostring, val)
		return ok and s or "<userdata>"
	end

	-- plain table
	if t == "table" then
		local result = {}
		for k, v in pairs(val) do
			result[_normalize(k, depth + 1, max_depth, seen)] = _normalize(v, depth + 1, max_depth, seen)
		end
		return result
	end

	return tostring(val)
end

Serialize.normalize = _normalize

-- ────────────────────────────────────────────────────────────
-- Pretty printing
-- ────────────────────────────────────────────────────────────

function Serialize.dump_value(val, options)
	options = options or {}
	local pretty = options.pretty or false
	local max_depth = options.max_depth or 5

	-- Normalize game types first
	local normalized = _normalize(val, 0, max_depth, {})

	-- Use inspect for pretty printing
	return inspect(normalized, {
		pretty = pretty,
		newline = pretty and "\n" or " ",
		indent = "  ",
	})
end

function Serialize.dump_instance(obj)
	if not Serialize.is_instance_like(obj) then
		return Serialize.dump_value(obj)
	end
	return inspect(obj, {
		pretty = true,
		inspect_instances_deep = true,
	})
end

_G.dump = Serialize.dump_value

return Serialize
