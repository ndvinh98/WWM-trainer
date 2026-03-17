-- ============================================================
-- XINFA_BUFFS.LUA - Xinfa Passive Buff Extractor & Applicator
-- ============================================================
-- Extracts all xinfa with their passive buff lists from game data,
-- and can apply all passive buffs for a selected xinfa.
--
-- Data chain (from buff-system-analysis-21001002.md):
--   G.datam.xinfa[id] -> passive_skill_id (rank 0)
--   G.datam.xinfa_uprank_info[id*100+rank] -> passive_skill_id (rank 1+)
--   G.datam.passive_skills[skill_id] -> buff_id[] (condition=0 -> auto-add)
--
-- Runtime player xinfa access:
--   mp.xinfa:cur_plan().passive_slots -> equipped passive xinfa IDs
--   mp.xinfa_set[xinfa_id] -> Xinfa object with .rank, .level
--   Xinfa:passive_skill() -> rank-aware passive_skill_id
--
-- Prerequisites: Bootstrap must be loaded first

local XinfaBuffs = {}

-- Reference libs via Reg (loaded once by bootstrap)
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Utils = Reg.get("Utils")

local function _log(msg)
	Logger.log("[XinfaBuffs] " .. msg)
end

-- ============================================================
-- STATE (registered via Reg for reload safety)
-- ============================================================
local STATE_NAME = "XINFA_BUFFS_STATE"
if not Reg.has(STATE_NAME) then
	Reg.set(STATE_NAME, {
		applied_buffs = {}, -- { buff_id = true, ... }
		applied_xinfa_ids = {}, -- { xinfa_id = rank, ... }
	})
end
local _state = Reg.get(STATE_NAME)

-- Reg keys for generated data (survives reload)
local XINFA_DATA_KEY = "XINFA_BUFF_DATA"
local XINFA_LIST_KEY = "XINFA_BUFF_LIST"

-- ============================================================
-- DATA EXTRACTION
-- ============================================================

--- Translate a TID to display text
local function _translate(tid)
	if not tid then
		return nil
	end
	local ok, text = pcall(function()
		return G.locale_manager:get_locale_text_by_tid(tid)
	end)
	if ok and text and text ~= "" and text ~= tostring(tid) then
		return text
	end
	return nil
end

--- Get passive skill ID for a xinfa at a given rank from data tables
local function _get_passive_skill_id(xinfa_id, rank, xinfa_row)
	if rank and rank > 0 then
		local uprank_key = xinfa_id * 100 + rank
		local uprank_data = G.datam.xinfa_uprank_info and G.datam.xinfa_uprank_info:get(uprank_key)
		if uprank_data then
			local ps_id = uprank_data:get("passive_skill_id")
			if ps_id then
				return ps_id
			end
		end
	end
	-- Rank 0 or fallback: use base row
	return xinfa_row:get("passive_skill_id")
end

