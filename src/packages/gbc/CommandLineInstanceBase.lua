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

local string_format = string.format

local Constants = cc.import(".Constants")

local InstanceBase = cc.import(".InstanceBase")
local CommandLineInstanceBase = cc.class("CommandLineInstanceBase", InstanceBase)

function CommandLineInstanceBase:ctor(config, arg)
    CommandLineInstanceBase.super.ctor(self, config, Constants.CLI_REQUEST_TYPE)
    self._requestParameters = cc.checktable(arg)
end

function CommandLineInstanceBase:run()
    local actionName = self._requestParameters.action or ""
    local result = self:runAction(actionName, self._requestParameters)
    if type(result) ~= "table" then
        print(result)
    else
        cc.dump(result)
    end
end

return CommandLineInstanceBase
