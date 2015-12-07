local ConnectIDService = cc.class("ConnectIDService")

local CONNECTS_ID_DICT = "_CON_ID_DICT"
local CONNECTS_TAG_DICT = "_CON_TAG_DICT"

function ConnectIDService:ctor(redis)
    self._Redis = redis
end

function ConnectIDService:getConnectId(tag)
    return self._Redis:hget(CONNECTS_TAG_DICT, tag)
end

function ConnectIDService:getTag(connectid)
    return self._Redis:hget(CONNECTS_ID_DICT, connectid)
end

function ConnectIDService:save(connectid, tag)
    if not tag or not connectid then 
        cc.printerror("ConnectIDService param error")
    end
    local redis = self._Redis
    redis:initPipeline()
    redis:hset(CONNECTS_ID_DICT, connectid, tag)
    redis:hset(CONNECTS_TAG_DICT, tag, connectid)
    redis:commitPipeline()
end

function ConnectIDService:remove(connectid, tag)
    local redis = self._Redis
    if not tag then
        tag = self:getTag(connectid)
    end
    redis:initPipeline()
    redis:hdel(CONNECTS_ID_DICT, connectid)
    redis:hdel(CONNECTS_TAG_DICT, tag)
    redis:commitPipeline()
end

return ConnectIDService