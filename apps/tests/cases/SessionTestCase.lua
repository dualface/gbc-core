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


local Session = cc.import("#session")

local helper = cc.import(".helper")
local tests = cc.import("#tests")
local check = tests.Check

local SessionTestCase = cc.class("SessionTestCase", tests.TestCase)

local _KEYS = table.readonly({
    NON_EXISTS_KEY = "NON_EXISTS_KEY",
    STRING_KEY     = "STRING_KEY",
    NUMBER_KEY     = "NUMBER_KEY",
})

local _newredis

function SessionTestCase:setup()
    self._redis = _newredis(self.instance.config.server.redis)
end

function SessionTestCase:teardown()
end

function SessionTestCase:createTest()
    local redis = self._redis
    local session = Session.new(redis)
    session:start()

    local sid = session:getSid()
    check.isString(sid)

    check.isNil(session:get(_KEYS.NON_EXISTS_KEY))

    local number = math.random(1, 100000)
    session:set(_KEYS.NUMBER_KEY, number)
    check.equals(session:get(_KEYS.NUMBER_KEY), number)

    local word = "hello " .. tostring(number)
    session:set(_KEYS.STRING_KEY, word)
    check.equals(session:get(_KEYS.STRING_KEY), word)

    -- save session
    session:save()

    -- create an other session use same sid
    local session2 = Session.new(redis)
    session2:start(sid)

    check.equals(session:get(_KEYS.NUMBER_KEY), number)
    check.equals(session:get(_KEYS.STRING_KEY), word)

    -- destroy first session
    session:destroy()

    -- second session should is destroyed also
    check.isFalse(session2:isAlive())

    return true
end

function SessionTestCase:expiredTest()
    local redis = self._redis
    local session = Session.new(redis, {expired = 1})
    session:start()

    local number = math.random(1, 100000)
    session:set(_KEYS.NUMBER_KEY, number)
    check.isFalse(session:isAlive())
    check.equals(session:get(_KEYS.NUMBER_KEY), number)

    session:save()
    check.isTrue(session:isAlive())

    session:setKeepAlive(2)
    helper.sleep(1)
    check.isTrue(session:isAlive())
    check.equals(session:get(_KEYS.NUMBER_KEY), number)

    helper.sleep(2)
    check.isFalse(session:isAlive())
    check.equals(session:get(_KEYS.NUMBER_KEY), nil)

    return true
end

-- private

_newredis = function(config)
    local redis, err = helper.newredis(config)
    check.isNil(err, err)
    redis:select(_TEST_DB_INDEX)
    redis:eval(_CLEANUP_CODE, 0)
    return redis
end

return SessionTestCase
