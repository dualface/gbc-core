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

local assert         = assert
local error          = error
local getmetatable   = getmetatable
local rawget         = rawget
local setmetatable   = setmetatable
local string_format  = string.format
local type           = type

if tolua then
    local tolua_getpeer  = tolua.getpeer
    local tolua_iskindof = tolua.iskindof
    local tolua_setpeer  = tolua.setpeer
end

local _setmetatableindex, _iskindof, _iskindofinternal

_setmetatableindex = function(target, index)
    if type(target) == "userdata" then
        if tolua_getpeer then
            local peer = tolua_getpeer(target)
            if not peer then
                peer = {}
                tolua_setpeer(t, peer)
            end
            _setmetatableindex(peer, index)
         else
            _setmetatableindex(target, index)
         end
    else
        setmetatable(target, {__index = index})
    end
end

_iskindof = function(target, classname)
    local targetType = type(target)
    if targetType ~= "userdata" and targetType ~= "table" then
        return false
    end

    local mt
    if targetType == "userdata" and tolua_iskindof then
        if tolua_iskindof(target, classname) then
            return true
        end
        mt = tolua_getpeer(target)
    else
        mt = getmetatable(target)
    end
    if not mt then
        return false
    end

    return _iskindofinternal(mt, classname)
end

_iskindofinternal = function(mt, classname)
    if not mt then return false end

    local index = rawget(mt, "__index")
    if not index then return false end

    local cname = rawget(index, "__cname")
    if cname == classname then return true end

    return _iskindofinternal(getmetatable(index), classname)
end

-- exports

function cc.class(classname, super)
    -- create class
    local cls = {__cname = classname}

    cls.new = function(...)
        local create = cls.__create
        local instance
        if create then
            instance = create(...)
        else
            instance = {}
        end
        _setmetatableindex(instance, cls)
        instance.class = cls
        instance:ctor(...)
        return instance
    end

    cls.create = function(_cls, ...)
        return cls.new(...)
    end

    cls.iskindof = function(target)
        return _iskindof(target, cls.__cname)
    end

    -- set super class
    local superType = type(super)
    if superType == "function" then
        assert(cls.__create == nil, string_format("class() - create class \"%s\" with more than one creating function", classname))
        cls.__create = super
    elseif superType == "table" then
        if super[".isclass"] then
            -- super is native class
            assert(cls.__create == nil, string_format("class() - create class \"%s\" with more than one creating function or native class", classname))
            cls.__create = function()
                return super:create()
            end
        else
            -- super is pure lua class
            assert(type(super.__cname) == "string", string_format("class() - create class \"%s\" used super class isn't declared by class()", classname))
            cls.super = super
            setmetatable(cls, {__index = cls.super})
        end
    elseif superType ~= "nil" then
        error(string_format("class() - create class \"%s\" with invalid super type \"%s\"", classname, superType))
    end

    if not cls.ctor then
        cls.ctor = function() end -- add default constructor
    end

    return cls
end

function cc.bind(target, extend)
    local id = tostring(extend)
    extend = extend()
    extend.__id = id
    setmetatable(extend, getmetatable(target))
    setmetatable(target, {__index = extend})
    return target
end

function cc.unbind(target, extend)
    local id = tostring(extend)
    local mt = getmetatable(target)
    while mt do
        local index = rawget(mt, "__index")
        if not index then break end
        if index.__id == id then
            setmetatable(target, getmetatable(index))
            break
        end
        mt = getmetatable(mt)
    end
    return target
end
