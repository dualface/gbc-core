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
VAR_APP_KEYS_PATH   = TMP_DIR .. "/app_keys.lua"


local ARGS = {...}

local exists
local readfile
local writefile
local split
local md5

--

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

function updateConfig()
    local contents = readfile(CONF_PATH)
    contents = string.gsub(contents, "_GBC_CORE_ROOT_", ROOT_DIR)
    writefile(VAR_CONF_PATH, contents)

    -- update all apps key and index
    local config = checkVarConfig()
    local apps = getValue(config, "apps")

    local names = {}
    for name, _ in pairs(apps) do names[#names + 1] = name end
    table.sort(names)

    local contents = {"", "local keys = {}"}
    for index, name in ipairs(names) do
        local path = apps[name]
        contents[#contents + 1] = string.format('keys["%s"] = {name = "%s", index = %d, key = "%s"}',
                path, name, index, md5.sumhexa(path))
    end
    contents[#contents + 1] = "return keys"
    contents[#contents + 1] = ""

    writefile(VAR_APP_KEYS_PATH, table.concat(contents, "\n"))
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

---- md5

md5 = {
  _VERSION     = "md5.lua 1.0.2",
  _DESCRIPTION = "MD5 computation in Lua (5.1-3, LuaJIT)",
  _URL         = "https://github.com/kikito/md5.lua",
  _LICENSE     = [[
    MIT LICENSE

    Copyright (c) 2013 Enrique García Cota + Adam Baldwin + hanzao + Equi 4 Software

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}


local char, byte, format, rep, sub =
  string.char, string.byte, string.format, string.rep, string.sub
local bit_or, bit_and, bit_not, bit_xor, bit_rshift, bit_lshift

local ok, bit = pcall(require, 'bit')
bit_or, bit_and, bit_not, bit_xor, bit_rshift, bit_lshift = bit.bor, bit.band, bit.bnot, bit.bxor, bit.rshift, bit.lshift

-- convert little-endian 32-bit int to a 4-char string
local function lei2str(i)
  local f=function (s) return char( bit_and( bit_rshift(i, s), 255)) end
  return f(0)..f(8)..f(16)..f(24)
end

-- convert raw string to big-endian int
local function str2bei(s)
  local v=0
  for i=1, #s do
    v = v * 256 + byte(s, i)
  end
  return v
end

-- convert raw string to little-endian int
local function str2lei(s)
  local v=0
  for i = #s,1,-1 do
    v = v*256 + byte(s, i)
  end
  return v
end

-- cut up a string in little-endian ints of given size
local function cut_le_str(s,...)
  local o, r = 1, {}
  local args = {...}
  for i=1, #args do
    table.insert(r, str2lei(sub(s, o, o + args[i] - 1)))
    o = o + args[i]
  end
  return r
end

local swap = function (w) return str2bei(lei2str(w)) end

local function hex2binaryaux(hexval)
  return char(tonumber(hexval, 16))
end

local function hex2binary(hex)
  local result, _ = hex:gsub('..', hex2binaryaux)
  return result
end

-- An MD5 mplementation in Lua, requires bitlib (hacked to use LuaBit from above, ugh)
-- 10/02/2001 jcw@equi4.com

local CONSTS = {
  0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
  0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
  0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
  0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
  0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
  0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
  0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
  0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
  0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
  0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
  0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
  0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
  0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
  0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
  0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
  0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
  0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476
}

local f=function (x,y,z) return bit_or(bit_and(x,y),bit_and(-x-1,z)) end
local g=function (x,y,z) return bit_or(bit_and(x,z),bit_and(y,-z-1)) end
local h=function (x,y,z) return bit_xor(x,bit_xor(y,z)) end
local i=function (x,y,z) return bit_xor(y,bit_or(x,-z-1)) end
local z=function (f,a,b,c,d,x,s,ac)
  a=bit_and(a+f(b,c,d)+x+ac,0xFFFFFFFF)
  -- be *very* careful that left shift does not cause rounding!
  return bit_or(bit_lshift(bit_and(a,bit_rshift(0xFFFFFFFF,s)),s),bit_rshift(a,32-s))+b
end

local function transform(A,B,C,D,X)
  local a,b,c,d=A,B,C,D
  local t=CONSTS

  a=z(f,a,b,c,d,X[ 0], 7,t[ 1])
  d=z(f,d,a,b,c,X[ 1],12,t[ 2])
  c=z(f,c,d,a,b,X[ 2],17,t[ 3])
  b=z(f,b,c,d,a,X[ 3],22,t[ 4])
  a=z(f,a,b,c,d,X[ 4], 7,t[ 5])
  d=z(f,d,a,b,c,X[ 5],12,t[ 6])
  c=z(f,c,d,a,b,X[ 6],17,t[ 7])
  b=z(f,b,c,d,a,X[ 7],22,t[ 8])
  a=z(f,a,b,c,d,X[ 8], 7,t[ 9])
  d=z(f,d,a,b,c,X[ 9],12,t[10])
  c=z(f,c,d,a,b,X[10],17,t[11])
  b=z(f,b,c,d,a,X[11],22,t[12])
  a=z(f,a,b,c,d,X[12], 7,t[13])
  d=z(f,d,a,b,c,X[13],12,t[14])
  c=z(f,c,d,a,b,X[14],17,t[15])
  b=z(f,b,c,d,a,X[15],22,t[16])

  a=z(g,a,b,c,d,X[ 1], 5,t[17])
  d=z(g,d,a,b,c,X[ 6], 9,t[18])
  c=z(g,c,d,a,b,X[11],14,t[19])
  b=z(g,b,c,d,a,X[ 0],20,t[20])
  a=z(g,a,b,c,d,X[ 5], 5,t[21])
  d=z(g,d,a,b,c,X[10], 9,t[22])
  c=z(g,c,d,a,b,X[15],14,t[23])
  b=z(g,b,c,d,a,X[ 4],20,t[24])
  a=z(g,a,b,c,d,X[ 9], 5,t[25])
  d=z(g,d,a,b,c,X[14], 9,t[26])
  c=z(g,c,d,a,b,X[ 3],14,t[27])
  b=z(g,b,c,d,a,X[ 8],20,t[28])
  a=z(g,a,b,c,d,X[13], 5,t[29])
  d=z(g,d,a,b,c,X[ 2], 9,t[30])
  c=z(g,c,d,a,b,X[ 7],14,t[31])
  b=z(g,b,c,d,a,X[12],20,t[32])

  a=z(h,a,b,c,d,X[ 5], 4,t[33])
  d=z(h,d,a,b,c,X[ 8],11,t[34])
  c=z(h,c,d,a,b,X[11],16,t[35])
  b=z(h,b,c,d,a,X[14],23,t[36])
  a=z(h,a,b,c,d,X[ 1], 4,t[37])
  d=z(h,d,a,b,c,X[ 4],11,t[38])
  c=z(h,c,d,a,b,X[ 7],16,t[39])
  b=z(h,b,c,d,a,X[10],23,t[40])
  a=z(h,a,b,c,d,X[13], 4,t[41])
  d=z(h,d,a,b,c,X[ 0],11,t[42])
  c=z(h,c,d,a,b,X[ 3],16,t[43])
  b=z(h,b,c,d,a,X[ 6],23,t[44])
  a=z(h,a,b,c,d,X[ 9], 4,t[45])
  d=z(h,d,a,b,c,X[12],11,t[46])
  c=z(h,c,d,a,b,X[15],16,t[47])
  b=z(h,b,c,d,a,X[ 2],23,t[48])

  a=z(i,a,b,c,d,X[ 0], 6,t[49])
  d=z(i,d,a,b,c,X[ 7],10,t[50])
  c=z(i,c,d,a,b,X[14],15,t[51])
  b=z(i,b,c,d,a,X[ 5],21,t[52])
  a=z(i,a,b,c,d,X[12], 6,t[53])
  d=z(i,d,a,b,c,X[ 3],10,t[54])
  c=z(i,c,d,a,b,X[10],15,t[55])
  b=z(i,b,c,d,a,X[ 1],21,t[56])
  a=z(i,a,b,c,d,X[ 8], 6,t[57])
  d=z(i,d,a,b,c,X[15],10,t[58])
  c=z(i,c,d,a,b,X[ 6],15,t[59])
  b=z(i,b,c,d,a,X[13],21,t[60])
  a=z(i,a,b,c,d,X[ 4], 6,t[61])
  d=z(i,d,a,b,c,X[11],10,t[62])
  c=z(i,c,d,a,b,X[ 2],15,t[63])
  b=z(i,b,c,d,a,X[ 9],21,t[64])

  return A+a,B+b,C+c,D+d
end

----------------------------------------------------------------

function md5.sumhexa(s)
  local msgLen = #s
  local padLen = 56 - msgLen % 64

  if msgLen % 64 > 56 then padLen = padLen + 64 end

  if padLen == 0 then padLen = 64 end

  s = s .. char(128) .. rep(char(0),padLen-1) .. lei2str(8*msgLen) .. lei2str(0)

  assert(#s % 64 == 0)

  local t = CONSTS
  local a,b,c,d = t[65],t[66],t[67],t[68]

  for i=1,#s,64 do
    local X = cut_le_str(sub(s,i,i+63),4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4)
    assert(#X == 16)
    X[0] = table.remove(X,1) -- zero based!
    a,b,c,d = transform(a,b,c,d,X)
  end

  return format("%08x%08x%08x%08x",swap(a),swap(b),swap(c),swap(d))
end

function md5.sum(s)
  return hex2binary(md5.sumhexa(s))
end

