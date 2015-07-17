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

local json_encode = json.encode
local json_decode = json.decode
local string_format = string.format
local os_tmpname = os.tmpname
local os_execute = os.execute
local os_remove = os.remove

local Factory = require("server.base.Factory")

--

local TEST_CASES = {
    "jobs.add",
    "jobs.query",
    "jobs.remove",
}

local CURL_PATTERN = "curl -s --no-keepalive -o '%s' '%s'"
local REQUEST_PATTERN = string_format("http://localhost:%s/tests/?action=%%s", tostring(SERVER_CONFIG.server.nginx.port))

local appConfigs

--

local function runTest(testfun, arg, action)
    local result
    local err

    local ok, contents = xpcall(function()
        return testfun(unpack(arg))
    end, function(_err)
        err = _err .. debug.traceback("", 4)
    end)

    if type(contents) == "table" then
        result = contents
    else
        result = json_decode(tostring(contents))
        if type(result) ~= "table" then
            contents = tostring(contents)
            contents = string.gsub(contents, "\\n", "\n")
            contents = string.gsub(contents, "\\\"", '"')
            result = {err = err}
        end
    end

    if result.err then
        print(string_format("[%s] \27[31mfailed\27[0m: %s", action, result.err))
    elseif result.ok == true then
        print(string_format("[%s] \27[32mok\27[0m", action))
        return true
    else
        print(string_format("[%s] \27[33minvalid result\27[0m: %s", action, contents))
    end
end

local function testInServer(action)
    local tmpfile = os_tmpname()
    local url = string_format(REQUEST_PATTERN, action)
    local cmd = string_format(CURL_PATTERN, tmpfile, url)
    os_execute(cmd)
    local contents = io.readfile(tmpfile)
    os_remove(tmpfile)
    return contents
end

local function testInCLI(action)
    local cmd = Factory.create(appConfigs[TESTS_APP_ROOT], "CLI", arg)
    return cmd:runAction(action)
end

--

appConfigs = Factory.makeAppConfigs(SERVER_APP_KEYS, SERVER_CONFIG, package.path)

for _, action in ipairs(TEST_CASES) do
    if not runTest(testInServer, {action}, "SERVER " .. action) then
        break
    end
    if not runTest(testInCLI, {action}, "CLI    " .. action) then
        break
    end
end

print("")
