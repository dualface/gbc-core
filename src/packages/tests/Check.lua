
local rawget = rawget
local rawequal = rawequal
local string_format = string.format
local _empty
local _equals
local _dump_result
local _dump_result_arr

local _M = {}

-- nil, "", {} is empty
function _M.empty(v, msg, ...)
    if not _empty(v) then
        throw(string_format(msg or "expected result is empty", ...))
    end
end

function _M.notEmpty(v, msg, ...)
    if _empty(v) then
        throw(string_format(msg or "expected result is not empty", ...))
    end
end

function _M.isNil(v, msg, ...)
    if type(v) ~= "nil" then
        throw(string_format(msg or "expected result is nil", ...))
    end
end

function _M.isTable(v, msg, ...)
    if type(v) ~= "table" then
        throw(string_format(msg or "expected result is table", ...))
    end
end

function _M.equals(actual, expected, msg, ...)
    if not _equals(actual, expected) then
        local msgs = {
            string_format(msg or "not equals", ...),
            _dump_result(actual, "actual"),
            _dump_result(expected, "expected"),
        }
        throw(table.concat(msgs, "\n"))
    end
end

function _M.notEquals(actual, expected, msg, ...)
    if _equals(actual, expected) then
        dump(actual, "actual")
        dump(expected, "expected")
        throw(string_format(msg, ...))
    end
end

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

_dump_result = function(value, label)
    return table.concat(_dump_result_arr(value, label), "\n")
end

_dump_result_arr = function(value, label)
    local result = {}
    local first = true
    dump(value, label, 99, function(s)
        if first then
            first = false
        else
            result[#result + 1] = s
        end
    end)
    return result
end

return _M
