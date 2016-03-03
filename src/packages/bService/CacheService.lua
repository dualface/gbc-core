local CacheService = cc.class("CacheService")
local json = cc.import("#json")

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
    local red = json.encode(data)
    redis:initPipeline()
    redis:lpush(self:getLKey(key), red)
    redis:ltrim(self:getLKey(key), 0, self:getLength() - 1)
    redis:commitPipeline()
end

function CacheService:_decodeMsgs(list)
    local result = {}
    local len = #list
    for i = len, 1, -1 do
        table.insert(result, json.decode(list[i]))
    end
    return result
end

function CacheService:pop(key)
    local redis = self._Redis
    redis:initPipeline()
    redis:lrange(self:getLKey(key), 0, -1)
    redis:del(self:getLKey(key))
    local ret = redis:commitPipeline()
    return self:_decodeMsgs(ret[1] or {})
end

function CacheService:get(key)
    local redis = self._Redis
    local msgs = redis:lrange(self:getLKey(key), 0, -1)
    return self:_decodeMsgs(msgs)
end

function CacheService:getLen(key)
    return self._Redis:llen(self:getLKey(key))
end

return CacheService