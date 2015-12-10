local mysqlService = cc.import("#mysql").service
local easyMysql = cc.class("easyMysql", mysqlService)

function easyMysql:query(queryStr)
    local res, err, errno, sqlstate = easyMysql.super.query(self, queryStr)
    if not res then
        cc.printerror("err:"..err.." errno:"..errno .. "sqlstate:"..sqlstate)
    end
    return res, err, errno, sqlstate
end

return easyMysql