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

local args = {...}

local help = function()
    print [[

$ lua start_worker.lua <GBC_CORE_ROOT> <APP_ROOT_PATH>

]]
end

if #args < 2 then
    return help()
end

ROOT_DIR = args[1]
APP_ROOT_PATH = args[2]

package.path = ROOT_DIR .. '/src/?.lua;' .. package.path
package.path = ROOT_DIR .. '/src/lib/?.lua;' .. package.path

require("framework.init")
local appKeys = dofile(ROOT_DIR .. "/tmp/app_keys.lua")
local globalConfig = dofile(ROOT_DIR .. "/tmp/config.lua")

cc.DEBUG = globalConfig.DEBUG

local gbc = cc.import("#gbc")
local bootstrap = gbc.WorkerBootstrap:new(appKeys, globalConfig)

bootstrap:runapp(APP_ROOT_PATH)
