local CacheService = cc.class("CacheService")

function CacheService:ctor(connect, name)
    self._Connect = connect
    self._Redis = connect:getRedis()
    self._Name = name
end

function CacheService:getLKey(key)
    return "CACHE:"..self._Name..":"..key
end

function CacheService:setLength(len)
    self._Length = len
end

function CacheService:getLength()
    return self._Length or 30
end

function CacheService:push(key, data)
    local redis = self._Redis
    redis:initPipeline()
    redis:lpush(self:getLKey(key), json.encode(data))
    redis:ltrim(self:getLKey(key), 0, self:getLength() - 1)
    redis:commitPipeline()
end

function CacheService:pop(key)
    local redis = self._Redis
    redis:initPipeline()
    redis:lrange(self:getLKey(key), 0, -1)
    redis:del(self:getLKey(key))
    local ret = redis:commitPipeline()
    return ret[1] or {}
end

function CacheService:getLen(key)
    return self._Redis:llen(self:getLKey(key))
end

return CacheService