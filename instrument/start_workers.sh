#!/bin/bash
export LUA_PATH="_QUICK_SERVER_ROOT_/src/?.lua;_QUICK_SERVER_ROOT_/src/lib/?.lua;;"

QUICK_SERVER_ROOT="_QUICK_SERVER_ROOT_"
LUABIN=bin/openresty/luajit/bin/lua
SCRIPT=WorkerBootstrap.lua

cd $QUICK_SERVER_ROOT

ENV="SERVER_CONFIG=loadfile([[_QUICK_SERVER_ROOT_/conf/config.lua]])(); DEBUG=_DBG_DEBUG; require([[framework.init]]); SERVER_CONFIG.appRootPath= SERVER_CONFIG.appRootPath .. [[/workers/?.lua;]] .. SERVER_CONFIG.appRootPath;"

# workers should be restarted by itself.
while true; do
    $LUABIN -e "$ENV" $QUICK_SERVER_ROOT/src/$SCRIPT
    if [ $? -ne 0 ]; then
        exit $?
    fi
    sleep 1
done
