module("resty.http", package.seeall)

_VERSION = '0.2'

-- constants
-- connection timeout in seconds
local TIMEOUT = 60
-- default ports for document retrieval
local PORT = 80
local SSL_PORT = 443

-- user agent field sent in request
local USERAGENT = 'resty.http/' .. _VERSION

-- default url parts
local default = {
    host = "",
    port = PORT,
    path ="/",
    scheme = "http"
}


-- global variables
local url = require("resty.url")

local mt = { __index = resty.http }

local tcp = ngx.socket.tcp
local base64 = ngx.encode_base64


local function adjusturi(reqt)
    local u = reqt
    -- if there is a proxy, we need the full url. otherwise, just a part.
    if not reqt.proxy and not PROXY then
        u = {
           path = reqt.path,
           params = reqt.params,
           query = reqt.query,
           fragment = reqt.fragment
        }
    end
    return url.build(u)
end


local function adjustheaders(reqt)
    -- default headers
    local lower = {
        ["user-agent"] = USERAGENT,
        ["host"] = reqt.host,
        ["connection"] = "close, TE",
        ["te"] = "trailers"
    }
    -- if we have authentication information, pass it along
    if reqt.user and reqt.password then
        lower["authorization"] =
            "Basic " ..  (base64(reqt.user .. ":" .. reqt.password))
    end
    -- override with user headers
    for i,v in pairs(reqt.headers or lower) do
        lower[string.lower(i)] = v
    end
    return lower
end


local function adjustproxy(reqt)
    local proxy = reqt.proxy or PROXY
    if proxy then
        proxy = url.parse(proxy)
        return proxy.host, proxy.port or 3128
    else
        return reqt.host, reqt.port
    end
end


local function adjustrequest(reqt)
    -- parse url if provided
    local nreqt = reqt.url and url.parse(reqt.url, default) or {}
    -- explicit components override url
    for i,v in pairs(reqt) do nreqt[i] = v end

    if nreqt.port == nil or nreqt.port == "" then
        if nreqt.scheme == "https" then
            nreqt.port = SSL_PORT
        else
            nreqt.port = PORT
        end
    end

    -- compute uri if user hasn't overriden
    nreqt.uri = reqt.uri or adjusturi(nreqt)
    -- ajust host and port if there is a proxy
    nreqt.host, nreqt.port = adjustproxy(nreqt)
    -- adjust headers in request
    nreqt.headers = adjustheaders(nreqt)

    nreqt.timeout = reqt.timeout or TIMEOUT * 1000;

    nreqt.fetch_size = reqt.fetch_size or 16*1024 -- 16k
    nreqt.max_body_size = reqt.max_body_size or 1024*1024*1024 -- 1024mb

    if reqt.keepalive then
        nreqt.headers['connection'] = 'keep-alive'
    end

    return nreqt
end


local function receivestatusline(sock)
    local status_reader = sock:receiveuntil("\r\n")

    local data, err, partial = status_reader()
    if not data then
        return nil, "read status line failed " .. err
    end

    local t1, t2, code = string.find(data, "HTTP/%d*%.%d* (%d%d%d)")

    return tonumber(code), data
end


local function receiveheaders(sock, headers)
    local line, name, value, err, tmp1, tmp2
    headers = headers or {}
    -- get first line
    line, err = sock:receive()
    if err then return nil, err end
    -- headers go until a blank line is found
    while line ~= "" do
        -- get field-name and value
        tmp1, tmp2, name, value = string.find(line, "^(.-):%s*(.*)")
        if not (name and value) then return nil, "malformed reponse headers" end
        name = string.lower(name)
        -- get next line (value might be folded)
        line, err  = sock:receive()
        if err then return nil, err end
        -- unfold any folded values
        while string.find(line, "^%s") do
            value = value .. line
            line = sock:receive()
            if err then return nil, err end
        end
        -- save pair in table
        if headers[name] then
	    if name == "set-cookie" then
	        headers[name] = headers[name] .. "," .. value
	    else
	        headers[name] = headers[name] .. ", " .. value
	    end
        else headers[name] = value end
    end
    return headers
end

local function read_body_data(sock, size, fetch_size, callback)
    local p_size = fetch_size
    while size and size > 0 do
        if size < p_size then
            p_size = size
        end
        local data, err, partial = sock:receive(p_size)
        if not err then
            if data then
                callback(data)
            end
        elseif err == "closed" then
            if partial then
                callback(partial)
            end
            return 1 -- 'closed'
        else
            return nil, err
        end
        size = size - p_size
    end
    return 1
end

local function receivebody(sock, headers, nreqt)
    local t = headers["transfer-encoding"] -- shortcut
    local body = ''
    local callback = nreqt.body_callback
    if not callback then
        local function bc(data, chunked_header, ...)
            if chunked_header then return end
            body = body .. data
        end
        callback = bc
    end
    if t and t ~= "identity" then
        -- chunked
        while true do
            local chunk_header = sock:receiveuntil("\r\n")
            local data, err, partial = chunk_header()
            if not data then
                return nil,err
            else
                if data == "0" then
                    return body -- end of chunk
                else
                    local length = tonumber(data, 16)

                    -- TODO check nreqt.max_body_size !!

                    local ok, err = read_body_data(sock,length, nreqt.fetch_size, callback)
                    if err then
                        return nil,err
                    end
                end
            end
        end
    elseif headers["content-length"] ~= nil and tonumber(headers["content-length"]) >= 0 then
        -- content length
        local length = tonumber(headers["content-length"])
        if length > nreqt.max_body_size then
            ngx.log(ngx.INFO, 'content-length > nreqt.max_body_size !! Tail it !')
            length = nreqt.max_body_size
        end

        local ok, err = read_body_data(sock,length, nreqt.fetch_size, callback)
        if not ok then
            return nil,err
        end
    else
        -- connection close
        local ok, err = read_body_data(sock,nreqt.max_body_size, nreqt.fetch_size, callback)
        if not ok then
            return nil,err
        end
    end
    return body
