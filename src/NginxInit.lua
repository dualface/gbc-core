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

local Factory = require("server.base.Factory")
local req_get_headers = ngx.req.get_headers
local string_lower = string.lower

local appConfigs = Factory.makeAppConfigs(SERVER_APP_KEYS, SERVER_CONFIG, package.path)

local function processRequest(appRootPath)
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

    local connect = Factory.create(appConfig, classNamePrefix)
    connect:run()
end

cc.exports.processRequest = processRequest
