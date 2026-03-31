-- Scripts/tests/probe_get_buff.lua
-- Probe: Discover API shape for G.main_player:get_buff / get_buffs / get_buff_by_No
-- Run: dofile(_G.SCRIPTS_PATH .. '\\tests\\probe_get_buff.lua')

pcall(function()
	local f = io.open(_G.SCRIPTS_PATH .. "\\logs\\probe_get_buff.txt", "w")
	if f then f:close() end
end)

_G.print_file = "probe_get_buff.txt"

local function log(msg)
	print("[BUFF_PROBE] " .. msg)
end

local function safe(fn, fallback)
	local ok, val = pcall(fn)
	if ok then return val end
	return fallback
end

local mp = G.main_player
if not mp then
	log("ERROR: no main_player")
	_G.print_file = nil
	return
end

-- === TEST 1: Check available buff methods on main_player ===
log(">>> TEST 1: Available buff methods")
local method_names = {
	"get_buff", "get_buffs", "get_buff_by_No", "buff_get_by_no",
	"has_buff", "add_buff", "remove_buff", "remove_buffs_by_No",
}
for _, name in ipairs(method_names) do
	local exists = mp[name] ~= nil
	local mtype = type(mp[name])
	log(string.format("  mp.%s: exists=%s type=%s", name, tostring(exists), mtype))
end

-- === TEST 2: get_buffs() return shape ===
log("\n>>> TEST 2: get_buffs() return shape")
local buffs_ok, buffs = pcall(function() return mp:get_buffs() end)
if buffs_ok and buffs then
	log(string.format("  type(get_buffs()) = %s", type(buffs)))
	log(string.format("  #buffs = %s", tostring(#buffs)))

	-- Try iterating with pairs
	local count = 0
	local sample_buff_id = nil
	local sample_buff_no = nil
	for buff_id, buff_item in pairs(buffs) do
		count = count + 1
		if count <= 5 then
			local bno = safe(function() return buff_item.buff_no end, "?")
			local bno2 = safe(function() return buff_item.No end, "?")
			log(string.format("  buff[%s]: buff_no=%s No=%s type=%s",
				tostring(buff_id), tostring(bno), tostring(bno2), type(buff_item)))
			if not sample_buff_id and bno ~= "?" then
				sample_buff_id = buff_id
				sample_buff_no = tonumber(bno)
			end
		end
	end
	log(string.format("  total buff entries: %d", count))

	-- === TEST 3: get_buff(buff_no) lookup ===
	if sample_buff_no then
		log("\n>>> TEST 3: get_buff(buff_no) with known buff_no=" .. sample_buff_no)
		local gb_ok, gb_val = pcall(function() return mp:get_buff(sample_buff_no) end)
		log(string.format("  get_buff(%d): ok=%s val=%s type=%s",
			sample_buff_no, tostring(gb_ok), tostring(gb_val ~= nil), type(gb_val)))

		-- Try get_buff_by_No
		local gbno_ok, gbno_val = pcall(function() return mp:get_buff_by_No(sample_buff_no) end)
		log(string.format("  get_buff_by_No(%d): ok=%s val=%s type=%s",
			sample_buff_no, tostring(gbno_ok), tostring(gbno_val ~= nil), type(gbno_val)))

		-- Try has_buff
		local hb_ok, hb_val = pcall(function() return mp:has_buff(sample_buff_no) end)
		log(string.format("  has_buff(%d): ok=%s val=%s",
			sample_buff_no, tostring(hb_ok), tostring(hb_val)))
	end

	-- === TEST 4: Negative — check a buff we definitely DON'T have ===
	log("\n>>> TEST 4: Negative lookup (buff_no=999999)")
	local neg_ok, neg_val = pcall(function() return mp:get_buff(999999) end)
	log(string.format("  get_buff(999999): ok=%s val=%s type=%s",
		tostring(neg_ok), tostring(neg_val), type(neg_val)))

	local neg2_ok, neg2_val = pcall(function() return mp:get_buff_by_No(999999) end)
	log(string.format("  get_buff_by_No(999999): ok=%s val=%s type=%s",
		tostring(neg2_ok), tostring(neg2_val), type(neg2_val)))

	local neg3_ok, neg3_val = pcall(function() return mp:has_buff(999999) end)
	log(string.format("  has_buff(999999): ok=%s val=%s",
		tostring(neg3_ok), tostring(neg3_val)))

	-- === TEST 5: Check specific buff IDs from our presets ===
	log("\n>>> TEST 5: Check preset buff IDs")
	local preset_ids = { 109040, 109041, 104027, 102704, 102701, 102452, 77120, 104051, 104031, 104045, 104021 }
	for _, bid in ipairs(preset_ids) do
		local ok1, v1 = pcall(function() return mp:get_buff(bid) end)
		local ok2, v2 = pcall(function() return mp:get_buff_by_No(bid) end)
		local ok3, v3 = pcall(function() return mp:has_buff(bid) end)
		log(string.format("  buff %d: get_buff=%s(%s) get_buff_by_No=%s(%s) has_buff=%s(%s)",
			bid,
			ok1 and tostring(v1 ~= nil) or "ERR", ok1 and "" or tostring(v1),
			ok2 and tostring(v2 ~= nil) or "ERR", ok2 and "" or tostring(v2),
			ok3 and tostring(v3) or "ERR", ok3 and "" or tostring(v3)))
	end
else
	log("  get_buffs() failed: " .. tostring(buffs))
end

log("\n========== PROBE COMPLETE ==========")
_G.print_file = nil
