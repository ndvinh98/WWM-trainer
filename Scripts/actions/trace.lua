--[[
    Trace - Call Tracing Action Module

    Provides debug.sethook-based call tracing with:
    - Session-based trace output (JSON or readable compact tree)
    - Anchor-based slicing around key events
    - Configurable source/function skip lists

    UI: Debug tab → "Trace Call" toggle (on/off)
    Prerequisites: Bootstrap must be loaded first
]]

local ActionBase = _G.Reg.lib("ActionBase")
local Constants = _G.Reg.lib("Constants")

local Trace = ActionBase:extend("actions.trace")

-- ============================================================
-- CONSTANTS
-- ============================================================
local BASE_PATH = Constants and (Constants.SCRIPTS_ROOT .. "\\traces\\")
	or "C:\\temp\\Where Winds Meet\\Scripts\\traces\\"

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

local ANCHOR_PATTERNS = {
	'event="e_parry"',
	'event="e_be_parry"',
	'event="e_pre_damage"',
}

local SLICE_WINDOW = 120
local SAVE_ACTUAL_LOGS = false
local MAX_ARGS = 10

local dbg = debug

-- ============================================================
-- STATE
-- ============================================================

function Trace:define_state()
	return {
		persistent = {
			output_format = "json",
			log_enabled = true,
		},
		transient = {
			is_tracing = false,
			call_sequence = 0,
			file_count = 0,
			current_trace = {},
			trace_count = 0,
			root_func_name = nil,
			root_src = nil,
			this_src = nil,
			in_hook = false,
			session_id = nil,
			completed_traces = {}, -- buffered traces, flushed on stop()
		},
	}
end

-- ============================================================
-- HOOKS
-- ============================================================

function Trace:define_hooks()
	return {}
end

-- ============================================================
-- LIFECYCLE
-- ============================================================

function Trace:on_disable()
	if self.state.is_tracing then
		self:stop()
	end
end

-- ============================================================
-- PRIVATE HELPERS
-- ============================================================

function Trace:_get_timestamp()
	local t = os.date("*t")
	local ms = math.floor((os.clock() % 1) * 1000)
	return string.format("%02d%02d%02d_%03d", t.hour, t.min, t.sec, ms)
end

function Trace:_extract_filename(src)
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

function Trace:_sanitize_name(name)
	if not name or name == "" or name == "<anonymous>" then
		return "anon"
	end
	name = name:gsub("[^%w_]", "_")
	if #name > 20 then
		name = name:sub(1, 20)
	end
	return name
end

function Trace:_basename(p)
	if not p or p == "" then
		return "?"
	end
	p = p:gsub(":%d+$", "")
	return p:match("([^/\\]+)$") or p
end

function Trace:_safe_tostring(v)
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

function Trace:_json_escape(s)
	if type(s) ~= "string" then
		return tostring(s)
	end
	return s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
end

function Trace:_generate_session_id()
	local t = os.date("*t")
	return string.format("%04d%02d%02d_%02d%02d%02d", t.year, t.month, t.day, t.hour, t.min, t.sec)
end

function Trace:_ensure_folder(src)
	local s = self.state
	if not src or src == "?" then
		local session_path = BASE_PATH .. "session_" .. (s.session_id or "unknown") .. "\\"
		if not s.created_folders[session_path] then
			os.execute('mkdir "' .. session_path .. '" 2>nul')
			s.created_folders[session_path] = true
		end
		return session_path
	end
	local dir = src:match("(.+)[/\\][^/\\]+$") or ""
	if dir == "" then
		local session_path = BASE_PATH .. "session_" .. (s.session_id or "unknown") .. "\\"
		if not s.created_folders[session_path] then
			os.execute('mkdir "' .. session_path .. '" 2>nul')
			s.created_folders[session_path] = true
		end
		return session_path
	end
	dir = dir:gsub("/", "\\")
	local full_path = BASE_PATH .. dir .. "\\session_" .. (s.session_id or "unknown") .. "\\"
	if not s.created_folders[full_path] then
		os.execute('mkdir "' .. full_path .. '" 2>nul')
		s.created_folders[full_path] = true
	end
	return full_path
end

function Trace:_add_line(line)
	local s = self.state
	s.trace_count = s.trace_count + 1
	s.current_trace[s.trace_count] = line
end

-- ============================================================
-- TRACE LINE PARSING
-- ============================================================

function Trace:_count_leading_spaces(s)
	local a = s:match("^(%s*)")
	return a and #a or 0
end

function Trace:_extract_call_fields(line)
	local func, src, lno = line:match("^%s*CALL%s+([^%s]+)%s+%((.-):(%-?%d+)%)")
	if not func then
		func, src, lno = line:match("^%s*CALL%s+(.+)%s+%((.-):(%-?%d+)%)")
	end
	local args = line:match("args:%s*%((.*)%)%s*$")
	return func, src, tonumber(lno), args
