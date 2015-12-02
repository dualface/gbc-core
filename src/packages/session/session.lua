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

local _gensid, _cleanup

function Session:ctor(redis, config)
    config = config or {}
    self._expired = config.expired or _DEFAULT_EXPIRED
    self._prefix  = config.prefix or _DEFAULT_SID_KEY_PREFIX
    self._secret  = config.secret or _DEFAULT_SECRET
    self._redis   = redis
    self._values  = {}
    self._saved   = false
end

function Session:start(sid)
    if type(sid) == "nil" then
        sid = _gensid(self._secret)
    elseif type(sid) ~= "string" or sid == "" then
        cc.throw("Session:start() - invalid sid '%s'", tostring(sid))
    end

    local redis = self._redis
    local key = self._prefix .. sid
    local res, err = self._redis:get(key)
    if not res then
        cc.throw("Session:start() - redis failed, %s", err)
    end

    if res ~= redis.null then
        self._values = json.decode(res)
        self._saved = true
    end
    self._values = checktable(self._values)
    self._sid = sid
    self._key = key
    self:setKeepAlive()
end

function Session:getSid()
    return self._sid
end

function Session:getExpired()
    return self._expired
end

function Session:get(key)
    if type(key) ~= "string" or key == "" then
        cc.throw("Session:get() - invalid key '%s'", tostring(key))
    end
    return self._values[key]
end

function Session:set(key, value)
    if type(key) ~= "string" or key == "" then
        cc.throw("Session:set() - invalid key '%s'", tostring(key))
    end
    self._values[key] = value
end

function Session:save()
    if not self._key then
        cc.throw("Session:save() - not set sid")
    end

    local j = json.encode(self._values)
    if type(j) ~= "string" then
        cc.throw("Session:save() - serializing failed")
    end

    local ok, err = self._redis:set(self._key, j, "EX", self._expired)
    if not ok then
        cc.throw("Session:save() - redis failed, %s", err)
    end

    self._saved = true
end

function Session:setKeepAlive(expired)
    local ok, err = self._redis:expire(self._key, expired or self._expired)
    if not ok then
        cc.throw("Session:setKeepAlive() - redis failed, %s", err)
    end
end

function Session:isAlive()
    local res, err = self._redis:exists(self._key)
    if not res then
        cc.throw("Session:isAlive() - redis failed, %s", err)
    end
    if tostring(res) == "1" then
        return true
    elseif self._saved then
        _cleanup(self)
    end
    return false
end

function Session:destroy()
    if not self._key then
        cc.throw("Session:destroy() - not set sid")
    end

    local ok, err = self._redis:del(self._key)
    if not ok then
        cc.throw("Session:destroy() - redis failed, %s", err)
    end

    _cleanup(self)
end

-- private

_gensid = function(secret)
    math.newrandomseed()

    local random = math.random() * 100000000000000
    local now
    if ngx then
        local addr = ngx.var.remote_addr
        now = ngx.now()
    else
        local addr = "127.0.0.1"
        now = os.time()
    end

    local mask = string.format("%0.5f|%0.10f|%s", now, random, secret)
    local origin = string.format("%s|%s", addr, mask)
    return md5(origin)
end

_cleanup = function(self)
    self._redis  = nil
    self._values = {}
    self._sid    = nil
    self._key    = nil
    self._saved  = false
end

return Session
