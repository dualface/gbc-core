local StringParse = {}

function StringParse.parse(str, param1, isnumber)
    local ret = {}
    local items = string.split(str, param1)
    if not items then
        return {}
    end
    if isnumber then
        for _, v in pairs(items) do
            table.insert(ret, tonumber(v))
        end
    else
        ret = items
    end

    return ret
end

function StringParse.parseInt(str, param1, param2)
    if not param2 then
        return StringParse.parse(str, param1, true)
    end
    local ret = {}
    local items = StringParse.parse(str, param1, false)
    for _, v in pairs(items) do
        table.insert(ret, StringParse.parse(v, param2, true))
    end
    return ret
end

return StringParse