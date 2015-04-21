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

local ActionDispatcher = import(".ActionDispatcher")
local Constants = import(".Constants")

local CLIBase = class("CLIBase", ActionDispatcher)

function CLIBase:ctor(config, arg)
    CLIBase.super.ctor(self, config)

    self._requestType = Constants.CLI_REQUEST_TYPE
    self._requestParameters = checktable(arg)
end

function CLIBase:run()
    local ok, res = xpcall(function()
        return self:runEventLoop()
    end, function(err)
        err = tostring(err)
        printError(err)
    end)

    if ok then
        if type(res) ~= "table" then
            printf(res)
        else
            dump(res)
        end
    end

    printInfo("DONE")
end

function CLIBase:runEventLoop()
    local actionName = self._requestParameters[1]
    if actionName == nil or actionName == "help" then
        self:_showHelp()
        return
    end

    return self:runAction(actionName, self._requestParameters)
end

function CLIBase:_showHelp()
    printf("usage: tools [ActionModule.Action] [args]")
end

return CLIBase
