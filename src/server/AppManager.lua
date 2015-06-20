
local AppManager = class("AppManager")

function AppManager:ctor()
    -- load tmp/appId.lua
    self._paths = {}
    laodfile()
end

function AppManager:getId(appRootPath)
    if not appRootPath then
        throw("")
    end

    if not self._paths[appRootPath] then
        self._paths[appRootPath] = table.nums(self._paths) + 1
    end
    return self._paths[appRootPath]
end




return AppManager
