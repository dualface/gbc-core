local Time = {}

--获取当前节点中的下一个时间点
function Time.getNextTime(tList)
    local dt = os.date("*t")
    local seconds = dt.hour*60*60 + dt.min*60 + dt.sec
    for _, sec in pairs(tList) do
        if sec > seconds then
            return os.time({
                year = dt.year,
                month = dt.month,
                day = dt.day,
                hour = 0,
                min = 0,
                sec = sec,
            })
        end
    end
    return os.time({
        year = dt.year,
        month = dt.month,
        day = dt.day + 1,
        hour = 0,
        min = 0,
        sec = tList[1] or 0,
    })
end

function Time.getTimelines(gap)
    local ret = {}
    for t = gap, 24*60*60, gap do
        table.insert(ret, t)
    end
    return ret
end

function Time.getDate(time)
    return os.date("*t", time)
end

function Time.isNewDay(cdate, ldate)
    if ldate.year ~= cdate.year or ldate.yday ~= cdate.yday then
        return true
    end
    return false
end

function Time.isNewWeek(cdate, ldate)
    local wdays = cdate.wday - ldate.wday
    local ydays = cdate.yday - ldate.yday
    if wdays >= 0 and ydays ~= 0 then
        return true
    end
    return false
end

function Time.isNewMonth(cdate, ldate)
    if ldate.year ~= cdate.year or ldate.month ~= cdate.month then
        return true
    end
    return false
end

return Time