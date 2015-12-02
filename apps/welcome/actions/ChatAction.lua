
local gbc = cc.import("#gbc")
local ChatAction = cc.class("ChatAction", gbc.ActionBase)

ChatAction.ACCEPTED_REQUEST_TYPE = "websocket"

function ChatAction:sendmessageAction(arg)
    local username = arg.username
    if not username then
        cc.throw("not set argument: \"username\"")
    end

    local message = arg.message
    if not message then
        cc.throw("not set argument: \"message\"")
    end

    -- forward message to other client
    self.instance:sendMessageToUser(username, message)
end

return ChatAction
