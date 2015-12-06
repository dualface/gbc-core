local Session = cc.import("#session")
local gbc = cc.import("#gbc")

local ConnectIDService = cc.import("#bService").ConnectIDService

local Broadcast = gbc.Broadcast

local WebSocketInstanceBz = cc.class("WebSocketInstanceBz", gbc.WebSocketInstanceBase)

local _EVENT = WebSocketInstanceBz.EVENT

function WebSocketInstanceBz:ctor(config)
    WebSocketInstanceBz.super.ctor(self, config)
    self:addEventListener(_EVENT.CONNECTED, cc.handler(self, self.onConnected))
    self:addEventListener(_EVENT.DISCONNECTED, cc.handler(self, self.onDisconnected))
end

function WebSocketInstanceBz:initInstance()
    local redis = self:getRedis()
    self._ConnIDs = ConnectIDService:create(redis)
    self._Broadcast = Broadcast:create(redis, self)
end

function WebSocketInstanceBz:sendMessageToUser(user, message)
    local cids = self._ConnIDs
    if cids then
        local connectId = cids:getConnectId(user)
        if connectId and self._Broadcast then
            self._Broadcast:sendMessage(connectId, message, self.config.app.websocketMessageFormat)
        end
    end
end

function WebSocketInstanceBz:closeConnect()
    local cid = self._connectId
    if cid and self._Broadcast then
        self._Broadcast:sendControlMessage(cid, gbc.Constants.CLOSE_CONNECT)
    end
end

function WebSocketInstanceBz:verifyToken(token)
    return token
end

local _LOCK_SID = "_LOCK_SID"
function WebSocketInstanceBz:lockSID(sid)
    local ret = self:getRedis():hincrby(_LOCK_SID, sid, 1)
    if ret > 1 then
        return false
    else
        return true
    end
end

function WebSocketInstanceBz:unlockSID(sid)
    self:getRedis():hdel(_LOCK_SID, sid)
end

function WebSocketInstanceBz:onConnected()
    local cid = self._connectId
    local redis = self:getRedis()
    local sid = self:verifyToken(self._connectToken)
    if not sid then
        self:closeConnect()
        cc.throw("verifyToken failed")
    end
    if not self:lockSID(sid) then
        self:closeConnect()
        cc.throw("sid:"..sid.." is been used")
    end

    local session = Session.new(redis)
    session:start(sid)
    local user = session:get("user")
    if user then
        self:initInstance()
        self._ConnIDs:save(cid, user)
        self._session = session
    else
        self:closeConnect()
        cc.throw("can not find the user")
    end
end

function WebSocketInstanceBz:onDisconnected()
    local cid = self._connectId
    if self._ConnIDs then
        self._ConnIDs:remove(cid)
    end
    if self._session then
        local sid = self._session:getSid()
        self:unlockSID(sid)
    end
end

function WebSocketInstanceBz:heartbeat()
    if self._session then
        self._session:setKeepAlive()
    end
end

return WebSocketInstanceBz
