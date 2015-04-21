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

local assert = assert
local type = type
local string_lower = string.lower
local json_decode = json.decode
local json_encode = json.encode
local tostring = tostring
local os_date = os.date
local os_time = os.time
local io_flush = io.flush

local _JOB_HASH = "_JOB_HASH"

local RedisService = cc.load("redis").service
local BeansService = cc.load("beanstalkd").service
local JobService = cc.load("job").service

local CLIBase = import(".CLIBase")
local Constants = import(".Constants")

local WorkerBase = class("WorkerBase", CLIBase)

function WorkerBase:ctor(config)
    WorkerBase.super.ctor(self, config)

    self._requestType = Constants.WORKER_REQUEST_TYPE
    self._jobTube = config.beanstalkd.jobTube
    self._jobService = JobService:create(self:_getRedis(), self:_getBeans(), config)
end

function WorkerBase:run()
    local ok, err = xpcall(function()
        self:runEventLoop()
    end, function(err)
        err = tostring(err)
        printError(err)
    end)
end

function WorkerBase:runEventLoop()
    local beans = self:_getBeans()
    local redis = self:_getRedis()
    local jobService = self._jobService

    beans:command("watch", self._jobTube)

    while true do
        local job, err = beans:command("reserve")
        if not job then
            printWarn("reserve beanstalkd job failed: %s", err)
            if err == "NOT_CONNECTED" then
                throw("beanstalkd NOT_CONNECTED")
            end
            goto reserve_next_job
        end

        local data, err = json_decode(job.data)
        if not data then
            printWarn("job bid: %s,  contents: \"%s\" is invalid: %s", job.id, job.data, err)
            beans:command("delete", job.id)
            goto reserve_next_job
        end

        printInfo("get a job, jobId: %s, contents: %s", tostring(data.id), job.data)

        -- remove redis data, which is related to this job
        jobService:remove(data.id)

        -- handle this job
        local jobAction = data.action
        res = self:runAction(jobAction, data.arg)
        if self.config.appJobMessageFormat == "json" then
            res = json_encode(res)
        end

        printf("finish job, jobId: %s, joined_time: %s, reserved_time:%s, result: %s", tostring(data.id), os_date("%Y-%m-%d %H:%M:%S", data.joined_time), os_date("%Y-%m-%d %H:%M:%S"), res)

        io_flush()
::reserve_next_job::
    end

    printInfo("DONE")
end

function WorkerBase:_getBeans()
    if not self._beans then
        self._beans = self:_newBeans()
    end
    return self._beans
end

function WorkerBase:_newBeans()
    local beans = BeansService:create(self.config.beanstalkd)
    local ok, err = beans:connect()
    if err then
        throw("connect internal beanstalkd failed, %s", err)
    end
    return beans
end

function WorkerBase:_getRedis()
    if not self._redis then
        self._redis = self:_newRedis()
    end
    return self._redis
end

function WorkerBase:_newRedis()
    local redis = RedisService:create(self.config.redis)
    local ok, err = redis:connect()
    if err then
        throw("connect internal redis failed, %s", err)
    end
    return redis
end

return WorkerBase
