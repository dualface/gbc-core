
local tests = cc.load("tests")
local check = tests.Check

local JobsTestCase = class("JobsTestCase", tests.TestCase)

function JobsTestCase:setup()
    self._jobs = self.connect:getJobs()
end

function JobsTestCase:teardown()
end

function JobsTestCase:addTest()
    local action, data, job = self:_addJob()
    check.isTable(job, "invalid result")
    check.notEmpty(job.id, "invalid job.id")
    check.equals(job.action, action, "job.action not equals")
    check.equals(job.data, data, "job.data not equals")

    data.number = data.number + 1
    check.notEquals(job.data, data, "after data changed, job.data should be is not equals")

    return {ok = true}
end

function JobsTestCase:queryTest()
    local action, data, job = self:_addJob()
    local queryResult = self._jobs:query(job.id)
    check.equals(queryResult, job, "job mismatch")

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
