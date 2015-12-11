local socket = require("socket")
local IP = {}

function IP.parseHostname(hostname)
    local ip, resolved = socket.dns.toip(hostname)
    local list = {}
    for _, v in ipairs(resolved.ip) do
        table.insert(list, v)
    end
    return ip, list
end

function IP.getLocal()
    local hostname = socket.dns.gethostname()
    local ip, list = IP.parseHostname(hostname)
    if list[1] then
        return list[1]
    else
        return ip
    end
end

return IP