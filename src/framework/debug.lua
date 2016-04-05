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

local ngx = ngx
local ngx_log = nil
if ngx then
    ngx_log = ngx.log
end

local cc              = cc
local debug_traceback = debug.traceback
local error           = error
local print           = print
local string_format   = string.format
local string_rep      = string.rep
local string_upper    = string.upper
local table_concat    = table.concat
local tostring        = tostring

function cc.throw(fmt, ...)
    local msg
    if #{...} == 0 then
        msg = fmt
    else
        msg = string_format(fmt, ...)
    end
    if cc.DEBUG > cc.DEBUG_WARN then
        error(msg, 2)
    else
        error(msg, 0)
    end
end

local function _dump_value(v)
    if type(v) == "string" then
        v = "\"" .. v .. "\""
    end
    return tostring(v)
end

function cc.dump(value, desciption, nesting, _print)
    if type(nesting) ~= "number" then nesting = 3 end
    _print = _print or print

    local lookup = {}
    local result = {}
    local traceback = string.split(debug_traceback("", 2), "\n")
    _print("dump from: " .. string.trim(traceback[2]))

    local function _dump(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string_rep(" ", keylen - string.len(_dump_value(desciption)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string_format("%s%s%s = %s", indent, _dump_value(desciption), spc, _dump_value(value))
        elseif lookup[tostring(value)] then
            result[#result +1 ] = string_format("%s%s%s = *REF*", indent, _dump_value(desciption), spc)
        else
            lookup[tostring(value)] = true
            if nest > nesting then
                result[#result +1 ] = string_format("%s%s = *MAX NESTING*", indent, _dump_value(desciption))
            else
                result[#result +1 ] = string_format("%s%s = {", indent, _dump_value(desciption))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = _dump_value(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    _dump(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string_format("%s}", indent)
            end
        end
    end
    _dump(value, desciption, "- ", 1)

    for i, line in ipairs(result) do
        _print(line)
    end
end

function cc.printf(fmt, ...)
    print(string_format(tostring(fmt), ...))
end

function cc.printlog(tag, fmt, ...)
    fmt = tostring(fmt)
    if ngx_log then
        if tag == "ERR" and cc.DEBUG > cc.DEBUG_WARN then
            ngx_log(ngx.ERR, string_format(fmt, ...) .. "\n" .. debug_traceback("", 3))
        else
            ngx_log(ngx[tag], string_format(fmt, ...))
        end
        return
    end

    local t = {
        "[",
        string_upper(tostring(tag)),
        "] ",
        string_format(fmt, ...)
    }
    if tag == "ERR" then
        table_insert(t, debug_traceback("", 2))
    end
    print(table.concat(t))
end

local _printlog = cc.printlog

function cc.printerror(fmt, ...)
    _printlog("ERR", fmt, ...)
end

function cc.printdebug(fmt, ...)
    if cc.DEBUG >= cc.DEBUG_VERBOSE then
        _printlog("DEBUG", fmt, ...)
    end
end

function cc.printinfo(fmt, ...)
    if cc.DEBUG >= cc.DEBUG_INFO then
        _printlog("INFO", fmt, ...)
    end
end

function cc.printwarn(fmt, ...)
    if cc.DEBUG >= cc.DEBUG_WARN then
        _printlog("WARN", fmt, ...)
    end
end
