#!/bin/bash
export LUA_PATH="_GBC_CORE_ROOT_/src/?.lua;_GBC_CORE_ROOT_/src/lib/?.lua;;"

GBC_CORE_ROOT="_GBC_CORE_ROOT_"
LUABIN=bin/openresty/luajit/bin/lua
SCRIPT=WorkerBootstrap.lua

cd $GBC_CORE_ROOT

ENV="SERVER_CONFIG=loadfile([[_GBC_CORE_ROOT_/conf/config.lua]])(); DEBUG=_DBG_DEBUG; require([[framework.init]]); SERVER_CONFIG.appRootPath= SERVER_CONFIG.appRootPath;"

# workers should be restarted by itself.
while true; do
    $LUABIN -e "$ENV" $GBC_CORE_ROOT/src/$SCRIPT
    if [ $? -ne 0 ]; then
        exit $?
    fi
    sleep 1
done
