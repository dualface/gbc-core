--[[

Copyright (c) 2011-2015 dualface#github

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
local string_lower = string.lower
local string_ucfirst = string.ucfirst
local string_gsub = string.gsub
local string_format = string.format
local string_find = string.find
local string_sub = string.sub
local table_concat = table.concat
local table_remove = table.remove

local Constants = import(".Constants")

local ActionDispatcher = class("ActionDispatcher")

function ActionDispatcher:ctor(config)
    self.config = clone(checktable(config))

    self.config.appRootPath = self.config.appRootPath
    self.config.actionPackage = self.config.actionPackage or Constants.ACTION_PACKAGE_NAME
    self.config.actionModuleSuffix = config.actionModuleSuffix or Constants.DEFAULT_ACTION_MODULE_SUFFIX

    self._actionModules = {}
    self._actionInstances = {}
    self._requestParameters = nil
end

function ActionDispatcher:runAction(actionName, data, isPersistentActionInstance)
    -- parse actionName
    local actionModuleName, actionMethodName = self:normalizeActionName(actionName)
    actionMethodName = actionMethodName .. self.config.actionModuleSuffix

    local action -- instance
    if isPersistentActionInstance and self._actionInstances[actionModuleName] then
        action = self._actionInstances[actionModuleName]
    else
        -- check registered action module before load module
        local actionModule = self._actionModules[actionModuleName]
        local actionModulePath
        if not actionModule then
            actionModulePath = string_format("%s.%s%s", self.config.actionPackage, actionModuleName, self.config.actionModuleSuffix)
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

        action = actionModule:create(self)
        if isPersistentActionInstance then
            self._actionInstances[actionModuleName] = action
        end
    end

    local method = action[actionMethodName]
    if type(method) ~= "function" then
        throw("invalid action method \"%s:%s()\"", actionModuleName, actionMethodName)
    end

    if not data then
        data = self._requestParameters or {}
    end

    return method(action, data)
end

function ActionDispatcher:registerActionModule(actionModuleName, actionModule)
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

function ActionDispatcher:normalizeActionName(actionName)
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

return ActionDispatcher
