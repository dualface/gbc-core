local Rpc = cc.class("Rpc")
local HttpClient
if ngx then
    HttpClient = cc.import(".HttpClientResty")
else
    HttpClient = cc.import(".HttpClientLua")
end

function Rpc:ctor(url, name)
    self._url = url or "http://127.0.0.1:8088/"
    self._AppName = name
end

function Rpc:call(action, params)
    local _, _, body = HttpClient:new(self._url..self._AppName.."/?action="..action):Post(params)
    return body
end

return Rpc