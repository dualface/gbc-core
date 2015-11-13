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

local ListsTestCase = class("ListsTestCase", tests.TestCase)

ListsTestCase.ACCEPTED_REQUEST_TYPE = {"http", "cli"}

function ListsTestCase:setup()
end

function ListsTestCase:teardown()
end

-- BLPOP key [key ...] timeout
-- Remove and get the first element in a list, or block until one is available
function ListsTestCase:blpopTest()
end

-- BRPOP key [key ...] timeout
-- Remove and get the last element in a list, or block until one is available
function ListsTestCase:brpopTest()
end

-- BRPOPLPUSH source destination timeout
-- Pop a value from a list, push it to another list and return it; or block until one is available
function ListsTestCase:brpoplpushTest()
end

-- LINDEX key index
-- Get an element from a list by its index
function ListsTestCase:lindexTest()
end

-- LINSERT key BEFORE|AFTER pivot value
-- Insert an element before or after another element in a list
function ListsTestCase:linsertTest()
end

-- LLEN key
-- Get the length of a list
function ListsTestCase:llenTest()
end

-- LPOP key
-- Remove and get the first element in a list
function ListsTestCase:lpopTest()
end

-- LPUSH key value [value ...]
-- Prepend one or multiple values to a list
function ListsTestCase:lpushTest()
end

-- LPUSHX key value
-- Prepend a value to a list, only if the list exists
function ListsTestCase:lpushxTest()
end

-- LRANGE key start stop
-- Get a range of elements from a list
function ListsTestCase:lrangeTest()
end

-- LREM key count value
-- Remove elements from a list
function ListsTestCase:lremTest()
end

-- LSET key index value
-- Set the value of an element in a list by its index
function ListsTestCase:lsetTest()
end

-- LTRIM key start stop
-- Trim a list to the specified range
function ListsTestCase:ltrimTest()
end

-- RPOP key
-- Remove and get the last element in a list
function ListsTestCase:rpopTest()
end

-- RPOPLPUSH source destination
-- Remove the last element in a list, prepend it to another list and return it
function ListsTestCase:rpoplpushTest()
end

-- RPUSH key value [value ...]
-- Append one or multiple values to a list
function ListsTestCase:rpushTest()
end

-- RPUSHX key value
-- Append a value to a list, only if the list exists
function ListsTestCase:rpushxTest()
end

return ListsTestCase
