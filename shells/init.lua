
if not ROOT_DIR then
    print("Not set ROOT_DIR for Lua, exit.")
    os.exit(1)
end

if not _DEBUG then _DEBUG = 1 end

if tostring(_DEBUG) == "0" then
    DEBUG = false
else
    DEBUG = true
end

LUA_BIN             = ROOT_DIR .. "/bin/openresty/luajit/bin/lua"
NGINX_DIR           = ROOT_DIR .. "/bin/openresty/nginx"
REDIS_DIR           = ROOT_DIR .. "/bin/redis"
TMP_DIR             = ROOT_DIR .. "/tmp"
CONF_DIR            = ROOT_DIR .. "/conf"

CONF_PATH           = CONF_DIR .. "/config.lua"
NGINX_CONF_PATH     = CONF_DIR .. "/nginx.conf"
REDIS_CONF_PATH     = CONF_DIR .. "/redis.conf"

VAR_CONF_PATH       = TMP_DIR .. "/config.lua"
VAR_NGINX_CONF_PATH = TMP_DIR .. "/nginx.conf"
VAR_REDIS_CONF_PATH = TMP_DIR .. "/redis.conf"
VAR_BEANS_LOG_PATH  = TMP_DIR .. "/beanstalkd.log"


local ARGS = {...}

local exists
local readfile
local writefile
local split

--

