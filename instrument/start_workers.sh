#!/bin/bash

_DIR=$(cd "$(dirname $0)" && pwd)
_DIR=`dirname $_DIR`

ROOT_DIR=`dirname $_DIR`
source $ROOT_DIR/bin/init.inc quiet

# start

cd $ROOT_DIR
export LUA_PATH="$ROOT_DIR/src/?.lua;$ROOT_DIR/src/lib/?.lua;;"
SCRIPT=WorkerBootstrap.lua

ENV="SERVER_CONFIG=loadfile('$VAR_CONF_PATH')(); DEBUG=_DBG_DEBUG; require('framework.init');"

# workers should be restarted by itself.
while true; do
    $LUA_BIN -e "$ENV" $ROOT_DIR/src/$SCRIPT
    if [ $? -ne 0 ]; then
        exit $?
    fi
    sleep 1
done
