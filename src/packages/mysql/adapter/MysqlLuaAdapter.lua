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
local type = type
local pairs = pairs
local strFormat = string.format

local mysql = require "3rd.luasql.mysql"

local MysqlLuaAdapter = class("MysqlLuaAdapter")

function MysqlLuaAdapter:ctor(config)
    self.db_   = nil
    self.env_ = nil

    local env, err = mysql.mysql()
    if err then
        printWarn("MysqlLuaAdapter:ctor() - failed to instantiate mysql: %s", err)
        return db, err
    end

    self.env_ = env

    local con, err = self.env_:connect(config.database, config.user, config.password, config.host, config.port)
    self.db_ = con

    self.db_:execute"SET NAMES 'utf8'"
end

function MysqlLuaAdapter:close()
    assert(self.db_ ~= nil, "Not connect to mysql")

    self.db_:close()
    self.env_:close()
end

function MysqlLuaAdapter:query(queryStr)
    assert(self.db_ ~= nil, "Not connect to mysql")

    local cur, err = self.db_:execute(queryStr)
    if err then
        printWarn("MysqlLuaAdapter:query() - failed to query mysql: %s", err)
        return cur, err
    end

    if type(cur) == "userdata" then
        local row, err = cur:fetch ({}, "a")
        if err then
            printWarn("MysqlLuaAdapter:query() - failed to query mysql: %s", err)
            return row, err
        end

        local results = {row}

        while true do
            row = cur:fetch (row, "a")

            if row == nil then
                break
            end

            local result = {}
            for key, value in pairs(row) do
                result[key] = value
            end

            results[#results + 1] = result
        end

        return results, err
    end

    return cur, err
end


function MysqlLuaAdapter:escapeValue(value)
    assert(self.db_ ~= nil, "Not connect to mysql")

    return strFormat("'%s'", self.db_:escape(value))
end

return MysqlLuaAdapter
