local WarnChar = cc.class("WarnChar")

function WarnChar:ctor(warnlist)
    cc.printinfo("WarnChar ctor")
    self:createTree(warnlist)
end

function WarnChar:createNode(c, flag, nodes)
    local node = {}
    node.c = c or nil           --字符
    node.flag = flag or 0       --是否结束标记0：继续，1：结尾
    node.nodes = nodes or {}    --保存子节点
    return node
end

--创建查找树
function WarnChar:createTree(warnlist)
    self._RootNode = self:createNode("R")
    for _, v in pairs(warnlist) do
        local chars = self:getCharArray(v.name)
        self:insertNode(self._RootNode, chars, 1)
    end
end

--插入节点
function WarnChar:insertNode(node, cs, index)
    local len = #cs
    if index > len then
        return
    end
    local c = cs[index]
    local n = self:findNode(node, c)
    if n == nil then
        n = self:createNode(c)
        node.nodes[c] = n
    end
    if index == len then
        n.flag = 1
    end

    index = index + 1
    if index <= len then
        self:insertNode(n, cs, index)
    end
end

--查找子节点
function WarnChar:findNode(node, c)
    local nodes = node.nodes
    return nodes[c]
end

function WarnChar:getCharArray(str)
    local array = {}
    local len = string.len(str)
    while str do
        local fontUTF = string.byte(str,1)

        if fontUTF == nil then
            break
        end

        if fontUTF > 127 then 
            local tmp = string.sub(str,1,3)
            table.insert(array,tmp)
            str = string.sub(str,4,len)
        else
            local tmp = string.sub(str,1,1)
            table.insert(array,tmp)
            str = string.sub(str,2,len)
        end
    end
    return array
end

function WarnChar:replaceWithStar(str)
    local chars = self:getCharArray(str)
    local index = 1
    local node = self._RootNode
    local word = {}
    local len = #chars
    while len >= index do
        local char = chars[index]
        if char ~= ' ' then
            node = self:findNode(node, char)
        end
        if node == nil then
            index = index - #word
            node = self._RootNode
            word = {}
        elseif node.flag == 1 then
            table.insert(word, index)
            for _, v in pairs(word) do
                chars[v] = '*'
            end
            node = self._RootNode
            word = {}
        else
            table.insert(word, index)
        end
        index = index + 1
    end

    local _str = ''
    for _, v in pairs(chars) do
        _str = _str .. v
    end
    return _str
end

return WarnChar