
local Hello = class("Hello")

function Hello:ctor(config, app)
    if app then
        printinfo("package Hello created by autoloads")
    end
end

return Hello
