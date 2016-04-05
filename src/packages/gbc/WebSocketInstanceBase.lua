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

local ngx              = ngx
local ngx_log          = ngx.log
local ngx_md5          = ngx.md5
local ngx_thread_spawn = ngx.thread.spawn
local req_get_headers  = ngx.req.get_headers
local req_read_body    = ngx.req.read_body
local string_format    = string.format
local string_sub       = string.sub
local table_concat     = table.concat
local table_insert     = table.insert
local tostring         = tostring
local type             = type

local json      = cc.import("#json")
local Constants = cc.import(".Constants")

local json_encode = json.encode
local json_decode = json.decode

local InstanceBase = cc.import(".InstanceBase")
local WebSocketInstanceBase = cc.class("WebSocketInstanceBase", InstanceBase)

local _EVENT = table.readonly({
    CONNECTED       = "CONNECTED",
    DISCONNECTED    = "DISCONNECTED",
    CONTROL_MESSAGE = "CONTROL_MESSAGE",
})

WebSocketInstanceBase.EVENT = _EVENT

local _processMessage, _parseMessage, _authConnect

function WebSocketInstanceBase:ctor(config)
    WebSocketInstanceBase.super.ctor(self, config, Constants.WEBSOCKET_REQUEST_TYPE)

    local appConfig = self.config.app
    if config.app.websocketMessageFormat then
        appConfig.messageFormat = config.app.websocketMessageFormat
    end
    appConfig.websocketsTimeout = appConfig.websocketsTimeout or Constants.WEBSOCKET_DEFAULT_TIME_OUT
    appConfig.websocketsMaxPayloadLen = appConfig.websocketsMaxPayloadLen or Constants.WEBSOCKET_DEFAULT_MAX_PAYLOAD_LEN
end

function WebSocketInstanceBase:run()
    local ok, err = xpcall(function()
        self:runEventLoop()
        ngx.exit(ngx.OK)
    end, function(err)
        err = tostring(err)
        if cc.DEBUG > cc.DEBUG_WARN then
            ngx_log(ngx.ERR, err .. debug.traceback("", 3))
        else
            ngx_log(ngx.ERR, err)
        end
        ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
        ngx.exit(ngx.ERROR)
    end)
end

