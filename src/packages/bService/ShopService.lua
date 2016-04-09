local ShopService = cc.class("ShopService")

--key，比如玩家的id
function ShopService:ctor(connect, key, shopName)
    self.connect = connect
    self._Redis = connect:getRedis()
    self._Key = key
    self._ShopName = shopName or "SHOP"
end

--出售中的列表
function ShopService:getSKeySell()
    return self._ShopName..":Se:"..self._Key
end
--已经出售的列表
function ShopService:getSKeySale()
    return self._ShopName..":Sa:"..self._Key
end

--更新次数的key
function ShopService:getShopTimesKey()
    return self._ShopName..":UT:"..self._Key
end

function ShopService:getShopUpdateKey()
    return self._ShopName..":UP:"..self._Key
end

function ShopService:getBuyTimesKey()
    return self._ShopName..":BT:"..self._Key
end

function ShopService:resetShopTimes()
    self._Redis:del(self:getShopTimesKey())
end

function ShopService:increaseShopTimes()
    self._Redis:incr(self:getShopTimesKey())
end

function ShopService:increaseBuyTimes()
    self._Redis:incr(self:getBuyTimesKey())
end

function ShopService:getShopTimes()
    return tonumber(self._Redis:get(self:getShopTimesKey())) or 0
end

function ShopService:getBuyTimes()
    return tonumber(self._Redis:get(self:getBuyTimesKey())) or 0
end

function ShopService:canShopUpdate()
    return (tonumber(self._Redis:get(self:getShopUpdateKey())) or 0) <= os.time()
end

function ShopService:getShopUpdate()
    return tonumber(self._Redis:get(self:getShopUpdateKey())) or 0
end

function ShopService:setShopUpdate(time)
    self._Redis:set(self:getShopUpdateKey(), time)
end

function ShopService:clear()
    self._Redis:del(self:getSKeySell())
    self._Redis:del(self:getSKeySale())
end

function ShopService:addSellItem(id)
    return self._Redis:sadd(self:getSKeySell(), id) == 1
end

function ShopService:getSellList()
    return self._Redis:smembers(self:getSKeySell())
end

function ShopService:getSellCount()
    return self._Redis:scard(self:getSKeySell())
end

function ShopService:getSaleList()
    return self._Redis:smembers(self:getSKeySale())
end

function ShopService:addSaleItem(id)
    return self._Redis:sadd(self:getSKeySale(), id) == 1
end

function ShopService:isSale(id)
    return self._Redis:sismember(self:getSKeySale(), id) == 1
end

function ShopService:canSell(id)
    return self._Redis:sismember(self:getSKeySell(), id) == 1
end

return ShopService