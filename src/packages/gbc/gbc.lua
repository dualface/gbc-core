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

local _M = {
    VERSION                 = "0.8.0",

    Constants               = cc.import(".Constants", _CUR),
    Factory                 = cc.import(".Factory", _CUR),

    ActionBase              = cc.import(".ActionBase", _CUR),
    InstanceBase            = cc.import(".InstanceBase", _CUR),

    CommandLineInstanceBase = cc.import(".CommandLineInstanceBase", _CUR),
    CommandLineBootstrap    = cc.import(".CommandLineBootstrap", _CUR),

    WorkerInstanceBase      = cc.import(".WorkerInstanceBase", _CUR),
    WorkerBootstrap         = cc.import(".WorkerBootstrap", _CUR),

    Broadcast               = cc.import(".Broadcast", _CUR),
}

if ngx then
    _M.HttpInstanceBase      = cc.import(".HttpInstanceBase", _CUR)
    _M.WebSocketInstanceBase = cc.import(".WebSocketInstanceBase", _CUR)
    _M.NginxBootstrap        = cc.import(".NginxBootstrap", _CUR)
end

return _M
