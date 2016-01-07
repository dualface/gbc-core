local MissionService = cc.class("MissionService")

function MissionService:ctor(connect, key)
    self._Connect = connect
    self._Redis = connect:getRedis()
    self._Key = key
    self:loadFromDB()
end

function MissionService:loadFromDB() end
function MissionService:saveToDB() end

function MissionService:getKey()
    return "Mission:"..self._Key
end

function MissionService:addMission(Missionid, times)
    self._Redis:zadd(self:getKey(), times or 0, Missionid)
end

function MissionService:removeMission(Missionid)
    self._Redis:zrem(self:getKey(), Missionid)
end

function MissionService:finishMission(Missionid)
    self._Redis:zadd(self:getKey(), -1, Missionid)
end

function MissionService:processMission(Missionid, times)
    return self._Redis:zincrby(self:getKey(), times, Missionid)
end

function MissionService:clearMissions()
    self._Redis:del(self:getKey())
end

function MissionService:getTimes(id)
    return tonumber(self._Redis:zscore(self:getKey(), id)) or 0
end

function MissionService:getAll(noFinish)
    local list
    if noFinish then
        list = self._Redis:zrangebyscore(self:getKey(), 0, "+inf", "WITHSCORES")
    else
        list = self._Redis:zrange(self:getKey(), 0, -1, "WITHSCORES")
    end

    local len = #list
    local ret = {}
    for i = 1, len, 2 do
        table.insert(ret, {id = tonumber(list[i]) or 0, times = tonumber(list[i+1]) or 0})
    end
    return ret
end

function MissionService:getAllHashMap(noFinish)
    local list
    if noFinish then
        list = self._Redis:zrangebyscore(self:getKey(), 0, "+inf", "WITHSCORES")
    else
        list = self._Redis:zrange(self:getKey(), 0, -1, "WITHSCORES")
    end
    local len = #list
    local ret = {}
    for i = 1, len, 2 do
        local id = tonumber(list[i])
        if id then
            ret[id] = tonumber(list[i+1]) or 0
        end
    end
    return ret
end

return MissionService