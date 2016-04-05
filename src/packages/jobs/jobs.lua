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

local json = cc.import("#json")

local Jobs = cc.class("Jobs")

Jobs.DEFAULT_DELAY    = 1
Jobs.DEFAULT_TTR      = 10

Jobs.DEFAULT_PRIORITY = 2048
Jobs.NORMAL_PRIORITY  = Jobs.DEFAULT_PRIORITY
Jobs.HIGH_PRIORITY    = 512
Jobs.LOW_PRIORITY     = 4096

function Jobs:ctor(bean)
    self._bean = bean
    return 1
end

function Jobs:getBeanstalkd()
    return self._bean
end

function Jobs:add(job)
    local action = job.action
    local data   = job.data
    local delay  = job.delay or Jobs.DEFAULT_DELAY
    local pri    = job.pri or Jobs.DEFAULT_PRIORITY
    local ttr    = job.ttr or Jobs.DEFAULT_TTR

    local job = {
        action = action,
        data   = data,
        delay  = delay,
        pri    = pri,
        ttr    = ttr,
    }

    return self._bean:put(json.encode(job), pri, delay, ttr)
end

function Jobs:at(job)
    local now = os.time()
    local at = job.time
    if type(at) ~= "number" then
        at = now
    end
    local delay = at - now
    job.delay = delay
    job.time = nil
    return self:add(job)
end

function Jobs:get(id)
    local bean = self._bean

    local jobraw, err = bean:peek(id)
    if not jobraw then
        return nil, err
    end

    local job = json.decode(jobraw.data)
    if type(job) ~= "table" then
        self:delete(jobraw.id)
        return nil, string.format("invalid job %s", jobraw.id)
    end

    job.id = jobraw.id
    return job
end

function Jobs:getready(timeout)
    local bean = self._bean

    local jobraw, err = bean:reserve(timeout)
    if not jobraw then
        return nil, err
    end

    local id = jobraw.id
    local job = json.decode(jobraw.data)
    if type(job) ~= "table" or not job.action then
        bean:delete(id)
        return {id = nil}
    end

    job.id = id
    return job
end

function Jobs:delete(id)
    return self._bean:delete(id)
end

return Jobs

