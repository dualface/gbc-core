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

local pairs = pairs
local json_encode = json.encode
local json_decode = json.decode
local string_format = string.format

local JobService = class("JobService")

JobService.DEFAULT_PRIORITY = 5000
JobService.DEFAULT_TTR      = 120

function JobService:ctor(beans, config)
    if not beans then
        throw("job service is initialized failed: beans is invalid.")
    end
    if not config then
        throw("job service is initialized failed: config is invalid.")
    end
    self._beans = beans

    self._tube = string.format("job-%d", config.appIndex)
    self._beans:command("use", self._tube)
end

function JobService:add(action, data, delay, priority, ttr)
    if type(action) ~= "string" then
        throw("add job failed, invalid action name")
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
        data     = data,
        delay    = delay,
        priority = priority,
        ttr      = ttr,
    }

    local id, line = self._beans:command("put", json_encode(job), priority, delay, ttr)
    if not id then
        throw(string_format("add job failed, %s", line))
    end

    job.id = id
    job.line = line
    return job
end

function JobService:query(jobId)
    local id, line = self._beans:command("peek", jobId)
    
end

function JobService:remove(jobId)
    local redis = self._redis
    local beans = self._beans

    local job, err = redis:command("HGET", _JOB_HASH, jobId)
    if not job then
        return nil, string_format("job service remove failed: can't get job from db, %s", err)
    end
    if ngx and jobStr == ngx.null then
        return nil, string_format("job service remove failed: job[%d] does not exist.", jobId)
    end

    -- delete it from redis
    redis:command("HDEL", _JOB_HASH, jobId)

    job, err = json_decode(job)
    if not job then
        return nil, string_format("job service remove, the contents of job[%d] is invalid.", jobId)
    end

    -- delete it from beanstalkd
    local bid = job.bid
    local ok, err = beans:command("delete", tonumber(bid))
    if not ok then
        return nil, string_format("job service remove failed: %s", err)
    end

    return true, nil
end

return JobService
