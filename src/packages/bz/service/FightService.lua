local FightService = cc.class("FightService")
local Constants = import("..Constants")

function FightService:ctor(connect, pid)
    self.connect = connect
    self._Redis = connect:getRedis()
    self._PID = pid
end

function FightService:getSetKey()
    return "FHT:"..self._PID
end

function FightService:generateFightID()
    return tostring(self._Redis:incr(Constants.NEXT_FIGHT_ID_KEY))
end

function FightService:setRoom()

end

return FightService