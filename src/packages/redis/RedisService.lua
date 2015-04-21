--[[

Copyright (c) 2015 gameboxcloud.com

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

local type = type
local pairs = pairs
local clone = clone
local string_lower = string.lower
local string_upper = string.upper
local table_concat = table.concat

local RedisService = class("RedisService")

local RESULT_CONVERTER = {
    exists = {
        RedisLuaAdapter = function(self, result)
            if result == true then
                return 1
            else
                return 0
            end
        end,
    },

    hgetall = {
        RestyRedisAdapter = function(self, result)
            return self:arrayToHash(result)
        end,
    },
}

local RedisAdapter
if ngx then
    RedisAdapter = import(".adapter.RestyRedisAdapter")
else
    RedisAdapter = import(".adapter.RedisLuaAdapter")
end
local RedisTransaction = import(".RedisTransaction")
local RedisPipeline = import(".RedisPipeline")

function RedisService:ctor(config)
    if type(config) ~= "table" then
        throw("redis init with invalid config")
    end
    self._config = clone(config)
    self._redis = RedisAdapter:create(self._config)
end

function RedisService:connect()
    local ok, err = self._redis:connect()
    if err then
        throw("%s", err)
    end
end

function RedisService:close()
    local ok, err = self._redis:close()
    if err then
        throw("%s", err)
    end
    return true
end

function RedisService:setKeepAlive(timeout, size)
    if not ngx then
        self:close()
        return
    end
    self._redis:setKeepAlive(timeout, size)
end

function RedisService:command(command, ...)
    command = string_lower(command)
    local res, err = self._redis:command(command, ...)
    if err then
        throw("%s", err)
    end

    -- converting result
    local convert = RESULT_CONVERTER[command]
    if convert and convert[self._redis.name] then
        res = convert[self._redis.name](self, res)
    end

    return res
end

function RedisService:pubsub(subscriptions)
    local loop, err = self._redis:pubsub(subscriptions)
    if err then
        throw("%s", err)
    end
    return loop
end

function RedisService:newPipeline()
    return RedisPipeline:create(self)
end

function RedisService:newTransaction(...)
    return RedisTransaction:create(self, ...)
end

function RedisService:hashToArray(hash)
    local arr = {}
    for k, v in pairs(hash) do
        arr[#arr + 1] = k
        arr[#arr + 1] = v
    end
    return arr
end

function RedisService:arrayToHash(arr)
    local c = #arr
    local hash = {}
    for i = 1, c, 2 do
        hash[arr[i]] = arr[i + 1]
    end
    return hash
end

return RedisService
