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

local HashesTestCase = class("HashesTestCase", tests.TestCase)

HashesTestCase.ACCEPTED_REQUEST_TYPE = {"http", "cli"}

function HashesTestCase:setup()
end

function HashesTestCase:teardown()
end

-- HDEL key field [field ...]
-- Delete one or more hash fields
function HashesTestCase:hdelTest()
end

-- HEXISTS key field
-- Determine if a hash field exists
function HashesTestCase:hexistsTest()
end

-- HGET key field
-- Get the value of a hash field
function HashesTestCase:hgetTest()
end

-- HGETALL key
-- Get all the fields and values in a hash
function HashesTestCase:hgetallTest()
end

-- HINCRBY key field increment
-- Increment the integer value of a hash field by the given number
function HashesTestCase:hincrbyTest()
end

-- HINCRBYFLOAT key field increment
-- Increment the float value of a hash field by the given amount
function HashesTestCase:hincrbyfloatTest()
end

-- HKEYS key
-- Get all the fields in a hash
function HashesTestCase:hkeysTest()
end

-- HLEN key
-- Get the number of fields in a hash
function HashesTestCase:hlenTest()
end

-- HMGET key field [field ...]
-- Get the values of all the given hash fields
function HashesTestCase:hmgetTest()
end

-- HMSET key field value [field value ...]
-- Set multiple hash fields to multiple values
function HashesTestCase:hmsetTest()
end

-- HSET key field value
-- Set the string value of a hash field
function HashesTestCase:hsetTest()
end

-- HSETNX key field value
-- Set the value of a hash field, only if the field does not exist
function HashesTestCase:hsetnxTest()
end

-- HSTRLEN key field
-- Get the length of the value of a hash field
function HashesTestCase:hstrlenTest()
end

-- HVALS key
-- Get all the values in a hash
function HashesTestCase:hvalsTest()
end

-- HSCAN key cursor [MATCH pattern] [COUNT count]
-- Incrementally iterate hash fields and associated values
function HashesTestCase:hscanTest()
end

return HashesTestCase
