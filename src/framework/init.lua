--[[

Copyright (c) 2015 gameboxcloud.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

local debug_getlocal = debug.getlocal
local string_byte    = string.byte
local string_find    = string.find
local string_format  = string.format
local string_lower   = string.lower
local string_sub     = string.sub
local table_concat   = table.concat

cc = cc or {}

socket = {} -- avoid require("socket") warning
-- export global variable
local _g = _G
cc.exports = {}
setmetatable(cc.exports, {
    __newindex = function(_, name, value)
        rawset(_g, name, value)
    end,

    __index = function(_, name)
        return rawget(_g, name)
    end
})

-- disable create unexpected global variable
setmetatable(_g, {
    __newindex = function(_, name, value)
        local msg = string_format("USE \"cc.exports.%s = <value>\" INSTEAD OF SET GLOBAL VARIABLE", name)
        print(debug.traceback(msg, 2))
        if not ngx then print("") end
    end
})

--

cc.DEBUG_ERROR   = 0
cc.DEBUG_WARN    = 1
cc.DEBUG_INFO    = 2
cc.DEBUG_VERBOSE = 3
cc.DEBUG         = cc.DEBUG_DEBUG

cc.GBC_VERSION = "0.8.0"

-- loader
local _loaded = {}
function cc.load(name)
    name = string_lower(name)
    if not _loaded[name] then
        local modulename = string_format("packages.%s.%s", name, name)
        _loaded[name] = require(modulename)
    end
    return _loaded[name]
end

function cc.import(name, current)
    if string_byte(name) ~= 46 --[[ "." ]] then
        return require(name)
    end

    if not current then
        local _, v = debug_getlocal(3, 1)
        current = v
    end

    local parts = {}
    local offset = 1
    while true do
        local pos = string_find(current, ".", offset, true)
        if pos then
            parts[#parts + 1] = string_sub(current, offset, pos - 1)
            offset = pos + 1
        else
            parts[#parts + 1] = string_sub(current, offset)
            break
        end
    end

    offset = 1
    while string_byte(name, offset) == 46 do
        table.remove(parts)
        offset = offset + 1
    end

    parts[#parts + 1] = string_sub(name, offset)
    return require(table_concat(parts, "."))
end

-- load basics modules
require("framework.class")
require("framework.table")
require("framework.string")
require("framework.debug")
require("framework.math")
require("framework.ctype")
require("framework.os")
require("framework.io")
