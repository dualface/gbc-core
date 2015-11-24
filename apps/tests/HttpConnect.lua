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

local HttpConnectBase = cc.load("gbc").server.HttpConnectBase
local HttpConnect = cc.class("HttpConnect", HttpConnectBase)

local STRIP_LUA_PATH_PATTERN = "[./%a]+.lua:%d+: "

function HttpConnect:ctor(config)
    config.app.actionPackage = "cases"
    config.app.actionModuleSuffix = "TestCase"
    config.app.actionMethodSuffix = "Test"
    HttpConnect.super.ctor(self, config)
end

function HttpConnect:_formatError(actionName, err)
    return string.gsub(err, STRIP_LUA_PATH_PATTERN, "")
end

return HttpConnect
