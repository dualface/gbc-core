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

local tcp, unix_socket
local _USE_COSOCKET = false
local _TIME_MULTIPLY = 1
if ngx and ngx.socket then
    _USE_COSOCKET = true
    tcp = ngx.socket.tcp
    _TIME_MULTIPLY = 1000
else
    local socket = require("socket")
    tcp = socket.tcp
    unix_socket = require("socket.unix")
end

local _COMMANDS = {
    "cluster",

    "auth",                 "echo",                 "ping",
    "quit",                 "select",

    "geoadd",               "geohash",              "geopos",
    "geodist",              "georadius",            "georadiusbymember",

    "hdel",                 "hexists",              "hget",
    "hgetall",              "hincrby",              "hincrbyfloat",
    "hkeys",                "hlen",                 "hmget",
    "hmset",                "hset",                 "hsetnx",
    "hstrlen",              "hvals",                "hscan",

    "pfadd",                "pfcount",              "pfmerge",

    "del",                  "dump",                 "exists",
    "expire",               "expireat",             "keys",
    "migrate",              "move",                 "object",
    "persist",              "pexpire",              "pexpireat",
    "pttl",                 "randomkey",            "rename",
    "renamenx",             "restore",              "sort",
    "ttl",                  "type",                 "wait",
    "scan",

    "blpop",                "brpop",                "brpoplpush",
    "lindex",               "linsert",              "llen",
    "lpop",                 "lpush",                "lpushx",
    "lrange",               "lrem",                 "lset",
    "ltrim",                "rpop",                 "rpoplpush",
    "rpush",                "rpushx",

    --[["psubscribe",]]     "pubsub",               "publish",
    --[["punsubscribe",]]   --[["subscribe",]]      --[["unsubscribe",]]

    "eval",                 "evalsha",              "script",

    "bgrewriteaof",         "bgsave",               "client",
    "command",              "config",               "dbsize",
    "debug",                "flushall",             "flushdb",
    "info",                 "lastsave",             "monitor",
    "role",                 "save",                 "shutdown",
    "slaveof",              "slowlog",              "sync",
    "time",

    "sadd",                 "scard",                "sdiff",
    "sdiffstore",           "sinter",               "sinterstore",
    "sismember",            "smembers",             "smove",
    "spop",                 "srandmember",          "srem",
    "sunion",               "sunionstore",          "sscan",

    "zadd",                 "zcard",                "zcount",
    "zincrby",              "zinterstore",          "zlexcount",
    "zrange",               "zrangebylex",          "zrevrangebylex",
    "zrangebyscore",        "zrank",                "zrem",
    "zremrangebylex",       "zremrangebyrank",      "zremrangebyscore",
    "zrevrange",            "zrevrangebyscore",     "zrevrank",
    "zscore",               "zunionstore",          "zscan",

    "append",               "bitcount",             "bitop",
    "bitpos",               "decr",                 "decrby",
    "get",                  "getbit",               "getrange",
    "getset",               "incr",                 "incrby",
    "incrbyfloat",          "mget",                 "mset",
    "msetnx",               "psetex",               "set",
    "setbit",               "setex",                "setnx",
    "setrange",             "strlen",

    "discard",              "exec",                 "multi",
    "unwatch",              "watch",
}

local _SUB_COMMANDS = {
    "subscribe", "psubscribe",
}

local _UNSUB_COMMANDS = {
    "unsubscribe", "punsubscribe",
}

local null = null or function() return "null" end
local type = type
local pairs = pairs
local tostring = tostring
local tonumber = tonumber
local string_lower = string.lower
local string_upper = string.upper
local string_byte = string.byte
local string_sub = string.sub
local table_concat = table.concat
local table_new = table.new

local RedisService = class("RedisService")

RedisService.VERSION = "0.5"
RedisService.null = null

local _checkSubscribed

function RedisService:ctor(config)
    if type(config) ~= "table" then
        throw("RedisService:ctor() - invalid config")
    end
    self._config = {}
    self._config.host = config.host or "localhost"
    self._config.port = config.port or 6379
    self._config.timeout = config.timeout or 10
    self._config.socket = config.socket
end

function RedisService:connect()
    local socket_file = self._config.socket
    if socket_file and unix_socket then
        if string_sub(socket_file, 1, 5) == "unix:" then
            socket_file = string_sub(socket_file, 6)
        else
            socket_file = "unix:" .. socket_file
        end
        self._socket = unix_socket()
    else
        self._socket = tcp()
    end

    local ok, err
    if socket_file then
        ok, err = self._socket:connect(socket_file)
    else
        ok, err = self._socket:connect(self._config.host, self._config.port)
    end

    if not ok then
        self._socket = nil
    else
        self:setTimeout(self._config.timeout)
    end
end

function RedisService:setTimeout(timeout)
    if self._socket then
        self._socket:settimeout(timeout * _TIME_MULTIPLY)
    end
end

function RedisService:setKeepAlive(...)
    if not ngx then
        self:close()
    else
        self._socket:setKeepAlive(...)
    end
end

function RedisService:getReusedTimes()
    if self._socket and self._socket.getreusedtimes then
        return self._socket:getreusedtimes()
    else
        return 0
    end
end

function RedisService:close()
    if self._socket then
        self._socket:close()
        self._socket = nil
    end
end

