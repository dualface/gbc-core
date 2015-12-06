local RankService = cc.class("RankService")

--最小排名为0
function RankService:ctor(connect, RankName)
    self.connect = connect
    self._Redis = connect:getRedis()
    self._RankName = RankName
end

function RankService:getZKey()
    return "RANK:"..self._RankName
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
    return self._Redis:zrank(self:getZKey(), name)
end

--从大到小
function RankService:getRRank(name)
    return self._Redis:zrevrank(self:getZKey(), name)
end

--统计分数之间的总数
function RankService:count(min, max)
    return self._Redis:zcount(self:getZKey(), min, max)
end

function RankService:getRangeByScore(min, max)
    return self._Redis:zrangebyscore(self:getZKey(), min, max)
end

--获取集合总数
function RankService:getCount()
    return self._Redis:zcard(self:getZKey())
end

return RankService


