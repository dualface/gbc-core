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

local cc           = cc
local string_upper = string.upper
local tostring     = tostring
local type         = type

local Event = cc.class("Event")

local _newtag = 0

function Event:ctor(target)
    self._target = target
    self._listeners = {}
end

function Event:bind(name, listener, tag)
    local listeners = self._listeners
    name = string_upper(tostring(name))
    if not listeners[name] then
        listeners[name] = {}
    end

    if not tag then
        _newtag = _newtag + 1
        tag = "#" .. tostring(_newtag)
    end

    listeners[name][tag] = listener

    -- cc.printinfo("[Event:%s] bind event '%s' with listener '%s'", tostring(self._target), name, tag)

    return tag
end

function Event:unbind(tag)
    local listeners = self._listeners
    for name, listenersForEvent in pairs(listeners) do
        for _tag, _ in pairs(listenersForEvent) do
            if tag == _tag then
                listenersForEvent[tag] = nil
                -- cc.printinfo("[Event:%s] unbind event '%s' listener '%s'", tostring(self._target), name, tag)
                return
            end
        end
    end
end

function Event:trigger(event)
    if type(event) ~= "table" then
        event = {name = event}
    end
    event.name = string_upper(tostring(event.name))

    -- cc.printinfo("[Event:%s] dispatch event '%s'", tostring(self), event.name)

    local listeners = self._listeners
    if not listeners[event.name] then
        return
    end

    event._stop = false
    event.target = self._target
    event.stop = function()
        event._stop = true
    end

    for tag, listener in pairs(listeners[event.name]) do
        -- cc.printinfo("[Event:%s] trigger event '%s' to listener '%s'", tostring(self._target), event.name, tag)
        listener(event)
        if event._stop then
            cc.printinfo("[Event:%s] break dispatching event '%s'", tostring(self._target), event.name)
            break
        end
    end
end

function Event:remove(name)
    name = string_upper(tostring(name))
    self._listeners[name] = nil
    -- cc.printinfo("[Event:%s] remove event '%s' all listeners", tostring(self._target), name)
end

function Event:removeAll()
    self._listeners = {}
    -- cc.printinfo("[Event:%s] remove all listeners", tostring(self._target))
end

function Event:dump()
    cc.printinfo("[Event:%s] dump all listeners", tostring(self._target))
    for name, listeners in pairs(self._listeners) do
        cc.printf("  event: %s", name)
        for tag, listener in pairs(listeners) do
            cc.printf("    %s: %s", tag, tostring(listener))
        end
    end
end

return Event
