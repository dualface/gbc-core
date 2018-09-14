
local gbc = cc.import("#gbc")
local JobsAction = cc.class("JobsAction", gbc.ActionBase)

JobsAction.ACCEPTED_REQUEST_TYPE = "worker"

function JobsAction:triggingAction(job)
    local key = job.data.key
    local number = job.data.number

    local redis = self:getInstance():getRedis()
    redis:set(key, number * 2)
end

return JobsAction
