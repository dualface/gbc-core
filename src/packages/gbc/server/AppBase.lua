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
local string_byte = string.byte
local string_find = string.find
local string_format = string.format
local string_gsub = string.gsub
local string_lower = string.lower
local string_sub = string.sub
local string_trim = string.trim
local string_ucfirst = string.ucfirst
local table_concat = table.concat
local table_remove = table.remove
local type = type

local sleep

if ngx then
    sleep = ngx.sleep
else
    local socket = require("socket")
    sleep = socket.sleep
end

local json = cc.load("json")
local Constants = cc.import(".Constants")

local AppBase = cc.class("AppBase")

function AppBase:ctor(config)
    self.config = table.copy(cc.checktable(config))

    self.config.app.actionPackage      = self.config.app.actionPackage or Constants.ACTION_PACKAGE_NAME
    self.config.app.actionModuleSuffix = config.app.actionModuleSuffix or Constants.DEFAULT_ACTION_MODULE_SUFFIX
    self.config.app.actionMethodSuffix = config.app.actionMethodSuffix or Constants.DEFAULT_ACTION_METHOD_SUFFIX
    self.config.app.autoloads          = config.app.autoloads or {}

    self._requestType = "unknown"
    self._actionModules = {}
    self._requestParameters = nil

    -- autoloads
    for packageName, packageConfig in pairs(self.config.app.autoloads) do
        local packageClass = cc.load(packageName)
        local package = packageClass.new(packageConfig, self)
        self[packageName .. "_"] = package
    end
end

function AppBase:getRequestType()
    return self._requestType or "unknown"
end

function AppBase:runAction(actionName, data)
    -- parse actionName
    local moduleName, methodName, folder = self:normalizeActionName(actionName)
    methodName = methodName .. self.config.app.actionMethodSuffix

    local action -- instance
    -- check registered action module before load module
    local actionModule = self._actionModules[folder .. moduleName]
    local actionModulePath
    if not actionModule then
        actionModulePath = self:getActionModulePath(moduleName, folder)
        if cc.DEBUG >= cc.DEBUG_INFO then
            package.loaded[actionModulePath] = false
        end
        local ok, _actionModule = pcall(require,  actionModulePath)
        if ok then
            actionModule = _actionModule
        else
            local err = _actionModule
            cc.throw(err)
        end
    end

    local t = type(actionModule)
    if t ~= "table" and t ~= "userdata" then
        cc.throw("failed to load action module \"%s\"", actionModulePath or moduleName)
    end

    local acceptedRequestType = actionModule.ACCEPTED_REQUEST_TYPE or self.config.app.defaultAcceptedRequestType
    local currentRequestType = self:getRequestType()
    if not self:checkActionTypes(currentRequestType, acceptedRequestType) then
        cc.throw("can't access this action via request type \"%s\"", currentRequestType)
    end

    action = actionModule:create(self)

    local method = action[methodName]
    if type(method) ~= "function" then
        cc.throw("invalid action method \"%s:%s()\"", moduleName, methodName)
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
        cc.throw("invalid ACCEPTED_REQUEST_TYPE of the action.")
    end

    return false
end

function AppBase:getActionModulePath(moduleName, folder)
    moduleName = moduleName .. self.config.app.actionModuleSuffix
    if folder ~= "" then
        return string_format("%s.%s", string.gsub(folder, "/", "."), moduleName)
    else
        return string_format("%s.%s", self.config.app.actionPackage, moduleName)
    end
end

function AppBase:registerActionModule(actionModuleName, actionModule)
    if type(actionModuleName) ~= "string" then
        cc.throw("invalid action module name \"%s\"", actionModuleName)
    end
    if type(actionModule) ~= "table" or type(actionModule) ~= "userdata" then
        cc.throw("invalid action module \"%s\"", actionModuleName)
    end

    local action = actionModuleName .. ".index"
    local actionModuleName, _, folder = self:normalizeActionName(actionName)
    self._actionModules[folder .. actionModuleName] = actionModule
end

function AppBase:normalizeActionName(actionName)
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
        return string_ucfirst(parts[1]), "index"
    end
    -- method = "say"
    local method = parts[c]
    table_remove(parts, c)
    c = c - 1
    -- mdoule = "demo.Hello"
    parts[c] = string_ucfirst(parts[c])
    return table_concat(parts, "."), method, folder
end

function AppBase:closeConnect(connectId)
    if not connectId then
        cc.throw("invalid connect id \"%s\"", tostring(connectId))
    end
    self:sendMessageToConnect(connectId, "QUIT")
end

function AppBase:sendMessageToConnect(connectId, message)
    if not connectId then
        cc.throw("send message to connect with invalid id \"%s\"", tostring(connectId))
    end
    local channelName = Constants.CONNECT_CHANNEL_PREFIX .. tostring(connectId)
    self:sendMessageToChannel(channelName, message)
end

function AppBase:sendMessageToChannel(channelName, message)
    if not channelName or not message then
        cc.throw("send message to channel with invalid channel name \"%s\" or invalid message", tostring(channelName))
    end
    if self.config.app.messageFormat == Constants.MESSAGE_FORMAT_JSON and type(message) == "table" then
        message = json.encode(message)
    end
    local redis = self:getRedis()
    redis:command("PUBLISH", channelName, tostring(message))
end

function AppBase:getRedis()
    local redis = self._redis
    if not redis then
        local config = self.config.server.redis
        local Redis = cc.load("redis")
        redis = Redis:create()

        local ok, err
        if config.socket then
            ok, err = redis:connect(config.socket)
        else
            ok, err = redis:connect(config.host, config.port)
        end
        if not ok then
            cc.throw("AppBase:getRedis() - %s", err)
        end

        redis:select(self.config.app.appIndex)
        self._redis = redis
    end
    return redis
end

function AppBase:getJobs(opts)
    opts = cc.checktable(opts)
    opts.try = cc.checkint(opts.try)
    if opts.try < 1 then opts.try = 1 end
    local jobs = self._jobs
    if not jobs then
        local Beanstalkd = cc.load("beanstalkd")

        local bean = Beanstalkd:create()
        local config = self.config.server.beanstalkd
        local try = opts.try
        while true do
            local ok, err = bean:connect(config.host, config.port)
            if ok then break end
            try = try - 1
            if try == 0 then
                cc.throw("AppBase:getJobs() - connect to beanstalkd, %s", err)
            else
                sleep(1.0)
            end
        end

        local tube = string_format(Constants.BEANSTALKD_JOB_TUBE_PATTERN, tostring(self.config.app.appIndex))
        bean:use(tube)
        bean:watch(tube)
        bean:ignore("default")

        local Jobs = cc.load("jobs")
        jobs = Jobs:create(bean, self:getRedis())
        self._jobs = jobs
    end
    return jobs
end

return AppBase
