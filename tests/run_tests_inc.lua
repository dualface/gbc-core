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
local string_sub = string.sub
local string_lower = string.lower
local os_tmpname = os.tmpname
local os_execute = os.execute
local os_remove = os.remove

local Factory = require("server.base.Factory")

--

local TEST_CASES = {
    "RedisTestCase",
    "JobsTestCase",
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

    if contents == true then
        result = {ok = true}
    elseif type(contents) == "table" then
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
    elseif tostring(result.ok) == "true" or tostring(result.result) == "true" then
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
    return string.rtrim(contents)
end

local function testInCLI(action)
    local cmd = Factory.create(appConfigs[TESTS_APP_ROOT], "CLI", arg)
    return cmd:runAction(action)
end

--

appConfigs = Factory.makeAppConfigs(SERVER_APP_KEYS, SERVER_CONFIG, package.path)

package.path = TESTS_APP_ROOT .. "/?.lua;" .. package.path

local NO_STOP_ON_FAILED = NO_STOP_ON_FAILED

local pass
for _, testCaseClassName in ipairs(TEST_CASES) do
    local testCaseClass = require("cases." .. testCaseClassName)
    local actionPackageName = string_lower(string_sub(testCaseClassName, 1, -9))
    local tests = {}
    for methodName, _2 in pairs(testCaseClass) do
        if string_sub(methodName, -4) == "Test" then
            tests[#tests + 1] = actionPackageName .. "." .. string_lower(string_sub(methodName, 1, -5))
        end
    end

    table.sort(tests)

    print(string_format("## Test Case : %s", actionPackageName))

    for _3, action in ipairs(tests) do
        pass = runTest(testInServer, {action}, "SERVER " .. action)
        if (not pass) and (not NO_STOP_ON_FAILED) then
            break
        end
        pass = runTest(testInCLI, {action}, "CLI    " .. action)
        if (not pass) and (not NO_STOP_ON_FAILED) then
            break
        end
    end

    print("")

    if (not pass) and (not NO_STOP_ON_FAILED) then
        break
    end

end
