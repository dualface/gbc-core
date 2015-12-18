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

local io_flush      = io.flush
local os_date       = os.date
local os_time       = os.time
local string_format = string.format
local string_lower  = string.lower
local tostring      = tostring
local type          = type

local json      = cc.import("#json")
local Constants = cc.import(".Constants")

local InstanceBase = cc.import(".InstanceBase")
local WorkerInstanceBase = cc.class("WorkerInstanceBase", InstanceBase)

function WorkerInstanceBase:ctor(config, args, tag)
    WorkerInstanceBase.super.ctor(self, config, Constants.WORKER_REQUEST_TYPE)
    self._tag = tag or "worker"
end

function WorkerInstanceBase:run()
    return self:runEventLoop()
end

function WorkerInstanceBase:runEventLoop()
    local jobWorkerRequests = self.config.app.jobWorkerRequests
    local jobs     = self:getJobs({try = 3})
    local bean     = jobs:getBeanstalkd()
    local beanerrs = bean.ERRORS
    local appname  = self.config.app.appName
    local tag      = string_format("%s:%s", appname, self._tag)
    local running  = true

    cc.printinfo("[%s] ready, waiting for job", tag)

    while running do
        while true do
            io_flush()

            jobWorkerRequests = jobWorkerRequests - 1
            if jobWorkerRequests < 0 then
                cc.printinfo("[%s] job worker is done", tag)
                running = false -- stop loop
                break
            end

            local job, err = jobs:getready()
            if not job then
                if err == beanerrs.TIMED_OUT then
                    break -- wait next job
                end
                if err == beanerrs.DEADLINE_SOON then
                    cc.printinfo("[%s] deadline soon", tag)
                    break -- wait next job
                end

                cc.printwarn("[%s] reserve job failed, %s", tag, err)                running = false -- stop loop
                break
            end

            if not job.id then
                cc.printinfo("[%s] get a invalid job", tag)
                break -- wait next job
            else
                cc.printinfo("[%s] get a job %s, action: %s", tag, job.id, job.action)
            end

            -- handle the job
            local actionName = job.action
            local _, res = xpcall(function()
                return self:runAction(actionName, job)
            end, function(err)
                if cc.DEBUG > cc.DEBUG_WARN then
                    err = debug.traceback(err, 3)
                    cc.printwarn(err)
                end
            end)
            if res ~= false then
                -- delete job
                local ok, err = jobs:delete(job.id)
                if not ok then
                    cc.printwarn("[%s] delete job %s failed, %s", tag, job.id, err)
                else
                    cc.printinfo("[%s] job %s done", tag, job.id)
                end
            end
        end -- wait next job
    end -- loop

    io_flush()
    return 1
end

return WorkerInstanceBase
