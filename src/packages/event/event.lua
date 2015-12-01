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

local function addEventListener(self, event, listener, tag)
    self._listeners = self._listeners or {}
    local listeners = self._listeners

    self._listenerNextId = self._listenerNextId or 0
    self._listenerNextId = self._listenerNextId + 1
    local id = tostring(self._listenerNextId)

    tag = tag or ""
    tag = tostring(tag)

    event = string_upper(tostring(event))
    if not listeners[event] then
        listeners[event] = {}
    end

    listeners[event][id] = {listener, tag}

    if DEBUG then
        cc.printinfo("[Event:%s] add event '%s' listener with id '%s' and tag '%s'", tostring(self), event, id, tag)
    end

    return id
end

local function dispatchEvent(self, event)
    local DEBUG = cc.DEBUG > cc.DEBUG_WARN

    if type(event) ~= "table" then
        event = {name = event}
    end
    event.name = string_upper(tostring(event.name))

    if DEBUG then
        cc.printinfo("[Event:%s] dispatch event '%s'", tostring(self), event.name)
    end

    local listeners = self._listeners
    if (not listeners) or (not listeners[event.name]) then
        return self
    end

    event._stop = false
    event.target = self
    event.stop = function()
        event._stop = true
    end

    for id, pair in pairs(listeners[event.name]) do
        if DEBUG then
            cc.printinfo("[Event:%s] dispatch event '%s' to listener %s", tostring(self), event.name, id)
        end

        event.tag = pair[2]
        pair[1](event)
        if event._stop then
            if DEBUG then
                cc.printinfo("[Event:%s] break dispatching event '%s'", tostring(self), event)
            end
            break
        end
    end
end

local function removeEventListener(self, removeId)
    local DEBUG = cc.DEBUG > cc.DEBUG_WARN

    local listeners = self._listeners
    if not listeners then
        return self
    end

    for event, listenersForEvent in pairs(listeners) do
        for id, _ in pairs(listenersForEvent) do
            if id == removeId then
                listenersForEvent[id] = nil
                if DEBUG then
                    cc.printinfo("[Event:%s] remove event '%s' listener %s", tostring(self), event, id)
                end
                return self
            end
        end
    end

    return self
end

local function removeEventListenersByTag(self, removeTag)
    local DEBUG = cc.DEBUG > cc.DEBUG_WARN

    local listeners = self._listeners
    if not listeners then
        return self
    end

    for event, listenersForEvent in pairs(listeners) do
        for id, pair in pairs(listenersForEvent) do
            if pair[2] == removeTag then
                listenersForEvent[id] = nil
                if DEBUG then
                    cc.printinfo("[Event:%s] remove event '%s' listener %s", tostring(self), event, id)
                end
            end
        end
    end

    return self
end

local function removeEventListenersByEvent(self, event)
    if self._listeners then
        self._listeners[string_upper(event)] = nil
        if cc.DEBUG > cc.DEBUG_WARN then
            cc.printinfo("[Event:%s] remove event '%s' all listeners", tostring(self), event)
        end
    end
    return self
end

local function removeAllEventListeners(self)
    self._listeners = nil
    if cc.DEBUG > cc.DEBUG_WARN then
        cc.printinfo("[Event:%s] remove all event listener %s", tostring(self))
    end
    return self
end

local function dumpAllEventListeners(self)
    if not self._listeners then
        return self
    end

    cc.printf("[Event:%s] all event listeners", tostring(self))
    for name, listeners in pairs(self._listeners) do
        cc.printf("  event: %s", name)
        for id, pair in pairs(listeners) do
            cc.printf("    %s - id: %s, tag: %s", tostring(pair[1]), tostring(id), tostring(pair[2]))
        end
    end
    return self
end

--

local function Event()
    return {
        addEventListener            = addEventListener,
        dispatchEvent               = dispatchEvent,
        removeEventListener         = removeEventListener,
        removeEventListenersByTag   = removeEventListenersByTag,
        removeEventListenersByEvent = removeEventListenersByEvent,
        removeAllEventListeners     = removeAllEventListeners,
        dumpAllEventListeners       = dumpAllEventListeners,
    }
end

return Event
