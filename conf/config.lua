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

local config = {
    DEBUG = cc.DEBUG_VERBOSE,

    -- all sites
    sites  = {
       sample = {
          server = {
             nginx = {
                port = 8088
             }
          },
          apps = {
             welcome = "_GBC_CORE_ROOT_/sites/welcome",
             tests   = "_GBC_CORE_ROOT_/sites/tests",
          }
       }
    },
 

    -- default app config
    app = {
        messageFormat              = "json",
        defaultAcceptedRequestType = "http",
        sessionExpiredTime         = 60 * 10, -- 10m

        httpEnabled                = true,
        httpMessageFormat          = "json",

        websocketEnabled           = true,
        websocketMessageFormat     = "json",
        websocketsTimeout          = 60 * 1000, -- 60s
        websocketsMaxPayloadLen    = 16 * 1024, -- 16KB

        jobMessageFormat           = "json",
        numOfJobWorkers            = 2,

        jobWorkerRequests          = 1000,
    },

    -- server config
    server = {
        nginx = {
            numOfWorkers = 4,
            --port = 8088,
        },

        -- internal memory database
        redis = {
            socket     = "unix:_GBC_CORE_ROOT_/tmp/redis.sock",
            -- host       = "127.0.0.1",
            -- port       = 6379,
            timeout    = 10 * 1000, -- 10 seconds
        },

        -- background job server
        beanstalkd = {
            -- host         = "127.0.0.1",
            host = "unix:_GBC_CORE_ROOT_/tmp/beanstalkd.sock",
            port         = 11300,
        },
    }
}

return config
