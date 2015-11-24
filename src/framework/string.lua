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

local string_find  = string.find
local string_gsub  = string.gsub
local string_len   = string.len
local string_sub   = string.sub
local string_upper = string.upper
local table_insert = table.insert
local tostring     = tostring

function string.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter == "") then return false end
    local pos,arr = 1, {}
    for st, sp in function() return string_find(input, delimiter, pos, true) end do
        local str = string_sub(input, pos, st - 1)
        if str ~= "" then
            table_insert(arr, str)
        end
        pos = sp + 1
    end
    if pos <= string_len(input) then
        table_insert(arr, string_sub(input, pos))
    end
    return arr
end

local _TRIM_CHARS = " \t\n\r"

function string.ltrim(input, chars)
    chars = chars or _TRIM_CHARS
    local pattern = "^[" .. chars .. "]+"
    return string_gsub(input, pattern, "")
end

function string.rtrim(input, chars)
    chars = chars or _TRIM_CHARS
    local pattern = "[" .. chars .. "]+$"
    return string_gsub(input, pattern, "")
end

function string.trim(input, chars)
    chars = chars or _TRIM_CHARS
    local pattern = "^[" .. chars .. "]+"
    input = string_gsub(input, pattern, "")
    pattern = "[" .. chars .. "]+$"
    return string_gsub(input, pattern, "")
end

function string.ucfirst(input)
    return string_upper(string_sub(input, 1, 1)) .. string_sub(input, 2)
end
