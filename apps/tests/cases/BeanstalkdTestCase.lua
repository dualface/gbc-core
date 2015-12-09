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

local helper = cc.import(".helper")
local tests = cc.import("#tests")
local check = tests.Check
local Beanstalkd = cc.import("#beanstalkd")

local BeanstalkdTestCase = cc.class("BeanstalkdTestCase", tests.TestCase)

local _newbean, _flush

local _DEFAULT_TUBE = "default"
local _TEST_TUBE    = "_test_"
local _JOB_PRIORITY = 0
local _JOB_DELAY    = 1
local _JOB_TTR      = 2
local _JOB_WORD     = "hello, number is " .. math.random(1, 100)

function BeanstalkdTestCase:setup()
    local config = self:getInstanceConfig()
    self._beanstalkd = _newbean(instance.config.server.beanstalkd)
    _flush(self._beanstalkd)
end

function BeanstalkdTestCase:teardown()
    _flush(self._beanstalkd)
end

function BeanstalkdTestCase:basicsTest()
    local bean = self._beanstalkd
    local errors = bean.ERRORS

    -- add job, reserve it
    local id = bean:put(_JOB_WORD, _JOB_PRIORITY, _JOB_DELAY, _JOB_TTR)
    check.isInt(id)
    local job = bean:reserve()
    check.equals(job, {id = id, data = _JOB_WORD})

    -- sleep, reserve again with deadline_soon
    helper.sleep(_JOB_TTR - 1)

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
    local id = bean:put(_JOB_WORD, 0, _JOB_DELAY, _JOB_TTR)
    check.isInt(id)
    local job = bean:reserve()
    check.equals(job, {id = id, data = _JOB_WORD})
    check.equals({bean:release(job.id, _JOB_PRIORITY, _JOB_DELAY)}, {true})

    -- release non exists job
    check.equals({bean:release(job.id, _JOB_PRIORITY, _JOB_DELAY)}, {nil, errors.NOT_FOUND})
    -- delete it
    check.equals({bean:delete(job.id)}, {true})

    return true
end

function BeanstalkdTestCase:changestateTest()
    local bean = self._beanstalkd
    local errors = bean.ERRORS

    -- add job, peek it
    local id = bean:put(_JOB_WORD, 0, _JOB_DELAY, _JOB_TTR)
    check.isInt(id)

    local expected = {id = id, data = _JOB_WORD}
    local job = bean:peek(id)
    check.equals(job, expected)

    -- peek delayed job
    local job = bean:peek("delayed")
    check.equals(job, expected)

    -- reserve it, bury reserved job, peek buried job
    check.equals({bean:reserve()}, {expected})
    check.equals({bean:bury(job.id, _JOB_PRIORITY)}, {true})
    local job = bean:peek("buried")
    check.equals(job, expected)

    -- kick it
    check.equals({bean:kick(100)}, {1})
    -- wait it ready
    helper.sleep(_JOB_DELAY)
    local job = bean:peek("ready")
    check.equals(job, expected)

    return true
end

function BeanstalkdTestCase:statsTest()
    local bean = self._beanstalkd
    local errors = bean.ERRORS

    -- add job
    local id = bean:put(_JOB_WORD, 0, _JOB_DELAY, _JOB_TTR)
    check.isInt(id)

    -- get job info
    local res = bean:statsJob(id)
    check.equals(res["id"], tostring(id))
    check.equals(res["state"], "delayed")

    -- get tube info
    local res = bean:statsTube(_TEST_TUBE)
    check.equals(res["name"], _TEST_TUBE)
    check.equals(res["current-jobs-delayed"], "1")

    -- get system info
    local res = bean:stats()
    check.equals(res["current-jobs-ready"], "0")
    check.equals(res["current-jobs-delayed"], "1")

    -- list tubes
    local tubes = bean:listTubes()
    check.isTable(tubes)
    check.contains(tubes, _TEST_TUBE)

    -- list used tube
    local tube = bean:listTubeUsed()
    check.equals(tube, _TEST_TUBE)

    -- list watched tubes
    local tubes = bean:listTubesWatched()
    check.isTable(tubes)
    check.contains(tubes, _TEST_TUBE)

    return true
end

function BeanstalkdTestCase:tubeTest()
    local bean = self._beanstalkd
    local errors = bean.ERRORS

    -- use, watch, ignore
    check.equals({bean:use(_TEST_TUBE)}, {_TEST_TUBE})

    local count = bean:watch(_TEST_TUBE)
    check.isInt(count)
    check.greaterThan(count, 0)

    local count2 = bean:ignore(_DEFAULT_TUBE)
    check.isInt(count2)

    return true
end

-- private

_newbean = function(config)
    local beanstalkd = Beanstalkd:new()
    beanstalkd:connect(config.host, config.port)
    beanstalkd:use(_TEST_TUBE)
    beanstalkd:watch(_TEST_TUBE)
    beanstalkd:ignore(_DEFAULT_TUBE)
    return beanstalkd
end

_flush = function(bean)
    bean:kick(10000)

    while true do
        local data = bean:reserve(0)
        if not data then break end
        bean:delete(data.id)
    end
end

return BeanstalkdTestCase
