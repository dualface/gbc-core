local JobService = cc.class("JobService")

function JobService:ctor(redis)
    self._Redis = redis
end

function JobService:getKey(key)
    return "JOBS:"..key
end

function JobService:isJob(id, key)
    local var = self._Redis:get(self:getKey(key))
    if var and var == tostring(id) then
        self:delete(key)
        return true
    else
        cc.printwarn("check unknown job:"..id)
        return false
    end
end

function JobService:save(id, key)
    self._Redis:set(self:getKey(key), id)
    cc.printwarn("save %s :%d", key, id)
end

function JobService:getJob(key)
    local var = self._Redis:get(self:getKey(key))
    if var then
        return tonumber(var) or 0
    end
    return 0
end

function JobService:delete(key)
    self._Redis:del(self:getKey(key))
end

return JobService