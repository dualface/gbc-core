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

local StringsTestCase = class("StringsTestCase", tests.TestCase)

StringsTestCase.ACCEPTED_REQUEST_TYPE = {"http", "cli"}

function StringsTestCase:setup()
end

function StringsTestCase:teardown()
end

-- APPEND key value
-- Append a value to a key
function StringsTestCase:appendTest()
end

-- BITCOUNT key [start end]
-- Count set bits in a string
function StringsTestCase:bitcountTest()
end

-- BITOP operation destkey key [key ...]
-- Perform bitwise operations between strings
function StringsTestCase:bitopTest()
end

-- BITPOS key bit [start] [end]
-- Find first bit set or clear in a string
function StringsTestCase:bitposTest()
end

-- DECR key
-- Decrement the integer value of a key by one
function StringsTestCase:decrTest()
end

-- DECRBY key decrement
-- Decrement the integer value of a key by the given number
function StringsTestCase:decrbyTest()
end

-- GET key
-- Get the value of a key
function StringsTestCase:getTest()
end

-- GETBIT key offset
-- Returns the bit value at offset in the string value stored at key
function StringsTestCase:getbitTest()
end

-- GETRANGE key start end
-- Get a substring of the string stored at a key
function StringsTestCase:getrangeTest()
end

-- GETSET key value
-- Set the string value of a key and return its old value
function StringsTestCase:getsetTest()
end

-- INCR key
-- Increment the integer value of a key by one
function StringsTestCase:incrTest()
end

-- INCRBY key increment
-- Increment the integer value of a key by the given amount
function StringsTestCase:incrbyTest()
end

-- INCRBYFLOAT key increment
-- Increment the float value of a key by the given amount
function StringsTestCase:incrbyfloatTest()
end

-- MGET key [key ...]
-- Get the values of all the given keys
function StringsTestCase:mgetTest()
end

-- MSET key value [key value ...]
-- Set multiple keys to multiple values
function StringsTestCase:msetTest()
end

-- MSETNX key value [key value ...]
-- Set multiple keys to multiple values, only if none of the keys exist
function StringsTestCase:msetnxTest()
end

-- PSETEX key milliseconds value
-- Set the value and expiration in milliseconds of a key
function StringsTestCase:psetexTest()
end

-- SET key value [EX seconds] [PX milliseconds] [NX|XX]
-- Set the string value of a key
function StringsTestCase:setTest()
end

-- SETBIT key offset value
-- Sets or clears the bit at offset in the string value stored at key
function StringsTestCase:setbitTest()
end

-- SETEX key seconds value
-- Set the value and expiration of a key
function StringsTestCase:setexTest()
end

-- SETNX key value
-- Set the value of a key, only if the key does not exist
function StringsTestCase:setnxTest()
end

-- SETRANGE key offset value
-- Overwrite part of a string at key starting at the specified offset
function StringsTestCase:setrangeTest()
end

-- STRLEN key
-- Get the length of the value stored in a key
function StringsTestCase:strlenTest()
end

return StringsTestCase
