local http = require("resty.http")
local HttpClient = cc.class("HttpClient")

local json = cc.import("#json")

function HttpClient:ctor(url)
    self._url = url
end

function HttpClient:_request(data, method, Contenttype)
    if Contenttype == "application/json" then
        data = json.encode(data)
    end

     local res, err = http:new():request_uri(self._url, {
        timeout = 3000,
        scheme = 'http',
        method = method,
        headers = {
            ["Content-Type"] = Contenttype,
        },
        body = data,
    })
    if not res then
        cc.printinfo("failed to request:"..err)
        return false
    end

    if Contenttype == "application/json" then
        res.body = json.decode(res.body)
    end
    return true, res.status, res.body
end

function HttpClient:Post(data)
   return self:_request(data, "POST", "application/json")
end

function HttpClient:Get(data)
    return self:_request(data, "GET", "application/json")
end

return HttpClient