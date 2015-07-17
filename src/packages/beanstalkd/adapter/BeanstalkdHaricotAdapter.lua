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

local assert = assert
local type = type
local tostring = tostring
local string_format = string.format
local string_upper = string.upper
local checktable = checktable

local haricot = require("3rd.beanstalkd.haricot")

local _result_or_err
local _job_or_err

local _convertors = {
    -- connection
    -- connect = connect, -- (server,port) -> ok

    -- producer
    put = function(arg, method, instance)
        -- (pri,delay,ttr,data) -> ok,[id|err]
        return  _result_or_err(method(instance, arg[2], arg[3], arg[4], arg[1]))
    end,
    --use = use, -- (tube) -> ok,[err]

    -- consumer
    -- reserve = reserve, -- () -> ok,[job|err]
    -- reserve_with_timeout = reserve_with_timeout, -- () -> ok,[job|nil|err]
    -- delete = delete, -- (id) -> ok,[err]
    -- release = release, -- (id,pri,delay) -> ok,[err]
    -- bury = bury, -- (id,pri) -> ok,[err]
    -- touch = touch, -- (id) -> ok,[err]
    -- watch = watch, -- (tube) -> ok,[count|err]
    -- ignore = ignore, -- (tube) -> ok,[count|err]

    -- other
    peek = function(arg, method, instance)
        -- (id) -> ok,[job|nil|err]
        return _job_or_err(method(instance, arg[1]))
    end,
    -- peek_ready = make_peek("ready"), -- () -> ok,[job|nil|err]
    -- peek_delayed = make_peek("delayed"), -- () -> ok,[job|nil|err]
    -- peek_buried = make_peek("buried"), -- () -> ok,[job|nil|err]
    -- kick = kick, -- (bound) -> ok,[count|err]
    -- kick_job = kick_job, -- (id) -> ok,[err]
    -- stats_job = stats_job, -- (id) -> ok,[yaml|err]
    -- stats_tube = stats_tube, -- (tube) -> ok,[yaml|err]
    -- stats = stats, -- () -> ok,[yaml|err]
    -- list_tubes = list_tubes, -- () -> ok,[yaml|err]
    -- list_tube_used = list_tube_used, -- () -> ok,[tube|err]
    -- list_tubes_watched = list_tubes_watched, -- () -> ok,[tube|err]
    -- quit = quit, -- () -> ok
    -- pause_tube = pause_tube, -- (tube,delay) -> ok,[err]
}

local BeanstalkdHaricotAdapter = class("BeanstalkdHaricotAdapter")

function BeanstalkdHaricotAdapter:ctor(config)
    self._config = config
    self._instance = haricot.new(self._config.host, self._config.port)
end

function BeanstalkdHaricotAdapter:connect()
    return true
end

function BeanstalkdHaricotAdapter:close()
    return self._instance:quit()
end

function BeanstalkdHaricotAdapter:command(command, ...)
    local method = self._instance[command]
    if type(method) ~= "function" then
        return nil, string_format("invalid beanstalkd command \"%s\"", string_upper(command))
    end

    local convertor = _convertors[command]
    if convertor then
        return convertor({...}, method, self._instance)
    else
        return method(self._instance, ...)
    end
end

_result_or_err = function(ok, ...)
    if ok then
        return ...
    else
        return false, ...
    end
end

_job_or_err = function(ok, res)
    if ok then
        if res == nil then
            return false, "NOT_FOUND"
        end
        return res.id, res.data
    else
        return false, res
    end
end

return BeanstalkdHaricotAdapter
