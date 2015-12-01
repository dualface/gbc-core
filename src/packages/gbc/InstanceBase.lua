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

local pcall          = pcall
local string_byte    = string.byte
local string_find    = string.find
local string_format  = string.format
local string_gsub    = string.gsub
local string_lower   = string.lower
local string_sub     = string.sub
local string_trim    = string.trim
local string_ucfirst = string.ucfirst
local table_concat   = table.concat
local table_remove   = table.remove
local type           = type

local sleep

if ngx then
    sleep = ngx.sleep
else
    local socket = require("socket")
    sleep = socket.sleep
end

local Redis      = cc.import("#redis")
local Beanstalkd = cc.import("#beanstalkd")
local Jobs       = cc.import("#jobs")
local Event      = cc.import("#event")
local Constants  = cc.import(".Constants")

local InstanceBase = cc.class("InstanceBase")

local _normalize, _getpath, _loadmodule, _checkreqtype

function InstanceBase:ctor(config)
    self.config = table.copy(cc.checktable(config))
    local appConfig = self.config.app

    appConfig.actionPackage      = appConfig.actionPackage or Constants.ACTION_PACKAGE_NAME
    appConfig.actionModuleSuffix = config.app.actionModuleSuffix or Constants.DEFAULT_ACTION_MODULE_SUFFIX
    appConfig.actionMethodSuffix = config.app.actionMethodSuffix or Constants.DEFAULT_ACTION_METHOD_SUFFIX
    appConfig.messageFormat      = appConfig.messageFormat or Constants.DEFAULT_MESSAGE_FORMAT

    self._requestType       = "unknown"
    self._requestParameters = nil
    self._actions           = {}

    -- enable events
    cc.bind(self, Event)
end

function InstanceBase:getRequestType()
    return self._requestType or "unknown"
end

function InstanceBase:runAction(actionName, args)
    local appConfig = self.config.app

    local moduleName, methodName, folder = _normalize(actionName)
    methodName = methodName .. appConfig.actionMethodSuffix

    local actionModulePath = _getpath(moduleName, folder, appConfig)
    local action = self._actions[actionModulePath]
    if not action then
        local actionModule = _loadmodule(actionModulePath)
        local acceptedRequestType = actionModule.ACCEPTED_REQUEST_TYPE or appConfig.defaultAcceptedRequestType
        local currentRequestType = self:getRequestType()
        if not _checkreqtype(currentRequestType, acceptedRequestType) then
            cc.throw("can't access this action via request type \"%s\"", currentRequestType)
        end

        action = actionModule.new(self)
        self._actions[actionModulePath] = action
    end

    local method = action[methodName]
    if type(method) ~= "function" then
        cc.throw("invalid action method \"%s:%s()\"", moduleName, methodName)
    end

    if not args then
        args = self._requestParameters or {}
    end

    return method(action, args)
end

function InstanceBase:getRedis()
    local redis = self._redis
    if not redis then
        local config = self.config.server.redis
        redis = Redis.new()

        local ok, err
        if config.socket then
            ok, err = redis:connect(config.socket)
        else
            ok, err = redis:connect(config.host, config.port)
        end
        if not ok then
            cc.throw("InstanceBase:getRedis() - %s", err)
        end

        redis:select(self.config.app.appIndex)
        self._redis = redis
    end
    return redis
end

function InstanceBase:getJobs(opts)
    local jobs = self._jobs
    if not jobs then
        local bean   = Beanstalkd.new()
        local config = self.config.server.beanstalkd
        local try    = 3
        while true do
            local ok, err = bean:connect(config.host, config.port)
            if ok then break end
            try = try - 1
            if try == 0 then
                cc.throw("InstanceBase:getJobs() - connect to beanstalkd, %s", err)
            else
                sleep(1.0)
            end
        end

        local tube = string_format(Constants.BEANSTALKD_JOB_TUBE_PATTERN, tostring(self.config.app.appIndex))
        bean:use(tube)
        bean:watch(tube)
        bean:ignore("default")

        jobs = Jobs.new(bean, self:getRedis())
        self._jobs = jobs
    end
    return jobs
end

-- private

_normalize = function(actionName)
    if not actionName or actionName == "" then
        actionName = "index.index"
    end

    local folder = ""
    if string_byte(actionName) == 47 --[[ / ]] then
        local pos = 1
        local offset = 2
        while true do
            pos = string_find(actionName, "/", offset)
            if not pos then
                pos = offset - 1
                break
            else
                offset = offset + 1
            end
        end

        folder = string_trim(string_sub(actionName, 1, pos), "/")
        actionName = string_sub(actionName, pos + 1)
    end

    actionName = string_lower(actionName)
    actionName = string_gsub(actionName, "[^%a./]", "")
    actionName = string_gsub(actionName, "^[.]+", "")
    actionName = string_gsub(actionName, "[.]+$", "")

    -- demo.hello.say --> {"demo", "hello", "say"]
    local parts = string.split(actionName, ".")
    local c = #parts
    if c == 1 then
        return string_ucfirst(parts[1]), "index", folder
    end
    -- method = "say"
    local method = parts[c]
    table_remove(parts, c)
    c = c - 1
    -- mdoule = "demo.Hello"
    parts[c] = string_ucfirst(parts[c])
    return table_concat(parts, "."), method, folder
end

_getpath = function(moduleName, folder, appConfig)
    moduleName = moduleName .. appConfig.actionModuleSuffix
    if folder ~= "" then
        return string_format("%s.%s", string.gsub(folder, "/", "."), moduleName)
    else
        return string_format("%s.%s", appConfig.actionPackage, moduleName)
    end
end

_loadmodule = function(actionModulePath)
    if cc.DEBUG >= cc.DEBUG_INFO then
        package.loaded[actionModulePath] = nil
    end
    local ok, actionModule = pcall(require, actionModulePath)
    if not ok then
        cc.throw("%s", actionModule) -- actionModule is error message
    end
    return actionModule
end

_checkreqtype = function(currentRequestType, acceptedRequestType)
    if type(acceptedRequestType) == "table" then
        for _, v in ipairs(acceptedRequestType) do
            if string_lower(v) == currentRequestType then
                return true
            end
        end
    elseif type(acceptedRequestType) == "string" then
        return currentRequestType == string_lower(acceptedRequestType)
    else
        cc.throw("invalid ACCEPTED_REQUEST_TYPE of the action.")
    end

    return false
end

return InstanceBase
