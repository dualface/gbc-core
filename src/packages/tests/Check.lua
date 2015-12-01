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

local rawget = rawget
local rawequal = rawequal
local string_format = string.format
local _empty
local _equals
local _contains, _containsintable
local _dumpresult
local _dumpresultarr
local _formatmsg

local _M = {}

-- nil, "", {} is empty
function _M.empty(v, msg)
    if _empty(v) then return end
    cc.throw("expected is empty, actual is '%s'%s", tostring(v), _formatmsg(msg))
end

function _M.notEmpty(v, msg)
    if not _empty(v) then return end
    cc.throw("expected is not empty, actual is '%s'%s", tostring(v), _formatmsg(msg))
end

function _M.isTrue(v, msg)
    if v == true then return end
    cc.throw("expected is true, actual is '%s'%s", tostring(v), _formatmsg(msg))
end

function _M.isFalse(v, msg)
    if v == false then return end
    cc.throw("expected is false, actual is '%s'%s", tostring(v), _formatmsg(msg))
end

function _M.isNil(v, msg)
    if type(v) == "nil" then return end
    cc.throw("expected is nil, actual is '%s'%s", type(v), _formatmsg(msg))
end

function _M.isFunction(v, msg)
    if type(v) == "function" then return end
    cc.throw("expected is function, actual is '%s'%s", type(v), _formatmsg(msg))
end

function _M.isTable(v, msg)
    if type(v) == "table" then return end
    cc.throw("expected is table, actual is '%s'%s", type(v), _formatmsg(msg))
end

function _M.isInt(v, msg)
    if type(v) == "number" and math.floor(v) == v then return end
    cc.throw("expected is integer, actual is '%s'%s", tostring(v), _formatmsg(msg))
end

function _M.isPosInt(v, msg)
    if type(v) == "number" and math.floor(v) == v and v >= 0 then return end
    cc.throw("expected is positive integer, actual is '%s'%s", tostring(v), _formatmsg(msg))
end

function _M.isString(v, msg)
    if type(v) == "string" then return end
    cc.throw("expected is string, actual is '%s'%s", tostring(v), _formatmsg(msg))
end

function _M.greaterThan(actual, expected, msg)
    if type(actual) == "number" and type(expected) == "number" and actual > expected then return end
    cc.throw("expected is '%s' > '%s'%s", tostring(actual), tostring(expected), _formatmsg(msg))
end

function _M.equals(actual, expected, msg)
    if _equals(actual, expected) then return end
    local msgs = {
        "should be equals" .. _formatmsg(msg),
        _dumpresult(actual, "actual"),
        _dumpresult(expected, "expected"),
    }
    cc.throw(table.concat(msgs, "\n"))
end

function _M.notEquals(actual, expected, msg)
    if not _equals(actual, expected) then return end
    local msgs = {
        "should be not equals" .. _formatmsg(msg),
        _dumpresult(actual, "actual"),
        _dumpresult(expected, "expected"),
    }
    cc.throw(table.concat(msgs, "\n"))
end

function _M.contains(actual, expected, msg)
    if _contains(actual, expected) then return end
    local msgs = {
        string_format("expected contains '%s'%s", tostring(expected), _formatmsg(msg)),
        _dumpresult(actual, "actual"),
        _dumpresult(expected, "expected"),
    }
    cc.throw(table.concat(msgs, "\n"))
end

function _M.notContains(actual, expected, msg)
    if not _contains(actual, expected) then return end
    local msgs = {
        string_format("expected not contains '%s'%s", tostring(needle), _formatmsg(msg)),
        _dumpresult(actual, "actual"),
        _dumpresult(expected, "expected"),
    }
    cc.throw(table.concat(msgs, "\n"))
end

-- private

_empty = function(v)
    local t = type(v)
    local test = true
    while true do
        if t == "nil" then break end
        if t == "string" and v == "" then break end
        if t ~= "table" then
            test = false
            break
        end

        for k, v in pairs(v) do
            test = false
            break
        end

        break
    end

    return test
end

_equals = function(actual, expected)
    local at = type(actual)
    local et = type(expected)
    if at ~= et then return false end

    if at == "table" then
        local akeys = {}
        -- check all values in actual exists in expected
        for k, v in pairs(actual) do
            akeys[k] = true
            if not _equals(v, rawget(expected, k)) then return false end
        end
        -- check expected not have more keys
        for k, v in pairs(expected) do
            if akeys[k] ~= true then return false end
        end
        return true
    elseif at == "number" then
        return tostring(actual) == tostring(expected)
    else
        return actual == expected
    end
end

_contains = function(actual, expected)
    if type(actual) == "table" then
        return _containsintable(actual, expected)
    end
    return string.find(tostring(actual), tostring(expected), 1, true)
end

_containsintable = function(arr, needle)
    for _, v in pairs(arr) do
        if needle == v then return true end
    end
    return false
end

_dumpresult = function(value, label)
    return table.concat(_dumpresultarr(value, label), "\n")
end

_dumpresultarr = function(value, label)
    local result = {}
    local first = true
    cc.dump(value, label, 99, function(s)
        if first then
            first = false
        else
            result[#result + 1] = s
        end
    end)
    return result
end

_formatmsg = function(msg)
    if msg then
        return ", " .. tostring(msg)
    else
        return ""
    end
end

return _M
