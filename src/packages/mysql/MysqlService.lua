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
local ngx = ngx
local string_format = string.format
local table_concat = table.concat

local MysqlService = class("MysqlService")

local MysqlAdapter
if ngx then
    MysqlAdapter = import(".adapter.MysqlRestyAdapter")
else
    MysqlAdapter = import(".adapter.MysqlLuaAdapter")
end

function MysqlService:ctor(config)
    if not config or type(config) ~= "table" then
        throw("invalid mysql config")
    end

    self._config = config
    self._mysql = MysqlAdapter:create(config)
end

function MysqlService:close()
    return self._mysql:close()
end

function MysqlService:setKeepAlive(timeout, size)
    if not ngx then
        return self:close()
    end
    return self._mysql:setKeepAlive(timeout, size)
end

function MysqlService:query(queryStr)
    return self._mysql:query(queryStr)
end

function MysqlService:insert(tableName, params)
    local fieldNames = {}
    local fieldValues = {}

    for name, value in pairs(params) do
        fieldNames[#fieldNames + 1] = self:_escapeName(name)
        fieldValues[#fieldValues + 1] = self:_escapeValue(value)
    end

    local sql = string_format("INSERT INTO %s (%s) VALUES (%s)",
                        self:_escapeName(tableName),
                        table_concat(fieldNames, ","),
                        table_concat(fieldValues, ","))
    return self._mysql:query(sql)
end

function MysqlService:update(tableName, params, where)
    local fields = {}
    local whereFields = {}

    for name, value in pairs(params) do
        fields[#fields + 1] = self:_escapeName(name) .. "=" .. self:_escapeValue(value)
    end

    for name, value in pairs(where) do
        whereFields[#whereFields + 1] = self:_escapeName(name) .. "=" .. self:_escapeValue(value)
    end

    local sql = string_format("UPDATE %s SET %s WHERE %s",
                        self:_escapeName(tableName),
                        table_concat(fields, ","),
                        table_concat(whereFields, " AND "))
    return self._mysql:query(sql)
end

function MysqlService:del(tableName, where)
    local whereFields = {}

    for name, value in pairs(where) do
        whereFields[#whereFields + 1] = self:_escapeName(name) .. "=" .. self:_escapeValue(value)
    end

    local sql = string_format("DElETE FROM %s WHERE %s",
                        self:_escapeName(tableName),
                        table_concat(whereFields, " AND "))
    return self._mysql:query(sql)
end

function MysqlService:_escapeValue(value)
    return self._mysql:escapeValue(value)
end

function MysqlService:_escapeName(name)
    return string_format([[`%s`]], name)
end

return MysqlService
