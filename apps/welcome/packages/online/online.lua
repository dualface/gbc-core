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

local json = cc.import("#json")
local gbc = cc.import("#gbc")

local Online = cc.class("Online")

local _ONLINE_SET        = "_ONLINE_USERS"
local _ONLINE_CHANNEL    = "_ONLINE_CHANNEL"
local _EVENT = table.readonly({
    ADD_USER    = "ADD_USER",
    REMOVE_USER = "REMOVE_USER",
})
local _CONNECT_TO_USERNAME = "_CONNECT_TO_USERNAME"
local _USERNAME_TO_CONNECT = "_USERNAME_TO_CONNECT"

function Online:ctor(instance)
    self._instance  = instance
    self._redis     = instance:getRedis()
    self._broadcast = gbc.Broadcast:new(self._redis, instance.config.app.websocketMessageFormat)
end

function Online:getAll()
    return self._redis:smembers(_ONLINE_SET)
end

function Online:add(username, connectId)
    local redis = self._redis
    redis:initPipeline()
    -- map username <-> connect id
    redis:hset(_CONNECT_TO_USERNAME, connectId, username)
    redis:hset(_USERNAME_TO_CONNECT, username, connectId)
    -- add username to set
    redis:sadd(_ONLINE_SET, username)
    -- send event to all clients
    redis:publish(_ONLINE_CHANNEL, json.encode({name = _EVENT.ADD_USER, username = username}))
    redis:commitPipeline()
end

function Online:remove(username)
    local redis = self._redis
    local connectId = redis:hget(_USERNAME_TO_CONNECT, username)

    redis:initPipeline()
    -- remove map
    redis:hdel(_CONNECT_TO_USERNAME, connectId)
    redis:hdel(_USERNAME_TO_CONNECT, username)
    -- remove username from set
    redis:srem(_ONLINE_SET, username)
    redis:publish(_ONLINE_CHANNEL, json.encode({name = _EVENT.REMOVE_USER, username = username}))
    redis:commitPipeline()

    self._broadcast:sendControlMessage(connectId, gbc.Constants.CLOSE_CONNECT)
end

function Online:getChannel()
    return _ONLINE_CHANNEL
end

function Online:sendMessage(recipient, event)
    local redis = self._redis
    -- query connect id by recipient
    local connectId, err = redis:hget(_USERNAME_TO_CONNECT, recipient)
    if not connectId then
        cc.printwarn(err)
        return
    end

    if connectId == redis.null then
        cc.printwarn("not found recipient '%s'", recipient)
        return
    end

    -- send message to connect id
    self._broadcast:sendMessage(connectId, event)
end

function Online:sendMessageToAll(event)
    self._broadcast:sendMessageToAll(event)
end

return Online
