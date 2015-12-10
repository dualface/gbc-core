local MySQL = {}
local mysqlService = cc.import(".easyMysql")

function MySQL:getConnect(config)
    if ngx.ctx[MySQL] then
        return ngx.ctx[MySQL]
    end
    if not config then return nil end
    local ok, db = pcall(function()
            return mysqlService:new(config)
        end)
    if ok then
        ngx.ctx[MySQL] = db
        return db
    else
        printWarn(db)
        return nil
    end
end

function MySQL:close()
    if ngx.ctx[MySQL] then
        ngx.ctx[MySQL]:setKeepAlive(60000, 100)
        ngx.ctx[MySQL] = nil
    end
end

return MySQL