cc.exports.bz = cc.exports.bz or {}

function bz.diffTable(new, old)
    local ret = {}
    for k, v in pairs(new) do
        if not old[k] then
            ret[k] = v
        end
    end
    return ret
end

function bz.checkProbability(probability)
    math.newrandomseed()
    if math.random(1000) <= probability then
        return true
    else
        return false
    end
end