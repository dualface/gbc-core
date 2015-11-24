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

local math_ceil  = math.ceil
local math_floor = math.floor
local ok, socket = pcall(function()
    return require("socket")
end)

function math.round(value)
    value = tonumber(value) or 0
    return math_floor(value + 0.5)
end

function math.trunc(x)
    if x <= 0 then
        return math_ceil(x)
    end
    if math_ceil(x) == x then
        x = math_ceil(x)
    else
        x = math_ceil(x) - 1
    end
    return x
end

function math.newrandomseed()
    if socket then
        math.randomseed(socket.gettime() * 1000)
    else
        math.randomseed(os.time())
    end

    math.random()
    math.random()
    math.random()
    math.random()
end
