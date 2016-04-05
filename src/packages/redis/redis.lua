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

local _tcp, _null, _unix_socket, _TIME_MULTIPLY
if ngx and ngx.socket then
    _tcp = ngx.socket.tcp
    _null = ngx.null
    _TIME_MULTIPLY = 1000
else
    local socket = require("socket")
    _tcp = socket.tcp
    _null = function() return nil end
    _unix_socket = require("socket.unix")
    _TIME_MULTIPLY = 1
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

local pairs         = pairs
local string_byte   = string.byte
local string_format = string.format
local string_lower  = string.lower
local string_sub    = string.sub
local string_upper  = string.upper
local table_concat  = table.concat
local table_new     = table.new
local tonumber      = tonumber
local tostring      = tostring
local type          = type

local Loop
if ngx then
    Loop = cc.import(".NginxRedisLoop")
end

local Redis = cc.class("Redis")

Redis.VERSION = "0.6"
Redis.null    = _null

local DEFAULT_HOST = "localhost"
local DEFAULT_PORT = 6379

local _genreq, _readreply, _checksub

function Redis:ctor()
    self._config = {}
end

function Redis:connect(host, port)
    local socket_file, socket, ok, err
    host = host or DEFAULT_HOST
    if string_sub(host, 1, 5) == "unix:" then
        socket_file = host
        if _unix_socket then
            socket_file = string_sub(host, 6)
            socket = _unix_socket()
        else
            socket = _tcp()
        end
        ok, err = socket:connect(socket_file)
    else
        socket = _tcp()
        ok, err = socket:connect(host, port or DEFAULT_PORT)
    end

    if not ok then
        return nil, err
    end

    self._config = {host = host, port = port}
    self._socket = socket
    return 1
end

function Redis:setTimeout(timeout)
    local socket = self._socket
    if not socket then
        return nil, "not initialized"
    end
    return socket:settimeout(timeout * _TIME_MULTIPLY)
end

function Redis:setKeepAlive(...)
    local socket = self._socket
    if not socket then
        return nil, "not initialized"
    end

    self._socket = nil
    if not ngx then
        return socket:close()
    else
        return socket:setkeepalive(...)
    end
end

function Redis:getReusedTimes()
    local socket = self._socket
    if not socket then
        return nil, "not initialized"
    end
    if socket.getreusedtimes then
        return socket:getreusedtimes()
    else
        return 0
    end
end

function Redis:close()
    local socket = self._socket
    if not socket then
        return nil, "not initialized"
    end
    self._socket = nil
    return socket:close()
end

function Redis:doCommand(...)
    local args = {...}
    local cmd = args[1] or "<unknown command>"

    -- cc.printinfo("[Redis:%s] %s", string.sub(tostring(self), 8), table.concat(args, " "))

    local socket = self._socket
    if not socket then
        return nil, string_format('"%s" failed, not initialized', cmd)
    end

    local req = _genreq(args)
    local reqs = self._reqs
    if reqs then
        reqs[#reqs + 1] = req
        return "OK"
    end

    local bytes, err = socket:send(req)
    if not bytes then
        return nil, string_format('"%s" failed, %s', cmd, err)
    end

    local res, err = _readreply(self, socket)
    if not res then
        return nil, string_format('"%s" failed, %s', cmd, err)
    end

    return res
end

function Redis:initPipeline(numberOfCommands)
    self._reqs = table_new(numberOfCommands or 4, 0)
end

function Redis:cancelPipeline()
    self._reqs = nil
end

function Redis:commitPipeline()
    local socket = self._socket
    if not socket then
        return nil, "not initialized"
    end

    local reqs = self._reqs
    if not reqs then
        return nil, "no pipeline"
    end
    self._reqs = nil

    local bytes, err = socket:send(table_concat(reqs))
    if not bytes then
        return nil, err
    end

    local nvals = 0
    local nreqs = #reqs
    local vals = table_new(nreqs, 0)
    for i = 1, nreqs do
        local res, err = _readreply(self, socket)
        if res then
            nvals = nvals + 1
            vals[nvals] = res
        elseif res == nil then
            if err == "timeout" then
                self:close()
            end
            return nil, err
        else
            -- be a valid redis error value
            nvals = nvals + 1
            vals[nvals] = {false, err}
        end
    end

    return vals
end

function Redis:readReply()
    local res, err = _readreply(self, self._socket)
    if not res then
        return nil, err
    end

    _checksub(self, res)
    return res
end

function Redis:makeSubscribeLoop(id)
    if not Loop then
        return nil, "not support subscribe loop in current platform"
    end

    local subredis = Redis:new()
    local ok, err = subredis:connect(self._config.host, self._config.port)
    if not ok then
        return nil, err
    end
    return Loop:new(self, subredis, id)
end

function Redis:hashToArray(hash)
    local arr = {}
    local i = 0
    for k, v in pairs(hash) do
        arr[i + 1] = k
        arr[i + 2] = v
        i = i + 2
    end
    return arr
end

function Redis:arrayToHash(arr)
    local c = #arr
    local hash = table_new(0, c / 2)
    for i = 1, c, 2 do
        hash[arr[i]] = arr[i + 1]
    end
    return hash
end

-- private

_genreq = function(args)
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

_readreply = function(self, socket)
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
            return _null
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
        local n = tonumber(string_sub(line, 2))
        -- print("multi-bulk reply: ", n)
        if n < 0 then
            return _null
        end

        local vals = table_new(n, 0)
        local nvals = 0
        for i = 1, n do
            local res, err = _readreply(self, socket)
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

_checksub = function(self, res)
    if type(res) == "table"
            and (res[1] == "unsubscribe" or res[1] == "punsubscribe")
            and res[3] == 0 then
        self._subscribed = nil
    end
end

-- add commands

for _, cmd in ipairs(_COMMANDS) do
    Redis[cmd] = function(self, ...)
        return self:doCommand(cmd, ...)
    end
end

for _, cmd in ipairs(_SUB_COMMANDS) do
    Redis[cmd] = function(self, ...)
        self._subscribed = true
        return self:doCommand(cmd, ...)
    end
end

for _, cmd in ipairs(_UNSUB_COMMANDS) do
    Redis[cmd] = function(self, ...)
        local res = self:doCommand(cmd, ...)
        _checksub(self, res)
        return res
    end
end

return Redis
