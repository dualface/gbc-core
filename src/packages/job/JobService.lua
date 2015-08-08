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

local json_encode   = json.encode
local json_decode   = json.decode
local string_format = string.format
local string_gsub   = string.gsub
local string_split  = string.split
local table_filter  = table.filter
local clone = clone

local _check_posint
local _export_yaml_arr

local JobService = class("JobService")

local DEFAULT_PRIORITY = 5000
local DEFAULT_TTR      = 120
local DEFAULT_DELAY    = 0

function JobService:ctor(beans)
    if not beans then
        throw("job service is initialized failed: beans is invalid.")
    end
    self._beans = beans
end

function JobService:useChannel(tube)
    local ok, err = self._beans:use(tube)
    if not ok then
        throw("JobService:use() failed, %s", err)
    end
end

function JobService:getUsedChannel()
    local tube, err = self._beans:listTubeUsed()
    if not tube then
        throw("JobService:getUsedTube() failed, %s", err)
    end
    return tube
end

function JobService:add(job)
    if type(job.action) ~= "string" then
        throw("JobService:add() failed, invalid action name")
    end

    if type(job.priority) ~= "number" then
        job.priority = DEFAULT_PRIORITY
    end
    if type(job.delay) ~= "number" then
        job.delay = DEFAULT_DELAY
    end
    if type(job.ttr) ~= "number" then
        job.ttr = DEFAULT_TTR
    end

    local id, line = self._beans:put(json_encode(job), job.priority, job.delay, job.ttr)
    if not id then
        throw(string_format("JobService:add() failed, %s", line))
    end

    job.id = id
    return job
end

function JobService:reserve(timeout)
    local id, data = self._beans:reserve(timeout)
    if not id then
        if data == "NOT_FOUND" then return nil end
        throw(string_format("JobService:reserve() failed, %s", data))
    end

    local job = json_decode(data)
    if type(job) ~= "table" then
        throw(string_format("JobService:reserve() failed, invalid job data"))
    end

    job.id = id
    return job
end

function JobService:release(job)
    local id = _check_posint(job.id)
    if type(job.delay) ~= "number" then
        job.delay = DEFAULT_DELAY
    end
    if type(job.priority) ~= "number" then
        job.priority = DEFAULT_PRIORITY
    end
    local ok, err = self._beans:release(id, job.priority, job.delay)
    if not ok then
        throw(string_format("JobService:release() failed, %s", err))
    end
end

function JobService:remove(id)
    id = _check_posint(id)
    local ok, err = self._beans:delete(id)
    if not ok then
        throw(string_format("JobService:remove() failed, %s", err))
    end
end

function JobService:query(id)
    id = _check_posint(id)
    local _id, data = self._beans:peek(id)
    if not _id then
        if data == "NOT_FOUND" then return nil end
        throw(string_format("JobService:query() failed, %s", data))
    end

    local job = json_decode(data)
    if type(job) ~= "table" then
        throw(string_format("JobService:query() failed, invalid job data"))
    end

    job.id = _check_posint(_id)
    return job
end

function JobService:queryNext(state)
    if type(state) ~= "string" then
        throw("JobService:queryNext() failed, invalid state")
    end

    local _id, data = self._beans:peek(state)
    if not _id then
        if data == "NOT_FOUND" then return nil end
        throw(string_format("JobService:query() failed, %s", data))
    end

    local job = json_decode(data)
    if type(job) ~= "table" then
        throw(string_format("JobService:query() failed, invalid job data"))
    end

    job.id = _check_posint(_id)
    return job
end

function JobService:watchChannel(tube)
    local size, err = self._beans:watch(tube)
    if not size then
        throw("JobService:watch() failed, %s", err)
    end
    return tonumber(size)
end

function JobService:ignoreChannel(tube)
    local size, err = self._beans:ignore(tube)
    if not size then
        throw("JobService:ignore() failed, %s", err)
    end
    return tonumber(size)
end

function JobService:getWatchedChannels()
    local result, err = self._beans:listTubesWatched()
    if not result then
        throw("JobService:getWatchedChannels() failed, %s", err)
    end
    return _export_yaml_arr(result)
end

_check_posint = function(x)
    local _x = tonumber(x)
    assert(type(_x) == "number" and math.floor(_x) == _x and _x >= 0, string_format("value expected is positive integer, actual is %s", tostring(x)))
    return _x
end

_export_yaml_arr = function(yaml)
    local values = string_gsub(yaml, "%-%-%-", "")
    values = string_gsub(values, "%- ", "")
    values = string_split(values, "\n")
    return table_filter(values, function(n) return n ~= "" end)
end

return JobService
