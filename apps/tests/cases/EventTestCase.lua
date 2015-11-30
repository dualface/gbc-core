--[[

Copyright (c) 2015 gameboxcloud.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]


local Event = cc.import("#event")

local helper = cc.import(".helper")
local tests = cc.import("#tests")
local check = tests.Check

local EventTestCase = cc.class("EventTestCase", tests.TestCase)

function EventTestCase:setup()
end

function EventTestCase:teardown()
end

function EventTestCase:bindingTest()
    local Animal = cc.class("Animal")

    function Animal:run()
        return "run"
    end

    function Animal:eat()
        return "eat"
    end

    local Sheep = cc.class("Sheep", Animal)

    function Sheep:eat()
        return "sheep eat"
    end

    -- create object
    local sheep = Sheep.new()

    -- add binding
    cc.bind(sheep, Event)
    check.isFunction(sheep.addEventListener)
    check.isFunction(sheep.run)
    check.isFunction(sheep.eat)
    check.equals(sheep:run(), "run")
    check.equals(sheep:eat(), "sheep eat")

    local event
    local eventName = "run"
    sheep:addEventListener(eventName, function(evt)
        event = evt
    end)
    local steps = math.random(1, 10000)
    sheep:dispatchEvent({name = eventName, steps = steps})
    check.equals(event.steps, steps)
    check.equals(event.name, eventName)

    -- remove binding
    cc.unbind(sheep, Event)
    check.isNil(sheep.addEventListener)
    check.isFunction(sheep.run)
    check.isFunction(sheep.eat)
    check.equals(sheep:run(), "run")
    check.equals(sheep:eat(), "sheep eat")

    return true
end

return EventTestCase
