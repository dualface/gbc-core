local http = require "socket.http"
local ltn12 = require "ltn12"

local HttpClient = cc.class("HttpClient")

local json = cc.import("#json")

function HttpClient:ctor(url)
    self._url = url
end

function HttpClient:_request(data, method, Contenttype)
    if Contenttype == "application/json" then
        data = json.encode(data)
    end
    local respbody = {} 
    local ok, code, headers, status = http.request{
        method = method,
        url = self._url,
        headers = {
            ["Content-Type"] = Contenttype,  
            ["Content-Length"] = #data, 
        },
        source = ltn12.source.string(data),
        sink = ltn12.sink.table(respbody),
    }

    local body
    if Contenttype == "application/json" then
        if respbody[1] then
            body = json.decode(respbody[1])
        end
    end
    return ok, code, body
end

function HttpClient:Post(data)
   return self:_request(data, "POST", "application/json")
end

function HttpClient:Get(data)
    return self:_request(data, "GET", "application/json")
end

return HttpClient