local TypeUtils = {}

function TypeUtils.init_dict(tbl)
	local CustomMapType = require("common.classutils").CustomMapType
	local data = CustomMapType(tbl):to_valid_dict()
	return data
end

function TypeUtils.init_list(tbl)
	local CustomListType = require("common.classutils").CustomListType
	local data = CustomListType(tbl):to_list()
	return data
end

return TypeUtils
