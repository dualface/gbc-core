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

_QUICK_SERVER_VERSION = "0.5.1"

_DBG_ERROR = 0
_DBG_WARN  = 1
_DBG_INFO  = 2
_DBG_DEBUG = 3

local config = {
    -- user app
    appRootPath = "_QUICK_SERVER_ROOT_/<USER_APP_ROOT>",

    numOfWorkers = 4,

    appHttpMessageFormat   = "json",
    appSocketMessageFormat = "json",
    appJobMessageFormat    = "json",
    appSessionExpiredTime  = 60 * 10, -- 10m

    -- quick server
    quickserverRootPath = "_QUICK_SERVER_ROOT_",
    port = 8088,
    welcomeEnabled = true,
    adminEnabled = true,
    websocketsTimeout = 60 * 1000, -- 60s
    websocketsMaxPayloadLen = 16 * 1024, -- 16KB
    maxSubscribeRetryCount = 10,

    -- internal memory database
    redis = {
        socket     = "unix:_QUICK_SERVER_ROOT_/tmp/redis.sock",
        -- host       = "127.0.0.1",
        -- port       = 6379,
        timeout    = 10 * 1000, -- 10 seconds
    },

    -- background job server
    beanstalkd = {
        host       = "127.0.0.1",
        port       = 11300,
        jobTube    = "jobTube",
    },

    -- internal monitor
    monitor = {
        process = {
            "nginx",
            "redis-server",
            "beanstalkd",
        },

        interval = 2,
    },
}

return config
