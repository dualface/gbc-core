
local UserAction = cc.class("UserAction")

local OnlineService = cc.load("online").service

function UserAction:ctor(connect)
    self.connect = connect
    self.online = OnlineService:create(connect)
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
    if self.online:isExists(username) then
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
