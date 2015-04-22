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
local ipairs = ipairs
local tostring = tostring
local ngx_null = ngx.null
local ngx_worker_exiting = ngx.worker.exiting
local table_concat = table.concat
local table_remove = table.remove
local table_walk = table.walk
local string_sub = string.sub
local string_lower = string.lower
local string_upper = string.upper
local string_format = string.format
local string_match = string.match

local redis = require("resty.redis")

local RestyRedisAdapter = class("RestyRedisAdapter")

function RestyRedisAdapter:ctor(config)
    self._config = config
    self._instance = redis:new()
    self.name = "RestyRedisAdapter"
end

function RestyRedisAdapter:connect()
    self._instance:set_timeout(self._config.timeout)
    local ok, err
    if self._config.socket then
        ok, err = self._instance:connect(self._config.socket)
    else
        ok, err = self._instance:connect(self._config.host, self._config.port)
    end
    if err then
        err = string_format("%s connect, %s", self:_instancename(), err)
    end
    return ok, err
end

function RestyRedisAdapter:close()
    local ok, err = self._instance:close()
    if err then
        err = string_format("%s close, %s", self:_instancename(), err)
    end
    return ok, err
end

function RestyRedisAdapter:setKeepAlive(timeout, size)
    if size then
        return self._instance:set_keepalive(timeout, size)
    elseif timeout then
        return self._instance:set_keepalive(timeout)
    else
        return self._instance:set_keepalive()
    end
end

local function _formatCommandArgs(args)
    local result = {}
    table_walk(args, function(v) result[#result + 1] = tostring(v) end)
    return table_concat(result, ", ")
end

function RestyRedisAdapter:command(command, ...)
    command = string_lower(command)
    local method = self._instance[command]
    if type(method) ~= "function" then
        local err = string_format("%s invalid command \"%s\"", self:_instancename(), string_upper(command))
        return nil, err
    end

    if DEBUG > 1 then
        printInfo("%s command \"%s\": %s", self:_instancename(), string_upper(command), _formatCommandArgs({...}))
    end

    local res, err = method(self._instance, ...)
    if res == ngx_null then res = nil end

    if err then
        err = string_format("%s command \"%s\" failed, %s", self:_instancename(), string_upper(command), err)
    elseif DEBUG > 1 then
        printInfo("%s command \"%s\", result = %s", self:_instancename(), string_upper(command), tostring(res))
    end

    return res, err
end

function RestyRedisAdapter:pubsub(subscriptions)
    if type(subscriptions) ~= "table" then
        return nil, string.format("%s invalid subscriptions argument", self:_instancename())
    end

    if type(subscriptions.subscribe) == "string" then
        subscriptions.subscribe = {subscriptions.subscribe}
    end
    if type(subscriptions.psubscribe) == "string" then
        subscriptions.psubscribe = {subscriptions.psubscribe}
    end
    subscriptions.exit = false

    local subscribeMessages = {}

    local function _subscribe(f, channels, command)
        for _, channel in ipairs(channels) do
            if DEBUG > 1 then
                printInfo("%s command \"%s\": %s", self:_instancename(), string_upper(command), channel)
            end
            local res, err = f(self._instance, channel)
            if err then
                printWarn("%s command \"%s\" failed, %s", self:_instancename(), string_upper(command), err)
            else
                subscribeMessages[#subscribeMessages + 1] = res
                if DEBUG > 1 then
                    printInfo("%s command \"%s\", result = %s", self:_instancename(), string_upper(command), _formatCommandArgs(res))
                end
            end
        end
    end

    local function _unsubscribe(f, channels, command)
        for _, channel in ipairs(channels) do
            if DEBUG > 1 then
                printInfo("%s command \"%s\": %s", self:_instancename(), string_upper(command), channel)
            end
            f(self._instance, channel)
        end
    end

    local subscriptionsCount = 0
    local function _abort()
        if subscriptions.subscribe then
            _unsubscribe(self._instance.unsubscribe, subscriptions.subscribe, "UNSUBSCRIBE")
        end
        if subscriptions.psubscribe then
            _unsubscribe(self._instance.punsubscribe, subscriptions.psubscribe, "PUNSUBSCRIBE")
        end
    end

    if subscriptions.subscribe then
        _subscribe(self._instance.subscribe, subscriptions.subscribe, "SUBSCRIBE")
    end
    if subscriptions.psubscribe then
        _subscribe(self._instance.psubscribe, subscriptions.psubscribe, "PSUBSCRIBE")
    end

    return coroutine.wrap(function()
        while true do
            if ngx_worker_exiting() then
                _abort()
                break
            end
            local message, result, err
            if #subscribeMessages > 0 then
                result = subscribeMessages[1]
                table_remove(subscribeMessages, 1)
            else
                result, err = self._instance:read_reply()
                if err then
                    if err ~= "timeout" then
                        _abort()
                        break
                    else
                        -- err == timeout
                        message = {kind = "timeout"}
                    end
                end
            end

            if not message and result then
                if result[1] == "pmessage" then
                    message = {
                        kind = result[1],
                        pattern = result[2],
                        channel = result[3],
                        payload = result[4],
                    }
                else
                    message = {
                        kind = result[1],
                        channel = result[2],
                        payload = result[3],
                    }
                end

                if string_match(message.kind, '^p?subscribe$') then
                    subscriptionsCount = subscriptionsCount + 1
                end
                if string_match(message.kind, '^p?unsubscribe$') then
                    subscriptionsCount = subscriptionsCount - 1
                end

                if subscriptionsCount == 0 then
                    break
                end
            end
            coroutine.yield(message, _abort)
        end
    end)
end

function RestyRedisAdapter:commitPipeline(commands)
    self._instance:init_pipeline()
    for _, arg in ipairs(commands) do
        self:command(arg[1], unpack(arg[2]))
    end
    return self._instance:commit_pipeline()
end

function RestyRedisAdapter:_instancename()
    return "redis *" .. string_sub(tostring(self._instance), 10)
end

return RestyRedisAdapter
