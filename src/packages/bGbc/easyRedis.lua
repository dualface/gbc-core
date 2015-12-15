local easyRedis = {}

function easyRedis:hmset(redis, key, tdata)
    if not tdata then return end
    redis:initPipeline()
    for k, v in pairs(tdata) do
        redis:hset(key, k, v)
    end
    redis:commitPipeline()
end

function easyRedis:hmget(redis, key, tdata)
    if not tdata then return {} end
    redis:initPipeline()
    local result = {}
    local index = 1
    for k, _ in pairs(tdata) do
        redis:hget(key, k)
        result[k] = index
        index = index + 1
    end
    local ret = redis:commitPipeline()    
    for k, idx in pairs(result) do
        local v = ret[idx]
        if v and type(tdata[k]) == "number" then
            result[k] = cc.checknumber(v)
        else
            if v ~= ngx.null then
                result[k] = v
            else
                result[k] = nil
            end
        end
    end

    return result
end

function easyRedis:hincrby(redis, key, tdata)
    if not tdata then return {} end
    redis:initPipeline()
    local result = {}
    local index = 1
    for k, v in pairs(tdata) do
        redis:hincrby(key, k, v)
        result[k] = index
        index = index + 1
    end
    local ret = redis:commitPipeline()    
    for k, idx in pairs(result) do
        result[k] = cc.checknumber(ret[idx])
    end

    return result
end

return easyRedis