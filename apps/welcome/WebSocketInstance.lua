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

local Online = cc.import("#online")
local Session = cc.import("#session")

local gbc = cc.import("#gbc")
local Constants = gbc.Constants
local Broadcast = gbc.Broadcast

local WebSocketInstance = cc.class("WebSocketInstance", gbc.WebSocketInstanceBase)

local _EVENT = WebSocketInstance.EVENT

local _CONNECT_TO_USERNAME = "_CONNECT_TO_USERNAME"
local _USERNAME_TO_CONNECT = "_USERNAME_TO_CONNECT"
local _LIST_ALL_USERS      = "LIST_ALL_USERS"

function WebSocketInstance:ctor(config)
    WebSocketInstance.super.ctor(self, config)
    self:addEventListener(_EVENT.CONNECTED, cc.handler(self, self.onConnected))
    self:addEventListener(_EVENT.DISCONNECTED, cc.handler(self, self.onDisconnected))

    self._broadcast = Broadcast.new(self:getRedis())
end

function WebSocketInstance:sendMessageToUser(recipient, message)
    local redis = self:getRedis()
    -- query connect id by recipient
    local id, err = redis:hget(_USERNAME_TO_CONNECT, recipient)
    if not id then
        cc.printwarn(err)
        return
    end
    -- send message to connect id
    self._broadcast:sendMessage(id, {
        name      = "MESSAGE",
        sender    = self._username,
        recipient = recipient,
        body      = message
    }, self.config.app.websocketMessageFormat)
end

function WebSocketInstance:onConnected()
    local redis = self:getRedis()

    -- get username from session
    local sid = self._connectToken -- token is session id
    local session = Session.new(redis)
    session:start(sid)
    local username = session:get("username")
    self._username = username
    -- save connect id to session
    session:set("connect", self._connectId)
    session:save()
    self._session = session

    -- add user to online users list
    local online = Online.new(redis)
    online:add(username)
    -- send all usernames to current client
    local users = online:getAll()
    self:sendMessage({name = _LIST_ALL_USERS, users = users})
    -- subscribe online users event
    self:subscribe(online:getChannel())

    -- map username <-> connect id
    local id = self._connectId
    redis:hset(_CONNECT_TO_USERNAME, id, username)
    redis:hset(_USERNAME_TO_CONNECT, username, id)

    self._session = session
    self._online = online
end

function WebSocketInstance:onDisconnected()
    -- remove user from online list
    local session = self._session
    local username = session:get("username")
    self._online:remove(username)

    -- remove map
    local redis = self:getRedis()
    local id = self._connectId
    redis:hdel(_CONNECT_TO_USERNAME, id)
    redis:hdel(_USERNAME_TO_CONNECT, username)
end

function WebSocketInstance:heartbeat()
    if self._session then
        -- refresh session expired time
        self._session:setKeepAlive()
    end
end

return WebSocketInstance
