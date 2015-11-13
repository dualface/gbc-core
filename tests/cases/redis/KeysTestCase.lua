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

local KeysTestCase = class("KeysTestCase", tests.TestCase)

KeysTestCase.ACCEPTED_REQUEST_TYPE = {"http", "cli"}

function KeysTestCase:setup()
end

function KeysTestCase:teardown()
end

-- DEL key [key ...]
-- Delete a key
function KeysTestCase:delTest()
end

-- DUMP key
-- Return a serialized version of the value stored at the specified key.
function KeysTestCase:dumpTest()
end

-- EXISTS key [key ...]
-- Determine if a key exists
function KeysTestCase:existsTest()
end

-- EXPIRE key seconds
-- Set a key's time to live in seconds
function KeysTestCase:expireTest()
end

-- EXPIREAT key timestamp
-- Set the expiration for a key as a UNIX timestamp
function KeysTestCase:expireatTest()
end

-- KEYS pattern
-- Find all keys matching the given pattern
function KeysTestCase:keysTest()
end

-- MIGRATE host port key destination-db timeout [COPY] [REPLACE]
-- Atomically transfer a key from a Redis instance to another one.
function KeysTestCase:migrateTest()
end

-- MOVE key db
-- Move a key to another database
function KeysTestCase:moveTest()
end

-- OBJECT subcommand [arguments [arguments ...]]
-- Inspect the internals of Redis objects
function KeysTestCase:objectTest()
end

-- PERSIST key
-- Remove the expiration from a key
function KeysTestCase:persistTest()
end

-- PEXPIRE key milliseconds
-- Set a key's time to live in milliseconds
function KeysTestCase:pexpireTest()
end

-- PEXPIREAT key milliseconds-timestamp
-- Set the expiration for a key as a UNIX timestamp specified in milliseconds
function KeysTestCase:pexpireatTest()
end

-- PTTL key
-- Get the time to live for a key in milliseconds
function KeysTestCase:pttlTest()
end

-- RANDOMKEY
-- Return a random key from the keyspace
function KeysTestCase:randomkeyTest()
end

-- RENAME key newkey
-- Rename a key
function KeysTestCase:renameTest()
end

-- RENAMENX key newkey
-- Rename a key, only if the new key does not exist
function KeysTestCase:renamenxTest()
end

-- RESTORE key ttl serialized-value [REPLACE]
-- Create a key using the provided serialized value, previously obtained using DUMP.
function KeysTestCase:restoreTest()
end

-- SORT key [BY pattern] [LIMIT offset count] [GET pattern [GET pattern ...]] [ASC|DESC] [ALPHA] [STORE destination]
-- Sort the elements in a list, set or sorted set
function KeysTestCase:sortTest()
end

-- TTL key
-- Get the time to live for a key
function KeysTestCase:ttlTest()
end

-- TYPE key
-- Determine the type stored at key
function KeysTestCase:typeTest()
end

-- WAIT numslaves timeout
-- Wait for the synchronous replication of all the write commands sent in the context of the current connection
function KeysTestCase:waitTest()
end

-- SCAN cursor [MATCH pattern] [COUNT count]
-- Incrementally iterate the keys space
function KeysTestCase:scanTest()
end

return KeysTestCase
