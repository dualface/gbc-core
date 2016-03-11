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

local semaphore = require "ngx.semaphore"

local ipairs             = ipairs
local ngx_thread_kill    = ngx.thread.kill
local ngx_thread_spawn   = ngx.thread.spawn
local string_byte        = string.byte
local string_split       = string.split
local string_sub         = string.sub
local table_concat       = table.concat
local table_remove       = table.remove
local tostring           = tostring
local unpack             = unpack

local NginxRedisLoop = cc.class("NginxRedisLoop")

local _loop, _cleanup, _onmessage, _onerror

function NginxRedisLoop:ctor(redis, subredis, id)
    self._redis = redis
    self._subredis = subredis
    self._subredis:setTimeout(5) -- check client connect abort quickly
    self._sema = semaphore.new()

    id = id or ""
    self._id = id .. "_" .. string_sub(tostring(self), 10)
end

function NginxRedisLoop:start(onmessage, cmdchannel, ...)
    if not self._subredis then
        return nil, "not initialized"
    end
    local onmessage = onmessage or _onmessage
    local onerror = _onerror
    self._cmdchannel = cmdchannel

    local res, err = self._subredis:subscribe(cmdchannel, ...)
    if not res then
        return nil, err
    end
    cc.printinfo("[RedisSub:%s] <loop start> %s", self._id, table_concat(res, " "))

    self._thread = ngx_thread_spawn(_loop, self, onmessage, onerror)
    return 1
end

function NginxRedisLoop:stop()
    self._redis:publish(self._cmdchannel, "!STOP")
    self._sema:wait(1)
    _cleanup(self)
end

-- add methods

local _COMMANDS = {
    "subscribe", "unsubscribe",
    "psubscribe", "punsubscribe",
}

for _, cmd in ipairs(_COMMANDS) do
    NginxRedisLoop[cmd] = function(self, ...)
        local args = {"!REDIS", cmd}
        for _, arg in ipairs({...}) do
            args[#args + 1] = tostring(arg)
        end
        -- cc.printinfo("[RedisSub:%s] CMD: %s", self._id, table_concat(args, " "))
        local res, err = self._redis:publish(self._cmdchannel, table_concat(args, " "))
        -- wait for command completed
        self._sema:wait(1)
        return res, err
    end
end

-- private

local _skipmsgtypes = {
    subscribe    = true,
    unsubscribe  = true,
    psubscribe   = true,
    punsubscribe = true,
}

_loop = function(self, onmessage, onerror)
    local cmdchannel = self._cmdchannel
    local subredis   = self._subredis
    local id         = self._id
    local running    = true
    local sema       = self._sema
    local DEBUG = cc.DEBUG > cc.DEBUG_WARN

    local msgtype, channel, msg, pchannel

    cc.printinfo("[RedisSub:%s] <loop ready>", id)

    while running do
        -- cc.printinfo("[RedisSub:%s] <wait read reply>", id)
        local res, err = subredis:readReply()
        if not res then
            if err ~= "timeout" then
                onerror(err, id)
                running = false -- stop loop
                break
            end
        end

        while res do -- process message
            -- cc.printinfo("[RedisSub:%s] <read reply> %s", id, table_concat(res, " "))

            msgtype = res[1]
            channel = res[2]
            msg     = res[3]

            if _skipmsgtypes[msgtype] then
                -- cc.printinfo("[RedisSub:%s] <skip> %s", id, table_concat(res, " "))
                break -- read reply
            end

            if channel ~= cmdchannel then
                -- general message
                if msgtype == "message" then
                    -- msgtype, channel, msg
                    onmessage(channel, msg, nil, id)
                elseif msgtype == "pmessage" then
                    pchannel = res[2]
                    channel  = res[3]
                    msg      = res[4]
                    onmessage(channel, msg, pchannel, id)
                else
                    cc.printwarn("[RedisSub:%s] invalid message, %s", id, table_concat(res, " "))
                end
                break -- read reply
            end

            if string_byte(msg) ~= 33 --[[ ! ]] then
                -- forward control message
                onmessage(channel, msg, nil, id)
                break -- read reply
            end

            -- control message
            local parts = string_split(msg, " ")
            local cmd = parts[1]
            if cmd == "!STOP" then
                running = false -- stop loop
                break
            elseif cmd == "!REDIS" then
                table_remove(parts, 1)
                res, err = subredis:doCommand(unpack(parts))
                if not res then
                    cc.printwarn("[RedisSub:%s] redis failed, %s", id, err)
                    break -- read reply
                else
                    -- cc.printinfo("[RedisSub:%s] <forward> %s", id, table_concat(parts, " "))
                    -- cc.printinfo("[RedisSub:%s] <forward-result> %s", id, table_concat(res, " "))
                    sema:post(1) -- release lock
                end
            else
                -- unknown control message
                cc.printwarn("[RedisSub:%s] unknown control message, %s", id, msg)
                break -- read reply
            end

        end -- read reply
    end -- loop

    cc.printinfo("[RedisSub:%s] <loop ended>", id)

    subredis:unsubscribe()
    subredis:setKeepAlive()

    sema:post(1)
end

_cleanup = function(self)
    ngx_thread_kill(self._thread)
    self._thread = nil
    self._redis = nil
    self._subredis = nil
    self._id = nil
end

_onmessage = function(channel, msg, pchannel, id)
    if pchannel then
        cc.printinfo("[RedisSub:%s] <%s> <%s> %s", id, pchannel, channel, msg)
    else
        cc.printinfo("[RedisSub:%s] <%s> %s", id, channel, msg)
    end
end

_onerror = function(err, id)
    cc.printwarn("[RedisSub:%s] onerror: %s", id, err)
end

return NginxRedisLoop
