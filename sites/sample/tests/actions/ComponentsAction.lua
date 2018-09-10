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

local ComponentsTestCase = cc.class("ComponentsTestCase", tests.TestCase)

function ComponentsTestCase:setup()
end

function ComponentsTestCase:teardown()
end

function ComponentsTestCase:bindingAction()
    local Sheep = cc.class("Sheep")
    local sheep = Sheep:new()

    -- add component
    local eventComponent = cc.addComponent(sheep, Event)
    check.isTable(eventComponent)
    check.isFunction(eventComponent.bind)

    -- get component by class
    local eventComponent_ = cc.getComponent(sheep, Event)
    check.equals(tostring(eventComponent), tostring(eventComponent_))

    -- get component by class name
    local eventComponent_ = cc.getComponent(sheep, Event.__cname)
    check.equals(tostring(eventComponent), tostring(eventComponent_))

    -- bind listeners
    local results = {}

    local tag1 = eventComponent:bind("RUN", function(event)
        results[#results + 1] = {event.name, event.step}
    end)

    local tag2 = eventComponent:bind("RUN", function(event)
        results[#results + 1] = {event.name, event.step}
    end) -- add second listener for event "RUN"

    local tag3 = eventComponent:bind("WALK", function(event)
        results[#results + 1] = {event.name, event.step}
    end)

    -- trigger events
    local step1   = math.random(10000, 20000)
    local step2   = math.random(30000, 40000)
    local step3   = math.random(50000, 60000)

    eventComponent:trigger({name = "RUN", step = step1})
    eventComponent:trigger({name = "WALK", step = step2})

    -- unbind listener
    eventComponent:unbind(tag2)
    eventComponent:trigger({name = "RUN", step = step3})

    -- check
    check.equals(results, {
        {"RUN", step1},
        {"RUN", step1},
        {"WALK", step2},
        {"RUN", step3},
    })

    -- remove component by class
    cc.removeComponent(sheep, Event)
    check.isNil(cc.getComponent(sheep, Event))

    -- remove component by class name
    cc.addComponent(sheep, Event)
    cc.removeComponent(sheep, Event.__cname)
    check.isNil(cc.getComponent(sheep, Event))

    -- remove component by component object
    local eventComponent = cc.addComponent(sheep, Event)
    cc.removeComponent(sheep, eventComponent)
    check.isNil(cc.getComponent(sheep, Event))

    return true
end

return ComponentsTestCase
