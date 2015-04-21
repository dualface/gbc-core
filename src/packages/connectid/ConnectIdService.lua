--[[

Copyright (c) 2011-2015 dualface#github

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

local tostring = tostring

local ConnectIdService = class("ConnectIdService")

ConnectIdService.CONNECTS_ID_DICT_KEY  = "_CONNECTS_ID_DICT" -- id => tag
ConnectIdService.CONNECTS_TAG_DICT_KEY = "_CONNECTS_TAG_DICT" -- tag => id

function ConnectIdService:ctor(redis)
    self._redis = redis
end

function ConnectIdService:getIdByTag(tag)
    if not tag then
        throw("get connect id by invalid tag \"%s\"", tostring(tag))
    end
    return self._redis:command("HGET", ConnectIdService.CONNECTS_TAG_DICT_KEY, tostring(tag))
end

function ConnectIdService:getTagById(connectId)
    if not connectId then
        throw("get connect tag by invalid id \"%s\"", tostring(connectId))
    end
    return self._redis:command("HGET", ConnectIdService.CONNECTS_ID_DICT_KEY, tostring(connectId))
end

function ConnectIdService:getTag(connectId)
    return self._redis:command("HGET", ConnectIdService.CONNECTS_ID_DICT_KEY, connectId)
end

function ConnectIdService:setTag(connectId, tag)
    connectId = tostring(connectId)
    if not tag then
        throw("set connect \"%s\" tag with invalid tag", connectId)
    end
    local pipe = self._redis:newPipeline()
    pipe:command("HMSET", ConnectIdService.CONNECTS_ID_DICT_KEY, connectId, tag)
    pipe:command("HMSET", ConnectIdService.CONNECTS_TAG_DICT_KEY, tag, connectId)
    pipe:commit()
end

function ConnectIdService:removeTag(connectId)
    local tag = self:getTag(connectId)
    if tag then
        local pipe = self._redis:newPipeline()
        pipe:command("HDEL", ConnectIdService.CONNECTS_ID_DICT_KEY, connectId)
        pipe:command("HDEL", ConnectIdService.CONNECTS_TAG_DICT_KEY, tag)
        pipe:commit()
    end
end

return ConnectIdService
