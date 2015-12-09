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

local tostring = tostring
local type     = type

local json      = cc.import("#json")
local Constants = cc.import(".Constants")

local json_encode = json.encode

local Broadcast = cc.class("Broadcast")

local _formatmsg

function Broadcast:ctor(redis, messageType, websocketInstance)
    self._redis = redis
    self._messageType = messageType
    if websocketInstance and websocketInstance.getConnectId then
        self._websocketInstance = websocketInstance
    end
end

function Broadcast:sendMessage(connectId, message, format)
    format = format or self._messageType
    message = _formatmsg(message, format)

    if self._websocketInstance and self._websocketInstance:getConnectId() == connectId then
        return self._websocketInstance._socket:send_text(tostring(message))
    else
        local connectChannel = Constants.CONNECT_CHANNEL_PREFIX .. connectId
        local ok, err = self._redis:publish(connectChannel, message)
        if not ok then
            return nil, err
        end
        return 1
    end
end

function Broadcast:sendMessageToAll(message, format)
    format = format or self._messageType
    message = _formatmsg(message, format)
    return self._redis:publish(Constants.BROADCAST_ALL_CHANNEL, message)
end

function Broadcast:sendControlMessage(connectId, message)
    local controlChannel = Constants.CONTROL_CHANNEL_PREFIX .. connectId
    local ok, err = self._redis:publish(controlChannel, tostring(message))
    if not ok then
        return nil, err
    end
    return 1
end

-- private

_formatmsg = function(message, format)
    format = format or Constants.MESSAGE_FORMAT_JSON
    if type(message) == "table" then
        if format == Constants.MESSAGE_FORMAT_JSON then
            message = json_encode(message)
        else
            -- TODO: support more message formats
        end
    end
    return tostring(message)
end

return Broadcast
