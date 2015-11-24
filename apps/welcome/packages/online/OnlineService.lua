
local ngx_null = ngx.null
local table_map = table.map
local json = cc.load("json")

local OnlineService = cc.class("OnlineService")

OnlineService.USER_ADD_EVENT = "USER_ADD_EVENT"
OnlineService.USER_REMOVE_EVENT = "USER_REMOVE_EVENT"

local _ONLINE_KEY_PREFIX = "_OL_"
local _ONLINE_SET = "_ONLINES_USERS"
local _ONLINE_CHANNEL = "_ONLINES"

local _ADD_MESSAGE = "add"
local _REMOVE_MESSAGE = "remove"

local function _key(username)
    return _ONLINE_KEY_PREFIX .. tostring(username)
end

function OnlineService:ctor(connect)
    cc.bind(self, "event")
    self.connect = connect
    self.redis = connect:getRedis()
    self.eventsEnabled = false
end

function OnlineService:setEventsEnabled(enabled)
    if self.eventsEnabled == enabled then return end

    self.eventsEnabled = enabled
    if enabled then
        self.connect:subscribeChannel(_ONLINE_CHANNEL, function(message)
            local message = json.decode(message)
            if message.name == _ADD_MESSAGE then
                self:dispatchEvent({name = OnlineService.USER_ADD_EVENT, username = message.username})
            elseif message.name == _REMOVE_MESSAGE then
                self:dispatchEvent({name = OnlineService.USER_REMOVE_EVENT, username = message.username})
            end
        end)
    else
        self.connect:unsubscribeChannel(_ONLINE_CHANNEL)
    end
end

function OnlineService:isExists(username)
    return tostring(self.redis:command("EXISTS", _key(username))) == "1"
end

function OnlineService:get(username)
    local res = self.redis:command("GET", _key(username))
    if not res then return {} end
    return json.decode(res)
end

function OnlineService:getAll()
    local usernames = self.redis:command("SMEMBERS", _ONLINE_SET)
    if #usernames == 0 then return {} end

    local keys = table_map(usernames, function(v, k)
        return _ONLINE_KEY_PREFIX .. v
    end)
    local all = self.redis:command("MGET", unpack(keys))
    local res = {}
    for i, username in ipairs(usernames) do
        if all[i] ~= ngx_null then
            local userdata = json.decode(all[i])
            res[#res + 1] = {username = username, tag = userdata.tag}
        end
    end
    return res
end

function OnlineService:getAllUsername()
    return self.redis:command("SMEMBERS", _ONLINE_SET)
end

function OnlineService:add(username, data)
    local pipe = self.redis:newPipeline()
    pipe:command("SET", _key(username), json.encode(data))
    pipe:command("SADD", _ONLINE_SET, username)
    pipe:command("PUBLISH", _ONLINE_CHANNEL, json.encode({name = _ADD_MESSAGE, username = username}))
    pipe:commit()
end

function OnlineService:remove(username)
    local pipe = self.redis:newPipeline()
    pipe:command("DEL", _key(username))
    pipe:command("SREM", _ONLINE_SET, username)
    pipe:command("PUBLISH", _ONLINE_CHANNEL, json.encode({name = _REMOVE_MESSAGE, username = username}))
    pipe:commit()
end

return OnlineService
