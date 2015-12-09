
local Online = cc.import("#online")

local gbc = cc.import("#gbc")
local JobsAction = cc.class("JobsAction", gbc.ActionBase)

JobsAction.ACCEPTED_REQUEST_TYPE = "worker"

function JobsAction:echoAction(job)
    local username = job.data.username
    local message = job.data.message

    local online = Online:new(self:getInstance())
    online:sendMessage(username, {
        name   = "MESSAGE",
        sender = username,
        body   = string.format("'%s' do a job, message is '%s', delay is %d", username, message, job.delay),
    })
end

return JobsAction
