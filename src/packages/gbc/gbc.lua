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

local _CURRENT_MODULE = ...

local _M = {}

_M.Factory         = cc.import(".Factory", _CURRENT_MODULE)
_M.NginxBootstrap  = cc.import(".NginxBootstrap", _CURRENT_MODULE)
_M.WorkerBootstrap = cc.import(".WorkerBootstrap", _CURRENT_MODULE)
_M.CLIBootstrap    = cc.import(".CLIBootstrap", _CURRENT_MODULE)

_M.server = {
    Constants            = cc.import(".server.Constants", _CURRENT_MODULE),
    ActionBase           = cc.import(".server.ActionBase", _CURRENT_MODULE),
    AppBase              = cc.import(".server.AppBase", _CURRENT_MODULE),
    CLIBase              = cc.import(".server.CLIBase", _CURRENT_MODULE),
    WorkerBase           = cc.import(".server.WorkerBase", _CURRENT_MODULE),
}

if ngx then
    _M.server.ConnectBase          = cc.import(".server.ConnectBase", _CURRENT_MODULE)
    _M.server.HttpConnectBase      = cc.import(".server.HttpConnectBase", _CURRENT_MODULE)
    _M.server.SessionService       = cc.import(".server.SessionService", _CURRENT_MODULE)
    _M.server.WebSocketConnectBase = cc.import(".server.WebSocketConnectBase", _CURRENT_MODULE)
end

return _M
