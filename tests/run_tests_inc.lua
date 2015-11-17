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

local json_decode = json.decode
local json_encode = json.encode
local os_execute = os.execute
local os_remove = os.remove
local os_tmpname = os.tmpname
local string_format = string.format
local string_lower = string.lower
local string_sub = string.sub

local Factory = require("server.base.Factory")

local Tests = class("Tests")

local _CURL_PATTERN = "curl -s --no-keepalive -o '%s' '%s'"
local _REQUEST_PATTERN = string_format("http://localhost:%s/tests/?action=%%s", tostring(SERVER_CONFIG.server.nginx.port))

local _parseargs, _findtests
local _runtest, _testsrv, _testcli
local _help

function Tests:ctor()
    package.path = TESTS_APP_ROOT .. "/?.lua;" .. package.path
end

function Tests:run(args)
    local opts, err = _parseargs(args)
    if not opts then
        _help()
        return
    end

    local appConfigs = Factory.makeAppConfigs(SERVER_APP_KEYS, SERVER_CONFIG, package.path)
    local appConfig = appConfigs[TESTS_APP_ROOT]

    if #opts.tests == 0 then
        local casesDir= TESTS_APP_ROOT .. "/cases"
        opts.tests = _findtests(casesDir)
    end

    local pass
    for _, casename in ipairs(opts.tests) do
        if string.sub(casename, -8) ~= "TestCase" then
            casename = string.ucfirst(string.lower(casename)) .. "TestCase"
        end

        local ok, testCaseClass = pcall(require, "cases." .. casename)
        if not ok then
            printf("ERR: not found test '%s'", casename)
            break
        end
        local actionPackageName = string_lower(string_sub(casename, 1, -9))
        local tests = {}
        for methodName, _2 in pairs(testCaseClass) do
            if string_sub(methodName, -4) == "Test" then
                tests[#tests + 1] = actionPackageName .. "." .. string_lower(string_sub(methodName, 1, -5))
            end
        end

        table.sort(tests)

        print(string_format("## Test Case : %s", actionPackageName))

        for _3, action in ipairs(tests) do
            if opts.testsrv then
                pass = _runtest(appConfig, _testsrv, {action}, "SERVER " .. action)
                if (not pass) and (not opts.continue) then
                    break
                end
            end

            if opts.testcli then
                pass = _runtest(appConfig, _testcli, {action}, "CLI    " .. action)
                if (not pass) and (not opts.continue) then
                    break
                end
            end
        end

        print("")

        if (not pass) and (not opts.continue) then
            break
        end

    end
end

-- private

_parseargs = function(args)
    local opts = {
        continue = false,
        testsrv = true,
        testcli = true,
        tests = {}
    }
    for _, arg in ipairs(string.split(args, " ")) do
        if arg == "-h" then
            return
        elseif arg == "-c" then
            opts.continue = true
        elseif arg == "-ns" then
            opts.testsrv = false
        elseif arg == "-nc" then
            opts.testcli = false
        elseif string.sub(arg, 1, 1) == "-" then
            print("Invalid options")
            return
        else
            opts.tests[#opts.tests + 1] = arg
        end
    end

    return opts
end

_findtests = function(rootdir)
    local command = string.format('ls "%s"', rootdir)
    local h = io.popen(command)
    local res = h:read("*a")
    h:close()

    local cases = {}
    for _, file in ipairs(string.split(res, "\n")) do
        if string.sub(file, -12) == "TestCase.lua" then
            cases[#cases + 1] = string.sub(file, 1, -5)
        end
    end

    table.sort(cases)

    return cases
end

_runtest = function(appConfig, testfun, arg, action)
    local result
    local err

    local ok, contents = xpcall(function()
        return testfun(appConfig, unpack(arg))
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

_testsrv = function(_, action)
    local tmpfile = os_tmpname()
    local url = string_format(_REQUEST_PATTERN, action)
    local cmd = string_format(_CURL_PATTERN, tmpfile, url)
    os_execute(cmd)
    local contents = io.readfile(tmpfile)
    os_remove(tmpfile)
    return string.rtrim(contents)
end

_testcli = function(appConfig, action)
    local cmd = Factory.create(appConfig, "CLI", arg)
    return cmd:runAction(action)
end

_help = function()
    print [[

$ run_tests.sh [options] [test case name ...]

options:
-h: show help
-c: continue when test failed
-ns: skip server tests
-nc: skip cli tests

examples:

# run JobsTestCase and RedisTestCase
run_tests.sh jobs redis

]]

end

return Tests
