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

local gbc = cc.import("#gbc")
local Online = cc.import("#online")

local UserAction = cc.class("UserAction", gbc.server.ActionBase)

function UserAction:oninit()
    self._online = Online:create(connect)
end

function UserAction:pingAction(arg)
    return {text = "pong"}
end

function UserAction:loginAction(arg)
    local username = arg.username
    if not username then
        cc.throw("not set argument: \"username\"")
    end

    -- check username is exists
    if self._online:isExists(username) then
        cc.throw("username \"%s\" is exists", username)
    end

    -- start session
    local session = self.connect:newSession()
    session:set("username", username)

    -- generating tag by session id
    local sid = session:getSid()
    local tag = ngx.md5(sid)
    session:set("tag", tag)

    -- set count value
    local count = 0
    session:set("count", count)
    session:save()

    -- return result
    return {sid = sid, tag = tag, count = count}
end

function UserAction:logoutAction(arg)
    local sid = arg.sid
    if not sid then
        cc.throw("not set argument: \"sid\"")
    end

    local session = self.connect:openSession(sid)
    if not session then
        cc.throw("session is expired, or invalid session id")
    end

    -- close websocket connect
    self.connect:closeConnect(session:getConnectId())
    -- destroy session
    self.connect:destroySession()
    return {ok = "ok"}
end

function UserAction:countAction(arg)
    local sid = arg.sid
    if not sid then
        cc.throw("not set argument: \"sid\"")
    end

    local session = self.connect:openSession(sid)
    if not session then
        cc.throw("session is expired, or invalid session id")
    end

    -- update count value
    local count = session:get("count")
    count = count + 1
    session:set("count", count)
    session:save()
    return {count = count}
end

return UserAction
