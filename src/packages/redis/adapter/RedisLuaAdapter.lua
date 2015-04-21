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

local assert = assert
local pcall = pcall
local type = type
local tostring = tostring
local table_concat = table.concat
local table_walk = table.walk
local string_format = string.format
local string_upper = string.upper
local string_lower = string.lower

local redis = require("3rd.redis.redis_lua")

local RedisLuaAdapter = class("RedisLuaAdapter")

function RedisLuaAdapter:ctor(config)
    self._config = config
    self.name = "RedisLuaAdapter"
end

function RedisLuaAdapter:connect()
    local ok, result = pcall(function()
        if self._config.socket then
            self._instance = redis.connect(self._config.socket)
        else
            self._instance = redis.connect({
                host = self._config.host,
                port = self._config.port,
                timeout = self._config.timeout
            })
        end
    end)
    if ok then
        return true
    else
        return nil, result
    end
end

function RedisLuaAdapter:close()
    return self._instance:quit()
end

function RedisLuaAdapter:command(command, ...)
    command = string_lower(command)
    local method = self._instance[command]
    assert(type(method) == "function", string_format("RedisLuaAdapter:command() - invalid command %s", tostring(command)))

    if DEBUG > 1 then
        local a = {}
        table_walk({...}, function(v) a[#a + 1] = tostring(v) end)
        printInfo("RedisLuaAdapter:command() - command %s: %s", string_upper(command), table_concat(a, ", "))
    end

    local arg = {...}
    local ok, result = pcall(function()
        return method(self._instance, unpack(arg))
    end)
    if ok then
        return result
    else
        return nil, result
    end
end

function RedisLuaAdapter:pubsub(subscriptions)
    return pcall(function()
        return self._instance:pubsub(subscriptions)
    end)
end

function RedisLuaAdapter:commitPipeline(commands)
    return pcall(function()
        self._instance:pipeline(function()
            printInfo("RedisLuaAdapter:commitPipeline() - init pipeline")
            for _, arg in ipairs(commands) do
                self:command(arg[1], unpack(arg[2]))
            end
            printInfo("RedisLuaAdapter:commitPipeline() - commit pipeline")
        end)
    end)
end

return RedisLuaAdapter
