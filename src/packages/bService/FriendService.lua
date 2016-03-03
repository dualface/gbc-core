local FriendService = cc.class("FriendService")

function FriendService:ctor(connect)
    self.connect = connect
    self._Redis = connect:getRedis()
end

--已经是好友
function FriendService:getSKey(name)
    return "FRD:A:"..name
end

function FriendService:setFriend(name1, name2)
    if name1 == name2 then return false end
    local redis = self._Redis
    redis:initPipeline()
    redis:sadd(self:getSKey(name1), name2)
    redis:sadd(self:getSKey(name2), name1)
    redis:commitPipeline()
end

function FriendService:removeFriend(name1, name2)
    local redis = self._Redis
    redis:initPipeline()
    redis:srem(self:getSKey(name1), name2)
    redis:srem(self:getSKey(name2), name1)
    redis:commitPipeline()
end

--获取好友的数量
function FriendService:count(name)
    return self._Redis:scard(self:getSKey(name))
end

function FriendService:getFriends(name)
    return self._Redis:smembers(self:getSKey(name))
end

function FriendService:beenFriend(nameself, nameother)
    return self._Redis:sismember(self:getSKey(nameself), nameother) == 1
end

--好友请求
function FriendService:getSKey2(name)
    return "FRD:Q:"..name
end

--0添加重复元数， 1，添加成功
function FriendService:sendQuestion(nameself, nameother)
    if nameself == nameother then return false end
    return self._Redis:sadd(self:getSKey2(nameother), nameself)
end

--0移除不存在元素，1移除单个元素
function FriendService:replyQuestion(nameself, nameother, isTrue)
    if not self:isQuestion(nameself, nameother) then
        return false
    end
    if isTrue then
        self:setFriend(nameself, nameother)
    end
    self._Redis:srem(self:getSKey2(nameself), nameother)
    return true
end

function FriendService:isQuestion(nameself, nameother)
    if nameself == nameother then return false end
    return self._Redis:sismember(self:getSKey2(nameself), nameother) == 1
end

function FriendService:getQuestions(name)
    return self._Redis:smembers(self:getSKey2(name))
end


return FriendService