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

local assert = assert
local type = type
local tostring = tostring
local string_format = string.format

local beanstalkd = require("resty.beanstalkd")

local RestyBeanstalkdAdapter = class("RestyBeanstalkdAdapter")

function RestyBeanstalkdAdapter:ctor(config)
    self._config = config
    self._instance = beanstalkd:new()
end

function RestyBeanstalkdAdapter:connect()
    self._instance:set_timeout(self._config.timeout)

    return self._instance:connect(self._config.host, self._config.port)
end

function RestyBeanstalkdAdapter:close()
    return self._instance:close()
end

function RestyBeanstalkdAdapter:setKeepAlive(timeout, size)
    if size then
        return self._instance:set_keepalive(timeout, size)
    elseif timeout then
        return self._instance:set_keepalive(timeout)
    else
        return self._instance:set_keepalive()
    end
end

function RestyBeanstalkdAdapter:command(command, ...)
    local method = self._instance[command]
    if type(method) ~= "function" then
        local err = string_format("invalid beanstalkd command \"%s\"", string_upper(command))
        printError("%s", err)
        return nil, err
    end

    return method(self._instance, ...)
end

return RestyBeanstalkdAdapter
