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

local assert = assert
local type = type
local tostring = tostring
local string_format = string.format
local string_upper = string.upper

local haricot = require("3rd.beanstalkd.haricot")

local BeanstalkdHaricotAdapter = class("BeanstalkdHaricotAdapter")

function BeanstalkdHaricotAdapter:ctor(config)
    self._config = config
    self._instance = haricot.new(self._config.host, self._config.port)
end

function BeanstalkdHaricotAdapter:connect()
    return true
end

function BeanstalkdHaricotAdapter:close()
    return self._instance:quit()
end

function BeanstalkdHaricotAdapter:command(command, ...)
    local method = self._instance[command]
    if type(method) ~= "function" then
        local err = string_format("invalid beanstalkd command \"%s\"", string_upper(command))
        printError("%s", err)
        return nil, err
    end

    local ok, result = method(self._instance, ...)
    if ok then return result end
    return nil, result
end

return BeanstalkdHaricotAdapter
