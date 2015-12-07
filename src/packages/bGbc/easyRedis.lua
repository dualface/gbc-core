local easyRedis = {}

function easyRedis:hmset(redis, key, tdata)
    redis:initPipeline()
    for k, v in pairs(tdata) do
        redis:hset(key, k, v)
    end
    redis:commitPipeline()
end

function easyRedis:hmget(redis, key, tdata)
    redis:initPipeline()
    local result = {}
    local index = 1
    for k, _ in pairs(tdata) do
        redis:hget(key, key, k)
        result[k] = index
        index = index + 1
    end
    local ret = redis:commitPipeline()    
    for k, idx in pairs(result) do
        local v = ret[idx]
        if v and type(v) == "number" then
            result[k] = cc.checknumber(v)
        else
            result[k] = v
        end
    end

    return result
end

return easyRedis