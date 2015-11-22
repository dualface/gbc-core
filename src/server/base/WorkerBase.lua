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

local io_flush = io.flush
local json_decode = json.decode
local json_encode = json.encode
local os_date = os.date
local os_time = os.time
local string_format = string.format
local string_lower = string.lower
local tostring = tostring
local type = type

local CLIBase = import(".CLIBase")
local Constants = import(".Constants")

local WorkerBase = class("WorkerBase", CLIBase)

function WorkerBase:ctor(config)
    WorkerBase.super.ctor(self, config)
    self._requestType = Constants.WORKER_REQUEST_TYPE
end

function WorkerBase:run()
    return self:runEventLoop()
end

function WorkerBase:runEventLoop()
    local jobs = self:getJobs()
    local bean = jobs:getBeanstalkd()
    local beanerrs = bean.ERRORS
    local appname = self.config.app.appName

    while true do
        local job, err = jobs:getready()
        if not job then
            if err == beanerrs.TIMED_OUT then
                goto wait_next_job
            end
            if err == beanerrs.DEADLINE_SOON then
                printinfo("[Worker] - deadline soon")
                goto wait_next_job
            end
            printwarn("[Worker] - reserve job failed, %s", err)
            break
        end
        printinfo("get a job %s, action: %s", job.id, job.action)

        -- handle the job
        local actionName = job.action
        local res = self:runAction(actionName, job)
        if res ~= false then
            -- delete job
            local ok, err = jobs:delete(job.id)
            if not ok then
                printwarn("[Worker] - delete job %s failed, %s", job.id, err)
            else
                printinfo("[Worker] job %s done", job.id)
            end
        end

        io_flush()
::wait_next_job::
    end

    return 0
end

return WorkerBase
