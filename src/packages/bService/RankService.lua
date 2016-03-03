local RankService = cc.class("RankService")
local easyRedis = cc.import(".easyRedis")
--最小排名为0
function RankService:ctor(connect, RankName)
    self.connect = connect
    self._Redis = connect:getRedis()
    self._RankName = RankName
end

function RankService:getZKey()
    return "RANK:"..self._RankName
end

function RankService:getDataKey()
    return "RANK:Data:"..self._RankName
end

function RankService:saveData(params)
    local redis = self._Redis
    local pKey = self:getDataKey()
    return easyRedis:hmset(redis, pKey, params)
end

function RankService:incrData(keymap)
    local redis = self._Redis
    local pKey = self:getDataKey()
    return easyRedis:hincrby(redis, pKey, keymap)
end

function RankService:getData(params)
    local redis = self._Redis
    local pKey = self:getDataKey()
    return easyRedis:hmget(redis, pKey, params)
end

function RankService:clear()
    self._Redis:del(self:getZKey())
end

--添加排名数据
function RankService:addRank(name, score)
    return self._Redis:zadd(self:getZKey(), score, name)
end

function RankService:removeRank(name)
    return self._Redis:zrem(self:getZKey(), name)
end

--从小到大
function RankService:getRange(begin, ed, WITHSCORES)
    if WITHSCORES then
        return self._Redis:zrange(self:getZKey(), begin, ed, "WITHSCORES")
    else
        return self._Redis:zrange(self:getZKey(), begin, ed)
    end
end

function RankService:getNameByRank(rank)
    local ret = self:getRange(rank, rank)
    return ret[1]
end

--从大到小
function RankService:getRRange(begin, ed, WITHSCORES)
    if WITHSCORES then
        return self._Redis:zrevrange(self:getZKey(), begin, ed, "WITHSCORES")
    else
        return self._Redis:zrevrange(self:getZKey(), begin, ed)
    end
end

--从小到大, 获取自己的排名
function RankService:getRank(name)
    return tonumber(self._Redis:zrank(self:getZKey(), name)) or -1
end

--从大到小
function RankService:getRRank(name)
    return tonumber(self._Redis:zrevrank(self:getZKey(), name)) or -1
end

--统计分数之间的总数
function RankService:count(min, max)
    return tonumber(self._Redis:zcount(self:getZKey(), min, max)) or 0
end

function RankService:getScore(name)
    local score = self._Redis:zscore(self:getZKey(), name)
    score = tonumber(score) or -1
    return score
end

--分数在min, max之间，递增排列
function RankService:getRangeByScore(min, max)
    return self._Redis:zrangebyscore(self:getZKey(), min, max)
end

--分数在min, max之间，递减排列
function RankService:getRRangeByScore(min, max)
    return self._Redis:zrevrangebyscore(self:getZKey(), min, max)
end

--获取排行榜总数
function RankService:getCount()
    return self._Redis:zcard(self:getZKey())
end

return RankService


