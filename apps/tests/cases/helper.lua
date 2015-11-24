
local Redis = cc.load("redis")
local Beanstalkd = cc.load("beanstalkd")

local _M = {}

_M.newredis = function(config)
    local redis = Redis:create()
    local ok, err
    if config.socket then
        ok, err = redis:connect(config.socket)
    else
        ok, err = redis:connect(config.host, config.port)
    end
    if not ok then
        return nil, err
    end
    return redis
end

_M.newbeanstalkd = function(config)
    local bean = Beanstalkd:create()
    local ok, err = bean:connect(config.host, config.port)
    if not ok then
        return nil, err
    end
    return bean
end

_M.sleep = function(n)
    os.execute("sleep " .. tonumber(n))
end

return _M
