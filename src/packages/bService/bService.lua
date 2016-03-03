local _M = {
    CacheService    = cc.import(".CacheService"),
    FightService    = cc.import(".FightService"),
    FriendService   = cc.import(".FriendService"),
    RankService     = cc.import(".RankService"),
    RoomService     = cc.import(".RoomService"),
    ShopService     = cc.import(".ShopService"),
    MissionService  = cc.import(".MissionService"),

    JobService    = cc.import(".JobService"),

    ConnectIDService = cc.import(".ConnectIDService"),
    LockService     = cc.import(".LockService"),
    RandomNameService = cc.import(".RandomNameService"),

    CacheKeyService = cc.import(".CacheKeyService"),

    easyRedis = cc.import(".easyRedis"),
}

return _M