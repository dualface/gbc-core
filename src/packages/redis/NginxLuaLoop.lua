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
local ngx_thread_spawn   = ngx.thread.spawn
local ngx_thread_kill    = ngx.thread.kill
local string_byte        = string.byte
local string_split       = string.split
local string_sub         = string.sub
local table_concat       = table.concat
local table_remove       = table.remove
local tostring           = tostring
local unpack             = unpack

local NginxLuaLoop = cc.class("NginxLuaLoop")

local _FORWARD_CHANNEL = "_GBC_LOOP_FORWARD_CHANNEL"
local _COMMANDS = {
    "subscribe", "unsubscribe",
    "psubscribe", "punsubscribe",
}
local _CMD_PATTERN = "%s %s"

local _loop, _cleanup, _onmessage, _onerror

function NginxLuaLoop:ctor(redis, subredis)
    self._redis = redis
    self._subredis = subredis
    self._subredis:setTimeout(3) -- check client connect abort quickly
    self._id = string_sub(tostring(self), 8)
end

function NginxLuaLoop:start(callbacks)
    if not self._subredis then
        return nil, "not initialized"
    end
    local onmessage = callbacks.onmessage or _onmessage
    local onerror = callbacks.onerror or _onerror
    self._thread = ngx_thread_spawn(_loop, self, onmessage, onerror)
    self._redis:publish(_FORWARD_CHANNEL, self._id, "PING") -- make loop run
    return 1
end

function NginxLuaLoop:stop()
    self._redis:publish(_FORWARD_CHANNEL, "QUIT " .. self._id)
    _cleanup(self)
end

-- add methods

for _, cmd in ipairs(_COMMANDS) do
    NginxLuaLoop[cmd] = function(self, ...)
        local args = {cmd, self._id}
        for _, arg in ipairs({...}) do
            args[#args + 1] = tostring(arg)
        end
        return self._redis:publish(_FORWARD_CHANNEL, table_concat(args, " "))
    end
end

-- private

_loop = function(self, onmessage, onerror)
    local subredis = self._subredis
    local id = self._id
    subredis:subscribe(_FORWARD_CHANNEL)

    while true do
        local res, err = subredis:readReply()
        if not res then
            if err == "timeout" then
                cc.printinfo("timeout")
                goto wait_next_msg
            end

            onerror(err)
            break
        end

        local msgtype = res[1]
        local channel = res[2]
        local msg     = res[3]

        if channel ~= _FORWARD_CHANNEL then
            if msgtype == "message" then
                onmessage(channel, msg)
            elseif msgtype == "pmessage" then
                local pchannel = channel
                channel = msg
                msg = res[4]
                onmessage(channel, msg, pchannel)
            else
                cc.printinfo("[RedisSub] [%s] %s", id, table_concat(res, " "))
            end
            goto wait_next_msg
        end

        local parts = string_split(msg, " ")
        local cmd = parts[1]
        local cmdid = parts[2]
        if cmdid ~= id then
            goto wait_next_msg
        end

        cc.printinfo("[RedisSub] [%s] FORWARD: %s", id, msg)

        if cmd == "QUIT" then
            break -- stop loop
        end

        if cmd == "PING" then
            goto wait_next_msg
        end

        table_remove(parts, 2) -- remove id
        local ok, err = subredis:doCommand(unpack(parts))
        if not ok then
            cc.printwarn("[RedisSub] redis failed, %s", err)
        end

::wait_next_msg::

    end

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

_onmessage = function(channel, msg, pchannel)
    if pchannel then
        cc.printinfo("[RedisSub] [%s] [%s] %s", pchannel, channel, msg)
    else
        cc.printinfo("[RedisSub] [%s] %s", channel, msg)
    end
end

_onerror = function(err)
    cc.printwarn("[RedisSub] onerror: %s", err)
end

return NginxLuaLoop
