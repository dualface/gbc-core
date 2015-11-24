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
local tests = cc.load("tests")
local check = tests.Check

local JobsTestCase = cc.class("JobsTestCase", tests.TestCase)

local _TEST_REDIS_KEY = 'jobs.test.number'

local _flush

function JobsTestCase:setup()
    local config = self.connect.config.server
    self._jobs = self.connect:getJobs()
    self._redis = self.connect:getRedis()
    _flush(self._jobs, self._redis)
end

function JobsTestCase:teardown()
    _flush(self._jobs, self._redis)
end

function JobsTestCase:addTest()
    local number = math.random(1, 10000)
    local data = {number = number, key = _TEST_REDIS_KEY}

    local delay = 1
    local jobid = self._jobs:add({
        action = '/fixtures/jobs.trigging',
        data = data,
        delay = delay,
    })
    check.isInt(jobid)
    helper.sleep(delay + 1) -- waiting for job done

    -- query job result from redis
    local res = tonumber(self._redis:get(_TEST_REDIS_KEY))
    check.equals(res, number * 2)

    return true
end

function JobsTestCase:atTest()
    local number = math.random(20000, 30000)
    local data = {number = number, key = _TEST_REDIS_KEY}

    local time = os.time() + 1
    local jobid = self._jobs:at({
        action = '/fixtures/jobs.trigging',
        data = data,
        time = time,
    })
    check.isInt(jobid)
    helper.sleep(2) -- waiting for job done

    -- query job result from redis
    local now = os.time()
    local res = tonumber(self._redis:get(_TEST_REDIS_KEY))
    check.equals(res, number * 2)
    check.isTrue(math.abs(now - time) <= 1)

    return true
end

function JobsTestCase:getTest()
    local number = math.random(40000, 50000)
    local data = {number = number, key = _TEST_REDIS_KEY}

    local delay = 2
    local jobid = self._jobs:add({
        action = '/fixtures/jobs.trigging',
        data = data,
        delay = delay,
    })
    check.isInt(jobid)

    -- query job
    local job = self._jobs:get(jobid)
    check.isTable(job)
    check.equals(job.id, jobid)
    check.equals(job.data, data)

    -- delete job
    local res = self._jobs:delete(jobid)
    check.isTrue(res)

    return true
end

-- remove all jobs
function JobsTestCase:_flush()
    local states = {"ready", "delayed", "buried"}
    for _, state in ipairs(states) do
        while true do
            local job = self._jobs:queryNext(state)
            if not job then break end
            self._jobs:remove(job.id)
        end
    end
end

-- private

_flush = function(jobs, redis)
    redis:del(_TEST_REDIS_KEY)
end

return JobsTestCase

