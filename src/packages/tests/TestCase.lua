
local TestCase = class("TestCase")

function TestCase:ctor(connect)
    self.connect = connect
    self:setup()
end

function TestCase:setup()
end

function TestCase:teardown()
end

return TestCase
