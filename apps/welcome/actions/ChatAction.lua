
local ChatAction = cc.class("ChatAction")

ChatAction.ACCEPTED_REQUEST_TYPE = "websocket"

function ChatAction:ctor(connect)
    self.connect = connect
    self.connects = connect.connects
end

function ChatAction:sendmessageAction(arg)
    local tag = arg.tag
    if not tag then
        cc.throw("not set argument: \"tag\"")
    end
    -- get connect id by tag
    local connectId = self.connects:getIdByTag(tag)
    if not connectId then
        cc.throw("not found connect id by tag \"%s\"", tag)
    end

    local message = arg.message
    if not message then
        cc.throw("not set argument: \"message\"")
    end

    local session = self.connect:getSession()
    local data = {
        src = session:get("tag"),
        username = session:get("username"),
        message = message,
    }
    self.connect:sendMessageToConnect(connectId, data)
end

return ChatAction
