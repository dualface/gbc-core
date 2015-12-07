--[[

Copyright (c) 2015 gameboxcloud.com

Permission is hereby granted, free of chargse, to any person obtaining a copy
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

local Session = cc.import("#session")

local gbc = cc.import("#gbc")
local UserAction = cc.class("UserAction", gbc.ActionBase)

local _opensession

function UserAction:init()
    self._redis = self.instance:getRedis()
end

function UserAction:signinAction(args)
    local username = args.username
    if not username then
        cc.throw("not set argsument: \"username\"")
    end

    -- start session
    local session = Session:new(self._redis)
    session:start()
    session:set("username", username)
    session:set("count", 0)
    session:save()

    -- return result
    return {sid = session:getSid(), count = 0}
end

function UserAction:signoutAction(args)
    local session = _opensession(self._redis, args)

    -- send control message to websocket connect
    local connectId = session:get("connect")
    local broadcast = gbc.Broadcast:new(self._redis)
    broadcast:sendControlMessage(connectId, gbc.Constants.CLOSE_CONNECT)

    -- delete session
    session:destroy()

    return {ok = "ok"}
end

function UserAction:countAction(args)
    -- update count value in session
    local session = _opensession(self._redis, args)
    local count = session:get("count")
    count = count + 1
    session:set("count", count)
    session:save()

    return {count = count}
end

-- private

_opensession = function(redis, args)
    local sid = args.sid
    if not sid then
        cc.throw("not set argsument: \"sid\"")
    end

    local session = Session:new(redis)
    if not session:start(sid) then
        cc.throw("session is expired, or invalid session id")
    end

    return session
end

return UserAction
