
local ActionBase = cc.import("#gbc").server.ActionBase

local JobsAction = cc.class("JobsAction", ActionBase)

JobsAction.ACCEPTED_REQUEST_TYPE = "worker"

function JobsAction:triggingAction(job)
    local key = job.data.key
    local number = job.data.number

    local redis = self.connect:getRedis()
    redis:set(key, number * 2)
end

return JobsAction