function updateConfig()
    local contents = readfile(CONF_PATH)
    contents = string.gsub(contents, "_GBC_CORE_ROOT_", ROOT_DIR)
    writefile(VAR_CONF_PATH, contents)

    -- update all apps key and index
    -- local varKeysPath = string.format(TMP_DIR
    -- local apps = getValue(config, "apps")

    -- local includes = {}
    -- for name, path in pairs(apps) do
    --     local entryPath = string.format("%s/app_entry.conf", path)
    --     local varEntryPath = string.format("%s/app_%s_entry.conf", TMP_DIR, name)
    --     if exists(entryPath) then
    --         local entry = readfile(entryPath)
    --         entry = string.gsub(entry, "_GBC_CORE_ROOT_", ROOT_DIR)
    --         entry = string.gsub(entry, "_APP_ROOT_", path)
    --         writefile(varEntryPath, entry)
    --         includes[#includes + 1] = string.format("        include %s;", varEntryPath)
    --     end
    -- end
end

function checkVarConfig()
    if not exists(VAR_CONF_PATH) then
        print(string.format("[ERR] Not found file: %s", VAR_CONF_PATH))
        os.exit(1)
    end

    local config = loadfile(VAR_CONF_PATH)()
    if type(config) ~= "table" then
        print(string.format("[ERR] Invalid config file: %s", VAR_CONF_PATH))
        os.exit(1)
    end

    return config
end

function getValue(t, key, def)
    local keys = split(key, ".")
    for _, key in ipairs(keys) do
        if t[key] then
            t = t[key]
        else
            if type(def) ~= "nil" then return def end
            return nil
        end
    end
    return t
end

function updateNginxConfig()
    local config = checkVarConfig()

    local contents = readfile(NGINX_CONF_PATH)
    contents = string.gsub(contents, "_GBC_CORE_ROOT_", ROOT_DIR)
    contents = string.gsub(contents, "listen[ \t]+[0-9]+",
            string.format("listen %d", getValue(config, "server.nginx.port", 8088)))
    contents = string.gsub(contents, "worker_processes[ \t]+[0-9]+",
            string.format("worker_processes %d", getValue(config, "server.nginx.numOfWorkers", 4)))

    if DEBUG then
        contents = string.gsub(contents, "DEBUG = [%a_]+", "DEBUG = _DBG_DEBUG")
        contents = string.gsub(contents, "error_log logs/error.log[ \t%a]*;", "error_log logs/error.log debug;")
        contents = string.gsub(contents, "lua_code_cache[ \t]+%a+;", "lua_code_cache off;")
    else
        contents = string.gsub(contents, "DEBUG = [%a_]+", "DEBUG = _DBG_ERROR")
        contents = string.gsub(contents, "error_log logs/error.log[ \t%a]*;", "error_log logs/error.log;")
        contents = string.gsub(contents, "lua_code_cache[ \t]+%a+;", "lua_code_cache on;")
    end

    -- copy app_entry.conf to tmp/
    local apps = getValue(config, "apps")
    local includes = {}
    for name, path in pairs(apps) do
        local entryPath = string.format("%s/app_entry.conf", path)
        local varEntryPath = string.format("%s/app_%s_entry.conf", TMP_DIR, name)
        if exists(entryPath) then
            local entry = readfile(entryPath)
            entry = string.gsub(entry, "_GBC_CORE_ROOT_", ROOT_DIR)
            entry = string.gsub(entry, "_APP_ROOT_", path)
            writefile(varEntryPath, entry)
            includes[#includes + 1] = string.format("        include %s;", varEntryPath)
        end
    end
    includes = "\n" .. table.concat(includes, "\n")
    contents = string.gsub(contents, "\n[ \t]*#[ \t]*_INCLUDE_APPS_ENTRY_", includes)

    writefile(VAR_NGINX_CONF_PATH, contents)
end

function updateRedisConfig()
    local config = checkVarConfig()

    local contents = readfile(REDIS_CONF_PATH)
    contents = string.gsub(contents, "_GBC_CORE_ROOT_", ROOT_DIR)

    local socket = getValue(config, "server.redis.socket")
    if socket then
        if string.sub(socket, 1, 5) == "unix:" then
            socket = string.sub(socket, 6)
        end
        contents = string.gsub(contents, "[# \t]*unixsocket[ \t]+[%a\\/\\.]+",
                string.format("unixsocket %s", socket))
    else
        contents = string.gsub(contents, "[# \t]*unixsocket[ \t]+", "# unixsocket")
    end

    local host = getValue(config, "server.redis.host")
    if host then
        contents = string.gsub(contents, "[# \t]*bind[ \t]+[%d\\.]+",
                string.format("bind %s", host))
    else
        contents = string.gsub(contents, "[# \t]*bind[ \t]+[%d\\.]+", "# bind 127.0.0.1")
    end

    local port = getValue(config, "server.redis.port")
    if port then
        contents = string.gsub(contents, "\n[# \t]*port[ \t]+[%d]+",
                string.format("\nport %s", tostring(port)))
    else
        contents = string.gsub(contents, "\n[# \t]*port[ \t]+[%d]+", "\nport 0")
    end

    writefile(VAR_REDIS_CONF_PATH, contents)
end

function getRedisArgs()
    local config = checkVarConfig()

    local args = {}
    local socket = getValue(config, "server.redis.socket")
    if socket then
        if string.sub(socket, 1, 5) == "unix:" then
            socket = string.sub(socket, 6)
        end
        args[#args + 1] = string.format("-s %s", socket)
    else
        local host = getValue(config, "server.redis.host")
        local port = getValue(config, "server.redis.port")

        if host then
            args[#args + 1] = string.format("-h %s", host)
        end
        if port then
            args[#args + 1] = string.format("-p %s", tostring(port))
        end
    end

    return table.concat(args, " ")
end

function getBeanstalkdArgs()
    local config = checkVarConfig()

    local args = {"-F"}
    local host = getValue(config, "server.beanstalkd.host")
    local port = getValue(config, "server.beanstalkd.port")

    if host then
        args[#args + 1] = string.format("-l %s", host)
    end
    if port then
        args[#args + 1] = string.format("-p %s", tostring(port))
    end

    return table.concat(args, " ")
end

--

exists = function(path)
    local file = io.open(path, "r")
    if file then
        io.close(file)
        return true
    end
    return false
end

readfile = function(path)
    local file = io.open(path, "r")
    if file then
        local content = file:read("*a")
        io.close(file)
        return content
    end
    return nil
end

writefile = function(path, content, mode)
    mode = mode or "w+b"
    local file = io.open(path, mode)
    if file then
        if file:write(content) == nil then return false end
        io.close(file)
        return true
    else
        return false
    end
end

split = function(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 1, {}
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        local str = string.sub(input, pos, st - 1)
        if str ~= "" then
            table.insert(arr, str)
        end
        pos = sp + 1
    end
    if pos <= string.len(input) then
        table.insert(arr, string.sub(input, pos))
    end
    return arr
end
