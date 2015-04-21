--[[

Copyright (c) 2011-2015 dualface#github

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
local tonumber = tonumber
local json_encode = json.encode
local json_decode = json.decode
local os_time = os.time
local string_format = string.format

local _JOB_KEY = "_JOB_KEY"
local _JOB_HASH = "_JOB_HASH"

local _JOB_PRIORITY_NORMAL = 5000

local JobService = class("JobService")

function JobService:ctor(redis, beans, config)
    if not redis or not beans then
        throw("job service is initialized failed: redis or beans is invalid.")
    end
    if not config then
        throw("job service is initialized failed: can't get jobTube from config.")
    end
    self._redis = redis
    self._beans = beans
    self._jobTube = config.beanstalkd.jobTube
end

function JobService:add(action, data, delay, priority, ttr)
    local beans = self._beans
    local redis = self._redis

    delay = delay or 0
    priority = priority or _JOB_PRIORITY_NORMAL
    ttr = ttr or 120

    if not action then
        throw("job service add job failed: job action is null.")
    end

    -- jobId means a redis id of this job.
    local jobId, err = redis:command("INCR", _JOB_KEY)
    if not jobId then
        return nil, string_format("job service generate job id failed: %s", err)
    end

    local job = {}
    job.id = jobId
    job.joined_time = os_time()
    job.action = action
    job.arg = data
    job.delay = delay
    job.priority = priority
    job.ttr = ttr

    -- put job to beanstalkd
    beans:command("use", self._jobTube)

    -- jobBid means job id in beanstalkd.
    jobBid = beans:command("put", json_encode(job), tonumber(priority), tonumber(delay), tonumber(ttr))
    printInfo("job Bid = %s", jobBid)

    -- store job info to redis for persistence
    job.bid = jobBid
    local ok, err = redis:command("HSET", _JOB_HASH, jobId, json_encode(job))
    if not ok then
        throw("job service newJob() store job into redis failed: %s", err)
    end

    return jobId
end

function JobService:query(jobId)
    local redis = self._redis

    local job, err = redis:command("HGET", _JOB_HASH, jobId)
    if not job then
        return nil, string_format("job service query failed: %s", err)
    end

    if ngx and job == ngx.null then
        return nil, string_format("job service query failed: job[%d] does not exist.", tonumber(jobId))
    end

    job, err = json_decode(job)
    if not job then
        return nil, string_format("job service query, the contents of job[%d] is invalid: %s", tonumber(jobId), err)
    end

    return job, nil
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
