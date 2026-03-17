--[[
    TraceCore - Call Tracing Utilities

    Provides:
    - start: Start tracing with debug hook
    - stop: Stop tracing and save files
    - build_compact_tree: Generate compact call tree
    - build_slices: Extract event-centered slices

    Saves traces to folder structure organized by module path.
    Creates index.log to track sequential order of all calls.
]]
-- Reference libs via Reg (loaded once by bootstrap)
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Serialize = Reg.lib("Serialize")

local TraceCore = {}

-- ============================================================
-- CONFIGURATION
-- ============================================================
local BASE_PATH = Constants and (Constants.SCRIPTS_ROOT .. "\\traces\\")
	or "C:\\temp\\Where Winds Meet\\Scripts\\traces\\"

-- Source prefixes to skip (reduce noise)
local SKIP_SRC_PREFIXES = {
	"engine/",
	"Sunshine/",
	"SunshineSDK/",
	"hexm/client/ui/red_point/",
	"hexm/client/ui/struct/",
	"hexm/client/ui/windows/chat/",
	"hexm/client/ui/windows/exp_level/",
	"hexm/client/ui/windows/home/",
	"hexm/client/entities/local/space_members/",
	"hexm/client/entities/local/space_component/",
	"hexm/client/entities/local/component/camera/",
	"hexm/client/entities/local/common_members/entity_common/",
	"hexm/client/entities/local/component/anim",
	"hexm/client/manager/input/",
	"hexm/client/trace.lua",
	"hexm/common/AI/",
	"hexm/common/strict.lua",
	"hexm/common/data/",
	"hexm/common/container/",
	"hexm/common/misc/",
	"hexm/common/flag_",
	"hexm/common/base/sight/",
	"hexm/common/datetime_manager.lua",
	"hexm/client/manager/task_queue/",
	"hexm/client/util/",
	"hexm/client/engine/",
	"hexm/client/server/",
	"hexm/client/entities/local/component/",
	"hexm/client/entities/local/component/",
	"hexm/client/entities/server/",
	"hexm/client/manager/",
	"C:\\temp\\Where Winds Meet\\Scripts",
}

-- Function names to skip
local SKIP_FUNC_NAMES = {
	newindexdot = true,
	excepthook = true,
	__G__TRACKBACK__ = true,
	repr = true,
	len = true,
	error = true,
	get_trace_msg = true,
	show_trace = true,
	format_datetime = true,
	now = true,
	now_raw = true,
}

-- Post-process config
local SLICE_WINDOW = 120
local ANCHOR_PATTERNS = {
	'event="e_parry"',
	'event="e_be_parry"',
	'event="e_pre_damage"',
}

local SAVE_ACTUAL_LOGS = false
local MAX_ARGS = 10

-- Output format: "readable" (default) or "json" (compact, searchable)
local OUTPUT_FORMAT = "json"

-- ============================================================
-- INTERNAL STATE
-- ============================================================
local _state = {
	is_enabled = false,
	index_file = nil,
	call_sequence = 0,
	file_count = 0,
	current_trace = {},
	trace_count = 0,
	root_func_name = nil,
	root_src = nil,
	created_folders = {},
	this_src = nil,
	in_hook = false,
	session_id = nil, -- Current session ID (timestamp-based)
}

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================
local dbg = debug

local function get_timestamp()
	local t = os.date("*t")
	local ms = math.floor((os.clock() % 1) * 1000)
	return string.format("%02d%02d%02d_%03d", t.hour, t.min, t.sec, ms)
end

local function extract_filename(src)
	if not src or src == "" or src == "?" then
		return "unknown"
	end
	src = src:gsub(":%d+$", "")
	local filename = src:match("([^/\\]+)%.lua$") or src:match("([^/\\]+)$") or "unknown"
	filename = filename:gsub("[^%w_]", "_")
	if #filename > 30 then
		filename = filename:sub(1, 30)
	end
	return filename
end

local function sanitize_name(name)
	if not name or name == "" or name == "<anonymous>" then
		return "anon"
	end
	name = name:gsub("[^%w_]", "_")
	if #name > 20 then
		name = name:sub(1, 20)
	end
	return name
end

local function basename(p)
	if not p or p == "" then
		return "?"
	end
	p = p:gsub(":%d+$", "")
	return p:match("([^/\\]+)$") or p
end

