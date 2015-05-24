package.path = package.path .. ";/opt/qs/src/?.lua;/opt/qs/bin/openresty/lualib/?.lua;;"

local assert = assert 
local type = type
local print = print
local pairs = pairs
local string_format = string.format
local table_cocat = table.concat
local table_insert = table.insert
local string_find = string.find

local printf = function(fmt, ...)
    local msg = string_format(fmt, ...)    
    print(msg)
end

local println = function()
    printf("")
end

local _tests = {}
local _failedTests = {}
local _steps = nil

local function _summarizeResult(suitNum, passed, failed)
    printf("Summarize %d TestSuits", suitNum)
    printf("======================================")
    printf("Total TestCase: %d", passed + failed)
    printf("Passed: %d", passed)
    printf("Failed: %d", failed)
    if failed ~= 0 then
        printf("\nFailed TestCases:")
        for suitName, v in pairs(_failedTests) do
            for _, caseName in ipairs(v) do
                printf("%s_%s", suitName, caseName)
            end
        end
    end
    printf("======================================")
end

local function _runAllCase()
    local allTestResut = 1
    local suitNum = 0
    local passed = 0
    local failed = 0

    for suitName, _cases in pairs(_tests) do 
        printf("Test %s", suitName)
        printf("======================================")

        local testSuitPassed = 0
        local testSuitFailed = 0
        for caseName, steps in pairs(_cases) do 
            assert(type(steps) == "table")

            printf("Run TestCase: %s", caseName)
            local run = loadstring(table_cocat(steps, "\n"))
            local r = run() 
            printf("End TestCase: %s", caseName) 
            if r then
                testSuitPassed = testSuitPassed + 1
                printf("--- Passed ---\n")
            else
                testSuitFailed = testSuitFailed + 1
                allTestResut = 0
                printf("--- Failed ---\n")

                -- recorde failed test case
                _failedTests[suitName] = _failedTests[suitName] or {}
                table_insert(_failedTests[suitName], caseName)
            end
        end

        printf("======================================")
        printf("Total TestCase in %s: %d",  suitName, testSuitPassed + testSuitFailed)
        printf("Passed: %d", testSuitPassed)
        printf("Failed: %d", testSuitFailed)
        println()

        suitNum = suitNum + 1
        passed = passed + testSuitPassed 
        failed = failed + testSuitFailed
    end 
    
    _summarizeResult(suitNum, passed, failed)

    return allTestResut 
end

local function _runCase(testSuitName, testCaseName)
end

local function _register(testSuitName, testCaseName)
    assert(type(testSuitName) == "string")
    assert(type(testCaseName) == "string")

    _tests[testSuitName] = _tests[testSuitName] or {}
    _tests[testSuitName][testCaseName] = _tests[testSuitName][testCaseName] or {}

    return _tests[testSuitName][testCaseName]
end

function BEGIN_CASE(testSuitName, testCaseName)
    _steps = _register(testSuitName, testCaseName) 
end

function END_CASE()
    local codes = [[do
        return true
    end]]
    table_insert(_steps, codes)
    _steps = nil
end

function RUN_ALL_CASES() 
    _runAllCase()
end

-- expections

-- boolean
function EXPECT_TRUE(condition)
    assert(_steps)

    if condition == false then
        local codes = [[do 
            return false
        end
        ]]
        table_insert(_steps, codes)
    end
end

function EXPECT_FALSE(condition)
    assert(_steps)

    if condition == true then
        local codes = [[do
            return false
        end
        ]]
        table_insert(_steps, codes)
    end
end

-- numeric
function EXPECT_EQ(expected, actual)
    assert(_steps)

    if expected ~= actual then
        local codes = [[do
            return false
        end
        ]]
        table_insert(_steps, codes)
    end
end

function EXPECT_NE(val1, val2)
    assert(_steps)

    if val1 == val2 then
        local codes = [[do
            return false
        end
        ]]
        table_insert(_steps, codes)
    end
end

-- string
function EXPECT_STREQ(expectedStr, actualStr)
    assert(_steps)

    if expectedStr ~= actualStr then
        local codes = [[do
            return false
        end
        ]]
        table_insert(_steps, codes)
    end
end

function EXPECT_STRNE(str1, str2)
    assert(_steps)

    if str1 == str2 then
        local codes = [[do
            return false
        end
        ]]
        table_insert(_steps, codes)
    end
end

function EXPECT_SUBSTR(substr, actualStr)
    assert(_steps)
    
    if not string_find(actualStr, substr) then
        local codes = [[do
            return false
        end
        ]]
        table_insert(_steps, codes)
    end
end

function EXPECT_NOCASE_STREQ(expectedStr, actualStr)
    assert(_steps)

    if string_lower(expectedStr) ~= string_lower(actualStr) then
        local codes = [[do
            return false
        end
        ]]
        table_insert(_steps, codes)
    end
end

function EXPECT_NOCASE_STRNE(str1, str2)
    assert(_steps)

    if string_lower(str1) == string_lower(str2) then
        local codes = [[do
            return false
        end
        ]]
        table_insert(_steps, codes)
    end
end

-- error
function EXPECT_ERROR(errMsg, func, arg1, ...)
    assert(_steps)

    local ok, res = pcall(func, arg1, ...)
    if ok or not string_find(res, errMsg) then
        local codes = [[do
            return false
        end
        ]]
        table_insert(_steps, codes)
    end
end

-- table
function EXPECT_TABLE(tbl, resTbl)
    assert(_steps)

    for k, v in pairs(tbl) do
        if resTbl[k] ~= v then
            local codes =  [[do
                return fales
            end
            ]]
            table_insert(_steps, codes)
            break
        end
    end
end
