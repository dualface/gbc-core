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
end

function JobsTestCase:teardown()
end

function JobsTestCase:addTest()
    local action, data, job = self:_addJob()
    check.isTable(job, "addTest() - job")
    check.notEmpty(job.id, "addTest() - job.id")
    check.isPosInt(job.id, "addTest() - job.id")
    check.equals(job.action, action, "addTest() - job.action")
    check.equals(job.data, data, "addTest() - job.data")

    data.number = data.number + 1
    check.notEquals(job.data, data, "after data changed, job.data should be is not equals")

    return {ok = true}
end

function JobsTestCase:queryTest()
    local action, data, job = self:_addJob()
    local queryResult = self._jobs:query(job.id)
    check.equals(queryResult, job, "queryTest() - job")

    return {ok = true}
end

function JobsTestCase:removeTest()
    local action, data, job = self:_addJob()
    self._jobs:remove(job.id)
    local queryResult = self._jobs:query(job.id)
    check.empty(queryResult)

    return {ok = true}
end

function JobsTestCase:_addJob()
    local action = "jobtests.hello"
    local data = {number = math.random(), str = "hello"}
    return action, data, self._jobs:add(action, data)
end

return JobsTestCase
