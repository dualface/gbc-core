
local Hello = class("Hello")

function Hello:ctor(config, actionDispatcher)
    if actionDispatcher then
        printInfo("package Hello created by autoloads")
    end
end

return Hello