--- Get buff list from a passive skill ID
local function _get_buff_ids(passive_skill_id)
	if not passive_skill_id or not G.datam.passive_skills then
		return {}
	end
	local ps_data = G.datam.passive_skills:get(passive_skill_id)
	if not ps_data then
		return {}
	end

	local condition = ps_data:get("condition", 0)
	if condition ~= 0 then
		return {}
	end -- Only auto-add buffs

	local buff_ids = ps_data:get("buff_id")
	if not buff_ids then
		return {}
	end

	-- Convert to plain list
	local result = {}
	for _, bid in pairs(buff_ids) do
		result[#result + 1] = tonumber(bid)
	end
	return result
end

--- Build rank progression for a xinfa
local function _build_rank_progression(xinfa_id, xinfa_row)
	local max_rank = xinfa_row:get("max_advanced_lv", 6)
	local ranks = {}

	-- Collect unique passive skill IDs per rank
	local seen_ps = {}
	for rank = 0, max_rank do
		local ps_id = _get_passive_skill_id(xinfa_id, rank, xinfa_row)
		if ps_id and not seen_ps[ps_id] then
			seen_ps[ps_id] = true
			local buff_ids = _get_buff_ids(ps_id)
			if #buff_ids > 0 then
				ranks[#ranks + 1] = {
					rank = rank,
					passive_skill_id = ps_id,
					buff_ids = buff_ids,
				}
			end
		end
	end

	return ranks, max_rank
end

--- Generate XINFA_DATA and XINFA_LIST from G.datam
function XinfaBuffs.generate_data()
	if not G or not G.datam then
		_log("ERROR: G.datam not available")
		return nil, nil
	end

	local xinfa_table = G.datam.xinfa
	if not xinfa_table then
		_log("ERROR: G.datam.xinfa not available")
		return nil, nil
	end

	local xinfa_data = {}
	local xinfa_list = {}
	local count = 0

	local items = xinfa_table:items()
	if not items then
		_log("ERROR: xinfa:items() returned nil")
		return nil, nil
	end

	for _, entry in pairs(items) do
		local xinfa_id = tonumber(entry[1])
		local row = entry[2]
		if xinfa_id and row then
			local name = _translate(row:get("name", nil)) or ("Xinfa #" .. xinfa_id)
			local xinfa_type = row:get("type", 0)
			local star = row:get("star", 0)
			local liupai_id = row:get("liupai_id", 0)
			local icon_no = row:get("icon_no", "")

			-- Build rank progression (passive_skill -> buff_ids)
			local ranks, max_rank = _build_rank_progression(xinfa_id, row)

			-- Get highest rank buff list as default display
			local highest_rank = ranks[#ranks]
			local default_buffs = highest_rank and highest_rank.buff_ids or {}

			if #default_buffs > 0 or #ranks > 0 then
				xinfa_data[xinfa_id] = {
					name = name,
					xinfa_type = xinfa_type,
					star = star,
					liupai_id = liupai_id,
					icon_no = icon_no,
					max_rank = max_rank,
					ranks = ranks,
					default_buffs = default_buffs,
				}

				xinfa_list[#xinfa_list + 1] = {
					xinfa_id = xinfa_id,
					name = name,
					star = star,
					xinfa_type = xinfa_type,
					buff_count = #default_buffs,
					rank_count = #ranks,
				}

				count = count + 1
			end
		end
	end

	-- Sort: by star desc, then name asc
	table.sort(xinfa_list, function(a, b)
		if a.star ~= b.star then
			return a.star > b.star
		end
		return a.name < b.name
	end)

	-- Store in Reg for reload safety
	Reg.set(XINFA_DATA_KEY, xinfa_data)
	Reg.set(XINFA_LIST_KEY, xinfa_list)

	_log("Generated " .. count .. " xinfa entries with passive buffs")
	return xinfa_data, xinfa_list
end

--- Load xinfa data (generate once, then from Reg cache)
function XinfaBuffs.load_data()
	local data = Reg.get(XINFA_DATA_KEY)
	local xinfa_list = Reg.get(XINFA_LIST_KEY)
	if data and xinfa_list then
		return data, xinfa_list
	end
	return XinfaBuffs.generate_data()
end

function XinfaBuffs.get_list()
	local _, xinfa_list = XinfaBuffs.load_data()
	return xinfa_list or {}
end

function XinfaBuffs.get_xinfa(xinfa_id)
	local data, _ = XinfaBuffs.load_data()
	return data and data[tonumber(xinfa_id)]
end

-- ============================================================
-- BUFF APPLICATION
-- ============================================================

--- Apply a single buff via fake_server.buff (the stronger local path)
local function _apply_buff(buff_id)
	local mp = G.main_player
	if not mp then
		_log("No main player")
		return false
	end

	-- Primary path: fake_server.buff:add_buff (works in single-mode spaces)
	if mp.fake_server and mp.fake_server.buff then
		local ok, err = pcall(function()
			mp.fake_server.buff:add_buff(buff_id, mp.id)
		end)
		if ok then
			return true
		end
		_log("fake_server.buff failed for " .. buff_id .. ": " .. tostring(err))
	end

	-- Fallback: player add_buff (routes through RPC or fake_server internally)
	if mp.add_buff then
		local ok, err = pcall(function()
			mp:add_buff(buff_id, mp.id, {
				["duration"] = -1,
				["persistent"] = false,
				["reason"] = "xinfa_buffs_mod",
				["ignore_dead"] = true,
			})
		end)
		if ok then
			return true
		end
		_log("add_buff fallback failed for " .. buff_id .. ": " .. tostring(err))
	end

	return false
end

--- Remove a single buff
local function _remove_buff(buff_id)
	local mp = G.main_player
	if not mp then
		return false
	end

	-- Try fake_server removal first
	if mp.fake_server and mp.fake_server.buff then
		local ok = pcall(function()
			mp.fake_server.buff:remove_buffs_by_No({ buff_id }, mp.id, "xinfa_buffs_mod")
		end)
		if ok then
			return true
		end
	end

	-- Fallback methods
	if mp.remove_buffs_by_No then
		local ok = pcall(function()
			mp:remove_buffs_by_No({ buff_id }, mp.id, "xinfa_buffs_mod")
		end)
		if ok then
			return true
		end
	end

	return false
end

--- Collect all buff IDs across all ranks for a xinfa
--- Returns a set { buff_id = true } of every buff from every rank
local function _collect_all_rank_buffs(xinfa)
	local all = {}
	for _, r in ipairs(xinfa.ranks) do
		for _, bid in ipairs(r.buff_ids) do
			all[bid] = true
		end
	end
	return all
end

--- Apply all passive buffs for a xinfa at a given rank
--- @param xinfa_id number
--- @param rank number|nil - If nil, uses highest available rank
function XinfaBuffs.apply(xinfa_id, rank)
	xinfa_id = tonumber(xinfa_id)
	if not xinfa_id then
		return false, "Invalid xinfa_id"
	end

	local xinfa = XinfaBuffs.get_xinfa(xinfa_id)
	if not xinfa then
		return false, "Xinfa not found: " .. xinfa_id
	end

	-- Find the right rank entry
	local buff_ids
	if rank then
		for _, r in ipairs(xinfa.ranks) do
			if r.rank <= rank then
				buff_ids = r.buff_ids
			end
		end
	end
	buff_ids = buff_ids or xinfa.default_buffs

	if #buff_ids == 0 then
		return false, "No buffs for xinfa " .. xinfa_id
	end

	-- Build set of target (highest) buff IDs for quick lookup
	local target_set = {}
	for _, bid in ipairs(buff_ids) do
		target_set[bid] = true
	end

	-- Remove lower-rank buffs that are NOT in the target set
	-- These are buffs from other ranks of the same xinfa that the player
	-- already has from the real xinfa system at their actual rank
	local all_rank_buffs = _collect_all_rank_buffs(xinfa)
	local removed_lower = 0
	for bid, _ in pairs(all_rank_buffs) do
		if not target_set[bid] then
			if _remove_buff(bid) then
				removed_lower = removed_lower + 1
			end
		end
	end

	-- Apply highest rank buffs (dedup against already-applied set)
	local applied = 0
	for _, bid in ipairs(buff_ids) do
		if not _state.applied_buffs[bid] then
			if _apply_buff(bid) then
				applied = applied + 1
				_state.applied_buffs[bid] = true
			end
		end
	end

	_state.applied_xinfa_ids[xinfa_id] = rank or -1

	_log(
		string.format(
			"Applied %d/%d buffs for xinfa %d (%s) rank=%s (removed %d lower-rank buffs)",
			applied,
			#buff_ids,
			xinfa_id,
			xinfa.name,
			tostring(rank or "max"),
			removed_lower
		)
	)
	return true, applied, #buff_ids
end

--- Apply passive buffs for ALL currently equipped xinfa on the player
--- Reads the player's actual equipped passive xinfa slots and their runtime ranks
function XinfaBuffs.apply_current()
	local mp = G.net:get_avatar()
	if not mp then
		return false, "No main player"
	end

	-- Remove any previously applied mod buffs
	XinfaBuffs.remove_applied()

	-- Read player's equipped passive xinfa from runtime
	local plan = mp.xinfa and mp.xinfa.cur_plan and mp.xinfa:cur_plan()
	if not plan or not plan.passive_slots then
		_log("ERROR: Could not read player xinfa plan: " .. Utils.dump_value(plan))
		return false, "No xinfa plan"
	end

	local total_applied = 0
	local total_buffs = 0
	local applied_names = {}

	for _, xinfa_id in pairs(plan.passive_slots) do
		xinfa_id = tonumber(xinfa_id)
		if xinfa_id and xinfa_id > 0 then
			-- Always apply highest rank buffs (pass nil -> uses default_buffs which is highest rank)
			local ok, applied, total = XinfaBuffs.apply(xinfa_id, nil)
			if ok then
				total_applied = total_applied + (applied or 0)
				total_buffs = total_buffs + (total or 0)
				local xinfa_info = XinfaBuffs.get_xinfa(xinfa_id)
				applied_names[#applied_names + 1] = xinfa_info and xinfa_info.name or tostring(xinfa_id)
			end
		end
	end

	if #applied_names > 0 then
		_log(
			string.format(
				"Applied current xinfa buffs: %d/%d from [%s]",
				total_applied,
				total_buffs,
				table.concat(applied_names, ", ")
			)
		)
	else
		_log("No equipped passive xinfa found")
	end

	return total_applied > 0, total_applied, total_buffs
end

--- Remove all previously applied xinfa buffs
function XinfaBuffs.remove_applied()
	local removed = 0
	for bid, _ in pairs(_state.applied_buffs) do
		if _remove_buff(bid) then
			removed = removed + 1
		end
	end
	if removed > 0 then
		_log("Removed " .. removed .. " previously applied xinfa buffs")
	end
	_state.applied_buffs = {}
	_state.applied_xinfa_ids = {}
	return removed
end

--- Get currently applied xinfa info
function XinfaBuffs.get_applied()
	return _state.applied_xinfa_ids
end

--- Check if any xinfa buffs are currently applied
function XinfaBuffs.is_applied()
	return next(_state.applied_buffs) ~= nil
end

return XinfaBuffs
