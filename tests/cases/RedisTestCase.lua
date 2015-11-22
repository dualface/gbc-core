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

local tests = cc.load("tests")
local check = tests.Check
local helper = import("..helper")

local Redis = cc.load("redis")

local RedisTestCase = class("RedisTestCase", tests.TestCase)

RedisTestCase.ACCEPTED_REQUEST_TYPE = {"http", "cli"}
RedisTestCase.TEST_DB_INDEX = 15
RedisTestCase.CLEANUP_CODE = [[
local keys = redis.call('KEYS', '*')
for _, key in ipairs(keys) do
    redis.call('DEL', key)
end
]]

local _newredis, _runcmds

function RedisTestCase:setup()
    self._redis = _newredis(self.connect.config.server.redis)
end

function RedisTestCase:teardown()
    local redis = self._redis
    redis:select(RedisTestCase.TEST_DB_INDEX)
    redis:eval(RedisTestCase.CLEANUP_CODE, 0)
    redis:close()
    self._redis = nil
end

function RedisTestCase:typesTest()
    local redis = self._redis

    -- check return types:
    -- Simple Strings
    local word = "hello world"
    check.equals(redis:echo(word), word)
    check.equals(redis:ping(), "PONG")

    -- Errors
    local ok, err = redis:auth("INVALID_PASSWORD")
    check.contains(string.lower(err), "no password is set")

    -- Integers
    check.equals(redis:del("NON_EXISTS_KEY"), 0)
    redis:del("TEST_KEY")
    check.equals(redis:set("TEST_KEY", word), "OK")
    check.equals(redis:del("TEST_KEY"), 1)

    -- Bulk Strings
    check.equals(redis:set("TEST_KEY", word), "OK")
    check.equals(redis:get("TEST_KEY"), word)

    -- Arrays
    check.equals(redis:set("TEST_KEY_1", word), "OK")
    check.equals(redis:set("TEST_KEY_2", word), "OK")
    local keys = redis:keys("TEST_KEY_*")
    check.isTable(keys)
    table.sort(keys)
    check.equals(keys, {"TEST_KEY_1", "TEST_KEY_2"})

    check.equals(redis:mget("TEST_KEY", "NON_EXISTS_KEY"), {word, redis.null})

    return true
end

function RedisTestCase:pipelineTest()
    local redis = self._redis

    local word = "hello world"
    local commands = {
        {"echo", word},
        {"ping"},
        {"del", "NON_EXISTS_KEY"},
        {"set", "TEST_KEY", word},
        {"del", "TEST_KEY"},
        {"set", "TEST_KEY_1", word},
        {"set", "TEST_KEY_2", word},
        {"keys", "TEST_KEY_*"},
        {"mget", "TEST_KEY", "TEST_KEY_1", "NON_EXISTS_KEY"},
        {"eval", "return {redis.call('get', 'NON_EXISTS_KEY'), KEYS[1], ARGV[1]}", 1, "KEY_1", "ARG_1"},
        {"auth", "NO_PASSWORD"}, -- get error in pipeline
    }

    local expected = {
        word,
        "PONG",
        0,
        "OK",
        1,
        "OK",
        "OK",
        {"TEST_KEY_1", "TEST_KEY_2"},
        {redis.null, word, redis.null},
        {
            redis.null, "KEY_1", "ARG_1",
        },
    }

    local function _checkResult(vals)
        table.sort(vals[8])
        local last = table.remove(vals)

        check.equals(vals, expected)
        check.isTable(last)
        check.isFalse(last[1])
        check.contains(last[2], "no password is set")
    end

    -- test commit pipeline
    redis:initPipeline()
    _runcmds(redis, commands)
    local vals = redis:commitPipeline()
    check.isTable(vals)
    _checkResult(vals)

    -- test cancel pipeline
    redis:initPipeline()
    _runcmds(redis, commands)
    redis:cancelPipeline() -- cleanup pipeline

    redis:initPipeline() -- start again
    _runcmds(redis, commands)
    local vals = redis:commitPipeline()
    check.isTable(vals)
    _checkResult(vals)

    return true
end

function RedisTestCase:pubsubTest()
    local redis = self._redis

    local channel1 = "MSG_CHANNEL_1"
    local channel2 = "MSG_CHANNEL_2"

    -- use current instance to subscribe to channels
    check.equals(redis:subscribe(channel1, channel2), {
        "subscribe", channel1, 1
    })
    check.equals(redis:readReply(), {
        "subscribe", channel2, 2
    })

    -- use an other instance publish message to channels
    local redis2 = _newredis(self.connect.config.server.redis)
    redis2:publish(channel1, "hello")

    check.equals(redis:readReply(), {
        "message", channel1, "hello"
    })

    redis2:publish(channel2, "world")

    check.equals(redis:readReply(), {
        "message", channel2, "world"
    })

    redis2:close()

    -- unsubscribe from channels
    check.equals(redis:unsubscribe(channel1), {
        "unsubscribe", channel1, 1
    })
    check.equals(redis:unsubscribe(channel2), {
        "unsubscribe", channel2, 0
    })
    check.equals(redis:echo("hello"), "hello")

    return true
end

-- private methods

_newredis = function(config)
    local redis, err = helper.newredis(config)
    check.isNil(err, err)
    redis:select(RedisTestCase.TEST_DB_INDEX)
    redis:eval(RedisTestCase.CLEANUP_CODE, 0)
    return redis
end

_runcmds = function(redis, commands)
    local res = {}
    for i, args in ipairs(commands) do
        res[i] = redis:doCommand(unpack(args))
    end
    return res
end

return RedisTestCase
