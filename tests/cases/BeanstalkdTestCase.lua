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
local Beanstalkd = cc.load("beanstalkd")

local BeanstalkdTestCase = class("BeanstalkdTestCase", tests.TestCase)

BeanstalkdTestCase.ACCEPTED_REQUEST_TYPE = {"http", "cli"}

local _createBeanstalkd, _flush, _sleep

local DEFAULT_TUBE = "default"
local TEST_TUBE    = "test"
local JOB_PRIORITY = 0
local JOB_DELAY    = 1
local JOB_TTR      = 2
local JOB_WORD     = "hello, number is " .. math.random(1, 100)


function BeanstalkdTestCase:setup()
    self._beanstalkd = _createBeanstalkd(self.connect.config.server.beanstalkd)
    _flush(self._beanstalkd)
end

function BeanstalkdTestCase:teardown()
    _flush(self._beanstalkd)
end

function BeanstalkdTestCase:basicsTest()
    local bean = self._beanstalkd
    local errors = bean.ERRORS

    -- add job, reserve it
    local id = bean:put(JOB_WORD, JOB_PRIORITY, JOB_DELAY, JOB_TTR)
    check.isInt(id)
    local job = bean:reserve()
    check.equals(job, {id = id, data = JOB_WORD})

    -- sleep, reserve again with deadline_soon
    _sleep(JOB_TTR - 1)

    check.equals({bean:reserve(0)}, {nil, errors.DEADLINE_SOON})
    check.equals({bean:touch(job.id)}, {true})

    -- delete it
    check.equals({bean:delete(job.id)}, {true})
    -- delete non exists job
    check.equals({bean:delete(job.id)}, {nil, errors.NOT_FOUND})

    -- reserve with timeout
    check.equals({bean:reserve(1)}, {nil, errors.TIMED_OUT})

    return true
end

function BeanstalkdTestCase:releaseTest()
    local bean = self._beanstalkd
    local errors = bean.ERRORS

    -- add job, reserve it, release it
    local id = bean:put(JOB_WORD, 0, JOB_DELAY, JOB_TTR)
    check.isInt(id)
    local job = bean:reserve()
    check.equals(job, {id = id, data = JOB_WORD})
    check.equals({bean:release(job.id, JOB_PRIORITY, JOB_DELAY)}, {true})

    -- release non exists job
    check.equals({bean:release(job.id, JOB_PRIORITY, JOB_DELAY)}, {nil, errors.NOT_FOUND})
    -- delete it
    check.equals({bean:delete(job.id)}, {true})

    return true
end

function BeanstalkdTestCase:changestateTest()
    local bean = self._beanstalkd
    local errors = bean.ERRORS

    -- add job, peek it
    local id = bean:put(JOB_WORD, 0, JOB_DELAY, JOB_TTR)
    check.isInt(id)

    local expected = {id = id, data = JOB_WORD}
    local job = bean:peek(id)
    check.equals(job, expected)

    -- peek delayed job
    local job = bean:peek("delayed")
    check.equals(job, expected)

    -- reserve it, bury reserved job, peek buried job
    check.equals({bean:reserve()}, {expected})
    check.equals({bean:bury(job.id, JOB_PRIORITY)}, {true})
    local job = bean:peek("buried")
    check.equals(job, expected)

    -- kick it
    check.equals({bean:kick(100)}, {1})
    -- wait it ready
    _sleep(JOB_DELAY)
    local job = bean:peek("ready")
    check.equals(job, expected)

    return true
end

function BeanstalkdTestCase:statsTest()
    local bean = self._beanstalkd
    local errors = bean.ERRORS

    -- add job
    local id = bean:put(JOB_WORD, 0, JOB_DELAY, JOB_TTR)
    check.isInt(id)

    -- get job info
    local res = bean:statsJob(id)
    check.equals(res["id"], tostring(id))
    check.equals(res["state"], "delayed")

    -- get tube info
    local res = bean:statsTube(DEFAULT_TUBE)
    check.equals(res["name"], DEFAULT_TUBE)
    check.equals(res["current-jobs-delayed"], "1")

    -- get system info
    local res = bean:stats()
    check.equals(res["current-jobs-ready"], "0")
    check.equals(res["current-jobs-delayed"], "1")

    -- list tubes
    local tubes = bean:listTubes()
    check.isTable(tubes)
    check.contains(tubes, DEFAULT_TUBE)

    -- list used tube
    local tube = bean:listTubeUsed()
    check.equals(tube, DEFAULT_TUBE)

    -- list watched tubes
    local tubes = bean:listTubesWatched()
    check.isTable(tubes)
    check.contains(tubes, DEFAULT_TUBE)

    return true
end

function BeanstalkdTestCase:tubeTest()
    local bean = self._beanstalkd
    local errors = bean.ERRORS

    -- use, watch, ignore
    check.equals({bean:use(TEST_TUBE)}, {TEST_TUBE})
    local count = bean:watch(TEST_TUBE)
    check.isInt(count)
    check.greaterThan(count, 0)
    local count2 = bean:ignore(TEST_TUBE)
    check.isInt(count2)
    check.equals(count - 1, count2)

    return true
end

-- private

_createBeanstalkd = function (config)
    local beanstalkd = Beanstalkd:create()
    beanstalkd:connect(config.host, config.port)
    return beanstalkd
end

_flush = function (bean)
    bean:kick(10000)

    while true do
        local data = bean:reserve(0)
        if not data then break end
        bean:delete(data.id)
    end
end

_sleep = function (n)
    os.execute("sleep " .. tonumber(n))
end

return BeanstalkdTestCase
