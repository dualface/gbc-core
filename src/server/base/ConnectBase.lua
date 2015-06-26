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

local clone = clone
local checktable = checktable
local ngx = ngx
local ngx_now = ngx.now
local ngx_md5 = ngx.md5
local json_encode = json.encode

local Constants = import(".Constants")
local SessionService = import(".SessionService")
local RedisService = cc.load("redis").service

local ActionDispatcher = import(".ActionDispatcher")
local ConnectBase = class("ConnectBase", ActionDispatcher)

function ConnectBase:ctor(config)
    ConnectBase.super.ctor(self, config)
    self.config.app.messageFormat = self.config.app.messageFormat or Constants.DEFAULT_MESSAGE_FORMAT
end

function ConnectBase:getRequestType()
    return self._requestType or "unknow"
end

function ConnectBase:run()
    throw("ConnectBase:run() - must override in inherited class")
end

function ConnectBase:runEventLoop()
    throw("ConnectBase:runEventLoop() - must override in inherited class")
end

function ConnectBase:getSession()
    return self._session
end

function ConnectBase:openSession(sid)
    if self._session then
        throw("session \"%s\" already exists, disallow open an other session", self._session:getSid())
    end
    if type(sid) ~= "string" or sid == "" then
        throw("open session with invalid sid")
    end
    self._session = self:_loadSession(sid)
    return self._session
end

function ConnectBase:newSession()
    if self._session then
        throw("session \"%s\" already exists, disallow start a new session", self._session:getSid())
    end
    self._session = self:_genSession()
    return self._session
end

function ConnectBase:destroySession()
    if self._session then
        self._session:destroy()
        self._session = nil
    end
end

function ConnectBase:closeConnect(connectId)
    if not connectId then
        throw("invalid connect id \"%s\"", tostring(connectId))
    end
    self:sendMessageToConnect(connectId, "QUIT")
end

function ConnectBase:sendMessageToConnect(connectId, message)
    if not connectId then
        throw("send message to connect with invalid id \"%s\"", tostring(connectId))
    end
    local channelName = Constants.CONNECT_CHANNEL_PREFIX .. tostring(connectId)
    self:sendMessageToChannel(channelName, message)
end

function ConnectBase:sendMessageToChannel(channelName, message)
    if not channelName or not message then
        throw("send message to channel with invalid channel name \"%s\" or invalid message", tostring(channelName))
    end
    if self.config.app.messageFormat == Constants.MESSAGE_FORMAT_JSON and type(message) == "table" then
        message = json_encode(message)
    end
    local redis = self:getRedis()
    redis:command("PUBLISH", channelName, tostring(message))
end

function ConnectBase:getRedis()
    if not self._redis then
        self._redis = self:_newRedis()
    end
    return self._redis
end

function ConnectBase:_loadSession(sid)
    local redis = self:getRedis()
    local session = SessionService.load(redis, sid, self.config.app.sessionExpiredTime, ngx.var.remote_addr)
    if session then
        session:setKeepAlive()
        printInfo("load session \"%s\"", sid)
    end
    return session
end

function ConnectBase:_genSession()
    local addr = ngx.var.remote_addr
    local now = ngx_now()
    math.newrandomseed()
    local random = math.random() * 100000000000000
    local mask = string.format("%0.5f|%0.10f|%s", now, random, self._secret)
    local origin = string.format("%s|%s", addr, ngx_md5(mask))
    local sid = ngx_md5(origin)
    return SessionService:create(self:getRedis(), sid, self.config.app.sessionExpiredTime, addr)
end

function ConnectBase:_newRedis()
    local redis = RedisService:create(self.config.server.redis)
    local ok, err = redis:connect()
    if err then
        throw("connect internal redis failed, %s", err)
    end
    return redis
end

return ConnectBase
