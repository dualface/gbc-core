local Replay = cc.class("Replay")

function Replay:ctor(eMap)
    local rep = {}
    rep.deleteList = {}
    rep.updateList = {}
    self._Rep = rep
    self._EMap = eMap
end

function Replay:catch(func, ...)
    if func then
        local ok, err = pcall(func, self, ...)
        if not ok then
            self:addErrorMsg(err)
        end
    end
end

function Replay:addOperMsg(name)
    table.insert(self._Rep.updateList, {desc = "OperMsg", content = {
        req_descriptor = name,
    }})
end

function Replay:addErrorMsg(err)
    if self._EMap then
        local e = self._EMap[err]
        if e then
            table.insert(self._Rep.updateList, {desc = "ErrorMsg", content = e})
            return
        end
    end
    table.insert(self._Rep.updateList, {desc = "ErrorMsg", content = err})
end

function Replay:addMsg(name, data)
    table.insert(self._Rep.updateList, {desc = name, content = data})
end

function Replay:get()
    return self._Rep
end

return Replay