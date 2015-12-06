local http = require("resty.http")
local HttpClient = class("HttpClient")

function HttpClient:ctor(url)
    self._url = url
end

function HttpClient:_request(data, method, Contenttype)
    if Contenttype == "application/json" then
        data = json.encode(data)
    end

     local ok, code, headers, status, body = http:new():request({
        url = self._url,
        timeout = 3000,
        scheme = 'http',
        method = method,
        headers = {
            ["Content-Type"] = Contenttype,
        },
        body = data,
    })

    if Contenttype == "application/json" then
        body = json.decode(body)
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