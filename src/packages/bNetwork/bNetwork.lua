local _M = {}

if ngx then
    _M.HttpClient = cc.import(".HttpClientResty")
else
    _M.HttpClient = cc.import(".HttpClientLua")
end

return _M