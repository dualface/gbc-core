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

local appKeys = SERVER_APP_KEYS
local defaultAppConfig = SERVER_CONFIG.app
local defaultPackagePath = package.path

-- load apps config, cached in SERVER_APP_CONFIGS
local appConfigs = {}

for appRootPath, opts in pairs(appKeys) do
    local appConfig = clone(defaultAppConfig)
    appConfig.rootPath = appRootPath
    appConfig.appKey   = opts.key
    appConfig.appIndex = opts.index
    appConfig.appName  = opts.name
    appConfig.packagePath = appRootPath .. "/?.lua;" .. defaultPackagePath

    local appConfigPath = appRootPath .. "/app_config.lua"
    if io.exists(appConfigPath) then
        local appCustomConfig = loadfile(appRootPath .. "/app_config.lua")()
        table.merge(appConfig, appCustomConfig)
    end

    local config = clone(SERVER_CONFIG)
    config.apps = nil
    config.app = appConfig

    appConfigs[appRootPath] = config
end

SERVER_APP_CONFIGS = appConfigs

--

local Factory = require("server.base.Factory")
local req_get_headers = ngx.req.get_headers
local string_lower = string.lower

function processRequest(appRootPath)
    local headers = req_get_headers()
    local val = headers.upgrade
    if type(val) == "table" then
        val = val[1]
    end

    local classNamePrefix = "HttpConnect"
    local appConfig = appConfigs[appRootPath]
    if val and string_lower(val) == "websocket" then
        classNamePrefix = "WebSocketConnect"
        if not appConfig.app.websocketEnabled then
            ngx.exit(ngx.HTTP_FORBIDDEN)
        end
    else
        if not appConfig.app.httpEnabled then
            ngx.exit(ngx.HTTP_FORBIDDEN)
        end
    end

    local connect = Factory.create(appRootPath, classNamePrefix)
    connect:run()
end
