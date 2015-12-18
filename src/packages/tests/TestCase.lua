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

local string_sub = string.sub

local gbc = cc.import("#gbc")

local TestCase = cc.class("TestCase", gbc.ActionBase)

TestCase.ACCEPTED_REQUEST_TYPE = {"http", "cli"}

function TestCase:init()
    local mt = getmetatable(self)
    for name, method in pairs(mt.__index) do
        if type(method) == "function" and string_sub(name, -6) == "Action" then
            self[name] = function(...)
                self:setup()
                local res = {method(...)}
                self:teardown()
                return unpack(res)
            end
        end
    end

    math.newrandomseed()
end

function TestCase:setup()
end

function TestCase:teardown()
end

return TestCase
