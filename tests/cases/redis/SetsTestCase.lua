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

local SetsTestCase = class("SetsTestCase", tests.TestCase)

SetsTestCase.ACCEPTED_REQUEST_TYPE = {"http", "cli"}

function SetsTestCase:setup()
end

function SetsTestCase:teardown()
end

-- SADD key member [member ...]
-- Add one or more members to a set
function SetsTestCase:saddTest()
end

-- SCARD key
-- Get the number of members in a set
function SetsTestCase:scardTest()
end

-- SDIFF key [key ...]
-- Subtract multiple sets
function SetsTestCase:sdiffTest()
end

-- SDIFFSTORE destination key [key ...]
-- Subtract multiple sets and store the resulting set in a key
function SetsTestCase:sdiffstoreTest()
end

-- SINTER key [key ...]
-- Intersect multiple sets
function SetsTestCase:sinterTest()
end

-- SINTERSTORE destination key [key ...]
-- Intersect multiple sets and store the resulting set in a key
function SetsTestCase:sinterstoreTest()
end

-- SISMEMBER key member
-- Determine if a given value is a member of a set
function SetsTestCase:sismemberTest()
end

-- SMEMBERS key
-- Get all the members in a set
function SetsTestCase:smembersTest()
end

-- SMOVE source destination member
-- Move a member from one set to another
function SetsTestCase:smoveTest()
end

-- SPOP key [count]
-- Remove and return one or multiple random members from a set
function SetsTestCase:spopTest()
end

-- SRANDMEMBER key [count]
-- Get one or multiple random members from a set
function SetsTestCase:srandmemberTest()
end

-- SREM key member [member ...]
-- Remove one or more members from a set
function SetsTestCase:sremTest()
end

-- SUNION key [key ...]
-- Add multiple sets
function SetsTestCase:sunionTest()
end

-- SUNIONSTORE destination key [key ...]
-- Add multiple sets and store the resulting set in a key
function SetsTestCase:sunionstoreTest()
end

-- SSCAN key cursor [MATCH pattern] [COUNT count]
-- Incrementally iterate Set elements
function SetsTestCase:sscanTest()
end

return SetsTestCase
