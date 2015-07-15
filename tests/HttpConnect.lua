
local HttpConnectBase = require("server.base.HttpConnectBase")
local HttpConnect = class("HttpConnect", HttpConnectBase)

local STRIP_LUA_PATH_PATTERN = "[./%a]+.lua:%d+: "

function HttpConnect:_formatError(actionName, err)
    return string.gsub(err, STRIP_LUA_PATH_PATTERN, "")
end

return HttpConnect
