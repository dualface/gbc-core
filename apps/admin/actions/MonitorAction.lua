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

local tonumber = tonumber
local string_format = string.format
local string_match = string.match
local string_sub = string.sub
local string_lower = string.lower
local string_split = string.split
local string_find = string.find
local table_insert = table.insert
local math_trunc = math.trunc
local io_popen = io.popen

local _MONITOR_PROC_DICT_KEY = "_MONITOR_PROC_DICT"
local _MONITOR_LIST_PATTERN = "_MONITOR_%s_%s_LIST"
local _MONITOR_MEM_INFO_KEY = "_MONITOR_MEM_INFO"
local _MONITOR_CPU_INFO_KEY = "_MONITOR_CPU_INFO"
local _MONITOR_DISK_INFO_KEY = "_MONITOR_DISK_INFO"

local MonitorAction = class("MonitorAction")

function MonitorAction:ctor(connect)
    self.connect = connect
    self._interval = connect.config.monitor.interval
end

function MonitorAction:getalldataAction(arg)
    local result = {}
    local process = self:_getProcess()
    for _, procName in ipairs(process) do
        result[procName] = self:_fillData(procName, {"SEC", "MINUTE", "HOUR"}, 0)
    end

    result.interval = self._interval
    result.cpu_cores = self:_getSystemInfo(_MONITOR_CPU_INFO_KEY)
    result.mem_total, result.mem_free = self:_getSystemInfo(_MONITOR_MEM_INFO_KEY)
    result.disk_total, result.disk_free = self:_getSystemInfo(_MONITOR_DISK_INFO_KEY)

    return result
end

function MonitorAction:getdataAction(arg)
    local timeSpan = self:_convertToSec(arg.time_span)

    if not timeSpan or timeSpan <= 0 then
        return self:getalldataAction(arg)
    end

    local listType = {}
    local start = 0
    if timeSpan <= 60 then
        table_insert(listType, "SEC")
        start = -math_trunc(timeSpan / self._interval)
        -- indicate that client has a query interval less than monitoring interval
        -- so at least return the latest data.
        if start == 0 then
            start = -1
        end
    elseif timeSpan <= 3600 then
        table_insert(listType, "MINUTE")
        start = -math_trunc(timeSpan / 60)
    else
        table_insert(listType, "HOUR")
        start = -math_trunc(timeSpan / 3600)
    end

    local result = {}
    local process = self:_getProcess()
    for _, procName in ipairs(process) do
        result[procName] = self:_fillData(procName, listType, start)
        if procName == "REDIS-SERVER" then
            result["REDIS_SERVER"] = result[procName]
            result[procName] = nil
        end
    end

    result.interval = self._interval
    result.cpu_cores = self:_getSystemInfo(_MONITOR_CPU_INFO_KEY)
    result.mem_total, result.mem_free = self:_getSystemInfo(_MONITOR_MEM_INFO_KEY)
    result.disk_total, result.disk_free = self:_getSystemInfo(_MONITOR_DISK_INFO_KEY)

    return result
end

function MonitorAction:_getProcess()
    local redis = self.connect:getRedis()
    local process = redis:command("HKEYS", _MONITOR_PROC_DICT_KEY)

    return process
end

function MonitorAction:_getSystemInfo(key)
    local redis = self.connect:getRedis()
    local res = string_split(redis:command("GET", key), "|")

    return res[1], res[2]
end

function MonitorAction:_convertToSec(timeSpan)
    if not timeSpan then return nil end

    local time = string_match(string_lower(timeSpan), "^(%d+[s|h|m])")
    if time == nil then
        throw("time format error.")
    end
    local unit = string_sub(time, -1)
    local number = tonumber(string_sub(time, 1, -2))
    if not number then
        return nil
    end

    if unit == "h" then
        return number * 3600
    end

    if unit == "m" then
        return number * 60
    end

    if unit == "s" then
        return number
    end

    return nil
end

function MonitorAction:_fillData(procName, listType, start)
    local redis = self.connect:getRedis()
    local t = {}
    t.cpu = {}
    if not string_find(procName, "BEANSTALKD") then
        t.mem = {}
        if not string_find(procName, "NGINX_WORKER") then
            t.conn_num = {}
        end
    else
        t.total_jobs = {}
    end

    for _, typ in ipairs(listType) do
        local list = string_format(_MONITOR_LIST_PATTERN, procName, typ)
        local data = redis:command("LRANGE", list, start, -1)
        local field = self:_getFiled(typ)
        t.cpu[field] = {}
        if not string_find(procName, "BEANSTALKD") then
            t.mem[field] = {}
            if not string_find(procName, "NGINX_WORKER") then
                t.conn_num[field] = {}
            end
        else
            t.total_jobs[field] = {}
        end

        for _, v in ipairs(data) do
            local tmp = string_split(v, "|")
            table_insert(t.cpu[field], tonumber(tmp[1]))
            if not string_find(procName, "BEANSTALKD") then
                table_insert(t.mem[field], tonumber(tmp[2]))
                if not string_find(procName, "NGINX_WORKER") then
                    table_insert(t.conn_num[field], tonumber(tmp[3]))
                end
            else
                table_insert(t.total_jobs[field], tonumber(tmp[3]))
            end
        end
    end

    return t
end

function MonitorAction:_getFiled(typ)
    if typ == "SEC" then
        return "last_60s"
    end

    if typ == "MINUTE" then
        return "last_hour"
    end

    if typ == "HOUR" then
        return "last_day"
    end
end

return MonitorAction
