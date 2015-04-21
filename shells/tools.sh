#!/bin/bash
export LUA_PATH="_QUICK_SERVER_ROOT_/src/?.lua;_QUICK_SERVER_ROOT_/src/lib/?.lua;;"

QUICK_SERVER_ROOT="_QUICK_SERVER_ROOT_"
LUABIN=bin/openresty/luajit/bin/lua
SCRIPT=CLIBootstrap.lua

cd $QUICK_SERVER_ROOT

ENV="SERVER_CONFIG=loadfile([[_QUICK_SERVER_ROOT_/conf/config.lua]])();DEBUG=_DBG_DEBUG;require([[framework.init]]);SERVER_CONFIG.appRootPath=SERVER_CONFIG.appRootPath..[[/tools]];"

$LUABIN -e "$ENV" $QUICK_SERVER_ROOT/src/$SCRIPT $*
