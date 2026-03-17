local FSUtils = {}

local fileutils_cache = false

local function get_fileutils()
	if fileutils_cache ~= false then
		return fileutils_cache
	end

	local candidates = {
		"fileutils",
		"engine.Lib.fileutils",
	}

	for _, name in ipairs(candidates) do
		local ok, mod = pcall(portable.safe_import, name)
		if ok and mod then
			fileutils_cache = mod
			return mod
		end
	end

	fileutils_cache = nil
	return nil
end

function FSUtils.path_exists(path)
	local fileutils = get_fileutils()
	if fileutils and type(fileutils.exist) == "function" then
		local ok, exists = pcall(fileutils.exist, path)
		if ok then
			return exists == true
		end
	end

	local ok, _, code = os.rename(path, path)
	return ok == true or code == 13
end

function FSUtils.mkdir(path)
	if FSUtils.path_exists(path) then
		return true
	end

	local fileutils = get_fileutils()
	if fileutils and type(fileutils.mkdir) == "function" then
		local ok, result = pcall(fileutils.mkdir, path)
		if ok and result ~= nil then
			return result == true or FSUtils.path_exists(path)
		end
	end

	local ok = os.execute('mkdir "' .. path .. '" 2>nul')
	return ok == true or ok == 0 or FSUtils.path_exists(path)
end

function FSUtils.ensure_dir(path)
	if not path or path == "" then
		return false
	end

	if FSUtils.path_exists(path) then
		return true
	end

	local current = nil
	for part in tostring(path):gmatch("[^\\]+") do
		if current == nil then
			current = part
		else
			current = current .. "\\" .. part
		end
		FSUtils.mkdir(current)
	end

	return FSUtils.path_exists(path)
end

function FSUtils.ensure_parent_dir(filepath)
	local parts = {}
	for part in tostring(filepath):gmatch("[^\\]+") do
		parts[#parts + 1] = part
	end

	if #parts < 2 then
		return true
	end

	local current = parts[1]
	for i = 2, #parts - 1 do
		current = current .. "\\" .. parts[i]
		FSUtils.mkdir(current)
	end
	return true
end

function FSUtils.sanitize_name(name)
	return tostring(name):gsub("[^%w%._-]", "_")
end

function FSUtils.get_module_output_path(module_path, output_dir, ext)
	local path_parts = {}
	for part in tostring(module_path):gmatch("[^%.]+") do
		path_parts[#path_parts + 1] = FSUtils.sanitize_name(part)
	end

	if #path_parts == 0 then
		return nil
	end

	local current = output_dir
	for i = 1, #path_parts - 1 do
		current = current .. "\\" .. path_parts[i]
	end
	return current .. "\\" .. path_parts[#path_parts] .. (ext or "")
end

return FSUtils
