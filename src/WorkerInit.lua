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

$ lua WorkerInit <GBC_CORE_ROOT> <APP_ROOT_PATH> [args...]

]]
end

if #args < 2 then
    return help()
end

GBC_CORE_ROOT = args[1]
APP_ROOT_PATH = args[2]
table.remove(args, 1)
table.remove(args, 1)

package.path = table.concat({
    GBC_CORE_ROOT, '/src/?.lua;',
    GBC_CORE_ROOT, '/src/lib/?.lua;',
    package.path}, "")

SERVER_CONFIG = dofile(GBC_CORE_ROOT .. "/tmp/config.lua")
SERVER_APP_KEYS = dofile(GBC_CORE_ROOT .. "/tmp/app_keys.lua")
DEBUG = _DBG_DEBUG

require("framework.init")

local Factory = require("server.base.Factory")

local function startWorker(appRootPath, args)
    local appConfigs = Factory.makeAppConfigs(SERVER_APP_KEYS, SERVER_CONFIG, package.path)
    local appConfig = appConfigs[appRootPath]

    local cli = Factory.create(appConfig, "Worker", args)
    return cli:run()
end

startWorker(APP_ROOT_PATH, args)
