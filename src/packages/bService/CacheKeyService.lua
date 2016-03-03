local CacheKeyService = cc.class("CacheKeyService")
local easyRedis = cc.import(".easyRedis")

function CacheKeyService:ctor(connect, namePre, name)
    self._Connect = connect
    self._Redis = connect:getRedis()
    self._NamePre = namePre
    self._Name = name
end

function CacheKeyService:_getKey()
    return self._NamePre ..":"..self._Name
end

function CacheKeyService:save(keymap)
    local redis = self._Redis
    local pKey = self:_getKey()
    return easyRedis:hmset(redis, pKey, keymap)
end

function CacheKeyService:incr(keymap)
    local redis = self._Redis
    local pKey = self:_getKey()
    return easyRedis:hincrby(redis, pKey, keymap)
end

function CacheKeyService:get(keymap)
    local redis = self._Redis
    local pKey = self:_getKey()
    return easyRedis:hmget(redis, pKey, keymap)
end

return CacheKeyService