local function safe_tostring(v)
	local t = type(v)
	if t == "string" then
		local s = v
		local max_len = 200
		if #s > max_len then
			s = s:sub(1, max_len) .. string.format("...<len=%d>", #s)
		end
		return string.format("%q", s)
	elseif t == "number" or t == "boolean" or t == "nil" then
		return tostring(v)
	end
	local ok_t, s = pcall(tostring, v)
	if ok_t and type(s) == "string" then
		return s
	end
	return "<" .. t .. ">"
end

-- JSON escape helper
local function json_escape(s)
	if type(s) ~= "string" then
		return tostring(s)
	end
	return s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
end

local function generate_session_id()
	local t = os.date("*t")
	return string.format("%04d%02d%02d_%02d%02d%02d", t.year, t.month, t.day, t.hour, t.min, t.sec)
end

local function ensure_folder(src)
	if not src or src == "?" then
		-- Still need session folder even for unknown source
		local session_path = BASE_PATH .. "session_" .. (_state.session_id or "unknown") .. "\\"
		if not _state.created_folders[session_path] then
			os.execute('mkdir "' .. session_path .. '" 2>nul')
			_state.created_folders[session_path] = true
		end
		return session_path
	end
	local dir = src:match("(.+)[/\\][^/\\]+$") or ""
	if dir == "" then
		local session_path = BASE_PATH .. "session_" .. (_state.session_id or "unknown") .. "\\"
		if not _state.created_folders[session_path] then
			os.execute('mkdir "' .. session_path .. '" 2>nul')
			_state.created_folders[session_path] = true
		end
		return session_path
	end
	dir = dir:gsub("/", "\\")
	-- Include session folder in path: traces/hexm/client/.../session_xxx/
	local full_path = BASE_PATH .. dir .. "\\session_" .. (_state.session_id or "unknown") .. "\\"
	if not _state.created_folders[full_path] then
		os.execute('mkdir "' .. full_path .. '" 2>nul')
		_state.created_folders[full_path] = true
	end
	return full_path
end

local function write_index(filepath, func_name, src)
	_state.call_sequence = _state.call_sequence + 1
	if _state.index_file then
		local timestamp = os.date("%H:%M:%S")
		local ms = math.floor((os.clock() % 1) * 1000)
		_state.index_file:write(
			string.format(
				"%05d | %s.%03d | %s | %s | %s\n",
				_state.call_sequence,
				timestamp,
				ms,
				func_name or "?",
				src or "?",
				filepath
			)
		)
		_state.index_file:flush()
	end
end

local function add_line(line)
	_state.trace_count = _state.trace_count + 1
	_state.current_trace[_state.trace_count] = line
end

local function count_leading_spaces(s)
	local a = s:match("^(%s*)")
	return a and #a or 0
end

local function extract_call_fields(line)
	local func, src, lno = line:match("^%s*CALL%s+([^%s]+)%s+%((.-):(%-?%d+)%)")
	if not func then
		func, src, lno = line:match("^%s*CALL%s+(.+)%s+%((.-):(%-?%d+)%)")
	end
	local args = line:match("args:%s*%((.*)%)%s*$")
	return func, src, tonumber(lno), args
end

local function line_has_anchor(line)
	if not line then
		return false
	end
	for _, pat in ipairs(ANCHOR_PATTERNS) do
		if line:find(pat, 1, true) then
			return true
		end
	end
	return false
end

local function build_compact_tree(lines)
	local out = {}
	local last_depth = -1
	local first_srcfile = nil

	for i = 1, #lines do
		local line = lines[i]
		if line:find("CALL ", 1, true) == 1 or line:match("^%s*CALL%s") then
			local spaces = count_leading_spaces(line)
			local depth = math.floor(spaces / 2)
			local func, src, lno, args = extract_call_fields(line)
			if func and src then
				local srcfile = basename(src)
				if not first_srcfile then
					first_srcfile = srcfile
					out[#out + 1] = srcfile
				end
				local indent = string.rep("  ", depth)
				local bullet = (depth == 0) and "  └─ " or indent .. "└─ "
				local args_str = args and ("  args: (" .. args .. ")") or ""
				out[#out + 1] = string.format("%s%s : %s()%s", bullet, srcfile, func, args_str)
				last_depth = depth
			end
		end

		if
			line:find('event="e_parry"', 1, true)
			or line:find('event="e_be_parry"', 1, true)
			or line:find('event="e_pre_damage"', 1, true)
		then
			local indent = string.rep("  ", math.max(0, last_depth + 1))
			local ev = line:match('event="([^"]+)"') or "event"
			out[#out + 1] = string.format("%s└─ dispatch event : %s", indent, ev)
		end
	end

	return out
end

-- Build JSON tree from trace lines
-- Returns a structured JSON object representing the call stack
local function build_json_tree(lines, root_func, root_src)
	-- Parse lines into structured nodes
	local nodes = {}
	local stack = {} -- Stack of {depth, node}

	for i = 1, #lines do
		local line = lines[i]
		if line:find("CALL ", 1, true) or line:match("^%s*CALL%s") then
			local spaces = count_leading_spaces(line)
			local depth = math.floor(spaces / 2)
			local func, src, lno, args = extract_call_fields(line)

			if func and src then
				local node = {
					func = func,
					src = basename(src),
					line = lno or 0,
					args = args or "",
					children = {},
				}

				-- Find parent by matching depth
				while #stack > 0 and stack[#stack].depth >= depth do
					table.remove(stack)
				end

				if #stack > 0 then
					-- Add as child of parent
					local parent = stack[#stack].node
					parent.children[#parent.children + 1] = node
				else
					-- Top-level node
					nodes[#nodes + 1] = node
				end

				-- Push this node onto stack
				stack[#stack + 1] = { depth = depth, node = node }
			end
		end

		-- Handle event dispatches
		if
			line:find('event="e_parry"', 1, true)
			or line:find('event="e_be_parry"', 1, true)
			or line:find('event="e_pre_damage"', 1, true)
		then
			local ev = line:match('event="([^"]+)"') or "event"
			local event_node = {
				func = "dispatch_event",
				src = "event",
				line = 0,
				args = 'event="' .. ev .. '"',
				children = {},
			}

			if #stack > 0 then
				local parent = stack[#stack].node
				parent.children[#parent.children + 1] = event_node
			else
				nodes[#nodes + 1] = event_node
			end
		end
	end

	return nodes
end

-- Serialize a node to JSON string
local function node_to_json(node, indent)
	indent = indent or 0
	local sp = string.rep("  ", indent)
	local sp2 = string.rep("  ", indent + 1)
	local parts = {}

	parts[#parts + 1] = sp .. "{"
	parts[#parts + 1] = sp2 .. '"func": "' .. json_escape(node.func) .. '",'
	parts[#parts + 1] = sp2 .. '"src": "' .. json_escape(node.src) .. '",'
	parts[#parts + 1] = sp2 .. '"line": ' .. tostring(node.line) .. ","
	parts[#parts + 1] = sp2 .. '"args": "' .. json_escape(node.args) .. '",'

	if node.children and #node.children > 0 then
		parts[#parts + 1] = sp2 .. '"children": ['
		for i, child in ipairs(node.children) do
			local child_json = node_to_json(child, indent + 2)
			if i < #node.children then
				child_json = child_json .. ","
			end
			parts[#parts + 1] = child_json
		end
		parts[#parts + 1] = sp2 .. "]"
	else
		parts[#parts + 1] = sp2 .. '"children": []'
	end

	parts[#parts + 1] = sp .. "}"
	return table.concat(parts, "\n")
end

-- Build complete JSON output
local function build_json_output(lines, root_func, root_src, seq)
	local nodes = build_json_tree(lines, root_func, root_src)
	local parts = {}

	parts[#parts + 1] = "{"
	parts[#parts + 1] = '  "_trace": true,'
	parts[#parts + 1] = '  "_seq": ' .. tostring(seq) .. ","
	parts[#parts + 1] = '  "_root_func": "' .. json_escape(root_func or "unknown") .. '",'
	parts[#parts + 1] = '  "_root_src": "' .. json_escape(root_src or "unknown") .. '",'
	parts[#parts + 1] = '  "_time": "' .. os.date("%Y-%m-%d %H:%M:%S") .. '",'
	parts[#parts + 1] = '  "calls": ['

	for i, node in ipairs(nodes) do
		local node_json = node_to_json(node, 2)
		if i < #nodes then
			node_json = node_json .. ","
		end
		parts[#parts + 1] = node_json
	end

	parts[#parts + 1] = "  ]"
	parts[#parts + 1] = "}"

	return table.concat(parts, "\n")
end

local function build_slices(lines)
	local out = {}
	local seen = {}
	for i = 1, #lines do
		if line_has_anchor(lines[i]) then
			local key = (lines[i]:sub(1, 200))
			if not seen[key] then
				seen[key] = true
				local a = math.max(1, i - SLICE_WINDOW)
				local b = math.min(#lines, i + SLICE_WINDOW)
				out[#out + 1] = ""
				out[#out + 1] = string.rep("=", 80)
				out[#out + 1] = string.format("ANCHOR @ line %d (window %d): %s", i, SLICE_WINDOW, lines[i])
				out[#out + 1] = string.rep("-", 80)
				for j = a, b do
					out[#out + 1] = string.format("%6d | %s", j, lines[j])
				end
			end
		end
	end
	if #out == 0 then
		return nil
	end
	return out
end

local function save_trace_to_file()
	if _state.trace_count == 0 then
		return
	end

	_state.file_count = _state.file_count + 1

	local folder_path = ensure_folder(_state.root_src)
	local src_name = extract_filename(_state.root_src)
	local func_name = sanitize_name(_state.root_func_name)
	local timestamp = get_timestamp()
	local base_filename = string.format("%s%s_%s_%s", folder_path, src_name, func_name, timestamp)

	-- Determine the actual output filename based on format
	local actual_filename
	if OUTPUT_FORMAT == "json" then
		actual_filename = base_filename .. ".json"
	else
		actual_filename = base_filename .. "_compact.log"
	end

	-- Write to index with the ACTUAL filename that will be created
	local relative_path = actual_filename:sub(#BASE_PATH + 1)
	write_index(relative_path, _state.root_func_name, _state.root_src)

	-- Save raw logs if enabled
	if SAVE_ACTUAL_LOGS then
		local f = io.open(base_filename .. ".log", "wb")
		if f then
			f:write("-- Sequence: " .. _state.call_sequence .. "\n")
			f:write("-- Root: " .. (_state.root_func_name or "unknown") .. "\n")
			f:write("-- Source: " .. (_state.root_src or "unknown") .. "\n")
			f:write("-- Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n")
			f:write(table.concat(_state.current_trace, "\n"))
			f:write("\n")
			f:close()
		end
	end

	-- Output compact tree OR JSON based on format
	if OUTPUT_FORMAT == "json" then
		-- JSON output
		local json_path = base_filename .. ".json"
		local jf = io.open(json_path, "wb")
		if jf then
			local json_output =
				build_json_output(_state.current_trace, _state.root_func_name, _state.root_src, _state.call_sequence)
			jf:write(json_output)
			jf:write("\n")
			jf:close()
		end
	else
		-- Readable compact tree output (default)
		local compact_path = base_filename .. "_compact.log"
		local cf = io.open(compact_path, "wb")
		if cf then
			cf:write("-- Compact call tree (CALL-only)\n")
			cf:write("-- Root: " .. (_state.root_func_name or "unknown") .. "\n")
			cf:write("-- Source: " .. (_state.root_src or "unknown") .. "\n")
			cf:write("-- Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n")
			cf:write(
				string.format(
					"[ROOT] %s : %s()\n",
					basename(_state.root_src or "?"),
					_state.root_func_name or "anonymous"
				)
			)
			cf:write(table.concat(build_compact_tree(_state.current_trace), "\n"))
			cf:write("\n")
			cf:close()
		end
	end

	local slices = build_slices(_state.current_trace)
	if slices then
		local slice_path = base_filename .. "_slice.log"
		local sf = io.open(slice_path, "wb")
		if sf then
			sf:write("-- Anchor slices around e_parry / e_be_parry / e_pre_damage\n")
			sf:write("-- Window: " .. tostring(SLICE_WINDOW) .. " lines before/after\n\n")
			sf:write(table.concat(slices, "\n"))
			sf:write("\n")
			sf:close()
		end
	end

	_state.current_trace = {}
	_state.trace_count = 0
	_state.root_func_name = nil
	_state.root_src = nil
end

local function should_skip(info)
	local src = info.short_src or ""

	if _state.this_src and src == _state.this_src then
		return true
	end

	for _, prefix in ipairs(SKIP_SRC_PREFIXES) do
		if src == prefix or src:sub(1, #prefix) == prefix then
			return true
		end
	end

	local name = info.name
	if name and SKIP_FUNC_NAMES[name] then
		return true
	end

	return false
end

local function get_indent()
	local depth = 0
	local level = 3

	while true do
		local info = dbg.getinfo(level, "S")
		if not info then
			break
		end
		if info.what == "Lua" then
			depth = depth + 1
		end
		level = level + 1
	end

	if depth > 0 then
		depth = depth - 1
	end

	return string.rep("  ", depth), depth
end

local function hook(event, line)
	if _state.in_hook then
		return
	end
	if event ~= "call" and event ~= "tail call" and event ~= "return" then
		return
	end

	_state.in_hook = true

	local info
	if event == "return" then
		info = dbg.getinfo(2, "nS")
	else
		info = dbg.getinfo(2, "nSlu")
	end

	if not info or info.what ~= "Lua" or should_skip(info) then
		_state.in_hook = false
		return
	end

	local func_name = info.name or "<anonymous>"
	local src = info.short_src or "?"
	local linedef = info.linedefined or -1

	local prefix, depth = get_indent()

	if event == "return" then
		add_line(string.format("%sRET  %s (%s:%d)", prefix, func_name, src, linedef))
		if depth == 0 then
			save_trace_to_file()
		end
		_state.in_hook = false
		return
	end

	if depth == 0 then
		_state.root_func_name = func_name
		_state.root_src = src
	end

	local args = {}
	local nparams = info.nparams or 0
	if nparams > MAX_ARGS then
		nparams = MAX_ARGS
	end

	for i = 1, nparams do
		local name, value = dbg.getlocal(2, i)
		if not name then
			break
		end
		args[#args + 1] = string.format("%s=%s", name, safe_tostring(value))
	end

	if info.isvararg and #args < MAX_ARGS then
		local i = 1
		while #args < MAX_ARGS do
			local name, value = dbg.getlocal(2, -i)
			if not name then
				break
			end
			args[#args + 1] = string.format("...%d=%s", i, safe_tostring(value))
			i = i + 1
		end
	end

	add_line(string.format("%sCALL %s (%s:%d)  args: (%s)", prefix, func_name, src, linedef, table.concat(args, ", ")))

	_state.in_hook = false
end

-- ============================================================
-- PUBLIC API
-- ============================================================

function TraceCore.start(options)
	options = options or {}

	if _state.is_enabled then
		return true, "Already enabled"
	end

	if not dbg or not dbg.sethook then
		return false, "debug.sethook not available"
	end

	-- Get this script's source to skip it
	local info = dbg.getinfo(1, "S")
	_state.this_src = info and info.short_src or nil

	-- Generate new session ID (no need to delete old traces)
	_state.session_id = generate_session_id()

	-- Ensure base traces folder exists (don't delete it)
	os.execute('mkdir "' .. BASE_PATH .. '" 2>nul')

	-- Open session-specific index file
	local index_filename = BASE_PATH .. "index_session_" .. _state.session_id .. ".log"
	_state.index_file = io.open(index_filename, "wb")
	if _state.index_file then
		_state.index_file:write("-- SESSION STARTED at " .. os.date("%Y-%m-%d %H:%M:%S") .. " --\n")
		_state.index_file:write("-- Session ID: " .. _state.session_id .. " --\n")
		_state.index_file:write("-- Format: " .. OUTPUT_FORMAT .. " --\n\n")
		_state.index_file:flush()
	end

	_state.call_sequence = 0
	_state.file_count = 0
	_state.created_folders = {}

	-- Set hook
	dbg.sethook(hook, "cr")
	_state.is_enabled = true

	return true, "Session: " .. _state.session_id
end

function TraceCore.stop()
	if not _state.is_enabled then
		return true, "Not enabled"
	end

	-- Remove hook
	if dbg and dbg.sethook then
		dbg.sethook(nil)
	end

	-- Save any pending trace
	if _state.trace_count > 0 then
		save_trace_to_file()
	end

	-- Close index file
	if _state.index_file then
		_state.index_file:write("\n-- SESSION ENDED at " .. os.date("%Y-%m-%d %H:%M:%S") .. " --\n")
		_state.index_file:write(
			"-- Total calls: " .. _state.call_sequence .. ", Files: " .. _state.file_count .. " --\n\n"
		)
		_state.index_file:close()
		_state.index_file = nil
	end

	_state.is_enabled = false

	return true, string.format("Stopped. %d files saved.", _state.file_count)
end

function TraceCore.is_enabled()
	return _state.is_enabled
end

function TraceCore.get_output_path()
	return BASE_PATH
end

function TraceCore.get_stats()
	return {
		is_enabled = _state.is_enabled,
		call_sequence = _state.call_sequence,
		file_count = _state.file_count,
		format = OUTPUT_FORMAT,
	}
end

-- Set output format ("readable" or "json")
function TraceCore.set_format(format)
	if format == "json" or format == "readable" then
		OUTPUT_FORMAT = format
		return true, "Format set to: " .. format
	end
	return false, "Invalid format. Use 'readable' or 'json'"
end

-- Get current format
function TraceCore.get_format()
	return OUTPUT_FORMAT
end

-- Register global stop function for backwards compatibility
Reg.set("stop_trace_hook", TraceCore.stop)

return TraceCore
