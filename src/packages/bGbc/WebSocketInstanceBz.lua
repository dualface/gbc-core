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
    self:addEventListener(_EVENT.CONTROL_MESSAGE, cc.handler(self, self.onControlMessage))
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

function WebSocketInstanceBz:sendMessageToSelf(message)
    local connectId = self._connectId
    if connectId and self._Broadcast then
        self._Broadcast:sendMessage(connectId, message, self.config.app.websocketMessageFormat)
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

function WebSocketInstanceBz:authConnect()
    local token, err = WebSocketInstanceBz.super.authConnect(self)
    if token then
        token = self:verifyToken(token)
    end
    return token, err
end

function WebSocketInstanceBz:onLoadUser()
    return nil
end

function WebSocketInstanceBz:onUnloadUser()
end

function WebSocketInstanceBz:onControlMessage()
end

function WebSocketInstanceBz:onConnected()
    local connectId = self._connectId
    local redis = self:getRedis()
    local sid = self._connectToken

    local session = Session.new(redis)
    session:start(sid)
    local ok, user = pcall(function()
        return self:onLoadUser(session)
    end)
    if ok then
        self:initInstance()
        self._ConnIDs:save(connectId, user)
        self._session = session
    else
        cc.printerror(user)
    end
end

function WebSocketInstanceBz:onDisconnected()
    local ok, err = pcall(function()
        return self:onUnloadUser()
    end)
    if not ok then
        cc.printerror(err)
    end
    local connectId = self._connectId
    if self._ConnIDs then
        self._ConnIDs:remove(connectId)
    end
    if self._session then
        self._session:destroy()
    end
end

function WebSocketInstanceBz:heartbeat()
    if self._session then
        self._session:setKeepAlive()
    end
end

return WebSocketInstanceBz
