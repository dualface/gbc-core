
local actions = {
    "jobs.add",
    "jobs.query",
    "jobs.remove",
}

--

local json_encode = json.encode
local json_decode = json.decode
local string_format = string.format
local os_tmpname = os.tmpname
local os_execute = os.execute
local os_remove = os.remove

local CURL_PATTERN = "curl -s --no-keepalive -o '%s' '%s'"
local REQUEST_PATTERN = "http://localhost:8088/tests/?action=%s"

local function printResult(contents, action)
    local j = json_decode(contents)
    if type(j) ~= "table" then
        contents = string.gsub(contents, "\\n", "\n")
        contents = string.gsub(contents, "\\\"", '"')
        print(string_format("[%s] invalid result: %s", action, contents))
        return
    end

    if j.err then
        print(string_format("[%s] \27[31mfailed\27[0m: %s", action, j.err))
    elseif j.ok == true then
        print(string_format("[%s] \27[32mok\27[0m", action))
    else
        print(string_format("[%s] \27[33minvalid result\27[0m: %s", action, contents))
    end
end

local function test(action)
    local tmpfile = os_tmpname()
    local url = string_format(REQUEST_PATTERN, action)
    local cmd = string_format(CURL_PATTERN, tmpfile, url)
    os_execute(cmd)
    local contents = io.readfile(tmpfile)
    os_remove(tmpfile)
    return contents
end

for _, action in ipairs(actions) do
    printResult(test(action), action)
end

print("")
