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

ROOT_DIR = args[1]
APP_ROOT_PATH = args[2]
table.remove(args, 1)
table.remove(args, 1)

package.path = table.concat({
    ROOT_DIR, '/src/?.lua;',
    ROOT_DIR, '/src/lib/?.lua;',
    package.path}, "")

SERVER_CONFIG = dofile(ROOT_DIR .. "/tmp/config.lua")
SERVER_APP_KEYS = dofile(ROOT_DIR .. "/tmp/app_keys.lua")
DEBUG = _DBG_DEBUG

require("framework.init")

local Factory = require("server.base.Factory")

local function startWorker(appRootPath, args, tag)
    local appConfigs = Factory.makeAppConfigs(SERVER_APP_KEYS, SERVER_CONFIG, package.path)
    local appConfig = appConfigs[appRootPath]
    if type(appConfig) ~= "table" then
        printf("[ERR] invalid app config for path: %s", appRootPath)
        return 1
    end

    local worker = Factory.create(appConfig, "Worker", args, tag)
    return worker:run()
end

local process = require("process")
local pid = tostring(process.getpid())

return startWorker(APP_ROOT_PATH, args, pid)
