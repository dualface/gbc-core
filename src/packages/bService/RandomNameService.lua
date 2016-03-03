local RandomNameService = cc.class("RandomNameService")

function RandomNameService:ctor(config)
    self._NameTalbe = config
    self:init(config)
end

function RandomNameService:init(config)
    if not config.bInit then
        local cnt1 = 0
        local cnt2 = 0
        local cnt3 = 0
        for _, v in pairs(config) do
            if v.Name1 ~= "" then cnt1 = cnt1 + 1 end
            if v.Name2 ~= "" then cnt2 = cnt2 + 1 end
            if v.Name3 ~= "" then cnt3 = cnt3 + 1 end
        end
        config.bInit = true
        config.cnt1 = cnt1
        config.cnt2 = cnt2
        config.cnt3 = cnt3
    end
end

function RandomNameService:getName()
    local config = self._NameTalbe
    if not config then return "" end
    local retName = ""
    math.newrandomseed()
    local idx = math.random(1, config.cnt1)
    retName = retName..config[idx].Name1
    idx = math.random(1, config.cnt2)
    retName = retName..config[idx].Name2
    idx = math.random(1, config.cnt3)
    retName = retName..config[idx].Name3
    return retName
end

return RandomNameService