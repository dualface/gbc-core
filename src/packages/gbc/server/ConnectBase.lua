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
local ngx = ngx

local Constants = cc.import(".Constants")
local SessionService = cc.import(".SessionService")

local AppBase = cc.import(".AppBase")
local ConnectBase = cc.class("ConnectBase", AppBase)

function ConnectBase:ctor(config)
    ConnectBase.super.ctor(self, config)
    self.config.app.messageFormat = self.config.app.messageFormat or Constants.DEFAULT_MESSAGE_FORMAT
end

function ConnectBase:run()
    cc.throw("ConnectBase:run() - must override in inherited class")
end

function ConnectBase:runEventLoop()
    cc.throw("ConnectBase:runEventLoop() - must override in inherited class")
end

function ConnectBase:getSession()
    return self._session
end

function ConnectBase:openSession(sid)
    if self._session then
        cc.throw("session \"%s\" already exists, disallow open an other session", self._session:getSid())
    end
    if type(sid) ~= "string" or sid == "" then
        cc.throw("open session with invalid sid")
    end
    self._session = self:_loadSession(sid)
    return self._session
end

function ConnectBase:newSession()
    if self._session then
        cc.throw("session \"%s\" already exists, disallow start a new session", self._session:getSid())
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

function ConnectBase:_loadSession(sid)
    local redis = self:getRedis()
    local session = SessionService.load(redis, sid, self.config.app.sessionExpiredTime, ngx.var.remote_addr)
    if session then
        session:setKeepAlive()
       cc.printinfo("load session \"%s\"", sid)
    end
    return session
end

function ConnectBase:_genSession()
    local addr = ngx.var.remote_addr
    local now = ngx.now()
    math.newrandomseed()
    local random = math.random() * 100000000000000
    local mask = string.format("%0.5f|%0.10f|%s", now, random, self._secret)
    local origin = string.format("%s|%s", addr, ngx.md5(mask))
    local sid = ngx.md5(origin)
    return SessionService:create(self:getRedis(), sid, self.config.app.sessionExpiredTime, addr)
end

return ConnectBase
