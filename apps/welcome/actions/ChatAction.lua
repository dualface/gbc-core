
local gbc = cc.import("#gbc")
local ChatAction = cc.class("ChatAction", gbc.ActionBase)

ChatAction.ACCEPTED_REQUEST_TYPE = "websocket"

function ChatAction:sendmessageAction(arg)
    local recipient = arg.recipient
    if not recipient then
        cc.throw("not set argument: \"recipient\"")
    end

    local message = arg.message
    if not message then
        cc.throw("not set argument: \"message\"")
    end

    -- forward message to other client
    local instance = self:getInstance()
    instance:getOnline():sendMessage(recipient, {
        name      = "MESSAGE",
        sender    = instance:getUsername(),
        recipient = recipient,
        body      = message,
    })
end

function ChatAction:sendmessagetoallAction(arg)
    local message = arg.message
    if not message then
        cc.throw("not set argument: \"message\"")
    end

    -- forward message to all clients
    local instance = self:getInstance()
    instance:getOnline():sendMessageToAll({
        name      = "MESSAGE",
        sender    = instance:getUsername(),
        recipient = recipient,
        body      = message,
    })
end

return ChatAction
