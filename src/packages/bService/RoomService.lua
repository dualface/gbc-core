local RoomService = cc.class("RoomService")

local json = cc.import("#json")
local json_encode = json.encode
local msgpack   = cc.import("#MessagePack")

function RoomService:keyRoomSet()
    return "_ROOM:US:" .. self._RoomName
end

function RoomService:keyRoomMsg()
    return "_ROOM:MSG:" .. self._RoomName
end

function RoomService:keyChannel()
    return "_ROOM:CH:" .. self._RoomName
end

function RoomService:ctor(connect, roomName)
    self.connect = connect
    self._Redis = connect:getRedis()
    self._RoomName = roomName
    self._EventsEnabled = false
    self:setEventsEnabled(true)
end

function RoomService:setEventsEnabled(enabled)
    if self._EventsEnabled == enabled then return end

    self._EventsEnabled = enabled
    if enabled then
        self.connect:subscribe(self:keyChannel())
    else
        self.connect:unsubscribe(self:keyChannel())
    end
end

function RoomService:sendMessage(msg)
    if type(msg) == "table" then
        self._Redis:publish(self:keyChannel(), msgpack.pack(msg))
    else
        self._Redis:publish(self:keyChannel(), msg)
    end
end

function RoomService:setMsgLength(len)
    self._MsgLength = len
end

function RoomService:getMsgLength()
    return self._MsgLength or 30
end

function RoomService:saveMessage(data)
    self._Redis:lpush(self:keyRoomMsg(), json_encode(data))
    self._Redis:ltrim(self:keyRoomMsg(), 0, self:getMsgLength() - 1)
end

function RoomService:getAllMsg()
    return self._Redis:lrange(self:keyRoomMsg(), 0, -1)
end

function RoomService:getAll()
    return self._Redis:smembers(self:keyRoomSet())
end

function RoomService:add(username)
    self._Redis:sadd(self:keyRoomSet(), username)
end

function RoomService:remove(username)
    self._Redis:srem(self:keyRoomSet(), username)
end

return RoomService