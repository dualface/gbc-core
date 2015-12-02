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

local ipairs             = ipairs
local ngx_thread_kill    = ngx.thread.kill
local ngx_thread_spawn   = ngx.thread.spawn
local string_byte        = string.byte
local string_split       = string.split
local string_sub         = string.sub
local table_concat       = table.concat
local table_insert       = table.insert
local table_remove       = table.remove
local tostring           = tostring
local unpack             = unpack

local NginxRedisLoop = cc.class("NginxRedisLoop")

local _loop, _cleanup, _onmessage, _onerror

function NginxRedisLoop:ctor(redis, subredis, id)
    self._redis = redis
    self._subredis = subredis
    self._subredis:setTimeout(3) -- check client connect abort quickly
    id = id or ""
    self._id = id .. "_" .. string_sub(tostring(self), 10)
end

function NginxRedisLoop:start(onmessage, cmdchannel)
    if not self._subredis then
        return nil, "not initialized"
    end
    local onmessage = onmessage or _onmessage
    local onerror = _onerror
    self._cmdchannel = cmdchannel
    self._thread = ngx_thread_spawn(_loop, self, onmessage, onerror)
    self._redis:publish(cmdchannel, self._id, "!PING") -- make loop run
    return 1
end

function NginxRedisLoop:stop()
    self._redis:publish(self._cmdchannel, "!STOP")
    _cleanup(self)
end

-- add methods

local _COMMANDS = {
    "subscribe", "unsubscribe",
    "psubscribe", "punsubscribe",
}

for _, cmd in ipairs(_COMMANDS) do
    NginxRedisLoop[cmd] = function(self, ...)
        local args = {cmd, self._id}
        for _, arg in ipairs({...}) do
            args[#args + 1] = tostring(arg)
        end
        table_insert(args, 1, "!REDIS")
        return self._redis:publish(self._cmdchannel, table_concat(args, " "))
    end
end

-- private

_loop = function(self, onmessage, onerror)
    local cmdchannel = self._cmdchannel
    local subredis   = self._subredis
    local id         = self._id
    subredis:subscribe(cmdchannel)

    while true do
        local res, err = subredis:readReply()
        if not res then
            if err == "timeout" then
                goto wait_next_msg
            end

            onerror(err, id)
            break
        end

        local msgtype = res[1]
        local channel = res[2]
        local msg     = res[3]

        if channel == cmdchannel then
            local parts = string_split(msg, " ")
            local cmd = parts[1]
            cc.printinfo("[RedisSub:%s] COMMAND: %s", id, msg)

            if cmd == "!STOP" then
                break -- stop loop
            end

            if cmd == "!PING" then
                goto wait_next_msg
            end

            if cmd == "!REDIS" then
                table_remove(parts, 1)
                local ok, err = subredis:doCommand(unpack(parts))
                if not ok then
                    cc.printwarn("[RedisSub:%s] redis failed, %s", id, err)
                end
                goto wait_next_msg
            end

            -- unknown command, forward it
            onmessage(channel, msg, nil, id)
        else
            if msgtype == "message" then
                onmessage(channel, msg, nil, id)
            elseif msgtype == "pmessage" then
                local pchannel = channel
                channel = msg
                msg = res[4]
                onmessage(channel, msg, pchannel, id)
            else
                cc.printinfo("[RedisSub:%s] %s", id, table_concat(res, " "))
            end
        end

::wait_next_msg::

    end

    cc.printinfo("[RedisSub:%s] STOPPED", id)

    subredis:unsubscribe()
    subredis:setKeepAlive()
    _cleanup(self)
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
