--[[
    DumpCore - Core Module Dumping Utilities

    Provides:
    - Encoder: Value encoding with cycle detection
    - StreamingEncoder: Memory-efficient file streaming
    - ReadableFormatter: Human-readable documentation format
    - ModuleDumper: File/folder utilities
    - DumpAllModules: Dump all loaded modules
    - DumpModule: Dump single module
    - DumpGM: Dump GM menus

    This is the core implementation. Use Scripts/actions/dump.lua for the public API.
]]
-- Reference libs via Reg (loaded once by bootstrap)
local Reg = _G.Reg
local Constants = Reg.get("Constants")
local Logger = Reg.get("Logger")
local Serialize = Reg.lib("Serialize")

local DumpCore = {}

-- ============================================================
-- SHARED CONSTANTS
-- ============================================================
local LUA_RESERVED = {
    ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
    ["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
    ["function"] = true, ["goto"] = true, ["if"] = true, ["in"] = true,
    ["local"] = true, ["nil"] = true, ["not"] = true, ["or"] = true,
    ["repeat"] = true, ["return"] = true, ["then"] = true, ["true"] = true,
    ["until"] = true, ["while"] = true
}

local function is_valid_ident(s)
    return type(s) == "string" and s:match("^[A-Za-z_][A-Za-z0-9_]*$") and not LUA_RESERVED[s]
end

-- Check if a value can be iterated with pairs() (table, class, userdata with __pairs)
local function is_iterable(v)
    local t = type(v)
    if t == "table" then return true end
    if t == "userdata" or t == "class" then
        local ok = pcall(pairs, v)
        return ok
    end
    return false
end

-- ============================================================
-- GLOBAL SESSION CACHE - Prevents re-traversing shared tables
-- ============================================================
-- This cache persists across dump_module calls during a dump session.
-- Large tables (>100 keys) that have been fully traversed are cached.
-- Subsequent encounters return a reference marker instead of re-traversing.

-- Session cache name (Reg handles prefix)
local SESSION_CACHE_NAME = "DUMP_SESSION_CACHE"

-- Initialize a new dump session (call before batch dump)
function DumpCore.start_session()
    Reg.set(
        SESSION_CACHE_NAME,
        {
            visited = setmetatable({}, {__mode = "k"}), -- Weak keys for GC
            stats = {tables_cached = 0, cache_hits = 0}
        }
    )
end

-- End dump session (clears cache for GC)
function DumpCore.end_session()
    local cache = Reg.get(SESSION_CACHE_NAME)
    if cache then
        local stats = cache.stats
        if Logger and Logger.log then
            Logger.log(
                string.format(
                    "[DumpCore] Session ended: %d tables cached, %d cache hits",
                    stats.tables_cached,
                    stats.cache_hits
                )
            )
        end
    end
    Reg.del(SESSION_CACHE_NAME)
end

-- Get current session cache (or nil if no session)
function DumpCore.get_session_cache()
    return Reg.get(SESSION_CACHE_NAME)
end

-- ============================================================
-- CONFIGURATION
-- ============================================================
local BASE_DIR = Constants and Constants.LUA_DEBUGGING_ROOT or "C:\\temp\\Where Winds Meet\\Scripts\\dumped"

-- ============================================================
-- MODULE DUMPER UTILITIES - File/folder helpers
-- ============================================================
local ModuleDumper = {}
ModuleDumper.BASE_DIR = BASE_DIR

-- ============================================================
-- SKIP PREFIXES - Modules to skip when dumping (by source path)
-- ============================================================
local SKIP_SRC_PREFIXES = {
    -- "engine/Lib/",
    -- "hexm/client/trace.lua",
    -- "hexm/client/logger.lua",
    -- "hexm/common/strict.lua",
    -- "hexm/common/datetime_manager.lua",
    --"hexm/common/data/dir_object.lua",
    -- "hexm/common/data/bin_data_object.lua"
    -- "engine/Lib/partial.lua",
    -- "hexm/client/entities/local/component/anim.lua",
    -- "hexm/client/manager/task_queue/",
}

-- ============================================================
-- SKIP MODULE NAMES - Modules to skip by name (circular/massive)
-- ============================================================
-- _G: Global table, contains references to everything, self-referential
-- package: Contains package.loaded which references ALL loaded modules
local SKIP_MODULE_NAMES = {
    ["_G"] = true,
    ["package"] = true,
    -- ["hexm.common.data.dir_object"] = true,
    -- ["hexm.common.data.bin_data_object"] = true
}

-- ============================================================
-- UNLUAC DECOMPILATION - Bytecode → Source via unluac.jar
-- ============================================================
local UNLUAC_JAR = "C:\\temp\\Where Winds Meet\\Scripts\\lib\\unluac.jar"
local UNLUAC_TEMP = BASE_DIR .. "\\_temp_bytecode.luac"
local UNLUAC_OUT = BASE_DIR .. "\\_temp_decompiled.lua"
local decompile_cache = setmetatable({}, {__mode = "k"})

-- ============================================================
-- BYTECODE SAVE MODE (default) - Save bytecodes to disk, return placeholders
-- Decompilation happens offline via Scripts/tools/merge_decompiled.py
-- Pass enable_decompile=true to use JVM inline (slow, single-module use)
-- ============================================================
local bytecode_counter = 0
local bytecode_manifest = {}
local BYTECODE_DIR = nil

-- Initialize bytecode saving for a dump session
function DumpCore.start_bytecode_session(output_dir)
    bytecode_counter = 0
    bytecode_manifest = {}
    BYTECODE_DIR = (output_dir or BASE_DIR) .. "\\\\bytecodes"
    ModuleDumper.mkdir(BYTECODE_DIR)
end

-- Finalize bytecode session - write manifest
function DumpCore.end_bytecode_session()
    if not BYTECODE_DIR then return nil end

    local manifest_path = BYTECODE_DIR .. "\\\\_manifest.jsonl"
    local f = io.open(manifest_path, "w")
    if f then
        for _, entry in ipairs(bytecode_manifest) do
            f:write(entry .. "\n")
        end
        f:close()
    end

    local stats = {
        total = bytecode_counter,
        manifest = manifest_path,
        bytecode_dir = BYTECODE_DIR
    }

    if Logger and Logger.log then
        Logger.log(string.format(
            "[Decompile] Bytecode session ended: %d functions saved, manifest: %s",
            bytecode_counter, manifest_path
        ))
    end

    bytecode_counter = 0
    bytecode_manifest = {}

    return stats
end

-- Save bytecode to disk and return a placeholder string
local function save_bytecode_placeholder(func, bytecode, dbg_info)
    bytecode_counter = bytecode_counter + 1

    -- Build source-based name matching placeholder format for easy merge
    local source = (dbg_info.source or "?"):gsub('^@', ''):gsub('\\', '/')
    local line_start = dbg_info.linedefined or 0
    local line_end = dbg_info.lastlinedefined or 0
    local name_id = string.format("%s:%d-%d", source, line_start, line_end)

    -- Filesystem-safe filename using __DECOMPILE__ prefix to match placeholder
    local safe_name = "__DECOMPILE__" .. name_id:gsub('[/\\:*?"<>|]', '_') .. "__"

    -- Write bytecode file
    local bc_path = BYTECODE_DIR .. "\\\\" .. safe_name .. ".luac"
    local f = io.open(bc_path, "wb")
    if not f then
        decompile_cache[func] = false
        return nil
    end
    f:write(bytecode)
    f:close()

    -- Build manifest entry (manual JSON - no dependency needed)
    local source_escaped = source:gsub('\\', '\\\\'):gsub('"', '\\"')
    local entry = string.format(
        '{"id":"%s","source":"%s","lines":"%d-%d","file":"%s.luac"}',
        safe_name, source_escaped, line_start, line_end, safe_name
    )
    bytecode_manifest[#bytecode_manifest + 1] = entry

    -- Return placeholder matching comment format: -- __DECOMPILE__source:lines__
    local placeholder = "-- __DECOMPILE__" .. name_id .. "__"
    decompile_cache[func] = placeholder
    return placeholder
end

-- Decompile via JVM (original slow path, opt-in only)
local function decompile_via_jvm(func, bytecode)
    -- Write bytecode to temp file
    local f = io.open(UNLUAC_TEMP, "wb")
    if not f then
        if Logger and Logger.log then
            Logger.log("[Decompile] Failed to open temp file: " .. UNLUAC_TEMP)
        end
        decompile_cache[func] = false
        return nil
    end
    f:write(bytecode)
    f:close()

    -- Run unluac: redirect stdout to file to avoid visible cmd window
    local cmd = 'java -jar "' .. UNLUAC_JAR .. '" --wwm "' .. UNLUAC_TEMP .. '" > "' .. UNLUAC_OUT .. '" 2>nul'
    local exec_ok = os.execute(cmd)
    if not exec_ok and exec_ok ~= true and exec_ok ~= 0 then
        if Logger and Logger.log then
            Logger.log("[Decompile] os.execute failed for unluac")
        end
        pcall(os.remove, UNLUAC_TEMP)
        pcall(os.remove, UNLUAC_OUT)
        decompile_cache[func] = false
        return nil
    end

    -- Read decompiled output from file
    local out_f = io.open(UNLUAC_OUT, "r")
    if not out_f then
        if Logger and Logger.log then
            Logger.log("[Decompile] Failed to read output file: " .. UNLUAC_OUT)
        end
        pcall(os.remove, UNLUAC_TEMP)
        pcall(os.remove, UNLUAC_OUT)
        decompile_cache[func] = false
        return nil
    end

    local output = out_f:read("*a")
    out_f:close()

    -- Cleanup temp files
    pcall(os.remove, UNLUAC_TEMP)
    pcall(os.remove, UNLUAC_OUT)

    if not output or output == "" then
        if Logger and Logger.log then
            Logger.log("[Decompile] unluac returned empty output")
        end
        decompile_cache[func] = false
        return nil
    end

    -- Trim trailing whitespace
    output = output:gsub("%s+$", "")
    decompile_cache[func] = output
    return output
end

-- Main entry point: save bytecode placeholder (default) or decompile via JVM (opt-in)
function DumpCore.decompile_function(func, enable_decompile)
    -- Check cache first (false = already tried and failed)
    if decompile_cache[func] ~= nil then
        local cached = decompile_cache[func]
        return cached ~= false and cached or nil
    end

    -- Only Lua functions can be string.dump'd
    local info_ok, dbg_info = pcall(debug.getinfo, func, "S")
    if not info_ok or not dbg_info or dbg_info.what == "C" then
        decompile_cache[func] = false
        return nil
    end

    -- Get bytecode
    local dump_ok, bytecode = pcall(string.dump, func)
    if not dump_ok or not bytecode then
        if Logger and Logger.log then
            Logger.log("[Decompile] string.dump failed: " .. tostring(bytecode))
        end
        decompile_cache[func] = false
        return nil
    end

    -- Dispatch: JVM decompile (opt-in) or bytecode save (default)
    if enable_decompile then
        return decompile_via_jvm(func, bytecode)
    end

    -- Default: save bytecode, return placeholder
    if BYTECODE_DIR then
        return save_bytecode_placeholder(func, bytecode, dbg_info)
    end

    -- No bytecode session active - return comment placeholder with source info
    local source = (dbg_info.source or "?"):gsub('\\', '/')
    local line_start = dbg_info.linedefined or 0
    local line_end = dbg_info.lastlinedefined or 0
    local placeholder = string.format("-- __DECOMPILE__%s:%d-%d__", source, line_start, line_end)
    decompile_cache[func] = placeholder
    return placeholder
end

function ModuleDumper.path_exists(path)
    local ok, err, code = os.rename(path, path)
    if ok then
        return true
    end
    if code == 13 then
        return true
    end
    return false
end

function ModuleDumper.mkdir(path)
    if ModuleDumper.path_exists(path) then
        return true
    end
    local cmd = 'mkdir "' .. path .. '" 2>nul'
    return os.execute(cmd) == 0 or os.execute(cmd) == true
end

function ModuleDumper.sanitize_name(name)
    if type(name) ~= "string" then
        return tostring(name)
    end
    return name:gsub("[^%w%._-]", "_")
end

function ModuleDumper.describe_value(v, depth)
    local t = type(v)
    if t == "function" then
        return "function"
    elseif is_iterable(v) then
        local count = 0
        pcall(
            function()
                for _ in pairs(v) do
                    count = count + 1
                end
            end
        )
        return string.format("%s (%d items)", t, count)
    elseif t == "string" then
        if #v > 50 then
            return string.format('"%s..." (%d chars)', v:sub(1, 50):gsub("\n", "\\n"), #v)
        else
            return string.format('"%s"', v:gsub("\n", "\\n"))
        end
    elseif t == "number" or t == "boolean" then
        return tostring(v)
    else
        return t
    end
end

DumpCore.ModuleDumper = ModuleDumper

-- ============================================================
-- ENCODER - DumpGM-style encoding logic
-- ============================================================
local Encoder = {}

function Encoder.init(config)
    config = config or {}
    local self = {
        DUMP_DEPTH = config.depth or 12,
        PRETTY = config.pretty ~= false,
        INCLUDE_SOURCE = config.include_source ~= false
    }

    -- Locaux for perf
    local _G = _G
    local rawget = rawget
    local dbg = rawget(_G, "debug")
    self.getmt = (dbg and dbg.getmetatable) or getmetatable
    self.type = type
    self.tostring = tostring
    self.pcall = pcall
    self.rawget = rawget
    self.math = math
    self.next = next
    self.ipairs = ipairs

    -- Python-like libs
    self.listlib = rawget(_G, "listlib")
    self.dictlib = rawget(_G, "dictlib")
    self.len_fn = rawget(_G, "len")

    -- String helpers
    self.format = string.format
    self.rep = string.rep
    self.concat = table.concat
    self.sort = table.sort
    self.q = function(s)
        return string.format("%q", s)
    end

    -- IDs for non-primitive objects
    self.OBJ_ID = setmetatable({}, {__mode = "k"})
    self.OBJ_SEQ = {table = 0, ["function"] = 0, userdata = 0, thread = 0}

    -- Tracking for cycles and deduplication
    self.VISITING = setmetatable({}, {__mode = "k"})
    self.TIDS = setmetatable({}, {__mode = "k"})
    self.ENCODED = setmetatable({}, {__mode = "k"})
    self.NEXT_TID = 0

    -- Reserved Lua keywords (shared module-level constant)
    self.RESERVED = LUA_RESERVED

    -- Keys to ignore
    self.IGNORE_KEYS =
        rawget(_G, "DUMP_IGNORE_KEYS") or
        {
            gm_command_short_cuts = true,
            gm_command_ui_components = true
        }

    -- Debug callback
    self.write_debug = config.write_debug or function()
        end

    -- Source cache
    self.source_cache = {}

    return setmetatable(self, {__index = Encoder})
end

function Encoder:uid(x)
    local id = self.OBJ_ID[x]
    if id then
        return id
    end
    local t = self.type(x)
    local n = (self.OBJ_SEQ[t] or 0) + 1
    self.OBJ_SEQ[t] = n
    id = self.format("%s%d", t:sub(1, 1):upper(), n)
    self.OBJ_ID[x] = id
    return id
end

function Encoder:safe_tostring(x)
    local t = self.type(x)
    if t == "nil" or t == "boolean" or t == "number" then
        return self.tostring(x)
    elseif t == "string" then
        return x
    end

    local mt = self.getmt and self.getmt(x) or nil
    if self.type(mt) == "table" and self.rawget(mt, "__tostring") ~= nil then
        return "<" .. t .. ":" .. self:uid(x) .. ">"
    end

    local ok_t, s = self.pcall(self.tostring, x)
    if ok_t and self.type(s) == "string" then
        return s
    end
    return "<" .. t .. ":" .. self:uid(x) .. ">"
end

function Encoder:seq_len(t)
    -- Fast path: Use # operator (works for most arrays)
    local len = #t
    if len > 0 then
        return len
    end

    -- Fallback: Manual scan for sparse arrays or edge cases
    local n = 0
    for i = 1, math.huge do
        if self.rawget(t, i) == nil then
            break
        end
        n = i
        -- Safety limit to prevent infinite loops
        if i > 1000000 then
            self.write_debug("[Encoder] WARNING: seq_len exceeded 1M elements, stopping scan")
            break
        end
    end
    return n
end

function Encoder:is_ident(s)
    return is_valid_ident(s)
end

-- Try to yield in async mode (prevents blocking game thread)
function Encoder:try_async_yield()
    if not self.async_mode then return end
    local ok, _ = pcall(function()
        if coroutine.running() then
            coroutine.yield()
        end
    end)
    -- Silently ignore yield errors in non-coroutine contexts
end

function Encoder:should_ignore_key(k)
    return self.type(k) == "string" and self.IGNORE_KEYS[k] == true
end

function Encoder:tid_for(t)
    local id = self.TIDS[t]
    if id then
        return id
    end
    self.NEXT_TID = self.NEXT_TID + 1
    self.TIDS[t] = self.NEXT_TID
    return self.NEXT_TID
end

function Encoder:cmp_keys(a, b)
    local ta, tb = self.type(a), self.type(b)
    if ta ~= tb then
        return ta < tb
    end
    if ta == "string" then
        return a < b
    end
    if ta == "number" then
        return a < b
    end
    if ta == "boolean" then
        return (a and 1 or 0) < (b and 1 or 0)
    end
    local sa = self:safe_tostring(a)
    local sb = self:safe_tostring(b)
    return sa < sb
end

function Encoder:key_repr(k)
    local kt = self.type(k)
    if kt == "string" and self:is_ident(k) then
        return k .. " = "
    elseif kt == "string" then
        return "[" .. self.q(k) .. "] = "
    elseif kt == "number" then
        if k ~= k or k == self.math.huge or k == -self.math.huge then
            return "[" .. self.q("<number>") .. "] = "
        else
            return "[" .. self.tostring(k) .. "] = "
        end
    elseif kt == "boolean" then
        return "[" .. (k and "true" or "false") .. "] = "
    else
        return "[" .. self.q("<key:" .. self:safe_tostring(k) .. ">") .. "] = "
    end
end

function Encoder:get_function_info(func)
    local info = {}
    self.pcall(
        function()
            local dbg = debug.getinfo(func, "Slu")
            if dbg then
                local params = {}
                if dbg.nparams then
                    for i = 1, dbg.nparams do
                        local name = debug.getlocal(func, i)
                        params[#params + 1] = name or ("arg" .. i)
                    end
                end
                if dbg.isvararg then
                    params[#params + 1] = "..."
                end
                info.params = "(" .. table.concat(params, ", ") .. ")"
                if dbg.source then
                    info.source = dbg.source
                end
                if dbg.linedefined and dbg.lastlinedefined then
                    info.lines = dbg.linedefined .. "-" .. dbg.lastlinedefined
                elseif dbg.linedefined then
                    info.lines = tostring(dbg.linedefined)
                end
                info.what = dbg.what or "?"
            end
        end
    )
    return info
end

-- Main encode_value function
function Encoder:encode_value(v, depth, indent)
    depth = depth or 0
    indent = indent or 0

    local sp = self.PRETTY and self.rep("  ", indent) or ""
    local nl = self.PRETTY and "\n" or ""

    local t = self.type(v)

    if t == "nil" then
        return "nil"
    elseif t == "boolean" then
        return v and "true" or "false"
    elseif t == "number" then
        if v ~= v or v == self.math.huge or v == -self.math.huge then
            return self.q("<number>")
        end
        return self.tostring(v)
    elseif t == "string" then
        return self.q(v)
    elseif t == "function" then
        local info = self:get_function_info(v)
        local params = info.params or "()"
        local source_info = info.source and info.lines and (info.source .. ":" .. info.lines) or nil

        -- Try decompilation
        local decompiled = DumpCore.decompile_function(v)

        if self.PRETTY then
            local result = "{" .. nl
            result = result .. sp .. "  __type = " .. self.q(info.what or "?") .. "," .. nl
            result = result .. sp .. "  __params = " .. self.q(params) .. "," .. nl
            if source_info then
                result = result .. sp .. "  __source = " .. self.q(source_info) .. "," .. nl
            end
            if decompiled then
                local wrapped = "function" .. params .. "\n" .. decompiled .. "\nend"
                result = result .. sp .. "  __code = " .. self.q(wrapped) .. nl
            end
            result = result .. sp .. "}"
            return result
        else
            if decompiled then
                return self.q(decompiled)
            end
            return self.q(self:safe_tostring(v))
        end
    elseif t == "thread" then
        return self.q(self:safe_tostring(v))
    elseif not is_iterable(v) then
        return self.q(self:safe_tostring(v))
    end

    -- Table / class / iterable object
    local id = self:tid_for(v)

    if self.ENCODED[v] then
        return self.q(self:safe_tostring(v))
    end

    if depth >= self.DUMP_DEPTH then
        return self.q("<truncated:T" .. id .. ">")
    end
    if self.VISITING[v] then
        return self.q("<cycle:T" .. id .. ">")
    end

    self.VISITING[v] = true

    local is_plain_table = (t == "table")
    local n = is_plain_table and self:seq_len(v) or 0
    local parts = {}

    -- Sequential part (only for plain tables; class/userdata don't support rawget)
    for i = 1, n do
        -- Yield every 100 iterations if in async mode
        if i % 100 == 0 then
            self:try_async_yield()
        end

        local ev = self:encode_value(self.rawget(v, i), depth + 1, indent + 1)
        if self.PRETTY then
            parts[#parts + 1] = self.format("%s  %s", sp, ev)
        else
            parts[#parts + 1] = ev
        end
    end

    -- Hash part - use pairs() to support class/userdata with __pairs metamethod
    local hkeys = {}
    local ok_pairs, iter, state, initial = self.pcall(pairs, v)
    if ok_pairs then
        for k, _ in iter, state, initial do
            if not (self.type(k) == "number" and k % 1 == 0 and k >= 1 and k <= n) then
                if not self:should_ignore_key(k) then
                    hkeys[#hkeys + 1] = k
                end
            end
        end
    end

    -- Enhanced progress logging for massive tables
    local total_keys = #hkeys
    if total_keys > 2000 then
        self.write_debug(string.format("[Encoder] Processing large table (T%d): %d keys...", id, total_keys))
    end
    if total_keys > 10000 then
        self.write_debug(
            string.format("[Encoder] WARNING: Very large table (T%d): %d keys - this may take a while", id, total_keys)
        )
    end

    local self_ref = self
    self.sort(
        hkeys,
        function(a, b)
            return self_ref:cmp_keys(a, b)
        end
    )

    -- Process hash keys with yielding and progress updates
    for idx, k in self.ipairs(hkeys) do
        -- Yield every 100 keys if in async mode
        if idx % 100 == 0 then
            self:try_async_yield()
        end

        -- Progress logging for very large tables
        if total_keys > 5000 and idx % 1000 == 0 then
            self.write_debug(
                string.format(
                    "[Encoder] T%d: Processing key %d/%d (%.1f%%)",
                    id,
                    idx,
                    total_keys,
                    (idx / total_keys) * 100
                )
            )
        end

        local ok_val, val = self.pcall(function() return v[k] end)
        if ok_val then
            local ev = self:encode_value(val, depth + 1, indent + 1)
            local kr = self:key_repr(k)
            if self.PRETTY then
                parts[#parts + 1] = self.format("%s  %s%s", sp, kr, ev)
            else
                parts[#parts + 1] = kr .. ev
            end
        end
    end

    -- Final progress log for large tables
    if total_keys > 2000 then
        self.write_debug(string.format("[Encoder] T%d: Completed all %d keys", id, total_keys))
    end

    self.VISITING[v] = nil
    self.ENCODED[v] = true

    if self.PRETTY then
        return "{" .. nl .. self.concat(parts, "," .. nl) .. nl .. sp .. "}"
    else
        return "{" .. self.concat(parts, ",") .. "}"
    end
end

function Encoder:encode(value)
    return self:encode_value(value, 0, 0)
end

DumpCore.Encoder = Encoder

-- ============================================================
-- READABLE FORMATTER - Human-readable documentation format
-- ============================================================
local ReadableFormatter = {}

function ReadableFormatter.init(config)
    local self = {}
    config = config or {}

    -- Config
    self.DUMP_DEPTH = config.depth or 12
    self.INCLUDE_SOURCE = config.include_source ~= false
    self.DETAILED_FUNCTIONS = config.detailed_functions or false

    -- Safe references
    self.rawget = rawget
    self.type = type
    self.tostring = tostring
    self.pcall = pcall
    self.pairs = pairs
    self.ipairs = ipairs
    self.next = next
    self.sort = table.sort
    self.concat = table.concat
    self.format = string.format
    self.rep = string.rep
    self.dbg = rawget(_G, "debug")
    self.getmt = (self.dbg and self.dbg.getmetatable) or getmetatable
    self.getinfo = self.dbg and self.dbg.getinfo

    -- Reserved Lua keywords (shared module-level constant)
    self.RESERVED = LUA_RESERVED

    -- Tracking
    self.VISITING = setmetatable({}, {__mode = "k"})
    self.ENCODED = setmetatable({}, {__mode = "k"})

    setmetatable(self, {__index = ReadableFormatter})
    return self
end

function ReadableFormatter:indent(level)
    return self.rep("  ", level)
end

-- Comparator for sorting keys: strings first alphabetically, then numbers, then others
function ReadableFormatter:sort_keys(keys)
    local self_ref = self
    self.pcall(
        function()
            self.sort(
                keys,
                function(a, b)
                    local ta, tb = self_ref.type(a), self_ref.type(b)
                    if ta ~= tb then
                        if ta == "string" then
                            return true
                        end
                        if tb == "string" then
                            return false
                        end
                        return ta < tb
                    end
                    if ta == "string" then
                        return a < b
                    end
                    if ta == "number" then
                        return a < b
                    end
                    return self_ref.tostring(a) < self_ref.tostring(b)
                end
            )
        end
    )
end

-- Convert key to valid Lua table key syntax
function ReadableFormatter:lua_key(k)
    local kt = self.type(k)
    if kt == "string" then
        -- Check if it's a valid identifier AND not a reserved keyword
        if k:match("^[A-Za-z_][A-Za-z0-9_]*$") and not self.RESERVED[k] then
            return k
        else
            return "[" .. self.format("%q", k) .. "]"
        end
    elseif kt == "number" then
        return "[" .. self.tostring(k) .. "]"
    else
        return "[" .. self.format("%q", self.tostring(k)) .. "]"
    end
end

function ReadableFormatter:safe_tostring(x)
    local t = self.type(x)
    if t == "nil" or t == "boolean" or t == "number" then
        return self.tostring(x)
    elseif t == "string" then
        return x
    end
    local ok, s = self.pcall(self.tostring, x)
    if ok and self.type(s) == "string" then
        return s
    end
    return "<" .. t .. ">"
end

function ReadableFormatter:get_type_label(v)
    local t = self.type(v)

    -- Check for class
    local str_repr = nil
    self.pcall(
        function()
            str_repr = self.tostring(v)
        end
    )

    if str_repr and self.type(str_repr) == "string" then
        if str_repr:match("^<class[ :]") or str_repr:match("^%[class ") then
            return "class"
        end
        if str_repr:match("%[%w+DataObject") or str_repr:match("%[DirObject") then
            return "instance"
        end
    end

    -- Check metatable for class indicators
    local mt = nil
    self.pcall(
        function()
            mt = self.getmt(v)
        end
    )
    if mt then
        local has_tostring = false
        self.pcall(
            function()
                has_tostring = self.rawget(mt, "__tostring") ~= nil
            end
        )
        if has_tostring then
            return "instance"
        end
    end

    if t == "table" then
        return "table"
    end
    if t == "class" then
        return "class"
    end
    return t
end

function ReadableFormatter:get_metatable_info(v)
    local keys = {}
    local mt = nil
    self.pcall(
        function()
            mt = self.getmt(v)
        end
    )

    if not mt or self.type(mt) ~= "table" then
        return keys
    end

    -- Collect all keys from metatable
    self.pcall(
        function()
            for k, _ in self.pairs(mt) do
                if self.type(k) == "string" then
                    keys[#keys + 1] = k
                end
            end
        end
    )
    self.pcall(
        function()
            self.sort(keys)
        end
    )

    return keys
end

-- Format metatable as simple key list
function ReadableFormatter:format_metatable(v, indent_level)
    indent_level = indent_level or 0
    local ind = self:indent(indent_level)

    local keys = self:get_metatable_info(v)
    if #keys == 0 then
        return {}
    end

    return {ind .. "-- __mt: [" .. self.concat(keys, ", ") .. "]"}
end

function ReadableFormatter:get_function_info(func)
    local info = {params = "()", source = nil, lines = nil, what = "?"}

    if not self.getinfo then
        return info
    end

    self.pcall(
        function()
            local dbg_info = self.getinfo(func, "Slu")
            if dbg_info then
                info.what = dbg_info.what or "?"
                info.source = dbg_info.source or dbg_info.short_src

                if dbg_info.linedefined and dbg_info.lastlinedefined then
                    if dbg_info.linedefined > 0 then
                        info.lines = dbg_info.linedefined .. "-" .. dbg_info.lastlinedefined
                    end
                end

                -- Build params with actual names
                local params = {}
                local nparams = dbg_info.nparams or 0
                for i = 1, nparams do
                    local name = debug.getlocal(func, i)
                    params[i] = name or ("arg" .. i)
                end
                if dbg_info.isvararg then
                    params[#params + 1] = "..."
                end
                info.params = "(" .. self.concat(params, ", ") .. ")"
            end
        end
    )

    return info
end

-- Returns: value_str, comment_str (comment may be nil)
function ReadableFormatter:format_function(func)
    local info = self:get_function_info(func)
    local comment = nil

    if self.INCLUDE_SOURCE and info.lines then
        comment = "@" .. info.lines
    elseif info.what == "C" then
        comment = "[C]"
    end

    -- Try decompilation
    local decompiled = DumpCore.decompile_function(func)
    if decompiled then
        -- Wrap in function(params) ... end so output is valid Lua
        local wrapped = "function" .. info.params .. "\n" .. decompiled .. "\nend"
        return wrapped, comment
    end

    local value = "function" .. info.params .. " end"
    return value, comment
end

function ReadableFormatter:format_function_detailed(func, indent_level)
    -- Now just uses the same compact format as format_function
    return self:format_function(func)
end

-- Helper to format a line with value, optional comma, and optional comment
function ReadableFormatter:format_line(indent, key, value, comment, add_comma)
    local line = indent
    if key then
        line = line .. key .. " = "
    end
    line = line .. value
    if add_comma then
        line = line .. ","
    end
    if comment then
        line = line .. "  -- " .. comment
    end
    return line
end

function ReadableFormatter:format_value(v, level)
    level = level or 0
    local t = self.type(v)

    if t == "nil" then
        return "nil", nil
    elseif t == "boolean" then
        return self.tostring(v), nil
    elseif t == "number" then
        return self.tostring(v), nil
    elseif t == "string" then
        -- Use %q for proper Lua string escaping
        return self.format("%q", v), nil
    elseif t == "function" then
        if self.DETAILED_FUNCTIONS then
            return self:format_function_detailed(v, level)
        else
            return self:format_function(v)
        end
    elseif t == "userdata" then
        -- Try to treat userdata as table (some engines allow this)
        return nil, nil -- recurse
    end

    -- If it has a __tostring metatable, it might be an instance we want to expand
    local mt = self.getmt(v)
    if mt and self.rawget(mt, "__tostring") then
        return nil, nil -- recurse
    end

    return nil, nil -- Indicates needs recursive handling
end

function ReadableFormatter:format_object(v, level, key_name)
    level = level or 0
    local ind = self:indent(level)
    local lines = {}

    -- Check for already visited (cycles)
    if self.VISITING[v] then
        local cycle_str = "nil --[[<cycle>]]"
        if key_name then
            return ind .. self:lua_key(key_name) .. " = " .. cycle_str .. ","
        end
        return ind .. cycle_str
    end

    -- Check depth limit
    if level >= self.DUMP_DEPTH then
        local trunc_str = "nil --[[<truncated>]]"
        if key_name then
            return ind .. self:lua_key(key_name) .. " = " .. trunc_str .. ","
        end
        return ind .. trunc_str
    end

    -- Get type label
    local type_label = self:get_type_label(v)

    -- Header line (as Lua table assignment)
    local header = ""
    if key_name then
        header = self:lua_key(key_name) .. " = {  -- " .. type_label
    else
        header = "{  -- " .. type_label
    end
    lines[#lines + 1] = ind .. header

    -- Metatable info as comments
    local mt_lines = self:format_metatable(v, level + 1)
    for _, line in self.ipairs(mt_lines) do
        lines[#lines + 1] = line
    end

    -- Mark as visiting
    self.VISITING[v] = true

    -- Collect and sort keys
    local keys = {}
    self.pcall(
        function()
            for k, _ in self.pairs(v) do
                keys[#keys + 1] = k
            end
        end
    )

    -- Sort keys: strings first alphabetically, then numbers
    self:sort_keys(keys)

    -- Format each member
    for _, k in self.ipairs(keys) do
        local ok, val =
            self.pcall(
            function()
                return v[k]
            end
        )
        if ok and val ~= nil then
            local key_lua = self:lua_key(k)

            -- Check if value needs recursive formatting
            local simple_val, comment = self:format_value(val, level + 1)

            if simple_val then
                lines[#lines + 1] = self:format_line(ind .. "  ", key_lua, simple_val, comment, true)
            else
                local nested = self:format_object(val, level + 1, k)
                lines[#lines + 1] = nested
            end
        end
    end

    -- Try to get __index methods if it's a class
    if type_label == "class" then
        local mt = nil
        self.pcall(
            function()
                mt = self.getmt(v)
            end
        )
        if mt and self.type(mt) == "table" then
            local index_table = nil
            self.pcall(
                function()
                    index_table = self.rawget(mt, "__index")
                end
            )
            if index_table and self.type(index_table) == "table" and index_table ~= v then
                local method_keys = {}
                self.pcall(
                    function()
                        for k, _ in self.pairs(index_table) do
                            if self.type(k) == "string" and not k:match("^__") then
                                method_keys[#method_keys + 1] = k
                            end
                        end
                    end
                )
                self.pcall(
                    function()
                        self.sort(method_keys)
                    end
                )

                for _, k in self.ipairs(method_keys) do
                    local ok, val =
                        self.pcall(
                        function()
                            return index_table[k]
                        end
                    )
                    if ok and self.type(val) == "function" then
                        local fn_val, fn_comment = self:format_function(val)
                        lines[#lines + 1] = self:format_line(ind .. "  ", k, fn_val, fn_comment, true)
                    end
                end
            end
        end
    end

    -- Close brace with comma for nested tables
    if key_name then
        lines[#lines + 1] = ind .. "},"
    else
        lines[#lines + 1] = ind .. "}"
    end

    -- Unmark visiting
    self.VISITING[v] = nil

    return self.concat(lines, "\n")
end

function ReadableFormatter:format_module(module_data, module_name, order)
    local lines = {}

    -- Header block as Lua comments
    lines[#lines + 1] = "-- ======================================================================"
    lines[#lines + 1] = "-- Module: " .. module_name
    lines[#lines + 1] = "-- Source: package.loaded"
    lines[#lines + 1] = "-- Type: " .. self.type(module_data)
    if order then
        lines[#lines + 1] = "-- Order: #" .. order
    end
    lines[#lines + 1] = "-- ======================================================================"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "return {"

    local t = self.type(module_data)

    if t == "function" then
        local fn_val, fn_comment = self:format_function(module_data)
        lines[#lines + 1] = self:format_line("  ", "_module_fn", fn_val, fn_comment, true)
    elseif t == "table" or t == "class" or t == "dict" or t == "list" then
        -- Format each top-level item
        local keys = {}
        self.pcall(
            function()
                for k, _ in self.pairs(module_data) do
                    keys[#keys + 1] = k
                end
            end
        )

        -- Sort keys
        self:sort_keys(keys)

        for _, k in self.ipairs(keys) do
            local ok, val =
                self.pcall(
                function()
                    return module_data[k]
                end
            )
            if ok and val ~= nil then
                local key_lua = self:lua_key(k)

                local simple_val, comment = self:format_value(val, 1)

                if simple_val then
                    lines[#lines + 1] = self:format_line("  ", key_lua, simple_val, comment, true)
                else
                    local nested = self:format_object(val, 1, k)
                    lines[#lines + 1] = nested
                end
            end
        end
    else
        -- Simple type
        local simple, comment = self:format_value(module_data, 0)
        if not simple then
            simple = self.format("%q", self:safe_tostring(module_data))
        end
        lines[#lines + 1] = self:format_line("  ", "_value", simple, comment, true)
    end

    -- Close return table
    lines[#lines + 1] = "}"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "-- End of " .. module_name

    return self.concat(lines, "\n")
end

DumpCore.ReadableFormatter = ReadableFormatter

-- ============================================================
-- JSON FORMATTER - Compact JSON format for searching
-- ============================================================
local JsonFormatter = {}

function JsonFormatter.init(config)
    local self = {}
    config = config or {}

    self.DUMP_DEPTH = config.depth or 12
    self.INCLUDE_SOURCE = config.include_source ~= false
    self.INDENT = "  " -- 2 spaces

    -- Debug callback
    self.write_debug = config.write_debug or function()
        end

    -- Verbose logging (logs progress for large tables)
    self.VERBOSE = config.verbose or false
    self.LOG_INTERVAL = config.log_interval or 100 -- Log every N keys for large tables

    -- Streaming mode: write directly to file handle instead of accumulating strings
    self.stream_file = config.stream_file -- Optional file handle for streaming output
    self.stream_buffer = {} -- Buffer for batched writes (improves I/O performance)
    self.stream_buffer_size = 0
    self.STREAM_BUFFER_LIMIT = 65536 -- Flush every 64KB

    -- Statistics tracking
    self.stats = {
        tables_processed = 0,
        keys_processed = 0,
        max_depth_reached = 0,
        start_time = os.clock(),
        bytes_written = 0
    }

    -- Safe references
    self.rawget = rawget
    self.type = type
    self.tostring = tostring
    self.pcall = pcall
    self.pairs = pairs
    self.ipairs = ipairs
    self.concat = table.concat
    self.format = string.format
    self.dbg = rawget(_G, "debug")
    self.getmt = (self.dbg and self.dbg.getmetatable) or getmetatable
    self.getinfo = self.dbg and self.dbg.getinfo

    -- Tracking
    self.VISITING = setmetatable({}, {__mode = "k"})

    -- Current path for logging (helps identify where we are)
    self.current_path = {}

    setmetatable(self, {__index = JsonFormatter})
    return self
end

-- Get indent string for depth
function JsonFormatter:indent(depth)
    return string.rep(self.INDENT, depth)
end

-- Sort keys for JSON output (skip sort for massive tables >500 keys)
function JsonFormatter:sort_keys(keys, path_str)
    self.pcall(
        function()
            if #keys > 500 then
                if self.VERBOSE then
                    self.write_debug(string.format("[JsonFormatter] Skipping sort for %s (too many keys)", path_str))
                end
            else
                table.sort(
                    keys,
                    function(a, b)
                        local ta, tb = self.type(a), self.type(b)
                        if ta ~= tb then
                            return ta < tb
                        end
                        if ta == "number" then
                            return a < b
                        end
                        return self.tostring(a) < self.tostring(b)
                    end
                )
            end
        end
    )
end

-- Streaming write helpers
function JsonFormatter:stream_write(str)
    if not self.stream_file then
        -- Not in streaming mode, return the string for accumulation
        return str
    end

    -- Add to buffer
    self.stream_buffer[#self.stream_buffer + 1] = str
    self.stream_buffer_size = self.stream_buffer_size + #str

    -- Flush if buffer is large enough
    if self.stream_buffer_size >= self.STREAM_BUFFER_LIMIT then
        self:stream_flush()
    end

    return "" -- Return empty string in streaming mode
end

function JsonFormatter:stream_flush()
    if not self.stream_file or #self.stream_buffer == 0 then
        return
    end

    local content = self.concat(self.stream_buffer)
    self.stream_file:write(content)
    self.stats.bytes_written = self.stats.bytes_written + #content

    -- Clear buffer
    self.stream_buffer = {}
    self.stream_buffer_size = 0
end

-- Escape string for JSON
function JsonFormatter:escape_string(s)
    if self.type(s) ~= "string" then
        return self.tostring(s)
    end

    -- Lookup table for common escape sequences
    local escape_chars = {
        ["\\"] = "\\\\",
        ['"'] = '\\"',
        ["\b"] = "\\b",
        ["\f"] = "\\f",
        ["\n"] = "\\n",
        ["\r"] = "\\r",
        ["\t"] = "\\t"
    }

    -- Replace all characters that need escaping using native gsub
    return s:gsub(
        ".",
        function(c)
            -- Use lookup table for common escapes
            if escape_chars[c] then
                return escape_chars[c]
            end

            -- Escape control characters (ASCII 0-31) as \uXXXX
            local byte = string.byte(c)
            if byte < 32 then
                return string.format("\\u%04x", byte)
            end

            -- Return character as-is
            return c
        end
    )
end

-- Get function signature
function JsonFormatter:get_func_sig(func)
    local sig = {params = nil, source = nil, lines = nil}
    if not self.getinfo then
        return sig
    end

    self.pcall(
        function()
            local info = self.getinfo(func, "Slu")
            if info then
                local params = {}
                local nparams = info.nparams or 0
                for i = 1, nparams do
                    local name = debug.getlocal(func, i)
                    params[i] = name or ("arg" .. i)
                end
                if info.isvararg then
                    params[#params + 1] = "..."
                end
                sig.params = self.concat(params, ", ")

                if info.source then
                    sig.source = info.source:gsub("^@", "")
                end
                if info.linedefined and info.linedefined > 0 then
                    sig.lines = info.linedefined .. "-" .. (info.lastlinedefined or info.linedefined)
                end
            end
        end
    )
    return sig
end

-- Get metatable keys only (simplified)
function JsonFormatter:get_mt_keys(tbl)
    local keys = {}
    local mt = nil
    self.pcall(
        function()
            mt = self.getmt(tbl)
        end
    )

    if mt and self.type(mt) == "table" then
        self.pcall(
            function()
                for k, _ in self.pairs(mt) do
                    if self.type(k) == "string" then
                        keys[#keys + 1] = k
                    end
                end
            end
        )
        self.pcall(
            function()
                table.sort(keys)
            end
        )
    end
    return keys
end

-- Format value as JSON with indentation
function JsonFormatter:format_value(v, depth, key_name)
    depth = depth or 0
    local t = self.type(v)

    if t == "nil" then
        return "null"
    elseif t == "boolean" then
        return v and "true" or "false"
    elseif t == "number" then
        if v ~= v then
            return "null"
        end
        if v == math.huge or v == -math.huge then
            return "null"
        end
        return self.tostring(v)
    elseif t == "string" then
        return '"' .. self:escape_string(v) .. '"'
    elseif t == "function" then
        -- Try decompilation first
        local sig = self:get_func_sig(v)
        local decompiled = DumpCore.decompile_function(v)
        if decompiled then
            -- Wrap in function(params) ... end so output is valid Lua
            local wrapped = "function(" .. (sig.params or "") .. ")\n" .. decompiled .. "\nend"
            return '"' .. self:escape_string(wrapped) .. '"'
        end
        local fn_str = "function(" .. (sig.params or "") .. ")"
        if sig.lines then
            -- Only show line numbers (source path is in file header)
            fn_str = fn_str .. " @" .. sig.lines
        end
        return '"' .. self:escape_string(fn_str) .. '"'
    elseif t == "table" or t == "class" or t == "dict" or t == "list" or t == "userdata" then
        return self:format_table(v, depth, key_name)
    else
        -- Unknown type - check if it's a class-like object we can iterate
        -- (matches behavior from backup Dump.lua lines 600-625)
        local mt = nil
        self.pcall(
            function()
                mt = self.getmt(v)
            end
        )

        -- If it has a metatable, try to treat it as a table-like object
        if mt then
            return self:format_table(v, depth, key_name)
        end

        -- Try to check if we can iterate over it (dynamic type with pairs support)
        local can_iterate = false
        self.pcall(
            function()
                for _ in pairs(v) do
                    can_iterate = true
                    break
                end
            end
        )

        if can_iterate then
            return self:format_table(v, depth, key_name)
        end

        -- Fall back to string representation
        return '"<' .. t .. '>"'
    end
end

-- Format table as JSON with indentation (STREAMING VERSION)
-- Writes directly to file instead of accumulating in memory
function JsonFormatter:write_table_stream(tbl, depth, key_name, is_last)
    depth = depth or 0
    local ind = self:indent(depth)
    local ind_inner = self:indent(depth + 1)

    -- Update stats
    self.stats.tables_processed = self.stats.tables_processed + 1
    if depth > self.stats.max_depth_reached then
        self.stats.max_depth_reached = depth
    end

    -- Cycle detection
    if self.VISITING[tbl] then
        self:stream_write('"<cycle>"')
        return
    end
    if depth >= self.DUMP_DEPTH then
        self:stream_write('"<truncated>"')
        return
    end

    -- Session cache check
    local session_cache = Reg.get(SESSION_CACHE_NAME)
    if session_cache and session_cache.visited[tbl] then
        session_cache.stats.cache_hits = session_cache.stats.cache_hits + 1
        local cached_path = session_cache.visited[tbl]
        self:stream_write('"<see: ' .. cached_path .. '>"')
        return
    end

    self.VISITING[tbl] = true

    -- Track current path
    if key_name then
        self.current_path[#self.current_path + 1] = key_name
    end

    -- Get all keys
    local keys = {}
    self.pcall(
        function()
            for k, _ in self.pairs(tbl) do
                keys[#keys + 1] = k
            end
        end
    )

    -- Log for large tables
    local is_large = #keys > 100
    local path_str = #self.current_path > 0 and table.concat(self.current_path, ".") or "<root>"

    if is_large then
        self.write_debug(string.format("[JsonFormatter] >> Entering: %s (%d keys, depth=%d)", path_str, #keys, depth))

        if session_cache then
            session_cache.visited[tbl] = path_str
            session_cache.stats.tables_cached = session_cache.stats.tables_cached + 1
        end
    end

    -- Sort keys (skip for massive tables)
    self:sort_keys(keys, path_str)

    -- Write opening brace
    self:stream_write("{\n")

    -- First pass: collect valid key-value pairs (to know which is last)
    local valid_pairs = {}
    for _, k in self.ipairs(keys) do
        local ok, v =
            self.pcall(
            function()
                return tbl[k]
            end
        )
        if ok and v ~= nil then
            valid_pairs[#valid_pairs + 1] = {key = k, value = v}
        end
    end

    -- Second pass: write with correct comma handling
    local processed = 0
    for idx, pair in self.ipairs(valid_pairs) do
        local k = pair.key
        local v = pair.value

        -- Write key
        local key_str
        if self.type(k) == "string" then
            key_str = '"' .. self:escape_string(k) .. '"'
        else
            key_str = '"[' .. self.tostring(k) .. ']"'
        end
        self:stream_write(ind_inner .. key_str .. ": ")

        -- Write value
        local vt = self.type(v)
        if vt == "table" or vt == "class" or vt == "dict" or vt == "list" then
            local child_key = self.type(k) == "string" and k or ("[" .. self.tostring(k) .. "]")
            self:write_table_stream(v, depth + 1, child_key)
        else
            -- Simple value
            self:stream_write(self:format_value(v, depth + 1))
        end

        -- Add comma only if NOT the last VALID element
        if idx < #valid_pairs then
            self:stream_write(",\n")
        else
            self:stream_write("\n")
        end

        processed = processed + 1
        self.stats.keys_processed = self.stats.keys_processed + 1

        -- Progress logging
        if is_large and processed % self.LOG_INTERVAL == 0 then
            local elapsed = os.clock() - self.stats.start_time
            self.write_debug(
                string.format(
                    "[JsonFormatter] %s: %d/%d keys (%.1fs elapsed)",
                    path_str,
                    processed,
                    #valid_pairs,
                    elapsed
                )
            )

            -- Flush buffer periodically for large tables
            self:stream_flush()
        end
    end

    -- Write closing brace
    self:stream_write(ind .. "}")

    self.VISITING[tbl] = nil

    -- Log completion
    if is_large then
        local elapsed = os.clock() - self.stats.start_time
        self.write_debug(
            string.format("[JsonFormatter] << Exiting: %s (%d keys done, %.1fs elapsed)", path_str, processed, elapsed)
        )
    end

    -- Pop current path
    if key_name then
        self.current_path[#self.current_path] = nil
    end
end

-- Format entire module as JSON (STREAMING VERSION)
-- Writes directly to file instead of accumulating in memory
function JsonFormatter:write_module_stream(module_data, module_name)
    local ind = self.INDENT

    -- Write opening brace
    self:stream_write("{\n")

    -- Module header
    self:stream_write(ind .. '"_module": "' .. self:escape_string(module_name) .. '",\n')
    self:stream_write(ind .. '"_type": "' .. self.type(module_data) .. '",\n')
    self:stream_write(ind .. '"_time": "' .. os.date("%Y-%m-%d %H:%M:%S") .. '",\n')

    -- Module content
    if self.type(module_data) == "function" then
        local sig = self:get_func_sig(module_data)
        local fn_str = "function(" .. (sig.params or "") .. ")"
        if sig.lines then
            fn_str = fn_str .. " @" .. sig.lines
        end
        self:stream_write(ind .. '"_fn": "' .. self:escape_string(fn_str) .. '"\n')
    elseif self.type(module_data) == "table" or self.type(module_data) == "class" then
        -- Get all members
        local keys = {}
        self.pcall(
            function()
                for k, _ in self.pairs(module_data) do
                    keys[#keys + 1] = k
                end
            end
        )
        self.pcall(
            function()
                table.sort(
                    keys,
                    function(a, b)
                        return self.tostring(a) < self.tostring(b)
                    end
                )
            end
        )

        for idx, k in self.ipairs(keys) do
            local ok, v =
                self.pcall(
                function()
                    return module_data[k]
                end
            )
            if ok and v ~= nil then
                local key_str = self.type(k) == "string" and k or ("[" .. self.tostring(k) .. "]")
                self:stream_write(ind .. '"' .. self:escape_string(key_str) .. '": ')

                local vt = self.type(v)
                if vt == "table" or vt == "class" or vt == "dict" or vt == "list" then
                    self:write_table_stream(v, 1, key_str, idx == #keys)
                else
                    self:stream_write(self:format_value(v, 1))
                end

                if idx < #keys then
                    self:stream_write(",\n")
                else
                    self:stream_write("\n")
                end
            end
        end
    else
        self:stream_write(ind .. '"_value": ' .. self:format_value(module_data, 1) .. "\n")
    end

    -- Write closing brace
    self:stream_write("}\n")

    -- Final flush
    self:stream_flush()

    -- Log statistics
    local elapsed = os.clock() - self.stats.start_time
    self.write_debug(
        string.format(
            "[JsonFormatter] COMPLETED: %s - %d tables, %d keys, max_depth=%d, %.2fs total, %.2f MB written",
            module_name,
            self.stats.tables_processed,
            self.stats.keys_processed,
            self.stats.max_depth_reached,
            elapsed,
            self.stats.bytes_written / 1024 / 1024
        )
    )
end

-- Format table as JSON with indentation (ORIGINAL - MEMORY VERSION)
function JsonFormatter:format_table(tbl, depth, key_name)
    depth = depth or 0
    local ind = self:indent(depth)
    local ind_inner = self:indent(depth + 1)

    -- Update stats
    self.stats.tables_processed = self.stats.tables_processed + 1
    if depth > self.stats.max_depth_reached then
        self.stats.max_depth_reached = depth
    end

    -- Cycle detection (within current module)
    if self.VISITING[tbl] then
        return '"<cycle>"'
    end
    if depth >= self.DUMP_DEPTH then
        return '"<truncated>"'
    end

    -- ============================================================
    -- SESSION CACHE CHECK - Skip large tables already seen
    -- ============================================================
    local session_cache = Reg.get(SESSION_CACHE_NAME)
    if session_cache and session_cache.visited[tbl] then
        -- This large table was already fully dumped in a previous module
        session_cache.stats.cache_hits = session_cache.stats.cache_hits + 1
        local cached_path = session_cache.visited[tbl]
        return '"<see: ' .. cached_path .. '>"'
    end

    self.VISITING[tbl] = true

    -- Track current path for verbose logging
    if key_name then
        self.current_path[#self.current_path + 1] = key_name
    end

    local lines = {}

    -- Get all keys
    local keys = {}
    self.pcall(
        function()
            for k, _ in self.pairs(tbl) do
                keys[#keys + 1] = k
            end
        end
    )

    -- Log for large tables (always log if > 100 keys, or verbose mode)
    local is_large = #keys > 100
    local path_str = #self.current_path > 0 and table.concat(self.current_path, ".") or "<root>"

    if is_large then
        self.write_debug(string.format("[JsonFormatter] >> Entering: %s (%d keys, depth=%d)", path_str, #keys, depth))

        -- Add to session cache for future reference
        if session_cache then
            session_cache.visited[tbl] = path_str
            session_cache.stats.tables_cached = session_cache.stats.tables_cached + 1
        end
    end

    -- Sort keys (skip for massive tables)
    self:sort_keys(keys, path_str)

    -- Format each key-value pair with progress logging
    local processed = 0
    for idx, k in self.ipairs(keys) do
        local ok, v =
            self.pcall(
            function()
                return tbl[k]
            end
        )
        if ok and v ~= nil then
            local key_str
            if self.type(k) == "string" then
                key_str = '"' .. self:escape_string(k) .. '"'
            else
                key_str = '"[' .. self.tostring(k) .. ']"'
            end

            -- Pass key name for nested path tracking
            local child_key = self.type(k) == "string" and k or ("[" .. self.tostring(k) .. "]")
            local val_str = self:format_value(v, depth + 1, child_key)
            lines[#lines + 1] = ind_inner .. key_str .. ": " .. val_str

            processed = processed + 1
            self.stats.keys_processed = self.stats.keys_processed + 1

            -- Log progress for large tables
            if is_large and processed % self.LOG_INTERVAL == 0 then
                local elapsed = os.clock() - self.stats.start_time
                self.write_debug(
                    string.format("[JsonFormatter] %s: %d/%d keys (%.1fs elapsed)", path_str, processed, #keys, elapsed)
                )
            end
        end
    end

    -- Add metatable keys only (simplified)
    local mt_keys = self:get_mt_keys(tbl)
    if #mt_keys > 0 then
        local mt_quoted = {}
        for _, k in self.ipairs(mt_keys) do
            mt_quoted[#mt_quoted + 1] = '"' .. k .. '"'
        end
        lines[#lines + 1] = ind_inner .. '"__mt": [' .. self.concat(mt_quoted, ", ") .. "]"
    end

    self.VISITING[tbl] = nil

    -- Log completion for large tables
    if is_large then
        local elapsed = os.clock() - self.stats.start_time
        self.write_debug(
            string.format("[JsonFormatter] << Exiting: %s (%d keys done, %.1fs elapsed)", path_str, processed, elapsed)
        )
    end

    -- Pop current path
    if key_name then
        self.current_path[#self.current_path] = nil
    end

    if #lines == 0 then
        return "{}"
    end
    return "{\n" .. self.concat(lines, ",\n") .. "\n" .. ind .. "}"
end

-- Format entire module as JSON
function JsonFormatter:format_module(module_data, module_name)
    local lines = {}
    local ind = self.INDENT

    -- Module header
    lines[#lines + 1] = ind .. '"_module": "' .. self:escape_string(module_name) .. '"'
    lines[#lines + 1] = ind .. '"_type": "' .. self.type(module_data) .. '"'
    lines[#lines + 1] = ind .. '"_time": "' .. os.date("%Y-%m-%d %H:%M:%S") .. '"'

    -- Module content
    if self.type(module_data) == "function" then
        local sig = self:get_func_sig(module_data)
        local fn_str = "function(" .. (sig.params or "") .. ")"
        if sig.lines then
            fn_str = fn_str .. " @" .. sig.lines
        end
        lines[#lines + 1] = ind .. '"_fn": "' .. self:escape_string(fn_str) .. '"'
    elseif self.type(module_data) == "table" or self.type(module_data) == "class" then
        -- Get all members
        local keys = {}
        self.pcall(
            function()
                for k, _ in self.pairs(module_data) do
                    keys[#keys + 1] = k
                end
            end
        )
        self.pcall(
            function()
                table.sort(
                    keys,
                    function(a, b)
                        return self.tostring(a) < self.tostring(b)
                    end
                )
            end
        )

        for _, k in self.ipairs(keys) do
            local ok, v =
                self.pcall(
                function()
                    return module_data[k]
                end
            )
            if ok and v ~= nil then
                local key_str = self.type(k) == "string" and k or ("[" .. self.tostring(k) .. "]")
                local val_str = self:format_value(v, 1)
                lines[#lines + 1] = ind .. '"' .. self:escape_string(key_str) .. '": ' .. val_str
            end
        end

        -- Metatable keys only
        local mt_keys = self:get_mt_keys(module_data)
        if #mt_keys > 0 then
            local mt_quoted = {}
            for _, k in self.ipairs(mt_keys) do
                mt_quoted[#mt_quoted + 1] = '"' .. k .. '"'
            end
            lines[#lines + 1] = ind .. '"__mt": [' .. self.concat(mt_quoted, ", ") .. "]"
        end
    else
        lines[#lines + 1] = ind .. '"_value": ' .. self:format_value(module_data, 1)
    end

    -- Log final statistics
    local elapsed = os.clock() - self.stats.start_time
    self.write_debug(
        string.format(
            "[JsonFormatter] COMPLETED: %s - %d tables, %d keys, max_depth=%d, %.2fs total",
            module_name,
            self.stats.tables_processed,
            self.stats.keys_processed,
            self.stats.max_depth_reached,
            elapsed
        )
    )

    return "{\n" .. self.concat(lines, ",\n") .. "\n}\n"
end

DumpCore.JsonFormatter = JsonFormatter

local function should_skip_source(source_path)
    if not source_path or type(source_path) ~= "string" then
        return false
    end
    local clean = source_path:gsub("^@", "")
    for _, prefix in ipairs(SKIP_SRC_PREFIXES) do
        if clean:sub(1, #prefix) == prefix then
            return true
        end
    end
    return false
end

local function get_module_source(module_data)
    if type(module_data) == "function" then
        local ok, info = pcall(debug.getinfo, module_data, "S")
        if ok and info and info.source then
            return info.source
        end
    elseif is_iterable(module_data) then
        local ok_iter, iter, state, initial = pcall(pairs, module_data)
        if ok_iter then
            for k, v in iter, state, initial do
                if type(v) == "function" then
                    local ok, info = pcall(debug.getinfo, v, "S")
                    if ok and info and info.source then
                        return info.source
                    end
                end
            end
        end
    end
    return nil
end

-- ============================================================
-- DUMP MODULE - Dump a single module
-- ============================================================
-- module_path: string name of module
-- options:
--   module_data: optional pre-loaded module (skips package.loaded lookup)
--   output_dir: optional output directory
--   write_debug: optional debug logging function
--   depth: optional encoding depth
--   pretty: optional pretty print flag
--   include_source: optional include source flag
-- ============================================================
-- AUTO-SPLIT FOR MASSIVE TABLES
-- ============================================================

--[[
    Dumps a module by splitting its top-level keys into separate files.
    Used for massive tables (500+ keys) to avoid performance issues.
    
    @param module_path - Module name (e.g., "hexm.common.data.dir_object")
    @param mod - The module table to dump
    @param options - Configuration options
    @return split_dir - Path to the split directory
]]
function DumpCore.dump_module_split(module_path, mod, options)
    options = options or {}
    local write_debug = options.write_debug or function()
        end
    local format = "readable" -- Always .lua
    local file_ext = ".lua"

    write_debug("[SplitDump] ============================================================")
    write_debug("[SplitDump] SPLITTING MODULE: " .. module_path)

    -- Build split directory path
    local path_parts = {}
    for part in module_path:gmatch("[^%.]+") do
        path_parts[#path_parts + 1] = ModuleDumper.sanitize_name(part)
    end

    if #path_parts == 0 then
        write_debug("[SplitDump] ERROR: Invalid module path")
        return nil, "Invalid module path"
    end

    local base_dir = options.output_dir or ModuleDumper.BASE_DIR
    local module_dir = base_dir

    -- Build path to parent directory
    for i = 1, #path_parts - 1 do
        module_dir = module_dir .. "\\\\" .. path_parts[i]
    end

    -- Create split subdirectory (module_name/)
    local split_name = path_parts[#path_parts]
    local split_dir = module_dir .. "\\\\" .. split_name
    ModuleDumper.mkdir(split_dir)

    write_debug("[SplitDump] Split directory: " .. split_dir)

    -- Count keys
    local keys = {}
    for k, _ in pairs(mod) do
        keys[#keys + 1] = k
    end
    table.sort(
        keys,
        function(a, b)
            return tostring(a) < tostring(b)
        end
    )

    local total = #keys
    write_debug(string.format("[SplitDump] Detected %d top-level keys", total))

    -- Create formatter based on format
    local formatter
    if format == "json" then
        formatter =
            JsonFormatter.init(
            {
                depth = options.depth or 12,
                include_source = options.include_source ~= false,
                write_debug = function()
                end -- Suppress per-key logs
            }
        )
    else
        formatter =
            ReadableFormatter.init(
            {
                depth = options.depth or 12,
                include_source = options.include_source ~= false,
                detailed_functions = options.detailed_functions or true,
                write_debug = function()
                end -- Suppress per-key logs
            }
        )
    end

    -- Write index file (JSONL format: one JSON object per line)
    local index_path = split_dir .. "\\\\_index.jsonl"
    local index_file = io.open(index_path, "w")
    if not index_file then
        write_debug("[SplitDump] ERROR: Cannot create index file")
        return nil, "Failed to create index file"
    end

    write_debug("[SplitDump] Creating index: _index.jsonl")

    -- Split each key to separate file
    local success_count = 0
    local error_count = 0

    for i, key in ipairs(keys) do
        -- Progress logging every 100 keys
        if i % 100 == 0 or i == 1 or i == total then
            write_debug(string.format("[SplitDump] Progress: %d/%d (%.1f%%)", i, total, (i / total) * 100))
        end

        local value = mod[key]
        local safe_key = ModuleDumper.sanitize_name(tostring(key))
        local key_file = split_dir .. "\\\\" .. safe_key .. file_ext

        -- Format the value with error handling
        local ok, content =
            pcall(
            function()
                return formatter:format_value(value)
            end
        )

        if not ok or not content then
            error_count = error_count + 1
            write_debug(string.format("[SplitDump] ERROR formatting key '%s': %s", tostring(key), tostring(content)))
            -- Skip this key
            goto continue
        end

        -- Write key file
        local f, write_err = io.open(key_file, "w")
        if f then
            if format == "json" then
                f:write(content)
            else
                -- Wrap in return statement for Lua files
                f:write("return " .. content)
            end
            f:close()
            success_count = success_count + 1

            -- Write index entry (JSONL format) with error handling
            local ok_key, formatted_key = pcall(formatter.format_value, formatter, key)
            local ok_file, formatted_file = pcall(formatter.format_value, formatter, safe_key .. file_ext)

            if ok_key and ok_file then
                local index_entry = string.format('{"key":%s,"file":%s}\n', formatted_key, formatted_file)
                index_file:write(index_entry)
            end
        else
            error_count = error_count + 1
            write_debug("[SplitDump] ERROR writing key file: " .. tostring(write_err))
        end

        ::continue::
    end

    index_file:close()

    write_debug("[SplitDump] ============================================================")
    write_debug(string.format("[SplitDump] COMPLETE: %d files written, %d errors", success_count, error_count))
    write_debug("[SplitDump] Index: " .. index_path)
    write_debug("[SplitDump] Files: " .. split_dir)

    return split_dir, nil
end

function DumpCore.dump_module(module_path, options)
    options = options or {}
    local force = options.force or false
    local write_debug = options.write_debug or function()
        end
    local format = "readable" -- Always .lua
    local file_ext = ".lua"

    write_debug("[DumpModule] Dumping: " .. tostring(module_path) .. " (format: " .. format .. ")")

    -- ============================================================
    -- EARLY CACHE CHECK - Skip if file already exists
    -- ============================================================
    -- Parse module path into parts (split by .) to build filepath
    local path_parts = {}
    for part in module_path:gmatch("[^%.]+") do
        path_parts[#path_parts + 1] = ModuleDumper.sanitize_name(part)
    end

    if #path_parts == 0 then
        write_debug("[DumpModule] ERROR: Invalid module path")
        return nil, "Invalid module path"
    end

    -- Build the target filepath
    local base_dir = options.output_dir or ModuleDumper.BASE_DIR
    local current_path = base_dir

    for i = 1, #path_parts - 1 do
        current_path = current_path .. "\\\\" .. path_parts[i]
    end

    local file_name = path_parts[#path_parts] .. file_ext
    local filepath = current_path .. "\\\\" .. file_name

    -- Check if file exists (Caching) - EARLY EXIT
    if ModuleDumper.path_exists(filepath) and not force then
        write_debug("[DumpModule] CACHED (file exists): " .. filepath)
        return filepath
    end

    -- ============================================================
    -- MODULE LOADING & AUTO-SPLIT DETECTION
    -- ============================================================

    -- Get module - use provided module_data or look up from package.loaded
    local mod = options.module_data or package.loaded[module_path]
    if not mod then
        write_debug("[DumpModule] Module not loaded: " .. tostring(module_path))
        return nil, "Module not loaded"
    end

    write_debug("[DumpModule] Module type: " .. type(mod))

    -- ============================================================
    -- AUTO-SPLIT DETECTION (Hybrid approach)
    -- ============================================================

    -- Hardcoded list: Always split these known massive modules
    -- Format: [module_path] = "nested.path.to.cache" or true for top-level
    local ALWAYS_SPLIT = {
        ["hexm.common.data.dir_object"] = "DirObject.DirObject_Cache" -- Nested structure
    }

    -- Auto-split detection for tables
    local should_split = false
    local key_count = 0
    local split_target = mod -- What to actually split

    if type(mod) == "table" then
        -- Check hardcoded list first
        if ALWAYS_SPLIT[module_path] then
            local nested_path = ALWAYS_SPLIT[module_path]

            if type(nested_path) == "string" then
                -- Navigate to nested table
                write_debug("[DumpModule] Navigating to nested cache: " .. nested_path)
                local parts = {}
                for part in nested_path:gmatch("[^%.]+") do
                    parts[#parts + 1] = part
                end

                local target = mod
                for _, part in ipairs(parts) do
                    if type(target) == "table" and target[part] then
                        target = target[part]
                    else
                        write_debug(
                            string.format("[DumpModule] WARNING: Nested path '%s' not found at '%s'", nested_path, part)
                        )
                        target = nil
                        break
                    end
                end

                if target and type(target) == "table" then
                    split_target = target
                    -- Count keys in nested table
                    for _ in pairs(split_target) do
                        key_count = key_count + 1
                    end
                    should_split = true
                    write_debug(
                        string.format("[DumpModule] Hardcoded split (nested): %s -> %d keys", module_path, key_count)
                    )
                else
                    write_debug("[DumpModule] WARNING: Could not find nested cache, falling back to normal dump")
                    -- Count top-level keys as fallback
                    for _ in pairs(mod) do
                        key_count = key_count + 1
                    end
                end
            else
                -- Top-level split
                split_target = mod
                for _ in pairs(split_target) do
                    key_count = key_count + 1
                end
                should_split = true
                write_debug(string.format("[DumpModule] Hardcoded split: %s (%d keys)", module_path, key_count))
            end
        else
            -- Count top-level keys for generic auto-split
            for _ in pairs(mod) do
                key_count = key_count + 1
            end

            -- Check generic auto-split (opt-in via options)
            if options.auto_split then
                local threshold = options.split_threshold or 500
                if key_count > threshold then
                    should_split = true
                    write_debug(
                        string.format(
                            "[DumpModule] Auto-split triggered: %d keys > threshold (%d)",
                            key_count,
                            threshold
                        )
                    )
                end
            end
        end
    end

    -- If should split, use split dumper instead
    if should_split then
        write_debug("[DumpModule] Redirecting to dump_module_split...")
        -- Pass the actual table to split (might be nested)
        local split_options = {}
        for k, v in pairs(options) do
            split_options[k] = v
        end
        split_options.module_data = split_target -- Override with nested table
        return DumpCore.dump_module_split(module_path, split_target, split_options)
    end

    -- ============================================================
    -- NORMAL DUMP (for non-massive tables)
    -- ============================================================

    -- Create directories first (ensure they exist)
    ModuleDumper.mkdir(base_dir)
    current_path = base_dir
    for i = 1, #path_parts - 1 do
        current_path = current_path .. "\\\\" .. path_parts[i]
        ModuleDumper.mkdir(current_path)
    end

    write_debug("[DumpModule] Directory: " .. current_path)
    write_debug("[DumpModule] Opening file: " .. filepath)

    -- Open file for writing
    local f, err = io.open(filepath, "w")
    if not f then
        write_debug("[DumpModule] Failed to open file: " .. tostring(err))
        return nil, err
    end

    -- Use STREAMING MODE for JSON (writes directly to file, constant memory usage)
    -- Use MEMORY MODE for Lua (smaller files, faster)
    if format == "json" then
        write_debug("[DumpModule] Using STREAMING mode (constant memory, ~64KB buffer)")

        -- Create formatter with streaming enabled
        local formatter =
            JsonFormatter.init(
            {
                depth = options.depth or 12,
                include_source = options.include_source ~= false,
                write_debug = write_debug,
                stream_file = f -- Enable streaming mode!
            }
        )

        -- Stream module directly to file (no memory accumulation)
        formatter:write_module_stream(mod, module_path)
    else
        write_debug("[DumpModule] Using MEMORY mode (faster for small files)")

        -- Use memory mode for Lua format (typically smaller)
        local formatter =
            ReadableFormatter.init(
            {
                depth = options.depth or 12,
                include_source = options.include_source ~= false,
                detailed_functions = options.detailed_functions or true,
                write_debug = write_debug
            }
        )

        local content = formatter:format_module(mod, module_path)
        f:write(content)
    end

    f:close()

    write_debug("[DumpModule] Saved: " .. filepath)
    return filepath
end

-- ============================================================
-- DUMP ALL MODULES - Dump all loaded modules
-- ============================================================
function DumpCore.dump_all_modules(options)
    options = options or {}
    local write_debug = options.write_debug or function()
        end

    local base_dir = options.output_dir or ModuleDumper.BASE_DIR
    ModuleDumper.mkdir(base_dir)

    -- Collect all modules first
    local modules = {}
    for name, mod in pairs(package.loaded) do
        if type(name) == "string" and mod ~= nil then
            local source = get_module_source(mod)
            if not (source and should_skip_source(source)) then
                modules[#modules + 1] = {name = name, mod = mod}
            end
        end
    end

    -- Sort for consistent order
    table.sort(
        modules,
        function(a, b)
            return a.name < b.name
        end
    )

    local total = #modules
    write_debug(string.format("[DumpAll] Starting dump of %d modules...", total))

    local count = 0
    local errors = 0

    for i, item in ipairs(modules) do
        write_debug(string.format("[DumpAll] [%d/%d] %s", i, total, item.name))

        local ok, err =
            pcall(
            function()
                DumpCore.dump_module(
                    item.name,
                    {
                        output_dir = base_dir,
                        depth = options.depth,
                        include_source = options.include_source,
                        format = options.format,
                        module_data = item.mod,
                        write_debug = write_debug -- FIX: Pass write_debug to dump_module!
                    }
                )
            end
        )

        if ok then
            count = count + 1
        else
            errors = errors + 1
            write_debug("[DumpAll] ERROR: " .. item.name .. " - " .. tostring(err))
        end
    end

    write_debug(string.format("[DumpAll] Complete: %d dumped, %d errors", count, errors))
    return count, errors
end

-- ============================================================
-- ASYNC DUMP STATE - Global state for async dump operations
-- ============================================================
local ASYNC_DUMP_STATE_NAME = "ASYNC_DUMP_STATE"

-- ============================================================
-- DUMP ALL MODULES ASYNC - Non-blocking chunked dump
-- ============================================================
--[[
    Dumps all modules asynchronously using Cocos2d-x scheduler.
    Processes modules in small batches to avoid blocking the game thread.

    @param options table:
        - output_dir: string - Output directory
        - format: string - "json" or "readable"
        - depth: number - Max dump depth
        - batch_size: number - Modules per tick (default: 3)
        - delay_ms: number - Delay between batches in ms (default: 50)
        - write_debug: function - Debug logging callback
        - on_progress: function(current, total, name) - Progress callback
        - on_complete: function(count, errors) - Completion callback
        - defer_massive: boolean - Defer massive modules to end (default: true)

    @return boolean - true if started, false if already running
]]
function DumpCore.dump_all_modules_async(options)
    options = options or {}
    local write_debug = options.write_debug or function()
        end

    -- Check if already running
    if Reg.has(ASYNC_DUMP_STATE_NAME) and Reg.get(ASYNC_DUMP_STATE_NAME).running then
        write_debug("[AsyncDump] Already running!")
        return false, "Already running"
    end

    -- Start session cache (prevents re-traversing shared large tables)
    DumpCore.start_session()
    write_debug("[AsyncDump] Session cache started")

    -- Start bytecode session (saves bytecodes to disk instead of calling JVM)
    local base_dir = options.output_dir or ModuleDumper.BASE_DIR
    if options.save_bytecode then
        DumpCore.start_bytecode_session(base_dir)
        write_debug("[AsyncDump] Bytecode session started -> " .. base_dir .. "\\\\bytecodes")
    else
        write_debug("[AsyncDump] Bytecode session skipped (save_bytecode=false)")
    end

    -- Configuration
    local batch_size = options.batch_size or 3 -- Modules per tick
    local delay_sec = (options.delay_ms or 50) / 1000 -- Convert ms to seconds
    local on_progress = options.on_progress or function()
        end
    local on_complete = options.on_complete or function()
        end

    local base_dir = options.output_dir or ModuleDumper.BASE_DIR
    ModuleDumper.mkdir(base_dir)

    -- Collect all modules
    write_debug("[AsyncDump] Collecting modules...")
    local modules = {}
    local skipped_modules = {} -- For logging skipped modules

    -- Uses top-level SKIP_MODULE_NAMES and SKIP_SRC_PREFIXES
    for name, mod in pairs(package.loaded) do
        if type(name) == "string" and mod ~= nil then
            -- Check skip list first (by module name)
            if SKIP_MODULE_NAMES[name] then
                skipped_modules[#skipped_modules + 1] = name
            else
                -- Check skip list by source path
                local source = get_module_source(mod)
                if not (source and should_skip_source(source)) then
                    modules[#modules + 1] = {name = name, mod = mod}
                end
            end
        end
    end

    -- Sort for consistent order
    table.sort(
        modules,
        function(a, b)
            return a.name < b.name
        end
    )

    -- Log skipped modules
    for _, name in ipairs(skipped_modules) do
        write_debug("[AsyncDump] SKIPPED (circular/massive): " .. name)
    end

    local total = #modules
    write_debug(
        string.format(
            "[AsyncDump] Starting async dump of %d modules (batch=%d, delay=%.0fms)",
            total,
            batch_size,
            delay_sec * 1000
        )
    )

    -- Initialize state
    Reg.set(
        ASYNC_DUMP_STATE_NAME,
        {
            running = true,
            cancelled = false,
            modules = modules,
            current_index = 1,
            total = total,
            count = 0,
            errors = 0,
            start_time = os.clock(),
            options = options,
            base_dir = base_dir,
            batch_size = batch_size,
            delay_sec = delay_sec,
            write_debug = write_debug,
            on_progress = on_progress,
            on_complete = on_complete,
            action_ref = nil
        }
    )

    -- Process one batch of modules
    local function process_batch()
        local state = Reg.get(ASYNC_DUMP_STATE_NAME)
        if not state or not state.running then
            return
        end

        -- Check cancellation
        if state.cancelled then
            state.write_debug("[AsyncDump] Cancelled by user")
            state.running = false
            state.on_complete(state.count, state.errors)
            DumpCore.stop_async_dump()
            return
        end

        -- Process batch
        local batch_end = math.min(state.current_index + state.batch_size - 1, state.total)

        for i = state.current_index, batch_end do
            local item = state.modules[i]
            if item then
                local elapsed = os.clock() - state.start_time
                state.write_debug(
                    string.format("[AsyncDump] [%d/%d] %s (%.1fs elapsed)", i, state.total, item.name, elapsed)
                )

                -- Call progress callback
                state.on_progress(i, state.total, item.name)

                local ok, err =
                    pcall(
                    function()
                        DumpCore.dump_module(
                            item.name,
                            {
                                output_dir = state.base_dir,
                                depth = state.options.depth or 12,
                                include_source = state.options.include_source,
                                format = state.options.format,
                                module_data = item.mod,
                                write_debug = state.write_debug
                            }
                        )
                    end
                )

                if ok then
                    state.count = state.count + 1
                else
                    state.errors = state.errors + 1
                    state.write_debug("[AsyncDump] ERROR: " .. item.name .. " - " .. tostring(err))
                end
            end
        end

        state.current_index = batch_end + 1

        -- Check if done
        if state.current_index > state.total then
            local elapsed = os.clock() - state.start_time
            state.write_debug(
                string.format(
                    "[AsyncDump] Complete: %d dumped, %d errors (%.1fs total)",
                    state.count,
                    state.errors,
                    elapsed
                )
            )
            state.running = false
            state.on_complete(state.count, state.errors)
            DumpCore.stop_async_dump()
        end
    end

    -- Start the async loop using Cocos2d-x scheduler
    local scene = cc.Director:getInstance():getRunningScene()
    if not scene then
        write_debug("[AsyncDump] ERROR: No running scene!")
        Reg.del(ASYNC_DUMP_STATE_NAME)
        return false, "No running scene"
    end

    -- Create repeating action
    local action =
        cc.RepeatForever:create(
        cc.Sequence:create(
            {
                cc.DelayTime:create(delay_sec),
                cc.CallFunc:create(
                    function()
                        process_batch()
                    end
                )
            }
        )
    )

    scene:runAction(action)
    Reg.get(ASYNC_DUMP_STATE_NAME).action_ref = action

    -- Process first batch immediately
    process_batch()

    write_debug("[AsyncDump] Async dump started!")
    return true
end

-- ============================================================
-- STOP ASYNC DUMP - Cancel running async dump
-- ============================================================
function DumpCore.stop_async_dump()
    local state = Reg.get(ASYNC_DUMP_STATE_NAME)
    if not state then
        return false
    end

    -- Stop the action
    if state.action_ref then
        local scene = cc.Director:getInstance():getRunningScene()
        if scene then
            scene:stopAction(state.action_ref)
        end
        state.action_ref = nil
    end

    state.running = false
    Reg.del(ASYNC_DUMP_STATE_NAME)

    -- End session cache (frees memory, logs stats)
    DumpCore.end_session()

    -- End bytecode session (writes manifest)
    local bc_stats = DumpCore.end_bytecode_session()
    if bc_stats and state.write_debug then
        state.write_debug(string.format(
            "[AsyncDump] Bytecodes saved: %d functions -> %s",
            bc_stats.total, bc_stats.bytecode_dir
        ))
    end

    if state.write_debug then
        state.write_debug("[AsyncDump] Stopped")
    end

    return true
end

-- ============================================================
-- CANCEL ASYNC DUMP - Request cancellation (graceful stop)
-- ============================================================
function DumpCore.cancel_async_dump()
    local state = Reg.get(ASYNC_DUMP_STATE_NAME)
    if not state or not state.running then
        return false, "Not running"
    end

    state.cancelled = true
    if state.write_debug then
        state.write_debug("[AsyncDump] Cancellation requested...")
    end

    return true
end

-- ============================================================
-- IS ASYNC DUMP RUNNING
-- ============================================================
function DumpCore.is_async_dump_running()
    local state = Reg.get(ASYNC_DUMP_STATE_NAME)
    return state ~= nil and state.running == true
end

-- ============================================================
-- GET ASYNC DUMP PROGRESS
-- ============================================================
function DumpCore.get_async_dump_progress()
    local state = Reg.get(ASYNC_DUMP_STATE_NAME)
    if not state then
        return nil
    end

    return {
        running = state.running,
        current = state.current_index - 1,
        total = state.total,
        count = state.count,
        errors = state.errors,
        elapsed = os.clock() - state.start_time
    }
end

-- ============================================================
-- DUMP BY PREFIX - Dump all modules matching a path prefix
-- ============================================================
function DumpCore.dump_by_prefix(path_prefix, options)
    options = options or {}
    local write_debug = options.write_debug or function()
        end

    if not path_prefix or path_prefix == "" then
        write_debug("[DumpByPrefix] ERROR: path_prefix is required")
        return 0, 0, "path_prefix is required"
    end

    write_debug("[DumpByPrefix] Dumping modules matching: " .. path_prefix)

    local base_dir = options.output_dir or ModuleDumper.BASE_DIR
    ModuleDumper.mkdir(base_dir)

    local count = 0
    local skipped = 0
    local matched = 0

    -- Collect matching modules first
    local matching_modules = {}
    for name, mod in pairs(package.loaded) do
        if type(name) == "string" and mod ~= nil then
            -- Check if module name starts with prefix
            if name:sub(1, #path_prefix) == path_prefix then
                matching_modules[#matching_modules + 1] = {name = name, mod = mod}
                matched = matched + 1
            end
        end
    end

    write_debug("[DumpByPrefix] Found " .. matched .. " matching modules")

    -- Sort alphabetically
    table.sort(
        matching_modules,
        function(a, b)
            return a.name < b.name
        end
    )

    -- Dump each matching module
    for _, item in ipairs(matching_modules) do
        local name = item.name

        -- Check source skip
        local source = get_module_source(item.mod)
        if source and should_skip_source(source) then
            skipped = skipped + 1
            write_debug("[DumpByPrefix] Skipping (source): " .. name)
        else
            local ok, err =
                pcall(
                function()
                    DumpCore.dump_module(
                        name,
                        {
                            output_dir = base_dir,
                            write_debug = write_debug,
                            depth = options.depth,
                            include_source = options.include_source,
                            detailed_functions = options.detailed_functions,
                            format = options.format, -- Pass format option
                            module_data = item.mod -- Pass the module data directly
                        }
                    )
                end
            )
            if ok then
                count = count + 1
                write_debug("[DumpByPrefix] Dumped: " .. name)
            else
                write_debug("[DumpByPrefix] Error dumping " .. name .. ": " .. tostring(err))
            end
        end
    end

    write_debug(
        string.format("[DumpByPrefix] Complete: %d dumped, %d skipped (of %d matched)", count, skipped, matched)
    )
    return count, skipped
end

-- ============================================================
-- DUMP GM MENU - Dump GM command menus
-- ============================================================
function DumpCore.dump_gm(options)
    options = options or {}
    local write_debug = options.write_debug or function()
        end

    write_debug("[DumpGM] Dumping GM menus...")

    local base_dir = options.output_dir or ModuleDumper.BASE_DIR
    ModuleDumper.mkdir(base_dir)

    -- Look for GM menu module
    local gm_module = nil
    for name, mod in pairs(package.loaded) do
        if type(name) == "string" and name:find("gm_menu") then
            gm_module = mod
            break
        end
    end

    if not gm_module then
        write_debug("[DumpGM] GM menu module not found")
        return nil, "GM menu not found"
    end

    local enc =
        Encoder.init(
        {
            depth = options.depth or 12,
            pretty = true,
            include_source = true
        }
    )

    local encoded = enc:encode(gm_module)

    local filepath = base_dir .. "\\gm_menu_dump.lua"
    local f, err = io.open(filepath, "w")
    if not f then
        return nil, err
    end

    f:write("-- GM Menu Dump\n")
    f:write("-- Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n")
    f:write("return " .. encoded .. "\n")
    f:close()

    write_debug("[DumpGM] Saved: " .. filepath)
    return filepath
end

-- ============================================================
-- DUMP BOOLEANS - Find all boolean variables
-- ============================================================
function DumpCore.dump_booleans(options)
    options = options or {}
    local write_debug = options.write_debug or function()
        end
    local path_prefix = options.path_prefix or ""
    local max_depth = options.max_depth or 8

    write_debug("[DumpBooleans] Starting boolean scan...")

    local base_dir = options.output_dir or ModuleDumper.BASE_DIR
    ModuleDumper.mkdir(base_dir)

    local function key_suffix(k)
        local kt = type(k)
        if kt == "string" and is_valid_ident(k) then
            return "." .. k
        elseif kt == "string" then
            return "[" .. string.format("%q", k) .. "]"
        elseif kt == "number" then
            return "[" .. tostring(k) .. "]"
        else
            return "[" .. string.format("%q", tostring(k)) .. "]"
        end
    end

    local visited = setmetatable({}, {__mode = "k"})
    local bool_vars = {}
    local true_count = 0
    local false_count = 0

    local function visit(value, path, depth)
        if depth > max_depth then
            return
        end

        local t = type(value)

        if t == "boolean" then
            bool_vars[#bool_vars + 1] = path .. " = " .. (value and "true" or "false")
            if value then
                true_count = true_count + 1
            else
                false_count = false_count + 1
            end
            return
        end

        if t ~= "table" then
            return
        end
        if visited[value] then
            return
        end
        visited[value] = true

        pcall(
            function()
                for k, _ in next, value do
                    local ok, v = pcall(rawget, value, k)
                    if ok and v ~= nil then
                        visit(v, path .. key_suffix(k), depth + 1)
                    end
                end
            end
        )
    end

    -- Scan loaded modules
    for name, mod in pairs(package.loaded) do
        if type(name) == "string" then
            if path_prefix == "" or name:sub(1, #path_prefix) == path_prefix then
                pcall(
                    function()
                        visit(mod, "ROOT." .. name, 0)
                    end
                )
            end
        end
    end

    -- Also scan _G
    pcall(
        function()
            visit(_G, "ROOT._G", 0)
        end
    )

    table.sort(bool_vars)

    -- Write output
    local filepath = base_dir .. "\\booleans_dump.lua"
    local f, err = io.open(filepath, "w")
    if not f then
        return nil, err
    end

    f:write(
        string.format(
            "-- Boolean dump\n-- Generated: %s\n-- Booleans: %d (true: %d, false: %d)\n\nreturn {\n",
            os.date("%Y-%m-%d %H:%M:%S"),
            #bool_vars,
            true_count,
            false_count
        )
    )

    for _, line in ipairs(bool_vars) do
        f:write("  " .. string.format("%q", line) .. ",\n")
    end

    f:write("}\n")
    f:close()

    write_debug(string.format("[DumpBooleans] Found %d booleans", #bool_vars))
    return bool_vars
end

-- ============================================================
-- BYTECODE DUMP ALL - Dump all module loaders as raw .luac files
-- Uses package.searchers[2] (engine searcher) to get loader functions,
-- then string.dump(loader) to save raw bytecode for offline decompilation.
-- ============================================================
local ASYNC_BC_DUMP_STATE_NAME = "ASYNC_BC_DUMP_STATE"

function DumpCore.dump_all_bytecodes_async(options)
    options = options or {}
    local write_debug = options.write_debug or function() end

    -- Check if already running
    if Reg.has(ASYNC_BC_DUMP_STATE_NAME) and Reg.get(ASYNC_BC_DUMP_STATE_NAME).running then
        write_debug("[BytecodeDumpAll] Already running!")
        return false, "Already running"
    end

    -- Get engine searcher (same approach as Test.lua)
    local engine_searcher = package.searchers and package.searchers[2]
    if not engine_searcher then
        write_debug("[BytecodeDumpAll] ERROR: package.searchers[2] not available")
        return false, "No engine searcher"
    end

    local batch_size = options.batch_size or 5
    local delay_sec = (options.delay_ms or 50) / 1000
    local on_progress = options.on_progress or function() end
    local on_complete = options.on_complete or function() end

    local base_dir = options.output_dir or BASE_DIR
    ModuleDumper.mkdir(base_dir)

    -- Collect all module names from package.loaded
    write_debug("[BytecodeDumpAll] Collecting modules...")
    local modules = {}
    for name, mod in pairs(package.loaded) do
        if type(name) == "string" and mod ~= nil then
            if not SKIP_MODULE_NAMES[name] then
                modules[#modules + 1] = name
            end
        end
    end

    table.sort(modules)
    local total = #modules
    write_debug(string.format("[BytecodeDumpAll] Found %d modules to dump", total))

    -- Initialize state
    Reg.set(ASYNC_BC_DUMP_STATE_NAME, {
        running = true,
        cancelled = false,
        modules = modules,
        current_index = 1,
        total = total,
        count = 0,
        skipped = 0,
        errors = 0,
        start_time = os.clock(),
        base_dir = base_dir,
        batch_size = batch_size,
        delay_sec = delay_sec,
        write_debug = write_debug,
        on_progress = on_progress,
        on_complete = on_complete,
        engine_searcher = engine_searcher,
        action_ref = nil
    })

    -- Process one batch of modules
    local function process_batch()
        local state = Reg.get(ASYNC_BC_DUMP_STATE_NAME)
        if not state or not state.running then return end

        -- Check cancellation
        if state.cancelled then
            state.write_debug("[BytecodeDumpAll] Cancelled by user")
            state.running = false
            state.on_complete(state.count, state.errors)
            DumpCore.stop_bytecode_dump()
            return
        end

        local batch_end = math.min(state.current_index + state.batch_size - 1, state.total)

        for i = state.current_index, batch_end do
            local modname = state.modules[i]
            if modname then
                local elapsed = os.clock() - state.start_time
                state.write_debug(string.format(
                    "[BytecodeDumpAll] [%d/%d] %s (%.1fs)",
                    i, state.total, modname, elapsed
                ))
                state.on_progress(i, state.total, modname)

                local ok, err = pcall(function()
                    -- Get loader via engine searcher
                    local loader, loader_path = state.engine_searcher(modname)
                    if type(loader) ~= "function" then
                        state.skipped = state.skipped + 1
                        return
                    end

                    -- Dump bytecode from loader
                    local dump_ok, bytecode = pcall(string.dump, loader)
                    if not dump_ok or not bytecode or #bytecode == 0 then
                        state.skipped = state.skipped + 1
                        return
                    end

                    -- Build output path: base_dir/a/b/c.luac from module a.b.c
                    local path_parts = {}
                    for part in modname:gmatch("[^%.]+") do
                        path_parts[#path_parts + 1] = ModuleDumper.sanitize_name(part)
                    end

                    if #path_parts == 0 then
                        state.skipped = state.skipped + 1
                        return
                    end

                    -- Create directories
                    local dir_path = state.base_dir
                    for j = 1, #path_parts - 1 do
                        dir_path = dir_path .. "\\\\" .. path_parts[j]
                        ModuleDumper.mkdir(dir_path)
                    end

                    -- Write .luac file
                    local filename = path_parts[#path_parts] .. ".luac"
                    local filepath = dir_path .. "\\\\" .. filename
                    local f = io.open(filepath, "wb")
                    if f then
                        f:write(bytecode)
                        f:close()
                        state.count = state.count + 1
                    else
                        state.errors = state.errors + 1
                        state.write_debug("[BytecodeDumpAll] ERROR writing: " .. filepath)
                    end
                end)

                if not ok then
                    state.errors = state.errors + 1
                    state.write_debug("[BytecodeDumpAll] ERROR: " .. modname .. " - " .. tostring(err))
                end
            end
        end

        state.current_index = batch_end + 1

        -- Check if done
        if state.current_index > state.total then
            local elapsed = os.clock() - state.start_time
            state.write_debug(string.format(
                "[BytecodeDumpAll] Complete: %d dumped, %d skipped, %d errors (%.1fs)",
                state.count, state.skipped, state.errors, elapsed
            ))
            state.running = false
            state.on_complete(state.count, state.errors)
            DumpCore.stop_bytecode_dump()
        end
    end

    -- Start async loop using Cocos2d-x scheduler
    local scene = cc.Director:getInstance():getRunningScene()
    if not scene then
        write_debug("[BytecodeDumpAll] ERROR: No running scene!")
        Reg.del(ASYNC_BC_DUMP_STATE_NAME)
        return false, "No running scene"
    end

    local action = cc.RepeatForever:create(
        cc.Sequence:create({
            cc.DelayTime:create(delay_sec),
            cc.CallFunc:create(function()
                process_batch()
            end)
        })
    )

    scene:runAction(action)
    Reg.get(ASYNC_BC_DUMP_STATE_NAME).action_ref = action

    -- Process first batch immediately
    process_batch()

    write_debug("[BytecodeDumpAll] Async bytecode dump started!")
    return true
end

function DumpCore.stop_bytecode_dump()
    local state = Reg.get(ASYNC_BC_DUMP_STATE_NAME)
    if not state then return false end

    if state.action_ref then
        local scene = cc.Director:getInstance():getRunningScene()
        if scene then
            scene:stopAction(state.action_ref)
        end
        state.action_ref = nil
    end

    state.running = false
    Reg.del(ASYNC_BC_DUMP_STATE_NAME)

    if state.write_debug then
        state.write_debug("[BytecodeDumpAll] Stopped")
    end

    return true
end

function DumpCore.cancel_bytecode_dump()
    local state = Reg.get(ASYNC_BC_DUMP_STATE_NAME)
    if not state or not state.running then
        return false, "Not running"
    end
    state.cancelled = true
    if state.write_debug then
        state.write_debug("[BytecodeDumpAll] Cancellation requested...")
    end
    return true
end

function DumpCore.is_bytecode_dump_running()
    local state = Reg.get(ASYNC_BC_DUMP_STATE_NAME)
    return state ~= nil and state.running == true
end

function DumpCore.get_bytecode_dump_progress()
    local state = Reg.get(ASYNC_BC_DUMP_STATE_NAME)
    if not state then return nil end
    return {
        running = state.running,
        current = state.current_index - 1,
        total = state.total,
        count = state.count,
        skipped = state.skipped,
        errors = state.errors,
        elapsed = os.clock() - state.start_time
    }
end

return DumpCore
