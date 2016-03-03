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

local ngx               = ngx
local ngx_say           = ngx.say
local req_get_body_data = ngx.req.get_body_data
local req_get_headers   = ngx.req.get_headers
local req_get_method    = ngx.req.get_method
local req_get_post_args = ngx.req.get_post_args
local req_get_uri_args  = ngx.req.get_uri_args
local req_read_body     = ngx.req.read_body
local string_format     = string.format
local string_gsub       = string.gsub
local string_ltrim      = string.ltrim
local table_merge       = table.merge

local json      = cc.import("#json")
local Constants = cc.import(".Constants")

local InstanceBase = cc.import(".InstanceBase")
local HttpInstanceBase = cc.class("HttpInstanceBase", InstanceBase)

function HttpInstanceBase:ctor(config)
    HttpInstanceBase.super.ctor(self, config, Constants.HTTP_REQUEST_TYPE)

    if config.app.httpMessageFormat then
        self.config.app.messageFormat = config.app.httpMessageFormat
    end

    self._requestMethod     = req_get_method()
    self._requestParameters = req_get_uri_args()

    if self._requestMethod == "POST" then
        req_read_body()
        -- handle json body
        local headers = req_get_headers()
        if headers["Content-Type"] == "application/json" then
            local body = req_get_body_data()
            --[[
            This function returns nil if

            - the request body has not been read,
            - the request body has been read into disk temporary files,
            - or the request body has zero size.

            If the request body has not been read yet, call ngx.req.read_body first
            (or turned on lua_need_request_body to force this module to read the
            request body. This is not recommended however).

            If the request body has been read into disk files, try calling
            the ngx.req.get_body_file function instead.

            To force in-memory request bodies, try setting client_body_buffer_size
            to the same size value in client_max_body_size.
            ]]
            if body then
                local data, err = json.decode(body)
                if err then
                   cc.printwarn("HttpInstanceBase:ctor() - invalid JSON content, %s", err)
                else
                    table_merge(self._requestParameters, data)
                end
            end
        else
            table_merge(self._requestParameters, req_get_post_args())
        end
    end
end

function HttpInstanceBase:onClose()
    -- body
end

function HttpInstanceBase:run()
    local result, err = self:runEventLoop()
    self:onClose()
    result, err = self:_genOutput(result, err)
    if err then
        -- return an error page with custom contents
        ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
        ngx_say(err)
        ngx.exit(ngx.HTTP_OK)
    else
        ngx.status = ngx.HTTP_OK
        if result then ngx_say(result) end
    end
end

-- actually it is not a loop, since it is based on HTTP.
function HttpInstanceBase:runEventLoop()
    local actionName = self._requestParameters.action or ""
    actionName = tostring(actionName)
    if cc.DEBUG > cc.DEBUG_WARN then
       cc.printinfo("HTTP action: %s, data: %s", actionName, json.encode(self._requestParameters))
    end

    local err = nil
    local ok, result = xpcall(function()
        return self:runAction(actionName, self._requestParameters)
    end, function(_err)
        err = _err
        if cc.DEBUG > cc.DEBUG_WARN then
            err = debug.traceback(err, 3)
            cc.printwarn(err)
        end
    end)
    if err then
        return nil, self:_formatError(actionName, err)
    end
    return result
end

function HttpInstanceBase:_formatError(actionName, err)
    return string_format("run action \"%s\" error, %s", actionName, err)
end

function HttpInstanceBase:_genOutput(result, err)
    local rtype = type(result)
    if self.config.app.messageFormat == Constants.MESSAGE_FORMAT_JSON then
        if err then
            result = {err = err}
        elseif rtype == "nil" then
            result = {}
        elseif rtype ~= "table" then
            result = {result = tostring(result)}
        end
        return json.encode(result)
    elseif self.config.app.messageFormat == Constants.MESSAGE_FORMAT_TEXT then
        if err then
            return nil, err
        elseif rtype == "nil" then
            return ""
        else
            return tostring(result)
        end
    end
end

return HttpInstanceBase
