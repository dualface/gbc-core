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

local _CUR = ...

local string_find   = string.find
local string_format = string.format
local string_sub    = string.sub

local Factory = cc.class("Factory")

function Factory.create(config, classname, ...)
    if config.app.packagePath then
        package.path = config.app.packagePath
    end

    local ok, cls = pcall(require, classname)
    if not ok then
        local err = cls
        local pos = string_find(err, "not found:", 1, true)
        if not pos then
            cc.throw(err)
        end

        if not string_find(err, string_format("module '%s' not found:", classname), 1, true) then
            cc.throw(err)
        end

        cls = nil
    end

    if not cls then
        cls = cc.import("." .. classname .. "Base", _CUR)
    end

    return cls.new(config, ...)
end

function Factory.makeAppConfigs(appKeys, serverConfig, defaultPackagePath)
    local appConfigs = {}

    for appRootPath, opts in pairs(appKeys) do
        local config = table.copy(serverConfig)
        local appConfig = config.app
        appConfig.rootPath = appRootPath
        appConfig.appKey   = opts.key
        appConfig.appIndex = opts.index
        appConfig.appName  = opts.name

        local appPackagePath = appRootPath .. "/?.lua;"
        local pattern = string.gsub(appPackagePath, "([.?-])", "%%%1")
        defaultPackagePath = string.gsub(defaultPackagePath, pattern, "")
        appConfig.packagePath = appPackagePath .. defaultPackagePath

        local appConfigPath = appRootPath .. "/conf/app_config.lua"
        if io.exists(appConfigPath) then
            local appCustomConfig = dofile(appConfigPath)
            table.merge(appConfig, appCustomConfig)
        end

        appConfigs[appRootPath] = config
    end

    return appConfigs
end

return Factory