end

local function shouldredirect(reqt, code, headers)
    return headers.location and
           string.gsub(headers.location, "%s", "") ~= "" and
           (reqt.redirect ~= false) and
           (code == 301 or code == 302) and
           (not reqt.method or reqt.method == "GET" or reqt.method == "HEAD")
           and (not reqt.nredirects or reqt.nredirects < 5)
end


local function shouldreceivebody(reqt, code)
    if reqt.method == "HEAD" then return nil end
    if code == 204 or code == 304 then return nil end
    if code >= 100 and code < 200 then return nil end
    return 1
end


function new(self)
    return setmetatable({}, mt)
end

function request(self, reqt)
    local code, headers, status, body, bytes, ok, err

    local nreqt = adjustrequest(reqt)

    local sock = tcp()
    if not sock then
        return nil, "create sock failed"
    end

    sock:settimeout(nreqt.timeout)

    -- connect
    ok, err = sock:connect(nreqt.host, nreqt.port)
    if err then
        return nil, "sock connected failed " .. err
    end

    -- check type of req_body, maybe string, file, function
    local req_body = nreqt.body
    local req_body_type = nil
    if req_body then
        req_body_type = type(req_body)
        if req_body_type == 'string' then -- fixed Content-Length
            nreqt.headers['content-length'] = #req_body
        end
    end

    -- send request line and headers
    local reqline = string.format("%s %s HTTP/1.1\r\n", nreqt.method or "GET", nreqt.uri)
    local h = ""
    for i, v in pairs(nreqt.headers) do
        -- fix cookie is a table value
        if type(v) == "table" then
    		if i == "cookie" then
				v = table.concat(v, "; ")
			else
				v = table.concat(v, ", ")
			end
        end
        h = i .. ": " .. v .. "\r\n" .. h
    end

    h = h .. '\r\n' -- close headers

	-- @modify: add ssl support
	if nreqt.scheme == 'https' then
		local sess, err = sock:sslhandshake();
		if err then
			return nil, err;
		end
	end

    bytes, err = sock:send(reqline .. h)
    if err then
        sock:close()
        return nil, err
    end

    -- send req_body, if exists
    if req_body_type == 'string' then
        bytes, err = sock:send(req_body)
        if err then
            sock:close()
            return nil, err
        end
    elseif req_body_type == 'file' then
        local buf = nil
        while true do -- TODO chunked maybe better
            buf = req_body:read(8192)
            if not buf then break end
            bytes, err = sock:send(buf)
            if err then
                sock:close()
                return nil, err
            end
        end
    elseif req_body_type == 'function' then
        err = req_body(sock) -- as callback(sock)
        if err then
            return err
        end
    end

    -- receive status line
    code, status = receivestatusline(sock)
    if not code then
        sock:close()
        if not status then
            return nil, "read status line failed "
        else
            return nil, "read status line failed " .. status
        end
    end

    -- ignore any 100-continue messages
    while code == 100 do
        headers, err = receiveheaders(sock, {})
        code, status = receivestatusline(sock)
    end

    -- notify code_callback
    if nreqt.code_callback then
        nreqt.code_callback(code)
    end

    -- receive headers
    headers, err = receiveheaders(sock, {})
    if err then
        sock:close()
        return nil, "read headers failed " .. err
    end

    -- notify header_callback
    if nreqt.header_callback then
        nreqt.header_callback(headers)
    end

    -- TODO rediret check

    -- receive body
    if shouldreceivebody(nreqt, code) then
        body, err = receivebody(sock, headers, nreqt)
        if err then
            sock:close()
            if code == 200 then
                return 1, code, headers, status, nil
            end
            return nil, "read body failed " .. err
        end
    end

    if nreqt.keepalive then
        sock:setkeepalive(nreqt.keepalive)
    else
        sock:close()
    end

    return 1, code, headers, status, body
end

function proxy_pass(self, reqt)
    local nreqt = {}
    for i,v in pairs(reqt) do nreqt[i] = v end

    if not nreqt.code_callback then
        nreqt.code_callback = function(code, ...)
            ngx.status = code
        end
    end

    if not nreqt.header_callback then
        nreqt.header_callback = function (headers, ...)
            for i, v in pairs(headers) do
                ngx.header[i] = v
            end
        end
    end

    if not nreqt.body_callback then
        nreqt.body_callback = function (data, ...)
            ngx.print(data) -- Will auto package as chunked format!!
        end
    end
    return request(self, nreqt)
end

-- to prevent use of casual module global variables
getmetatable(resty.http).__newindex = function (table, key, val)
    error('attempt to write to undeclared variable "' .. key .. '": '
            .. debug.traceback())
end

