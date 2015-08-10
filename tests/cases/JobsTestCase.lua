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

local JobsTestCase = class("JobsTestCase", tests.TestCase)

JobsTestCase.ACCEPTED_REQUEST_TYPE = {"http", "cli"}

function JobsTestCase:setup()
    self._jobs = self.connect:getJobs()
    local currentChannel = self._jobs:getUsedChannel()
    self._jobs:watchChannel(currentChannel)
end

function JobsTestCase:teardown()
    self:_flush()
end

function JobsTestCase:channelTest()
    local currentChannel = self._jobs:getUsedChannel()

    local channel = "channel-" .. tostring(math.random(1, 100))
    self._jobs:useChannel(channel)

    local usedChannel = self._jobs:getUsedChannel()
    check.equals(usedChannel, channel)

    local countWatched = self._jobs:watchChannel(usedChannel)
    check.greaterThan(countWatched, 0)

    local channels = self._jobs:getWatchedChannels()
    check.isTable(channels)
    check.equals(countWatched, #channels)
    check.contains(channel, channels)

    local countWatched2 = self._jobs:ignoreChannel(usedChannel)
    check.equals(countWatched2, countWatched - 1)

    local channels = self._jobs:getWatchedChannels()
    check.notContains(channel, channels)

    self._jobs:useChannel(currentChannel)

    return true
end

function JobsTestCase:addTest()
    local action, data, job = self:_addJob()
    check.isTable(job)
    check.notEmpty(job.id)
    check.isPosInt(job.id)
    check.equals(job.action, action)
    check.equals(job.data, data)

    return true
end

function JobsTestCase:reserveTest()
    local action, data, job = self:_addJob()
    local job = self._jobs:reserve()

    check.isTable(job)
    check.notEmpty(job.id)
    check.isPosInt(job.id)

    self._jobs:remove(job.id)
    -- printf("- remove job %s [reserved]", job.id)

    return true
end

function JobsTestCase:reservedelayTest()
    local delay = 1
    local action, data, job = self:_addJob(delay)
    local job = self._jobs:reserve(delay + 1) -- waiting for delay + 1s

    check.isTable(job)
    check.notEmpty(job.id)
    check.isPosInt(job.id)

    self._jobs:remove(job.id)
    -- printf("- remove job %s [reserved]", job.id)

    return true
end

function JobsTestCase:releaseTest()
    local action, data, job = self:_addJob()
    local job = self._jobs:reserve()

    self._jobs:release(job)
    local jobAgain = self._jobs:reserve()
    self._jobs:remove(jobAgain.id)
    -- printf("- remove job %s [reserved]", jobAgain.id)

    check.isTable(job)
    check.equals(jobAgain, job)

    return true
end

function JobsTestCase:removeTest()
    local action, data, job = self:_addJob()
    self._jobs:remove(job.id)
    local queryResult = self._jobs:query(job.id)
    check.empty(queryResult)

    return true
end

function JobsTestCase:queryTest()
    local action, data, job = self:_addJob()
    local queryResult = self._jobs:query(job.id)
    check.equals(queryResult, job)

    return true
end

function JobsTestCase:querynextTest()
    local _, __, readyJob = self:_addJob() -- add 1 ready job
    local queryReadyJob = self._jobs:queryNext("ready")
    check.equals(queryReadyJob, readyJob)

    local delay = 1
    local _, __, delayedJob = self:_addJob(delay) -- add 1 delayed job
    local queryDelayedJob = self._jobs:queryNext("delayed")
    check.equals(queryDelayedJob, delayedJob)

    return true
end

-- add random job
function JobsTestCase:_addJob(delay)
    local action = "jobtests.hello"
    local data = {number = math.random(), str = "hello"}
    local job = {action = action, data = data, delay = delay}
    self._jobs:add(job)
    -- printf("- add job %s", job.id)
    return action, data, job
end

-- remove all jobs
function JobsTestCase:_flush()
    -- local currentChannel = self._jobs:getUsedChannel()
    -- printf("currentChannel = %s", currentChannel)

    -- local watchedChannels = self._jobs:getWatchedChannels()
    -- printf("watchedChannels = %s", table.concat(watchedChannels, ", "))

    local states = {"ready", "delayed", "buried"}
    for _, state in ipairs(states) do
        while true do
            local job = self._jobs:queryNext(state)
            if not job then break end
            -- printf("- remove job %s [%s]", job.id, state)
            self._jobs:remove(job.id)
        end
    end
end

return JobsTestCase
