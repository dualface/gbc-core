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

local ServerTestCase = class("ServerTestCase", tests.TestCase)

ServerTestCase.ACCEPTED_REQUEST_TYPE = {"http", "cli"}

function ServerTestCase:setup()
end

function ServerTestCase:teardown()
end

-- BGREWRITEAOF
-- Asynchronously rewrite the append-only file
function ServerTestCase:bgrewriteaofTest()
end

-- BGSAVE
-- Asynchronously save the dataset to disk
function ServerTestCase:bgsaveTest()
end

-- CLIENT KILL [ip:port] [ID client-id] [TYPE normal|slave|pubsub] [ADDR ip:port] [SKIPME yes/no]
-- Kill the connection of a client
function ServerTestCase:clientTest()
end

-- CLIENT LIST
-- Get the list of client connections
function ServerTestCase:clientTest()
end

-- CLIENT GETNAME
-- Get the current connection name
function ServerTestCase:clientTest()
end

-- CLIENT PAUSE timeout
-- Stop processing commands from clients for some time
function ServerTestCase:clientTest()
end

-- CLIENT SETNAME connection-name
-- Set the current connection name
function ServerTestCase:clientTest()
end

-- COMMAND
-- Get array of Redis command details
function ServerTestCase:commandTest()
end

-- COMMAND COUNT
-- Get total number of Redis commands
function ServerTestCase:commandTest()
end

-- COMMAND GETKEYS
-- Extract keys given a full Redis command
function ServerTestCase:commandTest()
end

-- COMMAND INFO command-name [command-name ...]
-- Get array of specific Redis command details
function ServerTestCase:commandTest()
end

-- CONFIG GET parameter
-- Get the value of a configuration parameter
function ServerTestCase:configTest()
end

-- CONFIG REWRITE
-- Rewrite the configuration file with the in memory configuration
function ServerTestCase:configTest()
end

-- CONFIG SET parameter value
-- Set a configuration parameter to the given value
function ServerTestCase:configTest()
end

-- CONFIG RESETSTAT
-- Reset the stats returned by INFO
function ServerTestCase:configTest()
end

-- DBSIZE
-- Return the number of keys in the selected database
function ServerTestCase:dbsizeTest()
end

-- DEBUG OBJECT key
-- Get debugging information about a key
function ServerTestCase:debugTest()
end

-- DEBUG SEGFAULT
-- Make the server crash
function ServerTestCase:debugTest()
end

-- FLUSHALL
-- Remove all keys from all databases
function ServerTestCase:flushallTest()
end

-- FLUSHDB
-- Remove all keys from the current database
function ServerTestCase:flushdbTest()
end

-- INFO [section]
-- Get information and statistics about the server
function ServerTestCase:infoTest()
end

-- LASTSAVE
-- Get the UNIX time stamp of the last successful save to disk
function ServerTestCase:lastsaveTest()
end

-- MONITOR
-- Listen for all requests received by the server in real time
function ServerTestCase:monitorTest()
end

-- ROLE
-- Return the role of the instance in the context of replication
function ServerTestCase:roleTest()
end

-- SAVE
-- Synchronously save the dataset to disk
function ServerTestCase:saveTest()
end

-- SHUTDOWN [NOSAVE] [SAVE]
-- Synchronously save the dataset to disk and then shut down the server
function ServerTestCase:shutdownTest()
end

-- SLAVEOF host port
-- Make the server a slave of another instance, or promote it as master
function ServerTestCase:slaveofTest()
end

-- SLOWLOG subcommand [argument]
-- Manages the Redis slow queries log
function ServerTestCase:slowlogTest()
end

-- SYNC
-- Internal command used for replication
function ServerTestCase:syncTest()
end

-- TIME
-- Return the current server time
function ServerTestCase:timeTest()
end

return ServerTestCase
