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
local tostring = tostring
local throw = throw
local ngx_quote_sql_str = ngx.quote_sql_str

local mysql = require("resty.mysql")

local MysqlRestyAdapter = cc.class("MysqlRestyAdapter")

function MysqlRestyAdapter:ctor(config)
    self._config = config

    local db, err = mysql:new()
    if err then
        cc.throw("failed to instantiation mysql: %s", err)
    end

    self._db = db
    self._db:set_timeout(config.timeout)
    local ok, err, errno, sqlstate = db:connect(config)
    if err then
        cc.throw("mysql connect error [%s] %s, %s", tostring(errno), err, sqlstate)
    end
    self._db:query("SET NAMES 'utf8'")
end

function MysqlRestyAdapter:close()
    self._db:close()
end

function MysqlRestyAdapter:setKeepAlive(timeout, size)
    if size then
        return self._db:set_keepalive(timeout, size)
    elseif timeout then
        return self._db:set_keepAlive(timeout)
    else
        return self._db:set_keepalive()
    end
end

function MysqlRestyAdapter:query(queryStr)
    local res, err, errno, sqlstate = self._db:query(queryStr)
    if err then
        cc.throw("mysql query error: [%s] %s, %s", tostring(errno), err, sqlstate)
    end
    return res
end

function MysqlRestyAdapter:escapeValue(value)
    return ngx_quote_sql_str(value)
end

return MysqlRestyAdapter