function WebSocketInstanceBase:runEventLoop()
    -- auth client
    local token, err = _authConnect()
    if not token then
        cc.throw(err)
    end
    self._connectToken = token

    -- generate connect id and channel
    local redis = self:getRedis()
    local connectId = tostring(redis:incr(Constants.NEXT_CONNECT_ID_KEY))
    self._connectId = connectId

    local connectChannel = Constants.CONNECT_CHANNEL_PREFIX .. tostring(connectId)
    self._connectChannel = connectChannel
    local controlChannel = Constants.CONTROL_CHANNEL_PREFIX .. tostring(connectId)
    self._controlChannel = controlChannel

    -- create websocket server
    local server = require("resty.websocket.server")
    local socket, err = server:new({
        timeout         = self.config.app.websocketsTimeout,
        max_payload_len = self.config.app.websocketsMaxPayloadLen,
    })
    if err then
        cc.throw("[websocket:%s] create websocket server failed, %s", connectId, err)
    end
    self._socket = socket

    -- tracking socket close reason
    local closeReason = ""

    -- create subscribe loop
    local sub, err = self:getRedis():makeSubscribeLoop(connectId)
    if not sub then
        cc.throw(err)
    end

    local event = self._event
    sub:start(function(channel, msg)
        if channel == controlChannel then
            event:trigger({
                name    = _EVENT.CONTROL_MESSAGE,
                channel = channel,
                message = msg
            })
            if msg == Constants.CLOSE_CONNECT then
                closeReason = Constants.CLOSE_CONNECT
                socket:send_close()
            end
        else
            socket:send_text(msg)
        end
    end, controlChannel, connectChannel, Constants.BROADCAST_ALL_CHANNEL)
    self._subloop = sub

    -- connected
    cc.printinfo("[websocket:%s] connected", connectId)
    event:trigger(_EVENT.CONNECTED)

    -- event loop
    local frames = {}
    local running = true
    while running do
        self:heartbeat()

        while true do
            --[[
            Receives a WebSocket frame from the wire.

            In case of an error, returns two nil values and a string describing the error.

            The second return value is always the frame type, which could be
            one of continuation, text, binary, close, ping, pong, or nil (for unknown types).

            For close frames, returns 3 values: the extra status message
            (which could be an empty string), the string "close", and a Lua number for
            the status code (if any). For possible closing status codes, see

            http://tools.ietf.org/html/rfc6455#section-7.4.1

            For other types of frames, just returns the payload and the type.

            For fragmented frames, the err return value is the Lua string "again".
            ]]
            local frame, ftype, err = socket:recv_frame()
            if err then
                if err == "again" then
                    frames[#frames + 1] = frame
                    break -- recv next message
                end

                if string_sub(err, -7) == "timeout" then
                    break -- recv next message
                end

                cc.printwarn("[websocket:%s] failed to receive frame, type \"%s\", %s", connectId, ftype, err)
                closeReason = ftype
                running = false -- stop loop
                break
            end

            if #frames > 0 then
                -- merging fragmented frames
                frames[#frames + 1] = frame
                frame = table_concat(frames)
                frames = {}
            end

            if ftype == "close" then
                running = false -- stop loop
                break
            elseif ftype == "ping" then
                socket:send_pong()
            elseif ftype == "pong" then
                -- client ponged
            elseif ftype == "text" or ftype == "binary" then
                local ok, err = _processMessage(self, frame, ftype)
                if err then
                    cc.printerror("[websocket:%s] process %s message failed, %s", connectId, ftype, err)
                end
            else
                cc.printwarn("[websocket:%s] unknown frame type \"%s\"", connectId, tostring(ftype))
            end
        end -- rect next message
    end -- loop

    sub:stop()
    self._subloop = nil
    self._socket = nil

    -- disconnected
    event:trigger({name = _EVENT.DISCONNECTED, reason = reason})
    cc.printinfo("[websocket:%s] disconnected", connectId)
end

function WebSocketInstanceBase:heartbeat()
end

function WebSocketInstanceBase:getConnectToken()
    return self._connectToken
end

function WebSocketInstanceBase:getConnectId()
    return self._connectId
end

function WebSocketInstanceBase:getConnectChannel()
    return self._connectChannel
end

function WebSocketInstanceBase:getControlChannel()
    return self._controlChannel
end

-- add methods

local _COMMANDS = {
    "subscribe", "unsubscribe",
    "psubscribe", "punsubscribe",
}

for _, cmd in ipairs(_COMMANDS) do
    WebSocketInstanceBase[cmd] = function(self, ...)
        local subloop = self._subloop
        local method = subloop[cmd]
        return method(subloop, ...)
    end
end

-- private

_processMessage = function(self, rawMessage, messageType)
    local message = _parseMessage(rawMessage, messageType, self.config.app.websocketMessageFormat)
    local msgid = message.__id
    local actionName = message.action
    local err = nil
    local ok, result = xpcall(function()
        return self:runAction(actionName, message)
    end, function(_err)
        err = _err
        if cc.DEBUG > cc.DEBUG_WARN then
            err = err .. debug.traceback("", 4)
        end
    end)
    if err then
        return nil, err
    end

    local rtype = type(result)
    if rtype == "nil" then
        return
    end

    if rtype ~= "table" then
        if msgid then
           cc.printwarn("action \"%s\" return invalid result for message [__id:\"%s\"]", actionName, msgid)
        else
           cc.printwarn("action \"%s\" return invalid result", actionName)
        end
    end

    if not msgid then
       cc.printwarn("action \"%s\" return unused result", actionName)
        return true
    end

    if not self._socket then
        return nil, string.format("socket removed, action \"%s\"", actionName)
    end

    result.__id = msgid
    local message = json_encode(result)
    local bytes, err = self._socket:send_text(message)
    if err then
        return nil, string.format("send message to client failed, %s", err)
    end

    return true
end

_parseMessage = function(rawMessage, messageType, messageFormat)
    -- TODO: support message type plugin
    if messageType ~= Constants.WEBSOCKET_TEXT_MESSAGE_TYPE then
        cc.throw("not supported message type \"%s\"", messageType)
    end

    -- TODO: support message format plugin
    if messageFormat == "json" then
        local message = json_decode(rawMessage)
        if type(message) == "table" then
            return message
        else
            cc.throw("not supported message format \"%s\"", type(message))
        end
    else
        cc.throw("not support message format \"%s\"", tostring(messageFormat))
    end
end

_authConnect = function()
    if ngx.headers_sent then
        return nil, "response header already sent"
    end

    req_read_body()
    local headers = ngx.req.get_headers()
    local protocols = headers["sec-websocket-protocol"]
    if type(protocols) ~= "table" then
        protocols = {protocols}
    end
    if #protocols == 0 then
        return nil, "not set header: Sec-WebSocket-Protocol"
    end

    local pattern = Constants.WEBSOCKET_SUBPROTOCOL_PATTERN
    for _, protocol in ipairs(protocols) do
        local token = string.match(protocol, pattern)
        if token then
            return token
        end
    end

    return nil, "not found token in header: Sec-WebSocket-Protocol"
end

return WebSocketInstanceBase
