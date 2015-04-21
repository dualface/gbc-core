
local WebSocketConnectBase = require("server.base.WebSocketConnectBase")
local WebSocketConnect = class("WebSocketConnect", WebSocketConnectBase)

local ConnectIdService = cc.load("connectid").service
local OnlineService = cc.load("online").service

function WebSocketConnect:ctor(config)
    printInfo("new WebSocketConnect instance")
    WebSocketConnect.super.ctor(self, config)
end

function WebSocketConnect:onUserAdd(event)
    local userdata = self.online:get(event.username)
    self:sendMessageToSelf({name = "adduser", username = event.username, tag = userdata.tag})
end

function WebSocketConnect:onUserRemove(event)
    self:sendMessageToSelf({name = "removeuser", username = event.username})
end

function WebSocketConnect:afterConnectReady()
    -- add user to online list
    local session = self:getSession()
    local username = session:get("username")
    local tag = session:get("tag")
    self.online = OnlineService:create(self)
    self.online:add(username, {tag = tag})

    -- register events
    self.online:addEventListener(OnlineService.USER_ADD_EVENT, handler(self, self.onUserAdd))
    self.online:addEventListener(OnlineService.USER_REMOVE_EVENT, handler(self, self.onUserRemove))
    self.online:setEventsEnabled(true)

    -- send all users name to client
    local all = self.online:getAll()
    self:sendMessageToSelf({name = "allusers", users = all})

    -- set connect tag
    local connectId = self:getConnectId()
    self.connects = ConnectIdService:create(self:getRedis())
    self.connects:setTag(connectId, tag)
end

function WebSocketConnect:beforeConnectClose()
    -- remove user from online list
    local session = self:getSession()
    local username = session:get("username")
    self.online:remove(username)

    -- remove connect tag
    local connectId = self:getConnectId()
    self.connects:removeTag(connectId)
end

return WebSocketConnect
