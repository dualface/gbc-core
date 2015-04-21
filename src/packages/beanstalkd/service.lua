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

local type = type
local string_lower = string.lower

local BeanstalkdService = class("BeanstalkdService")

local BeanstalkdAdapter
if ngx then
    BeanstalkdAdapter = import(".adapter.RestyBeanstalkdAdapter")
else
    BeanstalkdAdapter = import(".adapter.BeanstalkdHaricotAdapter")
end

function BeanstalkdService:ctor(config)
    if type(config) ~= "table" then
        throw("invalid beanstalkd config")
    end
    self._config = clone(config)
    self._beans = BeanstalkdAdapter:create(self._config)
end

function BeanstalkdService:connect()
    local ok, err = self._beans:connect()
    if err then
        throw("connect to beanstalkd failed, %s", err)
    end
end

function BeanstalkdService:close()
    self._beans:close()
end

function BeanstalkdService:setKeepAlive(timeout, size)
    if not ngx then
        self:close()
        return
    end
    self._beans:setKeepAlive(timeout, size)
end

function BeanstalkdService:command(command, ...)
    command = string_lower(command)
    local res, err = self._beans:command(command, ...)

    -- make Haricot compatible. Such as "delete", it return nil, nil.
    if not res and not err then
        res = true
    end

    if not res then
        throw("beanstalkd command \"%s\" failed, %s, %s", command, err, res)
    end

    return res
end

return BeanstalkdService
