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

local type = type
local tostring = tostring
local ngx = ngx
local ngx_log = ngx.log
local ngx_thread_spawn = ngx.thread.spawn
local ngx_md5 = ngx.md5
local req_read_body = ngx.req.read_body
local req_get_headers = ngx.req.get_headers
local table_insert = table.insert
local table_concat = table.concat
local string_format = string.format
local string_sub = string.sub

local json = cc.load("json")
local Constants = cc.import(".Constants")

local ConnectBase = cc.import(".ConnectBase")
local WebSocketConnectBase = cc.class("WebSocketConnectBase", ConnectBase)

function WebSocketConnectBase:ctor(config)
    WebSocketConnectBase.super.ctor(self, config)

    if config.app.websocketMessageFormat then
        self.config.app.messageFormat = config.app.websocketMessageFormat
    end

    self.config.app.websocketsTimeout       = self.config.app.websocketsTimeout or Constants.WEBSOCKET_DEFAULT_TIME_OUT
    self.config.app.websocketsMaxPayloadLen = self.config.app.websocketsMaxPayloadLen or Constants.WEBSOCKET_DEFAULT_MAX_PAYLOAD_LEN
    self.config.app.maxSubscribeRetryCount  = self.config.app.maxSubscribeRetryCount or Constants.WEBSOCKET_DEFAULT_MAX_SUB_RETRY_COUNT

    self._requestType = Constants.WEBSOCKET_REQUEST_TYPE
    self._subscribeChannels = {}
end

function WebSocketConnectBase:run()
    local ok, err = xpcall(function()
        self:_authConnect()
        self:runEventLoop()
        ngx.exit(ngx.OK)
    end, function(err)
        err = tostring(err)
        if cc.DEBUG > cc.DEBUG_WARN then
            ngx_log(ngx.ERR, err .. debug.traceback("", 4))
        else
            ngx_log(ngx.ERR, err)
        end
        ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
        ngx.exit(ngx.ERROR)
    end)
end

