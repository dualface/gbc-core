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

if type(DEBUG) ~= "number" then DEBUG = 0 end

-- load framework
cc = cc or {}

require("framework.functions")
require("framework.server_functions")
require("framework.package_support")
json = require("framework.json")

cc.server = {VERSION = "GameBox Cloud Core 0.7.0"}

-- register the build-in packages
cc.register("event", require("framework.packages.event.init"))

-- export global variable
local __g = _G
cc.exports = {}
setmetatable(cc.exports, {
    __newindex = function(_, name, value)
        rawset(__g, name, value)
    end,

    __index = function(_, name)
        return rawget(__g, name)
    end
})

local string_split = string.split
local table_concat = table.concat

-- disable create unexpected global variable
function cc.disable_global()
    setmetatable(__g, {
        __newindex = function(_, name, value)
            local msg = string.format("USE \"cc.exports.%s = <value>\" INSTEAD OF SET GLOBAL VARIABLE", name)
            local lines = string_split(debug.traceback(msg, 4), "\n")
            local c = #lines
            if c > 4 then c = 4 end
            print(table_concat(lines, "\n", 1, c))
            print("")
            rawset(__g, name, value)
        end
    })
end

cc.disable_global()