function RedisService:doCommand(...)
    local args = {...}
    local cmd = args[1] or "<unknown command>"
    local socket = self._socket
    if not socket then
        throw("RedisService:%s() - not initialized", cmd)
    end

    local req = self:generateRequest(args)
    local reqs = self._reqs
    if reqs then
        reqs[#reqs + 1] = req
        return
    end

    local bytes, err = socket:send(req)
    if not bytes then
        throw("RedisService:%s() - %s", cmd, err)
    end

    local res, err = self:readReplyRaw(self, socket)
    if err then
        throw("RedisService:%s() - %s", cmd, err)
    end

    return res
end

function RedisService:generateRequest(args)
    local nargs = #args
    local req = table_new(nargs + 1, 0)
    req[1] = "*" .. nargs .. "\r\n"
    local nbits = 1

    for i = 1, nargs do
        local arg = args[i]
        nbits = nbits + 1

        if not arg then
            req[nbits] = "$-1\r\n"
        else
            if type(arg) ~= "string" then
                arg = tostring(arg)
            end
            req[nbits] = "$" .. #arg .. "\r\n" .. arg .. "\r\n"
        end
    end

    -- it is faster to do string concatenation on the Lua land
    return table_concat(req)
end

function RedisService:initPipeline(numberOfCommands)
    self._reqs = table_new(numberOfCommands or 4, 0)
end

function RedisService:cancelPipeline()
    self._reqs = nil
end

function RedisService:commitPipeline()
    local reqs = self._reqs
    if not reqs then
        throw("RedisService:commitPipeline() - no pipeline")
    end
    self._reqs = nil

    if not self._socket then
        throw("RedisService:commitPipeline() - not initialized")
    end

    local bytes, err = self._socket:send(table_concat(reqs))
    if not bytes then
        throw("RedisService:commitPipeline() - %s", err)
    end

    local nvals = 0
    local nreqs = #reqs
    local vals = table_new(nreqs, 0)
    for i = 1, nreqs do
        local res, err = self:readReplyRaw()
        if res then
            nvals = nvals + 1
            vals[nvals] = res
        elseif res == nil then
            if err == "timeout" then
                self:close()
            end
            throw("RedisService:commitPipeline() - %s", err)
        else
            -- be a valid redis error value
            nvals = nvals + 1
            vals[nvals] = {false, err}
        end
    end

    return vals
end

function RedisService:readReply()
    if not self._socket then
        throw("RedisService:readReply() - not initialized")
    end

    if not self._subscribed then
        throw("RedisService:readReply() - not subscribed")
    end

    local res, err = self:readReplyRaw()
    if err then
        throw("RedisService:readReply() - %s", err)
    end

    _checkSubscribed(self, res)
    return res
end

function RedisService:readReplyRaw()
    local socket = self._socket
    local line, err = socket:receive()
    if not line then
        if err == "timeout" and not self._subscribed then
            socket:close()
        end
        return nil, err
    end

    local prefix = string_byte(line)

    if prefix == 36 then    -- char '$'
        -- print("bulk reply")
        local size = tonumber(string_sub(line, 2))
        if size < 0 then
            return null
        end

        local data, err = socket:receive(size)
        if not data then
            if err == "timeout" then
                socket:close()
            end
            return nil, err
        end

        local dummy, err = socket:receive(2) -- ignore CRLF
        if not dummy then
            return nil, err
        end

        return data

    elseif prefix == 43 then    -- char '+'
        -- print("status reply")
        return string_sub(line, 2)

    elseif prefix == 42 then -- char '*'
        -- print("multi-bulk reply: ", n)
        local n = tonumber(string_sub(line, 2))
        if n < 0 then
            return null
        end

        local vals = table_new(n, 0)
        local nvals = 0
        for i = 1, n do
            local res, err = self:readReplyRaw()
            if res then
                nvals = nvals + 1
                vals[nvals] = res
            elseif res == nil then
                return nil, err
            else
                -- be a valid redis error value
                nvals = nvals + 1
                vals[nvals] = {false, err}
            end
        end

        return vals

    elseif prefix == 58 then    -- char ':'
        -- print("integer reply")
        return tonumber(string_sub(line, 2))

    elseif prefix == 45 then    -- char '-'
        -- print("error reply: ", n)
        return false, string_sub(line, 2)

    else
        return nil, "unknown prefix: \"" .. prefix .. "\""
    end
end

function RedisService:hashToArray(hash)
    local arr = {}
    local i = 0
    for k, v in pairs(hash) do
        arr[i + 1] = k
        arr[i + 2] = v
        i = i + 2
    end
    return arr
end

function RedisService:arrayToHash(arr)
    local c = #arr
    local hash = table_new(0, c / 2)
    for i = 1, c, 2 do
        hash[arr[i]] = arr[i + 1]
    end
    return hash
end

-- private methods

_checkSubscribed = function (self, res)
    if type(res) == "table"
            and (res[1] == "unsubscribe" or res[1] == "punsubscribe")
            and res[3] == 0 then
        self._subscribed = nil
    end
end

-- add commands

for _, cmd in ipairs(_COMMANDS) do
    RedisService[cmd] = function (self, ...)
        return self:doCommand(cmd, ...)
    end
end

for _, cmd in ipairs(_SUB_COMMANDS) do
    RedisService[cmd] = function (self, ...)
        self._subscribed = true
        return self:doCommand(cmd, ...)
    end
end

for _, cmd in ipairs(_UNSUB_COMMANDS) do
    RedisService[cmd] = function (self, ...)
        local res = self:doCommand(cmd, ...)
        _checkSubscribed(self, res)
        return res
    end
end

return RedisService
