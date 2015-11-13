--[[
z
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

local tests = cc.load("tests")
local check = tests.Check

local ConnectionTestCase = class("ConnectionTestCase", tests.TestCase)

ConnectionTestCase.ACCEPTED_REQUEST_TYPE = {"http", "cli"}

function ConnectionTestCase:setup()
end

function ConnectionTestCase:teardown()
end

-- AUTH password
-- Authenticate to the server
function ConnectionTestCase:authTest()
end

-- ECHO message
-- Echo the given string
function ConnectionTestCase:echoTest()
end

-- PING
-- Ping the server
function ConnectionTestCase:pingTest()
end

-- QUIT
-- Close the connection
function ConnectionTestCase:quitTest()
end

-- SELECT index
-- Change the selected database for the current connection
function ConnectionTestCase:selectTest()
end

return ConnectionTestCase
