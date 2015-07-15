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

local pcall = pcall
local type = type
local string_lower = string.lower
local string_ucfirst = string.ucfirst
local string_gsub = string.gsub
local string_format = string.format
local string_find = string.find
local string_sub = string.sub
local table_concat = table.concat
local table_remove = table.remove
local json_encode = json.encode

local Constants = import(".Constants")

local AppBase = class("AppBase")

function AppBase:ctor(config)
    self.config = clone(checktable(config))

    self.config.app.actionPackage      = self.config.app.actionPackage or Constants.ACTION_PACKAGE_NAME
    self.config.app.actionModuleSuffix = config.app.actionModuleSuffix or Constants.DEFAULT_ACTION_MODULE_SUFFIX
    self.config.app.actionMethodSuffix = config.app.actionMethodSuffix or Constants.DEFAULT_ACTION_METHOD_SUFFIX
    self.config.app.autoloads          = config.app.autoloads or {}

    self._actionModules = {}
    self._requestParameters = nil
    self._services = {}

    -- autoloads
    for packageName, packageConfig in pairs(self.config.app.autoloads) do
        local packageClass = cc.load(packageName)
        local package = packageClass.new(packageConfig, self)
        self[packageName .. "_"] = package
    end
end

function AppBase:runAction(actionName, data)
    -- parse actionName
    local actionModuleName, actionMethodName = self:normalizeActionName(actionName)
    actionMethodName = actionMethodName .. self.config.app.actionMethodSuffix

    local action -- instance
    -- check registered action module before load module
    local actionModule = self._actionModules[actionModuleName]
    local actionModulePath
    if not actionModule then
        actionModulePath = self:getActionModulePath(actionModuleName)
        if DEBUG >= _DBG_INFO then
            package.loaded[actionModulePath] = false
        end
        local ok, _actionModule = pcall(require,  actionModulePath)
        if ok then
            actionModule = _actionModule
        else
            local err = _actionModule
            throw(err)
        end
    end

    local t = type(actionModule)
    if t ~= "table" and t ~= "userdata" then
        throw("failed to load action module \"%s\"", actionModulePath or actionModuleName)
    end

    local acceptedRequestType = rawget(actionModule, "ACCEPTED_REQUEST_TYPE") or self.config.app.defaultAcceptedRequestType
    local currentRequestType = self:getRequestType()
    if not self:checkActionTypes(currentRequestType, acceptedRequestType) then
        throw("can't access this action via \"%s\"", currentRequestType)
    end

    action = actionModule:create(self)

    local method = action[actionMethodName]
    if type(method) ~= "function" then
        throw("invalid action method \"%s:%s()\"", actionModuleName, actionMethodName)
    end

    if not data then
        data = self._requestParameters or {}
    end

    return method(action, data)
end

function AppBase:checkActionTypes(currentRequestType, acceptedRequestType)
    if type(acceptedRequestType) == "table" then
        for _, v in ipairs(acceptedRequestType) do
            if string_lower(v) == currentRequestType then
                return true
            end
        end
    elseif type(acceptedRequestType) == "string" then
        return currentRequestType == string_lower(acceptedRequestType)
    else
        throw("invalid ACCEPTED_REQUEST_TYPE of the action.")
    end

    return false
end

function AppBase:getActionModulePath(actionModuleName)
    return string_format("%s.%s%s", self.config.app.actionPackage, actionModuleName, self.config.app.actionModuleSuffix)
end

function AppBase:registerActionModule(actionModuleName, actionModule)
    if type(actionModuleName) ~= "string" then
        throw("invalid action module name \"%s\"", actionModuleName)
    end
    if type(actionModule) ~= "table" or type(actionModule) ~= "userdata" then
        throw("invalid action module \"%s\"", actionModuleName)
    end

    local action = actionModuleName .. ".index"
    local actionModuleName, _ = self:normalizeActionName(actionName)
    self._actionModules[actionModuleName] = actionModule
end

function AppBase:normalizeActionName(actionName)
    local actionName = actionName
    if not actionName or actionName == "" then
        actionName = "index.index"
    end
    actionName = string_lower(actionName)
    actionName = string_gsub(actionName, "[^%a.]", "")
    actionName = string_gsub(actionName, "^[.]+", "")
    actionName = string_gsub(actionName, "[.]+$", "")

    -- demo.hello.say --> {"demo", "hello", "say"]
    local parts = string.split(actionName, ".")
    local c = #parts
    if c == 1 then
        return string_ucfirst(parts[1]), "index"
    end
    -- method = "say"
    method = parts[c]
    table_remove(parts, c)
    c = c - 1
    -- mdoule = "demo.Hello"
    parts[c] = string_ucfirst(parts[c])
    return table_concat(parts, "."), method
end

function AppBase:closeConnect(connectId)
    if not connectId then
        throw("invalid connect id \"%s\"", tostring(connectId))
    end
    self:sendMessageToConnect(connectId, "QUIT")
end

function AppBase:sendMessageToConnect(connectId, message)
    if not connectId then
        throw("send message to connect with invalid id \"%s\"", tostring(connectId))
    end
    local channelName = Constants.CONNECT_CHANNEL_PREFIX .. tostring(connectId)
    self:sendMessageToChannel(channelName, message)
end

function AppBase:sendMessageToChannel(channelName, message)
    if not channelName or not message then
        throw("send message to channel with invalid channel name \"%s\" or invalid message", tostring(channelName))
    end
    if self.config.app.messageFormat == Constants.MESSAGE_FORMAT_JSON and type(message) == "table" then
        message = json_encode(message)
    end
    local redis = self:getRedis()
    redis:command("PUBLISH", channelName, tostring(message))
end

function AppBase:getService(name, ...)
    local service = self._services[name]
    if not service then
        local serviceClass = cc.load(name).service
        service = serviceClass:create(...)
        self._services[name] = service
    end
    return service
end

function AppBase:getRedis()
    local redis = self._redis
    if not redis then
        redis = self:getService("redis", self.config.server.redis)
        redis:connect()
        redis:command("SELECT", self.config.app.appIndex)
        self._redis = redis
    end
    return redis
end

function AppBase:getJobs()
    if not self._beans then
        self._beans = self:getService("beanstalkd", self.config.server.beanstalkd)
        self._beans:connect()
    end
    if not self._jobs then
        self._jobs = self:getService("job", self._beans)
        self._jobs:use(string_format("job-%d", self.config.app.appIndex))
    end
    return self._jobs
end

return AppBase