end

function Trace:_line_has_anchor(line)
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

-- ============================================================
-- TREE BUILDERS
-- ============================================================

function Trace:_build_compact_tree(lines)
	local out = {}
	local last_depth = -1
	local first_srcfile = nil

	for i = 1, #lines do
		local line = lines[i]
		if line:find("CALL ", 1, true) == 1 or line:match("^%s*CALL%s") then
			local spaces = self:_count_leading_spaces(line)
			local depth = math.floor(spaces / 2)
			local func, src, lno, args = self:_extract_call_fields(line)
			if func and src then
				local srcfile = self:_basename(src)
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

function Trace:_build_json_tree(lines)
	local nodes = {}
	local stack = {}

	for i = 1, #lines do
		local line = lines[i]
		if line:find("CALL ", 1, true) or line:match("^%s*CALL%s") then
			local spaces = self:_count_leading_spaces(line)
			local depth = math.floor(spaces / 2)
			local func, src, lno, args = self:_extract_call_fields(line)

			if func and src then
				local node = {
					func = func,
					src = self:_basename(src),
					line = lno or 0,
					args = args or "",
					children = {},
				}

				while #stack > 0 and stack[#stack].depth >= depth do
					table.remove(stack)
				end

				if #stack > 0 then
					local parent = stack[#stack].node
					parent.children[#parent.children + 1] = node
				else
					nodes[#nodes + 1] = node
				end

				stack[#stack + 1] = { depth = depth, node = node }
			end
		end

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

function Trace:_node_to_json(node, indent)
	indent = indent or 0
	local sp = string.rep("  ", indent)
	local sp2 = string.rep("  ", indent + 1)
	local parts = {}

	parts[#parts + 1] = sp .. "{"
	parts[#parts + 1] = sp2 .. '"func": "' .. self:_json_escape(node.func) .. '",'
	parts[#parts + 1] = sp2 .. '"src": "' .. self:_json_escape(node.src) .. '",'
	parts[#parts + 1] = sp2 .. '"line": ' .. tostring(node.line) .. ","
	parts[#parts + 1] = sp2 .. '"args": "' .. self:_json_escape(node.args) .. '",'

	if node.children and #node.children > 0 then
		parts[#parts + 1] = sp2 .. '"children": ['
		for i, child in ipairs(node.children) do
			local child_json = self:_node_to_json(child, indent + 2)
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

function Trace:_build_json_output(lines, root_func, root_src, seq)
	local nodes = self:_build_json_tree(lines)
	local parts = {}

	parts[#parts + 1] = "{"
	parts[#parts + 1] = '  "_trace": true,'
	parts[#parts + 1] = '  "_seq": ' .. tostring(seq) .. ","
	parts[#parts + 1] = '  "_root_func": "' .. self:_json_escape(root_func or "unknown") .. '",'
	parts[#parts + 1] = '  "_root_src": "' .. self:_json_escape(root_src or "unknown") .. '",'
	parts[#parts + 1] = '  "_time": "' .. os.date("%Y-%m-%d %H:%M:%S") .. '",'
	parts[#parts + 1] = '  "calls": ['

	for i, node in ipairs(nodes) do
		local node_json = self:_node_to_json(node, 2)
		if i < #nodes then
			node_json = node_json .. ","
		end
		parts[#parts + 1] = node_json
	end

	parts[#parts + 1] = "  ]"
	parts[#parts + 1] = "}"

	return table.concat(parts, "\n")
end

function Trace:_build_slices(lines)
	local out = {}
	local seen = {}
	for i = 1, #lines do
		if self:_line_has_anchor(lines[i]) then
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

-- ============================================================
-- IN-MEMORY BUFFERING (zero I/O during tracing)
-- ============================================================

--- Buffer completed trace into memory. Called from the debug hook
--- on root-level return. No file I/O happens here.
function Trace:_buffer_current_trace()
	local s = self.state
	if s.trace_count == 0 then
		return
	end

	s.call_sequence = s.call_sequence + 1
	s.file_count = s.file_count + 1

	-- Snapshot the trace data into the buffer
	s.completed_traces[#s.completed_traces + 1] = {
		lines = s.current_trace,
		root_func_name = s.root_func_name,
		root_src = s.root_src,
		seq = s.call_sequence,
		timestamp = self:_get_timestamp(),
	}

	-- Reset for next trace (allocate new table, don't clear)
	s.current_trace = {}
	s.trace_count = 0
	s.root_func_name = nil
	s.root_src = nil
end

-- ============================================================
-- FILE I/O (called only from stop())
-- ============================================================

--- Write a single buffered trace record to disk.
function Trace:_write_trace_record(record)
	local s = self.state
	local folder_path = self:_ensure_folder(record.root_src)
	local src_name = self:_extract_filename(record.root_src)
	local func_name = self:_sanitize_name(record.root_func_name)
	local base_filename = string.format("%s%s_%s_%s", folder_path, src_name, func_name, record.timestamp)

	-- Save raw logs if enabled
	if SAVE_ACTUAL_LOGS then
		local f = io.open(base_filename .. ".log", "wb")
		if f then
			f:write("-- Sequence: " .. record.seq .. "\n")
			f:write("-- Root: " .. (record.root_func_name or "unknown") .. "\n")
			f:write("-- Source: " .. (record.root_src or "unknown") .. "\n")
			f:write("-- Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n")
			f:write(table.concat(record.lines, "\n"))
			f:write("\n")
			f:close()
		end
	end

	-- Output compact tree OR JSON based on format
	if s.output_format == "json" then
		local json_path = base_filename .. ".json"
		local jf = io.open(json_path, "wb")
		if jf then
			local json_output =
				self:_build_json_output(record.lines, record.root_func_name, record.root_src, record.seq)
			jf:write(json_output)
			jf:write("\n")
			jf:close()
		end
		return base_filename .. ".json"
	else
		local compact_path = base_filename .. "_compact.log"
		local cf = io.open(compact_path, "wb")
		if cf then
			cf:write("-- Compact call tree (CALL-only)\n")
			cf:write("-- Root: " .. (record.root_func_name or "unknown") .. "\n")
			cf:write("-- Source: " .. (record.root_src or "unknown") .. "\n")
			cf:write("-- Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n")
			cf:write(
				string.format(
					"[ROOT] %s : %s()\n",
					self:_basename(record.root_src or "?"),
					record.root_func_name or "anonymous"
				)
			)
			cf:write(table.concat(self:_build_compact_tree(record.lines), "\n"))
			cf:write("\n")
			cf:close()
		end
		return base_filename .. "_compact.log"
	end
end

--- Write anchor slices for a buffered trace record.
function Trace:_write_trace_slices(record)
	local slices = self:_build_slices(record.lines)
	if not slices then
		return
	end
	local folder_path = self:_ensure_folder(record.root_src)
	local src_name = self:_extract_filename(record.root_src)
	local func_name = self:_sanitize_name(record.root_func_name)
	local base_filename = string.format("%s%s_%s_%s", folder_path, src_name, func_name, record.timestamp)
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

--- Flush ALL buffered traces to disk. Called once from stop().
function Trace:_flush_all_to_disk()
	local s = self.state
	local traces = s.completed_traces
	if #traces == 0 then
		return
	end

	self:log(string.format("Flushing %d traces to disk...", #traces))

	-- Ensure base folder
	os.execute('mkdir "' .. BASE_PATH .. '" 2>nul')
	s.created_folders = {}

	-- Write index file
	local index_filename = BASE_PATH .. "index_session_" .. (s.session_id or "unknown") .. ".log"
	local index_file = io.open(index_filename, "wb")
	if index_file then
		index_file:write("-- SESSION STARTED at " .. os.date("%Y-%m-%d %H:%M:%S") .. " --\n")
		index_file:write("-- Session ID: " .. (s.session_id or "unknown") .. " --\n")
		index_file:write("-- Format: " .. s.output_format .. " --\n\n")
	end

	-- Write each trace record
	for i, record in ipairs(traces) do
		local ok, result = pcall(function()
			local filepath = self:_write_trace_record(record)
			self:_write_trace_slices(record)

			-- Write index entry
			if index_file and filepath then
				local relative_path = filepath:sub(#BASE_PATH + 1)
				index_file:write(
					string.format(
						"%05d | %s | %s | %s\n",
						record.seq,
						record.root_func_name or "?",
						record.root_src or "?",
						relative_path
					)
				)
			end
		end)
		if not ok then
			self:log("[Trace] Error writing trace " .. i .. ": " .. tostring(result))
		end
	end

	-- Close index
	if index_file then
		index_file:write("\n-- SESSION ENDED at " .. os.date("%Y-%m-%d %H:%M:%S") .. " --\n")
		index_file:write("-- Total calls: " .. s.call_sequence .. ", Files: " .. s.file_count .. " --\n\n")
		index_file:close()
	end

	self:log(string.format("Flush complete. %d files written.", s.file_count))

	-- Clear buffer
	s.completed_traces = {}
end

-- ============================================================
-- DEBUG HOOK
-- ============================================================

function Trace:_should_skip(info)
	local src = info.short_src or ""
	local s = self.state

	if s.this_src and src == s.this_src then
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

function Trace:_get_indent()
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

function Trace:_create_hook()
	local trace_self = self
	return function(event, line)
		local s = trace_self.state
		if s.in_hook then
			return
		end
		if event ~= "call" and event ~= "tail call" and event ~= "return" then
			return
		end

		s.in_hook = true

		local info
		if event == "return" then
			info = dbg.getinfo(2, "nS")
		else
			info = dbg.getinfo(2, "nSlu")
		end

		if not info or info.what ~= "Lua" or trace_self:_should_skip(info) then
			s.in_hook = false
			return
		end

		local func_name = info.name or "<anonymous>"
		local src = info.short_src or "?"
		local linedef = info.linedefined or -1

		local prefix, depth = trace_self:_get_indent()

		if event == "return" then
			trace_self:_add_line(string.format("%sRET  %s (%s:%d)", prefix, func_name, src, linedef))
			if depth == 0 then
				trace_self:_buffer_current_trace()
			end
			s.in_hook = false
			return
		end

		if depth == 0 then
			s.root_func_name = func_name
			s.root_src = src
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
			args[#args + 1] = string.format("%s=%s", name, trace_self:_safe_tostring(value))
		end

		if info.isvararg and #args < MAX_ARGS then
			local i = 1
			while #args < MAX_ARGS do
				local name, value = dbg.getlocal(2, -i)
				if not name then
					break
				end
				args[#args + 1] = string.format("...%d=%s", i, trace_self:_safe_tostring(value))
				i = i + 1
			end
		end

		trace_self:_add_line(
			string.format("%sCALL %s (%s:%d)  args: (%s)", prefix, func_name, src, linedef, table.concat(args, ", "))
		)

		s.in_hook = false
	end
end

-- ============================================================
-- PUBLIC API
-- ============================================================

function Trace:start(options)
	self:log("Starting trace...")
	local s = self.state
	options = options or {}

	if s.is_tracing then
		self:log("Already tracing")
		return true, "Already enabled"
	end

	if not dbg or not dbg.sethook then
		self:log("debug.sethook not available")
		return false, "debug.sethook not available"
	end

	-- Get this script's source to skip it
	local info = dbg.getinfo(1, "S")
	s.this_src = info and info.short_src or nil

	-- Generate new session ID
	s.session_id = self:_generate_session_id()

	-- Reset counters and buffer (no I/O here)
	s.call_sequence = 0
	s.file_count = 0
	s.completed_traces = {}
	s.created_folders = {}

	-- Set hook
	dbg.sethook(self:_create_hook(), "cr")
	s.is_tracing = true

	self:log("Started - session: " .. s.session_id .. " (buffered, flush on stop)")
	return true, "Session: " .. s.session_id
end

function Trace:stop()
	self:log("Stopping trace...")
	local s = self.state

	if not s.is_tracing then
		self:log("Not tracing")
		return true, "Not enabled"
	end

	-- Remove hook FIRST — no more callbacks after this
	if dbg and dbg.sethook then
		dbg.sethook(nil)
	end

	-- Buffer any pending trace
	if s.trace_count > 0 then
		self:_buffer_current_trace()
	end

	s.is_tracing = false

	-- NOW flush everything to disk (all I/O happens here)
	self:_flush_all_to_disk()

	local msg = string.format("Stopped. %d files saved.", s.file_count)
	self:log(msg)
	return true, msg
end

-- Aliases for backward compat with tests and other callers
function Trace:start_trace(options)
	return self:start(options)
end

function Trace:stop_trace()
	return self:stop()
end

function Trace:toggle(enabled)
	if enabled then
		return self:start()
	else
		return self:stop()
	end
end

function Trace:is_tracing()
	return self.state.is_tracing
end

function Trace:get_output_path()
	return BASE_PATH
end

function Trace:get_stats()
	local s = self.state
	return {
		is_enabled = s.is_tracing,
		call_sequence = s.call_sequence,
		file_count = s.file_count,
		format = s.output_format,
	}
end

function Trace:set_format(format)
	if format == "json" or format == "readable" then
		self.state.output_format = format
		local msg = "Format set to: " .. format
		self:log(msg)
		return true, msg
	end
	return false, "Invalid format. Use 'readable' or 'json'"
end

function Trace:get_format()
	return self.state.output_format
end

-- Emergency stop reference (external callers can stop tracing without module ref)
local TRACE_STATE = _G.Reg.state("actions.trace")
TRACE_STATE.stop = function()
	local mod = _G.Reg.module("actions.trace")
	if mod then
		return mod:stop()
	end
end

-- Singleton guard: if an instance is already registered (e.g. actively tracing),
-- return it instead of creating a new one that would orphan the debug hook.
local existing = _G.Reg.module("actions.trace")
if existing then
	return existing
end

return Trace:new()
