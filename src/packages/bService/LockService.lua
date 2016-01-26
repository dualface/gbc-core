local LockService = cc.class("LockService")

function LockService:ctor(connect)
    self.connect = connect
    self._Redis = connect:getRedis()
end

function LockService:getLockKey(user, platform)
    return "Lock:"..user..":"..platform
end

function LockService:Lock(user, platform)
    local ret = tonumber(self._Redis:incr(self:getLockKey(user, platform)))
    if ret == 1 then
        self._User = user
        self._Platform = platform
    end
    return ret == 1
end

function LockService:unLock()
    if self._User and self._Platform then
        self._Redis:del(self:getLockKey(self._User, self._Platform))
    end
end

return LockService