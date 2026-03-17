local _tl_compat
if (tonumber((_VERSION or ""):match("[%d.]*$")) or 0) < 5.3 then
    local p, m = pcall(require, "compat53.module")
    if p then
        _tl_compat = m
    end
end

local math = _tl_compat and _tl_compat.math or math
local pcall = _tl_compat and _tl_compat.pcall or pcall
local string = _tl_compat and _tl_compat.string or string
local table = _tl_compat and _tl_compat.table or table

local type = type
local pairs = pairs
local tostring = tostring
local getmetatable = getmetatable
local setmetatable = setmetatable
local debug = debug

local inspect = {Options = {}}

inspect._VERSION = "inspect.lua 3.1.0+custom"
inspect._URL = "http://github.com/kikito/inspect.lua"
inspect._DESCRIPTION = "human-readable representations of tables"
inspect._LICENSE =
    [[
  MIT LICENSE

  Copyright (c) 2022 Enrique García Cota

  Permission is hereby granted, free of charge, to any person obtaining a
  copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be included
  in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

inspect.KEY =
    setmetatable(
    {},
    {
        __tostring = function()
            return "inspect.KEY"
        end
    }
)

inspect.METATABLE =
    setmetatable(
    {},
    {
        __tostring = function()
            return "inspect.METATABLE"
        end
    }
)

local rep = string.rep
local match = string.match
local char = string.char
local gsub = string.gsub
local fmt = string.format

local sbavailable, stringbuffer = pcall(require, "string.buffer")
local buffnew
local puts
local render

if sbavailable then
    buffnew = stringbuffer.new
    puts = function(buf, str)
        buf:put(str)
    end
    render = function(buf)
        return buf:get()
    end
else
    buffnew = function()
        return {n = 0}
    end
    puts = function(buf, str)
        buf.n = buf.n + 1
        buf[buf.n] = str
    end
    render = function(buf)
        return table.concat(buf)
    end
end

local _rawget
if rawget then
    _rawget = rawget
else
    _rawget = function(t, k)
        return t[k]
    end
end

local function isInstanceLike(x)
    local tx = type(x)
    return tx == "instance" or tx == "class"
end

local function isContainer(x)
    local tx = type(x)
    return tx == "table" or tx == "list" or tx == "dict" or tx == "tuple"
end

local function smartQuote(str)
    if match(str, '"') and not match(str, "'") then
        return "'" .. str .. "'"
    end
    return '"' .. gsub(str, '"', '\\"') .. '"'
end

local shortControlCharEscapes = {
    ["\a"] = "\\a",
    ["\b"] = "\\b",
    ["\f"] = "\\f",
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t",
    ["\v"] = "\\v",
    ["\127"] = "\\127"
}

local longControlCharEscapes = {
    ["\127"] = "\127"
}

for i = 0, 31 do
    local ch = char(i)
    if not shortControlCharEscapes[ch] then
        shortControlCharEscapes[ch] = "\\" .. i
        longControlCharEscapes[ch] = fmt("\\%03d", i)
    end
end

local function escape(str)
    return (gsub(gsub(gsub(str, "\\", "\\\\"), "(%c)%f[0-9]", longControlCharEscapes), "%c", shortControlCharEscapes))
end

local luaKeywords = {}
for k in ([[ and break do else elseif end false for function goto if
             in local nil not or repeat return then true until while
]]):gmatch(
    "%w+"
) do
    luaKeywords[k] = true
end

local function isIdentifier(str)
    return type(str) == "string" and not (not str:match("^[_%a][_%a%d]*$")) and not luaKeywords[str]
end

local flr = math.floor
local function isSequenceKey(k, sequenceLength)
    return type(k) == "number" and flr(k) == k and 1 <= k and k <= sequenceLength
end

local function safe_pairs(obj)
    local ok, a, b, c = pcall(pairs, obj)
    if ok then
        return true, a, b, c
    end
    return false
end

local function formatFunction(fn)
    if not debug or not debug.getinfo then
        return tostring(fn)
    end

    local ok, info = pcall(debug.getinfo, fn, "uSn")
    if not ok or not info then
        return tostring(fn)
    end

    if info.what == "C" then
        return "C function"
    end

    local nparams = info.nparams
    local isvararg = info.isvararg

    if type(nparams) ~= "number" then
        return "function(?)"
    end

    local parts = {}
    for i = 1, nparams do
        parts[i] = "arg" .. i
    end

    if isvararg then
        parts[#parts + 1] = "..."
    end

    return "function(" .. table.concat(parts, ", ") .. ")"
end

local defaultTypeOrders = {
    ["number"] = 1,
    ["boolean"] = 2,
    ["string"] = 3,
    ["table"] = 4,
    ["list"] = 4,
    ["dict"] = 4,
    ["function"] = 5,
    ["userdata"] = 6,
    ["thread"] = 7
}

local function sortKeys(a, b)
    local ta, tb = type(a), type(b)

    if ta == tb and (ta == "string" or ta == "number") then
        return a < b
    end

    local dta = defaultTypeOrders[ta] or 100
    local dtb = defaultTypeOrders[tb] or 100

    return dta == dtb and ta < tb or dta < dtb
end

local function getKeys(t)
    local tx = type(t)
    local seqLen = 0

    if tx == "table" then
        local i = 1
        while _rawget(t, i) ~= nil do
            seqLen = i
            i = i + 1
        end
    elseif tx == "list" or tx == "dict" then
        local seen = {}
        local ok, iter, state, init = safe_pairs(t)
        if ok then
            for k in iter, state, init do
                if type(k) == "number" and flr(k) == k and k >= 1 then
                    seen[k] = true
                end
            end
        end
        while seen[seqLen + 1] do
            seqLen = seqLen + 1
        end
    else
        seqLen = 0
    end

    local keys, keysLen = {}, 0
    if tx == "table" then
        for k in next, t, nil do
            if not isSequenceKey(k, seqLen) then
                keysLen = keysLen + 1
                keys[keysLen] = k
            end
        end
    else
        local ok, iter, state, init = safe_pairs(t)
        if ok then
            for k in iter, state, init do
                if not isSequenceKey(k, seqLen) then
                    keysLen = keysLen + 1
                    keys[keysLen] = k
                end
            end
        end
    end

    table.sort(keys, sortKeys)
    return keys, keysLen, seqLen
end

local function countCycles(x, cycles, depth)
    if isContainer(x) then
        if cycles[x] then
            cycles[x] = cycles[x] + 1
        else
            cycles[x] = 1
            if depth > 0 then
                if type(x) == "table" then
                    for k, v in next, x, nil do
                        countCycles(k, cycles, depth - 1)
                        countCycles(v, cycles, depth - 1)
                    end
                else
                    local ok, iter, state, init = safe_pairs(x)
                    if ok then
                        for k, v in iter, state, init do
                            countCycles(k, cycles, depth - 1)
                            countCycles(v, cycles, depth - 1)
                        end
                    end
                end
                countCycles(getmetatable(x), cycles, depth - 1)
            end
        end
    end
end

local function makePath(path, a, b)
    local newPath = {}
    local len = #path
    for i = 1, len do
        newPath[i] = path[i]
    end

    newPath[len + 1] = a
    newPath[len + 2] = b

    return newPath
end

local function processRecursive(process, item, path, visited)
    if item == nil then
        return nil
    end
    if visited[item] then
        return visited[item]
    end

    local processed = process(item, path)
    if isContainer(processed) then
        local processedCopy = {}
        visited[item] = processedCopy
        local processedKey

        if type(processed) == "table" then
            for k, v in next, processed, nil do
                processedKey = processRecursive(process, k, makePath(path, k, inspect.KEY), visited)
                if processedKey ~= nil then
                    processedCopy[processedKey] = processRecursive(process, v, makePath(path, processedKey), visited)
                end
            end
        else
            local ok, iter, state, init = safe_pairs(processed)
            if ok then
                for k, v in iter, state, init do
                    processedKey = processRecursive(process, k, makePath(path, k, inspect.KEY), visited)
                    if processedKey ~= nil then
                        processedCopy[processedKey] =
                            processRecursive(process, v, makePath(path, processedKey), visited)
                    end
                end
            end
        end

        local mt = processRecursive(process, getmetatable(processed), makePath(path, inspect.METATABLE), visited)
        if type(mt) ~= "table" then
            mt = nil
        end
        setmetatable(processedCopy, mt)
        processed = processedCopy
    end
    return processed
end

local function is_pairable(obj)
    return pcall(
        function()
            for _, _ in pairs(obj) do
                break
            end
        end
    )
end

local function extractInstanceOrClass(obj, inspector)
    local ok_name, name_str = pcall(tostring, obj)
    name_str = ok_name and name_str or "<instance ?>"

    -- Only deep-inspect objects whose tostring looks like "<instance ... >" or "<class ... >".
    -- Simple engine value types (e.g. Vector3 "(1,2,3)") just get their tostring representation.
    local tv = type(obj)
    local is_complex = (tv == "instance" and name_str:find("instance"))
                    or (tv == "class"    and name_str:find("class"))
    if not is_complex then
        return name_str
    end

    local out = {
        __name__ = name_str,
        __type__ = tv,
        __properties__ = {},
        __methods__ = {}
    }

    local deep = inspector and inspector.inspect_instances_deep

    --------------------------------------------------
    -- PROPERTIES
    --------------------------------------------------
    local ok_has_props, has_props =
        pcall(
        function()
            return obj._query_properties ~= nil
        end
    )

    if ok_has_props and has_props then
        local ok_props, props =
            pcall(
            function()
                return obj:_query_properties()
            end
            )

        if ok_props and props ~= nil then
            if is_pairable(props) then
                pcall(
                    function()
                        for _, name in pairs(props) do
                            local val
                            if deep then
                                local ok_val, v = pcall(function() return obj[name] end)
                                if not ok_val then
                                    val = "<error reading>"
                                elseif isInstanceLike(v) then
                                    local ok_s, s = pcall(tostring, v)
                                    val = ok_s and s or "<instance ?>"
                                else
                                    val = v
                                end
                            else
                                val = "<value>"
                            end
                            out.__properties__[tostring(name)] = val
                        end
                    end
                )
            else
                out.__properties__["<query_properties>"] = tostring(props)
            end
        end
    end

    --------------------------------------------------
    -- METHODS / PAIRABLE MEMBERS (pairs() on engine instances can crash - only when deep)
    --------------------------------------------------
    if deep then
        local ok_pairable = pcall(
            function()
                for _ in pairs(obj) do
                    break
                end
            end
        )
        if ok_pairable then
            pcall(
                function()
                    for k, v in pairs(obj) do
                        if isInstanceLike(v) then
                            local ok_s, s = pcall(tostring, v)
                            out.__methods__[k] = ok_s and s or "<instance ?>"
                        else
                            out.__methods__[k] = v
                        end
                    end
                end
            )
        end
    end

    if next(out.__properties__) == nil then
        out.__properties__ = nil
    end

    if next(out.__methods__) == nil then
        out.__methods__ = nil
    end

    return out
end

local Inspector = {}
local Inspector_mt = {__index = Inspector}

local function tabify(inspector)
    puts(inspector.buf, inspector.newline .. rep(inspector.indent, inspector.level))
end

function Inspector:getId(v)
    local id = self.ids[v]
    local ids = self.ids
    if not id then
        local tv = type(v)
        id = (ids[tv] or 0) + 1
        ids[v], ids[tv] = id, id
    end
    return tostring(id)
end

function Inspector:putValue(v)
    local buf = self.buf
    local tv = type(v)

    if tv == "string" then
        puts(buf, smartQuote(escape(v)))
    elseif tv == "number" or tv == "boolean" or tv == "nil" or tv == "cdata" or tv == "ctype" then
        puts(buf, tostring(v))
    elseif tv == "function" then
        puts(buf, formatFunction(v))
    elseif isInstanceLike(v) then
        if self.level >= self.depth then
            puts(buf, "{...}")
            return
        end

        if self.cycles[v] and self.cycles[v] > 1 and not self.ids[v] then
            puts(buf, fmt("<%d>", self:getId(v)))
        end

        self:putValue(extractInstanceOrClass(v, self))
    elseif isContainer(v) and not self.ids[v] then
        local t = v

        if t == inspect.KEY or t == inspect.METATABLE then
            puts(buf, tostring(t))
            return
        end

        if self.level >= self.depth then
            puts(buf, "{...}")
            return
        end

        if self.cycles[t] and self.cycles[t] > 1 then
            puts(buf, fmt("<%d>", self:getId(t)))
        end

        local keys, keysLen, seqLen = getKeys(t)

        puts(buf, "{")
        self.level = self.level + 1

        for i = 1, seqLen + keysLen do
            if i > 1 then
                puts(buf, ",")
                if not self.pretty then
                    puts(buf, " ")
                end
            end

            if i <= seqLen then
                if self.pretty then
                    puts(buf, " ")
                end
                self:putValue(t[i])
            else
                local k = keys[i - seqLen]
                if self.pretty then
                    tabify(self)
                end
                if isIdentifier(k) then
                    puts(buf, k)
                else
                    puts(buf, "[")
                    self:putValue(k)
                    puts(buf, "]")
                end
                puts(buf, self.pretty and " = " or "=")
                self:putValue(t[k])
            end
        end

        local mt = self.show_metatable and getmetatable(t) or nil
        if type(mt) == "table" then
            if seqLen + keysLen > 0 then
                puts(buf, ",")
                if not self.pretty then
                    puts(buf, " ")
                end
            end
            if self.pretty then
                tabify(self)
            end
            puts(buf, self.pretty and "<metatable> = " or "<metatable>=")
            self:putValue(mt)
        end

        self.level = self.level - 1

        if self.pretty and (keysLen > 0 or type(mt) == "table") then
            tabify(self)
        elseif self.pretty and seqLen > 0 then
            puts(buf, " ")
        end

        puts(buf, "}")
    else
        puts(buf, tostring(v))
    end
end

function inspect.inspect(root, options)
    options = options or {}

    local pretty = options.pretty or false
    local depth = options.depth or math.huge
    local newline = pretty and (options.newline or "\n") or ""
    local indent = pretty and (options.indent or "  ") or ""
    local process = options.process
    local show_metatable = options.show_metatable or false
    -- Default false: obj[name] on engine instances (e.g. BoneColliderResult) can native-crash, uncatchable by pcall
    local inspect_instances_deep = options.inspect_instances_deep or false

    if process then
        root = processRecursive(process, root, {}, {})
    end

    local cycles = {}
    countCycles(root, cycles, depth)

    local inspector =
        setmetatable(
        {
            buf = buffnew(),
            ids = {},
            cycles = cycles,
            depth = depth,
            level = 0,
            newline = newline,
            indent = indent,
            pretty = pretty,
            show_metatable = show_metatable,
            inspect_instances_deep = inspect_instances_deep
        },
        Inspector_mt
    )

    inspector:putValue(root)

    return render(inspector.buf)
end

setmetatable(
    inspect,
    {
        __call = function(_, root, options)
            return inspect.inspect(root, options)
        end
    }
)

return inspect
