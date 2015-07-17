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

local json_encode = json.encode
local json_decode = json.decode
local string_format = string.format
local _check_posint

local JobService = class("JobService")

JobService.DEFAULT_PRIORITY = 5000
JobService.DEFAULT_TTR      = 120

function JobService:ctor(beans)
    if not beans then
        throw("job service is initialized failed: beans is invalid.")
    end
    self._beans = beans
end

function JobService:use(tube)
    local ok, err = self._beans:command("use", tube)
    if not ok then
        throw("JobService:use() failed, %s", err)
    end
end

function JobService:watch(tube)
    local size, err = self._beans:command("watch", tube)
    if not size then
        throw("JobService:watch() failed, %s", err)
    end
    return tonumber(size)
end

function JobService:ignore(tube)
    local size, err = self._beans:command("ignore", tube)
    if not size then
        throw("JobService:ignore() failed, %s", err)
    end
    return tonumber(size)
end

function JobService:add(action, data, delay, priority, ttr)
    if type(action) ~= "string" then
        throw("JobService:add() failed, invalid action name")
    end

    if type(delay) ~= "number" then
        delay = 0
    end
    if type(priority) ~= "number" then
        priority = JobService.DEFAULT_PRIORITY
    end
    if type(ttr) ~= "number" then
        ttr = JobService.DEFAULT_TTR
    end

    local job = {
        action   = action,
        data     = clone(data),
        delay    = delay,
        priority = priority,
        ttr      = ttr,
    }

    local id, line = self._beans:command("put", json_encode(job), priority, delay, ttr)
    if not id then
        throw(string_format("JobService:add() failed, %s", line))
    end

    job.id = _check_posint(id)
    return job
end

function JobService:query(jobId)
    jobId = _check_posint(jobId)
    local id, data = self._beans:command("peek", jobId)
    if not id then
        if data == "NOT_FOUND" then return nil end
        throw(string_format("JobService:query() failed, %s", data))
    end

    local job = json_decode(data)
    if type(job) ~= "table" then
        throw(string_format("JobService:query() failed, invalid job data"))
    end

    job.id = jobId
    return job
end

function JobService:remove(jobId)
    jobId = _check_posint(jobId)
    local ok, err = self._beans:command("delete", jobId)
    if not ok then
        throw(string_format("JobService:remove() failed, %s", err))
    end
end

_check_posint = function(x)
    local _x = tonumber(x)
    assert(type(_x) == "number" and math.floor(_x) == _x and _x >= 0, string_format("value expected is positive integer, actual is %s", tostring(x)))
    return _x
end

return JobService
