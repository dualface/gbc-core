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

local checkint      = cc.checkint
local checktable    = cc.checktable
local clone         = clone
local string_format = string.format
local tostring      = tostring
local type          = type
local md5
if ngx then
    md5 = ngx.md5
else
    local luamd5 = cc.import("#luamd5")
    md5 = luamd5.sumhexa
end

local json = cc.import("#json")

local Session = cc.class("Session")

local _DEFAULT_EXPIRED        = 60 * 5 -- 5m
local _DEFAULT_SID_KEY_PREFIX = "_SID_"
local _DEFAULT_SECRET         = "1b876ea6"

local _gensid

function Session:ctor(redis, config)
    config = config or {}
    self._expired = config.expired or _DEFAULT_EXPIRED
    self._prefix  = config.prefix or _DEFAULT_SID_KEY_PREFIX
    self._secret  = config.secret or _DEFAULT_SECRET
    self._redis   = redis
end

function Session:start(sid)
    local create = sid == nil
    if type(sid) == "nil" then
        sid = _gensid(self._secret)
    elseif type(sid) ~= "string" or sid == "" then
        cc.throw("[Session] invalid sid '%s'", tostring(sid))
    end

    local key = self._prefix .. sid

    if create then
        self._values = {}
        self._sid = sid
        self._key = key
    else
        local redis = self._redis
        local res, err = self._redis:get(key)
        if not res then
            return false, err
        end
        if res == redis.null then
            return false, string_format("not found session '%s'", sid)
        end

        self._values = checktable(json.decode(res))
        self._sid = sid
        self._key = key
        self:setKeepAlive()
    end

    return true
end

function Session:getSid()
    return self._sid
end

function Session:getExpired()
    return self._expired
end

function Session:get(key)
    if not self._values then
        cc.throw("[Session] get key '%s' failed, not initialized", key)
    end

    if type(key) ~= "string" or key == "" then
        cc.throw("[Session] invalid get key '%s'", tostring(key))
    end

    return self._values[key]
end

function Session:set(key, value)
    if not self._values then
        cc.throw("[Session] set key '%s' failed, not initialized", key)
    end

    if type(key) ~= "string" or key == "" then
        cc.throw("[Session] invalid set key '%s'", tostring(key))
    end

    self._values[key] = value
end

function Session:save()
    if not self._values then
        cc.throw("[Session] save failed, not initialized")
    end

    local jsonstr = json.encode(self._values)
    if type(jsonstr) ~= "string" then
        return false, "serializing failed"
    end

    local ok, err = self._redis:set(self._key, jsonstr, "EX", self._expired)
    if not ok then
        return false, err
    end

    return true
end

function Session:setKeepAlive(expired)
    if not self._values then
        cc.throw("[Session] set keep alive failed, not initialized")
    end

    if expired then
        self._expired = expired
    end
    local ok, err = self._redis:expire(self._key, self._expired)
    if not ok then
        return false, err
    end

    return true
end

function Session:isAlive()
    if not self._values then
        cc.throw("[Session] check alive failed, not initialized")
    end

    local res, err = self._redis:exists(self._key)
    if not res then
        return false, err
    end

    if tostring(res) == "1" then
        return true
    end

    return false, string_format("not found session '%s'", self._sid)
end

function Session:destroy()
    if not self._values then
        cc.throw("[Session] destroy failed, not initialized")
    end

    local ok, err = self._redis:del(self._key)
    self._values = nil
    self._redis = nil
    self._sid = nil
    self._key = nil

    if not ok then
        return false, err
    end
    return true
end

-- private

_gensid = function(secret)
    math.newrandomseed()

    local random = math.random() * 100000000000000
    local now
    local addr
    if ngx then
        addr = ngx.var.remote_addr
        now = ngx.now()
    else
        addr = "127.0.0.1"
        now = os.time()
    end

    local mask = string.format("%0.5f|%0.10f|%s", now, random, secret)
    local origin = string.format("%s|%s", addr, mask)
    return md5(origin)
end

return Session