function WebSocketConnectBase:runEventLoop()
   cc.printinfo("websocket [beforeConnectReady]")
    self:beforeConnectReady()

    local server = require("resty.websocket.server")
    local socket, err = server:new({
        timeout = self.config.app.websocketsTimeout,
        max_payload_len = self.config.app.websocketsMaxPayloadLen,
    })
    if err then
        cc.throw("failed to create websocket server, %s", err)
    end

    -- ready
    self._socket = socket

    -- spawn a thread to subscribe redis channel for broadcast
    self:subscribeChannel(self._connectChannel, function(payload)
        if payload == "QUIT" then
            -- ubsubscribe
            if self._socket then
                self._socket:send_close()
            end
            return false
        end
        -- forward message to connect
        self._socket:send_text(payload)
    end)

    -- event callback
    self:afterConnectReady()
   cc.printinfo("websocket [afterConnectReady], connect id: %s", tostring(self._connectId))

    -- event loop
    local retryCount = 0
    local framesPool = {}
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
        -- check session
        if not self._session:checkAlive() then
           cc.printwarn("session is lost")
            break
        end

        if err then
            if err == "again" then
                framesPool[#framesPool + 1] = frame
                goto recv_next_message
            end

            if string_sub(err, -7) == "timeout" then
                goto recv_next_message
            end

           cc.printwarn("failed to receive frame, type \"%s\", %s", ftype, err)
            break
        end

        if #framesPool > 0 then
            -- merging fragmented frames
            framesPool[#framesPool + 1] = frame
            frame = table.concat(framesPool)
            framesPool = {}
        end

        if ftype == "close" then
            break -- exit event loop
        elseif ftype == "ping" then
            local bytes, err = socket:send_pong()
            if err then
               cc.printwarn("failed to send pong, %s", err)
            end
        elseif ftype == "pong" then
            -- client ponged
        elseif ftype == "text" or ftype == "binary" then
            local ok, err = self:_processMessage(frame, ftype)
            if err then
               cc.printerror("process %s message failed, %s", ftype, err)
            end
        else
           cc.printwarn("unknwon frame type \"%s\"", tostring(ftype))
        end

::recv_next_message::

    end -- while

    -- end the subscribe thread
    self:_unsubscribeChannel()
   cc.printinfo("websocket [beforeConnectClose]")
    self:beforeConnectClose()

    -- close connect
    self._socket:send_close()
    self._socket = nil

    self:afterConnectClose()
   cc.printinfo("websocket [afterConnectClose]")
end

function WebSocketConnectBase:getConnectId()
    if not self._connectId then
        local redis = self:getRedis()
        self._connectId = tostring(redis:command("INCR", Constants.NEXT_CONNECT_ID_KEY))
    end
    return self._connectId
end

function WebSocketConnectBase:sendMessageToSelf(message)
    if self.config.app.messageFormat == Constants.MESSAGE_FORMAT_JSON and type(message) == "table" then
        message = json.encode(message)
    end
    self._socket:send_text(tostring(message))
end

function WebSocketConnectBase:subscribeChannel(channelName, callback)
    local sub = self._subscribeChannels[channelName]
    if not sub then
        sub = {
            name = channelName,
            enabled = false,
            running = false,
            retryCount = 0,
        }
        self._subscribeChannels[channelName] = sub
    end

    if sub.enabled then
       cc.printwarn("already subscribed channel \"%s\"", sub.name)
        return
    end

    local function _subscribe()
        sub.enabled = true
        sub.running = true

        -- pubsub thread need separated redis connect
        local redis = cc.load("redis").service:create(self.config.server.redis)
        redis:connect()
        redis:command("SELECT", self.config.app.appIndex)

        local channel = sub.name
        local loop, err = redis:pubsub({subscribe = channel})
        if not loop then
            cc.throw("subscribe channel \"%s\" failed, %s", channel, err)
        end

        for msg, abort in loop do
            if not sub.running then
                abort()
                break
            end

            if msg then
                if msg.kind == "subscribe" then
                   cc.printinfo("channel \"%s\" subscribed", channel)
                elseif msg.kind == "message" then
                    local payload = msg.payload
                   cc.printinfo("channel \"%s\" message \"%s\"", channel, payload)
                    if callback(payload) == false then
                        sub.running = false
                        abort()
                        break
                    end
                end
            end
        end

        -- when error occured or exit normally,
        -- connect will auto close, channel will be unsubscribed
        sub.enabled = false
        redis:setKeepAlive()
        if not sub.running then
            self._subscribeChannels[channel] = nil
        else
            -- if an error leads to an exiting, retry to subscribe channel
            if sub.retryCount < self.config.app.maxSubscribeRetryCount then
                sub.retryCount = sub.retryCount + 1
               cc.printwarn("subscribe channel \"%s\" loop ended, try [%d]", channel, sub.retryCount)
                self:subscribeChannel(channel, callback)
            else
               cc.printwarn("subscribe channel \"%s\" loop ended, max try", channel)
                self._subscribeChannels[channel] = nil
            end
        end
    end

    local thread = ngx_thread_spawn(_subscribe)
   cc.printinfo("spawn subscribe thread \"%s\"", tostring(thread))
end

function WebSocketConnectBase:unsubscribeChannel(channelName)
    local sub = self._subscribeChannels[channelName]
    if not sub then
       cc.printinfo("not subscribe channel \"%s\"", channelName)
    else
       cc.printinfo("unsubscribe channel \"%s\"", channelName)
        sub.running = false
    end
end

-- events

function WebSocketConnectBase:beforeConnectReady()
end

function WebSocketConnectBase:afterConnectReady()
end

function WebSocketConnectBase:beforeConnectClose()
end

function WebSocketConnectBase:afterConnectClose()
end

function WebSocketConnectBase:convertTokenToSessionId(token)
    return token
end

-- private methods

function WebSocketConnectBase:_processMessage(rawMessage, messageType)
    local message = self:_parseMessage(rawMessage, messageType)
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
    if rtype == "nil" then return end
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
    local message = cc.json.encode(result)
    local bytes, err = self._socket:send_text(message)
    if err then
        return nil, string.format("send message to client failed, %s", err)
    end

    return true
end

function WebSocketConnectBase:_parseMessage(rawMessage, messageType)
    -- TODO: support message type plugin
    if messageType ~= Constants.WEBSOCKET_TEXT_MESSAGE_TYPE then
        cc.throw("not supported message type \"%s\"", messageType)
    end

    -- TODO: support message format plugin
    if self.config.app.messageFormat == "json" then
        local message = cc.json.decode(rawMessage)
        if type(message) == "table" then
            return message
        else
            cc.throw("not supported message format \"%s\"", type(message))
        end
    else
        cc.throw("not support message format \"%s\"", tostring(self.config.app.messageFormat))
    end
end

function WebSocketConnectBase:_unsubscribeChannel()
    local redis = self:getRedis()
    redis:command("PUBLISH", self._connectChannel, "QUIT")
end

function WebSocketConnectBase:_authConnect()
    if ngx.headers_sent then
        cc.throw("response header already sent")
    end

    req_read_body()
    local headers = ngx.req.get_headers()
    local protocols = headers["sec-websocket-protocol"]
    if type(protocols) == "table" then
        protocols = protocols[1]
    end
    if not protocols then
        cc.throw("not set header: Sec-WebSocket-Protocol")
    end

    local token = string.match(protocols, Constants.WEBSOCKET_SUBPROTOCOL_PATTERN)
    if not token then
        cc.throw("not found token in header: Sec-WebSocket-Protocol")
    end

    -- convert token to session id
    local sid = self:convertTokenToSessionId(token)
    if not sid then
        cc.throw("convertTokenToSessionId() return invalid sid")
    end

    local session = self:openSession(sid)
    if not session then
        cc.throw("not set valid session id in header: Sec-WebSocket-Protocol")
    end

    -- save connect id in session
    local connectId = self:getConnectId()
    session:setConnectId(connectId)
    session:save()
    self._connectChannel = Constants.CONNECT_CHANNEL_PREFIX .. connectId
end

return WebSocketConnectBase
